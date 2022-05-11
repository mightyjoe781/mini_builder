-- Load support for MT game translation.
local S = minetest.get_translator("creative")
local MP = minetest.get_modpath(minetest.get_current_modname())

local mbuild = {
    items = {},
}
mbuild.get_translator = S

-- define a function that can reload mbuild.items tables
local function reload_mbuild()
    mbuild.items = {}
    local file = io.open(MP.."/items.txt", "r")
    if not file then
        minetest.log("error", "mbuild: items.txt not found")
        return
    end
    for line in file:lines() do
        table.insert(mbuild.items, line)
    end
    file:close()
end

-- reload once on startup mbuild.items table
reload_mbuild()

minetest.register_privilege("builder", {
	description = S("Allow player to use restricted creative inventory"),
	give_to_singleplayer = false,
	give_to_admin = false,
})

minetest.register_chatcommand("bgive",{
    params = S("<item> <count>"),
    description = S("Give player item(s)"),
    privillage = "builder",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, S("Player not found")
        end
        local params = param:split(" ")
        if #params < 2 then
            return false, S("Invalid parameters")
        end
        local item = params[1]
        local count = tonumber(params[2])
        if not item or not count then
            return false, S("Invalid parameters")
        end
        local inv = player:get_inventory()
        if not inv then
            return false, S("Player inventory not found")
        end
        -- check if items are in allowed inventory list
        if not mbuild.items[item] then
            return false, S("Item not allowed")
        end
        -- before adding to inventory check if player has enough space
        if not inv:room_for_item("main", {name=item, count=count}) then
            return false, S("Player inventory is full")
        end
        -- check if item exists in minetest global registered nodes table
        if not minetest.registered_items[item] then
            return false, S("Item not found")
        end
        inv:add_item("main", item.." "..count)
        return true, S("Item(s) given")
    end
})

-- chatcommand to reload mbuild.items table
minetest.register_chatcommand("mbuild_reload",{
    params = S(""),
    description = S("Reload mbuild items table"),
    privillage = "builder",
    func = function(name, param)
        reload_mbuild()
        return true, S("Items table reloaded")
    end
})