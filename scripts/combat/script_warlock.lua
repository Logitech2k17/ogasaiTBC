script_warlock = {
	version = '0.1',
	message = 'Warlock Combat',
	drinkMana = 50,
	eatHealth = 50,
	isSetup = false,
	waitTimer = 0,
	healthStone = {},
	numStone = 0,
	stoneHealth = 40,
	useWand = true,
	corruptionCastTime = 0,
	siphonTime = 0,
	agonyTime = 0,
	corruptTime = 0,
	immoTime = 0,
	useFelguard = true,
	useVoid = true,
	useImp = false,
	useLifeTap = true,
	stoneTime = 0
}

function script_warlock:addHealthStone(name)
	self.healthStone[self.numStone] = name;
	self.numStone = self.numStone + 1;
end

function script_warlock:setup()
	self.waitTimer = GetTimeEX();
	self.siphonTime = GetTimeEX();
	self.agonyTime = GetTimeEX();
	self.corruptTime = GetTimeEX();
	self.immoTime = GetTimeEX();
	self.stoneTime = GetTimeEX();

	script_warlock:addHealthStone('Master Healthstone');
	script_warlock:addHealthStone('Major Healthstone');
	script_warlock:addHealthStone('Greater Healthstone');
	script_warlock:addHealthStone('Healthstone');
	script_warlock:addHealthStone('Lesser Healthstone');
	script_warlock:addHealthStone('Minor Healthstone');

	DEFAULT_CHAT_FRAME:AddMessage('script_warlock: loaded...');

	self.isSetup = true;
end

function script_warlock:run(targetObj)
	if(not self.isSetup) then
		script_warlock:setup();
		return;
	end

	if (targetObj == 0) then
		targetObj = GetTarget();
	end

	local targetGUID = GetTargetGUID(targetObj);

	local localObj = GetLocalPlayer();
	local localMana = GetManaPercentage(localObj);
	local localHealth = GetHealthPercentage(localObj);
	local localLevel = GetLevel(localObj);
	local hasPet = false; if(GetPet() ~= 0) then hasPet = true; end

	-- Check: Do we have a pet?
	local pet = GetPet(); local petHP = 0;
	if (pet ~= nil and pet ~= 0) then petHP = GetHealthPercentage(pet); end

	-- Pre Check
	if (IsChanneling() or IsCasting() or self.waitTimer > GetTimeEX()) then return; end

	-- Use Soul Link
	if (HasSpell('Soul Link') and not HasBuff(localObj, 'Soul Link') and petHP > 0) then
		CastSpellByName('Soul Link');
	end
	
	--Valid Enemy
	if (targetObj ~= 0) then
		
		-- Cant Attack dead targets
		if (IsDead(targetObj)) then return; end
		if (not CanAttack(targetObj)) then return; end
		
		targetHealth = GetHealthPercentage(targetObj);

		-- Check: When channeling, cancel Health Funnel when low HP
		if (hasPet) then
			if (HasBuff(GetPet(), "Health Funnel") and localHealth < 40) then
				local _x, _y, _z = GetPosition(localObj);
				MoveToTarget(_x + 1, _y + 1, _z); 
				return;
			end
		end

		--Opener
		if (not IsInCombat()) then

			if (HasSpell("Shadow Bolt")) then
				if (HasSpell('Unstable Affliction')) then
					if (Cast("Unstable Affliction", targetGUID)) then self.waitTimer = GetTimeEX() + 1600; return; end
				elseif (HasSpell("Siphon Life")) then
					if (Cast("Siphon Life", targetGUID)) then self.waitTimer = GetTimeEX() + 1600; return; end
				elseif (HasSpell("Curse of Agony")) then
					if (Cast('Curse of Agony', targetGUID)) then self.waitTimer = GetTimeEX() + 1600; return; end
				elseif (HasSpell("Immolate")) then
					if (Cast('Immolate', targetGUID)) then self.waitTimer = GetTimeEX() + 2500; return; end
				else
					if (Cast('Shadow Bolt', targetGUID)) then return 0; end
					
				end
				-- Perhaps we are not in line of sight
				if (not Cast('Shadow Bolt', targetGUID)) then return 4; end
			end	

		-- Combat
		else	
			-- Set the pet to attack
			if (hasPet) then PetAttack(); end

			-- Check: If we got Nightfall buff then cast Shadow Bolt
			if (HasBuff(localObj, "Shadow Trance")) then
				if (Cast('Shadow Bolt', targetGUID)) then return; end
			end	

			-- Use Healthstone
			if (localHealth < self.stoneHealth and self.stoneTime < GetTimeEX()) then
				for i=0,self.numStone do
					if(HasItem(self.healthStone[i])) then
						if (UseItem(self.healthStone[i])) then
							self.stoneTime = GetTimeEX() + 125000;
							return 0;
						end
					end
				end
			end

			-- Check: If we don't got a soul shard, try to make one
			if (targetHealth < 25 and HasSpell("Drain Soul") and not script_warlock:haveSoulshard()) then
				if (Cast('Drain Soul', targetGUID)) then return; end
			end

			-- Check: Heal the pet if it's below 50 perc and we are above 50 perc
			local petHP = 0; 
			if (hasPet) then local petHP = GetHealthPercentage(GetPet()); end
			if (hasPet and petHP > 0 and petHP < 50 and HasSpell("Health Funnel") and localHealth > 50) then
				if (GetDistance(GetPet()) > 20 or not IsInLineOfSight(GetPet())) then
					MoveToTarget(GetPet()); 
					script_grind.waitTimer = GetTimeEX() + 2000;
					return;
				else
					StopMoving();
				end
				CastSpellByName("Health Funnel"); 
				return;
			end

			local max = 0;
			local dur = 0;
			if (GetInventoryItemDurability(18) ~= nil) then
				dur, max = GetInventoryItemDurability(18);
			end

			if (self.useWand and dur > 0) then
				if (localMana <= 5 or targetHealth <= 5) then
					if (not script_target:autoCastingWand()) then 
						FaceTarget(targetObj);
						CastSpell("Shoot", targetObj);
						self.waitTimer = GetTimeEX() + 500; 
						return;
					end
					return;
				end
			end

			-- Check: Keep Siphon Life up (30 s duration)
			if (not script_target:hasDebuff('Siphon Life') and self.siphonTime < GetTimeEX() and targetHealth > 20) then
				if (Cast('Siphon Life', targetGUID)) then self.siphonTime = GetTimeEX()+5000; self.waitTimer = GetTimeEX() + 1600; return 0; end
			end

			-- Check: Keep the Curse of Agony up (24 s duration)
			if (not script_target:hasDebuff('Curse of Agony') and self.agonyTime < GetTimeEX() and targetHealth > 20) then
				if (Cast('Curse of Agony', targetGUID)) then self.agonyTime = GetTimeEX()+5000; self.waitTimer = GetTimeEX() + 1600; return 0; end
			end
	
			-- Check: Keep the Corruption DoT up (15 s duration)
			if (not script_target:hasDebuff('Corruption') and self.corruptTime < GetTimeEX() and targetHealth > 20) then
				if (Cast('Corruption', targetGUID)) then self.corruptTime = GetTimeEX()+5000; self.waitTimer = GetTimeEX() + 1600 + self.corruptionCastTime; return 0; end
			end
	
			-- Check: Keep the Immolate DoT up (15 s duration)
			if (not script_target:hasDebuff('Immolate') and self.immoTime < GetTimeEX() and targetHealth > 20) then
				if (Cast('Immolate', targetGUID)) then self.immoTime = GetTimeEX()+5000; self.waitTimer = GetTimeEX() + 2500; return 0; end
			end
	
			-- Cast: Life Tap if conditions are right, see the function
			if (script_warlock:lifeTap(localHealth, localMana)) then return; end

			-- Cast: Drain Life, don't use Drain Life if we need a soul shard
			if (HasSpell("Drain Life") and script_warlock:haveSoulshard() and GetCreatureType(targetObj) ~= "Mechanic") then
				if (GetDistance(targetObj) < 20) then
					if (IsMoving()) then StopMoving(); return; end
					if (Cast('Drain Life', targetGUID)) then return; end
				else
					MoveToTarget(targetObj); 
					script_grind.waitTimer = GetTimeEX() + 1250;
					return;
				end
			else	
				-- Cast: Shadow Bolt
				if (Cast('Shadow Bolt', targetGUID)) then return; end
			end

			-- Auto Attack if no mana
			if (localMana < 5) then
				UnitInteract(targetObj);
			end
			
			return;	
		end
	
	end
end

function script_warlock:lifeTap(localHealth, localMana)
	if (localMana < localHealth and self.useLifeTap) then
		if (HasSpell("Life Tap") and localHealth > 50 and localMana < 90) then
			if(IsSpellOnCD("Life Tap")) then 
				return false; 
			else 
				CastSpellByName("Life Tap"); 
				return true; 
			end
		end
	end
	return false;
end


function script_warlock:haveSoulshard()
	for i = 0,4 do 
		for y=0,GetContainerNumSlots(i) do 
			if (GetContainerItemLink(i,y) ~= nil) then
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
   				itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(GetContainerItemLink(i,y));
				if (itemName == "Soul Shard") then
					return true;
				end
			end
		end 
	end
	return false;
end

function script_warlock:rest()
	if(not self.isSetup) then script_warlock:setup(); return true; end

	local localObj = GetLocalPlayer();
	local localMana = GetManaPercentage(localObj);
	local localHealth = GetHealthPercentage(localObj);

	-- Check: Do we have a pet?
	local pet = GetPet(); local petHP = 0;
	local hasPet = false;
	if (pet ~= nil and pet ~= 0) then hasPet = true; petHP = GetHealthPercentage(pet); end

	-- Update rest values
	if (script_grind.restHp ~= 0) then self.eatHealth = script_grind.restHp; end
	if (script_grind.restMana ~= 0) then self.drinkMana = script_grind.restMana; end

	if (self.waitTimer > GetTimeEX()) then return true; end

	-- Cast: Life Tap if conditions are right, see the function
	if (not IsDrinking() and not IsEating() and localMana < self.drinkMana) then
		if (script_warlock:lifeTap(localHealth, localMana)) then return true; end
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

	-- Check: If the pet is an Imp, require Firebolt to be in slot 4
	local petIsImp = false;
	local petIsVoid = false;
	if (hasPet) then
		name, __, __, __, __, __, __ = GetPetActionInfo(4);
		if (name == "Firebolt") then petIsImp = true; end
		if (name == "Torment") then petIsVoid = true; end
	end
	
	-- Check: Summon our Demon if we are not in combat (Voidwalker is Summoned in favor of the Imp)
	if (not IsEating() and not IsDrinking() and not IsMounted()) then
		if ((not hasPet or petIsVoid or petIsImp) and self.useFelguard and HasSpell('Summon Felguard') and script_warlock:haveSoulshard()) then
			if (not IsStanding() or IsMoving()) then StopMoving(); end
			if (localMana > 40) then CastSpellByName("Summon Felguard"); script_grind:restOn(); return true; end
		elseif ((not hasPet or petIsImp) and self.useVoid and HasSpell("Summon Voidwalker") and script_warlock:haveSoulshard()) then
			if (not IsStanding() or IsMoving()) then StopMoving(); end
			if (localMana > 40) then CastSpellByName("Summon Voidwalker"); script_grind:restOn(); return true; end
		elseif (not hasPet and HasSpell("Summon Imp")) then
			if (not IsStanding() or IsMoving()) then StopMoving(); end
			if (localMana > 30) then
				CastSpellByName("Summon Imp"); script_grind:restOn(); return true; 
			end
		end
	end

	--Create Healthstone
	local stoneIndex = -1;
	for i=0,self.numStone do
		if (HasItem(self.healthStone[i])) then
			stoneIndex= i;
			break;
		end
	end
	if (stoneIndex == -1 and HasItem("Soul Shard")) then 
		if (localMana > 10 and not IsDrinking() and not IsEating() and not AreBagsFull()) then
			if (HasSpell('Create Healthstone') and IsMoving()) then
				StopMoving();
				script_grind:restOn();
				return true;
			end
			if (HasSpell('Create Healthstone')) then
				CastSpellByName('Create Healthstone')
				script_grind:restOn();
				return true;
			end
		end
	end

	-- Do buffs if we got some mana 
	if (localMana > 30) then
		if(HasSpell("Demon Armor")) then
			if (not HasBuff(localObj, "Demon Armor")) then
				if (Buff("Demon Armor", localObj)) then
					script_grind:restOn();
					return true;
				end
			end
		elseif (not HasBuff(localObj, 'Demon Skin') and HasSpell('Demon Skin')) then
			if (Buff('Demon Skin', localObj)) then
				script_grind:restOn();
				return true;
			end
		end
		--if (HasSpell("Unending Breath")) then
			--if (not HasBuff(localObj, 'Unending Breath')) then
				--if (Buff('Unending Breath', localObj)) then
					--return true;
				--end
			--end
		--end
	end

	-- Check: Health funnel on the pet or wait for it to regen if lower than 70 perc
	local petHP = 0;
	if (GetPet() ~= 0) then
		petHP = GetHealthPercentage(GetPet());
	end
	if (hasPet and petHP > 0) then
		if (petHP < 70) then
			if (GetDistance(GetPet()) > 8) then
				PetFollow();
				self.waitTimer = GetTimeEX() + 1850; 
				script_grind:restOn();
				return true;
			end
			if (GetDistance(GetPet()) < 20 and localMana > 10) then
				if (hasPet and petHP < 70 and petHP > 0) then
					DEFAULT_CHAT_FRAME:AddMessage('script_Warlock: Pet health below 70 percent, resting...');
					if (HasSpell('Health Funnel')) then CastSpellByName('Health Funnel'); end
					self.waitTimer = GetTimeEX() + 1850; 
					script_grind:restOn();
					return true;
				end
			end
		end
	end

	
	script_grind:restOff();
	return false;
end

function script_warlock:menu()
	if (CollapsingHeader("[Warlock - Afflic/Demo")) then
		local wasClicked = false;
		Text('Skills options:');
		Separator();
		wasClicked, self.useWand = Checkbox("Use Wand", self.useWand);
		wasClicked, self.useLifeTap = Checkbox("Use Life Tap", self.useLifeTap);
		wasClicked, self.useFelguard = Checkbox("Use Felguard before Voidwalker", self.useFelguard);
		wasClicked, self.useVoid = Checkbox("Use Voidwalker before Imp", self.useVoid);
		Text('Corruption cast time');
		self.corruptionCastTime = SliderFloat("CCT", 0, 2000, self.corruptionCastTime);
		Text("Use Healthstones below HP percent");
		self.stoneHealth = SliderFloat("HSHP", 1, 99, self.stoneHealth);
	end
end
