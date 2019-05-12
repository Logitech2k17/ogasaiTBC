script_shaman = {
	version = '0.1',
	message = 'Enhancement Combat',
	drinkMana = 50,
	eatHealth = 50,
	isSetup = false,
	timer = 0,
	enhanceWeapon = 'Rockbiter Weapon',
	totem = 'no totem yet',
	totemBuff = '',
	healingSpell = 'Healing Wave'
}



function script_shaman:setup()
	self.timer = GetTimeEX();
	script_shaman:setSpells();
	DEFAULT_CHAT_FRAME:AddMessage('script_shaman: loaded...');
	self.isSetup = true;
end

function script_shaman:setSpells()
	-- Set weapon enhancement
	if (HasSpell('Windfury Weapon')) then
		self.enhanceWeapon = 'Windfury Weapon';
	elseif (HasSpell('Flametongue Weapon')) then
		self.enhanceWeapon = 'Flametongue Weapon';
	end

	-- Set totem
	if (HasSpell('Strength of Earth Totem') and HasItem('Earth Totem')) then
		self.totem = 'Strength of Earth Totem';
		self.totemBuff = 'Strength of Earth';
	elseif (HasSpell('Grace of Air Totem') and HasItem('Air Totem')) then
		self.totem = 'Grace of Air Totem';
		self.totemBuff = 'Grace of Air';
	end

	-- Set healing spell
	if (HasSpell('Lesser Healing Wave')) then
		self.healingSpell = 'Lesser Healing Wave';
	end
end

-- Checks and apply enhancement on the meele weapon
function script_shaman:checkEnhancement()
	hasMainHandEnchant, _, _, _, _, _ = GetWeaponEnchantInfo();
	if (hasMainHandEnchant == nil) then 
		-- Apply enhancement
		if (HasSpell(self.enhanceWeapon)) then

			-- Check: Stop moving, sitting
			if (not IsStanding() or IsMoving()) then 
				StopMoving(); 
				return true;
			end 

			CastSpellByName(self.enhanceWeapon);
			self.message = "Applying " .. self.enhanceWeapon .. " on weapon...";
		else
			return false;
		end
		return true;
	end
	return false;
end

function script_shaman:run(targetObj)

	if(not self.isSetup) then
		script_shaman:setup();
	end

	local localObj = GetLocalPlayer();
	local localMana = GetManaPercentage(localObj);
	local localHealth = GetHealthPercentage(localObj);
	local localLevel = GetLevel(localObj);

	targetHealth = GetHealthPercentage(targetObj);

	if (targetObj == 0) then
		targetObj = GetTarget();
	end

	local targetGUID = GetTargetGUID(targetObj);

	-- Pre Check
	if (IsChanneling() or IsCasting() or self.timer > GetTimeEX()) then
		return;
	end
	
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
		
		--Opener
		if (not IsInCombat()) then

			-- Update enhancement spells/totems
			script_shaman:setSpells();
			
			-- Enhancement on weapon
			if (script_shaman:checkEnhancement()) then
				return;
			end

			-- Pull with: Lighting Bolt
			if (Cast("Lightning Bolt", targetGUID)) then
				self.timer = GetTimeEX() + 4000;
				return;
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
				if (Cast('Attack', targetGUID)) then 
					return; 
				end
			end
			
			
		-- Combat
		else	

			-- Check: Lightning Shield
			if (not HasBuff(localObj, 'Lightning Shield')) then
				if (Buff("Lightning Shield", localObj)) then
					return;
				end
			end
			
			-- Earth Shock
			local name, subText, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("target");
			if (name ~= nil) then
				if (Cast("Earth Shock", targetGUID)) then
					return;
				end
			end

			-- If too far away move to the target then stop
			if (GetDistance(targetObj) > 5) then 
				if (script_grind.waitTimer ~= 0) then
					script_grind.waitTimer = GetTimeEX()+1250;
				end
				MoveToTarget(targetObj); 
				return; 
			else 
				if (IsMoving()) then 
					StopMoving(); 
				end 
			end 

			-- Check: If we are in meele range, do meele attacks
			if (GetDistance(targetObj) < 5) then
				
				FaceTarget(targetObj);
				AutoAttack(targetObj);

				-- Totem
				if (HasSpell(self.totem) and not HasBuff(localObj, self.totemBuff)) then
					CastSpellByName(self.totem);
					self.timer = GetTimeEX() + 1500;
				end

				-- Stormstrike
				if (HasSpell('Stormstrike') and not IsSpellOnCD('Stormstrike')) then
					if (Cast("Stormstrike", targetGUID)) then
						return;
					end
				end
			end

			return;
			
		end
	
	end
end

function script_shaman:rest()

	if(not self.isSetup) then
		script_shaman:setup();
		return true;
	end
	
	local localObj = GetLocalPlayer();
	local localMana = GetManaPercentage(localObj);
	local localHealth = GetHealthPercentage(localObj);

	-- Update rest values
	if (script_grind.restHp ~= 0) then
		self.eatHealth = script_grind.restHp;
	end

	if (script_grind.restMana ~= 0) then
		self.drinkMana = script_grind.restMana;
	end

	--Eat and Drink
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

	-- Keep us buffed: Lightning Shield
	if (Buff("Lightning Shield", localObj)) then
		return true;
	end

	if (script_shaman:checkEnhancement()) then
		return true;
	end
	
	script_grind:restOff();
	return false;
end

function script_shaman:mount()

end

function script_shaman:menu()

	if (CollapsingHeader("[Shaman - Enhancement")) then
		local wasClicked = false;	
		Text('No options yet...');
		Separator();
	end
end
