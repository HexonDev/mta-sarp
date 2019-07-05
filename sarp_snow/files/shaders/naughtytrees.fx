texture noiseTexture;

#include "mta-helper.fx"

sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
};

sampler3D SamplerNoise = sampler_state
{
   Texture = (noiseTexture);
   MAGFILTER = LINEAR;
   MINFILTER = LINEAR;
   MIPFILTER = LINEAR;
   MIPMAPLODBIAS = 0.000000;
};

struct VSInput
{
  float3 Position : POSITION0;
  float3 Normal : NORMAL0;
  float4 Diffuse : COLOR0;
  float2 TexCoord : TEXCOORD0;
};

struct PSInput
{
  float4 Position : POSITION0;
  float4 Diffuse : COLOR0;
  float2 TexCoord : TEXCOORD0;
  float2 NoiseCoord : TEXCOORD1;
};

PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;

    MTAFixUpNormal( VS.Normal );

    PS.Position = MTACalcScreenPosition ( VS.Position );
    PS.TexCoord = VS.TexCoord;
    PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );

    float3 WorldPos = MTACalcWorldPosition( VS.Position );
    PS.NoiseCoord.x = WorldPos.x / 48;
    PS.NoiseCoord.y = WorldPos.y / 48;

    if ( PS.Diffuse.r < 0.25 )
    {
        float amount = MTAUnlerp( 0.25, 0.15, PS.Diffuse.r ) * 0.2;
        PS.Diffuse.rgb += float3(amount,amount,amount);
    }
	
    return PS;
}

float4 PixelShaderFunction(PSInput PS) : COLOR0
{
    float4 texel = tex2D(Sampler0, PS.TexCoord);
    float3 texelNoise = tex3D(SamplerNoise, float3(PS.NoiseCoord.xy,1)).rgb;
    float4 texelSnow = texel.g * 2 + 0.2;
    float amount = texelNoise.y * texelNoise.y * 3;
    float4 finalColor = lerp( texel, texelSnow, amount );

    finalColor = finalColor * PS.Diffuse;
    finalColor.a = texel.a * PS.Diffuse.a;
	
    return finalColor;
}

technique snowtrees
{
    pass P0
    {
        VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}

technique fallback
{
    pass P0
    {
        // Fallbacking
    }
}