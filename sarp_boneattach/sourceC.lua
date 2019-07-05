local bone_0 = {5, 4, 3, 1, 4, 4, 32, 22, 33, 23, 34, 24, 41, 51, 42, 52, 43, 53, 44, 54}
local bone_t = {nil, 5, nil, 2, 32, 22, 33, 23, 34, 24, 35, 25, 42, 52, 43, 53, 42, 52, 43, 53}
local bone_f = {6, 8, 31, 3, 5, 5, 34, 24, 32, 22, 36, 26, 43, 53, 44, 54, 44, 54, 42, 52}

local sx, sy, sz = 0, 0, 3
local tx, ty, tz = 0, 0, 4
local fx, fy, fz = 0, 1, 3

local sqrt, deg, asin, atan2, rad, sin, cos = math.sqrt, math.deg, math.asin, math.atan2, math.rad, math.sin, math.cos

local playerIsMinimized = false

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		triggerServerEvent("requestAttachmentData", getRootElement())
		
		addEvent("attachElementToBone", true)
		addEvent("detachElementFromBone", true)
		addEventHandler("attachElementToBone", getRootElement(), attachElementToBone)
		addEventHandler("detachElementFromBone", getRootElement(), detachElementFromBone)
	end
)

addEventHandler("onClientPreRender", getRootElement(),
	function ()
		if playerIsMinimized then
			return
		end
		
		for element, ped in pairs(attached_ped) do
			if not isElement(element) then
				clearAttachmentData(element)
			elseif isElementStreamedIn(ped) then
				local bone = attached_bone[element]
				local x, y, z = getPedBonePosition(ped, bone_0[bone])
				local xx, xy, xz, yx, yy, yz, zx, zy, zz = getBoneMatrix(ped, bone)
				local offx, offy, offz = attached_x[element], attached_y[element], attached_z[element]
				local offrx, offry, offrz = attached_rx[element], attached_ry[element], attached_rz[element]
				local objx = x + offx * xx + offy * yx + offz * zx
				local objy = y + offx * xy + offy * yy + offz * zy
				local objz = z + offx * xz + offy * yz + offz * zz
				local rxx, rxy, rxz, ryx, ryy, ryz, rzx, rzy, rzz = getMatrixFromEulerAngles(offrx, offry, offrz)

				local txx = rxx * xx + rxy * yx + rxz * zx
				local txy = rxx * xy + rxy * yy + rxz * zy
				local txz = rxx * xz + rxy * yz + rxz * zz
				local tyx = ryx * xx + ryy * yx + ryz * zx
				local tyy = ryx * xy + ryy * yy + ryz * zy
				local tyz = ryx * xz + ryy * yz + ryz * zz
				local tzx = rzx * xx + rzy * yx + rzz * zx
				local tzy = rzx * xy + rzy * yy + rzz * zy
				local tzz = rzx * xz + rzy * yz + rzz * zz
				
				offrx, offry, offrz = getEulerAnglesFromMatrix(txx, txy, txz, tyx, tyy, tyz, tzx, tzy, tzz)
				
				if not isNaN(objx) and not isNaN(objy) and not isNaN(objz) then
					setElementPosition(element, objx, objy, objz)
				end
				
				if not isNaN(offrx) and not isNaN(offry) and not isNaN(offrz) then
					setElementRotation(element, offrx, offry, offrz, "ZXY")
				end
			else
				setElementPosition(element, getElementPosition(ped))
			end
		end
	end
)

addEventHandler("onClientMinimize", getRootElement(),
	function ()
		playerIsMinimized = true
	end
)

addEventHandler("onClientRestore", getRootElement(),
	function ()
		playerIsMinimized = false
	end
)

function getAttachmentData(ped, bone, x, y, z, rx, ry, rz)
	for element, attachToPed in pairs(ped) do
		setElementCollisionsEnabled(element, false)
		
		attached_ped[element] = attachToPed
		attached_bone[element] = bone[element]
		attached_x[element] = x[element]
		attached_y[element] = y[element]
		attached_z[element] = z[element]
		attached_rx[element] = rx[element]
		attached_ry[element] = ry[element]
		attached_rz[element] = rz[element]
	end
end
addEvent("receiveAttachmentData", true)
addEventHandler("receiveAttachmentData", getRootElement(), getAttachmentData)

function isNaN(x)
	return x ~= x
end

function getMatrixFromPoints(x, y, z, x3, y3, z3, x2, y2, z2)
	x3 = x3 - x
	y3 = y3 - y
	z3 = z3 - z
	x2 = x2 - x
	y2 = y2 - y
	z2 = z2 - z
	
	local x1 = y2 * z3 - z2 * y3
	local y1 = z2 * x3 - x2 * z3
	local z1 = x2 * y3 - y2 * x3
	
	x2 = y3 * z1 - z3 * y1
	y2 = z3 * x1 - x3 * z1
	z2 = x3 * y1 - y3 * x1
	
	local len1 = 1 / sqrt(x1 * x1 + y1 * y1 + z1 * z1)
	local len2 = 1 / sqrt(x2 * x2 + y2 * y2 + z2 * z2)
	local len3 = 1 / sqrt(x3 * x3 + y3 * y3 + z3 * z3)
	
	x1 = x1 * len1
	y1 = y1 * len1
	z1 = z1 * len1
	x2 = x2 * len2
	y2 = y2 * len2
	z2 = z2 * len2
	x3 = x3 * len3
	y3 = y3 * len3
	z3 = z3 * len3
	
	return x1, y1, z1, x2, y2, z2, x3, y3, z3
end

function getEulerAnglesFromMatrix(x1, y1, z1, x2, y2, z2, x3, y3, z3)
	local nz1, nz2, nz3
	nz3 = sqrt(x2 * x2 + y2 * y2)
	nz1 = -x2 * z2 / nz3
	nz2 = -y2 * z2 / nz3
	
	local vx = nz1 * x1 + nz2 * y1 + nz3 * z1
	local vz = nz1 * x3 + nz2 * y3 + nz3 * z3
	
	return deg(asin(z2)), -deg(atan2(vx, vz)), -deg(atan2(x2, y2))
end

function getMatrixFromEulerAngles(x, y, z)
	x, y, z = rad(x), rad(y), rad(z)
	local sinx, cosx, siny, cosy, sinz, cosz = sin(x), cos(x), sin(y), cos(y), sin(z), cos(z)
	
	return cosy * cosz - siny * sinx * sinz, cosy * sinz + siny * sinx * cosz, -siny * cosx, -cosx * sinz, cosx * cosz, sinx, siny * cosz + cosy * sinx * sinz, siny * sinz - cosy * sinx * cosz, cosy * cosx
end

if not isFromServerSide then
	function getBoneMatrix(ped, bone)
		local x, y, z, tx, ty, tz, fx, fy, fz
		x, y, z = getPedBonePosition(ped, bone_0[bone])
		
		if bone == 1 then
			local x6, y6, z6 = getPedBonePosition(ped, 6)
			local x7, y7, z7 = getPedBonePosition(ped, 7)
			tx, ty, tz = (x6 + x7) * 0.5, (y6 + y7) * 0.5, (z6 + z7) * 0.5
		elseif bone == 3 then
			local x21, y21, z21 = getPedBonePosition(ped, 21)
			local x31, y31, z31 = getPedBonePosition(ped, 31)
			tx, ty, tz = (x21 + x31) * 0.5, (y21 + y31) * 0.5, (z21 + z31) * 0.5
		else
			tx, ty, tz = getPedBonePosition(ped, bone_t[bone])
		end
		
		fx, fy, fz = getPedBonePosition(ped, bone_f[bone])
		local xx, xy, xz, yx, yy, yz, zx, zy, zz = getMatrixFromPoints(x, y, z, tx, ty, tz, fx, fy, fz)
		
		if bone == 1 or bone == 3 then
			xx, xy, xz, yx, yy, yz = -yx, -yy, -yz, xx, xy, xz
		end
		
		return xx, xy, xz, yx, yy, yz, zx, zy, zz
	end
end