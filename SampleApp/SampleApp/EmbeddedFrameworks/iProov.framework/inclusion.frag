//#gljs varname: 'iProov.webgl.shader.inclusion.fragment', type: 'fragment'

uniform sampler2D tDiffuse;
uniform vec2 uWindow;
uniform float threshold;

varying vec2 vUv;

void main() {

    vec2 offset = threshold / uWindow;

    float bottomLeftIntensity = texture2D(tDiffuse, vUv + vec2(-offset.x, offset.y)).r;
    float topRightIntensity = texture2D(tDiffuse, vUv + vec2(offset.x, -offset.y)).r;
    float topLeftIntensity = texture2D(tDiffuse, vUv + vec2(-offset.x, -offset.y)).r;
    float bottomRightIntensity = texture2D(tDiffuse, vUv + vec2(offset.x, offset.y)).r;
    float leftIntensity = texture2D(tDiffuse, vUv + vec2(-offset.x, 0.0)).r;
    float rightIntensity = texture2D(tDiffuse, vUv + vec2(offset.x, 0.0)).r;
    float bottomIntensity = texture2D(tDiffuse, vUv + vec2(0.0, offset.y)).r;
    float topIntensity = texture2D(tDiffuse, vUv + vec2(0.0, -offset.y)).r;
    float centerIntensity = texture2D(tDiffuse, vUv).r;

    float pixelIntensitySum = bottomLeftIntensity + topRightIntensity + topLeftIntensity + bottomRightIntensity + leftIntensity + rightIntensity + bottomIntensity + topIntensity + centerIntensity;
    float sumTest = step(1.5, pixelIntensitySum);
    float pixelTest = step(0.01, centerIntensity);

    gl_FragColor = vec4(vec3(sumTest * pixelTest, sumTest * pixelTest, sumTest * pixelTest), 1.0);

}
