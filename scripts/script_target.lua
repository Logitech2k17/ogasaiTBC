script_target = {
	isSetup = false,
	skipHumanoid = false,
	skipElemental = false,
	skipUndead = false,
	skipDemon = false,
	skipBeast = false,
	skipAberration = false,
	skipDragonkin = false,
	skipGiant = false,
	skipMechanical = false,
	skipElites = true,
	pullRange = 89,
	minLevel = GetLevel(GetLocalPlayer())-5,
	maxLevel = GetLevel(GetLocalPlayer())+1,
	currentLevel = GetLevel(GetLocalPlayer());
	currentTarget = 0,
	currentLootTarget = 0,
	lootTargets = {},
	numLoot = 0,
	lootDistance = 3,
	lootRange = 60,
	lootTimer = 0,
	skin = true,
	extra = include("scripts\\script_targetEX.lua")
}

function script_target:setup()
	self.lootTimer = GetTimeEX();
	self.isSetup = true;
	DEFAULT_CHAT_FRAME:AddMessage('script_target: loaded...');
end

function script_target:autoCastingWand()
	local autoCast = false;
	if IsAutoRepeatSpell(GetSpellInfo(5019)) then autoCast = true end
	return autoCast;
end

function script_target:resetLoot()
	self.currentLootTarget = 0;
	self.lootTargets = {};
	self.numLoot = 0;
end

function script_target:hasBuff(target, buff)
	for i=1,40 do
		if (target == GetLocalPlayer()) then local name, icon, _, _, _, etime = UnitBuff("player", i); end

		if (GetTarget() == target) then local name, icon, _, _, _, etime = UnitBuff("target", i); end

  		if name == buff and name ~= nil then return true; end
	end
	
	return false;
end

function script_target:hasDebuff(debuff)
	for i=1,40 do
		local name, icon, _, _, _, etime = UnitDebuff("target", i);
  		if name == debuff and name ~= nil then
    			return true;
  		end
	end
	
	return false;
end

function script_target:doLoot()
	local lootTarget = self.lootTargets[self.currentLootTarget];

	-- Reset loot if we are swimming, can't loot anyway
	if (IsSwimming()) then
		script_target:resetLoot();
	end

	-- Remove loot target if we can't move to it or not lootable/skinnable
	local x, y, z = GetPosition(lootTarget);
	if (IsNodeBlacklisted(x, y, z, 5) or (not IsLootable(lootTarget) and (not IsSkinnable(lootTarget) or (not self.skin) or (not HasItem('Skinning Knife')))) ) then
		self.lootTargets[self.currentLootTarget] = nil;
		return;
	end

	if (GetDistance(lootTarget) > self.lootDistance) then
		script_path:savePos(false); -- SAVE FOR UNSTUCK
		if (not script_grind.raycastPathing) then
			MoveToTarget(lootTarget);
		else
			local x, y, z = GetPosition(lootTarget);
			script_pather:moveToTarget(x, y, z);
		end
		return;
	end
		
	if (IsMoving()) then
		StopMoving();
		if (script_grind.waitTimer ~= 0) then
			script_grind.waitTimer = GetTimeEX() + 850;
		end
		return;
	end
			
	script_path:resetAutoPath();

	if (UnitInteract(lootTarget)) then
		script_path:savePos(true); 

		if (IsSkinnable(lootTarget) and self.skin and HasItem('Skinning Knife')) then
			
			if (script_grind.waitTimer ~= 0) then
				script_grind.waitTimer = GetTimeEX() + 1250;
			end
			
			return;
		end

		if (script_grind.waitTimer ~= 0) then
			script_grind.waitTimer = GetTimeEX() + 1250;
		end
		
		return;
	end
end

function script_target:addLootTarget(target)
	if (target ~= 0 and target ~= nil) then
		self.lootTargets[self.numLoot] = target;
		self.lootTargets['skin' .. self.numLoot] = false;
		self.numLoot = self.numLoot + 1;
	end
end

function script_target:isThereLoot()
	local isLoot = false;
	if (self.numLoot > 0) then
		for i=0, self.numLoot-1 do
			if (self.lootTargets[i] ~= 0 and self.lootTargets[i] ~= nil) then
				if (self.lootRange >= GetDistance(self.lootTargets[i])) then
					self.currentLootTarget = i;
					isLoot = true;
				end
			end	
		end
	end

	if (isLoot) then 
		return true;
	end

	-- Reset if no loot
	for i=0, self.numLoot-1 do
		self.lootTargets[i] = nil;
	end
	self.currentLootTarget = 0;
	self.numLoot = 0;
	return false;
end

function script_target:trueFalse(value)
	if (value == 1) then
		return true;
	end

	return false;	
end

function script_target:setPullRange(range)
	self.pullRange = range;
end

function script_target:getTarget()
	local targetObj = 0; 

	-- Fetch last target
	local lastTarget = self.currentTarget;

	local nearestTarget = script_targetEX:getNearestEnemy();

	-- Select the closest target if our last target is dead
	if (IsDead(lastTarget) or lastTarget == nil or lastTarget == 0) then
		targetObj = nearestTarget;
		lastTarget = 0;
	end
	
	if (lastTarget ~= 0) then
		-- Check: Swap to the nearest enemy if not in combat yet
		if (not IsInCombat() and GetDistance(nearestTarget) < GetDistance(lastTarget)) then 
			targetObj = nearestTarget; 
		end

		-- Check: Swap to the target with lowest HP
		local lastTargetHP = GetHealthPercentage(lastTarget); 
		local nearestTargetHP = GetHealthPercentage(nearestTarget);
		if (lastTargetHP >= nearestTargetHP) then 
			targetObj = nearestTarget;
		end
	end

	-- Set and save our target
	self.currentTarget = targetObj;

	return GetTargetGUID(self.currentTarget);
end

function script_target:lootMenu()
	if (CollapsingHeader("[Loot options")) then
		wasClicked, script_grind.skipLoot = Checkbox("Skip Looting", script_grind.skipLoot);
		if (Button("Reset Loot Targets")) then script_target:resetLoot(); end
		Text('Loot corpses within range (yd)');
		script_target.lootRange = SliderFloat("LR (yd)", 1, 150, script_target.lootRange);
	end
end