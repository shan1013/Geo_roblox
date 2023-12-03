--DEFINE 

print("START_GEOTerrain")
--#DEFINE
local LOAD_DATA_OTM		= true
local LOAD_TERRAIN		= false
local LOAD_BUILDINGS		= false
local LOAD_ROADS			= false
local LOAD_POINTS		= false
local LOAD_OSM			= true
local COEFF				= 4  -- 4 units in 1 meter
local SHOW_PLAYER_INFO	= true
local TERRAIN_HIGHT		= 50
local FLOOR_WIDTH		= 2.8 -- meters

--local l, b, r, t = 8.38498, 49.01212, 8.40052	, 49.01898;
--local l, b, r, t = 8.39150, 49.02000, 8.40000, 49.02030; --klein
--local l, b, r, t = 7.9460, 46.3040, 7.9824, 46.3184; -- Mountains

local l, b, r, t = 35.12396, 48.40579, 35.14217, 48.41298; -- Test UA
--local l, b, r, t = 11.0762, 42.2340, 11.1491, 42.2660; -- Test island
--local l, b, r, t = 8.39056, 49.01417, 8.39832, 49.01772; -- Test HKA
--local l, b, r, t = 8.39469, 49.01516, 8.39924, 49.01694; -- Test HKA SH
--local l, b, r, t = 8.38268, 49.02199, 8.39178, 49.02554; -- Test FHd
--local l, b, r, t = 8.40302, 49.01574, 8.40758, 49.01751; -- Test Klein
local l, b, r, t = 8.40246, 49.01254, 8.40701, 49.01431; -- Schloss
--local l, b, r, t = 8.3736, 48.9967, 8.4465, 49.0251; -- KA

--[[
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

-- Create a new toolbar section titled "Custom Script Tools"
local toolbar = plugin:CreateToolbar("Custom Script Tools")

-- Add a toolbar button named "Create Empty Script"
local newScriptButton = toolbar:CreateButton("CreateGEO", "CreateGEO", "rbxassetid://14978048121")

-- Make button clickable even if 3D viewport is hidden
newScriptButton.ClickableWhenViewportHidden = true

]]

function meterToUnit(meter)
	return meter * COEFF
end

--[[ 
	@return (number) Winkel zwischen p1(x1,0,z1) and p2(x2,0,y2) 
]]
function angle_pointsXZ(point1:Vector3, point2:Vector3):number
	return math.atan2(point2.Z - point1.Z, point2.X - point1.X)
end

--[[ 
	@return (number) Winkel zwischen p1(x1,y1,z1) und p2(x2,y2,y2) 
]]
function angle_pointsXYZ(point1:Vector3, point2:Vector3):number
	local x1,y1,z1 = point1.X,point1.Y,point1.Z
	local x2,y2,z2 = point2.X,point2.Y,point2.Z

	return math.acos((x1*x2 + y1*y2 + z1*z2)
		/(math.sqrt(math.pow(x1,2)+math.pow(y1,2)+math.pow(z1,2))
			*math.sqrt(math.pow(x2,2)+math.pow(y2,2)+math.pow(z2,2))))

end
--[[
 @return Abstand (XZ Kathete) zwischen point1, point2
]]
function distance_pointsXZ(point1: Vector3, point2: Vector3):number
	return math.sqrt(math.pow(point2.X - point1.X, 2) + math.pow(point2.Z - point1.Z, 2))
end

--[[
return Abstand (XZ Kathete) zwischen point1, point2
]]
function distance_pointsXYZ(point1: Vector3, point2: Vector3):number
	return math.sqrt(math.pow(point2.X - point1.X, 2) + math.pow(point2.Y - point1.Y,2) + math.pow(point2.Z - point1.Z,2))
end


--[[
	@return Abstand zwischen lat1,lon1 und la2,lon2 in Meters
]]
function haversine(lat1: number, lon1: number, lat2: number, lon2: number):number -- Meters
	local R = 6378.137
	local R = 6371.088

	
	lat1, lon1, lat2, lon2 = math.rad(lat1), math.rad(lon1), math.rad(lat2), math.rad(lon2)

	local dlat = lat2 - lat1
	local dlon = lon2 - lon1

	local a = math.sin(dlat / 2)^2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2)^2
	local c = 2 * math.asin(math.sqrt(a))

	local distance = R * c

	return distance * 1000
end

function terrain_write_Line(point1: Vector3, point2: Vector3, material:Enum.Material, step:number, terrain:Terrain, terrain_Y:number, terrain_width:number)
	local distance = distance_pointsXZ(point1,point2)
	local distamce_3d = distance_pointsXYZ(point1,point2)
	if distance == 0 then
		return false
	end
	local ignore = {}
	--[[ -- Von bottom kann man die Collisions nicht überprüfen ]]
	for _, element in workspace:GetChildren() do
		if element.Name ~= "Terrain" then
			table.insert(ignore, element)
		end
	end
	--[[]]
	local start = 0;
	
	
	
	local rayStart = Vector3.new(point1.X, 10000, point1.Z)

	local rayEnd = Vector3.new(point1.X, -1000, point1.Z)

	local ray = Ray.new(rayStart, (rayEnd - rayStart).Unit * (rayEnd - rayStart).Magnitude)

	local hit1, hitPosition, hitNormal, material_hit1 = workspace:FindPartOnRayWithIgnoreList(ray, ignore, false, true)
	local new_p1 = Vector3.new(point1.X, hitPosition.Y - TERRAIN_HIGHT/2, point1.Z)
	
	local rayStart = Vector3.new(point2.X, 10000, point2.Z)

	local rayEnd = Vector3.new(point2.X, -1000, point2.Z)

	local ray = Ray.new(rayStart, (rayEnd - rayStart).Unit * (rayEnd - rayStart).Magnitude)

	local hit2, hitPosition, hitNormal, material_hit2 = workspace:FindPartOnRayWithIgnoreList(ray, ignore, false, true)
	local new_p2 = Vector3.new(point2.X, hitPosition.Y - TERRAIN_HIGHT/2, point2.Z)
	
	local Center_new_point = Vector3.new(
		new_p1.X + (new_p2.X - new_p1.X)/2,
		new_p1.Y + (new_p2.Y - new_p1.Y)/2,
		new_p1.Z + (new_p2.Z - new_p1.Z)/2
	)
	if material_hit1 == Enum.Material.Grass and material_hit2 == Enum.Material.Grass then
		terrain:FillBlock(CFrame.new(Center_new_point, new_p2), Vector3.new(terrain_width,TERRAIN_HIGHT*2,distamce_3d), Enum.Material.Air)
		terrain:FillBlock(CFrame.new(Center_new_point, new_p2), Vector3.new(terrain_width,TERRAIN_HIGHT,distamce_3d), material)
	end
	

	
end

function terrain_write_wall(point1: Vector3, point2: Vector3, material:Enum.Material, terrain:Terrain, floors:number, folder:Workspace)
	local distance = distance_pointsXZ(point1,point2)
	local distamce_3d = distance_pointsXYZ(point1,point2)
	if floors == nil then
		floors = 2
	end
	local build_width = meterToUnit(FLOOR_WIDTH * floors)
	if distance == 0 then
		return false
	end
	local ignore = {}
	--[[ -- Von bottom kann man die Collisions nicht überprüfen ]]
	for _, element in workspace:GetChildren() do
		if element.Name ~= "Terrain" then
			table.insert(ignore, element)
		end
	end
	--[[]]
	local start = 0;



	local rayStart = Vector3.new(point1.X, 10000, point1.Z)

	local rayEnd = Vector3.new(point1.X, -1000, point1.Z)

	local ray = Ray.new(rayStart, (rayEnd - rayStart).Unit * (rayEnd - rayStart).Magnitude)

	local hit1, hitPosition, hitNormal, material_hit1 = workspace:FindPartOnRayWithIgnoreList(ray, ignore, false, true)
	local new_p1 = Vector3.new(point1.X, hitPosition.Y, point1.Z)

	local rayStart = Vector3.new(point2.X, 10000, point2.Z)

	local rayEnd = Vector3.new(point2.X, -1000, point2.Z)

	local ray = Ray.new(rayStart, (rayEnd - rayStart).Unit * (rayEnd - rayStart).Magnitude)

	local hit2, hitPosition, hitNormal, material_hit2 = workspace:FindPartOnRayWithIgnoreList(ray, ignore, false, true)
	local new_p2 = Vector3.new(point2.X, hitPosition.Y, point2.Z)

	local Center_new_point = Vector3.new(
		new_p1.X + (new_p2.X - new_p1.X)/2,
		new_p1.Y + (new_p2.Y - new_p1.Y)/2 + build_width /2,
		new_p1.Z + (new_p2.Z - new_p1.Z)/2
	)
	local wall = Instance.new("Part")
	wall.Anchored = true
	--wall.Parent = workspace
	wall.Size = Vector3.new(1, build_width, distance)
	wall.CFrame = CFrame.new(Center_new_point)
	local vectorXY = Vector3.new(point2.X - point1.X, 0, point2.Z - point1.Z)
	local rotateY = math.atan2(vectorXY.X, vectorXY.Z)
	wall.Orientation = Vector3.new(0,math.deg(rotateY),0)
	return wall

end

--[[
	Zeichnet eine Linie 
]]
function terrain_write_Line1(point1: Vector3, point2: Vector3, material:Enum.Material, step:number, terrain:Terrain, terrain_Y:number, terrain_width:number)
	local distance = distance_pointsXZ(point1,point2)
	
	if distance == 0 then
		return false
	end
	local ignore = {}
	--[[ -- Von bottom kann man die Collisions nicht überprüfen ]]
	for _, element in workspace:GetChildren() do
		if element.Name ~= "Terrain" then
			table.insert(ignore, element)
		end
	end
	--[[]]
	local start = 0;
	while true do
		if start > distance then
			start = distance
		end
		local new_point = Vector3.new(
			point1.X + start/distance * (point2.X - point1.X),
			0,
			point1.Z + start/distance * (point2.Z - point1.Z)
		)
		local rayStart = Vector3.new(new_point.X, 10000, new_point.Z)

		local rayEnd = Vector3.new(new_point.X, -1000, new_point.Z)

		local ray = Ray.new(rayStart, (rayEnd - rayStart).Unit * (rayEnd - rayStart).Magnitude)

		local hit, hitPosition, hitNormal = workspace:FindPartOnRayWithIgnoreList(ray, ignore, false, true)

		--terrain:FillBlock(CFrame.new(hitPosition.X, hitPosition.Y - terrain_Y, hitPosition.Z), Vector3.new(terrain_width,50,terrain_width), Enum.Material.Air)
		terrain:FillBlock(CFrame.new(hitPosition.X, hitPosition.Y, hitPosition.Z), Vector3.new(terrain_width,1,terrain_width), material)

		if start == distance then
			break
		end
		start += step
	end
end

function getRandomColor()
	
	return Color3.new(math.random(255),math.random(255),math.random(255))
end


--[[
	Zeichnet eine Linie 
]]
function terrain_write_Line2(point1: Vector3, point2: Vector3, material:Enum.Material, step:number, terrain:Terrain, terrain_Y:number, terrain_width:number)
	local distance2d = distance_pointsXZ(point1,point2)
	
	local angle_xy = angle_pointsXZ(point1,point2)
	local ignore = {}
	local show_array = {}
	local current_point = nil
	local prew_point = nil
	for _, element in workspace:GetChildren() do
		if element.Name ~= "Terrain" then
			table.insert(ignore, element)
		end
	end
	local start = 0;
	while true do
		if start > distance2d then
			start = distance2d
		end
		local new_point = Vector3.new(
			point1.X + start/distance2d * (point2.X - point1.X),
			0,
			point1.Z + start/distance2d * (point2.Z - point1.Z)
		)
		local rayStart = Vector3.new(new_point.X, 1000, new_point.Z)

		local rayEnd = Vector3.new(new_point.X, -1000, new_point.Z)

		local ray = Ray.new(rayStart, (rayEnd - rayStart).Unit * (rayEnd - rayStart).Magnitude)

		local hit, hitPosition, hitNormal = workspace:FindPartOnRayWithIgnoreList(ray, ignore, false, true)
		current_point = hitPosition
		
		if(prew_point == nil and hit and hit.Material ~= material) then
			table.insert(show_array, {CFrame.new(hitPosition.X, hitPosition.Y - TERRAIN_HIGHT /2 + TERRAIN_HIGHT, hitPosition.Z),Vector3.new(terrain_width,TERRAIN_HIGHT,terrain_width)})
			--terrain:FillBlock(CFrame.new(hitPosition.X, hitPosition.Y - TERRAIN_HIGHT /2, hitPosition.Z), Vector3.new(terrain_width,TERRAIN_HIGHT,terrain_width), material)
		end
		if(hit and current_point ~= prew_point and prew_point ~= nil) then
			
			local new_point_3D = Vector3.new(
				prew_point.X + (current_point.X - prew_point.X)/2,
				(prew_point.Y + (current_point.Y - prew_point.Y)/2) - TERRAIN_HIGHT /2 + TERRAIN_HIGHT,
				prew_point.Z + (current_point.Z - prew_point.Z)/2
			)
			local angle_p1_p2 = angle_pointsXYZ(prew_point,current_point)
			local angle = angle_pointsXYZ(prew_point,current_point)
			--local new_point_3D_CF = CFrame.new(new_point_3D) * CFrame.fromEulerAnglesXYZ(angle_p1_p2, angle_xy, 0)
			local new_point_3D_CF = CFrame.new(new_point_3D, point2)
			--print("angle3d: " .. math.deg(angle) .. " angle2d: " .. math.deg(angle_xy))
			table.insert(show_array, {new_point_3D_CF,Vector3.new(terrain_width,TERRAIN_HIGHT,terrain_width)})
			--terrain:FillBlock(new_point_3D_CF , Vector3.new(terrain_width,TERRAIN_HIGHT,terrain_width), material)
			
		end

		prew_point = current_point
		if start == distance2d then
			break
		end
		start += step
	end
	
	-- show on terrain 
	for _, values in show_array do
		--terrain:FillBlock(values[1] , Vector3.new(terrain_width-1,100,terrain_width-1), Enum.Material.Air)
		terrain:FillBlock(values[1] , values[2], material)
	end
end


test_array = {
	{490196,119,84035},
	{490199,119,84035},
	{490129,121,84037},
	{490131,117,84037}
}

l, b, r, t = tonumber(string.format("%.5f", l)), tonumber(string.format("%.5f", b)), tonumber(string.format("%.5f", r)), tonumber(string.format("%.5f", t))
local meters = 30
local metersInGrad_lat = haversine(b, l, b + 0.00001, l)
local metersInGrad_lon = haversine(b, l, b, l + 0.00001)


function normalize(meters) --coef equator 1 sec ~ 30m
	if meters <= 30 then
		return 30
	else
		return math.round(meters/30) * 30
	end
end
local degreesPerSecond_lat = tonumber(string.format("%.5f", normalize(meters) / metersInGrad_lat * 0.00001 )) 
local degreesPerSecond_lon = tonumber(string.format("%.5f", normalize(meters) / metersInGrad_lon * 0.00001 )) 



local cl, cb, cr, ct = l, b, r, t;

print(l, b, r, t)


--OpenGeodata
--create List of Coordinates 
local pairsTable = {}

while cl < cr + degreesPerSecond_lon do
	while cb < ct + degreesPerSecond_lat do
		table.insert(pairsTable, {tonumber(string.format("%.5f", cb)),tonumber(string.format("%.5f", cl))})
		cb+=degreesPerSecond_lat;
	end
	cl+=degreesPerSecond_lon;
	cb = b;
end 
local counter = 0;
local holder_for_strings = {}
local request_params = ""
for k, underArr in pairsTable do
	if counter == 100 then
		table.insert(holder_for_strings, request_params)  
		request_params = ""
		counter = 0;
	end
	local lat, lon = underArr[1],underArr[2];
	if counter == 0 then
		request_params ..= "" .. lat .. "," .. lon
	else
		request_params ..= "|" .. lat .. "," .. lon
	end
	counter+=1;
end

table.insert(holder_for_strings, request_params)







--Openstreetmap
local HttpService = game:GetService("HttpService")
local URL_ASTROS = "https://api.openstreetmap.org/api/0.6/map?bbox=".. l .. ",".. b ..",".. r ..",".. t ..""

-- Make the request to our endpoint URL
-- for test 



local normX, normZ = math.round(l * 10000), math.round(b * 10000)
local xStart, zStart = 0 - normX, 0 - normZ;

local grid = {}
local X, Z = 15, 15

local point_data = {}
local min = 99999;
local max = -99999;

local rows = 0;
local row_wal = 0;
local columns = 0;
local request_counter = 0
if LOAD_DATA_OTM then
	for k, request_str in holder_for_strings do
		request_params = "https://api.opentopodata.org/v1/srtm30m?locations=" .. request_str .."&interpolation=cubic"
		--print(request_params)
		local response = HttpService:GetAsync(request_params)
		request_counter+=1

		local terrain_data = HttpService:JSONDecode(response)
		if terrain_data.status ~= "OK" then
			print(terrain_data.status)
		end
		--(terrain_data.results)

		--print(terrain_data)
		for k, point_data in terrain_data.results do

			--("{" .. a[1] .."," .. a[2] .. "," .. a[3] .. "},")
			table.insert(grid, {point_data.location.lat, point_data.elevation, point_data.location.lng})
			if row_wal == 0  then
				row_wal = point_data[3]
				rows+=1
				--print(columns .. " " .. rows)
				columns = 0;
			elseif (row_wal ~= 0 and row_wal ~= point_data[3]) then
				row_wal = point_data[3]
				rows+=1
				--print(columns .. " " .. rows)
				columns = 0
			end
			columns += 1;
			if min > point_data.elevation then
				min = point_data.elevation
			end
			if max < point_data.elevation then
				max = point_data.elevation
			end
		end
		print(request_counter .. " of " .. #holder_for_strings  .. "\tend ~" .. string.format("%.3f", (#holder_for_strings * 0.4 - k * 0.4)) .. "\ts")
		wait(0.4)
		
	end
else
	grid = test_array
	for k, point_data in grid do
		if row_wal == 0  then
			row_wal = point_data[3]
			rows+=1
			--print(columns .. " " .. rows)
			columns = 0;
		elseif (row_wal ~= 0 and row_wal ~= point_data[3]) then
			row_wal = point_data[3]
			rows+=1
			--print(columns .. " " .. rows)
			columns = 0
		end
		columns += 1;
		if min > point_data[2] then
			min = point_data[2]
		end
		if max < point_data[2] then
			max = point_data[2]
		end
	end
end

print("metersInGrad_lat " .. metersInGrad_lat)
print("metersInGrad_lon " .. metersInGrad_lon)
print("degreesPerSecond_lat " .. degreesPerSecond_lat)
print("degreesPerSecond_lon " .. degreesPerSecond_lon)



-- LAT(col), ELE, LON(row)
local meters = 30
local unitsCell = meterToUnit(meters)
local minLat, minLong, maxLat, maxLong, minH, maxH = 99999999,99999999,-99999999,-99999999,99999,-99999
local rows, columns = 0, 0
local prevRow, prevCol = 0, 0
local calculate = true
for i, data in grid do
	if(calculate) then
		calculate = false
		prevCol = data[1]
		prevRow = data[3]
	end
	if prevRow == 0  then
		prevRow = data[3]
		rows+=1
		--print(columns .. " " .. rows)
		columns = 0;
	elseif (prevRow ~= 0 and prevRow ~= data[3]) then
		prevRow = data[3]
		rows+=1
		--print(columns .. " " .. rows)
		columns = 0
	end
	columns += 1;


	if(minLat > data[1]) then
		minLat = data[1]
	end
	if(minLong > data[3]) then
		minLong = data[3]
	end
	if(minH > data[2]) then
		minH = data[2]
	end
	if(maxH < data[2]) then
		maxH = data[2]
	end
	if(maxLat < data[1]) then
		maxLat = data[1]
	end
	if(maxLong < data[3]) then
		maxLong = data[3]
	end
	prevCol = data[1]
	prevRow = data[3]

end
print("minLat:\t" .. minLat)
print("maxLat:\t" .. maxLat)
print("minLong:\t" .. minLong)
print("maxLong:\t" .. maxLong)
print("minH:\t" .. minH)
print("maxH:\t" .. maxH)
print("rows " .. rows)
print("columns " .. columns)

print("lat dist " .. haversine(minLat, minLong, maxLat, minLong))
print("long dist " .. haversine(minLat, minLong, minLat, maxLong))




function getNeighborsDiagonal1D(array, index, width)
	local neighbors = {-99999, -99999, -99999}

	local row = math.floor((index - 1) / width) + 1
	local col = (index - 1) % width + 1

	-- right
	if col + 1 <= width then
		neighbors[1] = array[index + 1][2]
	end

	-- bottom
	if row + 1 <= math.floor(#array / width) then
		neighbors[2] = array[index + width][2]
	end

	-- Diagoanl
	if row + 1 <= math.floor(#array / width) and col + 1 <= width then
		neighbors[3] = array[index + width + 1][2]
	end

	return neighbors
end





print("--Draw terrain")
local terrain = game.Workspace.Terrain
terrain.Anchored = true;
terrain.Size = Vector3.new(columns * unitsCell, 5, rows * unitsCell)
terrain.Position = Vector3.new(0, 0, 0)
terrain.Material = Enum.Material.Grass
local x, z = 0, 0
local osunterRows, counterCols = 0, 0
local metersInBlocs = unitsCell

local dif = metersInBlocs/meters
--print("meters: " .. meters .. " units: " .. unitsCell.. " dif: " .. dif)
for a, coordinate in ipairs(grid) do
	
	if(counterCols < columns) then

	else
		z+=metersInBlocs
		counterCols = 0
		x = 0
	end
	local elementValue = coordinate[2]
	local neighborElements = getNeighborsDiagonal1D(grid, a, columns)
	
	local y1 = elementValue - minH
	local y2 = neighborElements[1]
	if y2 == -99999 then
		y2 = y1
	else
		y2 = neighborElements[1] - minH
	end
	local y3 = (neighborElements[2])
	if y3 == -99999 then
		y3 = y2
	else
		y3 = neighborElements[2] - minH
	end
	local y4 = (neighborElements[3])
	if y4 == -99999 then
		y4 = y3
	else
		y4 = neighborElements[3] - minH
	end
	--print(y1,y2,y3,y4)
	--test
	--print("Meters:\t",y1,y2,y3,y4)
	y1 = meterToUnit(y1)
	y2 = meterToUnit(y2)
	y3 = meterToUnit(y3)
	y4 = meterToUnit(y4)	
	--print("Units:\t",y1,y2,y3,y4)
	
	local coef_interpol = 32
	local matrix = {}
	--terrain:FillBlock(CFrame.new(x		,y1,z), 		Vector3.new(metersInBlocs,10,metersInBlocs), Enum.Material.Sand)
	local str = ""
	local mat_rand = Enum.Material.Grass
	if y1 == y2 and y2 == y3 and y3 == y4  then
		--[[
		local bloc1 = Instance.new("Part")
		bloc1.Parent = workspace
		bloc1.Size = Vector3.new(metersInBlocs,10,metersInBlocs)
		bloc1.Anchored = true
		bloc1.Position = (Vector3.new(x + metersInBlocs/2, y1,z + metersInBlocs/2))
		]]
		terrain:FillBlock(CFrame.new(x + metersInBlocs/2, y1,z + metersInBlocs/2), 		Vector3.new(metersInBlocs,TERRAIN_HIGHT,metersInBlocs), Enum.Material.Grass)
	else
		
		for i = 1, coef_interpol do
			matrix[i] = {}

			for j = 1, coef_interpol do
				local t1 = (i - 1) / (coef_interpol - 1) -- normaalize x
				local t2 = (j - 1) / (coef_interpol - 1) -- normaalize y

				matrix[i][j] = (1 - t1) * ((1 - t2) * y1 + t2 * y2) + t1 * ((1 - t2) * y3 + t2 * y4)
				--str ..= string.format("%.1f", matrix[i][j]) .. ", "
				if(i == 1 or j == 1 or i == 32 or j == 32) then

				else
				--[[
				local bloc1 = Instance.new("Part")
				bloc1.Parent = workspace
				bloc1.Size = Vector3.new(dif,10,dif)
				bloc1.Anchored = true
				bloc1.Position = (Vector3.new(x + (j - 1) * dif - dif/2	,matrix[i][j],z + (i - 1) * dif - dif/2))
				--[[]]

					


					terrain:FillBlock(CFrame.new(x + (j - 1) * dif - dif/2	,matrix[i][j],z + (i - 1) * dif - dif/2), Vector3.new(dif,TERRAIN_HIGHT,dif), mat_rand)

				
				--if i ~= 0 and j~= 0 
				end
			end
			
			--print(str)
			--str = ""
		end
--print("-------------------------------------------------------------------------------------------------------------------------------")

	end
	if a % 10 == 0  then
		wait(0.01)
		
	end
	if a % 100 == 0 then
		print(a .. " of " .. #grid .. "\tend ~" .. string.format("%.3f", (#grid * (0.2) - a * 0.2))  .. "\ts")
	end
	
	x+=metersInBlocs
	counterCols+=1
end



local function makeOverpassRequest(bbox, _type)
	
	local overpassUrl = "http://overpass-api.de/api/interpreter?data="
	local overpassQuery = string.format([[[out:json];%s%s;out body;]],_type, bbox)
	overpassUrl = overpassUrl .. overpassQuery
	print(overpassUrl)
	local requestBody = HttpService:GetAsync(overpassUrl)
	request_counter+=1

	local terrain_data = HttpService:JSONDecode(requestBody)
	if terrain_data.status ~= "OK" then
		print(terrain_data.status)
	end
	--(terrain_data.results)
	--local requestBody = HttpService:RequestAsync(overpassUrl)
	
	return terrain_data
end

function binarySearch (list,value)
	local low = 1
	local high = #list
	while low <= high do
		local mid = math.floor((low+high)/2)
		if list[mid].id > value then high = mid - 1
		elseif list[mid].id < value then low = mid + 1
		else return list[mid]
		end
	end
	return false
end

local function search_in_Nodes(nodes, ids)
	local single = {}
	for i, id in ids do
		local an = binarySearch (nodes,id)
		if an  then
			table.insert(single, {an.lat, an.lon})
		end
			
	end
	--wait(0.01)
	return single
end
local function search_in_Nodes1(nodes, ids)
	local road_points = {}
	local singl_road = {}
	for i, node in nodes.elements do
		if node.tags == nil then
			for i, id in ids  do
				if id == node.id  then
					table.insert(singl_road, {node.lat, node.lon})
				end
			end
		end
		if #singl_road ~= 0 then
			table.insert(road_points, singl_road)
			singl_road = {}
		end


	end
	return road_points
end

local bbox = ' ('..b..','..l..','..t..','..r..')'
local nodes = makeOverpassRequest(bbox, "node")
local nodes_no_tags = {}

local trees = {}

for i, element in ipairs(nodes.elements) do
	if element.tags ~= nil then
		--print(element.tags)
		if element.tags.natural ~= nil and element.tags.natural == "tree" then
			table.insert(trees, {element.lat, element.lon})
		end
	else
		--nodes_no_tags[element.id] = element
		table.insert(nodes_no_tags, element)
	end
	if i % 1000 == 0 then
		wait(0.1)
	end
end

table.sort(nodes_no_tags, function (a,b)
	return a.id < b.id
end)
local prev = 0
--[[
for i, val in nodes_no_tags  do
	if prev ~= 0 and prev > val .id then
		print(val.id)
		
	end
	prev = val.id
end
]]
local bbox = ' ('..b..','..l..','..t..','..r..')'
local way = makeOverpassRequest(bbox, "way")
local buildings = {}
local roads = {}
local natural = {}

for i, element in ipairs(way.elements) do
	if element.tags ~= nil then
		--print(element.tags)
		if element.tags.highway ~= nil then
			--print(search_in_Nodes(nodes, element.nodes))
			local road = search_in_Nodes(nodes_no_tags, element.nodes)
			if #road ~= 0 then
				--print(buil)
				table.insert(roads,{element.tags, road})
			end
		end	
		if element.tags.building ~= nil then
			local buil = search_in_Nodes(nodes_no_tags, element.nodes)
			if #buil ~= 0 then
				--print(buil)
				table.insert(buildings,{element.tags["building:levels"], buil})
			end
			
		end
		if element.tags.natural ~= nil then
			local nat = search_in_Nodes(nodes_no_tags, element.nodes)
			if #nat ~= 0 then
				--print(buil)
				table.insert(natural,{element.tags, nat})
			end

		end
	end
	if i % 1000 == 0 then
		wait(0.1)
	end
	
end

local ServerStorage = game:GetService("ServerStorage")

local tree_mod = ServerStorage:WaitForChild("Tree")
print("--Draw trees")
local tree_layer = Instance.new("Folder")
tree_layer.Parent = ServerStorage
tree_layer.Name = "Trees Layer"
local terrain = workspace:WaitForChild("Terrain")
for i, tree in ipairs(trees) do
	local n_tree = tree_mod:Clone()
	n_tree.Parent = tree_layer
	
	
	local pos_x, pos_z = 
		meterToUnit(haversine(minLat, minLong, tree[1], minLong))+ metersInBlocs/2, 
		meterToUnit(haversine(minLat, minLong, minLat, tree[2]))+ metersInBlocs/2
	local rayStart = Vector3.new(pos_x, 1000, pos_z)

	local rayEnd = Vector3.new(pos_x, -1000, pos_z)

	
	local ray = Ray.new(rayStart, (rayEnd - rayStart).Unit * (rayEnd - rayStart).Magnitude)

	
	local ign = {n_tree}
	
	local hit, hitPosition, hitNormal = workspace:FindPartOnRayWithIgnoreList(ray, ign, false, true)
	
	local vec = Vector3.new(pos_x, hitPosition.Y + 20,pos_z)
	n_tree.Position = vec
	if i % 100 == 0 then
		wait(0.01)
	end
end
tree_layer.Parent = workspace

local road = Instance.new("Part")
road.Anchored = true;
road.Size = Vector3.new(5,20,5)
local road_layer = Instance.new("Folder")
road_layer.Parent = ServerStorage
road_layer.Name = "Road Layer"
print("--Draw roads")
for i, bul in ipairs(roads) do
	local color = Color3.new(math.random(255),math.random(255), math.random(255))
	local current_point = nil
	local prew_poin = nil
	local first_point = nil
	local last_point = nil
	local first_point_G = nil
	local last_point_G = nil
	local road_type = Enum.Material.Asphalt
	local width = 20
	local road_type = Enum.Material.Asphalt
	if bul[1]["highway"] == "footway" or bul[1]["highway"] == "path" then
		--local road_type = Enum.Material.Air
		width = 10
	else
		local road_type = Enum.Material.Asphalt
	end
	for j, coord in bul[2]  do
		if #coord == 0 or #coord == 1 then
			break
		end
		

		local pos_x, pos_z = meterToUnit(haversine(minLat, minLong, coord[1], minLong)) + metersInBlocs/2, meterToUnit(haversine(minLat, minLong, minLat, coord[2])) + metersInBlocs/2
		
		
		
		
		current_point = Vector3.new(pos_x, 0, pos_z)
		if(first_point == nil) then
			first_point = current_point
			first_point_G = coord
		end
		if j == #bul  then
			last_point = current_point
			last_point_G = coord
			if haversine(last_point_G[1], last_point_G[2], first_point_G[1], first_point_G[2]) < 20 and false then
				--print(10001)
				terrain_write_Line(last_point, first_point, road_type, 1, terrain, TERRAIN_HIGHT, width)
			end
		end
		if prew_poin ~= current_point and prew_poin ~= nil then
			terrain_write_Line(prew_poin, current_point, road_type, 1, terrain, TERRAIN_HIGHT, width)
			--print(10002)
		end
		prew_poin = current_point
		
	end
	if i % 10 == 0  then
		wait(0.01)
	end
	
end
road_layer.Parent = workspace

local buil = Instance.new("Part")
buil.Anchored = true;
buil.Size = Vector3.new(1,50,1)
local buildings_layer = Instance.new("Folder")
buildings_layer.Parent = ServerStorage
buildings_layer.Name = "Building Layer"
print("--Draw buildings")
for i, bul in ipairs(buildings) do
	local color = Color3.new(math.random(255),math.random(255), math.random(255))
	local current_point = nil
	local prew_poin = nil
	local first_point = nil
	local last_point = nil
	local first_point_G = nil
	local last_point_G = nil
	local current_build = {}
	local building_folder = Instance.new("Folder")
	building_folder.Parent = buildings_layer
	building_folder.Name = "Building_" .. i
	for j, coord in bul[2]  do
		
		if #coord == 0 or #coord == 1 then
			break
		end
		local pos_x, pos_z = meterToUnit(haversine(minLat, minLong, coord[1], minLong))+ metersInBlocs/2, meterToUnit(haversine(minLat, minLong, minLat, coord[2])) + metersInBlocs/2
		current_point = Vector3.new(pos_x, 0, pos_z)
		if(first_point == nil) then
			first_point = current_point
			first_point_G = coord
		end
		if j == #bul[2]  then
			last_point = current_point
			last_point_G = coord
			if haversine(last_point_G[1], last_point_G[2], first_point_G[1], first_point_G[2]) < 10 then
				--print(10003)
				table.insert(current_build, terrain_write_wall(last_point,first_point,Enum.Material.Brick,terrain,bul[1]))
			end
		end
		if prew_poin ~= current_point and prew_poin ~= nil then
			table.insert(current_build, terrain_write_wall(prew_poin,current_point,Enum.Material.Brick,terrain,bul[1]))
			--terrain_write_Line(prew_poin, current_point, road_type, 1, terrain, TERRAIN_HIGHT, width)
			--print(10002)
		end
		prew_poin = current_point
		
	end
	if i % 10 == 0  then
		wait(0.01)
	end
	 
	if #current_build ~= 0 then
		local cur_min, cur_max, avr = 99999,-99999,0
		for _, val in current_build do
			if val ~= false then
				
				--print(val)
				if cur_min > val.CFrame.p.Y then
					cur_min = val.CFrame.p.Y
				end
				if cur_max < val.CFrame.p.Y then
					cur_max = val.CFrame.p.Y
				end
			end
		end
		avr = (cur_min + cur_max)/2
		local dif = cur_max - cur_min
		--print(avr)
		for i, val in current_build do
			if val ~= false then		

				val.Size = Vector3.new(val.Size.X, val.Size.Y + dif * 2, val.Size.Z)
				local orient = val.Orientation
				val.CFrame = CFrame.new(val.CFrame.p.X, avr, val.CFrame.p.Z)
				val.Orientation = orient
				val.Parent = building_folder
			end
		end
	end
	

end
buildings_layer.Parent = workspace





print("Roads " .. #roads)
print("Trees " .. #trees)
print("Buildings " .. #buildings)
local gui = game.StarterGui
for i,player in pairs(game:GetService("Players"):GetPlayers())do
	player.PlayerGui:WaitForChild("ScreenGui").Enabled = true
end

if SHOW_PLAYER_INFO  then
	gui.ScreenGui.Frame.TextBox.Text = "asdasdasd"
	while true do
		for i,player in pairs(game:GetService("Players"):GetPlayers())do
			local lat,lon,ele
			lat = b + (player.Character.HumanoidRootPart.Position.X / COEFF - meters / 2) / metersInGrad_lat * 0.00001
			lon = l + (player.Character.HumanoidRootPart.Position.Z / COEFF - meters / 2) / metersInGrad_lon * 0.00001
			ele = min + player.Character.HumanoidRootPart.Position.Y / COEFF - 10
			player.PlayerGui.ScreenGui.Frame.TextBox.Text = string.format([[
				lat:	%.5f
				lon:	%.5f
				ele:%.1f]], lat,lon,ele)
			
		end
		wait(0.2)
		
	end
	--[[
	local test_player = nil
	for _, player  in game.Players:GetPlayers() do
		if player.Name == "chefik_01" then
			test_player = player
			break
		end
	end
	
	for i,player in pairs(game:GetService("Players"):GetPlayers())do
		player
	end
	local lat, lon, elev = 
	gui.ScreenGui.Frame.TextBox.Text = string.format("")
	while true and test_player ~= nil do
		print(test_player.Character.HumanoidRootPart.Position.Y/4)
		wait(0.5)
	end
	]]
end
