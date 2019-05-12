script_fish = {
	PoleName = 'Fishing Pole', 
	lureName = 'Shiny Bauble',
	useVendor = false,
	wasInCombat = false,
	weaponMainHand = '',
	weaponOffHand = '',
	bobberInfo = {},
	message = 'Fishing...',
	timer = 0,
	alive = true,
	isSetup = false,
	pause = false,
	fishPos = {},
	extra = include("scripts\\script_fishEX.lua")
}

function script_fish:draw()
	EndWindow();
	if (NewWindow("[Fishing options", 200, 100)) then
		script_fishEX:menu();
	end

	if (self.fishPos['x'] ~= nil) then
		local pX, pY, onScreen = WorldToScreen(self.fishPos['x'], self.fishPos['y'], self.fishPos['z']);
		if (onScreen) then
			DrawText('*Fishing Position*', pX-50, pY, 225, 225, 0);
		end
	end

	DrawMovePath();
end

function script_fish:setup()
	-- Set pole
	if (HasItem('Strong Fishing Pole')) then
		self.PoleName = 'Strong Fishing Pole';
	end
	-- Set lure
	if (HasItem('Aquadynamic Fish Attractor')) then
		self.lureName = 'Aquadynamic Fish Attractor';
	elseif (HasItem('Bright Baubles')) then
		self.lureName = 'Bright Baubles';
	elseif (HasItem('Nightcrawlers')) then
		self.lureName = 'Nightcrawlers';
	end
	self.fishPos = {};
	self.fishPos['x'], self.fishPos['y'], self.fishPos['z'] = GetPosition(GetLocalPlayer());
	script_vendor:setup();
	script_path:setup();
	DEFAULT_CHAT_FRAME:AddMessage('script_fish: loaded...');
	self.timer = GetTimeEX();
	self.isSetup = true;
end

function script_fish:run()
	-- Load nav mesh
	if (script_path:loadNavMesh()) then
		message = "Loading the oGasai maps...";
		return;
	end

	if (not self.isSetup) then
		script_fish:setup();
		return;
	end
	
	if (self.timer > GetTimeEX()) then return; end

	self.timer = GetTimeEX() + 150;

	if (self.pause) then 
		message = 'Paused by user.'; 
		return; 
	end

	-- Dead
	if (IsDead(localObj)) then
		if (self.alive) then self.alive = false; RepopMe(); self.message = "Releasing spirit..."; self.waitTimer = GetTimeEX() + 8000; return; end
		self.message = script_helper:ress(GetCorpsePosition()); 
		return;
	else
	-- Alive
		self.alive = true;
	end

	local localObj = GetLocalPlayer();
	local isInCombat = IsInCombat();

	self.alive = true;
	
	if (isInCombat and not self.wasInCombat) then
		self.wasInCombat = true;
		UseItem(weaponMainHand);
		UseItem(weaponOffHand);
	elseif(not isInCombat and self.wasInCombat) then
		self.wasInCombat = false;
		RunRestScript();
	end
		
	if(isInCombat) then
		message = "Running the combat script...";
		RunCombatScript(GetTarget());
		return
	else
		if (script_grind.shouldRest)  then
			message = "Running the rest script...";
			RunRestScript();
			return;
		end
	end

	-- Finish selling
	if (script_vendor.status == 2) then
		script_vendor:sell();
		self.timer = GetTimeEX() + 250;
		return;
	end
	
	if (AreBagsFull()) then
		if(self.useVendor and script_vendorEX.sellVendor ~= 0) then
			if (script_vendor.status == 1) then
				script_vendor:sell();
				self.timer = GetTimeEX() + 250;
				return;
			end
			if (script_vendor:sell()) then
				self.timer = GetTimeEX() + 250;
				return;
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage('script_fish: Stopping bot, bags are full...');
			StopBot();
			return;
		end
	end

	local x, y, z = GetUnitsPosition(localObj);
	local distToFishPos = math.sqrt((self.fishPos['x']-x)^2+(self.fishPos['y']-y)^2);
	
	if (distToFishPos > 3) then
		message = 'Moving to fishing position...';
		MoveToTarget(self.fishPos['x'], self.fishPos['y'], self.fishPos['z']);
		return;
	end

	bobberobj = script_fishEX:GetBobber();	
	if (bobberobj ~= 0) then	
		if (self.bobberInfo.GUID ~= bobberobj) then
			self.bobberInfo.x, self.bobberInfo.y, self.bobberInfo.z = GetObjectPosition(bobberobj);
			self.bobberInfo.GUID = bobberobj;
			self.bobberInfo.looted = false;
		end
	end
	
	if (bobberobj == 0 and not IsMoving() and not IsChanneling() and not IsCasting() and not IsLooting()) then
		message = "Cast Fishing Rod!";
		UseItem(self.PoleName);
		if (script_fishEX:checkLure(self.lureName)) then
			self.timer = GetTimeEX() + 6000;
			return;
		end
		CastSpellByName("Fishing");
		self.timer = GetTimeEX() + 1000;
	elseif (bobberobj ~= 0) then
		if (GetObjectState(bobberobj) == 0) then
			message = "Loot Fish!";
			if (not IsLooting()) then		
				GameObjectInteract(bobberobj);
				self.timer = GetTimeEX() + 500;
			else
				LootTarget(bobberobj);
				self.timer = GetTimeEX() + 200;
				self.bobberInfo.looted = true;
			end
		else
			message = "Waiting for bobber to move...";
		end
	end
end