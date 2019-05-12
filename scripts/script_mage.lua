script_mage = {
	version = '1.2',
	message = 'Mage Combat',
	FIRE = 1,
	FROST = 0,
	classType = 0,
	drinkMana = 25,
	eatHeath = 65,
	water = {},
	numWater = 0,
	food = {},
	numfood = 0,
	isSetup = false
}

function script_mage:addWater(name)
	self.water[self.numWater] = name;
	self.numWater = self.numWater + 1;
end

function script_mage:addFood(name)
	self.food[self.numfood] = name;
	self.numfood = self.numfood + 1;
end

function script_mage:setup()
	script_mage:addWater('Conjured Fresh Water');
	script_mage:addWater('Conjured Water');
	script_mage:addWater('Conjured Glacier Water');
	script_mage:addWater('Conjured Mountain Spring Water');
	script_mage:addWater('Conjured Crystal Water');
	script_mage:addWater('Conjured Sparkling Water');
	script_mage:addWater('Conjured Mineral Water');
	script_mage:addWater('Conjured Spring Water');
	script_mage:addWater('Conjured Purified Water');
	
	script_mage:addFood('Conjured Sourdough');
	script_mage:addFood('Conjured Sweet Roll');
	script_mage:addFood('Conjured Cinnamon Roll');
	script_mage:addFood('Conjured Croissant');
	script_mage:addFood('Conjured Muffin');
	script_mage:addFood('Conjured Bread');
	script_mage:addFood('Conjured Rye');
	script_mage:addFood('Conjured Pumpernickel');
	
	self.isSetup = true;
end

function script_mage:DeBugInfo()
	-- color
	local r = 255;
	local g = 2;
	local b = 233;
	
	-- position
	local y = 350;
	local x = 25;
	
	-- info
	DrawText(self.message, x, y, r, g, b);
end

function script_mage:init()
	--FOOD SETUP
end

function script_mage:prep()
	--CREAT FOOD
end

function script_mage:run(targetObj)
	
	script_mage:DeBugInfo();
	
	if(not self.isSetup) then
		script_mage:setup();
	end
	
	local localObj = GetLocalPlayer();
	local localMana = GetManaPercentage(localObj);
	local localHealth = GetHealthPercentage(localObj);
	local localLevel = GetLevel(localObj);
	
	if(targetObj == 0) then
		targetObj = GetNearestEnemy();
	end
	
	if (IsDead(localObj)) then
		--Grave();
		return;
	end

	-- Pre Check
	if (IsChanneling() or IsCasting()) then
		return;
	end

	-- Do Buff
	if (Buff('Arcane Intellect', localObj)) then
		return;
	elseif (Buff('Dampen Magic', localObj)) then
		return;
	elseif (Buff('Frost Armor', localObj)) then
		return;
	end
	
	--if (IsMoving()) then
	--	StopMoving();
	--	return;
	--end
	
	--Valid Enemy
	if (targetObj ~= 0) then
		
		-- Cant Attack dead targets
		if (IsDead(targetObj)) then
			return;
		end
		
		if (not CanAttack(targetObj)) then
			return;
		end
		
		-- Dismount
		DismountEX();
		
		-- Auto Attack
		--AutoAttack(targetObj);
		
		targetHealth = GetHealthPercentage(targetObj);
		
		--Opener
		if (not IsInCombat()) then
			
			--Cast Spell
			if (self.classType == self.FROST and Cast('Frostbolt', targetObj)) then
				return;
			elseif (self.classType == self.FIRE and Cast('Fireball', targetObj)) then
				return;
			end
			
		-- Combat
		else	
			-- Wand
			if (localMana <= 15 or targetHealth <= 15 and HasRangedWeapon(localObj)) then
				if (Cast('Shoot', targetObj)) then
					return;
				elseif (IsAutoCasting('Shoot')) then
					return;
				end
			end
			
			--
			if (targetHealth <= 45 and HasSpell('Fire Blast')) then
				castingTime, maxRange, minRange, powerType, Cost, spellID, spellObj = GetSpellInfoEX('Fire Blast');
				if (localManaVal > Cost and Cast('Fire Blast', targetObj)) then
					return;
				end
			end
			
			--Cast Spell
			if (self.classType == self.FROST and Cast('Frostbolt', targetObj)) then
				return;
			elseif (self.classType == self.FIRE and Cast('Fireball', targetObj)) then
				return;
			end
			
		end
	
	end
end

function script_mage:rest()

	if(not self.isSetup) then
		script_mage:setup();
	end
	
	local localObj = GetLocalPlayer();
	local localMana = GetManaPercentage(localObj);
	local localHealth = GetHealthPercentage(localObj);
	
	--Create Water
	local waterIndex = -1;
	for i=0,self.numWater do
		if (HasItem(self.water[i])) then
			waterIndex = i;
			break;
		end
	end
	
	if (waterIndex == -1) then 
		if (localMana > 10) then
			if (HasSpell('Conjure Water') and CastSpellByName('Conjure Water')) then
				return true;
			end
		end
	end

	
	--Create Food
	local foodIndex = -1;
	for i=0,self.numfood do
		if (HasItem(self.food[i])) then
			foodIndex = i;
			break;
		end
	end
	if (foodIndex == -1) then 
		if (localMana > 10) then
			if (HasSpell('Conjure Food') and CastSpellByName('Conjure Food')) then
				return true;
			end
		end
	end

	--Eat and Drink
	if (not IsDrinking() and localMana < self.drinkMana) then
		if (IsMoving()) then
			StopMoving();
			return true;
		end

		if(HasItem(self.water[waterIndex])) then
			UseItem(self.water[waterIndex]);
			return true;
		end
	end
	if (not IsEating() and localHealth < self.eatHeath) then	
		if (IsMoving()) then
			StopMoving();
			return true;
		end
		
		if(HasItem(self.food[foodIndex])) then
			UseItem(self.food[foodIndex]);
			return true;
		end
	end
	
	if(localMana < self.drinkMana or localHealth < self.eatHeath) then
		if (IsMoving()) then
			StopMoving();				
		end
		return true;
	end
	
	return false;
end

function script_mage:mount()

end

function script_mage:menu()

	if (CollapsingHeader("[Mage")) then
		Text('Mage Settings ' .. self.version);
		
		local wasClicked = false;	
		wasClicked, self.classType = RadioButton("Frost", self.classType, self.FROST);	
		wasClicked, self.classType = RadioButton("Fire", self.classType, self.FIRE);
		
		Separator();
		
		self.drinkMana = SliderFloat("Drink", 1, 100, self.drinkMana);
		self.eatHeath = SliderFloat("Eat", 1, 100, self.eatHeath);
	
		if (Button("LOAD")) then
			if (not LoadPath("Paths\\test.xml", 0)) then 
				DEFAULT_CHAT_FRAME:AddMessage('Failed to load TestGatherPath.xml');
			end
		end
	end
end
