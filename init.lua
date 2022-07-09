local MP = minetest.get_modpath(minetest.get_current_modname())

local mbuild = {
    items = {},
}

-- define a function that can reload mbuild.items tables
local function reload_mbuild()
    mbuild.items = {}
    local file = io.open(MP.."/items.txt", "r")
    if not file then
        minetest.log("error", "mbuild: items.txt not found")
        return
    end
    -- for each line put it in mbuild table
    local count = 0
    for line in file:lines() do
        count = count + 1
        -- partial naming support is removed because
        -- all mods do not have alias defined and prevents unknown
        -- regex issues from item names
        mbuild.items[line] = true
    end

    file:close()
    -- log the number of items loaded
    minetest.log("action", "mbuild: "..count.." items loaded")
end

-- a function to check if an item matches a regex pattern from mbuild table
local function check_item(item)
    if mbuild.items[item] then
        return true
    else
        -- do regex check on items from mbuild that have * in them
        for k, _ in pairs(mbuild.items) do
            if string.find(k, "*") then
                k = string.gsub(k, "*", "%.-")
                if string.find(item, k) then
                    return true
                end
            end
        end
    end
    return false
end


-- reload once on startup mbuild.items table
reload_mbuild()

minetest.register_privilege("builder", {
	description = "Allow player to use restricted creative inventory",
	give_to_singleplayer = false,
	give_to_admin = false,
})

minetest.register_chatcommand("bgive",{
    params = "<item> <count>",
    description = "Give player item(s)",
    privilage = "builder",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        -- check privilage is builder or not
        if not minetest.check_player_privs(name, {builder=true}) then
            return false, "You don't have permission to use this command"
        end
        local params = param:split(" ")
        if #params < 2 then
            return false, "Invalid parameters"
        end
        local item = params[1]
        local count = tonumber(params[2])
        if not item or not count then
            return false, "Invalid parameters"
        end
        local inv = player:get_inventory()
        if not inv then
            return false, "Player inventory not found"
        end
        -- check if items are in allowed inventory list
        if not check_item(item) then
            return false, "Item not allowed"
        end
        -- before adding to inventory check if player has enough space
        if not inv:room_for_item("main", {name=item, count=count}) then
            return false, "Player inventory is full"
        end
        -- check if item exists in minetest global registered nodes table
        if not minetest.registered_items[item] then
            return false, "Item not found"
        end
        inv:add_item("main", item.." "..count)
        -- log the action
        minetest.log("action", name.." gave "..count.." "..item.." to "..player:get_player_name())
        return true, "Item(s) given"
    end
})

-- chatcommand to reload mbuild.items table
minetest.register_chatcommand("bgive_reload",{
    params = "",
    description = "Reload mbuild items table",
    func = function(name, param)
        -- allow no parameters
        if param ~= "" then
            return false, "Invalid parameters"
        end
        -- check auth level of person
        if not minetest.check_player_privs(name, {server=true}) then
            return false, "You are not allowed to reload items table"
        end
        reload_mbuild()
        return true, "Items table reloaded"
    end
})

-- print OK on startup
print("[mini_builder] Loaded")
