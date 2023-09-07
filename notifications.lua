ctf_info.notifications = {}
ctf_info.notification_formspec_players = {}

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
            minetest.show_formspec(name, "ctf_info:notifications", ctf_info.get_notifications_formspec(name))
        end
    end
end)