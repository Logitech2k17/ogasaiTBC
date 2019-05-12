script_vendor = {
	message = "Idle...",
	isSetup = false,
	timer = 0,
	status = 0, --  0 = idle, 1 = repair, 2 = sell, 3 = buy items, 4 = sell when vendor already open
	itemName = 0,
	itemNum = 0,
	itemIsFood = false,
	itemIsDrink = false,
	itemIsArrow = false,
	itemIsBullet = false,
	reachedVendorTimer = 0,
	reachedVendor = false,
	atVendor = false,
	dontBuyTime = 0,
	tickRate = 150,
	extraFunctions = include("scripts//script_vendorEX.lua"),
	menuFunction = include("scripts//script_vendorMenu.lua")
}

function script_vendor:setup()
	self.status = 0;
	self.timer = GetTimeEX();
	script_vendor.dontBuyTime = GetTimeEX();
	self.reachedVendorTimer = GetTimeEX();
	DEFAULT_CHAT_FRAME:AddMessage('script_vendor: loaded...');
	script_vendorEX:setup();

	self.tickRate = script_grind.tickRate;

	self.isSetup = true;
end

function script_vendor:run()
	if (not self.isSetup) then
		script_vendor:setup();
		return;
	end

	if (self.timer > GetTimeEX()) then
		return 0;
	end
		
	self.timer = GetTimeEX() + self.tickRate;

	if (self.status == 0) then
		script_vendorEX.currentSlot = 0;
		script_vendorEX.self.currentBag = 0;
		self.message = "Idle...";
	end

	if (self.status == 1) then
		script_vendor:repair();
	end

	if (self.status == 2) then
		script_vendor:sell();
	end

	if (self.status == 3) then
		script_vendor:buy(self.itemName, self.itemNum, self.itemIsFood, self.itemIsDrink, self.itemIsArrow, self.itemIsBullet);
	end

	if (self.status == 4) then
		script_vendorEX:sell();
		script_grind:turnfOnLoot();
	end
	
	return self.tickRate;
end

function script_vendor:window()
	EndWindow();
	if(NewWindow("Logitech's Vendor", 200, 100)) then
		script_vendor:menu();
	end
end

function script_vendor:draw()
	script_vendor:window();
end

function script_vendor:sell()
	if (not self.isSetup) then
		script_vendor:setup();
	end

	-- Update sell quality rule
	script_vendorEX:setSellQuality(script_vendorEX.sellPoor, script_vendorEX.sellCommon, script_vendorEX.sellUncommon, script_vendorEX.sellRare, script_vendorEX.sellEpic);

	if (self.sellQuality == -1) then
		self.message = "Sell disabled, see vendor options...";
		return false;
	end	

	local localObj = GetLocalPlayer();
	local x, y, z = GetPosition(localObj);
	local factionID = 1; -- horde
	local faction, __ = UnitFactionGroup("player");
	if (faction == 'Alliance') then
		factionID = 0;
	end

	local vendor = nil;

	if (script_vendorEX.sellVendor == 0) then

		local vendorID = vendorDB:GetVendor(factionID, GetCurrentMapContinent(), GetCurrentMapZone(), false, false, false, false, x, y, z);

		if (vendorID ~= -1) then
			vendor = vendorDB:GetVendorByID(vendorID);
			self.sellVendor = nil;
			self.sellVendor = vendorDB:GetVendorByID(vendorID);
		else
			self.message = "No vendor found, see scripts\\VendorDB.lua...";
			return false;
		end
	else
		vendor = {};
		vendor = script_vendorEX.sellVendor;
	end
	
	if (vendor ~= nil) then
		local vX, vY, vZ = vendor['pos']['x'], vendor['pos']['y'], vendor['pos']['z'];
		
		-- Move to vendor
		if (script_helper:distance3D(x, y, z, vX, vY, vZ) > 3.5) then
			if (not IsMounted() and script_grind.jump) then script_helper:jump(); end

			if (not script_grind.raycastPathing) then
				MoveToTarget(vX, vY, vZ);
			else
				script_pather:moveToTarget(vX, vY, vZ);
			end
			
			self.status = 2; -- moving to sell at a vendor
			self.message = 'Moving to ' .. vendor['name'] .. ' to sell...';
			-- Reset bag and slot numbers before we sell
			script_vendorEX.currentBag = 0;
			script_vendorEX.currentSlot = 0;
			self.reachedVendorTimer = GetTimeEX() + 2250;
			self.reachedVendor = false;
			return true;
		else
			script_path:savePos(true); -- SAVE FOR UNSTUCK
		end

		-- Get Vendor Target
		local vendorTarget = nil;
		TargetUnit(vendor['name']);
		if (GetTarget() ~= 0 and GetTarget() ~= nil) then
			vendorTarget = GetTarget();
		end

		-- Open the vendor window
		if (vendorTarget ~= nil and script_vendorEX:canTrade()) then
			
			if (UnitInteract(vendorTarget) and not self.reachedVendor) then
				self.message = "Vendor reached...";
				self.reachedVendor = true;
				CloseGossip();
				return true;
			end

			-- Wait for vendor window to open
			if (self.reachedVendorTimer > GetTimeEX()) then
				return true;
			end

			if (script_vendor:skipGossip()) then
				return true;
			end

			-- Repair if possible
			if (CanMerchantRepair()) then
				RepairAllItems(); 
			end
				
			-- SELL LOGIC
			script_vendorEX:sell();
			script_grind:turnfOnLoot();
			
			return true;
		end
	end

	return false;
end

function script_vendor:skipGossip()
	if (GetGossipOptions() ~= nil) then
		title1, gossip1, title2, gossip2, title3, gossip3 = GetGossipOptions();
		if (title1 ~= nil) then
			if (string.find(title1, "browse")) then
				SelectGossipOption(1, " ");
			end
		elseif (title2 ~= nil) then
			if (string.find(title2, "browse")) then
				SelectGossipOption(2, " ");
			end
		elseif (title3 ~= nil) then
			if (string.find(title3, "browse")) then
				SelectGossipOption(3, " ");
			end
		end

		SelectGossipOption(2, " ");

		self.reachedVendorTimer = GetTimeEX() + 3000;
		return true;
	end

	return false;
end

function script_vendor:repair()
	if (not self.isSetup) then
		script_vendor:setup();
	end

	local localObj = GetLocalPlayer();
	local x, y, z = GetPosition(localObj);
	local factionID = 1; -- horde
	local faction, __ = UnitFactionGroup("player");
	if (faction == 'Alliance') then
		factionID = 0;
	end

	local vendor = nil;

	if (script_vendorEX.repairVendor == 0) then

		local vendorID = vendorDB:GetVendor(factionID, GetCurrentMapContinent(), GetCurrentMapZone(), true, false, false, false, x, y, z);

		if (vendorID ~= -1) then
			vendor = vendorDB:GetVendorByID(vendorID);
			self.repairVendor = nil;
			self.repairVendor = vendorDB:GetVendorByID(vendorID);
		else
			self.message = "No vendor found, see scripts\\VendorDB.lua...";
			return false;
		end
	else
		vendor = {};
		vendor = script_vendorEX.repairVendor;
	end
	
	if (vendor ~= nil) then
		local vX, vY, vZ = vendor['pos']['x'], vendor['pos']['y'], vendor['pos']['z'];
		
		-- Move to vendor
		if (script_helper:distance3D(x, y, z, vX, vY, vZ) > 3.5) then
			self.status = 1; -- moving to a repair vendor
			if (not IsMounted() and script_grind.jump) then script_helper:jump(); end
			if (not script_grind.raycastPathing) then
				MoveToTarget(vX, vY, vZ);
			else
				script_pather:moveToTarget(vX, vY, vZ);
			end
			self.message = 'Moving to ' .. vendor['name'] .. ' to repair...';
			self.reachedVendorTimer = GetTimeEX() + 2250;
			self.reachedVendor = false;
			return true;
		else
			script_path:savePos(true); -- SAVE FOR UNSTUCK
		end
	
		-- Get Vendor Target
		local vendorTarget = nil;
		TargetUnit(vendor['name']);
		if (GetTarget() ~= 0 and GetTarget() ~= nil) then
			vendorTarget = GetTarget();
		end

		-- Open the vendor window
		if (vendorTarget ~= nil and script_vendorEX:canTrade()) then
			
			self.message = 'Repairing...';

			if (UnitInteract(vendorTarget) and not self.reachedVendor) then
				self.message = "Vendor reached...";
				self.reachedVendor = true;
				script_vendorEX.sellVendor = vendor; -- We sell after repairing
				CloseGossip();
			end

			-- Wait for vendor window to open
			if (self.reachedVendorTimer > GetTimeEX()) then
				return true;
			end

			if (script_vendor:skipGossip()) then
				return true;
			end

			if (CanMerchantRepair()) then
				RepairAllItems(); 
				self.message = 'Finished repairing...';
				script_vendorEX.currentBag = 0; -- reset bag slots
				script_vendorEX.currentSlot = 0; -- reset bag slots
				self.status = 4; -- set status to sell after repairing
				return true;
			end

			return true;
		end
	end

	return false;
end

function script_vendor:buy(itemName, itemNum, itemIsFood, itemIsDrink, itemIsArrow, itemIsBullet)
	if (not self.isSetup) then
		script_vendor:setup();
	end

	local localObj = GetLocalPlayer();
	local x, y, z = GetPosition(localObj);
	local factionID = 1; -- horde
	local faction, __ = UnitFactionGroup("player");
	if (faction == 'Alliance') then
		factionID = 0;
	end

	local vendor = nil;

	if (itemIsFood) then
		vendor = script_vendorEX.foodVendor;
	elseif (itemIsDrink) then
		vendor = script_vendorEX.drinkVendor;
	elseif (itemIsArrow) then
		vendor = script_vendorEX.arrowVendor;
	elseif (itemIsBullet) then
		vendor = script_vendorEX.bulletVendor;
	end

	self.itemName = itemName;
	self.itemNum = itemNum;
	self.itemIsDrink = itemIsDrink; 
	self.itemIsFood = itemIsFood;
	self.itemIsArrow = itemIsArrow;
	self.itemIsBullet = itemIsBullet;

	if (vendor ~= nil) then
		local vX, vY, vZ = vendor['pos']['x'], vendor['pos']['y'], vendor['pos']['z'];
		
		-- Move to vendor
		if (script_helper:distance3D(x, y, z, vX, vY, vZ) > 3.5) then
			self.status = 3; -- moving to a buy vendor
			if (not IsMounted() and script_grind.jump) then script_helper:jump(); end
			if (not script_grind.raycastPathing) then
				MoveToTarget(vX, vY, vZ);
			else
				script_pather:moveToTarget(vX, vY, vZ);
			end
			self.message = 'Moving to ' .. vendor['name'] .. ' to buy...';
			self.reachedVendorTimer = GetTimeEX() + 2250;
			self.reachedVendor = false;
			return true;
		else
			script_path:savePos(true); -- SAVE FOR UNSTUCK
		end
	
		-- Get Vendor Target
		local vendorTarget = nil;
		TargetUnit(vendor['name']);
		if (GetTarget() ~= 0 and GetTarget() ~= nil) then
			vendorTarget = GetTarget();
		end

		-- Open the vendor window
		if (vendorTarget ~= nil and script_vendorEX:canTrade()) then
			
			self.message = 'Buying...';

			if (UnitInteract(vendorTarget) and not self.reachedVendor) then
				self.message = "Vendor reached...";
				self.reachedVendor = true;
				script_vendorEX.sellVendor = vendor; -- We sell after buying
				CloseGossip();
			end

			-- Wait for vendor window to open
			if (self.reachedVendorTimer > GetTimeEX()) then
				return true;
			end

			if (script_vendor:skipGossip()) then
				return true;
			end

			if (CanMerchantRepair()) then
				RepairAllItems(); 
			end

			if (script_vendorEX:buyItem(itemName, itemNum)) then
				self.message = "Finished buying items...";
				self.dontBuyTime = GetTimeEX() + 10000;
				script_grind.waitTimer = GetTimeEX() + 2500;
				script_vendorEX.currentBag = 0; -- reset bag slots
				script_vendorEX.currentSlot = 0; -- reset bag slots
				self.status = 4; -- set status to sell after repairing
				return true;
			else
				self.message = "Vendor does not have: " .. itemName;
				DEFAULT_CHAT_FRAME:AddMessage("script_vendor: Error vendor does not have: " .. itemName);
				script_vendorEX:unloadVendor(itemIsFood, itemIsDrink, itemIsArrow, itemIsBullet);
				script_grind.waitTimer = GetTimeEX() + 2500;
				self.dontBuyTime = GetTimeEX() + 10000;
				script_vendorEX.currentBag = 0; -- reset bag slots
				script_vendorEX.currentSlot = 0; -- reset bag slots
				self.status = 4; -- set status to sell after repairing
				return true;
			end
		end
	else
		self.message = "Error loading buy vendor...";
	end

	return false;
	
end
