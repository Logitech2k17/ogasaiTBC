script_follow = {
	isSetup = false,
	helperLoaded = include("scripts\\script_helper.lua"),
	targetLoaded = include("scripts\\script_target.lua"),
	pathLoaded = include("scripts\\script_path.lua"), 
	autoTalents = include("scripts\\script_talent.lua"),
	info = include("scripts\\script_info.lua"),
	extraFunctions = include("scripts\\script_followEX.lua"),
	message = 'Follower by Logitech...',
	alive = true,
	target = 0,
	targetTimer = GetTimeEX();
	pullDistance = 30,
	waitTimer = 0,
	tickRate = 150,
	restHp = 60,
	restMana = 60,
	potHp = 10,
	potMana = 10,
	pause = false,
	stopWhenFull = false,
	hsWhenFull = false,
	shouldRest = false,
	useMana = true,
	stopIfMHBroken = false,
	unStuckTime = 0,
	jump = true,
	useMount = true,
	tryMountTime = 0,
	autoTalent = true,
	unstuckRight = true,
	leader = 0,
	followDist = 20,
	acceptTimer = 0
}

function script_follow:setup()

	SetPVE(true);
	DrawNavMeshPath(true);

	-- Load nav mesh
	if (script_path:loadNavMesh()) then
		self.message = "Loading the oGasai maps...";
		return;
	end

	self.waitTimer = GetTimeEX();
	self.unStuckTime = GetTimeEX();
	self.tryMountTime = GetTimeEX();
	self.acceptTimer = GetTimeEX();

	-- Classes that doesn't use mana
	local class, classFileName = UnitClass("player");
	if (strfind("Warrior", class) or strfind("Rogue", class)) then self.useMana = false; self.restMana = 0; end
	if (strfind("Mage", class)) then self.vendorRefill = false; end

	if (GetLevel(GetLocalPlayer()) <= 39) then self.useMount = false; end

	DEFAULT_CHAT_FRAME:AddMessage('script_follow: loaded...');
	script_helper:setup(); 
	script_path:setup();
	script_target:setup();
	script_talent:setup();
	self.isSetup = true;
end

function script_follow:draw() 
	-- Draw everything
	script_followEX:draw();
end

function script_follow:run()
	-- Run the setup function once
	if (not self.isSetup) then script_follow:setup(); return; end

	-- Set nav mesh smoothness
	script_path:setNavNodeDist();

	-- Check: jump to the surface if we are under water
	local progress = GetMirrorTimerProgress("BREATH");
	if (progress ~= nil and progress ~= 0) then
		if ((progress/1000) < 35) then
			self.message = "Let's not drown...";
			Jump();
			return;
		end
	else
		StopJump();	
	end

	-- Check: wait for channeling and casting
	if (IsChanneling() or IsCasting()) then return true; end 

	-- Check: User pause
	if (self.pause) then script_path:savePos(true); self.message = "Paused by user..."; return true; end

	-- save pos while/if moving
	script_path:savePos(false); 

	if (self.unStuckTime > GetTimeEX()) then
		if (not self.unstuckRight) then
			StrafeRightStart();
		else
			StrafeLeftStart();
		end
		script_helper:jump();
		return true;
	end

	if (not self.unstuckRight) then
		StrafeRightStop();
	else
		StrafeLeftStop();
	end

	-- Check: Unstuck feature
	if (script_path:unStuck() and (GetTimeEX() - script_path.savedPos['time']) < 20000) then
		self.message = "Trying to unstuck..."; 
		self.unStuckTime = GetTimeEX()+3500; 
		local mx, my, mz = GetPosition(GetLocalPlayer());
		MoveToTarget(mx+2, my+2, mz);
		self.unstuckRight = not self.unstuckRight;
		return true; 
	end

	-- Don't run checks if dead
	if (not IsDead(GetLocalPlayer())) then
		-- Check: Spend talent points
		if (not IsInCombat() and self.autoTalent) then
			if (script_talent:learnTalents()) then
				self.message = "Checking/learning talent: " .. script_talent:getNextTalentName();
				script_path:savePos(true); 
				return;
			end
		end
	end

	-- Check: wait for timer
	if(self.waitTimer > GetTimeEX()) then return; end
	self.waitTimer = GetTimeEX() + self.tickRate;

	-- Check: jump randomly if not swimming
	if (self.jump and not IsMounted()) then script_helper:jump(); end

	if (IsDead(self.target)) then 
		self.followDist = random(10, 25);
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

	-- Accept group invite
	if (GetNumPartyMembers() < 1) then
		self.message = 'Waiting for a group invite...';

		if (self.acceptTimer < GetTimeEX()) then 
			self.acceptTimer = GetTimeEX() + 5000;
			AcceptGroup(); 
			script_path:savePos(true); -- SAVE FOR UNSTUCK
			return;
		end
		
		return;
	end

	-- Set Leader
	if (self.leader == 0) then
		self.message = 'Finding leader to follow...';
		self.leader = GetPartMember(GetPartyLeaderIndex());
		script_path:savePos(true); -- SAVE FOR UNSTUCK
		return;
	end

	-- Priest healer check: heal/buff the party
	if (script_followEX:healAndBuff() and HasSpell('Smite')) then
		self.message = "Healing/buffing the party...";
		return;
	end

	-- Check: Rest 
	local hp = GetHealthPercentage(GetLocalPlayer());
	local mana = GetManaPercentage(GetLocalPlayer());

	-- Stand up after resting
	if (self.useMana) then
		if (hp > 98 and mana > 98 and not IsStanding()) then StopMoving(); script_grind.shouldRest = false; return;
		else if (IsDrinking() or IsEating()) then script_grind.shouldRest = true; end end
	else
		if (hp > 98 and not IsStanding()) then StopMoving(); script_grind.shouldRest = false; return;
			else if (IsEating()) then script_grind.shouldRest = true; end
		end
	end

	-- Rest out of combat
	if (not IsInCombat()) then
		if (not IsSwimming()) then 
			RunRestScript();
		else 
			script_grind = false; 
		end
		if (script_grind.shouldRest) then 
			script_path:savePos(true); -- SAVE FOR UNSTUCK
			self.message = "Resting..."; self.waitTimer = GetTimeEX() + 2500; return; end
	else
		-- Use Potions in combat
		if (hp < self.potHp) then script_helper:useHealthPotion(); end
		if (mana < self.potMana and self.useMana) then script_helper:useHealthPotion(); end
	end

	-- Fetch a new target
	if (self.target == 0 or self.target == nil) then
		local targetGUID = script_followEX:getTarget();
		self.target = GetGUIDTarget(targetGUID);
		UnitInteract(self.target);
	end

	-- Set the right target
	if (GetTargetGUID(GetTarget()) ~= GetTargetGUID(self.target)) then 
		UnitInteract(self.target); 
		return; 
	end

	-- Don't attack before leader got aggro
	local targetHp = 0;
	targetHp = GetHealthPercentage(self.target);
	if (targetHp > 95) then
		return;
	end
	
	-- If we have a valid target attack it
	if (self.target ~= 0 and self.target ~= nil) then
		if (GetDistance(self.target) < self.pullDistance and IsInLineOfSight(self.target)) then
			FaceTarget(self.target);
			if (IsMoving() and script_grind.combatStatus == 0) then StopMoving(); return; end
		else
			self.message = "Moving to target...";
			MoveToTarget(self.target);
			return;
		end

		self.message = 'Attacking target...';

		RunCombatScript(self.target);
		
		-- Unstuck feature on valid "working" targets
		if (GetTarget() ~= 0 and GetTarget() ~= nil) then
			script_path:savePos(true); -- SAVE FOR UNSTUCK 
		end

		return;
	end

	-- Mount before following
	if (not IsMounted() and self.target ~= nil and self.target ~= 0 and IsOutdoors() and self.tryMountTime < GetTimeEX()) then
		if (IsMoving()) then StopMoving(); return; end
		script_helper:useMount(); self.tryMountTime = GetTimeEX() + 10000; return;
	end

	-- When no valid targets around
	if (not IsInCombat()) then 
		self.message = "Following our leader...";
		script_followEX:followLeader();
	end
end