#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// MARK: - Procedural noise helpers

/// Fast, artifact-free polynomial 2D hash (avoids trig banding under MTL_FAST_MATH).
static inline float dewyHash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031f);
    p3 += dot(p3, p3.yzx + 33.33f);
    return fract((p3.x + p3.y) * p3.z);
}

/// Smooth bilinear value noise in [0, 1].
static inline float dewyValueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0f - 2.0f * f);

    float a = dewyHash21(i);
    float b = dewyHash21(i + float2(1.0f, 0.0f));
    float c = dewyHash21(i + float2(0.0f, 1.0f));
    float d = dewyHash21(i + float2(1.0f, 1.0f));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

/// Two-octave organic noise for painterly gouache pigment variation.
static inline float dewySoftFBM(float2 p) {
    float n1 = dewyValueNoise(p);
    float n2 = dewyValueNoise(p * 2.13f + float2(17.4f, 31.2f));
    return n1 * 0.65f + n2 * 0.35f;
}

// MARK: - Cold-press watercolor paper grain

/// Subtle cold-press cotton-rag paper texture with gentle linen fiber tooth
/// and warm/cool rag micro-variation. Preserves premultiplied alpha cleanly.
[[stitchable]] half4 paperGrain(float2 position, half4 color, float intensity) {
    if (color.a <= half(0.001h) || intensity <= 0.0f) {
        return color;
    }

    float safeIntensity = clamp(intensity, 0.0f, 0.25f);

    // Medium organic paper tooth + cross-woven cotton fibers + fine micro tooth.
    float tooth = dewyValueNoise(position * 0.28f);
    float fiberH = dewyValueNoise(position * float2(0.82f, 0.34f) + float2(19.3f, 7.1f));
    float fiberV = dewyValueNoise(position * float2(0.34f, 0.82f) + float2(47.1f, 23.8f));
    float micro = dewyValueNoise(position * 1.45f + float2(73.7f, 11.9f));

    float combined = tooth * 0.44f + (fiberH + fiberV) * 0.20f + micro * 0.16f;
    float signedGrain = (combined - 0.5f) * 2.0f;

    half3 rgb = color.rgb / max(color.a, half(0.001h));

    // Warm cream highlight on fiber peaks, whisper-cool shadow in valleys.
    half3 warmBias = half3(1.06h, 1.00h, 0.92h);
    half3 coolBias = half3(0.94h, 0.97h, 1.05h);
    half3 tint = signedGrain >= 0.0f ? warmBias : coolBias;

    half3 grained = rgb + tint * half(signedGrain * safeIntensity);
    grained = clamp(grained, half3(0.0h), half3(1.0h));

    return half4(grained * color.a, color.a);
}

// MARK: - Sunlit gouache pond caustics

/// Flowing organic dual-wave caustic ribbons with gentle water-plane perspective.
[[stitchable]] half4 pondCaustics(
    float2 position,
    half4 color,
    float2 size,
    float time,
    half4 tint,
    float strength
) {
    if (color.a <= half(0.001h) || strength <= 0.0f) {
        return color;
    }

    float2 safeSize = max(size, float2(1.0f));
    float2 uv = clamp(position / safeSize, float2(0.0f), float2(1.0f));

    // Foreshorten near the far shore (uv.y -> 0) and broaden toward foreground.
    float depth = pow(max(uv.y, 0.015f), 0.72f);
    float2 p = float2((uv.x - 0.5f) * (3.5f - 1.55f * uv.y), depth * 4.1f);

    float t = time * 0.52f;

    // Gentle organic domain warp so filaments curve like sunlit water.
    float2 warp = float2(
        sin(p.y * 2.05f + t * 0.82f) * 0.30f + cos(p.x * 1.35f - t * 0.45f) * 0.14f,
        cos(p.x * 1.85f - t * 0.70f) * 0.26f + sin(p.y * 1.45f + t * 0.38f) * 0.12f
    );

    float2 pA = p * 1.42f + warp + float2(t * 0.22f, -t * 0.14f);
    float2 pB = p * 1.88f - warp * 0.82f + float2(-t * 0.17f, t * 0.11f);

    float waveA = abs(
        sin(pA.x * 2.35f + sin(pA.y * 2.05f + t * 0.48f)) +
        cos(pA.y * 2.55f - cos(pA.x * 1.75f - t * 0.36f))
    ) * 0.5f;

    float waveB = abs(
        sin(pB.x * 2.15f - cos(pB.y * 2.25f + t * 0.55f)) +
        cos(pB.y * 2.35f + sin(pB.x * 1.95f + t * 0.42f))
    ) * 0.5f;

    // Cube instead of pow() for fast-math NaN safety and sharper liquid filaments.
    float rA = clamp(1.0f - waveA, 0.0f, 1.0f);
    float rB = clamp(1.0f - waveB, 0.0f, 1.0f);
    float ridgeA = rA * rA * rA;
    float ridgeB = rB * rB * rB;
    float caustic = clamp(ridgeA * 0.62f + ridgeB * 0.54f, 0.0f, 1.0f);

    // Painterly dappled breakup across the water surface.
    float dapple = 0.62f + 0.38f * dewyValueNoise(p * 1.55f + float2(t * 0.14f, -t * 0.09f));

    // Soft feather along far shore lip and near bottom margin.
    float shoreFade = smoothstep(0.0f, 0.09f, uv.y);
    float nearFade = 1.0f - 0.20f * smoothstep(0.78f, 1.0f, uv.y);
    float mask = shoreFade * nearFade;

    half3 tintRGB = tint.a > half(0.001h)
        ? clamp(tint.rgb / tint.a, half3(0.0h), half3(1.0h))
        : half3(1.0h, 0.98h, 0.94h);

    half3 rgb = color.rgb / max(color.a, half(0.001h));
    half mixAmount = half(clamp(caustic * dapple * mask * clamp(strength, 0.0f, 0.8f), 0.0f, 0.65f));

    // Soft luminous screen lift so bright skies never blow out harshly.
    half3 result = rgb + (half3(1.0h) - rgb * half(0.52h)) * tintRGB * mixAmount;
    result = clamp(result, half3(0.0h), half3(1.0h));

    return half4(result * color.a, color.a);
}

/// Bounding-rect wrapper for layout-neutral SwiftUI View.colorEffect(.boundingRect).
[[stitchable]] half4 pondCausticsRect(
    float2 position,
    half4 color,
    float4 bounds,
    float time,
    half4 tint,
    float strength
) {
    return pondCaustics(position - bounds.xy, color, bounds.zw, time, tint, strength);
}

// MARK: - Painterly gouache pigment bloom

/// Soft painterly pigment granulation and atmospheric skylight diffusion
/// across illustrated skies, mountains and layered paper-cut hills.
[[stitchable]] half4 gouacheBloom(
    float2 position,
    half4 color,
    float2 size,
    float strength
) {
    if (color.a <= half(0.001h) || strength <= 0.0f) {
        return color;
    }

    float2 safeSize = max(size, float2(1.0f));
    float2 uv = clamp(position / safeSize, float2(0.0f), float2(1.0f));
    float safeStrength = clamp(strength, 0.0f, 0.25f);

    // Broad gouache wash + medium pigment settling in paper hollows.
    float wash = dewySoftFBM(uv * float2(3.8f, 3.2f) + float2(4.2f, 9.7f));
    float granulation = dewyValueNoise(position * 0.16f + float2(29.1f, 53.4f));
    float pigmentDelta = ((wash * 0.68f + granulation * 0.32f) - 0.5f) * 2.0f;

    // Gentle sunlit atmospheric skylight diffusion near upper-middle horizon.
    float2 lightDelta = (uv - float2(0.56f, 0.28f)) * float2(1.0f, 1.35f);
    float skyDiffusion = exp(-dot(lightDelta, lightDelta) * 2.4f);

    half3 rgb = color.rgb / max(color.a, half(0.001h));
    half3 warmLight = half3(1.0h, 0.97h, 0.90h);

    half3 painterly = rgb
        + half3(0.98h, 0.99h, 1.03h) * half(pigmentDelta * safeStrength)
        + (warmLight - rgb) * half(skyDiffusion * safeStrength * 0.55f);

    painterly = clamp(painterly, half3(0.0h), half3(1.0h));
    return half4(painterly * color.a, color.a);
}

/// Bounding-rect wrapper for layout-neutral SwiftUI View.colorEffect(.boundingRect).
[[stitchable]] half4 gouacheBloomRect(
    float2 position,
    half4 color,
    float4 bounds,
    float strength
) {
    return gouacheBloom(position - bounds.xy, color, bounds.zw, strength);
}

// MARK: - Liquid meniscus caustic shimmer

/// Subtle animated internal liquid highlight shift for translucent droplets and water rims.
[[stitchable]] half4 meniscusGlow(
    float2 position,
    half4 color,
    float2 size,
    float time,
    float strength
) {
    if (color.a <= half(0.001h) || strength <= 0.0f) {
        return color;
    }

    float2 safeSize = max(size, float2(1.0f));
    float2 uv = clamp(position / safeSize, float2(0.0f), float2(1.0f));
    float safeStrength = clamp(strength, 0.0f, 0.5f);

    float t = time * 0.75f;
    float band = sin((uv.x * 4.5f + uv.y * 3.2f) + sin(uv.y * 5.0f - t) * 0.55f - t * 0.9f);
    float sBase = clamp(band * 0.5f + 0.5f, 0.0f, 1.0f);
    float sheen = sBase * sBase * sBase;
    float edgeSoft = sin(uv.x * 3.14159265f) * sin(uv.y * 3.14159265f);

    half3 rgb = color.rgb / max(color.a, half(0.001h));
    half lift = half(sheen * edgeSoft * safeStrength);
    half3 result = clamp(rgb + half3(0.95h, 0.99h, 1.0h) * lift, half3(0.0h), half3(1.0h));

    return half4(result * color.a, color.a);
}

/// Bounding-rect wrapper for layout-neutral SwiftUI View.colorEffect(.boundingRect).
[[stitchable]] half4 meniscusGlowRect(
    float2 position,
    half4 color,
    float4 bounds,
    float time,
    float strength
) {
    return meniscusGlow(position - bounds.xy, color, bounds.zw, time, strength);
}
