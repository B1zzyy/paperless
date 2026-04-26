#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>

using namespace metal;

// Makes the whole receipt appear narrower in width, then restores full width.
// The `amount` parameter controls how strong the width squeeze is.
[[ stitchable ]] float2 receiptExitWarp(
    float2 position,
    float amount,
    float width,
    float height,
    float releaseLineFromBottom,
    float releaseTransition
) {
    if (amount <= 0.0001 || width <= 1.0 || height <= 1.0) {
        return position;
    }

    float yFromBottom = height - position.y;

    // Invisible horizontal release line:
    // - below line: squeezed
    // - above line: quickly returns to normal width
    float belowLine = 1.0 - smoothstep(
        releaseLineFromBottom,
        releaseLineFromBottom + max(releaseTransition, 1.0),
        yFromBottom
    );

    // Strong trapezoid-like squeeze below the line, no squeeze above it.
    float squeeze = clamp(amount * belowLine * 0.02, 0.0, 0.03);
    float invScaleX = 1.0 / max(0.10, 1.0 - squeeze);

    // For distortionEffect we return source coordinates for each destination pixel.
    // Mapping outward from center samples a wider source and renders as narrower output.
    float cx = width * 0.5;
    float xFromCenter = position.x - cx;
    float warpedX = cx + (xFromCenter * invScaleX);

    return float2(warpedX, position.y);
}
