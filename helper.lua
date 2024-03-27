-- Helper

local self = {}


--[[
    find_active_instance(index) -> instance or nil

    index           The object_index of the instance

    Returns the first active instance of the specified
    object_index, or nil if none can be found.
]]
self.find_active_instance = function(index)
    for i = 1, #gm.CInstance.instances_active do
        local inst = gm.CInstance.instances_active[i]
        if inst.object_index == index then
            return inst
        end
    end
    return nil
end


--[[
    find_active_instance_all(index) -> table or nil

    index           The object_index of the instance

    Returns a table of all active instances of the
    specified object_index, or nil if none can be found.
]]
self.find_active_instance_all = function(index)
    local objs = {}
    for i = 1, #gm.CInstance.instances_active do
        local inst = gm.CInstance.instances_active[i]
        if inst.object_index == index then
            table.insert(objs, inst)
        end
    end
    if #objs > 0 then return objs end
    return nil
end


--[[
    does_instance_exists(inst) -> bool

    inst            The instance to check

    Returns true if the instance is not
    lua nil, and if the instance is "valid".
]]
self.does_instance_exist = function(inst)
    return inst and gm._mod_instance_valid(inst) == 1.0
end


--[[
    get_client_player() -> instance or nil

    Returns the player instance belonging to
    this client, or nil if none can be found.
]]
self.get_client_player = function()
    -- Using pref_name to identify which player is this client
    -- TODO: Find a better way of checking instead
    local pref_name = ""
    local init = self.find_active_instance(gm.constants.oInit)
    if init then pref_name = init.pref_name end

    -- Get the player that belongs to this client
    local players = self.find_active_instance_all(gm.constants.oP)
    if players then
        for i = 1, #players do
            if players[i] then
                if players[i].user_name == pref_name then
                    return players[i]
                end
            end
        end
    end

    return nil
end


return self