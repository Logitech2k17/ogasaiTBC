script_pathStraight = {
}

function script_pathStraight:getNextNode(nX, nY, nZ, nA, dX, dY, dZ, path, pathSize, charCollision, nodeDist)
	local pathNode = {};
	pathNode['x'], pathNode['y'], pathNode['z'], pathNode['a'] = 0, 0, 0, 0;
	
	local closestDist = 9999;
	local newAngle = nA;
	local pathClear = true;
	local dX, dY, dZ = dX, dY, dZ;
	local distToDest = GetDistance3D(nX, nY, nZ, dX, dY, dZ);

	local dist = math.min(nodeDist, distToDest);
	local add = true;	

	-- Check angles
	for y = 0, script_pather.qualityAngle do 

		if (add) then
			newAngle = nA + y*(0.8*math.pi/script_pather.qualityAngle);	
			add = false;
		else
			newAngle = nA - y*(0.8*math.pi/script_pather.qualityAngle);	
			add = true;
		end
		
		pathClear = true;

		local pathNodeZ, zSlopeDown, zSlopeUp, noObstacle = script_patherEX:floorNextZ(nX, nY, nZ, newAngle, dist);

		local endZ = pathNodeZ + script_pather.zMin;
		
		-- Start positions 
		local mx, my, mz = nX, nY, nZ;	
			
		-- check z-slope and max/min diff
		if (zSlopeDown > script_pather.maxZSlopeDown and zSlopeUp < script_pather.maxZSlopeUp and noObstacle) then	

			mz = mz + script_pather.zMin;
			--local mlx, mly = mx+(script_pather.charWidth*math.cos(nA+math.pi/2)), my+(script_pather.charWidth*math.sin(nA+math.pi/2));
			--local mrx, mry = mx+(script_pather.charWidth*math.cos(nA-math.pi/2)), my+(script_pather.charWidth*math.sin(nA-math.pi/2));	

			-- End positions
			local _xpc, _ypc, _zpc = mx+(nodeDist)*math.cos(newAngle), my+(nodeDist)*math.sin(newAngle), endZ;		

			-- Check: Fences/Obstacles/Walls 
			--if (charCollision) then
			--	for u = 0, script_pather.qualityZ do
			--		local zCheck = u*(script_pather.zMax-script_pather.zMin)/script_pather.qualityZ;
			--		if ((not Raycast(mx, my, mz+zCheck, _xpc, _ypc, _zpc+script_pather.zMin))) then --or 
						--(not Raycast(mlx, mly, mz+zCheck, _xpl, _ypl, _zpc+script_pather.zMin)) or
						--(not Raycast(mrx, mry, mz+zCheck, _xpr, _ypr, _zpc+script_pather.zMin))) then
			--			pathClear = false;
			--		end
			--	end
			--end

			if (pathClear) then
				local currNodeDist = math.sqrt((_xpc-dX)^2+(_ypc-dY)^2);
				local saveNode = true;

				if (pathSize > 3) then
					if (script_patherEX:distToSavedNodes(_xpc, _ypc, pathNodeZ, path, pathSize) > 3) then
						saveNode = false;
					end
				end
		
				if (currNodeDist < closestDist and saveNode) then
					closestDist = currNodeDist;
					pathNode['x'], pathNode['y'], pathNode['z'], pathNode['a'] = mx+(nodeDist)*math.cos(newAngle), my+(nodeDist)*math.sin(newAngle), pathNodeZ, newAngle;
				end
			end
			
		end

	end
	return pathNode;
end

function script_pathStraight:generateStraightPath(sx, sy, sz, a, dx, dy, dz, charCollision, nodeDist)

	local path = {};
	local mx, my, mz = sx, sy, sz;

	local pathGen = false;
	path[1] = {};
	path[1]['x'], path[1]['y'], path[1]['z'], path[1]['a'] = sx, sy, sz, a;

	if (GetDistance3D(mx, my, mz, dx, dy, dz) < nodeDist) then
		path[2] = {};
		path[2]['x'], path[2]['y'], path[2]['z'], path[2]['a'] = dx, dy, dz, a;
		return true, path, 2; 
	end

	path[2] = {};	
	path[2] = script_pathStraight:getNextNode(mx, my, mz, a, dx, dy, dz, path, 0, charCollision, nodeDist);
	
	for i = 3, script_pather.straightPathSize do
		path[i] = {};
		path[i] = script_pathStraight:getNextNode(path[i-1]['x'], path[i-1]['y'], path[i-1]['z'], path[i-1]['a'], dx, dy, dz, path, i-1, charCollision, nodeDist);
		pathSize = i;

		-- Couldn't find the next path node
		if (path[i]['x'] == 0 or path[2]['x'] == 0) then
			if (i == 3) then
				return false, path, 1;
			else
				return false, path, i-1;
			end
		end
		
		local saveDestAsLastNode = true;
		--local atViewDistance = math.sqrt((path[i]['x']-sx)^2+(path[i]['y']-sy)^2) > 300;
		--if (atViewDistance and charCollision) then
		--	saveDestAsLastNode = false;
		--end

		-- Reached the destination or max view distance
		if ((math.sqrt((path[i]['x']-dx)^2+(path[i]['y']-dy)^2) < nodeDist))  then --or (atViewDistance)) then
			pathGen = true;
			break;
		end	

		if (pathSize > 3) then
			if (script_patherEX:distToSavedNodes(path[i]['x'], path[i]['y'], path[i]['z'], path, pathSize) > 3) then
				return false, path, i-2;
			end
		end
	end

	if (pathGen) then
		if (saveDestAsLastNode) then
			pathSize = pathSize+1;
			path[pathSize] = {};
			path[pathSize]['x'], path[pathSize]['y'], path[pathSize]['z'], path[pathSize]['a'] = dx, dy, dz, path[pathSize-1]['a'];
		end
		return true, path, pathSize;
	end

	return false, path, pathSize-1;
end

function script_pathStraight:trimToDest(path, pathSize, goToNode, dx, dy, dz)
	local trim = false;
	local size = pathSize;
	local tempPath = {};
	self.trimmingToDestLock = true;
	local start = math.floor(size/2);

	local start = math.floor(size/2);
	local stop = start + 10;

	if (pathSize < (stop)) then
		return path, pathSize, false;
	end

	for i = start, stop do
		if (i <= pathSize-1) then
			local straightPath, tempStraightPath, tempSize = 
				script_pathCircle:findStraightPath(path[i]['x'], path[i]['y'], path[i]['z'], dx, dy, dz, true, script_pather.nodeDist);
			
			if (straightPath) then
				tempPath = {};						

				for f = 1, i do
					tempPath[f] = path[f];
				end
					
				nextNode = i+1;

				for e = 1, tempSize do
					tempPath[nextNode] = tempStraightPath[e];
					nextNode = nextNode + 1;
				end
				
				--DEFAULT_CHAT_FRAME:AddMessage('script_pather: Found a straight path from node: ' .. i);
				size = nextNode-1;
				trim = true;
				break;
			end
		end 
	end

	if (trim) then
		return tempPath, size, trim;
	end
	
	return path, pathSize, trim;
end

function script_pathStraight:connectStraightPath(path, pathSize, dx, dy, dz, charCollision, nodeDist)
	local repaired = false;
	local size = pathSize;
	local tempPath = {};

	local startNode = 2;
	local distToDest = 9999;
	local failPath = {};

	for i = startNode, pathSize-1 do
		local straightPath, tempStraightPath, tempSize = 
			script_pathStraight:generateStraightPath(path[i]['x'], path[i]['y'], path[i]['z'], path[i]['a'], dx, dy, dz, charCollision, nodeDist);
					
		if (straightPath) then
			tempPath = {};	
					
			for f = 1, i do
				tempPath[f] = path[f];
			end

			tempPath = script_pathCircle:mergPaths(tempPath, tempStraightPath);
			size = #tempPath;
			repaired = true;
			break;
		else
			local dist = GetDistance3D(tempStraightPath[tempSize]['x'], tempStraightPath[tempSize]['y'], tempStraightPath[tempSize]['z'], dx, dy, dz);
			if (dist < distToDest) then
				distToDest = dist;

				tempPath = {};	
				for f = 1, i do
					tempPath[f] = path[f];
				end

				failPath = script_pathCircle:mergPaths(tempPath, tempStraightPath);
			end
		end

		startNode = startNode+1;
						
	end

	if (repaired) then
		return repaired, tempPath, size;
	end
	
	return repaired, failPath, #failPath;
end

function script_pathStraight:reverse(tbl)
	for i=1, math.floor(#tbl / 2) do
		local tmp = tbl[i]
		tbl[i] = tbl[#tbl - i + 1]
		tbl[#tbl - i + 1] = tmp
	end
	return tbl;
end