script_info = {

}

function script_info:playersNearby(dist)

	-- Return if another player (alive) is within distance
	local i, targetType = GetFirstObject();
	while i ~= 0 do
		if (targetType == 4 and not IsDead(i)) then
			if (GetDistance(i) <= dist) then
				return true;
			end
		end
		i, targetType = GetNextObject(i);
	end

	return false;
end

function script_info:nrTargetingMe()
	local player = GetLocalPlayer();
	local adds = 0;

	-- Return the number of mobs targeting us
	local i, targetType = GetFirstObject();
	while i ~= 0 do
		if (targetType == 3) then
			if (GetUnitsTarget(i) ~= 0) then
				if (GetGUID(GetUnitsTarget(i)) == GetGUID(player)
					or GetTargetGUID(GetUnitsTarget(i)) == GetTargetGUID(GetPet())
				) then 
					adds = adds + 1;
				end
			end
		end
		i, targetType = GetNextObject(i);
	end

	return adds;
end

function script_info:addTargetingMe(mainTarget)
	local player = GetLocalPlayer();
	local add = nil;

	-- Return an add targeting us
	local i, targetType = GetFirstObject();
	while i ~= 0 do
		if (targetType == 3) then
			if (GetUnitsTarget(i) ~= 0 and i ~= mainTarget) then
				if (GetGUID(GetUnitsTarget(i)) == GetGUID(player)) then 
					add = i;
				end
			end
		end
		i, targetType = GetNextObject(i);
	end

	return add;
end

function script_info:targetingMe()
	local player = GetLocalPlayer();

	-- Return if another player is targeting us
	local i, targetType = GetFirstObject();
	while i ~= 0 do
		if (targetType == 4) then
			if (GetUnitsTarget(i) ~= 0) then
				if (GetGUID(GetUnitsTarget(i)) == GetGUID(player)) then 
					return true;
				end
			end
		end
		i, targetType = GetNextObject(i);
	end

	return false;
end

function script_info:drawUnitsDataOnScreen()
	local i, targetType = GetFirstObject();
	while i ~= 0 do
		if (targetType == 3 and not IsCritter(i) and not IsDead(i) and CanAttack(i)) then
			script_info:drawMonsterDataOnScreen(i);
		end
		if (targetType == 4 and not IsCritter(i) and not IsDead(i)) then
			script_info:drawPlayerDataOnScreen(i);
		end
		i, targetType = GetNextObject(i);
	end
end

function script_info:drawMonsterDataOnScreen(target)
	local player = GetLocalPlayer();
	local distance = GetDistance(target);
	local tX, tY, onScreen = WorldToScreen(GetPosition(target));
	if (onScreen) then
		DrawText(GetCreatureType(target) .. ' - ' .. GetLevel(target), tX, tY-10, 255, 255, 0);
		if (GetTarget() == target) then 
			DrawText('(targeted)', tX, tY-20, 255, 0, 0); 
		end
		DrawText('HP: ' .. math.floor(GetHealthPercentage(target)), tX, tY, 255, 0, 0);
		DrawText('' .. math.floor(distance) .. ' yd.', tX, tY+10, 255, 255, 255);
	end
end

function script_info:drawPlayerDataOnScreen(target)
	local player = GetLocalPlayer();
	if (GetGUID(target) ~= GetGUID(player)) then 
		local distance = GetDistance(target);
		local tX, tY, onScreen = WorldToScreen(GetPosition(target));
		if (onScreen) then
			if (CanAttack(target)) then 
				DrawText('Enemy Player' .. ' - ' .. GetLevel(target), tX, tY-10, 255, 0, 0);
			else 
				DrawText('Friendly Player' .. ' - ' .. GetLevel(target), tX, tY-10, 0, 255, 0);
			end
			DrawText('HP: ' .. math.floor(GetHealthPercentage(target)), tX, tY, 255, 0, 0);
			DrawText('' .. math.floor(distance) .. ' yd.', tX, tY+10, 255, 255, 255);
			if (GetUnitsTarget(target) ~= 0) then
				if (GetGUID(GetUnitsTarget(target)) == GetGUID(player)) then 
					DrawText('TARGETING US!', tX, tY+20, 255, 0, 0); 
				end
			end
		end
	end
end

function script_info:waitGroup()
		-- Check: If in group wait for members to be within 60 yards and 75 percent mana
		local groupMana = 0;
		local manaUsers = 0;
		for i = 1, GetNumPartyMembers() do
			local partyMember = GetPartMember(i);
			if (GetManaPercentage(partyMember) > 0) then
				groupMana = groupMana + GetManaPercentage(partyMember);
				manaUsers = manaUsers + 1;
			end
			if (GetDistance(partyMember) > 50 and not IsInCombat()) then
				if (IsMoving()) then StopMoving(); end
				script_path:savePos(true);
				return true;
			end
		end
		if (groupMana/manaUsers < 75 and GetNumPartyMembers() >= 1 and not IsInCombat()) then
			if (IsMoving()) then StopMoving(); end
			script_path:savePos(true);
			return true;
		end
end