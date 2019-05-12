script_rogue = {
	version = '0.1',
	message = 'Rogue Combat',
	eatHealth = 50,
	isSetup = false,
	timer = 0,
	useStealth = false,
	useThrow = true,
	mainhandPoison = "Instant Poison",
	offhandPoison = "Instant Poison"
}

function script_rogue:setup()
	self.timer = GetTimeEX();
	DEFAULT_CHAT_FRAME:AddMessage('script_rogue: loaded...');
	self.isSetup = true;
end

function script_rogue:canRiposte()
	for i=1,132 do 
		local texture = GetActionTexture(i); 
		if texture ~= nil and string.find(texture,"Ability_Warrior_Challange") then
			local isUsable, _ = IsUsableAction(i); 
			if (isUsable == 1 and not IsSpellOnCD(Riposte)) then 
				return true; 
			end 
		end 
	end 
	return false;
end

function script_rogue:checkPoisons()
	hasMainHandEnchant, _, _,  hasOffHandEnchant, _, _ = GetWeaponEnchantInfo();
	if (hasMainHandEnchant == nil and HasItem(self.mainhandPoison)) then 
		-- Check: Stop moving, sitting
		if (not IsStanding() or IsMoving()) then 
			StopMoving(); 
			return; 
		end 
		-- Check: Dismount
		if (IsMounted()) then DisMount(); return true; end
		-- Apply poison to the main-hand
		self.message = "Applying poison to main hand..."
		UseItem(self.mainhandPoison); 
		PickupInventoryItem(16);  
		self.timer = GetTimeEX() + 6000; 
		return true;
	end
		
	if (hasOffHandEnchant == nil and HasItem(self.offhandPoison)) then
		-- Check: Stop moving, sitting
		if (not IsStanding() or IsMoving()) then 
			StopMoving(); 
			return; 
		end 
		-- Check: Dismount
		if (IsMounted()) then DisMount(); return true; end
		-- Apply poison to the off-hand
		self.message = "Applying poison to off hand..."
		UseItem(self.offhandPoison); 
		PickupInventoryItem(17); 
		self.timer = GetTimeEX() + 6000;  
		return true; 
	end

	return false;
end

function script_rogue:hasThrow()
	local id, texture, checkRelic = GetInventorySlotInfo("RangedSlot")
	local durability, max = GetInventoryItemDurability(id);
	if (durability ~= nil) then
		if (durability > 0) then
			return true;
		end
	end
	return false;
end

function script_rogue:run(targetObj)

	if(not self.isSetup) then script_rogue:setup(); return; end

	local localObj = GetLocalPlayer();
	local localEnergy = GetEnergy(localObj);
	local localHealth = GetHealthPercentage(localObj);
	local targetHealth = GetHealthPercentage(targetObj);

	-- Pre Check
	if (IsChanneling() or IsCasting() or self.timer > GetTimeEX()) then
		return;
	end

	if (targetObj == 0) then
		targetObj = GetTarget();
	end

	local targetGUID = GetTargetGUID(targetObj);

	-- Set pull range
	if (not self.useThrow) then
		script_grind.pullDistance = 4;
	else
		script_grind.pullDistance = 25;
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
		
		-- Combat
		if (IsInCombat()) then

			-- If too far away move to the target then stop
			if (GetDistance(targetObj) > 5) then 
				if (script_grind.combatStatus ~= nil) then
					script_grind.combatStatus = 1;
				end
				MoveToTarget(targetObj); 
				return; 
			else 
				if (script_grind.combatStatus ~= nil) then
					script_grind.combatStatus = 0;
				end
				if (IsMoving()) then 
					StopMoving(); 
				end 
			end 

			-- Check: Use Evasion
			if (HasSpell('Evasion') and not IsSpellOnCD('Evasion')) then
				if (localHealth < targetHealth and localHealth < 50) then
					CastSpellByName('Evasion');
					return; 
				end
			end

			-- Check: Kick Spells
			if (HasSpell('Kick')) then
			local name, subText, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("target");
				if (name ~= nil) then
					if (Cast('Kick', targetGUID)) then 
						return;
					end 
				end
			end


			-- Check: If we are in meele range
			if (GetDistance(targetObj) < 5) then 

				-- Auto attack
				UnitInteract(targetObj);

				local add = script_info:addTargetingMe(targetObj);

				if (add ~= nil and HasSpell('Blade Flurry') and not IsSpellOnCD('Blade Flurry')) then
					if (GetDistance(add) < 5) then
						CastSpellByName("Blade Flurry");
						return;
					end
				end

				if (script_info:nrTargetingMe() >= 3) then
					if (HasSpell('Adrenaline Rush') and not IsSpellOnCD('Adrenaline Rush')) then
						CastSpellByName('Adrenaline Rush');
					end
				end

				-- Use Riposte when we can
				if(script_rogue:canRiposte() and HasSpell("Riposte")) then
					CastSpellByName("Riposte");
					return;
				end

				local cp = GetComboPoints(localObj);

				-- Eviscerate
				if (HasSpell('Eviscerate') and ((cp == 5) or targetHealth <= cp*10)) then 
					if (localEnergy >= 35) then
						CastSpellByName('Eviscerate');
						return;
					else
						-- save energy
						return;
					end
				end 

				-- Keep Slice and Dice up when 1-4 CP
				if (cp < 5 and cp > 0 and HasSpell('Slice and Dice') and targetHealth > 50) then 
					-- Keep Slice and Dice up
					if (not HasBuff(localObj, 'Slice and Dice') and targetHealth > 50 and localEnergy >= 25) then
						CastSpellByName('Slice and Dice'); 
					end 
				end

				-- Sinister Strike
				if (localEnergy >= 25) then CastSpellByName('Sinister Strike'); end 
			
				return;
			end
			
		-- Oponer
		else	
			-- Apply poisons 
			if (script_rogue:checkPoisons()) then return; end

			-- Check: Use Stealth before oponer
			if (self.useStealth and HasSpell('Stealth') and not HasBuff(localObj, 'Stealth')) then
				CastSpellByName('Stealth');
				return;
			else
				-- Check: Use Throw	
				if (self.useThrow and script_rogue:hasThrow()) then
					if (IsSpellOnCD('Throw')) then
						self.timer = GetTimeEX() + 4000;
						return;	
					end
					if (IsMoving()) then
						StopMoving();
						return;
					end
					if (Cast('Throw', targetGUID)) then 
						return;
					end 
					return;
				end
			end
			
			if (GetDistance(targetObj) > 5) then
				-- Set the grinder to wait for momvement
				if (script_grind.waitTimer ~= 0) then
					script_grind.waitTimer = GetTimeEX()+1250;
				end
				MoveToTarget(targetObj);
				return;
			else
				-- Auto attack
				UnitInteract(targetObj);

				if (Cast('Sinister Strike', targetGUID)) then 
					return; 
				end
				
			end

			return;
			
		end
	end
end

function script_rogue:rest()

	if(not self.isSetup) then script_rogue:setup(); return; end

	local localObj = GetLocalPlayer();
	local localHealth = GetHealthPercentage(localObj);

	-- Update rest values
	if (script_grind.restHp ~= 0) then
		self.eatHealth = script_grind.restHp;
	end

	--Eat 
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

	if(localHealth < self.eatHealth) then
		if (IsMoving()) then
			StopMoving();				
		end
		script_grind:restOn();
		return true;
	end

	if(IsEating() and localHealth < 98) then
		script_grind:restOn();
		return true;
	end

	script_grind:restOff();
	return false;
end

function script_rogue:menu()
	if (CollapsingHeader("[Rogue - Combat")) then
		Separator();
		local clickStealth = false;
		local clickThrow = false;
		Text('Pull options:');
		clickStealth, self.useStealth = Checkbox("Use Stealth", self.useStealth);
		SameLine();
		clickThrow, self.useThrow = Checkbox("Use Throw", self.useThrow);
		if (clickStealth) then self.useThrow = false; end
		if (clickThrow) then self.useStealth = false; end
		Separator();
		Text("Poison on Main Hand");
		self.mainhandPoison = InputText("PMH", self.mainhandPoison);
		Text("Poison on Off Hand");
		self.offhandPoison = InputText("POH", self.offhandPoison);
	end
end