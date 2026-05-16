# Phase 17 Architecture: Analytics & Metrics Ingestion

## 1. Context and Goals

Phase 17 focuses on how Rulestead ingests, buffers, and stores high-volume metrics: feature flag impressions, exposures, and custom tracking/conversion events. Rulestead aims to bridge the gap between simple boolean toggles and full experimentation, which requires a robust, performant data pipeline that does not compromise the host application's primary database or latency.

The system must handle massive spikes (e.g., thousands of flag evaluations per second) without connection pool exhaustion, while providing a clear API (`Rulestead.track/3`) for hosts to record conversion metrics.

## 2. Ingestion Buffer Evaluation

We evaluated several common Elixir buffering strategies against our core principles: zero surprise performance degradation, idiomatic OTP usage, and excellent DX.

### 2.1 GenServer Periodic Flush via `Repo.insert_all`
- **Pros:** Zero external dependencies. Extremely high throughput. Batching (e.g., 1,000 events per insert) drastically reduces database connection pool contention and transaction overhead. Can be heavily optimized with ETS for concurrent non-blocking writes.
- **Cons:** Lossy. If the BEAM node crashes or restarts, the in-memory buffer is lost ("at-most-once" delivery). Requires explicit backpressure handling (e.g., dropping events if the buffer exceeds a memory threshold).
- **Verdict:** **Recommended.** Analytics data is inherently statistical; losing 5 seconds of telemetry during a rare node crash is an acceptable tradeoff to absolutely guarantee the host app's primary database will not be overwhelmed by telemetry insert spikes.

### 2.2 Oban Batch Worker
- **Pros:** Idiomatic for background jobs in modern Elixir. Provides guaranteed "at-least-once" delivery, persistence across restarts, and excellent observability via Oban Web.
- **Cons:** Enqueueing an Oban job requires a database insert. If we queue one Oban job per tracking event, we completely defeat the purpose of buffering—we still pay 1 DB write per event, and we rapidly bloat the `oban_jobs` table. Batch-inserting Oban jobs requires an in-memory buffer anyway.
- **Verdict:** **Discard.** Oban is built for durable task execution, not high-volume time-series metric ingestion.

### 2.3 Fire-and-Forget Tasks (`Task.Supervisor.async_nolink`)
- **Pros:** Dead simple to implement. Does not block the caller's process.
- **Cons:** Zero batching. Executes one `Repo.insert` per event. During traffic spikes, this will instantly exhaust the Ecto connection pool and cause cascading failures across the entire host application.
- **Verdict:** **Discard.** A dangerous footgun for high-throughput libraries.

### 2.4 Broadway
- **Pros:** Industry standard for robust backpressure, concurrency, and multi-stage batching.
- **Cons:** A massive, complex dependency. Broadway shines when pulling from external brokers (SQS, Kafka, RabbitMQ). Using Broadway with an in-process dummy producer to write to Postgres is massive architectural overkill compared to a focused GenServer/ETS batcher.
- **Verdict:** **Discard.** Violates the principle of keeping the core runtime package lean and dependency-light.

## 3. Lessons from the Ecosystem

- **Statsig & PostHog:** They separate the *exposure* (which user saw which variant) from the *conversion* (did the user buy the product). Downstream, they rely on joining these streams via a shared `user_id` and timestamp.
- **GrowthBook:** Avoids ingestion entirely by acting as a SQL engine on top of the host's existing data warehouse. They rely on the host dumping exposures and track events into Snowflake/BigQuery and handle the complex joining logic.
- **Footguns to Avoid:** Bolting on experimentation without a scalable measurement loop. Trying to do complex identity resolution (aliasing anonymous users to logged-in users) inside the feature flag DB. Forcing the host to pay a massive performance tax for analytics they might not even use.

## 4. Architectural Recommendation for Phase 17

Rulestead will implement a high-throughput, loss-tolerant, batch-insert pipeline using standard OTP primitives, coupled with an explicit telemetry contract.

### 4.1 The Buffering and Ingestion Mechanism

We will implement an **ETS-backed GenServer Batcher**.

1. **Write Path (Non-blocking):** `Rulestead.track/3` and the internal exposure hooks will write events directly to a `:public, :write_concurrency` ETS table. This guarantees that host application requests are never blocked by analytics ingestion.
2. **Flush Path:** A GenServer (`Rulestead.Analytics.Flusher`) will run on a periodic timer (e.g., every 5 seconds) or when the ETS table reaches a configured capacity (e.g., 2,000 records).
3. **Database Insertion:** The Flusher drains the ETS table, maps the records to Ecto structs, and executes a single `Repo.insert_all`.
4. **Backpressure/Safety:** If the database is down or slow and the ETS table grows beyond a hard limit (e.g., 50,000 records), the write path will gracefully drop new events to prevent OOMing the BEAM, emitting a `[:rulestead, :analytics, :dropped]` telemetry event.

### 4.2 The Host API Seam and Schema

**The API Seam:**
```elixir
# For custom conversion events
Rulestead.track(actor_id, event_name, metadata \\ %{}, opts \\ [])

# Example
Rulestead.track("user_123", "checkout_completed", %{revenue: 120.50})
```

**The Ecto Schema (`rulestead_analytics_events`):**
To ensure high write performance, this table will be append-only and heavily indexed for time-series queries.

```elixir
schema "rulestead_analytics_events" do
  field :id, Ecto.UUID               # UUIDv7 for temporal locality/clustering
  field :occurred_at, :utc_datetime_usec
  field :tenant_id, :string          # For multi-tenant setups
  field :env, :string
  field :kind, :string               # "exposure" | "impression" | "track"
  field :actor_id, :string           # The assignment ID (user, session, etc.)
  field :event_name, :string         # The flag_key (for exposures) or track name
  field :metadata, :map              # JSONB: variant, ruleset_version, conversion values
end
```

### 4.3 Joining Exposures and Conversions

Rulestead will not attempt to build a complex, in-database statistics engine in v1. Instead, it will provide the perfectly structured data required for experimentation.

**How they are joined:**
1. **The Shared Key:** Both `exposure` events (emitted by `Rulestead.RuleEngine` when a flag is evaluated) and `track` events (emitted by the host app) must carry the exact same `actor_id`.
2. **Temporal Attribution:** To determine if an exposure influenced a conversion, a SQL query or downstream warehouse joins the `rulestead_analytics_events` table onto itself:
   - Match where `exposure.actor_id == track.actor_id`
   - Match where `track.occurred_at >= exposure.occurred_at`
   - Filter to a specific attribution window (e.g., within 48 hours).

**Data Warehouse Export:**
Because high-volume deployments will not want to run heavy analytical queries on their primary Postgres database, Rulestead's architecture perfectly positions the `rulestead_analytics_events` table to be easily slurped by logical replication (Debezium/Airbyte) or periodic export scripts into Snowflake/BigQuery/ClickHouse, where GrowthBook or custom BI tools can run the final experimentation math.