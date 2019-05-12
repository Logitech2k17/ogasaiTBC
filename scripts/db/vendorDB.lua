vendorDB = {
	vendorList = {},
	numVendors = 0	
}

--[[
	todo:
		- Add class trainers
--]]

function vendorDB:addVendor(name, faction, continentID, mapID, canRepair, hasFood, hasWater, hasArrow, hasBullet, posX, posY, posZ)

	--[[
		faction:        
				0 = Alliance
				1 = Horde

		continentID: 	use: GetCurrentMapContinent() 
				
				0 - Azeroth World Map
				1 - Kalimdor
				2 - Eastern Kingdoms
				3 - Outlands
				4 - Northrend

		mapID:		use: GetCurrentMapZone()

	--]]

	self.vendorList[self.numVendors] = {};
	self.vendorList[self.numVendors]['name'] = name;
	self.vendorList[self.numVendors]['faction'] = faction;
	self.vendorList[self.numVendors]['continentID'] = continentID;
	self.vendorList[self.numVendors]['mapID'] = mapID;
	self.vendorList[self.numVendors]['canRepair'] = canRepair;
	self.vendorList[self.numVendors]['hasFood'] = hasFood;
	self.vendorList[self.numVendors]['hasWater'] = hasWater;
	self.vendorList[self.numVendors]['hasArrow'] = hasArrow;
	self.vendorList[self.numVendors]['hasBullet'] = hasBullet;
	self.vendorList[self.numVendors]['pos'] = {};
	self.vendorList[self.numVendors]['pos']['x'] = posX;
	self.vendorList[self.numVendors]['pos']['y'] = posY;
	self.vendorList[self.numVendors]['pos']['z'] = posZ;
	self.numVendors = self.numVendors + 1;
end

function vendorDB:setup()

	-- Ally: Human
	vendorDB:addVendor("Godric Rothgar", 0, 2, 10, true, false, false, false, false, -8898.24, -119.84, 81.83); -- Repair
	vendorDB:addVendor("Brother Danil", 0, 2, 10, false, true, true, false, false, -8901.59, -112.72, 81.84); -- Drink, Bread
	vendorDB:addVendor("Andrew Krighton", 0, 2, 10, true, false, false, false, false, -9462.3, 87.81, 58.33); -- Repair
	vendorDB:addVendor("Innkeeper Farley", 0, 2, 10, false, true, true, false, false, -9462.67, 16.19, 56.96); -- Drink, cheese

	-- Ally: Westfall 

	vendorDB:addVendor("Innkeeper Heather", 0, 2, 28, false, true, true, false, false, -10653.41, 1166.52, 34.46); -- Drink, fish
	vendorDB:addVendor("William MacGregor", 0, 2, 28, true, false, false, true, false, -10658.5, 996.85, 32.87); -- Repair, arrows
	
	-- Ally: Darkshore
	vendorDB:addVendor("Naram Longclaw", 0, 1, 5, true, false, false, false, false, 6571.59, 480.53, 8.25); -- Repair
	vendorDB:addVendor("Dalmond", 0, 1, 5, false, false, false, true, true, 6564.99, 488.88, 8.25); -- General
	vendorDB:addVendor("Taldan", 0, 1, 5, false, false, true, false, false, 6415.99, 529.09, 8.65); -- Drink 
	vendorDB:addVendor("Laird", 0, 1, 5, false, true, false, false, false, 6399.56, 533.38, 8.65); -- Fish

	-- Ally : Astranaar
	vendorDB:addVendor("Maliynn", 0, 1, 1, false, false, true, false, false, 2751.84, -412.04, 111.45); -- drink	
	vendorDB:addVendor("Haljan Oakheart", 0, 1, 1, false, false, false, true, true, 2717.69, -309.67, 110.72);
 -- general
	vendorDB:addVendor("Xai'ander", 0, 1, 1, true, false, false, false, false, 2672.31, -363.61, 110.72); -- repair
	vendorDB:addVendor("Innkeeper Kimlya", 0, 1, 1, false, true, false, false, false, 2781.15, -433, 116.58); -- fish

	-- Ally : Menethil Harbor
	vendorDB:addVendor("Innkeeper Helbrek", 0, 2, 29, false, true, true, false, false, -3827.93, -831.91, 10.09); -- meat/drink
	vendorDB:addVendor("Stuart Fleming", 0, 2, 29, false, true, false, false, false, -3755.63, -720.68, 8.18); -- fish
	vendorDB:addVendor("Naela Trance", 0, 2, 29, true, false, false, true, false, -3758.34, -855.73, 9.9); -- repair, arrow
	vendorDB:addVendor("Murndan Derth", 0, 2, 29, true, false, false, false, true, -3790.13, -858.47, 11.59); -- repair, bullets

	-- Ally : South Shore
	vendorDB:addVendor("Robert Aebischer", 0, 2, 13, true, false, false, false, false, -815.53, -572.19, 15.22);
	vendorDB:addVendor("Innkeeper Anderson", 0, 2, 13, false, false, true, false, false, -857.1, -570.76, 11.06);
	vendorDB:addVendor("Bront Coldcleave", 0, 2, 13, false, true, false, false, false, -820.3, -493.18, 16.45);
	vendorDB:addVendor("Sarah Raycroft", 0, 2, 13, false, false, false, true, true, -774.52, -505.75, 23.62);


	-- Ally : Arathi Highlands
	vendorDB:addVendor("Jannos Ironwill", 0, 2, 2, true, false, false, false, false, -1278.57, -2522, 21.37);
	vendorDB:addVendor("Vikki Lonsav", 0, 2, 2, false, false, false, false, true, -1275.75, -2538.73, 21.55);
	vendorDB:addVendor("Vikki Lonsav", 0, 2, 2, false, false, false, true, false, -1275.75, -2538.73, 21.55);
	vendorDB:addVendor("Vikki Lonsav", 0, 2, 2, false, false, true, false, false, -1275.75, -2538.73, 21.55);
	vendorDB:addVendor("Narj Deepslice", 0, 2, 2, false, true, false, false, false, -1275.91, -2506.19, 21.78);

	-- Horde : Arathi Highlands
	vendorDB:addVendor("Slagg", 1, 2, 2, false, true, false, false, false, -944.93, -3533.56, 70.93);
	vendorDB:addVendor("Graud", 1, 2, 2, false, false, false, true, true, -910.29, -3534.86, 72.72);
	vendorDB:addVendor("Innkeeper Adegwa", 1, 2, 2, false, false, true, false, false, -912.38, -3524.92, 72.68);

	-- Gadgetzan
	vendorDB:addVendor("Krinkle Goodsteel", 0, 1, 17, true, false, false, false, false, -7200.44, -3769.83, 8.67); -- repair
	vendorDB:addVendor("Krinkle Goodsteel", 1, 1, 17, true, false, false, false, false, -7200.44, -3769.83, 8.67); -- repair
	vendorDB:addVendor("Blizrik Buchshot", 0, 1, 17, false, false, false, false, true, -7141.5, -3719.69, 8.49); -- bullet	
	vendorDB:addVendor("Blizrik Buchshot", 1, 1, 17, false, false, false, false, true, -7141.5, -3719.69, 8.49); -- bullet	
	vendorDB:addVendor("Innkeeper Fizzgrimble", 0, 1, 17, false, true, true, false, false, -7159.08, -3841.72, 8.68); -- drinks, meat
	vendorDB:addVendor("Innkeeper Fizzgrimble", 1, 1, 17, false, true, true, false, false, -7159.08, -3841.72, 8.68); -- drinks, meat

	-- Thrallmar
	vendorDB:addVendor("Rohok", 1, 3, 2, true, false, false, false, false, 167.27, 2795.66, 113.36);
	vendorDB:addVendor("Floyd Pinkus", 1, 3, 2, false, true, true, false, false, 190.87, 2610.92, 87.28);

	DEFAULT_CHAT_FRAME:AddMessage('vendorDB: loaded...');
end

function vendorDB:GetVendorByID(id)
	return self.vendorList[id];
end

function vendorDB:GetVendor(faction, continentID, mapID, canRepair, needFood, needWater, needArrow, needBullet, posX, posY, posZ)
	local bestDist = 10000;
	local bestIndex = -1;
	
	-- Removed the map id check, not needed, always go for the closest

	for i=0,self.numVendors - 1 do
		if(self.vendorList[i]['faction'] == faction and self.vendorList[i]['continentID'] == continentID) then			
			if((needFood and self.vendorList[i]['hasFood'] or not needFood) and (needWater and self.vendorList[i]['hasWater'] or not needWater)
			and (needArrow and self.vendorList[i]['hasArrow'] or not needArrow) and (needBullet and self.vendorList[i]['hasBullet'] or not needBullet) and (canRepair and self.vendorList[i]['canRepair'] or not canRepair)) then
				local _dist = script_helper:distance3D(posX, posY, posZ, self.vendorList[i]['pos']['x'], self.vendorList[i]['pos']['y'], self.vendorList[i]['pos']['z']);
				if(_dist < bestDist) then
					bestDist = _dist;
					bestIndex = i;
				end
			end
		end
	end
	return bestIndex;
end

function vendorDB:loadDBVendors()
	local localObj = GetLocalPlayer();
	local x, y, z = GetPosition(localObj);
	local factionID = 1; -- horde
	local faction, __ = UnitFactionGroup("player");
	if (faction == 'Alliance') then
		factionID = 0;
	end
	
	local repID, sellID, foodID, drinkID, arrowID, bulletID = -1, -1, -1, -1, -1, -1;

	repID = vendorDB:GetVendor(factionID, GetCurrentMapContinent(), GetCurrentMapZone(), true, false, false, false, false, x, y, z);
	sellID = vendorDB:GetVendor(factionID, GetCurrentMapContinent(), GetCurrentMapZone(), false, false, false, false, false, x, y, z);
	foodID = vendorDB:GetVendor(factionID, GetCurrentMapContinent(), GetCurrentMapZone(), false, true, false, false, false, x, y, z);
	drinkID = vendorDB:GetVendor(factionID, GetCurrentMapContinent(), GetCurrentMapZone(), false, false, true, false, false, x, y, z);
	arrowID = vendorDB:GetVendor(factionID, GetCurrentMapContinent(), GetCurrentMapZone(), false, false, false, true, false, x, y, z);
	bulletID = vendorDB:GetVendor(factionID, GetCurrentMapContinent(), GetCurrentMapZone(), false, false, false, false, true, x, y, z);

	if (repID ~= -1) then
		script_vendorEX.repairVendor = vendorDB:GetVendorByID(repID);
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Repair vendor ' .. script_vendorEX.repairVendor['name'] .. ' loaded from DB...');
	end

	if (sellID ~= -1) then
		script_vendorEX.sellVendor = vendorDB:GetVendorByID(sellID);
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Sell vendor ' .. script_vendorEX.sellVendor['name'] .. ' loaded from DB...');
	end

	if (foodID ~= -1) then
		script_vendorEX.foodVendor = vendorDB:GetVendorByID(foodID);
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Food vendor ' .. script_vendorEX.foodVendor['name'] .. ' loaded from DB...');
	end

	if (drinkID ~= -1) then
		script_vendorEX.drinkVendor = vendorDB:GetVendorByID(drinkID);
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Drink vendor ' .. script_vendorEX.drinkVendor['name'] .. ' loaded from DB...');
	end

	if (arrowID ~= -1) then
		script_vendorEX.arrowVendor = vendorDB:GetVendorByID(arrowID);
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Arrow vendor ' .. script_vendorEX.arrowVendor['name'] .. ' loaded from DB...');
	end

	if (bulletID ~= -1) then
		script_vendorEX.bulletVendor = vendorDB:GetVendorByID(bulletID);
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Bullet vendor ' .. script_vendorEX.bulletVendor['name'] .. ' loaded from DB...');
	end

	if (repID == -1 and sellID == -1 and foodID == -1 and drinkID == -1 and arrowID == -1 and bulletID == -1) then
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: No Vendor found close to our location in vendorDB...');
	end 
end