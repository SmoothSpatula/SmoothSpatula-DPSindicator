-- DPS Indicator v1.0.0
-- SmoothSpatula

local dps_enabled = true

-- Parameters (in frames/ticks)

local nb_tp = 12 --number of tick periods before the damage is removed from the counter
local tick_length = 5 --time between 2 damage updates 
local ratio = 60 / (nb_tp * tick_length)

-- ========== ImGui ==========

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Show DPS", dps_enabled)
    if clicked then
        dps_enabled = new_value
    end
end)

-- ========== Utils ==========

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

-- ========== Main ==========

local damage_index = 1
local ingame = false
local damage_tab = {}

-- Adds damage together from last 5 ticks
gm.post_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
    if not dps_enabled then return end
    -- Get the player ids on first damage dealt
    -- (Tried to use run_create but player instances don't exist yet)
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
    if args[6].type == 0 then return end --check if damage is done by an instance
    local actor = args[6].value
    local damage_actor = get_value(damage_tab, actor.id)
    if damage_actor == nil then return end --check if instance is a player
    damage_actor[damage_index] = damage_actor[damage_index] + args[4].value
    
end)

-- Cycle through the damage in a queue
local tick_counter = 0
gm.pre_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    if not dps_enabled then return end
    tick_counter = tick_counter + 1
    if tick_counter == tick_length then
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

-- Hijack the Draw event
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

-- Disable mod when run ends
gm.pre_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    ingame = false
end)
