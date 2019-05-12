menu = {
	--Setup
	isSetup = false
}

function menu:reload()
	self.isSetup = false;
	menu:draw();
end

function menu:draw()

	if (self.isSetup == false) then
		
		self.isSetup = true;
		
		DEFAULT_CHAT_FRAME:AddMessage('menu.lua: Loading scripts...');
		DEFAULT_CHAT_FRAME:AddMessage('How to use:');
		DEFAULT_CHAT_FRAME:AddMessage("1. Select a mode script (MS) and a combat script (CS)...");
		DEFAULT_CHAT_FRAME:AddMessage("2. Push Start...");		

		-- Include scripts
		include("core.lua");
		include("scripts\\db\\hotspotDB.lua");
		include("scripts\\db\\vendorDB.lua");
	
		-- Mode scripts
		LoadScript("Grinder", "scripts\\script_grind.lua");
		AddScriptToMode("Logitech's Grinder", "script_grind");

		LoadScript("Follow", "scripts\\script_follow.lua");
		AddScriptToMode("Logitech's Follow", "script_follow");

		LoadScript("Gather", "scripts\\script_gatherMode.lua");
		AddScriptToMode("Logitech's Gather", "script_gatherMode");

		LoadScript("Fish", "scripts\\script_fish.lua");
		AddScriptToMode("Logitech's Fishing", "script_fish");

		-- Combat scripts
		LoadScript("Mage", "scripts\\combat\\script_mage.lua");
		AddScriptToCombat("Mage - Frost", "script_mage");

		LoadScript("Hunter", "scripts\\combat\\script_hunter.lua");
		AddScriptToCombat("Hunter - Beastmaster", "script_hunter");	

		LoadScript("Warlock", "scripts\\combat\\script_warlock.lua");
		AddScriptToCombat("Warlock - Afflic/Demo", "script_warlock");

		LoadScript("Paladin", "scripts\\combat\\script_paladin.lua");
		AddScriptToCombat("Paladin - Retribution", "script_paladin");

		LoadScript("Druid", "scripts\\combat\\script_druid.lua");
		AddScriptToCombat("Druid - Feral", "script_druid");	

		LoadScript("Priest", "scripts\\combat\\script_priest.lua");
		AddScriptToCombat("Priest - Shadow", "script_priest");

		LoadScript("Warrior", "scripts\\combat\\script_warrior.lua");
		AddScriptToCombat("Warrior - Fury", "script_warrior");

		LoadScript("Rogue", "scripts\\combat\\script_rogue.lua");
		AddScriptToCombat("Rogue - Combat", "script_rogue");

		LoadScript("Shaman", "scripts\\combat\\script_shaman.lua");
		AddScriptToCombat("Shaman - Enhance", "script_shaman");

	end

	Separator();

	-- Add mode menus
	if (CollapsingHeader("[Grinder options")) then
		script_grindMenu:menu();
	end

	script_gatherMenu:menu();

	if (CollapsingHeader("[Fishing options")) then
		script_fishEX:menu();
	end

	Separator();

	-- Add Combat scripts menus
	if (CollapsingHeader("[Combat options")) then
		script_mage:menu();
		script_hunter:menu();
		script_warlock:menu();
		script_paladin:menu();
		script_druid:menu();
		script_priest:menu();
		script_warrior:menu();
		script_rogue:menu();
		script_shaman:menu();
	end
	
end