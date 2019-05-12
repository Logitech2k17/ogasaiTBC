script_patherEX = {

}

function script_patherEX:distToSavedNodes(x, y, z, path, pathSize)
	local count = 0;

	for i = 1, pathSize do
		local dist = GetDistance3D(x, y, z, path[i]['x'], path[i]['y'], path[i]['z']);
		if (dist < script_pather.nodeDist/2) then
			count = count + 1;
		end
	end	

	return count;
end

function script_patherEX:trimPath(path, pathSize, goToNode, nodeDist)
	local trim = false;
	local size = pathSize;
	local tempPath = {};
	for i = goToNode+1, pathSize-1 do
		for y = i+2, pathSize do
			local dist = GetDistance3D(path[i]['x'], path[i]['y'], path[i]['z'], path[y]['x'], path[y]['y'], path[y]['z']);
			local zDiff = math.abs(path[i]['z']-path[y]['z']);
			if (i ~= y and y ~= goToNode) then
				if (dist < nodeDist and zDiff < 3) then
					tempPath = {};						

					for f = 1, i-1 do
						tempPath[f] = {};
						tempPath[f] = path[f];
					end
					
					nextNode = i;

					for e = y, pathSize do
						tempPath[nextNode] = path[e];
						nextNode = nextNode + 1;
					end
					size = nextNode-1;
					trim = true;
					break;
				end
			end
		end 
	end

	if (trim) then
		return tempPath, size, trim;
	end
	
	return path, pathSize, trim;
end

function script_patherEX:floorNextZ(x, y, z, a, dist)

	-- Start
	local xx, yy = x, y;

	-- Destination x,y
	local dx, dy = 0, 0;

	-- Save Z-floor, floorMinZ and floorMaxZ
	local lastFloor = z;
	local zSlopeDown = 0;
	local zSlopeUp = 0;

	local noObstacle = true;
	
	local iterations = math.floor(dist);
	for i = 1, iterations do
		dx, dy = x+(i)*math.cos(a), y+(i)*math.sin(a);

		local noWall, hitX, hitY, hitZ = Raycast(xx, yy, lastFloor+script_pather.zMax, dx, dy, lastFloor+script_pather.zMin);
		local noWallLow, hitX, hitY, hitZ = Raycast(xx, yy, lastFloor+script_pather.zMin, dx, dy, lastFloor+script_pather.zMax);

		if noWall and noWallLow then
			hitF, _, _, nextZ = Raycast(dx, dy, lastFloor+3.5, dx, dy, lastFloor-40);
		else
			noObstacle = false;
			hitF, _, _, nextZ = Raycast(dx, dy, lastFloor+40, dx, dy, lastFloor-40);
		end
		
		if (not hitF) then
			local tempZSlope = nextZ-lastFloor;

			if (tempZSlope > zSlopeUp) then
				zSlopeUp = tempZSlope;
			end

			if (tempZSlope < zSlopeDown) then
				zSlopeDown = tempZSlope;
			end

			lastFloor = nextZ;
			xx, yy = dx, dy;
		end
	end

	return lastFloor, zSlopeDown, zSlopeUp, noObstacle;
end

function script_patherEX:drawPath()
	if (script_pather.status == 0 and script_pather.pathSize > 0) then
		local x, y, z = GetPosition(GetLocalPlayer());
		local px, py, ps = WorldToScreen(x, y, z);

		if (ps) then
			DrawText("Path Size: " .. script_pather.pathSize, px+20, py-30, 0, 190, 45);
			DrawText("Current Node: " .. script_pather.goToIndex, px+20, py-20, 0, 190, 45);
		end

		for i = 2, script_pather.pathSize do
			if (script_pather.path[i-1]['x'] ~= nil) then
				local x1, y1, ss = WorldToScreen(script_pather.path[i-1]['x'], script_pather.path[i-1]['y'], script_pather.path[i-1]['z']);
				local x2, y2, sss = WorldToScreen(script_pather.path[i]['x'], script_pather.path[i]['y'], script_pather.path[i]['z']);
				if (ss and sss) then
					DrawLine(x1, y1, x2, y2, 0, 190, 45, 1);
					DrawText("N: " .. i, x1, y1, 0, 190, 45);
				end	
			end
		end
	end
end

function script_patherEX:drawMesh(distance, numberOfRings, maxSlopeDown, maxSlopeUp)
	local angle = 0;
	local x, y, z = GetPosition(GetLocalPlayer());
	local lx, ly, lz = x, y, z;
	for i = 1, numberOfRings do
		for u = 0, 32 do
			angle = angle + math.pi*2/32;
			zd, slopeDown, slopeUp, noObst = script_patherEX:floorNextZ(x, y, z, angle, i+1);
			xd, yd = x+i*distance*math.cos(angle), y+i*distance*math.sin(angle);
			local px, py, ps = WorldToScreen(lx, ly, lz);
			local pxd, pyd, pss = WorldToScreen(xd, yd, zd);
			if (ps and pss and u > 0) then
				if (slopeDown > maxSlopeDown and slopeUp < maxSlopeUp and noObst) then
					DrawLine(px, py, pxd, pyd, 0, 190, 45, 1);
				else
					DrawLine(px, py, pxd, pyd, 190, 0, 45, 1);
				end
			end
			x, y, z = GetPosition(GetLocalPlayer());
			lx, ly, lz = xd, yd, zd;
		end
	end
end

function script_patherEX:getObsMin(yardsInfront)
	_lx, _ly, _lz = GetPosition(GetLocalPlayer());
	_angle = GetAngle(GetLocalPlayer());	
	
	for i = 1, 25 do	
		local hit, _, _, _ = Raycast(_lx, _ly, _lz + (i*0.2),  _lx+yardsInfront*math.cos(_angle), _ly+yardsInfront*math.sin(_angle), _lz + (i*0.2));		
	
		if(not hit) then
			return i * 0.2;
		end
	end
	
	return 0;
end

function script_patherEX:getObsMax(yardsInfront)
	_lx, _ly, _lz = GetPosition(GetLocalPlayer());
	_angle = GetAngle(GetLocalPlayer());
	local maxObsZ = 0;

	for i = 1, 25 do	
		local hit, _, _, _ = Raycast(_lx, _ly, _lz + (i*0.2),  _lx+yardsInfront*math.cos(_angle), _ly+yardsInfront*math.sin(_angle), _lz + (i*0.2));	
	
		if(not hit) then
			maxObsZ =  i * 0.2;
		end
	end
	
	return maxObsZ;
end

function script_patherEX:closestPathNode()
	local dist = 100;
	local nr = 1;
	local _lx, _ly, _lz = GetPosition(GetLocalPlayer());
	for i = 1, script_pather.pathSize do
		local nodeDist = math.sqrt((script_pather.path[i]['x']-_lx)^2+(script_pather.path[i]['y']-_ly)^2);
		if (nodeDist < dist) then 
			dist = nodeDist; 
			nr = i; 
		end
	end
	return nr;
end