script_pathFlying = {
	nodeDist = 35,
	flyHeight = 60
}

function script_pathFlying:generatePath(x, y, z, dx, dy, dz)

	local nodeDist = self.nodeDist;

	local straightPath, tempPathS, tempSizeS = 
		script_pathFlying:generateStraightPath(x, y, z, dx, dy, dz, nodeDist);
	
	return straightPath, tempPathS, tempSizeS;
end

function script_pathFlying:getNextNode(nX, nY, nZ, nA, dX, dY, dZ, path, pathSize, nodeDist)
	
	local pathNode = {};
	pathNode['x'], pathNode['y'], pathNode['z'], pathNode['a'] = 0, 0, 0, 0;
	
	local closestDist = 9999;
	local newAngle = nA;
	local pathClear = true;
	local dX, dY, dZ = dX, dY, dZ;
	local distToDest = GetDistance3D(nX, nY, nZ, dX, dY, dZ);

	local dist = math.min(nodeDist, distToDest);
	local plus = false;

	local flyHeight = math.random(self.flyHeight/2, self.flyHeight);

	-- Check angles
	for y = 0, 32 do 
		
		if (not plus) then
			plus = true;
			newAngle = nA - y*(math.pi/32);	
		else
			plus = false;	
			newAngle = nA + y*(math.pi/32);	
		end

		local pathNodeZ, __, __, __ = script_pathFlyingEX:floorNextZ(nX, nY, nZ, newAngle, dist);

		local endZ = pathNodeZ + flyHeight;
		
		-- Start position
		local mx, my, mz = nX, nY, nZ;	
		mz = mz;

		-- End positions
		local _xpc, _ypc, _zpc = mx+(nodeDist)*math.cos(newAngle), my+(nodeDist)*math.sin(newAngle), endZ;		

		local currNodeDist = math.sqrt((_xpc-dX)^2+(_ypc-dY)^2);
		local saveNode = true;

		if (pathSize > 3) then
			if (script_patherEX:distToSavedNodes(_xpc, _ypc, pathNodeZ, path, pathSize) > 3) then
				saveNode = false;
			end
		end
		
		if (currNodeDist < closestDist and saveNode) then
			closestDist = currNodeDist;
			pathNode['x'], pathNode['y'], pathNode['z'], pathNode['a'] = mx+(nodeDist)*math.cos(newAngle), my+(nodeDist)*math.sin(newAngle), math.max(endZ, nZ), newAngle;
		end
	end

	return pathNode;
end

function script_pathFlying:generateStraightPath(sx, sy, sz, dx, dy, dz, nodeDist)

	local path = {};
	local mx, my, mz = sx, sy, sz;
	local a = GetAngle(GetLocalPlayer());

	local pathGen = false;
	path[1] = {};
	path[1]['x'], path[1]['y'], path[1]['z'], path[1]['a'] = sx, sy, sz, a;

	if (GetDistance3D(mx, my, mz, dx, dy, dz) < nodeDist) then
		path[2] = {};
		path[2]['x'], path[2]['y'], path[2]['z'], path[2]['a'] = dx, dy, dz, a;
		return true, path, 2; 
	end

	path[2] = {};	
	path[2] = script_pathFlying:getNextNode(mx, my, mz, a, dx, dy, dz, path, 0, nodeDist);
	
	for i = 3, script_pather.straightPathSize do
		path[i] = {};
		path[i] = script_pathFlying:getNextNode(path[i-1]['x'], path[i-1]['y'], path[i-1]['z'], path[i-1]['a'], dx, dy, dz, path, i-1, nodeDist);
		
		pathSize = i;

		-- Couldn't find the next path node
		if (path[i]['x'] == 0 or path[2]['x'] == 0) then
			if (i == 3) then
				return false, path, 1;
			else
				return false, path, i-1;
			end
		end

		-- Reached the destination
		if ((math.sqrt((path[i]['x']-dx)^2+(path[i]['y']-dy)^2) < nodeDist)) then
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
		local zDiffToDest = path[pathSize]['z'] - dz;
		local lastZ = path[pathSize]['z'];
		local addNodes = math.ceil(zDiffToDest/self.nodeDist);
		for i = 1, addNodes do
			pathSize = pathSize+1;
			path[pathSize] = {};
			path[pathSize]['x'], path[pathSize]['y'], path[pathSize]['z'], path[pathSize]['a'] = dx, dy, lastZ-(i*zDiffToDest/addNodes), path[pathSize-1]['a'];
		end
		return true, path, pathSize;
	end

	return false, path, pathSize-1;
end