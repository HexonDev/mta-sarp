
local myShader, tec
local timer

function switchWaterShader(state)
	if state then
		if getVersion ().sortable < "1.1.0" then
			outputChatBox( "Resource is not compatible with this client." )
			return
		end

		-- Create shader
		myShader, tec = dxCreateShader ( "assets/water.fx" )

		if not myShader then
			--outputChatBox( "Could not create shader. Please use debugscript 3" )
		else
			outputChatBox( "Using technique " .. tec )

			-- Set textures
			local textureVol = dxCreateTexture ( "assets/smallnoise3d.dds" );
			local textureCube = dxCreateTexture ( "assets/cube_env256.dds" );
			dxSetShaderValue ( myShader, "sRandomTexture", textureVol );
			dxSetShaderValue ( myShader, "sReflectionTexture", textureCube );

			-- Apply to global txd 13
			engineApplyShaderToWorldTexture ( myShader, "waterclear256" )

			-- Update water color incase it gets changed by persons unknown
			timer = setTimer(	
				function()
					if myShader then
						local r,g,b,a = getWaterColor()
						dxSetShaderValue ( myShader, "sWaterColor", r/255, g/255, b/255, a/255 );
					end
				end
			,100,0 )
		end
	else
		killTimer(timer)
		destroyElement(myShader)
	end
end
