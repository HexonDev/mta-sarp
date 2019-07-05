//
// wall_mrt.fx
//

//------------------------------------------------------------------------------------------
// Variables
//------------------------------------------------------------------------------------------
float4 sColorizePed = float4(1,1,1,1);

//------------------------------------------------------------------------------------------
// Include some common stuff
//------------------------------------------------------------------------------------------
texture gTexture0 < string textureState="0,Texture"; >;
float4x4 gWorld : WORLD;
float4x4 gView : VIEW;
float4x4 gWorldView : WORLDVIEW;
float4x4 gProjection: PROJECTION;
float3 gCameraDirection : CAMERADIRECTION;
float3 gCameraPosition : CAMERAPOSITION;
int CUSTOMFLAGS < string skipUnusedParameters = "yes"; >;
texture secondRT < string renderTarget = "yes"; >;

//------------------------------------------------------------------------------------------
// Sampler Inputs
//------------------------------------------------------------------------------------------
sampler ColorSampler = sampler_state
{
    Texture = (gTexture0);
};

//------------------------------------------------------------------------------------------
// Structure of data sent to the pixel shader ( from the vertex shader )
//------------------------------------------------------------------------------------------
struct PSInput
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float4 Diffuse : COLOR0;
};

//------------------------------------------------------------------------------------------
// Structure of color data sent to the renderer ( from the pixel shader
//------------------------------------------------------------------------------------------
struct Pixel
{
    float4 Color : COLOR0;      // Render target #0
    float4 Extra : COLOR1;      // Render target #1
};

//------------------------------------------------------------------------------------------
// PixelShaderFunction
//------------------------------------------------------------------------------------------
Pixel PixelShaderFunction(PSInput PS)
{
    Pixel output;
    float texelAlpha = tex2D(ColorSampler, PS.TexCoord.xy).a;	
    output.Color = float4(0, 0, 0, min(texelAlpha * PS.Diffuse.a, 0.006105));
    output.Extra = float4(sColorizePed.rgb, texelAlpha * sColorizePed.a);
	
    return output;
}

//------------------------------------------------------------------------------------------
// Techniques
//------------------------------------------------------------------------------------------
technique ped_wall_mrt
{
    pass P0
    {
        ZEnable = true;
        AlphaBlendEnable = true;
        AlphaRef = 1;
        PixelShader  = compile ps_2_0 PixelShaderFunction();
    }
}

// Fallback
technique fallback
{
    pass P0
    {
        // Just draw normally
    }
}
