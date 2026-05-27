# Rulesets

Rulestead rulesets are designed to stay readable under change. A flag has one
default outcome and an ordered list of rules. Evaluation is simple:
first matching rule wins; otherwise the default applies.

## Ruleset Shape

At the public API boundary, app code and operators should reason about four
things:

- the flag identity and default value
- the ordered rule list
- reusable audiences referenced by rules
- optional variants and rollout weights on rules that need stickiness

That is the model to preserve when authoring or reviewing a flag. You do not
need to learn internal evaluator modules or admin LiveView assigns to operate
it safely.

## Author In The Same Order You Expect To Debug

Put rules in the order you want them explained later:

1. most specific allow or treatment rules first
2. broader cohort rules after that
3. the default value last, outside the rule list

Because evaluation is first-match-wins, rule order is not presentation-only. If
you reorder rules, you may change live behavior.

## Keep Rules Focused

Good rulesets are narrow and intention-revealing:

- one rollout step per rule
- one audience idea per reusable audience
- one reason an operator can explain in plain language

If a rule starts carrying several unrelated conditions, split it. If several
flags repeat the same targeting logic, move that logic into a reusable
audience.

## Supported Condition Families

Phase `v0.1.0` supports bounded attribute predicates inside rules:

- equals
- in
- not_in
- gt
- lt
- gte
- lte
- regex
- exists

Rules can also reference reusable audiences so you do not copy large condition
sets into every flag.

## Reusable Audience Impact Preview

Operators manage reusable **Audience** definitions (the product term — internal
code may use `segment_match`). Before publish or archive of a shared audience,
run an **impact preview** against the **preview basis**: authored state ±
**explicit samples** only.

Previews carry **uncertainty** by design. They do **not** claim exact
affected-user or population counts. Treat preview output as bounded guidance,
not a census.

Audience references **fail closed** when assets are missing, archived,
incompatible, stale, or tenant-mismatched. Always confirm **environment scope**
and **tenant scope** — same-name audiences in different env/tenant contexts
are not assumed equivalent.

The mounted companion at `/admin/audiences` follows **preview → confirm →
audit** for audience mutations. Use that workflow instead of bypassing preview
when editing shared audiences.

## Variants And Weights

Multivariate flags keep stable variant keys and authored rollout weights.
Weights must add up to `100`, and deterministic bucketing keeps the same
targeting key in the same bucket for the same rule.

That gives operators a predictable question to ask during rollout work:

- Which rule matched?
- Which bucket did this targeting key land in?
- Which variant weight owned that bucket range?

Those answers show up again in explainability and rollout workflows.

## Draft Then Publish

When you author rules through the admin package, treat draft and publish as
separate moments:

- save draft while editing rule order, conditions, or variant weights
- publish when the ruleset is ready to become runtime truth for that
  environment

This is especially important when multiple operators review the same flag. The
mounted admin UI preserves that distinction at the package boundary without
making internal LiveView state part of the contract.

## Review Checklist

Before you publish or merge a ruleset change, confirm:

- the default value is safe if every rule misses
- the rule list reads top-to-bottom in business priority order
- sticky rules have a clear targeting-key strategy
- reused audiences are named for business meaning, not implementation trivia
- an on-call engineer could explain the outcome from the ruleset alone

## Where To Go Next

- Use [Evaluation](evaluation.md) for payload-first runtime calls.
- Use [Rollout](rollout.md) when a ruleset change is part of a staged release.
- Use [Explainability](explainability.md) when you need to read a decision back
  to a support or incident audience.
