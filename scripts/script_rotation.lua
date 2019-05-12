script_rotation = {}

function script_rotation:draw()

end

function script_rotation:run()
	if(GetTarget() ~= 0) then
		RunCombatScript(GetTarget());
	else
		RunRestScript();
	end
end


function script_rotation:menu()

end
