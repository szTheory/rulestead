# OpenFeatureRulestead

`open_feature_rulestead` is the optional OpenFeature bridge companion for
Rulestead.

Use it when a host application already has an OpenFeature-shaped integration
surface and wants to resolve through the Rulestead runtime instead of wiring a
custom adapter.

## Current posture

- Repo GA shipped in `v1.0.0` on 2026-05-21, while this companion package
  remains on the `0.1.0` line with the rest of the installable sibling
  packages.
- This is a secondary companion surface, not the primary front door.
- The current bounded proof path is the local demo under
  [../examples/demo/README.md](../examples/demo/README.md); broader bridge
  proof closure is intentionally deferred.

## Learn more

- Shared release story: [../README.md](../README.md)
- Installation choices: [../guides/introduction/installation.md](../guides/introduction/installation.md)
- Demo proof path: [../examples/demo/README.md](../examples/demo/README.md)
