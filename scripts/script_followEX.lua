script_followEX = {

}

function script_followEX:draw()
	-- Draw window
	script_followEX:window();

	-- Draw Nav Mesh path
	if (IsMoving()) then DrawMovePath(); end

	-- Draw info and status
	local pX, pY, onScreen = WorldToScreen(GetUnitsPosition(GetLocalPlayer()));
	if (onScreen) then
		DrawRectFilled(pX - 5, pY - 5, pX + 385, pY + 45, 0, 0, 0, 160, 0, 0);
		DrawRect(pX - 5, pY - 5, pX + 385, pY + 45, 0, 190, 45,  1, 1, 1);
		DrawText("Logitech's TBC Follower", pX, pY, 0, 190, 45);
		DrawText('Status: ' .. (script_follow.message or " "), pX, pY+10, 255, 255, 0);
		DrawText('Script Idle: ' .. math.max(script_follow.waitTimer - GetTimeEX(), 0) .. ' ms', pX, pY+20, 255, 255, 255);
		DrawText('Unstuck in: ' .. 10-math.floor(((GetTimeEX()-(script_path.savedPos['time'] or GetTimeEX()))/1000), 0) .. ' second(s)', pX, pY+30, 0, 255, 0);
	end
end

function script_followEX:followLeader()

	if (script_follow.leader ~= 0 and script_follow.leader ~= nil) then
		if (GetDistance(script_follow.leader) > script_follow.followDist) then
			MoveToTarget(script_follow.leader);
		else
			script_path:savePos(true); -- SAVE FOR UNSTUCK

			if (IsMoving()) then
				StopMoving();
			end
		end
	end
end

function script_followEX:moveInLineOfSight(partyMember)
	if (not IsInLineOfSight(partyMember) or GetDistance(partyMember) > 30) then
		local x, y, z = GetPosition(partyMember);
		MoveToTarget(x , y, z);
		return true;
	end

	script_path:savePos(true);

	if (IsMoving()) then
		StopMoving();
	end

	return false;
end

function script_followEX:healAndBuff()
	local localMana = GetManaPercentage(GetLocalPlayer());
	if (not IsStanding()) then StopMoving(); end
	-- Priest heal and buff
	for i = 1, GetNumPartyMembers()+1 do
		local partyMember = GetPartMember(i);
		if (i == GetNumPartyMembers()+1) then partyMember = GetLocalPlayer(); end
		local partyMembersHP = GetHealthPercentage(partyMember);
		if (partyMembersHP > 0 and partyMembersHP < 90 and localMana > 5) then
			
			-- Move in line of sight and in range of the party member
			if (script_followEX:moveInLineOfSight(partyMember)) then 
				return true; 
			end
			
			-- Renew
			if (localMana > 10 and partyMembersHP < 90 and not HasBuff(partyMember, "Renew") and HasSpell("Renew")) then
				if (Buff('Renew', partyMember)) then
					return true;
				end
			end

			-- Shield
			if (localMana > 10 and partyMembersHP < 80 and not HasDebuff(partyMember, "Weakened Soul") and IsInCombat() and HasSpell("Power Word: Shield")) then
				if (Buff('Power Word: Shield', partyMember)) then 
					return true; 
				end
			end

			-- Lesser Heal
			if (localMana > 10 and partyMembersHP < 70) then
				if (Cast('Lesser Heal', partyMember)) then
					self.waitTimer = GetTimeEX() + 3500;
					return true;
				end
			end

			-- Heal
			if (localMana > 15 and partyMembersHP < 50 and HasSpell("Heal")) then
				if (Cast('Heal', partyMember)) then
					self.waitTimer = GetTimeEX() + 4500;
					return true;
				end
			end

			-- Greater Heal
			if (localMana > 25 and partyMembersHP < 30 and HasSpell("Greater Heal")) then
				if (Cast('Greater Heal', partyMember)) then
					self.waitTimer = GetTimeEX() + 5500;
					return true;
				end
			end
		end

		if (not IsInCombat() and localMana > 40) then -- buff
			if (not HasBuff(partyMember, "Power Word: Fortitude") and HasSpell("Power Word: Fortitude")) then
				if (script_followEX:moveInLineOfSight(partyMember)) then return true; end -- move to member
				if (Buff("Power Word: Fortitude", partyMember)) then
					return true;
				end
			end	
		end
	end

	return false;
end

function script_followEX:getTarget()
	local target = GetTarget();

	local i, targetType = GetFirstObject();
	while i ~= 0 do
		if (targetType == 3 and not IsDead(i) and not IsCritter(i)) then
			if (script_followEX:isTargetingGroup(i)) then
				target = i;
			end
		end
		i, targetType = GetNextObject(i);
	end

	return GetTargetGUID(target);
end

function script_followEX:isTargetingGroup(y) 
	for i = 1, GetNumPartyMembers() do
		local partyMember = GetPartMember(i);
		if (partyMember ~= nil and partyMember ~= 0 and not IsDead(partyMember)) then
			if (GetUnitsTarget(y) ~= nil and GetUnitsTarget(y) ~= 0) then
				return GetGUID(GetUnitsTarget(y)) == GetGUID(partyMember);
			end
		end
	end
	return false;
end

function script_followEX:window() 
	EndWindow();
	if(NewWindow("Logitech's Follower", 200, 100)) then
		local wasClicked = false;
		if (Button("Start Bot")) then StartBot() end
		SameLine();
		if (script_follow.pause) then
			if (Button("Resume Bot")) then script_follow.pause = false; end
		else
			if (Button("Pause Bot")) then script_follow.pause = true; end end
		SameLine(); if (Button("Reload Scripts")) then menu:reload(); end
		SameLine(); if (Button("Exit Bot")) then StopBot(); end
		Separator();
		
		-- Load combat menu by class
		local class = UnitClass("player");
	
		if (class == 'Mage') then
			script_mage:menu();
		elseif (class == 'Hunter') then
			script_hunter:menu();
		elseif (class == 'Warlock') then
			script_warlock:menu();
		elseif (class == 'Paladin') then
			script_paladin:menu();
		elseif (class == 'Druid') then
			script_druid:menu();
		elseif (class == 'Priest') then
			script_priest:menu();
		elseif (class == 'Warrior') then
			script_warrior:menu();
		elseif (class == 'Rogue') then
			script_rogue:menu();
		elseif (class == 'Shaman') then
			script_shaman:menu();
		end
	end
end