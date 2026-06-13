// Source: svgo.dev/docs/configuration
// SVGO config for Rulestead logo lockup SVGs — preserves accessibility metadata and viewBox.
//
// In SVGO 4.x:
//   - removeTitle and removeViewBox are NOT in preset-default (standalone-only plugins)
//   - removeDesc and cleanupIds ARE in preset-default and must be disabled via overrides
//   - convertColors must be disabled to protect fill="currentColor" in rs-mark-mono.svg
//   - removeUnknownsAndDefaults strips role="img" unless keepRoleAttr is set
//
// This config disables removeDesc, cleanupIds, and convertColors via preset-default
// overrides, keeps role="img" via keepRoleAttr, pins floatPrecision (D-04), and uses
// multipass for maximum safe optimization.
export default {
  multipass: true,
  plugins: [
    {
      name: 'preset-default',
      params: {
        floatPrecision: 3,         // pinned (D-04) — deterministic output across runs
        overrides: {
          removeDesc: false,       // MUST keep <desc> for screen readers
          cleanupIds: false,       // keep IDs used by aria-labelledby
          convertColors: false,    // MUST keep fill="currentColor" in rs-mark-mono.svg
          removeUnknownsAndDefaults: {
            keepRoleAttr: true,    // MUST keep role="img" on the SVG root (D-04)
          },
          mergePaths: false,       // keep one <path> per glyph (103-WINNER frozen
                                   // technical fact: per-glyph outlined paths)
        },
      },
    },
    // removeTitle and removeViewBox are not in preset-default in SVGO 4.x,
    // so they are not invoked and do not need overrides.
  ],
};
