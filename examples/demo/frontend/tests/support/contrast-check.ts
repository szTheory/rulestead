/**
 * WCAG contrast-check helper for Phase 87 token verification (THM-06).
 *
 * Computes the WCAG 2.1 relative luminance contrast ratio between two
 * opaque hex color values. Used to assert AA compliance on token pairs
 * across light and dark themes.
 */

/** Parse a 6-char hex color string to an [R, G, B] tuple in 0–1 range. */
function hexToRgb(hex: string): [number, number, number] {
  const clean = hex.replace(/^#/, "");
  if (clean.length !== 6) {
    throw new Error(`wcagRatio: expected a 6-char hex color, got "${hex}"`);
  }
  const r = parseInt(clean.slice(0, 2), 16) / 255;
  const g = parseInt(clean.slice(2, 4), 16) / 255;
  const b = parseInt(clean.slice(4, 6), 16) / 255;
  return [r, g, b];
}

/** Linearize a sRGB channel value (0–1) per W3C formula. */
function linearize(c: number): number {
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

/** Compute relative luminance for a hex color (W3C formula). */
function relativeLuminance(hex: string): number {
  const [r, g, b] = hexToRgb(hex);
  return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
}

/**
 * Compute the WCAG 2.1 contrast ratio between two opaque hex colors.
 *
 * Returns a value in [1, 21]. AA normal text requires ≥ 4.5; large text ≥ 3.0.
 *
 * Example: wcagRatio('#ffffff', '#1a2332') ≈ 14.0 (light-mode text on surface)
 */
export function wcagRatio(hex1: string, hex2: string): number {
  const l1 = relativeLuminance(hex1);
  const l2 = relativeLuminance(hex2);
  const lMax = Math.max(l1, l2);
  const lMin = Math.min(l1, l2);
  return (lMax + 0.05) / (lMin + 0.05);
}

/**
 * Assert that a contrast ratio meets WCAG AA for the given text level.
 *
 * - `'normal'` text: ratio must be ≥ 4.5 (WCAG 2.1 §1.4.3)
 * - `'large'`  text: ratio must be ≥ 3.0  (WCAG 2.1 §1.4.3)
 *
 * Throws a descriptive error when the assertion fails.
 */
export function assertAA(
  ratio: number,
  level: "normal" | "large" = "normal",
): void {
  const required = level === "large" ? 3.0 : 4.5;
  if (ratio < required) {
    throw new Error(
      `WCAG AA ${level} text requires contrast ratio ≥ ${required}; got ${ratio.toFixed(2)}`,
    );
  }
}
