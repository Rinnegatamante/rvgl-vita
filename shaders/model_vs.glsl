#define MODEL

// constants
uniform float3 shadowColor;
uniform float3 fogColor;
uniform float2 fogParams;

// params
uniform float4 modelUpVec;
uniform float4 effectParams;
uniform float3 mirrorParams;
uniform float alphaRef;
uniform float3 tint;
uniform float3 envColor;
uniform float3 envMatX;
uniform float3 envMatY;

// projection matrix
uniform float4x4 matViewProj;
uniform float3 cameraPos;
uniform float3 cameraUpVec;

#ifdef USE_LIGHTS
float4 ProcessLights(float4 varColor, float4 inPosition, float3 inNormal);
#endif  // USE_LIGHTS
#ifdef USE_EFFECTS
void ProcessEffects(inout float4 pos, float4 inPosition, float3 inNormal, float2 inTexCoord, inout float2 varTexCoord, inout float4 varColor);
#endif  // USE_EFFECTS

void main(
	float4 inPosition,
	float4 inColor,
	float2 inTexCoord,
	float inFogCoord,
	float3 inNormal,
	float4 out varColor : TEXCOORD0,
	float2 out varTexCoord : TEXCOORD1,
#ifdef USE_ENV
	float2 out varEnvCoord : TEXCOORD2,
#endif
#ifdef USE_FOG
	float2 out varFogCoord : TEXCOORD3,
#endif
	float4 out gl_Position : POSITION,
	float out gl_PointSize : PSIZE
) {
  float4 pos = inPosition;

  varColor = inColor;
  varTexCoord = inTexCoord;

  #ifdef USE_EFFECTS
  // process effects
  ProcessEffects(pos, inPosition, inNormal, inTexCoord, varTexCoord, varColor);
  #endif  // USE_EFFECTS

  // calc position
  gl_Position = mul(matViewProj, pos);

  #ifdef USE_ENV
  // calc env tex coords
  #ifdef GOOD_ENV
  float3 vecz = normalize(pos.xyz - cameraPos);
  float3 vecx = cross(cameraUpVec, vecz);
  float3 vecy = cross(vecz, vecx);
  varEnvCoord.x = dot(inNormal, vecx) * 0.5 + 0.5;
  varEnvCoord.y = dot(inNormal, vecy) * 0.5 + 0.5;
  #else
  varEnvCoord.x = dot(inNormal, envMatX) + 0.5;
  varEnvCoord.y = dot(inNormal, envMatY) + 0.5;
  #endif  // GOOD_ENV
  #endif  // USE_ENV

  #ifdef USE_FOG
  // is it in fog?
  float fogEnd = fogParams.x;
  float fogMul = fogParams.y;
  #ifdef MIRROR_FOG
  float mirrorHeight = mirrorParams.x;
  float mirrorMul = mirrorParams.y;
  float mirrorAdd = mirrorParams.z;
  float vertFog = dot(pos, modelUpVec);
  vertFog = mirrorHeight - vertFog;
  vertFog *= mirrorMul;
  vertFog += mirrorAdd;
  #else
  float vertFog = inFogCoord;
  #endif  // MIRROR_FOG
  varFogCoord.x = (fogEnd - gl_Position.w) * fogMul;
  varFogCoord.y = vertFog;
  #endif  // USE_FOG

  #ifdef USE_LIGHTS
  // process lights
  varColor = ProcessLights(varColor, inPosition, inNormal);
  #endif  // USE_LIGHTS

  #ifdef USE_EFFECTS
  // add any tinting
  varColor.rgb += tint;
  #endif  // USE_EFFECTS

  // clamp the color
  varColor = clamp(varColor, 0.0, 1.0);
  gl_PointSize = 1.0f;
}
