script_priest = {
	version = '0.1',
	message = 'Priest Combat',
	drinkMana = 50,
	eatHealth = 50,
	isSetup = false,
	waitTimer = 0,
	renewHP = 90,
	shieldHP = 80,
	flashHealHP = 75,
	lesserHealHP = 60,
	healHP = 45,
	greaterHealHP = 20,
	useWand = true,
	wandMana = 10
}

function script_priest:draw()

end

function script_priest:setup()
	self.waitTimer = GetTimeEX();

	self.isSetup = true;

	DEFAULT_CHAT_FRAME:AddMessage('script_priest: loaded...');
end

function script_priest:healAndBuff(targetObject, localMana)

	local targetHealth = GetHealthPercentage(targetObject);
	
	-- Buff Fortitude
	if (localMana > 30 and not IsInCombat()) then
		if (Buff('Power Word: Fortitude', targetObject)) then 
			return true; 
		end
	end

	-- Renew
	if (localMana > 10 and targetHealth < self.renewHP and not HasBuff(targetObject, "Renew")) then
		if (Buff('Renew', targetObject)) then
			return true;
		end
	end

	-- Shield
	if (localMana > 10 and targetHealth < self.shieldHP and not HasDebuff(targetObject, "Weakened Soul") and IsInCombat()) then
		if (Buff('Power Word: Shield', targetObject)) then 
			return true; 
		end
	end

	-- Greater Heal
	if (localMana > 20 and targetHealth < self.greaterHealHP) then
		if (script_priest:heal('Heal', targetObject)) then
			return true;
		end
	end

	-- Heal
	if (localMana > 15 and targetHealth < self.healHP) then
		if (script_priest:heal('Heal', targetObject)) then
			return true;
		end
	end

	-- Lesser Heal
	if (localMana > 10 and targetHealth < self.lesserHealHP) then
		if (script_priest:heal('Lesser Heal', targetObject)) then
			return true;
		end
	end

	-- Flash Heal
	if (localMana > 8 and targetHealth < self.flashHealHP) then
		if (script_priest:heal('Flash Heal', targetObject)) then
			return true;
		end
	end
	
	return false;
end

function script_priest:heal(spellName, target, killTarget)
	if (HasSpell(spellName)) then 
		if (IsSpellInRange(target, spellName)) then 
			if (not IsSpellOnCD(spellName)) then 
				if (not IsAutoCasting(spellName)) then
					TargetEnemy(target); 
					CastSpellByName(spellName); 
					-- Wait for global CD before next spell cast
					self.waitTimer = GetTimeEX() + 1800;
					TargetEnemy(killTarget); 
					return true; 
				end 
			end 
		end 
	end
	return false;
end


function script_priest:run(targetObj)
	if(not self.isSetup) then
		script_priest:setup();
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
	if (targetObj ~= 0) then
		
		-- Cant Attack dead targets
		if (IsDead(targetObj)) then return; end
		if (not CanAttack(targetObj)) then return; end
		
		targetHealth = GetHealthPercentage(targetObj);

		if (HasSpell("Shadowform") and not HasBuff(localObj, "Shadowform")) then
			CastSpellByName("Shadowform");
			return;
		end
		
		--Opener
		if (not IsInCombat()) then
			-- Auto Attack
			if (GetDistance(targetObj) < 40) then AutoAttack(targetObj); end
			
			-- Opener
	
			if (Cast('Devouring Plague', targetGUID)) then
				self.waitTimer = GetTimeEX() + 200;
				return;
			end

			-- Mind Blast
			if (Cast('Mind Blast', targetGUID)) then
				self.waitTimer = GetTimeEX() + 200;
				return;
			end

			if (not HasBuff(localObj, "Shadowform")) then
				if (Cast('Smite', targetGUID)) then
					self.waitTimer = GetTimeEX() + 200;
					return;
				end
			end
			
			return;

		-- Combat
		else	

			-- Desperate prayer
			if (HasSpell("Desperate Prayer") and not IsSpellOnCD("Desperate Prayer") and not HasBuff(localObj, "Shadowform")) then
				if (localHealth < 10) then
					CastSpellByName("Desperate Prayer");
					return;
				end
			end			

			-- Cant heal with while in shadowform, use shield
			if (not HasBuff(localObj, "Shadowform")) then	
				if (script_priest:healAndBuff(localObj, localMana)) then 
					return; 
				end
			else
				-- Shield
				if (localMana > 10 and localHealth < self.shieldHP and not HasDebuff(localObj, "Weakened Soul")) then
					if (Buff('Power Word: Shield', localObj)) then 
						return; 
					end
				end
			end

			-- Check: Keep Shadow Word: Pain up
			if (not script_target:hasDebuff("Shadow Word: Pain")) then
				if (Cast('Shadow Word: Pain', targetGUID)) then 
					return; 
				end
			end

			-- Check: Keep Vampiric Embrace up
			if (not script_target:hasDebuff("Vampiric Embrace") and not IsSpellOnCD("Vampiric Embrace")) then
				if (Cast('Vampiric Embrace', targetGUID)) then 
					return; 
				end
			end

			-- Check: Keep Vampiric Touch up
			if (not script_target:hasDebuff("Vampiric Touch")) then
				if (Cast('Vampiric Touch', targetGUID)) then 
					return; 
				end
			end

			-- Wand if low mana or target is low
			local max = 0;
			local dur = 0;
			if (GetInventoryItemDurability(18) ~= nil) then
				dur, max = GetInventoryItemDurability(18);
			end

			if (self.useWand and dur > 0 and (localMana < self.wandMana or targetHealth <= 5)) then

				if (not script_target:autoCastingWand()) then 
					self.message = "Using wand...";
					FaceTarget(targetObj);
					CastSpell("Shoot", targetObj);
					self.waitTimer = GetTimeEX() + 500; 
					return;
				end
				
				return;
			end

			-- Auto Attack if no mana
			if (localMana < 5) then
				UnitInteract(targetObj);
			end

			-- Cast: Mind Blast
			if (Cast('Mind Blast', targetGUID)) then
				return; 
			end

			-- Mind Flay
			if (GetDistance(targetObj) < 20) then
				if (Cast('Mind Flay', targetGUID)) then 
					return; 
				end
			end

			-- Cast: Smite (last choice e.g. at level 1)
			if (not HasBuff(localObj, "Shadowform")) then
				if (Cast('Smite', targetGUID)) then 
					return; 
				end
			end
			
			return;	
		end
	
	end
end

function script_priest:rest()
	if(not self.isSetup) then script_priest:setup(); return true; end

	local localObj = GetLocalPlayer();
	local localMana = GetManaPercentage(localObj);
	local localHealth = GetHealthPercentage(localObj);

	if (localHealth < self.eatHealth and HasBuff(localObj, "Shadowform")) then
		CastSpellByName("Shadowform");
		script_grind:restOn();
		return true;
	end

	if (not HasBuff(localObj, "Shadowform")) then
		if (script_priest:healAndBuff(localObj, localMana)) then 
			script_grind:restOn();
			return true;
		end
	end
	
	-- Update rest values
	if (script_grind.restHp ~= 0) then self.eatHealth = script_grind.restHp; end
	if (script_grind.restMana ~= 0) then self.drinkMana = script_grind.restMana; end

	if (self.waitTimer > GetTimeEX()) then return true; end

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

function script_priest:menu()
	if (CollapsingHeader("[Priest - Shadow")) then
		local wasClicked = false;
		Text('Skills options:');
		Separator();
		wasClicked, self.useWand = Checkbox("Use Wand", self.useWand);
		self.wandMana = SliderInt("Mana to Wand", 1, 99, self.wandMana);
		self.renewHP = SliderInt("Renew HP", 1, 99, self.renewHP);
		self.shieldHP = SliderInt("Shield HP", 1, 99, self.shieldHP);
		self.flashHealHP = SliderInt("Flash HP", 1, 99, self.flashHealHP);
		self.lesserHealHP = SliderInt("Lesser HP", 1, 99, self.lesserHealHP);
		self.healHP = SliderInt("Heal HP", 1, 99, self.healHP);
		self.greaterHealHP = SliderInt("Greater HP", 1, 99, self.greaterHealHP);
	end
end
