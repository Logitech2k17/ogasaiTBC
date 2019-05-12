script_pathCircle = {
	circleQuality = 0,
	radiusQuality = 2,
	minRadius = 20,
	radiusDelta = 50,
	path = {},
	nrOfTwoPathChecks = 5,
	pathSize = 0,
	status = 0, 
	meshSize = 10
}

function script_pathCircle:generatePath(x, y, z, dx, dy, dz)

	local isFailPath, failPath, failPathSize = false, {}, 0;

	-- 1: Check for a straight path
	local straightPath, tempPathS, tempSizeS = script_pathCircle:findStraightPath(x, y, z, dx, dy, dz, true, script_pather.nodeDist);
	if (straightPath) then
		return straightPath, tempPathS, tempSizeS;
	else
		--isFailPath, failPath, failPathSize = script_pathStraight:generateStraightPath(x, y, z, GetAngle(GetLocalPlayer()), dx, dy, dz, true, script_pather.nodeDist);
		--local connected, connectedPath, connectedSize = script_pathStraight:connectStraightPath(failPath, failPathSize, dx, dy, dz, true, script_pather.nodeDist);
		--if (connected) then
		--	DEFAULT_CHAT_FRAME:AddMessage('script_pather: Generated a connected straight path...');
		--	return connected, connectedPath, connectedSize;
		--else
			--if (failPathSize > 25) then
			--	DEFAULT_CHAT_FRAME:AddMessage('script_pather: Failed to generate a complete path...');
			--	DEFAULT_CHAT_FRAME:AddMessage('script_pather: Moving through an uncompleted straight path...');
			--	return true, failPath, failPathSize-15;
			--end
		--end
	end
	
	-- 2: Check for a circle path
	isPath = false;
	local dist = GetDistance3D(x, y, z, dx, dy, dz);
	
	if (dist < script_pather.maxDist) then
		isPath, self.path, self.pathSize = script_pathCircle:findCirclePath(x, y, z, dx, dy, dz, failPath, failPathSize, true, script_pather.nodeDist);

		if (isPath) then
			DEFAULT_CHAT_FRAME:AddMessage('script_pather: Generated a circle path...');
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage('script_pather: Destination too far away...');
	end

	return isPath, self.path, self.pathSize-1;
end

function script_pathCircle:generateMeshPath(x, y, z, dx, dy, dz)

	local isFailPath, failPath, failPathSize = false, {}, 0;

	--self.meshSize = script_pather.meshSize;
	self.meshSize = script_pather.nodeDist;

	-- 1: Check for a straight mesh path
	local straightPath, tempPathS, tempSizeS = script_pathCircle:findStraightPath(x, y, z, dx, dy, dz, false, self.meshSize);
	if (straightPath) then
		return straightPath, tempPathS, tempSizeS;
	end

	-- 2: Check for a connected straight mesh path
	straightPath, tempPathS, tempSizeS = script_pathCircle:findConnectedPath(x, y, z, dx, dy, dz, false, self.meshSize);
	if (straightPath) then
		return straightPath, tempPathS, tempSizeS;
	end

	-- 3: Check for a circle mesh path
	isPath = false;
	local dist = GetDistance3D(x, y, z, dx, dy, dz);
	
	if (dist < script_pather.maxDist) then
		isPath, self.path, self.pathSize = script_pathCircle:findCircleMeshPath(x, y, z, dx, dy, dz, false, self.meshSize);
	else
		DEFAULT_CHAT_FRAME:AddMessage('script_pather: Destination too far away...');
	end

	return isPath, self.path, self.pathSize;
end

function script_pathCircle:findCirclePath(x1, y1, z1, x2, y2, z2, failedStraightPath, failSize, charCollision, nodeDist)
	DEFAULT_CHAT_FRAME:AddMessage('script_pather: Generating a circle path...');	

	local centerX, centerY = x1, y1;
	local radius = self.minRadius;
	local x1, y1, z1 =  x1, y1, z1;

	-- use the failed path as the first part of the complete path
	-- new start position (where the straight path stucks)
	if (failSize > 5) then
		x1, y1, z1 = failedStraightPath[failSize-1]['x'], failedStraightPath[failSize-1]['y'], failedStraightPath[failSize-1]['z'];
	end

	radius = math.max(GetDistance3D(x1, y1, z1, x2, y2, z2), self.minRadius);

	for y = 0, self.radiusQuality do
		radius = radius + y*self.radiusDelta;

		for i = 0, self.circleQuality do
			local deltaX = x2 - x1;
			local deltaY = y2 - y1;
			local angleToDest = 2*math.pi/360*atan2(deltaY, deltaX);
			local angleL = angleToDest + math.pi/2;
			local angleR = angleToDest - math.pi/2;

			angleL = angleL + (math.pi/16)*i;
			angleR = angleR - (math.pi/16)*i;

			local detourXL, detourYL = centerX + radius*math.cos(angleL), centerY + radius*math.sin(angleL);
			local detourXR, detourYR = centerX + radius*math.cos(angleR), centerY + radius*math.sin(angleR);
			
			local angleToDetourL = 2*math.pi/360*atan2((detourYL - y1), (detourXL - x1));
			local angleDestToDetourL = 2*math.pi/360*atan2((y2-detourYL), (x2-detourXL));
			local angleToDetourR = 2*math.pi/360*atan2((detourYR - y1), (detourXR - x1));
			local angleDestToDetourR = 2*math.pi/360*atan2((y2-detourYR), (x2-detourXR));
			
			local distToDetourL = math.sqrt((x1-detourXL)^2+(y1-detourYL)^2)/2;
			local distToDetourR = math.sqrt((x1-detourXR)^2+(y1-detourYR)^2)/2;
			
			local detourZL = script_patherEX:floorNextZ(x1, y1, z1, angleL, radius);
			local detourZR = script_patherEX:floorNextZ(x1, y1, z1, angleR, radius);

			local isPath, path, size =
				script_pathCircle:connectStraightPaths(x1, y1, z1, x2, y2, z2, detourXL, detourYL, detourZL, angleToDetourL, angleDestToDetourL, charCollision, nodeDist);

			if (not isPath) then
				isPath, path, size =
					script_pathCircle:connectStraightPaths(x1, y1, z1, x2, y2, z2, detourXR, detourYR, detourZR, angleToDetourR, angleDestToDetourR, charCollision, nodeDist);
			end

			if (isPath) then
				-- merge the failed straight path with the generated circle path
				path = script_pathCircle:mergPaths(failedStraightPath, path);
				size = #path;
				return isPath, path, size;
			end
		end
	end

	return false, {}, 0;
end

function script_pathCircle:findCircleMeshPath(x1, y1, z1, x2, y2, z2, charCollision, nodeDist)
	DEFAULT_CHAT_FRAME:AddMessage('script_pather: Generating a circle path...');	

	local centerX, centerY = x1, y1;
	local radius = 15;
	local deltaX = x2 - x1;
	local deltaY = y2 - y1;
	local angleToDest = 2*math.pi/360*atan2(deltaY, deltaX);


	for y = 1, 4 do
		radius = radius + y*50;

		for i = 1, 4 do
			--local angleL = angleToDest + i*math.pi/8;

			angleL = angleToDest - (math.pi/4)*i;

			local detourXL, detourYL = centerX + radius*math.cos(angleL), centerY + radius*math.sin(angleL);
			
			local angleToDetourL = 2*math.pi/360*atan2((detourYL - y1), (detourXL - x1));
			local angleDestToDetourL = 2*math.pi/360*atan2((y2-detourYL), (x2-detourXL));
			
			local distToDetourL = math.sqrt((x1-detourXL)^2+(y1-detourYL)^2)/2;
			
			local detourZL = script_patherEX:floorNextZ(x1, y1, z1, angleL, radius);

			local isPath, path, size =
				script_pathCircle:connectStraightPaths(x1, y1, z1, x2, y2, z2, detourXL, detourYL, detourZL, angleToDetourL, angleDestToDetourL, charCollision, nodeDist);

			if (isPath) then
				return isPath, path, size;
			end
		end
	end

	return false, {}, 0;
end

function script_pathCircle:connectStraightPaths(x1, y1, z1, x2, y2, z2, detourX, detourY, detourZ, angleToDetour, angleDetourToDest, charCollision, nodeDist)

	local pathToDetour, pathDetour, pathDetourSize = 
		script_pathStraight:generateStraightPath(x1, y1, z1, angleToDetour, detourX, detourY, detourZ, charCollision, nodeDist);
	
		local pathToDest, pathDest, pathDestSize = false, {}, 0;

		if (pathToDetour) then
			pathToDest, pathDest, pathDestSize =
				script_pathStraight:generateStraightPath(detourX, detourY, detourZ, angleDetourToDest, x2, y2, z2, charCollision, nodeDist);
		end

		if (pathToDest) then
			self.path = script_pathCircle:mergPaths(pathDetour, pathDest);
			self.pathSize = #self.path or 0;
			return true, self.path, self.pathSize;
		end

	return false, {}, 0;
end

function script_pathCircle:findConnectedPath(x1, y1, z1, x2, y2, z2, charCollision, nodeDist) 

	DEFAULT_CHAT_FRAME:AddMessage('script_pather: Generating a connected path...');

	-- First detour : half the distance
	local detourX, detourY = (x1+x2)/2, (y1+y2)/2; 
	
	local distToDetour = math.sqrt((x1-detourX)^2+(y1-detourY)^2);
	local angleToDetour = 2*math.pi/360*atan2((detourY - y1), (detourX - x1));
	local detourZ = script_patherEX:floorNextZ(x1, y1, z1, angleToDetour, distToDetour);
	local angleDetourToDest = 2*math.pi/360*atan2((y2 - detourY), (x2 - detourX));
	

	-- Check detour angles
	for i = 0, self.nrOfTwoPathChecks do

		if (i > 1) then
			angleToDetour = angleToDetour + i*math.pi/16;
			detourX, detourY = x1+distToDetour*math.cos(angleToDetour), y1+distToDetour*math.sin(angleToDetour);		
		end

		detourZ	= script_patherEX:floorNextZ(x1, y1, z1, angleToDetour, distToDetour);
		angleDetourToDest = 2*math.pi/360*atan2((y2 - detourY), (x2 - detourX));

		local isPath, tempPath, tempSize =
			script_pathCircle:connectStraightPaths(x1, y1, z1, x2, y2, z2, detourX, detourY, detourZ, angleToDetour, angleDetourToDest, charCollision, nodeDist)
		
		if (isPath) then
			return isPath, tempPath, tempSize;
		end
	end
	
	return false, {}, 0;
end


function script_pathCircle:findStraightPath(x1, y1, z1, x2, y2, z2, checkCollision, nodeDist)
	
	local angelToEnd = 2*math.pi/360*atan2((y2 - y1), (x2 - x1));
	local pathToDest, pathDest, pathDestSize = 
		script_pathStraight:generateStraightPath(x1, y1, z1, angelToEnd, x2, y2, z2, checkCollision, nodeDist);

	--local angleDestToStart = atan2((y1 - y2), (x1 - x2));
	--local pathToDestR, pathDestR, pathDestRSize = 
	--script_pathStraight:generateStraightPath(x2, y2, z2, angleDestToStart, x1, y1, z1, checkCollision, nodeDist);
	--pathDestR = script_pathStraight:reverse(pathDestR);

	--if (pathToDest and pathToDestR) then
	--	if (pathDestRSize < pathDestSize) then
	--		return true, pathDestR, pathDestRSize;
	--	else
	--		return true, pathDest, pathDestSize;
	--	end
	--end

	if (pathToDest) then
		return true, pathDest, pathDestSize;
	--elseif (pathToDestR) then
	--	return true, pathDestR, pathDestRSize;
	end

	return false, {}, 0;
end

function script_pathCircle:mergPaths(a, b)
	local nextNode = #a-1;
	for i = 1, #b do
		a[nextNode+i] = b[i];
	end
   	return a
end