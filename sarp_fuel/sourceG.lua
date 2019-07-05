availableStations = {
	[1] = {
		stationDetails = {1001.860168457, -915.00323486328, 42.1796875 + 3.45, -90 + 8},
		pedDetails = {
			name = "Petrol Joe",
			skin = 37,
			position = {1001.6373901367, -912.33361816406, 42.184375762939},
			rotation = 187,
			interior = 0,
			dimension = 0
		},
		syncColShape = {
			details = {1005.0244140625, -937.34375, 42.3515625, 175}
		},
		outerColShape = {
			details = {977.41778564453, -950.47991943359, 49.592590332031, 47.887329101563}
		},
		innerColShape = {
			details = {994.3173828125, -943.6484375, 20, 15}
		},
		priceTable = {
			details = {8246, 1004.9754638672, -948.31744384766, 42.184020996094 + 1.25, 0, 0, 275 - 90}
		},
		fuelPositions = {}
	},
	[2] = {
		stationDetails = {1921.2517089844, -1777.1514892578, 13.3828125 + 3.45, 0},
		pedDetails = {
			name = "Petrol Joe",
			skin = 37,
			position = {1918.5671386719, -1777.0419921875, 13.387500762939},
			rotation = 270,
			interior = 0,
			dimension = 0
		},
		syncColShape = {
			details = {1941.708984375, -1773.28125, 13.390598297119, 175}
		},
		outerColShape = {
			details = {1914.1927490234, -1797.1961669922, 42.518432617188, 39.71044921875}
		},
		innerColShape = {
			details = {1934.8016357422, -1785.1324462891, 10.962768554688, 15.44482421875}
		},
		priceTable = {
			details = {8246, 1951.6265869141, -1763.4243164063, 13.546875 + 1.25, 0, 0, 270 - 90}
		},
		fuelPositions = {}
	},
	[3] = {
		stationDetails = {-1684.2292480469, 423.80813598633, 7.1843748092651 + 3.45, -45},
		pedDetails = {
			name = "Petrol Joe",
			skin = 37,
			position = {-1686.4750976563, 425.34539794922, 7.1890621185303},
			rotation = 225,
			interior = 0,
			dimension = 0
		},
		syncColShape = {
			details = {-1672.6962890625, 408.4580078125, 7.1796875, 175}
		},
		outerColShape = {
			details = {-1672.6962890625, 408.4580078125, 7.1796875, 60}
		},
		innerColShape = {
			details = {-1672.6962890625, 408.4580078125, 7.1796875, 12}
		},
		priceTable = {
			details = {8246, -1679.7556152344, 391.25259399414, 7.1796875 + 1.25, 0, 0, 45}
		},
		fuelPositions = {}
	},
	[4] = {
		stationDetails = {-1599.3199462891, -2701.5258789063, 48.5390625 + 3.45, 232},
		pedDetails = {
			name = "Petrol Joe",
			skin = 36,
			position = {-1597.9281005859, -2699.2192382813, 48.543750762939},
			rotation = 140,
			interior = 0,
			dimension = 0
		},
		syncColShape = {
			details = {-1599.3199462891, -2701.5258789063, 48.5390625, 175}
		},
		outerColShape = {
			details = {-1611.2772216797, -2717.0173339844, 48.825000762939, 60}
		},
		innerColShape = {
			details = {-1611.2772216797, -2717.0173339844, 48.825000762939, 12}
		},
		priceTable = {
			details = {8246, -1595.2563476563, -2741.3732910156, 48.654373168945 + 1.25, 0, 0, 225 + 90}
		},
		fuelPositions = {}
	},
}

if localPlayer then
	function rotateAround(angle, x, y, x2, y2)
		local targetX = x2 or 0
		local targetY = y2 or 0
		local centerX = x
		local centerY = y

		local radiant = math.rad(angle)
		local rotatedX = targetX + (centerX - targetX) * math.cos(radiant) - (centerY - targetY) * math.sin(radiant)
		local rotatedY = targetY + (centerX - targetX) * math.sin(radiant) + (centerY - targetY) * math.cos(radiant)

		return rotatedX, rotatedY
	end

	function createSpline(points, steps)
		if #points < 3 then
			return points
		end

		local spline = {}

		do
			steps = steps or 3
			steps = 1 / steps

			local count = #points - 1
			local p0, p1, p2, p3, x, y, z

			for i = 1, count do
				if i == 1 then
					p0, p1, p2, p3 = points[i], points[i], points[i + 1], points[i + 2]
				elseif i == count then
					p0, p1, p2, p3 = points[#points - 2], points[#points - 1], points[#points], points[#points]
				else
					p0, p1, p2, p3 = points[i - 1], points[i], points[i + 1], points[i + 2]
				end

				for t = 0, 1, steps do
					x = (1 * ((2 * p1[1]) + (p2[1] - p0[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t * t + (3 * p1[1] - p0[1] - 3 * p2[1] + p3[1]) * t * t * t)) * 0.5
					y = (1 * ((2 * p1[2]) + (p2[2] - p0[2]) * t + (2 * p0[2] - 5 * p1[2] + 4 * p2[2] - p3[2]) * t * t + (3 * p1[2] - p0[2] - 3 * p2[2] + p3[2]) * t * t * t)) * 0.5
					z = (1 * ((2 * p1[3]) + (p2[3] - p0[3]) * t + (2 * p0[3] - 5 * p1[3] + 4 * p2[3] - p3[3]) * t * t + (3 * p1[3] - p0[3] - 3 * p2[3] + p3[3]) * t * t * t)) * 0.5

					local splineId = #spline

					if not (splineId > 0 and spline[splineId][1] == x and spline[splineId][2] == y and spline[splineId][3] == z) then
						spline[splineId + 1] = {x, y, z}
					end
				end
			end
		end

		return spline
	end

	function addFuelPoint(stationId, x, y, z, rot)
		local x2 = 0
		local y2 = 0

		local fuelPoint = {}

		rot = ((360 - rot) % 360 - 180) * -1

		fuelPoint.element = createObject(3465, x, y, z, 0, 0, 0 + rot)
		setElementDoubleSided(fuelPoint.element, true)
		setElementData(fuelPoint.element, "isFuelPump", stationId)

		-- ** Oldal 1.
		fuelPoint.drawPosition = {x2 + 0.350, y2 - 0.37, z - 0.275, 1, 0, 0.25}

		local rotatedX, rotatedY = rotateAround(rot, fuelPoint.drawPosition[1], fuelPoint.drawPosition[2])
		fuelPoint.drawPosition[1], fuelPoint.drawPosition[2] = rotatedX + x, rotatedY + y

		rotatedX, rotatedY = rotateAround(rot, fuelPoint.drawPosition[4], fuelPoint.drawPosition[5])
		fuelPoint.drawPosition[4], fuelPoint.drawPosition[5] = rotatedX, rotatedY

		fuelPoint.pistolDetails = {
			{330, x2 + 0.4, y2 + 0.0425, z - 0.275, 0, 90, 0 + rot},
			{330, x2 + 0.4, y2 + 0.55, z - 0.275, 0, 90, 0 + rot},
		}

		fuelPoint.lineStart = {
			{x2 + 0.3, y2 + 0.0425, z - 1.5},
			{x2 + 0.3, y2 + 0.55, z - 1.5},
		}

		fuelPoint.linePositions = {
			{
				{x2 + 0.3, y2 + 0.0425, z - 1.45},
				{x2 + 0.4, y2 + 0.05, z - 1.45},
				{x2 + 0.5, y2 + 0.25, z - 1.4},
				{x2 + 0.6, y2 + 0.125, z - 1.3},
				{x2 + 0.4, y2 + 0.0425, (z - 0.275) + ((z - 1.3) - (z - 0.275)) / 2},
				{x2 + 0.4 - 0.005, y2 + 0.0425, z - 0.275}
			},
			{
				{x2 + 0.3, y2 + 0.55, z - 1.45},
				{x2 + 0.4, y2 + 0.575, z - 1.45},
				{x2 + 0.5, y2 + 0.775, z - 1.4},
				{x2 + 0.6, y2 + 0.65, z - 1.3},
				{x2 + 0.4, y2 + 0.55, (z - 0.275) + ((z - 1.3) - (z - 0.275)) / 2},
				{x2 + 0.4 - 0.005, y2 + 0.55, z - 0.275}
			}
		}

		for i = 1, #fuelPoint.pistolDetails do
			rotatedX, rotatedY = rotateAround(rot, fuelPoint.pistolDetails[i][2], fuelPoint.pistolDetails[i][3])
			fuelPoint.pistolDetails[i][2], fuelPoint.pistolDetails[i][3] = rotatedX + x, rotatedY + y
		end

		for i = 1, #fuelPoint.lineStart do
			rotatedX, rotatedY = rotateAround(rot, fuelPoint.lineStart[i][1], fuelPoint.lineStart[i][2])
			fuelPoint.lineStart[i][1], fuelPoint.lineStart[i][2] = rotatedX + x, rotatedY + y

			if fuelPoint.linePositions[i] then
				for j = 1, #fuelPoint.linePositions[i] do
					rotatedX, rotatedY = rotateAround(rot, fuelPoint.linePositions[i][j][1], fuelPoint.linePositions[i][j][2])
					fuelPoint.linePositions[i][j][1], fuelPoint.linePositions[i][j][2] = rotatedX + x, rotatedY + y
				end

				fuelPoint.linePositions[i] = createSpline(fuelPoint.linePositions[i])
			end
		end

		fuelPoint.colShapeDetails = {x2 + 0.75, y2 + 0.25, z - 0.375, 0.5}
		rotatedX, rotatedY = rotateAround(rot, fuelPoint.colShapeDetails[1], fuelPoint.colShapeDetails[2])
		fuelPoint.colShapeDetails[1], fuelPoint.colShapeDetails[2] = rotatedX + x, rotatedY + y

		fuelPoint.checkRotation = function (angle)
			return angle < 270 + rot and angle > 90 + rot
		end

		table.insert(availableStations[stationId].fuelPositions, fuelPoint)

		-- ** Oldal 2.
		fuelPoint = {}

		fuelPoint.drawPosition = {x2 - 0.350 - 0.025, y2 - 0.37, z - 0.275, -1, 0, 0.25}

		local rotatedX, rotatedY = rotateAround(rot, fuelPoint.drawPosition[1], fuelPoint.drawPosition[2])
		fuelPoint.drawPosition[1], fuelPoint.drawPosition[2] = rotatedX + x, rotatedY + y

		rotatedX, rotatedY = rotateAround(rot, fuelPoint.drawPosition[4], fuelPoint.drawPosition[5])
		fuelPoint.drawPosition[4], fuelPoint.drawPosition[5] = rotatedX, rotatedY

		fuelPoint.pistolDetails = {
			{330, x2 - 0.4 - 0.025, y2 + 0.0425, z - 0.275, 0, 90, 180 + rot},
			{330, x2 - 0.4 - 0.025, y2 + 0.55, z - 0.275, 0, 90, 180 + rot},
		}

		fuelPoint.lineStart = {
			{x2 - 0.3 - 0.025, y2 + 0.0425, z - 1.5},
			{x2 - 0.3 - 0.025, y2 + 0.55, z - 1.5},
		}

		fuelPoint.linePositions = {
			{
				{x2 - 0.3 - 0.025, y2 + 0.0425, z - 1.45},
				{x2 - 0.4 - 0.025, y2 + 0.05, z - 1.45},
				{x2 - 0.5 - 0.025, y2 + 0.25, z - 1.4},
				{x2 - 0.6 - 0.025, y2 + 0.125, z - 1.3},
				{x2 - 0.4 - 0.025, y2 + 0.0425, (z - 0.275) + ((z - 1.3) - (z - 0.275)) / 2},
				{x2 - 0.4 - 0.025 + 0.005, y2 + 0.0425, z - 0.275}
			},
			{
				{x2 - 0.3 - 0.025, y2 + 0.55, z - 1.45},
				{x2 - 0.4 - 0.025, y2 + 0.575, z - 1.45},
				{x2 - 0.5 - 0.025, y2 + 0.775, z - 1.4},
				{x2 - 0.6 - 0.025, y2 + 0.65, z - 1.3},
				{x2 - 0.4 - 0.025, y2 + 0.55, (z - 0.275) + ((z - 1.3) - (z - 0.275)) / 2},
				{x2 - 0.4 - 0.025 + 0.005, y2 + 0.55, z - 0.275}
			}
		}

		for i = 1, #fuelPoint.pistolDetails do
			rotatedX, rotatedY = rotateAround(rot, fuelPoint.pistolDetails[i][2], fuelPoint.pistolDetails[i][3])
			fuelPoint.pistolDetails[i][2], fuelPoint.pistolDetails[i][3] = rotatedX + x, rotatedY + y
		end

		for i = 1, #fuelPoint.lineStart do
			rotatedX, rotatedY = rotateAround(rot, fuelPoint.lineStart[i][1], fuelPoint.lineStart[i][2])
			fuelPoint.lineStart[i][1], fuelPoint.lineStart[i][2] = rotatedX + x, rotatedY + y

			if fuelPoint.linePositions[i] then
				for j = 1, #fuelPoint.linePositions[i] do
					rotatedX, rotatedY = rotateAround(rot, fuelPoint.linePositions[i][j][1], fuelPoint.linePositions[i][j][2])
					fuelPoint.linePositions[i][j][1], fuelPoint.linePositions[i][j][2] = rotatedX + x, rotatedY + y
				end

				fuelPoint.linePositions[i] = createSpline(fuelPoint.linePositions[i])
			end
		end

		fuelPoint.colShapeDetails = {x2 - 0.75 - 0.025, y2 + 0.25, z - 0.375, 0.5}
		rotatedX, rotatedY = rotateAround(rot, fuelPoint.colShapeDetails[1], fuelPoint.colShapeDetails[2])
		fuelPoint.colShapeDetails[1], fuelPoint.colShapeDetails[2] = rotatedX + x, rotatedY + y

		fuelPoint.checkRotation = function (angle)
			return not (angle < 270 + rot) or not (angle > 90 + rot)
		end

		table.insert(availableStations[stationId].fuelPositions, fuelPoint)
	end

	addFuelPoint(1, 1006.95, -934.15, 42.465625762939 + 0.5, 278)
	addFuelPoint(1, 1002, -934.85, 42.465625762939 + 0.5, 278)
	
	addFuelPoint(2, 1940.95, -1774.75, 13.668750762939 + 0.5, 180)
	addFuelPoint(2, 1940.95, -1779.75, 13.668750762939 + 0.5, 180)

	addFuelPoint(3, -1671.6778564453, 408.6171875, 7.4703121185303 + 0.5, 225 - 90)
	addFuelPoint(3, -1668.8273925781, 411.43661499023, 7.4703121185303 + 0.5, 225 - 90)

	addFuelPoint(4, -1613.4952392578, -2715.4079589844, 48.825000762939 + 0.5, 50)
	addFuelPoint(4, -1609.8369140625, -2718.2448730469, 48.825000762939 + 0.5, 50)

	wheelSide = {
		bh = "wheel_lb_dummy",
		jh = "wheel_rb_dummy",
		je = "wheel_rf_dummy",
		be = "wheel_lf_dummy"
	}

	centerFilling = {
		[448] = true,
		[461] = true,
		[462] = true,
		[463] = true,
		[468] = true,
		[471] = true,
		[521] = true,
		[522] = true,
		[523] = true,
		[581] = true,
		[586] = true
	}

	defaultFuelSide = "jh"
	fuelSides = {
		-- Lehetőségek: "bh" (bal hátsó); "jh" (jobb hátsó); "je" (jobb első); "be" (bal első); {x, y} => koordináta ha a tanksapkához / custom helyre akarod
		[123] = "jh",
		[505] = {1.5, -0.65},
	}

	defaultFuelType = "p"
	vehicleFuelTypes = {
		-- Típusok: d => dízel; p => benzin, e => elektromos(ha van)
		[505] = "d"
	}
end