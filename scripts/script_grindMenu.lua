script_grindMenu = {
}

function script_grindMenu:menu()
	local wasClicked = false;
	if (script_grind.pause) then
		if (Button("Resume Bot")) then script_grind.pause = false; end
	else
		if (Button("Pause Bot")) then script_grind.pause = true; end end
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
	
	if (CollapsingHeader("[Mount, Talents & Display options")) then 
		wasClicked, script_grind.useMount = Checkbox("Use Mount", script_grind.useMount);
		SameLine(); wasClicked, script_grind.jump = Checkbox("Jump while moving (unmounted)", script_grind.jump);
		Separator();
		wasClicked, script_grind.autoTalent = Checkbox("Spend talent points", script_grind.autoTalent);
		Text("Change talents in script_talent.lua");
		if (script_grind.autoTalent) then Text("Spending next talent point in: " .. (script_talent:getNextTalentName() or " ")); end 
		Separator();
		wasClicked, script_grindEX.drawWindow = Checkbox("Draw grinder menus in a window", script_grindEX.drawWindow);
		wasClicked, script_grindEX.drawStatus = Checkbox("Draw grinder status window", script_grindEX.drawStatus);
		wasClicked, script_grindEX.drawGather = Checkbox("Draw gather nodes", script_grindEX.drawGather);
		wasClicked, script_grindEX.drawTarget = Checkbox("Draw info about units", script_grindEX.drawTarget);
		wasClicked, script_grindEX.drawPath = Checkbox("Draw move path", script_grindEX.drawPath);
		wasClicked, script_grindEX.drawAutoPath = Checkbox("Draw auto path nodes & hotspot", script_grindEX.drawAutoPath);
		Separator();
	end
	
	script_vendorMenu:menu();
	
	if (CollapsingHeader("[Rest options")) then
		wasClicked, script_grind.useMana = Checkbox("Class Uses Mana", script_grind.useMana);
		script_grind.restHp = SliderInt("Eat percent", 1, 99, script_grind.restHp);
		if (script_grind.useMana) then script_grind.restMana = SliderInt("Drink percent", 1, 99, script_grind.restMana); end
		Text("Use potions (when in combat):");
		script_grind.potHp = SliderInt("HP percent", 1, 99, script_grind.potHp);
		if (script_grind.useMana) then script_grind.potMana = SliderInt("Mana percent", 1, 99, script_grind.potMana); end
	end

	script_pathMenu:menu();

	if (CollapsingHeader("[Target options")) then
		Text("Scan for valid targets within X yds.");
		script_target.pullRange = SliderFloat("SD (yd)", 1, 150, script_target.pullRange);
		Text("Start attacking a new target within X yds.");
		script_grind.pullDistance = SliderFloat("PD (yd)", 1, 35, script_grind.pullDistance);
		Text("Attack targets within levels:");
		script_target.minLevel = SliderInt("Min Lvl", 1, 73, script_target.minLevel);
		script_target.maxLevel = SliderInt("Max Lvl", 1, 73, script_target.maxLevel);
		Separator();
		Text("Creature type selection:");
		local wasClicked = false;
		wasClicked, script_target.skipElites = Checkbox("Skip Elites", script_target.skipElites);
		SameLine();
		wasClicked, script_target.skipHumanoid = Checkbox("Skip Humanoids", script_target.skipHumanoid);
		wasClicked, script_target.skipUndead = Checkbox("Skip Undeads", script_target.skipUndead);
		SameLine();
		wasClicked, script_target.skipDemon = Checkbox("Skip Demons", script_target.skipDemon);
		wasClicked, script_target.skipBeast = Checkbox("Skip Beasts", script_target.skipBeast);
		SameLine();
		wasClicked, script_target.skipAberration= Checkbox("Skip Aberrations", script_target.skipAberration);
		wasClicked, script_target.skipDragonkin = Checkbox("Skip Dragonkin", script_target.skipDragonkin);
		SameLine();
		wasClicked, script_target.skipGiant = Checkbox("Skip Giants", script_target.skipGiant);
		wasClicked, script_target.skipMechanical = Checkbox("Skip Mechanicals", script_target.skipMechanical);
		SameLine();
		wasClicked, script_target.skipElemental = Checkbox("Skip Elementals", script_target.skipElemental);
	end

	script_target:lootMenu();

	script_gatherMenu:menu();
end