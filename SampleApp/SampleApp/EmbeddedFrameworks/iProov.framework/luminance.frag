//#gljs varname: 'iProov.webgl.shader.luminance.fragment', type: 'fragment'

const vec3 W = vec3(0.2125, 0.7154, 0.0721);

uniform sampler2D tDiffuse;

varying vec2 vUv;

void main() {

    vec4 textureColor = texture2D(tDiffuse, vUv);
    float luminance = dot(textureColor.rgb, W);

    gl_FragColor = vec4(vec3(luminance), textureColor.a);

}
