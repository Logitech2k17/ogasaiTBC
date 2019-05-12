script_mageEX = {
	isSetup = false,
}

function script_mageEX:addWater(name)
	script_mage.water[script_mage.numWater] = name;
	script_mage.numWater = script_mage.numWater + 1;
end

function script_mageEX:addFood(name)
	script_mage.food[script_mage.numfood] = name;
	script_mage.numfood = script_mage.numfood + 1;
end

function script_mageEX:addManaGem(name)
	script_mage.manaGem[script_mage.numGem] = name;
	script_mage.numGem = script_mage.numGem + 1;
end

function script_mageEX:setup()
	script_mageEX:addWater('Conjured Glacier Water');
	script_mageEX:addWater('Conjured Crystal Water');
	script_mageEX:addWater('Conjured Sparkling Water');
	script_mageEX:addWater('Conjured Mineral Water');
	script_mageEX:addWater('Conjured Spring Water');
	script_mageEX:addWater('Conjured Purified Water');
	script_mageEX:addWater('Conjured Fresh Water');
	script_mageEX:addWater('Conjured Water');
	
	script_mageEX:addFood('Conjured Croissant');
	script_mageEX:addFood('Conjured Cinnamon Roll');
	script_mageEX:addFood('Conjured Sweet Roll');
	script_mageEX:addFood('Conjured Sourdough')
	script_mageEX:addFood('Conjured Pumpernickel');
	script_mageEX:addFood('Conjured Rye');
	script_mageEX:addFood('Conjured Bread');
	script_mageEX:addFood('Conjured Muffin');
	
	script_mageEX:addManaGem('Mana Ruby');
	script_mageEX:addManaGem('Mana Agate');
	script_mageEX:addManaGem('Mana Citrine');
	script_mageEX:addManaGem('Mana Jade');
	script_mageEX:addManaGem('Mana Ruby');

	DEFAULT_CHAT_FRAME:AddMessage('script_mageEX: loaded...');
	script_mageEX.isSetup = true;
end