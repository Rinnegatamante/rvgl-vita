#define SCREEN

void main(
	float4 inPosition,
	float4 inColor,
	float2 inTexCoord,
	float4 out varColor : TEXCOORD0,
	float2 out varTexCoord : TEXCOORD1,
	float4 out gl_Position : POSITION
) {
  varColor = inColor;
  varTexCoord = inTexCoord;

  // set position
  gl_Position = inPosition;
}
