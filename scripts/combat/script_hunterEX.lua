script_hunterEX = {
	message = "Hunter extra functions",
	arcaneMana = 60,
	useCheetah = false,
	markTimer = 0,
	serpentTimer = 0,
	mendTimer = 0,
	feedTimer = 0,
	petTimer = 0,
	wingTimer = 0,
	hasPet = true,
	ammoName = 'Rough Arrow',
	ammoIsArrow = true,
	buyWhenAmmoEmpty = true
}

-- this file includes functions used by script_hunter

function script_hunterEX:setup()

	self.feedTimer = GetTimeEX();
	self.markTimer = GetTimeEX();
	self.serpentTimer = GetTimeEX();
	self.mendTimer = GetTimeEX();
	self.petTimer = GetTimeEX();
	self.wingTimer = GetTimeEX();

	DEFAULT_CHAT_FRAME:AddMessage('script_hunterEX: loaded...');
end

function script_hunterEX:doInCombatRoutine(targetGUID, localMana) 
	local targetObj = GetGUIDTarget(targetGUID);
	self.message = "Killing target...";
	local targetHealth = GetHealthPercentage(targetObj); -- update target's HP
	local pet = GetPet(); -- get pet

	if (not self.hasPet and HasSpell('Arcane Shot') and GetDistance(targetObj) > 13) then -- arcane early when no pet
		if (Cast('Arcane Shot', targetGUID)) then return true; end end

	if (self.hasPet and script_hunterEX:mendPet(GetManaPercentage(GetLocalPlayer()), GetHealthPercentage(pet))) then
		return true;
	end

	-- Check: If pet is too far away set it to follow us, else attack
	if (self.hasPet and GetPet() ~= 0) then if (GetDistance(pet) > 34) then PetFollow(); else PetAttack(); end end

	-- Check: Use Rapid Fire 
	if (HasSpell('Rapid Fire') and not IsSpellOnCD('Rapid Fire') and targetHealth > 80) then CastSpellByName('Rapid Fire'); return true; end

	-- Check: If pet is stunned, feared etc use Bestial Wrath
	if (self.hasPet and GetPet() ~= 0 and GetPet() ~= nil) then
		if ((IsStunned(pet) or IsConfused(pet) or IsFleeing(pet)) and UnitExists("Pet") and HasSpell('Bestial Wrath') and not IsSpellOnCD('Bestial Wrath')) then CastSpellByName('Bestial Wrath'); return true; end
	end

	-- Check: If in range, use range attacks
	if (GetDistance(targetObj) < 35 and GetDistance(targetObj) > 13) then
		if(script_hunterEX:doRangeAttack(targetGUID, localMana)) then return true; end 
	end

	if (GetDistance(targetObj) < 12 and GetDistance(targetObj) > 5) then
		return false;
	end

	-- Check: If we are in melee range, use meele abilities
	if (GetDistance(targetObj) < 5) then
		-- Meele Skill: Raptor Strike
		if (localMana > 10 and not IsSpellOnCD('Raptor Strike')) then 
			if (Cast('Raptor Strike', targetGUID)) then 
				return true; 
			end 
		end
		-- Meele Skill: Wing Clip (keeps the debuff up)
		if (self.wingTimer < GetTimeEX() and localMana > 10 and not HasDebuff(targetObj, 'Wing Clip') and HasSpell('Wing Clip')) then 
			if (Cast('Wing Clip', targetGUID)) then 
				self.wingTimer = GetTimeEX() + 10000;
				return true; 
			end 
		end
	end

	-- Return false and run close to target
	if (GetDistance(targetObj) > 35) then 
		return false;
	end

	-- Return true if in melee range
	if (GetDistance(targetObj) < 5) then 
		return true;
	end
end

function script_hunterEX:doRangeAttack(targetGUID, localMana)
	local targetObj = GetGUIDTarget(targetGUID);
	-- Keep up the debuff: Hunter's Mark 
	if (HasSpell("Hunter's Mark") and self.markTimer < GetTimeEX()) then 
		if (Cast("Hunter's Mark", targetGUID)) then self.markTimer = GetTimeEX() + 20000; return true; end 
	end

	-- Check: Let pet get aggro, dont use special attacks before the mob has less than 95 percent HP
	if (GetHealthPercentage(targetObj) > 95 and UnitExists("Pet")) then return true; end

	-- Check: Intimidation is ready and mob HP high
	if (not IsSpellOnCD('Intimidation') and GetHealthPercentage(targetObj) > 50) then 
		if (Cast('Intimidation', targetGUID)) then return true; end 
	end	
	
	-- Special attack: Serpent Sting (Keep the DOT up!)
	if (self.serpentTimer < GetTimeEX() and not IsSpellOnCD('Serpent Sting') 
		and GetCreatureType(targetObj) ~= 'Elemental') then 
		if (Cast('Serpent Sting', targetGUID)) then self.serpentTimer = GetTimeEX() + 15000; return true; end 
	end

	-- Special attack: Arcane Shot 
	if (not IsSpellOnCD('Arcane Shot') and localMana > self.arcaneMana) then 
		if (Cast('Arcane Shot', targetGUID)) then return true; end end

	-- Attack: Use Auto Shot 
	if (not IsAutoCasting('Auto Shot')) then
		if (Cast('Auto Shot', targetGUID)) then return true; else return false; end
	end

	return false;
end

function script_hunterEX:mendPet(localMana, petHP)
	local mendPet = HasSpell("Mend Pet");

	if (mendPet and IsInCombat() and self.hasPet and petHP > 0 and self.mendTimer < GetTimeEX()) then
		if (GetHealthPercentage(GetPet()) < 50) then
			self.message = "Pet has lower than 50 percenet HP, mending pet...";
			-- Check: If in range to mend the pet 
			if (GetDistance(GetPet()) < 45 and localMana > 10 and IsInLineOfSight(GetPet())) then 
				if (IsMoving()) then StopMoving(); return true; end 
				CastSpellByName("Mend Pet"); 
				self.mendTimer = GetTimeEX() + 15000;
				return true;
			elseif (localMana > 10) then 
				local x, y, z = GetPosition(GetPet());
				MoveToTarget(x, y, z); 
				return true; 
			end 
			
		end
	end

	return false;
end

function script_hunterEX:doOpenerRoutine(targetGUID) 
	local targetObj = GetGUIDTarget(targetGUID);

	-- Let pet loose early to get aggro (even before we are in range ourselves)
	if (self.hasPet and GetDistance(targetObj) < 50) then PetAttack(); end	

	if (script_hunterEX:doPullAttacks(targetGUID)) then return true; end
 
	-- Attack: Use Auto Shot 
	if (not IsAutoCasting('Auto Shot') and GetDistance(targetObj) < 35 and GetDistance(targetObj) > 13) then
		if (Cast('Auto Shot', targetGUID)) then return true; else return false; end
	end

	-- Check: If we are already in meele range before pull, use Raptor Strike
	if (GetDistance(targetObj) < 5) then
		if (Cast('Raptor Strike', targetGUID)) then return true; end 
	end

	-- Move to the target if not in range
	if (GetDistance(targetObj) > 35 or GetDistance(targetObj) < 14) then return false; end 

	-- return true so we dont move closer to the mob
	return true; 
end

function script_hunterEX:doPullAttacks(targetGUID)
	local targetObj = GetGUIDTarget(targetGUID);
	-- Pull with Concussive Shot to make it easier for pet to get aggro
	if (HasSpell('Concussive Shot')) then
		if (Cast('Concussive Shot', targetGUID)) then return true; end
	end

	-- If no concussive shot pull with Serpent Sting
	if (HasSpell('Serpent Sting')) then
		if (GetCreatureType(targetObj) ~= 'Elemental') then
			if (Cast('Serpent Sting', targetGUID)) then return true; end
		end
	end

	-- If no special attacks available for pull use Auto Shot
	if (Cast('Auto Shot', targetGUID)) then return true; end

	return false;
end

function script_hunterEX:chooseAspect(targetGUID)
	local targetObj = GetGUIDTarget(targetGUID);
	local localObj = GetLocalPlayer();

	if (not IsStanding()) then return false; end

	hasHawk, hasMonkey, hasCheetah = HasSpell("Aspect of the Hawk"), HasSpell("Aspect of the Monkey"), HasSpell("Aspect of the Cheetah");

	if (hasMonkey and GetLevel(localObj) < 10) then 
		if (not HasBuff(localObj, 'Aspect of the Monkey')) then  
			CastSpellByName('Aspect of the Monkey'); 
			return true; 
		end	
	elseif (hasMonkey and (targetObj ~= nil and targetObj ~= 0)) then
		if (GetDistance(targetObj) < 5 and IsInCombat() and not self.hasPet) then
			if (not HasBuff(localObj, 'Aspect of the Monkey')) then  
				CastSpellByName('Aspect of the Monkey'); 
				return true; 
			end
		else
			if (hasHawk and IsInCombat()) then 
				if (not HasBuff(localObj, 'Aspect of the Hawk')) then 
					CastSpellByName('Aspect of the Hawk'); 
					return true; 
				end 
			end
		end
	elseif (hasCheetah and not IsInCombat() and self.useCheetah) then 
		if (not HasBuff(localObj, 'Aspect of the Cheetah')) then 
			CastSpellByName('Aspect of the Cheetah'); 
			return true;  
		end 
	end

	return false;
end

function script_hunterEX:petChecks()
	local localObj = GetLocalPlayer();
	local localMana = GetManaPercentage(localObj);
	local pet = GetPet();
	local petHP = 0;

	if (IsMounted()) then
		return false;
	end

	if (pet ~= nil and pet ~= 0) then
		petHP = GetHealthPercentage(pet);
	end

	-- Check hasPet
	if (self.hasPet) then if (GetLevel(localObj) < 10) then self.hasPet = false; end end

	-- Check: If pet is dismissed then Call pet 
	if (GetPet() == nil and self.hasPet) then
		self.message = "Pet is missing, calling pet...";
		CastSpellByName('Call Pet'); 
		return true;
	end

	-- Check: If pet is dismissed/dead, call then revive pet
	if (self.hasPet and GetPet() == 0 and not IsInCombat() and HasSpell("Revive Pet")) then	
		self.message = "Pet is dead, reviving pet...";
		if (IsMoving() or not IsStanding()) then 
			StopMoving(); 
			return true; 
		end
		if (localMana > 60) then 
			CastSpellByName('Revive Pet'); 
			return true; 
		else 
			self.message = "Pet is dead, need more mana to ress it...";
			return true; 
		end
	end

	-- Check: Stop if we ran out of pet food in the "pet food slot"
	if (script_hunter.stopWhenNoPetFood and self.hasPet and not IsInCombat()) then
		local texture, itemCount, locked, quality, readable = GetContainerItemInfo(script_hunter.bagWithPetFood-1, GetContainerNumSlots(script_hunter.bagWithPetFood-1));
		if (itemCount == nil) then
			self.message = "No more pet food, stopping the bot..."; 
			if (IsMoving() or not IsStanding()) then StopMoving(); return true; end
			Logout(); 
			StopBot(); 
			return true;  
		end
	end	

	-- Check: If pet isn't happy, feed it 
	if (petHP > 0 and self.hasPet) then
		local happiness, damagePercentage, loyaltyRate = GetPetHappiness();	
		if (not IsDead(pet) and self.feedTimer < GetTimeEX() and not IsInCombat()) then
			if (happiness < 3 or loyaltyRate < 0) then
				self.message = "Pet is not happy, feeding the pet...";
				if (not IsStanding()) then StopMoving(); return true; end
				DEFAULT_CHAT_FRAME:AddMessage('script_hunter: Feeding the pet, and resting for 20 seconds...');
				CastSpellByName("Feed Pet"); 
				UseContainerItem(script_hunter.bagWithPetFood-1, script_hunter.slotWithPetFood, "Pet");
				-- Set a 20 seconds timer for this check (Feed Pet duration)
				self.feedTimer = GetTimeEX() + 20000; 
				return true;
			end
		end
	end	

	-- If we have the skill Mend Pet
	local mendPet = HasSpell("Mend Pet");
	if (mendPet and self.hasPet) then
		-- Check: Mend the pet if it has lower than 70 percent HP and out of combat
		if (self.hasPet and petHP < 70 and petHP > 0 and not IsInCombat() and self.mendTimer < GetTimeEX()) then
			if (GetDistance(GetPet()) > 8) then
				PetFollow();
				return true;
			end
			if (GetDistance(GetPet()) < 45 and localMana > 10) then
				if (self.hasPet and petHP < 70 and not IsInCombat() and petHP > 0) then
					self.message = "Pet has lower than 70 percent HP, mending pet...";
					if (IsMoving() or not IsStanding()) then StopMoving(); return true; end
					CastSpellByName('Mend Pet');
					self.mendTimer = GetTimeEX() + 15000;
					return true;
				end
			end
		end
	else
		if (petHP < 85 and self.hasPet) then
			if (self.hasPet and self.petTimer < GetTimeEX()) then
				DEFAULT_CHAT_FRAME:AddMessage('script_hunter: Pet has < 85 percent HP, lets wait...');
				self.petTimer = GetTimeEX() + 10000;
			end
			return true;
		end
	end

	return false;
end