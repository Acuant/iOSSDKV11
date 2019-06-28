//#gljs varname: 'iProov.webgl.shader.sobel.fragment', type: 'fragment'

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

    vec2 gradientDirection;
    gradientDirection.x = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
    gradientDirection.y = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;

    float gradientMagnitude = length(gradientDirection);
    vec2 normalizedDirection = normalize(gradientDirection);

    normalizedDirection = sign(normalizedDirection) * floor(abs(normalizedDirection) + 0.617316); // Offset by 1-sin(pi/8) to set to 0 if near axis, 1 if away
    normalizedDirection = (normalizedDirection + 1.0) * 0.5; // Place -1.0 - 1.0 within 0 - 1.0

    gl_FragColor = vec4(gradientMagnitude, normalizedDirection.x, normalizedDirection.y, 1.0);
    //gl_FragColor = vec4(gradientMagnitude, gradientMagnitude, gradientMagnitude, 1.0); // Normal edge detection version
}
