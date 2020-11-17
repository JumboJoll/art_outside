uniform mat4 texMatrix;

uniform float fraction;
uniform float frameCount;

attribute vec4 position;
attribute vec4 color;
attribute vec3 normal;
attribute vec2 texCoord;

uniform mat4 projection;
uniform mat4 modelview;

varying vec4 vertColor;
varying vec4 vertTexCoord;

void main(){
    vec4 positionVec4=position;
    positionVec4.w=1.;
    float frequency=20.;
    float amplitude=.2;
    float distortion=sin(positionVec4.x*frequency+(fraction*frameCount*.1));
    positionVec4+=distortion*amplitude;
    
    gl_Position=projection*modelview*positionVec4;
    
    vertColor=color;
    vertTexCoord=texMatrix*vec4(texCoord,1.,1.);
}
