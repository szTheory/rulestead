# Technology Stack

**Project:** Rulestead v1.0.0 (GA)
**Researched:** 2026-05-17

## Recommended Stack

### Core Framework (Locked)
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir / Phoenix | 1.14+ | Host application integration | Standard, already established. |

### Security & RBAC
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Pure Elixir Contexts | Built-in | Role-Based Access Control | Using simple Policy modules (functions returning `{:ok, user} \| {:error, :unauthorized}`) ensures zero dependency conflicts with the host application. Heavy libraries (Permit/Ash) are anti-patterns for embeddable libraries. |

### Infrastructure (Demo Environments)
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Docker Compose | Latest | E2E Demo Environment | Standard for "one-click" local evaluations. Can easily spin up Postgres, Redis, Rulestead core, and a demo client app together. |
| Livebook | Latest | Interactive Demos | Excellent for developer-focused, Elixir-centric walkthroughs of the Rulestead API. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `dialyxir` | 1.4+ | Static Analysis | Strict enforcement of API contracts and specs before locking down 1.0. |
| `ex_doc` | Latest | Documentation | Essential for "Documentation Perfection". |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| RBAC | Pure Elixir Contexts | Permit or AshRbac | Would impose heavy dependencies and potential version conflicts on the host application embedding Rulestead. |
| Demo Env | Docker Compose | Hosted Sandbox | Too expensive to maintain for an open-source project; Docker Compose is reliable and free. |

## Sources

- [HexDocs: Library Guidelines](https://hexdocs.pm/elixir/library-guidelines.html)
- Community consensus on zero-dependency pure-Elixir libraries for mountable Phoenix engines.
