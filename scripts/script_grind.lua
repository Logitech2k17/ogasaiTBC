script_grind = {
	isSetup = false,
	helperLoaded = include("scripts\\script_helper.lua"),
	targetLoaded = include("scripts\\script_target.lua"),
	pathLoaded = include("scripts\\script_path.lua"), 
	vendorScript = include("scripts\\script_vendor.lua"),
	grindExtra = include("scripts\\script_grindEX.lua"),
	grindMenu = include("scripts\\script_grindMenu.lua"),
	autoTalents = include("scripts\\script_talent.lua"),
	info = include("scripts\\script_info.lua"),
	gather = include("scripts\\script_gather.lua"),
	rayPather = include("scripts\\script_pather.lua"),
	message = 'Starting the grinder...',
	alive = true,
	target = 0,
	targetTimer = GetTimeEX();
	pullDistance = 30,
	waitTimer = 0,
	tickRate = 250,
	restHp = 60,
	restMana = 60,
	potHp = 10,
	potMana = 10,
	pause = false,
	stopWhenFull = false,
	hsWhenFull = false,
	shouldRest = false,
	skipMobTimer = 0,
	useMana = true,
	skipLoot = false,
	skipReason = 'user selected...',
	stopIfMHBroken = false,
	useVendor = true,
	sellWhenFull = true,
	repairWhenYellow = true,
	bagsFull = false,
	vendorRefill = true,
	refillMinNr = 5,
	unStuckPos = {},
	unStuckTime = 0,
	jump = false,
	useMount = true,
	tryMountTime = 0,
	autoTalent = true,
	gather = true,
	raycastPathing = false,
	showRayMenu = false,
	useNavMesh = true,
	combatStatus = 0 -- 0 = in range, 1 = not in range
}

function script_grind:setup()

	SetPVE(true);
	SetAutoLoot();
	DrawNavMeshPath(true);

	self.waitTimer = GetTimeEX();
	self.skipMobTimer = GetTimeEX();
	self.unStuckTime = GetTimeEX();
	self.tryMountTime = GetTimeEX();

	-- Classes that doesn't use mana
	local class, classFileName = UnitClass("player");
	if (strfind("Warrior", class) or strfind("Rogue", class)) then self.useMana = false; self.restMana = 0; end
	if (strfind("Mage", class)) then self.vendorRefill = false; end

	if (GetLevel(GetLocalPlayer()) <= 3) then self.vendorRefill = false; end

	if (GetLevel(GetLocalPlayer()) <= 39) then self.useMount = false; end

	hotspotDB:setup(); 

	DEFAULT_CHAT_FRAME:AddMessage('script_grind: loaded...');
	script_grindEX:setup();
	script_helper:setup(); 
	script_path:setup();
	script_target:setup();
	script_vendor:setup();
	script_talent:setup();
	script_pathFlyingEX:setup();
	self.isSetup = true;
end

function script_grind:draw() 
	-- Draw everything
	script_grindEX:draw();
end

function script_grind:run()
	-- Run the setup function once
	if (not self.isSetup) then script_grind:setup(); return; end

	-- Load nav mesh
	if (self.useNavMesh) then
		if (script_path:loadNavMesh()) then
			self.message = "Loading the oGasai maps...";
			return;
		end
	end

	-- Update min/max level if we level up
	if (script_target.currentLevel ~= GetLevel(GetLocalPlayer())) then
		script_target.minLevel = script_target.minLevel + 1;
		script_target.maxLevel = script_target.maxLevel + 1;
		script_target.currentLevel = script_target.currentLevel + 1;
	end

	-- Check: jump to the surface if we are under water
	local progress = GetMirrorTimerProgress("BREATH");
	if (progress ~= nil and progress ~= 0) then
		if ((progress/1000) < 35) then
			self.message = "Let's not drown...";
			Jump();
			return;
		end
	else
		--StopJump();	
	end

	-- Check: jump over obstacles
	if (IsMoving()) then
		script_pather:jumpObstacles();
	end

	-- Update node distance depending on if we are mounted or not
	script_path:setNavNodeDist();

	-- Check: Pause, Unstuck, Vendor, Repair, Buy and Sell etc
	if (script_grindEX:doChecks()) then return; end

	-- Check: wait for timer
	if(self.waitTimer > GetTimeEX()) then return; end
	self.waitTimer = GetTimeEX() + self.tickRate;

	if (IsDead(self.target)) then 
		-- Keep saving path nodes at dead target's locations
		if (script_path.reachedHotspot) then script_path:savePathNode(); end
		-- Add dead target to the loot list
		if (not self.skipLoot) then script_target:addLootTarget(self.target); end
		self.target = nil; 
		ClearTarget();
		return; 
	end

	-- Dead
	if (IsDead(GetLocalPlayer())) then
		if (self.alive) then self.alive = false; RepopMe(); self.message = "Releasing spirit..."; self.waitTimer = GetTimeEX() + 8000; return; end
		self.message = script_helper:ress(GetCorpsePosition()); 
		script_path:savePos(false); -- SAVE FOR UNSTUCK
		return;
	else
	-- Alive
		self.alive = true;
		script_path:savePos(false); -- SAVE FOR UNSTUCK
	end

	-- Check: Rest 
	local hp = GetHealthPercentage(GetLocalPlayer());
	local mana = GetManaPercentage(GetLocalPlayer());

	-- Stand up after resting
	if (self.useMana) then
		if (hp > 98 and mana > 98 and not IsStanding()) then StopMoving(); self.shouldRest = false; return;
		else if (IsDrinking() or IsEating()) then self.shouldRest = true; end end
	else
		if (hp > 98 and not IsStanding()) then StopMoving(); self.shouldRest = false; return;
			else if (IsEating()) then self.shouldRest = true; end
		end
	end

	-- Rest out of combat
	if (not IsInCombat() or script_info:nrTargetingMe() == 0) then
		if ((not IsSwimming()) and (not IsFlying())) then RunRestScript();
		else self.shouldRest = false; end
		if (self.shouldRest) then 
			script_path:savePos(true); -- SAVE FOR UNSTUCK
			self.message = "Resting..."; self.waitTimer = GetTimeEX() + 2500; return; end
	else
		-- Use Potions in combat
		if (hp < self.potHp) then script_helper:useHealthPotion(); end
		if (mana < self.potMana and self.useMana) then script_helper:useHealthPotion(); end
		-- Dismount in combat
		if (IsMounted()) then Dismount(); return; end 
		ResetNavigate();
		script_pather:resetPath()
	end

	-- Loot
	if (script_target:isThereLoot() and not IsInCombat() and not AreBagsFull() and not self.bagsFull) then
		self.message = "Looting... (enable auto loot)"; script_target:doLoot(); return;
	end

	-- Wait for group members
	if (GetNumPartyMembers() > 2) then

		if (script_followEX:getTarget() ~= 0) then
			local targetGUID = script_followEX:getTarget();
			self.target = GetGUIDTarget(targetGUID);
			UnitInteract(self.target);
		else
			if (script_info:waitGroup() and not IsInCombat()) then
				self.message = 'Waiting for group (rest & movement)...';
				script_path:savePos(true);
				return;
			end
		end
	end

	-- Gather
	if (self.gather and not IsInCombat() and not AreBagsFull() and not self.bagsFull) then
		if (script_gather:gather()) then
			self.message = 'Gathering ' .. script_gather:currentGatherName() .. '...';
			return;
		end
	end

	-- Fetch a new target
	if (self.skipMobTimer < GetTimeEX() or (IsInCombat() and script_info:nrTargetingMe() > 0)) then	
		if (script_path.reachedHotspot or (not IsUsingNavmesh() and not self.raycastPathing) or IsInCombat()) then
			local targetGUID = script_target:getTarget();
			self.target = GetGUIDTarget(targetGUID);
			if (GetTarget() ~= self.target) then
				UnitInteract(self.target);	
			end	
		end
	else
		-- Move away from unvalid targets
		if (IsUsingNavmesh() or self.raycastPathing) then 
			script_path:autoPath();
		else 
			Navigate();
		end
		return;
	end
	
	if (self.target ~= 0 and self.target ~= nil) then
		-- Swap target if we are not in combat and there is a closer target
		if (script_target:getTarget() ~= GetTargetGUID(self.target) and not IsInCombat()) then
			--ClearTarget(); 
			local targetGUID = script_target:getTarget();
			self.target = GetGUIDTarget(targetGUID);
			UnitInteract(self.target);
			return;
		end

		-- Swap target if we are in combat and there is a closer target attacking us and our target is at 100 percent
		if (script_target:getTarget() ~= GetTargetGUID(self.target) and IsInCombat() and GetHealthPercentage(self.target) == 100) then
			local newTarget = GetGUIDTarget(targetGUID);
			if (GetUnitsTarget(newTarget) == GetLocalPlayer()) then
				ClearTarget();
				self.target = newTarget;
				UnitInteract(self.target);
				return;
			end
			
		end

	end

	-- Check: Dont pull monsters too far away from the grinding hotspot
	if (self.target ~= 0 and self.target ~= nil and not IsInCombat()) then
		local mx, my, mz = GetPosition(self.target);
		local mobDistFromHotSpot = math.sqrt((mx - script_path.hx)^2+(my - script_path.hy)^2);
		if (mobDistFromHotSpot > script_path.grindingDist) then
			self.target = nil;
			self.skipMobTimer = GetTimeEX() + 15000; -- 15 sec to move back to waypoints
			ClearTarget();
		end
	end

	-- Dont fight if we are swimming
	if (IsSwimming()) then
		self.target = nil;
		if (IsUsingNavmesh() or self.raycastPathing) then 
			script_path:autoPath();
		else 
			Navigate();
		end
		script_target:resetLoot(); -- reset loot while swimming
		self.skipMobTimer = GetTimeEX() + 15000; -- 15 sec to move back to waypoints
		self.message = "Don't fight in water...";
		return;
	end

	-- If we have a valid target attack it
	if (self.target ~= 0 and self.target ~= nil) then
		if (GetDistance(self.target) < self.pullDistance and IsInLineOfSight(self.target)) then
			FaceTarget(self.target);
			if (IsMoving()) then StopMoving();  return; end
		else
			-- If we can't move to the target keep on grinding	
			local x, y, z = GetPosition(self.target);
			if (IsNodeBlacklisted(x, y, z, 5)) then
				self.target = nil;
				self.message = "Can't move to the target..";
				if (IsUsingNavmesh() or self.raycastPathing) then 
					script_path:autoPath();
				else 
					Navigate();
				end
				return;
			end
			
			self.message = "Moving to target...";
			if (not self.raycastPathing) then
				MoveToTarget(self.target);
			else
				local cx, cy, cz = GetPosition(self.target);
				script_pather:moveToTarget(cx, cy, cz);
			end
			return;
		end

		self.message = 'Attacking target...';

		script_path:resetAutoPath();
		script_pather:resetPath();
		ResetNavigate();
		RunCombatScript(self.target);
		
		-- Unstuck feature on valid "working" targets
		if (GetTarget() ~= 0 and GetTarget() ~= nil) then
			if (GetHealthPercentage(GetTarget()) < 98) then
				script_path:savePos(true); -- SAVE FOR UNSTUCK 
			end
		end

		return;
	end

	-- Mount before pathing
	if (not IsMounted() and self.target ~= nil and self.target ~= 0 and IsOutdoors() and self.tryMountTime < GetTimeEX()) then
		if (IsMoving()) then StopMoving(); return; end
		script_helper:useMount(); self.tryMountTime = GetTimeEX() + 10000; return;
	end

	-- When no valid targets around, run auto pathing
	if (not IsInCombat() and (IsUsingNavmesh() or self.raycastPathing)) then self.message = script_path:autoPath(); end

	if (not IsUsingNavmesh() and not self.raycastPathing) then self.message = "Navigating the walk path..."; Navigate(); end
end

function script_grind:turnfOffLoot(reason)
	self.skipReason = reason;
	self.skipLoot = true;
	self.bagsFull = true;
end

function script_grind:turnfOnLoot()
	self.skipLoot = false;
	self.bagsFull = false;
end

function script_grind:restOn()
	self.shouldRest = true;
end

function script_grind:restOff()
	self.shouldRest = false;
end