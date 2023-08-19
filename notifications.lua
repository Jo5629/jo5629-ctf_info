ctf_info.notifications = {}
ctf_info.notification_formspec_players = {}

minetest.register_on_leaveplayer(function(player)
    ctf_info.notifications[player:get_player_name()] = nil
end)

minetest.register_on_joinplayer(function(player)
    ctf_info.notifications[player:get_player_name()] = {}
end)

local maps = {}

for k, map in pairs(ctf_info.maps) do
    table.insert(maps, map)
end

local function get_formspec(name)
    local notifications = {}
    for i = 1, #ctf_info.notifications[name] do
        local notification_table = ctf_info.notifications[name][i]
        local deserialized_table = minetest.deserialize(notification_table)
        table.insert(notifications, deserialized_table.string_with_pos)
    end

    local formspec = {
        "formspec_version[4]",
        "size[12,12]",
        "label[0.375,0.8;Notifications]",
        "button[9.5,0.3;2,1;back;Back]",
        "dropdown[1.375,1.8;4,1;modes;Nade Fight,Classes,Classic;1;]",
        "dropdown[1.375,3.5;4,1;map;Any,".. table.concat(maps, ",") ..";1;]",
        "button[2.2,4.7;2,1;add;Add]",
        "field[7.2,3.5;4,1;remove_field;Remove Number:;1]",
        "button[8.3,4.7;2,1;remove;Remove]",
        "textarea[0.375,6.4;11.3,5;;All Notifications;".. table.concat(notifications, "") .."]",
    }
    local formspec = table.concat(formspec, "")

    return formspec
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    if formname ~= "ctf_info:formspec" then
        return
    end

    if fields.notifications then
        ctf_info.players[name] = nil
        minetest.show_formspec(name, "ctf_info:notifications", get_formspec(name))
        ctf_info.notification_formspec_players[name] = true
    end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "ctf_info:notifications" then
        return
    end

    local name = player:get_player_name()

    if fields.add then
        local notification = minetest.serialize({
            pos = 0,
            mode = fields.modes,
            map = fields.map,
            string = string.format("Mode: %s. Map: %s.\n", fields.modes, fields.map),
        })

        table.insert(ctf_info.notifications[name], notification)
    end

    if fields.remove then
        if tonumber(fields.remove_field) ~= nil then
            table.remove(ctf_info.notifications[name], fields.remove_field)
        end
    end
end)

minetest.register_globalstep(function(dtime)
    for name, notifications in pairs(ctf_info.notifications) do
        for i = 1, #notifications do
            local notification = ctf_info.notifications[name][i]
            local notification_table = minetest.deserialize(notification)
            notification_table.pos = i
            notification_table.string_with_pos = string.format("%d. %s", notification_table.pos, notification_table.string)
            ctf_info.notifications[name][i] = minetest.serialize(notification_table)

            local map = notification_table.map
            local mode = notification_table.mode

            if map == "Any" then
                if mode == ctf_info.modes[ctf_info.current_mode.name] then
                    minetest.chat_send_player(name, minetest.colorize("#85FF00", "Notification for: Mode: " .. mode .. " has gone off."))
                    minetest.sound_play({name = "relax-message-tone"}, {to_player = name}, true)
                    ctf_info.notifications[name][i] = nil
                    return
                end
            end

            if map == ctf_info.current_map.name and mode == ctf_info.modes[ctf_info.current_mode.name] then
                minetest.chat_send_player(name, minetest.colorize("#85FF00", "Notification for: Mode: " .. mode .. " and Map: " .. map .. " has gone off."))
                minetest.sound_play({name = "relax-message-tone"}, {to_player = name}, true)
                ctf_info.notifications[name][i] = nil
                return
            end
        end

        if ctf_info.notification_formspec_players[name] then
            minetest.show_formspec(name, "ctf_info:notifications", get_formspec(name))
        end
    end
end)