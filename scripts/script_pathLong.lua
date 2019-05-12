script_pathLong = {
	
}

function script_pathLong:getNextNode(nX, nY, nZ, nA, dX, dY, dZ, path, pathSize)

	local pathNode = {};
	pathNode['x'], pathNode['y'], pathNode['z'], pathNode['a'] = 0, 0, 0, 0;
	
	local closestDist = 9999;
	local newAngle = nA;
	local pathClear = true;
	local dX, dY, dZ = dX, dY, dZ;
	local distToDest = GetDistance3D(nX, nY, nZ, dX, dY, dZ);

	local dist = math.min(script_pather.nodeDist, distToDest);
	local distToFirstTempDest = GetDistance3D(nX, nY, nZ, script_pather.tempFirstdX, script_pather.tempFirstdY, nZ);
	local distToSecondTempDest = GetDistance3D(nX, nY, nZ, script_pather.tempSecdX, script_pather.tempSecdY, nZ);

	if (distToFirstTempDest < script_pather.nodeDist*2) then
		script_pather.firstDestNodes = 0;
	end

	if (script_pather.secondDestNodes < script_pather.nodeDist*2) then
		script_pather.firstDestNodes = 0;
	end

	if (script_pather.firstDestNodes > 0) then
		script_pather.firstDestNodes = script_pather.firstDestNodes - 1;
		dX, dY, dZ = script_pather.tempFirstdX, script_pather.tempFirstdY, nZ;
	end

	if (script_pather.secondDestNodes > 0 and script_pather.firstDestNodes == 0) then
		script_pather.secondDestNodes = script_pather.secondDestNodes - 1;
		dX, dY, dZ = script_pather.tempSecdX, script_pather.tempSecdY, nZ;
	end
	
	-- angle check
	for y = 0, script_pather.qualityAngle do 

		newAngle = nA - y*(2*math.pi/script_pather.qualityAngle);	
		pathClear = true;

		-- Z check
		for i = 0, script_pather.qualityZ do 

			-- Start positions 
			local mx, my, mz = nX, nY, nZ;
			mz = mz + script_pather.zMin + i*script_pather.zMax/script_pather.qualityZ;
			local mlx, mly = mx+(0.5*math.cos(nA+3.14/2)), my+(0.5*math.sin(nA+3.14/2));
			local mrx, mry = mx+(0.5*math.cos(nA-3.14/2)), my+(0.5*math.sin(nA-3.14/2));
		
			-- End positions
			local pathNodeZ = script_patherEX:floorNextZ(nX, nY, nZ, newAngle, dist);
			local pathNodeAddZ = script_patherEX:floorNextZ(nX, nY, nZ, newAngle, (dist+1));
			local endZ = pathNodeZ + script_pather.zMin + i*script_pather.zMax/script_pather.qualityZ;

			local _xpc, _ypc, _zpc = mx+(script_pather.nodeDist+1)*math.cos(newAngle), my+(script_pather.nodeDist+1)*math.sin(newAngle), endZ;
			local _xpl, _ypl, _zpl = mlx+(script_pather.nodeDist+1)*math.cos(newAngle), mly+(script_pather.nodeDist+1)*math.sin(newAngle), endZ;
			local _xpr, _ypr, _zpr = mrx+(script_pather.nodeDist+1)*math.cos(newAngle), mry+(script_pather.nodeDist+1)*math.sin(newAngle), endZ;

			local hitC, cX, cY, cZ = Raycast(mx, my, mz, _xpc, _ypc, _zpc);
			local hitL, lX, lY, lZ = Raycast(mlx, mly, mz, _xpl, _ypl, _zpl);	
			local hitR, rX, rY, rZ = Raycast(mrx, mry, mz, _xpr, _ypr, _zpr);

			-- Check: Fences/Obstacles
			if (i == 0) then
				for u = 0, 13 do
					if ((not Raycast(mx, my, mz+0.2*u, _xpc, _ypc, _zpc+0.2*u)) or 
						(not Raycast(mlx, mly, mz+0.2*u, _xpl, _ypl, _zpc+0.2*u)) or
						(not Raycast(mrx, mry, mz+0.2*u, _xpr, _ypr, _zpc+0.2*u))) then
						pathClear = false;
					end
				end
			end

			local zDiff = math.abs(nZ-pathNodeAddZ);
			local zSlope = zDiff/dist; 
				
			if ((not hitC) or (not hitL) or (not hitR)) then
				pathClear = false;
			end
			
			if (i == script_pather.qualityZ and pathClear) then
				if(zSlope < script_pather.maxZSlope) then
					local currNodeDist = GetDistance3D(_xpc, _ypc, pathNodeZ, dX, dY, dZ);
					if (currNodeDist < closestDist) then
						closestDist = currNodeDist;
						pathNode['x'], pathNode['y'], pathNode['z'], pathNode['a'] = mx+(script_pather.nodeDist)*math.cos(newAngle), my+(script_pather.nodeDist)*math.sin(newAngle), pathNodeZ, newAngle;
					end
				end
			end
		end	

	end

	if (pathSize > 3 and script_pather.firstDestNodes == 0 and script_pather.secondDestNodes == 0 and not script_pather.tempPathExist) then
		if (script_patherEX:distToSavedNodes(pathNode['x'], pathNode['y'], pathNode['z'], path, pathSize) > 2) then
			script_pathLong:tempPathDest(pathNode, path, pathSize);
		end
	end

	return pathNode;
end

function script_pathLong:tempPathDest(pathNode, path, size)
	local tempAL = path[size-1]['a'];
	local tempAR = path[size-2]['a'];

	local x, y, z = GetPosition(GetLocalPlayer());
	local tempDestDist = script_pather.tempSize*script_pather.nodeDist;

	local firstLX, firstLY = x + tempDestDist*math.cos(tempAL), y + tempDestDist*math.sin(tempAL);
	local firstRX, firstRY = x + tempDestDist*math.cos(tempAR), y + tempDestDist*math.sin(tempAR);
	local firstDistL = math.sqrt((script_pather.dX-firstLX)^2 + (script_pather.dY-firstLY)^2);
	local firstDistR = math.sqrt((script_pather.dX-firstRX)^2 + (script_pather.dY-firstRY)^2);
	local secAngle = tempAL+math.pi/2;

	if (firstDistL < firstDistR) then
		script_pather.tempFirstdX, script_pather.tempFirstdY = firstLX, firstLY;
	else
		script_pather.tempFirstdX, script_pather.tempFirstdY = firstRX, firstRY;
		secAngle = tempAL-math.pi/2;
	end
	
	script_pather.tempSecdX, script_pather.tempSecdY = script_pather.tempFirstdX + tempDestDist*math.cos(secAngle), script_pather.tempFirstdY + tempDestDist*math.sin(secAngle);
	
	script_pather.firstDestNodes = script_pather.tempSize;
	script_pather.secondDestNodes = script_pather.tempSize;

	DEFAULT_CHAT_FRAME:AddMessage('changing to temp destination for ' .. script_pather.firstDestNodes .. ' nodes.');
end

function script_pathLong:clearPath(x1, y1, z1, nA, x2, y2, z2)
	local dist = GetDistance3D(x1, y1, z1, x2, y2, z2);
	local pathClear = true;

	-- Z check
	for i = 0, script_pather.qualityZ do 

			-- Start positions 
			local mx, my, mz = x1, y1, z1;
			mz = mz + script_pather.zMin + i*script_pather.zMax/script_pather.qualityZ;
			local mlx, mly = mx+(0.5*math.cos(nA+3.14/2)), my+(0.5*math.sin(nA+3.14/2));
			local mrx, mry = mx+(0.5*math.cos(nA-3.14/2)), my+(0.5*math.sin(nA-3.14/2));
		
			-- End positions
			local _xpc, _ypc, _zpc = mx+(dist)*math.cos(newAngle), my+(dist)*math.sin(newAngle), endZ;
			local _xpl, _ypl, _zpl = mlx+(dist)*math.cos(newAngle), mly+(dist)*math.sin(newAngle), endZ;
			local _xpr, _ypr, _zpr = mrx+(dist)*math.cos(newAngle), mry+(dist)*math.sin(newAngle), endZ;

			local hitC, cX, cY, cZ = Raycast(mx, my, mz, _xpc, _ypc, _zpc);
			local hitL, lX, lY, lZ = Raycast(mlx, mly, mz, _xpl, _ypl, _zpl);	
			local hitR, rX, rY, rZ = Raycast(mrx, mry, mz, _xpr, _ypr, _zpr);

			-- Check: Fences/Obstacles
			if (i == 0) then
				for u = 0, 13 do
					if (not Raycast(mx, my, mz+0.2*u, _xpc, _ypc, _zpc+0.2*u) or 
						not Raycast(mlx, mly, mz+0.2*u, _xpl, _ypl, _zpc+0.2*u) or
						not Raycast(mrx, mry, mz+0.2*u, _xpr, _ypr, _zpc+0.2*u)) then
						pathClear = false;
					end
				end
			end

			if ((not hitC) or (not hitL) or (not hitR)) then
				pathClear = false;
			end
	end

	return pathClear;
end

function script_pathLong:trimLongPath(path, pathSize, goToNode)
	local trim = false;
	local size = pathSize;
	local tempPath = {};
	for i = goToNode+1, pathSize-1 do
		for y = i+2, pathSize do
			local zDiff = math.abs(path[i]['z']-path[y]['z']);
			local clearPath = script_pathLong:clearPath(path[i]['x'], path[i]['y'], path[i]['z'], path[i]['a'], path[y]['x'], path[y]['y'], path[y]['z']);
			if (i ~= y and y ~= goToNode) then
				if (zDiff < 3 and clearPath) then
					DEFAULT_CHAT_FRAME:AddMessage('script_pather: Found a clear path from node: ' .. i .. ' to node: ' .. y);
					tempPath = {};						

					for f = 1, i-1 do
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

	DEFAULT_CHAT_FRAME:AddMessage('trim long ran');	

	return path, pathSize, trim;
end