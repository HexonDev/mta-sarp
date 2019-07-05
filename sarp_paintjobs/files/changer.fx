texture newTexture : TEXTURE;

technique replaceTexture
{
    pass P0
	{
        Texture[0] = newTexture;
    }
}