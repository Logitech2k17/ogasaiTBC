script_targetEX = {
	
}

function script_targetEX:getNearestEnemy() 
	local closestDist = 999;
	local enemy = nil;

	-- return last target
	if (script_grind.target ~= nil and script_grind.target ~= 0) then
		if (not IsDead(script_grind.target) and IsInCombat() and GetHealthPercentage(script_grind.target) < 100) then
			if (GetGUID(GetUnitsTarget(script_grind.target)) == GetGUID(GetLocalPlayer())
				or GetTargetGUID(GetUnitsTarget(script_grind.target)) == GetTargetGUID(GetPet()) 
				or IsTappedByMe(script_grind.target)) then
				return script_grind.target;
			end
		end
	end

	-- return enemy attacking us
	local i, targetType = GetFirstObject();
	while i ~= 0 do
		if (targetType == 3) then
			if (not IsDead(i) and CanAttack(i) and not IsCritter(i)) then
				if (GetTargetGUID(GetUnitsTarget(i)) == GetTargetGUID(GetLocalPlayer())
					or GetTargetGUID(GetUnitsTarget(i)) == GetTargetGUID(GetPet())) then
					return i;
				end
			end
		end
		i, targetType = GetNextObject(i);
	end

	-- fetch a new target
	i, targetType = GetFirstObject();
	while i ~= 0 do
		if (targetType == 3) then
			if (not IsDead(i) and CanAttack(i) and not IsCritter(i)) then
				-- valid check: level, range, tapped
				local iLevel = GetLevel(i);
				local dist = GetDistance(i);
				if (dist < script_target.pullRange 
					and iLevel >= script_target.minLevel and iLevel <= script_target.maxLevel
					and (not IsTapped(i) or IsTappedByMe(i))
					and script_targetEX:isValid(i)) then
					if (dist < closestDist) then
						closestDist = dist;
						enemy = i;
					end
				end

			end
		end
		i, targetType = GetNextObject(i);
	end

	-- Check: If we are in combat but no valid target, kill the "unvalid" target attacking us
	if (enemy == nil and IsInCombat()) then
		if (GetTarget() ~= 0) then
			return GetTarget();
		end
	end

	return enemy;
end

function script_targetEX:isValid(i)

	local creatureType = GetCreatureType(i);
	--local classification = GetClassification(i);

	if (script_target.skipHumanoid and strfind("Humanoid", creatureType)) then
		return false;
	elseif (script_target.skipHumanoid and strfind("Humanoid", creatureType)) then
		return false;
	elseif (script_target.skipElemental and strfind("Elemental", creatureType)) then
		return false;
	elseif (script_target.skipUndead  and strfind("Undead ", creatureType)) then
		return false;
	elseif (script_target.skipDemon and strfind("Demon", creatureType)) then
		return false;
	elseif (script_target.skipBeast and strfind("Beast", creatureType)) then
		return false;
	elseif (script_target.skipAberration and strfind("Aberration", creatureType)) then
		return false;
	elseif (script_target.skipDragonkin and strfind("Dragonkin", creatureType)) then
		return false;
	elseif (script_target.skipGiant and strfind("Giant", creatureType)) then
		return false;
	elseif (script_target.skipMechanical and strfind("Mechanical", creatureType)) then
		return false;
	end

	--if (script_target.skipElites and classification > 0) then
	--	return false;
	--end

	return true;
end