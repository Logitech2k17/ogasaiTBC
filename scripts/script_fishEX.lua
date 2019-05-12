script_fishEX = {

}

function script_fishEX:checkLure(lureName)
	hasMainHandEnchant, _, _, _, _, _ = GetWeaponEnchantInfo();
	if (hasMainHandEnchant == nil) then 
		-- Apply enhancement
		if (HasItem(lureName)) then

			-- Check: Stop moving, sitting
			if (not IsStanding() or IsMoving()) then 
				StopMoving(); 
				return true;
			end 

			UseItem(lureName);
			PickupInventoryItem(16);
			script_fish.message = "Applying " .. lureName .. " on fish pole.";
		else
			return false;
		end
		return true;
	end
	return false;
end

function script_fishEX:GetBobber()
	local localGUID = GetGUID(GetLocalPlayer());
	local obj_, type_ = GetFirstObject();
	while obj_ ~= 0 do
		if (type_ == 5) then
			if (GetCreatorsGUID(obj_) == localGUID and GetObjectDisplayID(obj_) == 668) then
				if (obj_ == script_fish.bobberInfo.GUID) then
					if (not script_fish.bobberInfo.looted) then
						return obj_;
					end				
				else
					if (GetObjectState(obj_) ~= 0) then
						return obj_;
					end
				end
			end
		end
		obj_, type_ = GetNextObject(obj_);
	end
	return 0;
end

function script_fishEX:menu()
		Text('Status: ' .. script_fish.message);
		Text('Script Idle: ' .. (script_fish.timer - GetTimeEX()) .. ' ms');
		if (not script_fish.pause) then if Button('Pause') then script_fish.pause = true; end
		else if Button('Resume') then script_fish.pause = false; end end
		if Button('Set current location as fishing position') then
			script_fish.fishPos['x'], script_fish.fishPos['y'], script_fish.fishPos['z'] = 
				GetUnitsPosition(GetLocalPlayer());
		end			
		Separator();
		Text("Fishing Pole Name");
		script_fish.PoleName = InputText("PN", script_fish.PoleName);
		Text("Lure Name");
		script_fish.lureName = InputText("LN", script_fish.lureName);
		Text("Weapon: Main Hand Name");
		script_fish.weaponMainHand = InputText("MH", script_fish.weaponMainHand);
		Text("Weapon: Off Hand Name");
		script_fish.weaponOffHand = InputText("OH", script_fish.weaponOffHand);
		local wasClicked = false;
		wasClicked, script_fish.useVendor = Checkbox("Use Vendor", script_fish.useVendor);
		if (script_fish.useVendor) then
			Text('Please select a sell vendor!');
			script_vendorMenu:menu();
		end
end
