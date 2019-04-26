//#gljs varname: 'iProov.webgl.shader.suppression.fragment', type: 'fragment'

uniform sampler2D tDiffuse;
uniform highp float texelWidth;
uniform highp float texelHeight;
uniform mediump float upperThreshold;
uniform mediump float lowerThreshold;

varying highp vec2 vUv;

void main() {

    vec3 currentGradientAndDirection = texture2D(tDiffuse, vUv).rgb;
    vec2 gradientDirection = ((currentGradientAndDirection.gb * 2.0) - 1.0) * vec2(texelWidth, texelHeight);

    float firstSampledGradientMagnitude = texture2D(tDiffuse, vUv + gradientDirection).r;
    float secondSampledGradientMagnitude = texture2D(tDiffuse, vUv - gradientDirection).r;

    float multiplier = step(firstSampledGradientMagnitude, currentGradientAndDirection.r);
    multiplier = multiplier * step(secondSampledGradientMagnitude, currentGradientAndDirection.r);

    float thresholdCompliance = smoothstep(lowerThreshold, upperThreshold, currentGradientAndDirection.r);
    multiplier = multiplier * thresholdCompliance;

    gl_FragColor = vec4(multiplier, multiplier, multiplier, 1.0);

}
