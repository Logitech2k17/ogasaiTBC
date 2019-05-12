script_path = {
	isSetup = false,
	savedPathNodes = {},
	numSavedPathNodes = 0,
	currentPathNode = 0,
	navNodeDist = 4,
	navNodeDistMounted = 10,
	pathNodeDist = 40,
	grindingDist = 300,
	backwards = true,
	hotspotID = -1,
	hName = "No hotspot loaded...",
	hx = 0,
	hy = 0,
	hz = 0,
	savedPos = {},
	reachedHotspot = false,
	autoLoadHotspot = true,
	pathMenu = include("scripts\\script_pathMenu.lua")
}

function script_path:setup()
	self.isSetup = true;

	-- Save startup position, used as the hotspot to farm around
	self.hx, self.hy, self.hz = GetPosition(GetLocalPlayer());
	self.hName = GetMinimapZoneText() .. " (see path options)";

	-- Save current pos for unstuck feature
	self.savedPos = {};
	self.savedPos['x'], self.savedPos['y'], __= GetPosition(GetLocalPlayer());
	self.savedPos['time'] = GetTimeEX();

	DEFAULT_CHAT_FRAME:AddMessage('script_path: loaded...');
end

function script_path:loadNavMesh()
	if (not IsUsingNavmesh()) then
		UseNavmesh(true);
		return true;
	end
	
	if (GetLoadNavmeshProgress() == 0) then
		LoadNavmesh();
		return true;
	end

	if (GetLoadNavmeshProgress() < 1) then
		return true;
	end

	NavmeshSmooth(self.navNodeDist);

	return false;
end

function script_path:printHotspot()
	DEFAULT_CHAT_FRAME:AddMessage('script_path: Add this hotspot to your database by adding the following line in the setup-function in hotspotDB.lua:');
	DEFAULT_CHAT_FRAME:AddMessage('You can copy the line from logs//.txt');
	
	local race, level = UnitRace("player"), GetLevel(GetLocalPlayer());
	local hx, hy, hz = math.floor(self.hx*100)/100, math.floor(self.hy*100)/100, math.floor(self.hz*100)/100;

	local addString = 'hotspotDB:addHotspot("' .. GetMinimapZoneText() .. ' ' .. level .. ' - ' .. level+2 .. '", "' .. race
					.. '", ' .. level .. ', ' .. level+2 .. ', ' .. hx .. ', ' .. hy .. ', ' .. hz .. ');'	

	DEFAULT_CHAT_FRAME:AddMessage(addString);
	ToFile(addString);

end

function script_path:savePos(dontCheck)
	if (script_path:distToSavedPos() > 5 or dontCheck) then
		self.savedPos['x'], self.savedPos['y'], __= GetPosition(GetLocalPlayer());
		self.savedPos['time'] = GetTimeEX();
	end
end

function script_path:distToSavedPos()
	local x, y, z = GetPosition(GetLocalPlayer());

	return math.sqrt((x-self.savedPos['x'])^2 + (y-self.savedPos['y'])^2);
end

function script_path:unStuck()
	if (GetTimeEX() - self.savedPos['time'] > 10000) then
		return true;
	end 

	return false;
end

function script_path:draw() 

	if (self.hx ~= 0) then
		local xx, yy, hasHotspot = WorldToScreen(self.hx, self.hy, self.hz);
		if (hasHotspot) then
			DrawText('Loaded hotspot:', xx-50, yy, 0, 255, 255);
			DrawText(self.hName, xx-50, yy+10, 0, 255, 255);
		end
	end

	if (self.numSavedPathNodes > 1) then
		for i = 0,self.numSavedPathNodes-1 do
			local tX, tY, onScreen = WorldToScreen(self.savedPathNodes[i]['x'], self.savedPathNodes[i]['y'], self.savedPathNodes[i]['z']);
			if (onScreen) then
				DrawText('Auto Path Node: ' .. i, tX-25, tY, 0, 255, 255);
			end
		end
	end
end

function script_path:resetHotspot()
	self.hx, self.hy, self.hz = GetPosition(GetLocalPlayer());
	self.hName = GetMinimapZoneText() .. " (user created)";
	self.numSavedPathNodes = 0;
	self.hotspotID = -1;
	self.reachedHotspot = true;
end

function script_path:updateHotspot()
	local hId = -1;
	hId = hotspotDB:getHotspotID(UnitRace("player"), GetLevel(GetLocalPlayer()));
	if (self.hotspotID ~= hId and hId ~= -1) then
		self.hotspotID = hId;
		self.savedPathNodes = {};
		self.numSavedPathNodes = 0;
		local hotspot = hotspotDB:getHotSpotByID(hId);
		self.reachedHotspot = false;
		self.hx, self.hy, self.hz = hotspot['pos']['x'], hotspot['pos']['y'], hotspot['pos']['z'];
		self.hName = hotspot['name'];
	end
end

function script_path:resetAutoPath()
	self.currentPathNode = script_pathMenu:closestPathNode();
end

function script_path:autoPath()
	-- No path nodes yet
	if (self.numSavedPathNodes == 0 or not self.reachedHotspot) then
		if (script_path:distanceToHotspot() <= 10) then
			self.reachedHotspot = true;	
		end
		
		if (script_path:distanceToHotspot() > 5) then
			if (not script_grind.raycastPathing) then
				MoveToTarget(self.hx, self.hy, self.hz);
			else
				script_pather:moveToTarget(self.hx, self.hy, self.hz);
			end
			return "Moving to hotspot...";
		end
		
		return "Hotspot reached, no targets around?";
	end

	-- Reached the first node
	if (self.currentPathNode < 0 and self.numSavedPathNodes > 1) then
		if (script_path:distanceToPathNode(0) < 5) then
			self.currentPathNode = 0;
			self.backwards = false;
			return;
		end
	end

	-- Reached the end node
	if (script_path:distanceToPathNode(self.numSavedPathNodes-1) < 5) then
		if ((self.numSavedPathNodes-1) == self.currentPathNode) then
			self.currentPathNode = self.numSavedPathNodes - 1;
			self.backwards = true;
		end
	end

	-- When close to the next path node swap to the next one
	if (self.numSavedPathNodes > 2) then
		if (script_path:distanceToPathNode(self.currentPathNode) < 5) then
			if (self.currentPathNode < self.numSavedPathNodes) then
				if (not self.backwards) then
					self.currentPathNode = self.currentPathNode + 1;
				else
					self.currentPathNode = self.currentPathNode - 1;
				end
			end
		end
	end

	-- Move to path node
	if (self.currentPathNode > -1 and self.numSavedPathNodes > 2) then

		if (not script_grind.raycastPathing) then
			MoveToTarget(self.savedPathNodes[self.currentPathNode]['x'], 
			self.savedPathNodes[self.currentPathNode]['y'], 
			self.savedPathNodes[self.currentPathNode]['z']);
		else
			script_pather:moveToTarget(self.savedPathNodes[self.currentPathNode]['x'], 
			self.savedPathNodes[self.currentPathNode]['y'], 
			self.savedPathNodes[self.currentPathNode]['z']);
		end
		
		return 'Moving to auto path node ' .. self.currentPathNode;
	end

	if (script_path:distanceToHotspot() > 25) then

		if (not script_grind.raycastPathing) then
			MoveToTarget(self.hx, self.hy, self.hz);
		else
			script_pather:moveToTarget(self.hx, self.hy, self.hz);
		end

		return 'Moving to hotspot...';
	end

	script_path:savePos(true);
	return 'Not enough path nodes yet...';
end

function script_path:savePathNode()
	local _tx, _ty, _tz = GetPosition(GetLocalPlayer());

	-- Check: Don't save if we are outside the grinding distance
	if (script_path:distanceToHotspot() > self.grindingDist) then return; end

	-- Check: Don't save if we already saved a path node within self.pathNodeDist
	local savePathNode = true;
	if (self.numSavedPathNodes > 0) then
		for i = 0,self.numSavedPathNodes-1 do
			local dist = math.sqrt((_tx-self.savedPathNodes[i]['x'])^2+(_ty-self.savedPathNodes[i]['y'])^2);
			if (dist < self.pathNodeDist) then
				savePathNode = false;
			end
		end
	end

	if (savePathNode) then
		self.savedPathNodes[self.numSavedPathNodes] = {};
		self.savedPathNodes[self.numSavedPathNodes]['x'] = _tx;
		self.savedPathNodes[self.numSavedPathNodes]['y'] = _ty;
		self.savedPathNodes[self.numSavedPathNodes]['z'] = _tz;
		self.numSavedPathNodes = self.numSavedPathNodes + 1;
		-- Update current path node
		self.currentPathNode = self.numSavedPathNodes - 1;
		self.backwards = true;
	end
end



function script_path:distanceToHotspot()
	local _lx, _ly, _lz = GetPosition(GetLocalPlayer());
	return GetDistance3D(_lx, _ly, _lz, self.hx, self.hy, self.hz);
end

function script_path:distanceToPathNode(i)
	local _lx, _ly, _lz = GetPosition(GetLocalPlayer());
	return math.sqrt((self.savedPathNodes[i]['x']-_lx)^2 +(self.savedPathNodes[i]['y']-_ly)^2);
end 
	
function script_path:setNavNodeDist()
	if (IsMounted()) then
		NavmeshSmooth(self.navNodeDistMounted);
	else
		NavmeshSmooth(self.navNodeDist);
	end
end