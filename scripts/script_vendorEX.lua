script_vendorEX = {
	isSetup = false,
	keepItems = {},
	keepNum = 0,
	sellQuality = 2, -- 0-7 (1 = white, 2 = green)
	currentBag = 0,
	currentSlot = 0,
	sellPoor = true,
	sellCommon = true,
	sellUncommon = false,
	sellRare = false,
	sellEpic = false,
	selectedKeepItemNr = 0,
	addItemName = "",
	repairVendor = 0,
	sellVendor = 0,
	foodVendor = 0,
	drinkVendor = 0,
	arrowVendor = 0,
	bulletVendor = 0,
	foodName = "",
	drinkName = "",
	foodNr = 8,
	drinkNr = 8,
	arrowName = "",
	arrowNr = 7,
	bulletName = "",
	bulletNr = 7
}

function script_vendorEX:setup()
	DEFAULT_CHAT_FRAME:AddMessage('script_vendorEX: loaded...');
	-- Load DB
	vendorDB:setup();
	self.repairVendor, self.sellVendor, self.foodVendor, self.drinkVendor, self.arrowVendor, self.bulletVendor = 0, 0, 0, 0, 0, 0;
	-- Load Vendors from the DB
	vendorDB:loadDBVendors();
	self.keepItems = {};
	self.keepNum = 0;
	self.foodName = script_vendorEX:findFood();
	self.drinkName = script_vendorEX:findDrink();

	-- Put everything in our inventory at startup as "keep items" (won't be sold)
	for i = 0,4 do 
		for y=0,GetContainerNumSlots(i) do 
			if (GetContainerItemLink(i,y) ~= nil) then
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
   				itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(GetContainerItemLink(i,y));
				script_vendorEX:addSaveItem(itemName);
			end
		end 
	end

	self.isSetup = true;
end

function script_vendorEX:unloadVendor(itemIsFood, itemIsDrink, itemIsArrow, itemIsBullet)
	if (itemIsFood and self.foodVendor ~= 0) then
		DEFAULT_CHAT_FRAME:AddMessage("script_vendor: Unloading food vendor " .. self.foodVendor['name']);
		self.foodVendor = 0;
	end
	if (itemIsDrink and self.drinkVendor ~= 0) then
		DEFAULT_CHAT_FRAME:AddMessage("script_vendor: Unloading drink vendor " .. self.drinkVendor['name']);
		self.drinkVendor = 0;
	end
	if (itemIsArrow and self.arrowVendor ~= 0) then
		DEFAULT_CHAT_FRAME:AddMessage("script_vendor: Unloading arrow vendor " .. self.arrowVendor['name']);
		self.arrowVendor = 0;
	end
	if (itemIsBullet and self.bulletVendor ~= 0) then
		DEFAULT_CHAT_FRAME:AddMessage("script_vendor: Unloading bullet vendor " .. self.bulletVendor['name']);
		self.bulletVendor = 0;
	end
end

function script_vendorEX:checkVendor(minNr, useMana)
	local _f, foodLink = GetItemInfo(self.foodName);
	local _d, drinkLink = GetItemInfo(self.drinkName);
	local fNr = GetItemCount(foodLink);
	local dNr = GetItemCount(drinkLink);
	
	if (script_vendor.dontBuyTime > GetTimeEX()) then
		return false;
	end

	if (dNr <= minNr and self.drinkVendor ~= 0 and drinkLink ~= nil and useMana) then
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Amount of drinks less than ' .. minNr .. ', going to vendor...');
		script_vendor:buy(self.drinkName, self.drinkNr, false, true, false, false);
		return true;
		
	end

	if (fNr <= minNr and self.foodVendor ~= 0 and foodLink ~= nil) then
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Amount of food less than ' .. minNr .. ', going to vendor...');
		script_vendor:buy(self.foodName, self.foodNr, true, false, false, false);
		return true;
	end

	return false;
end

function script_vendorEX:findFood()
	for i = 0,4 do 
		for y=0,GetContainerNumSlots(i) do 
			if (GetContainerItemLink(i,y) ~= nil) then
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
   				itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(GetContainerItemLink(i,y));
				
				for u=0,script_helper.numFood-1 do
					if (strfind(itemName, script_helper.food[u])) then
						DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Food name is set to: "' .. script_helper.food[u] .. '" ...');
						return script_helper.food[u];
					end	
				end	
			end	
		end
	end

	return " ";
end

function script_vendorEX:findDrink()
	for i = 0,4 do 
		for y=0,GetContainerNumSlots(i) do 
			if (GetContainerItemLink(i,y) ~= nil) then
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
   				itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(GetContainerItemLink(i,y));
				
				for u=0,script_helper.numWater-1 do
					if (strfind(itemName, script_helper.water[u])) then
						DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Drink name is set to: "' .. script_helper.water[u] .. '" ...');
						return script_helper.water[u];
					end	
				end	
			end	
		end
	end

	return " ";
end

function script_vendorEX:buyItem(itemName, itemNum)
	local nrItems = GetMerchantNumItems();

	for i = 1, nrItems do

		name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(i);

		if (strfind(itemName, name)) then
			BuyMerchantItem(i, itemNum);
			return true;
		end
	end

	return false;
end

function script_vendorEX:sell()

	for i = self.currentBag,4 do 
		for y=self.currentSlot,GetContainerNumSlots(i) do 

			script_path:savePos(true); -- SAVE FOR UNSTUCK

			script_vendor.message = 'Selling, checking in bag: ' .. i ..' and slot ' .. y .. '...';

			-- At the last slot change status to idle again (sell routine done)
			if (i == 4 and y == GetContainerNumSlots(i)) then
				script_vendor.message = 'Finished selling...';
				script_vendor.status = 0; -- set status back to idle
			end

			-- Increase the slotID/BagID
			if (self.currentSlot == GetContainerNumSlots(i)) then
				self.currentSlot = 0;
				self.currentBag = self.currentBag + 1;
			else
				self.currentSlot = self.currentSlot + 1;
			end

			if (GetContainerItemLink(i,y) ~= nil) then

				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
   				itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(GetContainerItemLink(i,y));

				if (not script_vendorEX:keepItem(itemName) and itemRarity <= self.sellQuality
					and itemName ~= self.foodName and itemName ~= self.drinkName) then
					ShowContainerSellCursor(i,y);
					UseContainerItem(i,y, "target");
					return true;
				else
					return true;
				end
							
			end
		end
	end
	return true;
end

function script_vendorEX:canTrade()
	local canInteract = CheckInteractDistance("target", 2);
	if (canInteract == 1) then return true; end
	return false;
end

function script_vendorEX:getInfo()
	if (self.sellEpic) then
		return 'Unique keep items: ' .. self.keepNum-1 .. '. Sell: Epic items.';
	elseif (self.sellRare) then
		return 'Unique keep items: ' .. self.keepNum-1 .. '.Sell: Rare items.';
	elseif (self.sellUncommon) then
		return 'Unique keep items: ' .. self.keepNum-1 .. '. Sell: Uncommon items.';
	elseif (self.sellCommon) then
		return 'Unique keep items: ' .. self.keepNum-1 .. '. Sell: Common items.';
	elseif (self.sellPoor) then
		return 'Unique keep items: ' .. self.keepNum-1 .. '. Sell: Poor items.';
	else
		return 'Unique keep items: ' .. self.keepNum-1 .. '. Sell: Nothing.';
	end
end

function script_vendorEX:setSellQuality(sellPoor, sellCommon, sellUncommon, sellRare, sellEpic)
	if (sellEpic) then
		self.sellQuality = 4;
		return;
	elseif (sellRare) then
		self.sellQuality = 3;
		return;
	elseif (sellUncommon) then
		self.sellQuality = 2;
		return;
	elseif (sellCommon) then
		self.sellQuality = 1;
		return;
	elseif (sellPoor) then
		self.sellQuality = 0;
		return;
	else
		self.sellQuality = -1;
		return;
	end
end

function script_vendorEX:addSaveItem(name)
	-- Don't add multiple entries of the same item name
	if (not script_vendorEX:keepItem(name)) then
		self.keepItems[self.keepNum] = name;
		self.keepNum = self.keepNum + 1;
	end	
end

function script_vendorEX:deleteKeepItem(itemNr)
	local tempList = self.keepItems;
	self.keepItems = {};
	local x = 0;
	local y = 0;
	for i=0, self.keepNum-1 do
		if (i ~= itemNr) then
			self.keepItems[x] = tempList[y];
			x = x+1;
			y = y+1;
		else
			y = y+1;
		end
	end
	
	-- Correct the number of keep items
	self.keepNum = self.keepNum - 1;
	if (self.keepNum < 0) then
		self.keepNum = 0;
	end
end

function script_vendorEX:keepItem(name)
	for i = 0,self.keepNum-1 do
		if (strfind(self.keepItems[i], name)) then
			return true;
		end
	end
	
	return false; 
end

function script_vendorEX:setRepairVendor()
	if (GetTarget() ~= nil and GetTarget() ~= 0) then
		local name, realm = UnitName("target");
		self.repairVendor = nil;
		self.repairVendor = {};
		self.repairVendor['name'] = name;
		self.repairVendor['pos'] = {};
		self.repairVendor['pos']['x'], self.repairVendor['pos']['y'], self.repairVendor['pos']['z'] = GetPosition(GetTarget());
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Repair vendor set...');
		if (self.sellVendor == 0) then
			script_vendorEX:setSellVendor();
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: No vendor targeted...');
	end
end

function script_vendorEX:setSellVendor()
	if (GetTarget() ~= nil and GetTarget() ~= 0) then
		local name, realm = UnitName("target");
		self.sellVendor = nil;
		self.sellVendor = {};
		self.sellVendor['name'] = name;
		self.sellVendor['pos'] = {};
		self.sellVendor['pos']['x'], self.sellVendor['pos']['y'], self.sellVendor['pos']['z'] = GetPosition(GetTarget());
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Sell vendor set...');
	else
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: No vendor targeted...');
	end
end

function script_vendorEX:setFoodVendor()
	if (GetTarget() ~= nil and GetTarget() ~= 0) then
		local name, realm = UnitName("target");
		self.foodVendor = nil;
		self.foodVendor = {};
		self.foodVendor['name'] = name;
		self.foodVendor['pos'] = {};
		self.foodVendor['pos']['x'], self.foodVendor['pos']['y'], self.foodVendor['pos']['z'] = GetPosition(GetTarget());
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Food vendor set...');
		if (self.sellVendor == 0) then
			script_vendorEX:setSellVendor();
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: No vendor targeted...');
	end
end

function script_vendorEX:setDrinkVendor()
	if (GetTarget() ~= nil and GetTarget() ~= 0) then
		local name, realm = UnitName("target");
		self.drinkVendor = nil;
		self.drinkVendor = {};
		self.drinkVendor['name'] = name;
		self.drinkVendor['pos'] = {};
		self.drinkVendor['pos']['x'], self.drinkVendor['pos']['y'], self.drinkVendor['pos']['z'] = GetPosition(GetTarget());
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Drink vendor set...');
		if (self.sellVendor == 0) then
			script_vendorEX:setSellVendor();
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: No vendor targeted...');
	end
end

function script_vendorEX:setArrowVendor()
	if (GetTarget() ~= nil and GetTarget() ~= 0) then
		local name, realm = UnitName("target");
		self.arrowVendor = nil;
		self.arrowVendor = {};
		self.arrowVendor['name'] = name;
		self.arrowVendor['pos'] = {};
		self.arrowVendor['pos']['x'], self.arrowVendor['pos']['y'], self.arrowVendor['pos']['z'] = GetPosition(GetTarget());
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Arrow vendor set...');
		if (self.sellVendor == 0) then
			script_vendorEX:setSellVendor();
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: No vendor targeted...');
	end
end

function script_vendorEX:setBulletVendor()
	if (GetTarget() ~= nil and GetTarget() ~= 0) then
		local name, realm = UnitName("target");
		self.bulletVendor = nil;
		self.bulletVendor = {};
		self.bulletVendor['name'] = name;
		self.bulletVendor['pos'] = {};
		self.bulletVendor['pos']['x'], self.bulletVendor['pos']['y'], self.bulletVendor['pos']['z'] = GetPosition(GetTarget());
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Bullet vendor set...');
		if (self.sellVendor == 0) then
			script_vendorEX:setSellVendor();
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: No vendor targeted...');
	end
end