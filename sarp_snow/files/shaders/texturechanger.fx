texture newTexture : TEXTURE;

technique TextureReplace
{
    pass P0
	{
        Texture[0] = newTexture;
    }
}