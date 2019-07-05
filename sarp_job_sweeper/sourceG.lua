jobData = {
	containers = {},
	innerColShape = {
		details = {1673.4025878906, -1882.1429443359, 1610.8414306641, -1882.1446533203, 1610.8515625, -1897.5834960938, 1628.6807861328, -1897.8757324219, 1628.6850585938, -1912.8264160156, 1661.7897949219, -1904.6693115234, 1673.2664794922, -1904.7491455078, 1673.4025878906, -1882.1429443359}
	}
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
			local steps = steps or 5
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

				for t = 0, 1, 1 / steps do
					x = (1 * ((2 * p1[1]) + (p2[1] - p0[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t * t + (3 * p1[1] - p0[1] - 3 * p2[1] + p3[1]) * t * t * t)) * 0.5
					y = (1 * ((2 * p1[2]) + (p2[2] - p0[2]) * t + (2 * p0[2] - 5 * p1[2] + 4 * p2[2] - p3[2]) * t * t + (3 * p1[2] - p0[2] - 3 * p2[2] + p3[2]) * t * t * t)) * 0.5
					z = (1 * ((2 * p1[3]) + (p2[3] - p0[3]) * t + (2 * p0[3] - 5 * p1[3] + 4 * p2[3] - p3[3]) * t * t + (3 * p1[3] - p0[3] - 3 * p2[3] + p3[3]) * t * t * t)) * 0.5

					if not (#spline > 0 and spline[#spline][1] == x and spline[#spline][2] == y and spline[#spline][3] == z) then
						spline[#spline + 1] = {x, y, z}
					end
				end
			end
		end

		return spline
	end

	function addContainerPoint(type, x, y, z, rot)
		local x2 = 0
		local y2 = 0
		local data = {}

		data.element = createObject(3287, x, y, z, 0, 0, 0 + rot)
		data.type = type

		data.materialPosition = {x2 - 2, y2 - 2.1, z - 3.75}
		local rotatedX, rotatedY = rotateAround(rot, data.materialPosition[1], data.materialPosition[2])
		data.materialPosition[1], data.materialPosition[2] = rotatedX + x, rotatedY + y

		data.colShapeDetails = {x2 - 2.5, y2 - 2.1, z - 4, 1.25}
		rotatedX, rotatedY = rotateAround(rot, data.colShapeDetails[1], data.colShapeDetails[2])
		data.colShapeDetails[1], data.colShapeDetails[2] = rotatedX + x, rotatedY + y

		table.insert(jobData.containers, data)
	end

	addContainerPoint("water", 1671.8000488281, -1884.1999511719, 17.299999237061, 0)
	addContainerPoint("sewage", 1671.6999511719, -1892.5, 17.299999237061, 0)
end