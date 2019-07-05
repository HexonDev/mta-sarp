float2 sRes = float2(800,600);
float edgeStr = 2;
float outlStreng = 1;
texture sTex0;

sampler Sampler0 = sampler_state
{
	Texture = <sTex0>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Mirror;
	AddressV = Mirror;
};


float4 PixelShaderFunction(float2 TexCoord : TEXCOORD0) : COLOR0
{
	float4 Sample = tex2D(Sampler0, TexCoord);

	float4 lum = float4(0.3, 0.6, 0.1, 1);
 
	float s11 = dot(tex2D(Sampler0, TexCoord + edgeStr * float2(-1.0f / sRes.x, -1.0f / sRes.y)), lum);
	float s12 = dot(tex2D(Sampler0, TexCoord + edgeStr * float2(0, -1.0f / sRes.y)), lum);
	float s13 = dot(tex2D(Sampler0, TexCoord + edgeStr * float2(1.0f / sRes.x, -1.0f / sRes.y)), lum);
 
	float s21 = dot(tex2D(Sampler0, TexCoord + edgeStr * float2(-1.0f / sRes.x, 0)), lum);
	float s23 = dot(tex2D(Sampler0, TexCoord + edgeStr * float2(-1.0f / sRes.x, 0)), lum);
 
	float s31 = dot(tex2D(Sampler0, TexCoord + edgeStr * float2(-1.0f / sRes.x, 1.0f / sRes.y)), lum);
	float s32 = dot(tex2D(Sampler0, TexCoord + edgeStr * float2(0, 1.0f / sRes.y)), lum);
	float s33 = dot(tex2D(Sampler0, TexCoord + edgeStr * float2(1.0f / sRes.x, 1.0f / sRes.y)), lum);

	float t1 = s13 + s33 + (2 * s23) - s11 - (2 * s21) - s31;
	float t2 = s31 + (2 * s32) + s33 - s11 - (2 * s12) - s13;
 
	float4 OutLine;
 
	if (((t1 * t1) + (t2 * t2)) > outlStreng/10) {
		OutLine = 1;
	} else {
		OutLine = 0;
	}

	float4 finalColor = Sample * OutLine;
	
	return finalColor;
}
 
technique edge
{
	pass Pass1
	{
		SrcBlend = SrcAlpha;
		DestBlend = One;
		PixelShader = compile ps_2_0 PixelShaderFunction();
	}
}
