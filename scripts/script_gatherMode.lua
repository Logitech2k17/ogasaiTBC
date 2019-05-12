script_gatherMode = {
	gatherScript = include("scripts\\script_gather.lua"),
	pathScript = include("scripts\\script_path.lua"),
	timer = 0,
	status = 'Gatherer...',
	saveNode = false,
	isSetup = false
}

function script_gatherMode:setup()
	self.timer = GetTimeEX();
	script_path:setup();

	DEFAULT_CHAT_FRAME:AddMessage('script_gatherMode: loaded...');
	self.isSetup = true;
end

function script_gatherMode:run()

	if (not self.isSetup) then
		script_gatherMode:setup();
	end

	if (script_path:loadNavMesh()) then
		self.status = 'Loading oGasai maps...';
		return;
	end

	if (self.timer > GetTimeEX()) then
		return;
	end

	self.timer = GetTimeEX() + 150;

	if (IsInCombat()) then
		self.status = 'Running combat script...';
		local target = GetNearestEnemy();
		if (GetDistance(GetTarget()) < 5) then
			StopMoving();
			return;
		end
		TargetEnemy(target);
		RunCombatScript(target);
		return;
	else
		if (script_gather:gather()) then
			self.status = 'Gathering ' .. script_gather:currentGatherName() .. '...';
			self.saveNode = false;
			return;
		end
	end

	if (not self.saveNode) then
		script_path:savePathNode();
		self.saveNode = true;
		self.status = 'Saving a path node...';
	end
	
	self.status = script_path:autoPath();
end

function script_gatherMode:window()
	EndWindow();
	if(NewWindow("Logitech's Gatherer", 200, 100)) then
		script_gatherMenu:menu();
		script_pathMenu:menu();
	end
end

function script_gatherMode:draw()
	script_gather:drawGatherNodes();
	DrawMovePath();

	local pX, pY, onScreen = WorldToScreen(GetUnitsPosition(GetLocalPlayer()));
	pX = pX - 70;
	pY = pY + 100;
	if (onScreen) then
		DrawRectFilled(pX - 5, pY - 5, pX + 250, pY + 30, 0, 0, 0, 160, 0, 0);
		DrawRect(pX - 5, pY - 5, pX + 250, pY + 30, 0, 190, 45,  1, 1, 1);
		DrawText("Logitech's Gatherer", pX, pY, 0, 190, 45);
		if (not IsInCombat()) then
			DrawText(self.status, pX, pY+10, 255, 128, 0);	
		else
			DrawText('In combat...', pX, pY+10, 255, 0, 0);	
		end
	end

	script_gatherMode:window();

	script_path:draw();
end