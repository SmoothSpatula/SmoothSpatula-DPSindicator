local dps_enabled = true

log.info("Successfully loaded ".._ENV["!guid"]..".")

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Show DPS", dps_enabled)
    if clicked then
        dps_enabled = new_value
    end
end)

function get_value( t, key )
    for k,v in pairs(t) do 
        if k==key then return v end
    end
    return nil
end
  
function add_inst(tab, id, size)
    tab[id] = {}
    for i = 1, size do tab[id][i] = 0 end
    tab[id]['total'] = 0
end

local damage_index = 1
local ingame = false
local damage_tab = {}
local nb_tp = 12 --number of tick periods
local tpl = 5 --tick period length
local ratio = 60 / (nb_tp * tpl)

-- Adds damage together from last 5 ticks
gm.post_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
    if not dps_enabled then return end
    if not ingame then
        damage_tab = {} 
        ingame = true
        for i = 1, #gm.CInstance.instances_active do
            local inst = gm.CInstance.instances_active[i]
            if inst.object_index == gm.constants.oP then
                add_inst(damage_tab, inst.id, nb_tp)
            end
        end  
    end

    local damage_actor = get_value(damage_tab, args[6].value.id)
    if damage_actor == nil then return end
    local actor = args[6].value
    local damage_actor = get_value(damage_tab, actor.id)
    damage_actor[damage_index] = damage_actor[damage_index] + args[4].value
    
end)


local tick_counter = 0
gm.pre_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    if not dps_enabled then return end
    tick_counter = tick_counter + 1
    if tick_counter == tpl then
        for id, damage_actor in pairs(damage_tab) do 
            damage_actor['total'] = damage_actor['total'] + damage_actor[damage_index]
        end
        damage_index = damage_index + 1
        if damage_index==nb_tp + 1 then damage_index = 1 end
        for id, damage_actor  in pairs(damage_tab) do 
            damage_actor['total'] = damage_actor['total'] - damage_actor[damage_index]
            damage_actor[damage_index] = 0
        end
        tick_counter = 0
    end
end)

gm.post_code_execute(function(self, other, code, result, flags)
    if code.name:match("oInit_Draw_7") then
        if not ingame or not dps_enabled then return end
        for i = 1, #gm.CInstance.instances_active do
            local inst = gm.CInstance.instances_active[i]
            if inst.object_index == gm.constants.oP then
                local damage_actor = get_value(damage_tab, inst.id)
                if damage_actor == nil then return end
                local damage_to_display = damage_actor['total']*ratio  
                gm.draw_text(inst.x, inst.y+25, "DPS : " .. math.floor(damage_to_display))
            end
        end
    end
end)

gm.pre_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    ingame = false
end)
