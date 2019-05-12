script_gatherMenu = {
}

function script_gatherMenu:menu()

	if(not script_gather.isSetup) then
		script_gather:setup();
	end

	local wasClicked = false;
	
	if (CollapsingHeader("[Gather options")) then
		wasClicked, script_grind.gather = Checkbox("Gather on/off", script_grind.gather);
		
		wasClicked, script_gather.collectMinerals = Checkbox("Mining", script_gather.collectMinerals);
		SameLine();
		wasClicked, script_gather.collectHerbs = Checkbox("Herbalism", script_gather.collectHerbs);
		SameLine();
		wasClicked, script_target.skin = Checkbox("Skinning", script_target.skin);

		Text('Gather Search Distance');
		script_gather.gatherDistance = SliderFloat("GSD", 1, 150, script_gather.gatherDistance);
		
		if (script_gather.collectMinerals or script_gather.collectHerbs) then
			wasClicked, script_gather.gatherAllPossible = Checkbox("Gather everything we can", script_gather.gatherAllPossible);
		end

		if(script_gather.collectMinerals and not script_gather.gatherAllPossible) then
			Separator();
			Text('Minerals');
			
			for i=0,script_gather.numMinerals - 1 do
				wasClicked, script_gather.minerals[i][2] = Checkbox(script_gather.minerals[i][0], script_gather.minerals[i][2]);
				SameLine(); Text('(' .. script_gather.minerals[i][3] .. ')');
			end
		end
		
		if(script_gather.collectHerbs and not script_gather.gatherAllPossible) then
			Separator();
			Text('Herbs');
			
			for i=0,script_gather.numHerbs - 1 do
				wasClicked, script_gather.herbs[i][2] = Checkbox(script_gather.herbs[i][0], script_gather.herbs[i][2]);
				SameLine(); Text('(' .. script_gather.herbs[i][3] .. ')');
			end
		end
	end
end

function script_gatherMenu:getHerbSkill()
	local herbSkill = 0;
	for skillIndex = 1, GetNumSkillLines() do
  		skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier,
    		skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType,
    		skillDescription = GetSkillLineInfo(skillIndex)
    		if (skillName == 'Herbalism') then
			herbSkill = skillRank;
		end
	end

	return herbSkill;
end

function script_gatherMenu:getMiningSkill()
	local miningSkill = 0;
	for skillIndex = 1, GetNumSkillLines() do
  		skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier,
    		skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType,
    		skillDescription = GetSkillLineInfo(skillIndex)
    		if (skillName == 'Mining') then
			miningSkill = skillRank;
		end
	end

	return miningSkill;
end