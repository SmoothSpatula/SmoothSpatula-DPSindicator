-- DPS Indicator v1.0.6
-- SmoothSpatula

mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.tomlfuncs then Toml = v end end 
    params = {
        dps_enabled = true
    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
end)
mods.on_all_mods_loaded(function() for _, m in pairs(mods) do if type(m) == "table" and m.RoRR_Modding_Toolkit then for _, c in ipairs(m.Classes) do if m[c] then _G[c] = m[c] end end end end end)

-- Parameters (in frames/ticks)

local nb_tp = 12 --number of tick periods before the damage is removed from the counter
local tick_length = 5 --time between 2 damage updates 
local ratio = 60 / (nb_tp * tick_length)

-- ========== ImGui ==========
gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Show DPS", params['dps_enabled'])
    if clicked then
        params['dps_enabled'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
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
    if not params['dps_enabled'] then return end
    if args[6].type == 0 then return end --check if damage is done by an instance
    local actor = args[6].value
    if actor.master ~= nil then actor = actor.master end
    if actor.parent ~= nil then actor = actor.parent end
    local damage_actor = get_value(damage_tab, actor.id)
    if damage_actor == nil then return end --check if instance is a player
    damage_actor[damage_index] = damage_actor[damage_index] + args[4].value
end)

-- Cycle through the damage in a queue
local tick_counter = 0
gm.pre_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    if not params['dps_enabled'] then return end
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

-- Replaced for improved performance
function __initialize()
    Callback.add("postHUDDraw", "SmoothSpatula-DPSIndicator-Draw", function()
        if not ingame or not params['dps_enabled'] then return end
        for i = 1, #gm.CInstance.instances_active do
            local inst = gm.CInstance.instances_active[i]
            if inst.object_index == gm.constants.oP then
                local damage_actor = get_value(damage_tab, inst.id)
                if damage_actor == nil then return end
                local damage_to_display = damage_actor['total']*ratio  
                gm.draw_text(inst.x, inst.y+25, "DPS : " .. math.floor(damage_to_display))
            end
        end
    end)

    -- Init on stage start
    Callback.add("onStageStart", "SmoothSpatula-DPSIndicator-StageStart", function()
        damage_tab = {}
        ingame = true
        for i = 1, #gm.CInstance.instances_active do
            local inst = gm.CInstance.instances_active[i]
            if inst.object_index == gm.constants.oP then
                add_inst(damage_tab, inst.id, nb_tp)
            end
        end 
    end)
    
    Callback.add("onGameEnd", "SmoothSpatula-DPSIndicator-StageStart", function()
        ingame = false
    end)
end
