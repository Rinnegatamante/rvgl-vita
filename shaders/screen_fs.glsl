// textures
uniform sampler2D diffuseTexture;

float4 main(
	float4 varColor : TEXCOORD0,
	float2 varTexCoord : TEXCOORD1
) {
  float4 diffuse = tex2D(diffuseTexture, varTexCoord);
  #ifdef ALPHA_TEST
  if (diffuse.a < 0.5) {
    discard;
  }
  #endif  // ALPHA_TEST
  return varColor * diffuse;
}
