local share_gold_enabled = true

Helper = require("./helper")

log.info("Successfully loaded ".._ENV["!guid"]..".")

local damage_per_5ticks = {}
for i = 1, 24 do damage_per_5ticks[i] = 0 end

local damage_index = 1
local player = nil
local total_damage = 0
local ingame = false




-- Adds damage together from last 5 ticks
gm.post_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
    ingame = true
    if not Helper.does_instance_exist(player) then
        player = Helper.get_client_player()
    end
    if args[6].type ~= 15 then return end 
    local actor = args[6].value
    if player.id == actor.id then
        damage_per_5ticks[damage_index] = damage_per_5ticks[damage_index] + args[4].value
    end

end)


-- Every 5 ticks removes the damage done 60 ticks ago and adds damage done in last 5 ticks
local tick_counter = 0
gm.pre_script_hook(gm.constants.__input_system_tick, function()
    tick_counter = tick_counter + 1
    if tick_counter == 5 then
        total_damage = total_damage + damage_per_5ticks[damage_index]
        damage_index = damage_index + 1
        if damage_index==25 then damage_index =1 end
            total_damage = total_damage - damage_per_5ticks[damage_index]
            damage_per_5ticks[damage_index], tick_counter = 0, 0
    end
end)

-- Hijacks the draw event to write our dps text
--local skill_x, skill_y = 0, 0
gm.post_code_execute(function(self, other, code, result, flags)
    if not ingame or player == nil then
        return
    end
    
    if code.name:match("oInit_Draw") then
        for i = 1, #gm.CInstance.instances_active do
            local inst = gm.CInstance.instances_active[i]
            if inst.id == player.id then
                gm.draw_text_ext_w(inst.x, inst.y+25, "DPS : " .. math.floor(total_damage/2), 101, 100)
            end
        end
    end
end)



gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    ingame = true
    player = Helper.get_client_player()
end)

gm.pre_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    ingame = false
end)


