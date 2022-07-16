#ifdef USE_EFFECTS

#define EFFECT_FADE 0
#define EFFECT_GHOST 1
#define EFFECT_SPLASH 2
#define EFFECT_CHROME 3
#define EFFECT_UV 4

#define MESHFX_WATERBOX 0
#define MESHFX_SHOCKWAVE 1
#define MESHFX_BOMB 2

#ifdef MESH_EFFECTS
// effect tables
uniform float wboxSineTable[9];

// mesh effects
uniform int numMeshFx;
uniform float4 meshFxParams1[MAX_MESHFX];
uniform float4 meshFxParams2[MAX_MESHFX];
#endif  // MESH_EFFECTS

#ifdef MESH_EFFECTS
void ProcessWaterboxEffect(inout float4 pos, int i, float4 inPosition)
{
  float3 bboxMin = meshFxParams1[i].xyz;
  float3 bboxMax = meshFxParams2[i].xyz;

  if (all(greaterThan(inPosition.xyz, bboxMin)) && 
      all(lessThan(inPosition.xyz, bboxMax))) {
    short hash = short(abs(inPosition.x * inPosition.z));
    float3 delta = float3(
        wboxSineTable[Mod(hash+0, 9)], 
        wboxSineTable[Mod(hash+3, 9)] + 6.0, 
        wboxSineTable[Mod(hash+6, 9)]);
    #ifdef MODEL
    delta *= 0.2;
    #endif  // MODEL
    pos.xyz += delta;
  }
}

void ProcessShockwaveEffect(inout float4 pos, int i)
{
  float3 objPos = meshFxParams1[i].xyz;
  float reach = meshFxParams1[i].w;

  float3 delta = pos.xyz - objPos;
  float dist = dot(delta, delta);
  if (dist < reach * reach) {
    dist = sqrt(dist);
    float pull = (reach - dist) * 0.1;
    pull = min(pull, dist * 0.5);
    pos.xyz -= delta * (pull / dist);
  }
}

void ProcessBombEffect(inout float4 pos, int i)
{
  float3 objPos = meshFxParams1[i].xyz;
  float reach = meshFxParams1[i].w;
  float timeStep = meshFxParams2[i].x;

  float3 delta = pos.xyz - objPos;
  float dist = dot(delta, delta);
  dist = sqrt(dist);
  float scale = (0.5 - timeStep) / 0.5;
  float push = (64.0 - abs(reach - dist)) * scale;
  pos.xyz += delta * (max(push, 0.0) / dist);
}

void ProcessMeshEffect(inout float4 pos, int i, float4 inPosition)
{
  short type = short(meshFxParams2[i].w);

  if (type == MESHFX_WATERBOX) {
    ProcessWaterboxEffect(pos, i);
  } else if (type == MESHFX_SHOCKWAVE) {
    ProcessShockwaveEffect(pos, i);
  } else if (type == MESHFX_BOMB) {
    ProcessBombEffect(pos, i);
  }
}
#endif  // MESH_EFFECTS

#ifdef MODEL_EFFECT
#if (MODEL_EFFECT == EFFECT_FADE)
void ProcessFadeEffect(inout float4 pos, inout float4 varColor)
{
  float timeStep = effectParams.x;
  varColor.a = 1.0 - timeStep;
}

#elif (MODEL_EFFECT == EFFECT_GHOST)
void ProcessGhostEffect(inout float4 pos, inout float4 varColor)
{
  float ghostPos = effectParams.x;
  float ghostMul = effectParams.y;
  varColor.a = abs((pos.z + ghostPos) * ghostMul);
  varColor.a = 1.0 - varColor.a;
}

#elif (MODEL_EFFECT == EFFECT_SPLASH)
void ProcessSplashEffect(inout float4 pos, float4 inPosition, float3 inNormal, inout float4 varColor, inout float2 varTexCoord)
{
  float timeStep = effectParams.x;
  float frame = inPosition.w * timeStep;
  if (frame < 16.0) {
    float grav = 384.0 * timeStep;
    float3 vel = inNormal;
    vel.y += grav;
    pos.xyz += vel * timeStep;
    pos.w = 1.0;

    float rgb = (16.0 - frame) / 32.0;
    varColor.rgb = float3(rgb);
    varTexCoord.x += floor(frame) / 16.0;
  }
}

#elif (MODEL_EFFECT == EFFECT_CHROME)
void ProcessChromeEffect(inout float4 pos, float3 inNormal, inout float2 varTexCoord)
{
  varTexCoord.x = dot(inNormal, envMatX) + 0.5;
  varTexCoord.y = dot(inNormal, envMatY) + 0.6;
}

#elif (MODEL_EFFECT == EFFECT_UV)
void ProcessUVEffect(inout float4 pos, float2 inTexCoord, inout float2 varTexCoord)
{
  float timeStep = effectParams.x;
  float time = inTexCoord.x;
  float add = inTexCoord.y;
  time += add * timeStep;

  float3 texCoord = effectParams.yzw;
  varTexCoord.x = sin(time) * texCoord.x + texCoord.y;
  varTexCoord.y = cos(time) * texCoord.x + texCoord.z;
}
#endif

void ProcessModelEffect(inout float4 pos, float4 inPosition, float3 inNormal, float2 inTexCoord, inout float2 varTexCoord, inout float4 varColor)
{
  #if (MODEL_EFFECT == EFFECT_FADE)
  ProcessFadeEffect(pos, varColor);
  #elif (MODEL_EFFECT == EFFECT_GHOST)
  ProcessGhostEffect(pos, varColor);
  #elif (MODEL_EFFECT == EFFECT_SPLASH)
  ProcessSplashEffect(pos, inPosition, inNormal, varColor, varTexCoord);
  #elif (MODEL_EFFECT == EFFECT_CHROME)
  ProcessChromeEffect(pos, inNormal, varTexCoord);
  #elif (MODEL_EFFECT == EFFECT_UV)
  ProcessUVEffect(pos, inTexCoord, varTexCoord);
  #endif
}
#endif  // MODEL_EFFECT

void ProcessEffects(inout float4 pos, float4 inPosition, float3 inNormal, float2 inTexCoord, inout float2 varTexCoord, inout float4 varColor)
{
  #ifdef MESH_EFFECTS
  for (int i = 0; i < MAX_MESHFX; ++i) {
    if (i < numMeshFx) {
      ProcessMeshEffect(pos, i, inPosition);
    } else {
      break;
    }
  }
  #endif  // MESH_EFFECTS

  #ifdef MODEL_EFFECT
  ProcessModelEffect(pos, inPosition, inNormal, inTexCoord, varTexCoord, varColor);
  #endif  // MODEL_EFFECT
}
#endif  // USE_EFFECTS
