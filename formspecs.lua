--> All of the formspec here for code organization.
function ctf_info.get_main_formspec()
    --> From https://github.com/MT-CTF/capturetheflag/blob/8b604813f453dcd16782fed0dd1b44d7749b9ae8/mods/ctf/ctf_modebase/summary.lua#L22
    local function get_time_elapsed(start_time)
	    if not start_time then
		    return "-"
	    end

	    local time = os.time() - start_time
	    return string.format("Time Elapsed: %02d:%02d:%02d",
		    math.floor(time / 3600),        -- hours
		    math.floor((time % 3600) / 60), -- minutes
		    math.floor(time % 60))          -- seconds
    end

    local current_mode = string.format("Current Mode: %s. Match %d of %d.", ctf_info.modes[ctf_info.current_mode.name], ctf_info.current_mode.matches_played + 1, ctf_info.current_mode.matches)
    local current_map = string.format("Current Map: %s", ctf_info.current_map.name)
    local players_online = string.format("Players Online: %d", ctf_info.player_info.count)
    local time_elapsed = get_time_elapsed(ctf_info.current_map.start_time)
        
    local formspec = {
        "formspec_version[4]",
        "size[9.4,4.6]",
        "label[0.375,0.5;CTF Info by Jo5629]",
        "label[0.375,1.5;".. current_mode .."]",
        "label[0.375,2;".. current_map .."]",
        "label[0.375,2.5;" .. time_elapsed .."]",
        "label[0.375,3;".. players_online .."]",
        "button_exit[7.7,0.2;1.5,1;exit;Exit]",
        "button[4,0.2;2,1;notifications;Notifications]",
        "button[6.125,0.2;1.5,1;players;Players]",
    }
    local formspec = table.concat(formspec, "")

    return formspec
end

function ctf_info.get_notifications_formspec(name)
    local maps = {}

    for k, map in pairs(ctf_info.maps) do
        table.insert(maps, map)
    end

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

function ctf_info.get_players_formspec()
    local players_online = {}

    local players = ctf_info.player_info.players

    table.sort(players, function (a, b)
        return string.upper(a) < string.upper(b)
    end)

    for i = 1, #players do
        table.insert(players_online, string.format("%d. %s\n", i, players[i]))
    end

    local formspec = {
        "formspec_version[4]",
        "size[12,12]",
        "label[0.375,0.8;Players Online]",
        "button[9.5,0.3;2,1;back;Back]",
        "textarea[0.375,1.8;11.1,10;;Number of Players Online: ".. tostring(ctf_info.player_info.count) .. ";".. table.concat(players_online, "") .."]",
    }

    local formspec = table.concat(formspec, "")

    return formspec
end