//#gljs varname: 'iProov.webgl.shader.blur.fragment', type: 'fragment'

uniform sampler2D tDiffuse;
uniform float h;

varying vec2 vUv;

void main() {
    
    vec4 sum = vec4( 0.0 );
    
    sum += texture2D( tDiffuse, vec2( vUv.x - 4.0 * h, vUv.y ) ) * 0.0276305489;
    sum += texture2D( tDiffuse, vec2( vUv.x - 3.0 * h, vUv.y ) ) * 0.0662822425;
    sum += texture2D( tDiffuse, vec2( vUv.x - 2.0 * h, vUv.y ) ) * 0.123831533;
    sum += texture2D( tDiffuse, vec2( vUv.x - 1.0 * h, vUv.y ) ) * 0.180173814;
    sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y ) ) * 0.204163685;
    sum += texture2D( tDiffuse, vec2( vUv.x + 1.0 * h, vUv.y ) ) * 0.180173814;
    sum += texture2D( tDiffuse, vec2( vUv.x + 2.0 * h, vUv.y ) ) * 0.123831533;
    sum += texture2D( tDiffuse, vec2( vUv.x + 3.0 * h, vUv.y ) ) * 0.0662822425;
    sum += texture2D( tDiffuse, vec2( vUv.x + 4.0 * h, vUv.y ) ) * 0.0276305489;
    
    gl_FragColor = sum;
    
}
