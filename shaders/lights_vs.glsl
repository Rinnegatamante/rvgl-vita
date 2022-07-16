#ifdef USE_LIGHTS

#define LIGHT_OMNI 0
#define LIGHT_OMNINORMAL 1
#define LIGHT_SPOT 2
#define LIGHT_SPOTNORMAL 3
#define LIGHT_SHADOW 4

// lights
uniform int numLights;
uniform float4 lightPos[MAX_LIGHTS];
uniform float4 lightParams[MAX_LIGHTS];
uniform float4 lightDir[MAX_LIGHTS];

#ifdef SHADOW_BOX
// shadow box
uniform int numShadows;
uniform float4 shadowPos[MAX_SHADOWS];
uniform float4 shadowParams[MAX_SHADOWS];
uniform float3x3 shadowDir[MAX_SHADOWS];
#endif  // SHADOW_BOX

float4 ProcessLight(int i, float4 varColor, float4 inPosition, float3 inNormal)
{
  float3 delta = lightPos[i].xyz - inPosition.xyz;
  float reach = lightPos[i].w;
  float dist = dot(delta, delta);
  if (dist < reach) {
    float3 color = lightParams[i].xyz;
    short type = short(lightParams[i].w);
    float scale = 1.0 - (dist / reach);
    dist = sqrt(dist);

    // calc angle from normal if needed
    if (type == LIGHT_OMNINORMAL || type == LIGHT_SPOTNORMAL) {
      float ang = dot(delta, inNormal);
      ang = clamp(ang / dist, 0.0, 1.0);
      scale *= ang;
    }

    // calc cone adjustment if needed
    if (type == LIGHT_SPOT || type == LIGHT_SPOTNORMAL) {
      float cone = -dot(lightDir[i].xyz, delta) / dist - 1.0;
      float conemul = lightDir[i].w;
      cone = cone * conemul + 1.0;
      cone = clamp(cone, 0.0, 1.0);
      scale *= cone;
    }

    varColor.rgb += lerp(float3(0.0), color, scale);
  }
  
  return varColor;
}

#ifdef SHADOW_BOX
int ProcessShadow(int i, float4 inPosition)
{
  float3 delta = shadowPos[i].xyz - inPosition.xyz;
  float3 dist = mul(shadowDir[i], delta);
  float3 size = shadowParams[i].xyz;
  return int(
      all(greaterThan(dist, -size)) && 
      all(lessThan(dist, size)));
}
#endif  // SHADOW_BOX

float4 ProcessLights(float4 varColor, float4 inPosition, float3 inNormal)
{
  for (int i = 0; i < MAX_LIGHTS; ++i) {
    if (i < numLights) {
      varColor = ProcessLight(i, varColor, inPosition, inNormal);
    } else {
      break;
    }
  }

  #ifdef SHADOW_BOX
  int shadowFlag = 0;
  for (int i = 0; i < MAX_SHADOWS; ++i) {
    if (i < numShadows) {
      shadowFlag += ProcessShadow(i, inPosition);
    } else {
      break;
    }
  }
  if (shadowFlag > 0) {
    varColor.rgb += shadowColor;
  }
  #endif  // SHADOW_BOX
  
  return varColor;
}
#endif  // USE_LIGHTS
