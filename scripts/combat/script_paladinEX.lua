script_paladinEX = {
	isSetup = false
}

function script_paladinEX:setup()
	-- Sort Aura  
	if (not HasSpell('Retribution Aura') and not HasSpell('Sanctity Aura')) then
		script_paladin.aura = 'Devotion Aura';	
	elseif (not HasSpell('Sanctity Aura') and HasSpell('Retribution Aura')) then
		script_paladin.aura = 'Retribution Aura';
	elseif (HasSpell('Sanctity Aura')) then
		script_paladin.aura = 'Sanctity Aura';	
	end

	-- Sort Blessing  
	if (HasSpell('Blessing of Wisdom')) then
		script_paladin.blessing = 'Blessing of Wisdom';
	elseif (HasSpell("Blessing of Might")) then
		script_paladin.blessing = 'Blessing of Might';
	end

	-- Set pull range
	script_grind.pullDistance = 4;

	DEFAULT_CHAT_FRAME:AddMessage('script_paladinEX: loaded...');

	self.isSetup = true;
end

function script_paladinEX:isBuff(buff)
	for i=1,40 do
  		local name, icon, _, _, _, etime = UnitBuff("player", i);
  		if name == buff and name ~= nil then
    			return true;
  		end
	end
	
	return false;
end

function script_paladinEX:meleeAttack(targetGUID)
	targetObj = GetGUIDTarget(targetGUID);

	local targetHealth = GetHealthPercentage(targetObj);
	local localMana = GetManaPercentage(GetLocalPlayer());

	if ((IsCasting(targetObj) or IsFleeing(targetObj)) and HasSpell('Hammer of Justice') and not IsSpellOnCD('Hammer of Justice')) then
		if (Cast('Hammer of Justice', targetGUID)) then self.hJtime = GetTimeEX() + 4000; self.waitTimer = GetTimeEX() + 2000; return true; end
	end

	if (HasSpell('Hammer of Wrath') and not IsSpellOnCD('Hammer of Wrath') and targetHealth < 20) then
		if (Cast('Hammer of ', targetGUID)) then return true; end
	end

	-- Combo Check 1: Stun the target if we have HoJ and SoC
	if (HasSpell('Hammer of Justice') and not IsSpellOnCD('Hammer of Justice') and targetHealth > 50 and script_paladinEX:isBuff('Seal of Command') and localMana > 50 and not IsSpellOnCD('Judgement')) then
		if (Cast('Hammer of Justice', targetGUID)) then return true; end
	end
		
	-- Combo Check 2: Use Judgement on the stunned target
	if (script_paladinEX:isBuff('Seal of Command') and GetDistance(targetObj) < 10 and script_target:hasDebuff("Hammer of Justice")) then
		CastSpellByName('Judgement'); return true;
	end

	-- Check: Seal of the Crusader until we used judgement
	if (not script_target:hasDebuff("Judgement of the Crusader") and targetHealth > 20
		and not script_paladinEX:isBuff("Seal of the Crusader") and HasSpell('Seal of the Crusader')) then
		CastSpellByName('Seal of the Crusader'); return true;
	end 

	-- Check: Judgement when we have crusader
	if (GetDistance(targetObj) < 10  and script_paladinEX:isBuff('Seal of the Crusader') and
		not IsSpellOnCD('Judgement') and HasSpell('Judgement')) then
			CastSpellByName('Judgement'); return true;
	end

	-- Check: Seal of Righteousness (before we have SoC)
	if (not script_paladinEX:isBuff("Seal of Righteousness") and not script_paladinEX:isBuff("Seal of the Crusader") and not HasSpell('Seal of Command')) then 
		CastSpellByName('Seal of Righteousness'); return true;
	end

	-- Check: Judgement with Righteousness or Command if we have a lot of mana
	if ((script_paladinEX:isBuff("Seal of Righteousness") or script_paladinEX:isBuff("Seal of Command"))
		 and not IsSpellOnCD('Judgement') and localMana > 80) then 
		CastSpellByName('Judgement'); return true; 
	end

	-- Check: Use judgement if we are buffed with Righteousness or Command and the target is low
	if ((script_paladinEX:isBuff('Seal of Righteousness') or script_paladinEX:isBuff('Seal of Command'))
		and GetDistance(targetObj) < 10 and targetHealth < 10) then
		if (Cast('Judgement', targetGUID)) then return true; end
	end

	-- Check: Seal of Command
	if (not script_paladinEX:isBuff("Seal of Command") and not script_paladinEX:isBuff("Seal of the Crusader")) then 
		CastSpellByName('Seal of Command'); return true;
	end

	if (Cast("Crusader Strike", targetGUID)) then return true; end 

	return false;
end