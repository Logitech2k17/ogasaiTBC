script_paladin = {
	version = '0.1',
	message = 'Paladin Combat',
	palaExtra = include("scripts\\combat\\script_paladinEX.lua"),
	drinkMana = 50,
	eatHealth = 50,
	isSetup = false,
	waitTimer = 0,
	healHealth = 40,
	bopHealth = 20,
	lohHealth = 8,
	consecrationMana = 50,
	aura = " ",
	blessing = 0
}

function script_paladin:draw()

end

function script_paladin:setup()
	self.waitTimer = GetTimeEX();

	DEFAULT_CHAT_FRAME:AddMessage('script_paladin: loaded...');

	script_paladinEX:setup();

	self.isSetup = true;
end

function script_paladin:run(targetObj)
	if(not self.isSetup) then
		script_paladin:setup();
		return;
	end

	local localObj = GetLocalPlayer();
	local localMana = GetManaPercentage(localObj);
	local localHealth = GetHealthPercentage(localObj);
	local localLevel = GetLevel(localObj);

	-- Pre Check
	if (IsChanneling() or IsCasting() or self.waitTimer > GetTimeEX()) then return; end

	if (targetObj == 0) then
		targetObj = GetTarget();
	end

	local targetGUID = GetTargetGUID(targetObj);

	--Valid Enemy
	if (targetObj ~= 0 and targetObj ~= nil) then
	
		-- Cant Attack dead targets
		if (IsDead(targetObj)) then return; end
		if (not CanAttack(targetObj)) then return; end
		
		targetHealth = GetHealthPercentage(targetObj);

		--Opener
		if (not IsInCombat()) then
			-- Auto Attack
			if (GetDistance(targetObj) < 40) then AutoAttackTarget(targetObj); end
			
			-- Opener
	
			-- Check: Exorcism
			if (GetCreatureType(targetObj) == "Demon" or GetCreatureType(targetObj) == "Undead") then
				if (GetDistance(targetObj) < 30 and HasSpell('Exorcism') and not IsSpellOnCD('Exorcism')) then
					if (Cast('Exorcism', targetGUID)) then 
						self.message = "Pulling with Exocism...";
						return;
					end
				end
			end

			-- Rightneoussness if we dont have seal of the crusader
			if (not HasSpell('Seal of the Crusader') and localMana > 10) then
				if (GetDistance(targetObj) < 15 and not script_paladinEX:isBuff("Seal of Righteousness")) then
					CastSpellByName('Seal of Righteousness');
					return; 
				end 
			end

			-- Check: Seal of the Crusader until we used judgement
			if (not script_target:hasDebuff("Judgement of the Crusder") and GetDistance(targetObj) < 15 and not script_paladinEX:isBuff("Seal of the Crusader")) then
				CastSpellByName('Seal of the Crusader');
				return;
			end 

			-- Check: Judgement when we have crusader
			if (GetDistance(targetObj) < 10  and script_paladinEX:isBuff('Seal of the Crusader') and not IsSpellOnCD('Judgement') and HasSpell('Judgement')) then
				CastSpellByName('Judgement'); self.waitTimer = GetTimeEX() + 2000; return true;
			end

			-- Check: Melee range
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
				FaceTarget(targetObj);
				AutoAttack(targetObj);
				CastSpellByName('Attack');
				if (Cast('Attack', targetGUID)) then 
					return; 
				end
			end
			
			return;

		-- Combat
		else	

			-- Check: Melee range
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

			FaceTarget(targetObj);
			AutoAttack(targetObj);

			-- Check: Use Lay of Hands
			if (localHealth < self.lohHealth and HasSpell('Lay on Hands') and not IsSpellOnCD('Lay on Hands')) then 
				if (Cast('Lay on Hands', targetGUID)) then 
					self.message = "Cast Lay on Hands...";
					return;
				end
			end
		
			-- Buff with Blessing
			if (self.blessing ~= 0 and HasSpell(self.blessing)) then
				if (localMana > 10 and not script_paladinEX:isBuff(self.blessing)) then
					Buff(self.blessing, localObj);
					return;
				end
			end
			
			-- Check: Divine Protection if BoP on CD
			if(localHealth < self.bopHealth and not HasDebuff(localObj, 'Forbearance')) then
				if (HasSpell('Divine Shield') and not IsSpellOnCD('Divine Shield')) then
					CastSpellByName('Divine Shield');
					self.message = "Cast Divine Shield...";
					return;
				elseif (HasSpell('Divine Protection') and not IsSpellOnCD('Divine Protection')) then
					CastSpellByName('Divine Protection');
					self.message = "Cast Divine Protection...";
					return;
				elseif (HasSpell('Blessing of Protection') and not IsSpellOnCD('Blessing of Protection')) then
					CastSpellByName('Blessing of Protection');
					self.message = "Cast Blessing of Protection...";
					return;
				end
			end

			-- Check: Heal ourselves if below heal health or we are immune to physical damage
			if (localHealth < self.healHealth or 
				((script_paladinEX:isBuff('Blessing of Protection') or script_paladinEX:isBuff('Divine Protection')) and localHealth < 90) ) then 

				-- Check: Stun with HoJ before healing if available
				if (GetDistance(targetObj) < 5 and HasSpell('Hammer of Justice') and not IsSpellOnCD('Hammer of Justice')) then
					if (Cast('Hammer of Justice', targetGUID)) then self.waitTimer = GetTimeEX() + 1750; return; end
				end
				
				if (Buff('Holy Light', localObj)) then 
					self.waitTimer = GetTimeEX() + 5000;
					self.message = "Healing: Holy Light...";
					return;
				end
			end

			-- Check: If we are in meele range, do meele attacks
			if (GetDistance(targetObj) < 5) then
				if (script_paladinEX:meleeAttack(GetTargetGUID(targetObj))) then return; end
			end
			
			return;	
		end
	
	end
end

function script_paladin:rest()
	if(not self.isSetup) then script_paladin:setup(); return true; end

	local localObj = GetLocalPlayer();
	local localMana = GetManaPercentage(localObj);
	local localHealth = GetHealthPercentage(localObj);

	-- Set aura
	if (self.aura ~= 0 and not IsMounted()) then
		if (not HasBuff(localObj, self.aura) and HasSpell(self.aura)) then
			CastSpellByName(self.aura); 
		end
	end

	-- Buff with Blessing
	if (self.blessing ~= 0 and HasSpell(self.blessing) and not IsMounted()) then
		if (localMana > 10 and not HasBuff(localObj, self.blessing)) then
			Buff(self.blessing, localObj);
			return false;
		end
	end
	
	-- Update rest values
	if (script_grind.restHp ~= 0) then self.eatHealth = script_grind.restHp; end
	if (script_grind.restMana ~= 0) then self.drinkMana = script_grind.restMana; end

	if (self.waitTimer > GetTimeEX()) then return true; end

	-- Heal up: Holy Light
	if (localMana > 20 and localHealth < self.eatHealth and HasSpell('Holy Light')) then
		if (Buff('Holy Light', localObj)) then
			script_grind.waitTimer = GetTimeEX() + 5000;
			self.message = "Healing: Holy Light...";
		end
		script_grind:restOn();
		return true;
	end

	-- Heal up: Flash of Light
	if (localMana > 10 and localHealth < 90 and HasSpell('Flash of Light')) then
		if (Buff('Flash of Light', localObj)) then
			script_grind.waitTimer = GetTimeEX() + 5000;
			self.message = "Healing: Flash of Light...";
		end
		script_grind:restOn();
		return true;
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
	
	script_grind:restOff();
	return false;
end

function script_paladin:menu()
	if (CollapsingHeader('[Paladin - Retribution')) then
		local wasClicked = false;
		Text('Aura and Blessing options:');
		self.aura = InputText("Aura", self.aura);
		self.blessing = InputText("Blessing", self.blessing);
		Separator();
		Text('HP percent to heal in combat:');
		self.healHealth = SliderFloat("HIC", 1, 99, self.healHealth);
		Text('Lay on Hands below HP percent');
		self.lohHealth = SliderFloat("LoH", 1, 99, self.lohHealth);
		Text('BoP below HP percent');
		self.bopHealth = SliderFloat("BoP", 1, 99, self.bopHealth);
	end
end