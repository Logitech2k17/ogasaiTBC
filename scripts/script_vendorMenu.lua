script_vendorMenu = {

}

function script_vendorMenu:menu()
	local wasClicked = false;

	if (CollapsingHeader("[Vendor options")) then 
		wasClicked, script_grind.useVendor = Checkbox("Vendor on/off", script_grind.useVendor);

		-- Always show a cancel button to any vendor actions
		if (script_vendor.status ~= 0) then 
			if Button("Cancel Current Vendor Action") then 
				script_vendor.message = "Idle..."; 
				script_vendor.status = 0; 
			end 
		end
		
		if (script_grind.useVendor) then

			if Button("Load Vendors from VendorDB.lua") then 
				vendorDB:loadDBVendors();
			end
			
			SameLine();
			if Button("Unload all Vendors") then 
				DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Unloading all vendors...');
				script_vendorEX.repairVendor = 0;
				script_vendorEX.sellVendor = 0;
				script_vendorEX.foodVendor = 0;
				script_vendorEX.drinkVendor = 0;
				script_vendorEX.arrowVendor = 0;
				script_vendorEX.bulletVendor = 0;
		 	end

			Separator();

			if (CollapsingHeader("Selling options")) then
				wasClicked, script_vendorEX.sellPoor = Checkbox("Sell poor items (grey)", script_vendorEX.sellPoor);
				wasClicked, script_vendorEX.sellCommon = Checkbox("Sell common items (white)", script_vendorEX.sellCommon);
				wasClicked, script_vendorEX.sellUncommon = Checkbox("Sell uncommon items (green)", script_vendorEX.sellUncommon);
				wasClicked, script_vendorEX.sellRare = Checkbox("Sell rare items (blue)", script_vendorEX.sellRare);
				wasClicked, script_vendorEX.sellEpic = Checkbox("Sell epic items (purple)", script_vendorEX.sellEpic);

				Separator();

				Text("Unique Keep Items:");
				wasClicked, script_vendorEX.selectedKeepItemNr = 
					ComboBox("", script_vendorEX.selectedKeepItemNr, unpack(script_vendorEX.keepItems));

				if Button("Remove") then
					script_vendorEX:deleteKeepItem(script_vendorEX.selectedKeepItemNr+1);
				end

				SameLine();
				Text(" - Removes selected item from the keep list...");

				if Button("Add Item") then
					script_vendorEX:addSaveItem(script_vendorEX.addItemName);
				end

				SameLine();
				script_vendorEX.addItemName = InputText("", script_vendorEX.addItemName);
				Text("Tip: All items in your bag will be added to the");
				Text("keep item list when reloading scripts...");
			end
			
			Separator();

			script_vendorMenu:NPCMenu();

			Separator();

			wasClicked, script_grind.vendorRefill = Checkbox("Refill food/drink at vendor", script_grind.vendorRefill); 
			Text("Refill food/drinks at vendor if less than: " .. script_grind.refillMinNr);
			SameLine(); if Button('+') then script_grind.refillMinNr = script_grind.refillMinNr+1; end
			SameLine(); if Button('-') then script_grind.refillMinNr = script_grind.refillMinNr-1; end
			wasClicked, script_grind.repairWhenYellow = Checkbox("Repair when gear is almost broken...", script_grind.repairWhenYellow);
			wasClicked, script_grind.sellWhenFull = Checkbox("Sell to a vendor when bags are full", script_grind.sellWhenFull);
			Separator();
		else
			wasClicked, script_grind.stopIfMHBroken = Checkbox("Stop bot if main hand is broken...", script_grind.stopIfMHBroken);
			Separator();
			Text("When bags are full:");
			local wasClicked = false;
			wasClicked, script_grind.hsWhenFull = Checkbox("Use Hearthstone", script_grind.hsWhenFull);
			SameLine(); wasClicked, script_grind.stopWhenFull = Checkbox("Stop the bot", script_grind.stopWhenFull);
		end
	end
end

function script_vendorMenu:NPCMenu()
	local wasClicked = false;

	if (CollapsingHeader("[NPC and Buy options")) then
		Text("Repair Vendor:");
		if (script_vendorEX.repairVendor ~= 0) then
			SameLine();
			Text('' .. script_vendorEX.repairVendor['name'] .. ' loaded.');
			if Button("Repair Now") then script_vendor.status = 1; end
		end

		if Button("Set current target as repair vendor") then script_vendorEX:setRepairVendor(); 									script_vendorMenu:printAddVendor(true, false, false, false, false); 
		end

		Separator();
		Text("Sell Vendor:");
		if (script_vendorEX.sellVendor ~= 0) then
			SameLine();
			Text('' .. script_vendorEX.sellVendor['name'] .. ' loaded.');
			if Button("Sell Now") then script_vendor.status = 2; end
		end
		if Button("Set current target as sell vendor") then 
			script_vendorEX:setSellVendor(); 
			script_vendorMenu:printAddVendor(false, false, false, false, false); 
		end

		Separator();
		Text("Buy Food Vendor:");
		if (script_vendorEX.foodVendor ~= 0) then
			SameLine();
			Text('' .. script_vendorEX.foodVendor['name'] .. ' loaded.');
			if Button("Buy Food Now") then 
				script_vendor.status = 3; 
				script_vendor.itemName = script_vendorEX.foodName;
				script_vendor.itemNum = script_vendorEX.foodNr;
				script_vendor.itemIsFood = true;
				script_vendor.itemIsDrink = false;
				script_vendor.itemIsAmmo = false;
			end

			SameLine();
			if Button("Cancel Buy Food") then script_vendor.message = "Idle..."; script_vendor.status = 0; end
		end
				
		Text("Input food name number of stacks:");
		script_vendorEX.foodName = InputText("Food", script_vendorEX.foodName); 
		SameLine(); script_vendorEX.foodNr = InputText("FX", script_vendorEX.foodNr);
		
		if Button("Set current target as food vendor") then 
			script_vendorEX:setFoodVendor(); 
			script_vendorMenu:printAddVendor(false, true, false, false, false); 
		end

		Separator();
		Text("Buy Drink Vendor:");
		if (script_vendorEX.drinkVendor ~= 0) then
			SameLine();
			Text('' .. script_vendorEX.drinkVendor['name'] .. ' loaded.');
			if Button("Buy Drink Now") then 
				script_vendor.status = 3; 
				script_vendor.itemName = script_vendorEX.drinkName;
				script_vendor.itemNum = script_vendorEX.drinkNr;
				script_vendor.itemIsFood = false;
				script_vendor.itemIsDrink = true;
				script_vendor.itemIsAmmo = false;
			end
			SameLine();
			if Button("Cancel Buy Drinks") then script_vendor.message = "Idle..."; script_vendor.status = 0; end
		end

		Text("Input drink name and number of stacks:");
		
		script_vendorEX.drinkName = InputText("Drink", script_vendorEX.drinkName); 
		
		SameLine(); script_vendorEX.drinkNr = InputText("DX", script_vendorEX.drinkNr);
		
		if Button("Set current target as drink vendor") then 
			script_vendorEX:setDrinkVendor(); 
			script_vendorMenu:printAddVendor(false, false, true, false, false); 
		end

		Separator();
		Text("Buy Arrow Vendor:");
		if (script_vendorEX.arrowVendor ~= 0) then
			SameLine();
			Text('' .. script_vendorEX.arrowVendor['name'] .. ' loaded.');
			if Button("Buy Arrows Now") then 
				script_vendor.status = 3; 
				script_vendor.itemName = script_vendorEX.arrowName;
				script_vendor.itemNum = script_vendorEX.arrowNr;
				script_vendor.itemIsFood = false;
				script_vendor.itemIsDrink = false;
				script_vendor.itemIsArrow = true;
				script_vendor.itemIsBullet = false;
			end
			
			SameLine();
			
			if Button("Cancel Buy Arrows") then 
				script_vendor.message = "Idle..."; 
				script_vendor.status = 0; 
			end
		end

		Text("Input arrow name and number of stacks:");
		
		script_vendorEX.arrowName = InputText("Arrow", script_vendorEX.arrowName); 
		
		SameLine(); script_vendorEX.arrowNr = InputText("AX", script_vendorEX.arrowNr);

		if Button("Set current target as arrow vendor") then 
			script_vendorEX:setArrowVendor();
			script_vendorMenu:printAddVendor(false, false, false, true, false); 
		end
		
		Separator();
		Text("Buy Bullets Vendor:");
		if (script_vendorEX.bulletVendor ~= 0) then
			SameLine();
			Text('' .. script_vendorEX.bulletVendor['name'] .. ' loaded.');
			if Button("Buy Bullets Now") then 
				script_vendor.status = 3; 
				script_vendor.itemName = script_vendorEX.bulletName;
				script_vendor.itemNum = script_vendorEX.bulletNr;
				script_vendor.itemIsFood = false;
				script_vendor.itemIsDrink = false;
				script_vendor.itemIsArrow = false;
				script_vendor.itemIsBullet = true;
			end
			
			SameLine();
			if Button("Cancel Buy Bullets") then 
				script_vendor.message = "Idle..."; 
				script_vendor.status = 0; 
			end
		end

		Text("Input bullet name and number of stacks:");
		script_vendorEX.bulletName = InputText("Bullet", script_vendorEX.bulletName); 
		SameLine(); script_vendorEX.bulletNr = InputText("BX", script_vendorEX.bulletNr);
		
		if Button("Set current target as bullet vendor") then 
			script_vendorEX:setBulletVendor(); 
			script_vendorMenu:printAddVendor(false, false, false, false, true); 
		end
	end
end

function script_vendorMenu:printAddVendor(canRepair, hasFood, hasWater, hasArrow, hasBullet)
	if (GetTarget() ~= 0 and GetTarget()~= nil) then
		local factionID = 1; -- horde
		local faction, __ = UnitFactionGroup("player");
		if (faction == 'Alliance') then
			factionID = 0;
		end
		local x, y, z = GetPosition(GetTarget());
		x = math.floor(x*100) / 100;
		y = math.floor(y*100) / 100;
		z = math.floor(z*100) / 100;
		local pos = ', ' .. x .. ', ' .. y .. ', ' .. z .. ");";
		DEFAULT_CHAT_FRAME:AddMessage('Add vendor to database by adding the line below in the setup() function in VendorDB.lua');
		DEFAULT_CHAT_FRAME:AddMessage('You can copy the line from logs//.txt');
		local addString = 'vendorDB:addVendor("' .. UnitName("target") .. '", ' .. factionID .. ', ' .. GetCurrentMapContinent() .. ', ' .. GetCurrentMapZone() .. ', '
			.. tostring(canRepair) .. ', ' .. tostring(hasFood) .. ', ' .. tostring(hasWater) .. ', ' .. tostring(hasArrow) .. ', ' ..tostring(hasBullet) .. pos;

		DEFAULT_CHAT_FRAME:AddMessage(addString);
		ToFile(addString);
	end
end

