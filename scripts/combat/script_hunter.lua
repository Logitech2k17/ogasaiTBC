script_hunter = {
	version = '1.0',
	message = 'Hunter Combat',
	bagWithPetFood = 4, -- 2nd last slot to the left
	slotWithPetFood = GetContainerNumSlots(3), -- last slot in the bag
	foodName = 'PET FOOD NAME',
	quiverBagNr = 5, -- last bag slot to the left
	drinkMana = 50,
	eatHealth = 50,
	isSetup = false,
	timer = 0,
	stopWhenNoPetFood = false,
	stopWhenQuiverEmpty = false,
	stopWhenBagsFull = false,
	buyWhenAmmoEmpty = true,
	ammoName = "",
	ammoIsArrow = true,
	extraScript = include("scripts\\combat\\script_hunterEX.lua")
}

-- Only the functions setup, run, rest and menu are located in this file
-- See script_hunterEX for more "hunter" functions

function script_hunter:setup()
	self.timer = GetTimeEX();

	script_hunterEX:setup();

	DEFAULT_CHAT_FRAME:AddMessage('script_hunter: loaded...');

	-- Save the name of ammo we use, only checks the last slot on the bag
	local bagSlot = GetContainerNumSlots(self.quiverBagNr-1);
	if (GetContainerItemLink(self.quiverBagNr-1, bagSlot)  ~= nil) then
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
   		itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(GetContainerItemLink(self.quiverBagNr-1, bagSlot));
		self.ammoName = itemName;
		DEFAULT_CHAT_FRAME:AddMessage('script_hunter: Ammo name is set to: "' .. self.ammoName .. '" ...');
		if (not strfind(itemName, "Arrow")) then
			DEFAULT_CHAT_FRAME:AddMessage('script_hunter: Ammo will be bought at "Bullet" vendors...');
			self.ammoIsArrow = false;
			script_vendorEX.bulletName = itemName;
		else
			DEFAULT_CHAT_FRAME:AddMessage('script_hunter: Ammo will be bought at "Arrow" vendors...');
			script_vendorEX.arrowName = itemName;
		end
	end

	-- Save the name of pet food we use
	if (GetContainerItemLink(self.bagWithPetFood-1, self.slotWithPetFood)  ~= nil) then
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
   		itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(GetContainerItemLink(self.bagWithPetFood-1, self.slotWithPetFood));
		self.foodName = itemName;
		DEFAULT_CHAT_FRAME:AddMessage('script_hunter: Pet food name is set to: "' .. self.foodName .. '" ...');
	else
		DEFAULT_CHAT_FRAME:AddMessage('script_hunter: Please set the pet food name in hunter options...');
	end

	self.isSetup = true;
end

function script_hunter:buyAmmo()
	-- Quiver check : should we go buy ammo?
	if (self.buyWhenAmmoEmpty and self.ammoName ~= 0) then
		local ammoNr = 0;
		for y=1,GetContainerNumSlots(self.quiverBagNr-1) do
			local texture, itemCount, locked, quality, readable = GetContainerItemInfo(self.quiverBagNr-1,y);
			if (itemCount ~= nil) then 
				ammoNr = ammoNr + 1; 
			end 
		end

		-- Go buy ammo if we have just 1 stack of ammo left
		if (ammoNr <= 1 and self.ammoName ~= 0) then
			if (self.ammoIsArrow and script_vendorEX.arrowVendor ~= 0) then
				script_vendor:buy(self.ammoName, (GetContainerNumSlots(self.quiverBagNr-1)-1), false, false, true, false);
				return true;
			elseif (script_vendorEX.bulletVendor ~= 0) then
				script_vendor:buy(self.ammoName, (GetContainerNumSlots(self.quiverBagNr-1)-1), false, false, false, true);
				return true;
			end
			return false;
		end 
	end
end

function script_hunter:run(targetObj)
	if(not self.isSetup) then
		script_hunter:setup();
		return;
	end

	local localObj = GetLocalPlayer();
	local localMana = GetManaPercentage(localObj);
	local localHealth = GetHealthPercentage(localObj);
	local localLevel = GetLevel(localObj);

	if (targetObj == 0) then
		targetObj = GetTarget();
	end

	local targetGUID = GetTargetGUID(targetObj);

	-- Check: Do we have a pet?
	if (script_hunterEX.hasPet) then if (localLevel < 10) then script_hunterEX.hasPet = false; end end
	local pet = GetPet(); local petHP = 0;
	if (pet ~= nil and pet ~= 0) then petHP = GetHealthPercentage(pet); end

	-- Pre Check
	if (IsChanneling() or IsCasting() or self.timer > GetTimeEX()) then return; end
	
	--Valid Enemy
	if (targetObj ~= 0) then
		-- Cant Attack dead targets
		if (IsDead(targetObj)) then return; end
		if (not CanAttack(targetObj)) then return; end
		
		targetHealth = GetHealthPercentage(targetObj);
		script_hunterEX:chooseAspect(targetGUID);

		-- Check if we have ammo
		local hasAmmo = script_helper:hasAmmo();
		
		--Opener
		if (not IsInCombat()) then

			if (hasAmmo) then
				if (script_hunterEX:doOpenerRoutine(targetGUID)) then
					script_grind.waitTimer = GetTimeEX() + 1950;
					return;
				end
			end

			-- Check move into meele range
			if (GetDistance(targetObj) > 5) then
				if (script_grind.waitTimer ~= 0) then
					script_grind.waitTimer = GetTimeEX() + 1250;
				end
				MoveToTarget(targetObj);
				return;
			else
				FaceTarget(targetObj);
				AutoAttack(targetObj);
				if (Cast('Raptor Strike', targetGUID)) then 
					return; 
				end
			end

		-- Combat
		else	

			if (script_hunterEX:mendPet(localMana, petHP)) then
				self.timer = GetTimeEX() + 1850;
				return;
			end
			
			if (script_hunterEX:doInCombatRoutine(targetGUID, localMana)) then
				self.timer = GetTimeEX() + 1850;
				return;
			else
				if (script_grind.waitTimer ~= 0) then
					script_grind.waitTimer = GetTimeEX() + 1250;
				end
				MoveToTarget(targetObj);
				return;
			end

			return;	
		end
	
	end
end

function script_hunter:rest()
	if(not self.isSetup) then script_hunter:setup(); return true; end

	local localObj = GetLocalPlayer();
	local localMana = GetManaPercentage(localObj);
	local localHealth = GetHealthPercentage(localObj);

	-- Update rest values
	if (script_grind.restHp ~= 0) then self.eatHealth = script_grind.restHp; end
	if (script_grind.restMana ~= 0) then self.drinkMana = script_grind.restMana; end

	if (self.timer > GetTimeEX()) then return true; end

	-- Check: Let the feed pet duration last, don't engage new targets
	if (script_hunterEX.feedTimer > GetTimeEX() and not IsInCombat() and script_hunterEX.hasPet and GetPet() ~= 0) then 
		self.message = "Feeding the pet, pausing...";
		if (GetDistance(GetPet()) > 8) then
			PetFollow();
			self.timer = GetTimeEX() + 1750;
			script_grind:restOn();
			return true;
		end
		script_grind:restOn();
		return true;
	end


	-- Eat and Drink
	if (not IsDrinking() and localMana < self.drinkMana) then
		if (IsMoving()) then
			StopMoving();
			script_grind:restOn();
			return true;
		end

		if(script_helper:drinkWater()) then
			script_grind:restOn();
			return true;
		end
	end

	if (not IsEating() and localHealth < self.eatHealth) then	
		if (IsMoving()) then
			StopMoving();
			script_grind:restOn();
			return true;
		end
		
		if(script_helper:eat()) then
			script_grind:restOn();
			return true;
		end
	end

	if(localMana < self.drinkMana or localHealth < self.eatHealth) then
		if (IsMoving()) then
			StopMoving();				
		end
		script_grind:restOn();
		return true;
	end

	if(IsDrinking() and localMana < 98) then
		script_grind:restOn();
		return true;
	end

	if(IsEating() and localHealth < 98) then
		script_grind:restOn();
		return true;
	end

	-- Check hunter bags if they are full
	local inventoryFull = script_helper:areBagsFull(self.quiverBagNr);

	if (inventoryFull) then
		script_grind:turnfOffLoot("bags are full...");
		if (self.stopWhenBagsFull) then
			self.message = "Bags are full...";
			if (IsMoving()) then StopMoving(); return true; end
			Logout(); StopBot(); return true; 
		end
	end

	-- Quiver check : Stop when out of ammo
	if (self.stopWhenQuiverEmpty and not IsInCombat() and not script_helper:hasAmmo()) then
		Logout(); StopBot(); return true; 	
	end


	-- Check for pet food, change bag/slot if we have too
	if (GetContainerItemLink(self.bagWithPetFood-1, self.slotWithPetFood)  == nil) then
		bagNr = 0;
		bagSlot = 0;
		for i = 0, 4 do
			if i ~= self.quiverBagNr-1 then
				for y = 0, GetContainerNumSlots(i) do
					if (GetContainerItemLink(i, y) ~= nil) then
						local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
   							itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(GetContainerItemLink(i, y));
						if (self.foodName == itemName) then
							self.bagWithPetFood = i+1;
							self.slotWithPetFood = y;
							break;
						end
					end
				end
			end
		end
	end

	-- Pet checks
	if (script_hunterEX:petChecks()) then script_grind:restOn(); return true; end

	-- Aspect check
	script_hunterEX:chooseAspect(targetObj);

	-- Check if we should buy ammo, don't call more than once
	if (script_vendor.status == 0) then if (script_hunter:buyAmmo()) then self.timer = GetTimeEX() + 10000; return false; end end

	script_grind:restOff();
	return false;
end

function script_hunter:menu()
	if (CollapsingHeader("[Hunter - Beastmaster")) then
		local wasClicked = false;
		wasClicked, self.buyWhenAmmoEmpty = Checkbox("Buy ammo when almost out", self.buyWhenAmmoEmpty);
		SameLine(); wasClicked, self.ammoIsArrow = Checkbox("Ammo is Arrows", self.ammoIsArrow);
		self.ammoName = InputText("Ammo Name", self.ammoName); 
		Separator();
		Text('Dont use Arcane Shot below mana percent:');
		script_hunterEX.arcaneMana = SliderFloat("ASM", 1, 99, script_hunterEX.arcaneMana);
		wasClicked, script_hunterEX.useCheetah = Checkbox("Use Aspect of the Cheetah", script_hunterEX.useCheetah);
		Separator();
		Text("Bag# with pet food (1-5)");
		self.bagWithPetFood = InputText("BPF", self.bagWithPetFood);
		Text("Slot# with pet food (1-MaxSlot)");
		self.slotWithPetFood = InputText("SPF", self.slotWithPetFood);
		Text('Pet food name:');
		self.foodName = InputText("PFN", self.foodName);
		Separator();
		Text("Bag# for quiver (2-5)");
		self.quiverBagNr = InputText("QS", self.quiverBagNr);
		Separator();
		Text('Stop settings:');
		wasClicked, self.stopWhenBagsFull = Checkbox("Stop when bags are full", self.stopWhenBagsFull);
		wasClicked, self.stopWhenQuiverEmpty = Checkbox("Stop when we run out of ammo", self.stopWhenQuiverEmpty);
		wasClicked, self.stopWhenNoPetFood = Checkbox("Stop when we run out of pet food", self.stopWhenNoPetFood);
	end
end
