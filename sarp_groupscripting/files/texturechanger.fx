texture gTexture;

technique hello
{
    pass P0
    {
        Texture[0] = gTexture;
        AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
    }
}
