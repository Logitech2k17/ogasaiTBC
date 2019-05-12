script_pathFlyingEX = {
	myMounts = {},
	numMounts = 0,
	isSetup = false
}

function script_pathFlyingEX:setup()

	if (not self.isSetup) then
	
		self.myMounts = {};
		self.numMounts = 1;

		script_pathFlyingEX:addMount('Swift Blue Gryphon');
		script_pathFlyingEX:addMount('Swift Green Gryphon');
		script_pathFlyingEX:addMount('Swift Red Gryphon');
		script_pathFlyingEX:addMount('Swift Purple Gryphon');

		script_pathFlyingEX:addMount('Swift Yellow Windrider');
		script_pathFlyingEX:addMount('Swift Red Windrider');
		script_pathFlyingEX:addMount('Swift Purple Windrider');
		script_pathFlyingEX:addMount('Swift Green Windrider');

		script_pathFlyingEX:addMount('Tawny Windrider');
		script_pathFlyingEX:addMount('Blue Windrider');
		script_pathFlyingEX:addMount('Green Windrider');

		script_pathFlyingEX:addMount('Ebon Gryphon');
		script_pathFlyingEX:addMount('Snowy Gryphon');
		script_pathFlyingEX:addMount('Golden Gryphon');
		
		DEFAULT_CHAT_FRAME:AddMessage('script_pathFlyingEX: loaded.');
		self.isSetup = true;
	end
end

function script_pathFlyingEX:onMount()
	local player = GetLocalPlayer();

	if (HasBuff(player, "Swift Flight Form")) then
		return true;
	end

	if (HasBuff(player, "Flight Form")) then
		return true;
	end

	for i=1,self.numMounts do
		if (HasBuff(player, self.myMounts[i])) then
			return true;
		end
	end

	return false;
end

function script_pathFlyingEX:canFly()

	if (GetCurrentMapContinent() ~= 3) then
		return false;
	end

	if (GetLevel(GetLocalPlayer()) ~= 70) then
		return false;
	end

	if (IsOutdoors() ~= 1) then
		return false;
	end

	return true;
end

function script_pathFlyingEX:addMount(name)
	self.myMounts[self.numMounts] = name;
	self.numMounts = self.numMounts + 1;
end

function script_pathFlyingEX:useMount()

	if (IsMoving()) then
		StopMoving();
		return true;
	end

	if (HasSpell("Swift Flight Form")) then
		CastSpellByName("Swift Flight Form");
		return true;
	end

	if (HasSpell("Flight Form")) then
		CastSpellByName("Flight Form");
		return true;
	end
	
	for i=1,self.numMounts do
		if (HasItem(self.myMounts[i])) then
			if (UseItem(self.myMounts[i])) then
				return true;
			end
		end
	end

	return false;
end

function script_pathFlyingEX:floorNextZ(x, y, z, a, dist)

	-- Start
	local xx, yy = x, y;

	-- Destination x,y
	local dx, dy = 0, 0;

	-- Save Z-floor, floorMinZ and floorMaxZ
	local _, _, _, firstFloorZ = Raycast(x, y, z, x, y, z-100);
	local lastFloor = firstFloorZ;
	local zSlopeDown = 0;
	local zSlopeUp = 0;

	local noObstacle = true;
	
	local iterations = math.floor(dist);
	for i = 1, iterations do
		dx, dy = x+(i)*math.cos(a), y+(i)*math.sin(a);

		local noWall, hitX, hitY, hitZ = Raycast(xx, yy, lastFloor+script_pather.zMax, dx, dy, lastFloor+script_pather.zMin);
		local noWallLow, hitX, hitY, hitZ = Raycast(xx, yy, lastFloor+script_pather.zMin, dx, dy, lastFloor+script_pather.zMax);

		if noWall and noWallLow then
			hitF, _, _, nextZ = Raycast(dx, dy, lastFloor+3.5, dx, dy, lastFloor-150);
		else
			noObstacle = false;
			hitF, _, _, nextZ = Raycast(dx, dy, lastFloor+50, dx, dy, lastFloor-150);
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