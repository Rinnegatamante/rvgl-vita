// textures
uniform sampler2D diffuseTexture;
#ifdef USE_ENV
uniform sampler2D envTexture;
#endif  // USE_ENV

// constants
uniform float3 shadowColor;
uniform float3 fogColor;
uniform float2 fogParams;

// params
uniform float3 envColor;

float4 main(
	float2 varTexCoord : TEXCOORD1,
#ifdef USE_ENV
	float2 varEnvCoord : TEXCOORD2,
#endif
#ifdef USE_FOG
	float2 varFogCoord : TEXCOORD3,
#endif
	float4 varColor : TEXCOORD0
) {
  float4 diffuse = tex2D(diffuseTexture, varTexCoord);
  #ifdef ALPHA_TEST
  if (diffuse.a < 0.5) {
    discard;
  }
  #endif  // ALPHA_TEST
  float4 outColor = varColor * diffuse;

  #ifdef USE_ENV
  float3 specular = tex2D(envTexture, varEnvCoord).rgb;
  outColor.rgb += envColor * specular;
  #endif  // USE_ENV

  #ifdef USE_FOG
  float2 fog = clamp(varFogCoord, 0.0, 1.0);
  outColor.rgb = lerp(fogColor, outColor.rgb, fog.x - fog.y);
  #endif  // USE_FOG
  return outColor;
}
