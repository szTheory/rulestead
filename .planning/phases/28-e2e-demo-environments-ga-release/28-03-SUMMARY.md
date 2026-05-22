# 28-03 Summary

## Status

Completed on 2026-05-21.

## Outcome

Built the external Next.js demo app under `examples/demo/frontend`, including a custom OpenFeature web provider that reads from the Phoenix bridge and listens for backend configuration-change events. The page now renders an obvious seeded flag-driven state and the frontend Docker contract is defined for downstream Compose orchestration.

## Verification

- `cd examples/demo/frontend && npm test -- --runInBand tests/rulestead-web-provider.test.ts`
- `cd examples/demo/frontend && npm run build`

## Notes

- Server-rendered bootstrap fetches use `FLAGS_API_BASE` while browser fetches use `NEXT_PUBLIC_FLAGS_API_BASE` so Compose can route server-side traffic over the internal backend hostname.
- Playwright support and the `test:e2e` script were added here for the later browser proof.
