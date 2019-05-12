script_druid = {
	version = '0.1',
	message = 'Druid Combat',
	eatHealth = 50,
	drinkMana = 50,
	isSetup = false,
	timer = 0,
	rejuHealth = 80,
	healHealth = 40,
	regrowthHealth = 60,
	healHealthWhenShifted = 40,
	cat = false,
	bear = false,
	stayCat = false,
	moonFireTime = GetTimeEX(),
	tigerTime = GetTimeEX(),
	rakeTime = GetTimeEX(),
	pulled = false
}

function script_druid:setup()
	-- Sort forms
	if (HasSpell('Cat Form')) then
		self.cat = true;
	elseif (HasSpell('Bear Form')) then
		self.bear = true;
	end

	self.timer = GetTimeEX();
	DEFAULT_CHAT_FRAME:AddMessage('script_druid: loaded...');
	self.isSetup = true;
end

function script_druid:run(targetObj)

	if(not self.isSetup) then script_druid:setup(); return; end

	local localObj = GetLocalPlayer();
	local localMana = GetManaPercentage(localObj);
	local localHealth = GetHealthPercentage(localObj);
	local targetHealth = GetHealthPercentage(targetObj);

	if (targetObj == 0) then
		targetObj = GetTarget();
	end

	local targetGUID = GetTargetGUID(targetObj);

	-- Pre Check
	if (IsChanneling() or IsCasting()) then return; end

	self.timer = GetTimeEX() + 250;
	
	--Valid Enemy
	if (targetObj ~= 0) then
		
		-- Cant Attack dead targets
		if (IsDead(targetObj)) then return; end
		
		if (not CanAttack(targetObj)) then return; end
		
		-- Combat
		if (IsInCombat()) then

			self.pulled = false;

			self.stayCat = false; -- Reset stay cat after combat

			FaceTarget(targetObj);
			AutoAttack(targetObj);

			-- Check: Rejuvenation
			if (localHealth < self.rejuHealth and localMana > 10 and not HasBuff(localObj, 'Rejuvenation') and HasSpell('Rejuvenation')) then
				if (HasBuff(localObj, 'Bear Form') and localHealth < self.healHealthWhenShifted and localMana > 20) then
					CastSpellByName('Bear Form');
					self.timer = GetTimeEX() + 750;
					return;
				elseif(HasBuff(localObj, 'Cat Form') and localHealth < self.healHealthWhenShifted and localMana > 35) then
					CastSpellByName('Cat Form');
					self.timer = GetTimeEX() + 750;
					return;
				end
			
				if (not HasBuff(localObj, 'Cat Form') and not HasBuff(localObj, 'Bear Form')) then
					if ((self.cat and localMana > 35) or (self.bear and localMana > 20) or (not self.cat and not self.bear)) then
						if (Buff("Rejuvenation", localObj)) then
							return;
						end
					end
				end
			end

			-- Check: Regrowth
			if (localHealth < self.regrowthHealth and localMana > 15 and not HasBuff(localObj, 'Regrowth') and HasSpell('Regrowth')) then
				
				-- Bash the target before we heal
				if (HasBuff(localObj, 'Bear Form') and HasSpell('Bash') and not IsSpellOnCD('Bash')) then
					if(Cast('Bash', targetGUID)) then
						return;
					end
				end

				if (HasBuff(localObj, 'Bear Form') and localHealth < self.healHealthWhenShifted and localMana > 20) then
					CastSpellByName('Bear Form');
					self.timer = GetTimeEX() + 750;
					return;
				elseif(HasBuff(localObj, 'Cat Form') and localHealth < self.healHealthWhenShifted and localMana > 35) then
					CastSpellByName('Cat Form');
					self.timer = GetTimeEX() + 750;
					return;
				end

				if (not HasBuff(localObj, 'Cat Form') and not HasBuff(localObj, 'Bear Form')) then
					if ((self.cat and localMana > 35) or (self.bear and localMana > 20) or (not self.cat and not self.bear)) then
						if (Buff("Regrowth", localObj)) then
							return;
						end
					end
				end
			end

			-- Check: Heal ourselves if below heal health, if we have mana for heal & shapeshift back
			if (localHealth < self.healHealth) then
				-- Bash the target before we heal
				if (HasBuff(localObj, 'Bear Form') and HasSpell('Bash') and not IsSpellOnCD('Bash')) then
					if(Cast('Bash', targetGUID)) then
						return;
					end
				end

				-- Shapeshift
				if (HasBuff(localObj, 'Bear Form') and localHealth < self.healHealthWhenShifted and localMana > 20) then
					CastSpellByName('Bear Form');
					self.timer = GetTimeEX() + 750;
					return;
				elseif(HasBuff(localObj, 'Cat Form') and localHealth < self.healHealthWhenShifted and localMana > 35) then
					CastSpellByName('Cat Form');
					self.timer = GetTimeEX() + 750;
					return;
				end
				
				-- Heal when not shapeshifted
				if (not HasBuff(localObj, 'Cat Form') and not HasBuff(localObj, 'Bear Form')) then
					if ((self.cat and localMana > 35) or (self.bear and localMana > 20) or (not self.cat and not self.bear)) then
						-- Heal
						if (Buff('Healing Touch', localObj)) then 
							self.timer = GetTimeEX() + 4000;
							return;
						end
					end
				end

				-- When we are not shapeshifted , but save mana for shapeshift
				if (not HasBuff(localObj, 'Cat Form') and not HasBuff(localObj, 'Bear Form') and localMana > 10) then

					-- Rejuvenation if not full HP
					if (localHealth < 98 and localMana and localMana > 35) then
						if (Buff("Rejuvenation", localObj)) then
							return;
						end
					end

					-- Moonfire before shapeshift
					if (self.moonFireTime < GetTimeEX() and HasSpell('Moonfire') and localMana > 35) then
						if (Cast('Moonfire', targetGUID)) then
							self.moonFireTime = GetTimeEX() + 12000;
							-- global CD
							self.timer = GetTimeEX() + 1500; 
							return;
						end
					end

					-- Wrath if we don't have bear or cat
					if (not self.cat and not self.bear) then
						if (Cast('Wrath', targetGUID)) then
							return;
						end
					end
				end
			end

			if (not self.cat and not self.bear) then
				-- Moonfire before shapeshift
				if (self.moonFireTime < GetTimeEX() and HasSpell('Moonfire') and localMana > 35) then
					if (Cast('Moonfire', targetGUID)) then
						self.moonFireTime = GetTimeEX() + 12000;
						-- global CD
						self.timer = GetTimeEX() + 1500; 
						return;
					end
				end

				-- Wrath if we don't have bear or cat
				if (not self.cat and not self.bear) then
					if (Cast('Wrath', targetGUID)) then
						return;
					end
				end
			end

			-- Shapeshift
			if (self.cat and not HasBuff(localObj, 'Cat Form')) then
				CastSpellByName('Cat Form');
				return;
			elseif (self.bear and not HasBuff(localObj, 'Bear Form')) then
				CastSpellByName('Bear Form');
				return;
			end

			-- Check if we are in meele range
			if (GetDistance(targetObj) > 5) then
				MoveToTarget(targetObj);
				if (script_grind.waitTimer ~= 0) then
					script_grind.waitTimer = GetTimeEX() + 1500;
				end
				return;
			else
				if (IsMoving()) then
					StopMoving();
					return;
				end
			end

			-- Cat form
			if (self.cat) then
				local energy = GetEnergy(localObj);
				local cp = GetComboPoints("player", "target");

				-- Keep mangle up
				if (HasSpell('Mangle (Cat)') and not script_target:hasDebuff("Mangle")) then
					if (energy < 40) then return; end
					if (Cast('Mangle (Cat)', targetGUID)) then
						return;
					end
				end

				-- Buff: Tiger Fury
				if (HasSpell("Tiger's Fury") and not IsSpellOnCD("Tiger's Fury") and self.tigerTime < GetTimeEX()) then
					if (targetHealth > 50 and energy >= 30) then
						self.tigerTime = GetTimeEX() + 6000;
						CastSpellByName("Tiger's Fury");
						return;
					end
				end

				-- Finisher Logic, when 5 CPs or target has low HP
				if (cp == 5 or (cp*10) >= targetHealth) then

					-- Ferocious Bite
					if (HasSpell('Ferocious Bite')) then
						if (energy < 45) then
							return; 
						else
							if (Cast('Ferocious Bite', targetGUID)) then
								return;
							end
						end
					else	
						-- Rip 
						if (energy < 30) then
							return 0;
						else
							if (Cast('Rip', targetGUID)) then
								return;
							end
						end
					end
				end

				-- Keep Rake Up
				if (HasSpell('Rake') and not script_target:hasDebuff(Rake)) then
					if (energy <= 40) then
						return; -- save energy for rake
					else
						if (Cast('Rake', targetGUID)) then
							return;
						end
					end
				end

				-- Claw to get CP's
				if (not IsSpellOnCD('Claw') and energy >= 45) then
					if (Cast('Claw', targetGUID)) then
						return;
					end
				end
			end

			-- Bear form
			if (self.bear) then
				local rage = GetRagePercentage(localObj);

				if (script_info:nrTargetingMe() >= 1) then
					-- Demoralizing roar
					if (not script_target:hasDebuff('Demoralizing Roar') and HasSpell('Demoralizing Roar')) then
						if (rage < 10) then
							return; -- save rage
						else
							CastSpellByName('Demoralizing Roar');
							return;
						end
					end

					-- Swipe
					if (HasSpell('Swipe')) then
						if (rage < 15) then
							return; -- save rage
						else
							if (Cast('Swipe', targetGUID)) then
								return;
							end
						end						
					end
				end
				
				-- Maul
				if (rage >= 15) then
					if(Cast('Maul', targetGUID)) then
						return;
					end
				end					
			end

			return;
		
		else	
		-- Oponer

			-- Go human form if in bear to pull
			if (HasBuff(localObj, 'Bear Form')) then
				CastSpellByName('Bear Form');
				self.timer = GetTimeEX() + 750;
				return;
			end

			-- Go human form if in cat, before we got Faeri Fire
			if (HasBuff(localObj, 'Cat Form')) then
				CastSpellByName('Cat Form');
				self.timer = GetTimeEX() + 750;
				return;
			end

			-- Wrath
			if (GetDistance(targetObj) < 30 and not self.pulled) then
				if (IsMoving()) then StopMoving(); return; end

				if (HasBuff(localObj,'Bear Form')) then return; end

				if (Cast('Wrath', targetGUID)) then self.pulled = true; return; end
			end

			if (Cast('Faerie Fire', targetGUID)) then return; end

			if (GetDistance(targetObj) > 5) then
				-- Set the grinder to wait for momvement
				if (script_grind.waitTimer ~= 0) then
					script_grind.waitTimer = GetTimeEX()+1500;
				end
				MoveToTarget(targetObj);
				return;
			else
				FaceTarget(targetObj);
				AutoAttack(targetObj);
				if (Cast('Attack', targetGUID)) then return; end
			end

			return;
		end
	end
end

function script_druid:rest()
	if(not self.isSetup) then script_druid:setup(); return; end
	if (self.timer > GetTimeEX()) then return true; end
	if (IsCasting()) then return true; end
	self.timer = GetTimeEX() + 250;

	local localObj = GetLocalPlayer();
	local localHealth = GetHealthPercentage(localObj);
	local localMana = GetManaPercentage(localObj);
	-- Update rest values
	if (script_grind.restHp ~= 0) then
		self.eatHealth = script_grind.restHp;
		self.drinkMana = script_grind.restMana;
	end
	-- Stay shapeshifted if we have hp!
	if (HasBuff(localObj, 'Cat Form') or HasBuff(localObj, 'Bear Form')) then
		if (localHealth > 90) then
			script_grind:restOff();
			return;
		end
	end
	-- Leave shape shift form
	if ((localHealth < self.eatHealth or localMana < self.drinkMana) and not self.stayCat) then
		if (HasBuff(localObj, 'Cat Form')) then
			CastSpellByName('Cat Form');
			script_grind:restOn();
			return true;
		end
		if (HasBuff(localObj, 'Bear Form')) then
			CastSpellByName('Bear Form');
			script_grind:restOn();
			return true;
		end
	end

	-- Heal if we are not shapeshifted
	if (not HasBuff(localObj, 'Cat Form') and not HasBuff(localObj, 'Bear Form')) then
		-- Stand up before healing
		if (not IsStanding() and not IsDrinking()) then
			StopMoving();
			script_grind:restOn();
			return true;
		end
		-- Heal up: Healing Touch
		if (localMana > 20 and localHealth < self.healHealth) then
			if (Buff('Healing Touch', localObj)) then
				self.timer = GetTimeEX() + 5000;
			end
			script_grind:restOn();
			return true;
		end
		-- Heal up: Regrowth
		if (localMana > 20 and localHealth < self.regrowthHealth and not HasBuff(localObj, 'Regrowth')) then
			if (Buff('Regrowth', localObj)) then
				script_grind:restOn();
				return true;
			end
		end

		-- Heal up: Rejuvenation
		if (localMana > 20 and localHealth < self.rejuHealth and not HasBuff(localObj, 'Rejuvenation')) then
			if (Buff('Rejuvenation', localObj)) then
				script_grind:restOn();
				return true;
			end
		end
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

	-- Buff
	if (not HasBuff(localObj, 'Cat Form') and not HasBuff(localObj, 'Bear Form')) then
		if (not HasBuff(localObj, 'Mark of the Wild') and HasSpell('Mark of the Wild')) then
			if (not Buff('Mark of the Wild', localObj)) then
				script_grind:restOn();
				return true;
			end
		end
		
		if (not HasBuff(localObj, 'Thorns') and HasSpell('Thorns')) then
			if (not Buff('Thorns', localObj)) then
				script_grind:restOn();
				return true;
			end
		end
	end
	script_grind:restOff();
	return false;
end

function script_druid:menu()
	if (CollapsingHeader("[Druid - Feral")) then
		Text('Healing Tresh Holds:');
		Separator();
		Text('Healing while Shapeshifted');
		self.healHealthWhenShifted = SliderFloat("HPS percent", 1, 99, self.healHealthWhenShifted);
		Text('Healing Touch');
		self.healHealth = SliderFloat("HT percent", 1, 99, self.healHealth);
		Text('Regrowth');
		self.regrowthHealth = SliderFloat("RG percent", 1, 99, self.regrowthHealth);
		Text('Rejuvenation');
		self.rejuHealth = SliderFloat("RJ percent", 1, 99, self.rejuHealth);
	end

end