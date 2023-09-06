--> Tables used for the mod.
ctf_info = {}

ctf_info.current_map = {
    name = "",
    start_time = 0,
}

ctf_info.current_mode = {
    matches = 0,
    matches_played = 0,
    name = "",
}

ctf_info.player_info = {
    count = 0
}

ctf_info.modes = {
    ["nade_fight"] = "Nade Fight",
    ["classes"] = "Classes",
    ["classic"] = "Classic",
}

ctf_info.completed = false
ctf_info.players = {}

--> Code.
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/maps.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/notifications.lua")

local http = minetest.request_http_api()
local url = "https://ctf.rubenwardy.com/api/game.json"

if not http then
    error("\n\n[CTF Info] Please add the mod to secure.http_mods for the mod to function!\n")
end

minetest.register_on_leaveplayer(function(player)
    ctf_info.players[player:get_player_name()] = nil
end)

local function get_time_elapsed(start_time)
    local time_elapsed = os.time(os.date("!*t")) - start_time

    local date = os.date("*t", time_elapsed)

    date.hour = tostring(date.hour)
    date.min = tostring(date.min)
    date.sec = tostring(date.sec)

    if tonumber(date.hour) < 10 then
        date.hour = "0" .. tostring(date.hour)
    end

    if tonumber(date.min) < 10 then
        date.min = "0" .. tostring(date.min)
    end

    if tonumber(date.sec) < 10 then
        date.sec = "0" .. tostring(date.sec)
    end

    return date
end

local function fetch_url(url)
    http.fetch({
        url = url,
    }, function(result)
        if result.succeeded then
            ctf_info.completed = true
            if result.code == 200 then
                local json = minetest.parse_json(result.data)

                if json == nil then return end
                    
                ctf_info.current_map.name = json.current_map.name
                ctf_info.current_map.start_time = json.current_map.start_time

                ctf_info.current_mode.matches = json.current_mode.matches
                ctf_info.current_mode.matches_played = json.current_mode.matches_played
                ctf_info.current_mode.name = json.current_mode.name

                ctf_info.player_info.count = json.player_info.count
            end
        else
            ctf_info.completed = false
        end
    end)
end

local function get_formspec()
    local current_mode = string.format("Current Mode: %s. Match %d of %d.", ctf_info.modes[ctf_info.current_mode.name], ctf_info.current_mode.matches_played + 1, ctf_info.current_mode.matches)
    local current_map = string.format("Current Map: %s", ctf_info.current_map.name)
    local players_online = string.format("Players Online: %d", ctf_info.player_info.count)
    local date = get_time_elapsed(ctf_info.current_map.start_time)
    local time_elapsed = string.format("Time Elapsed: %s:%s:%s", date.hour, date.min, date.sec)
        
    local formspec = {
        "formspec_version[4]",
        "size[8,3.6]",
        "label[0.375,0.5;CTF Info by Jo5629]",
        "label[0.375,1.5;".. current_mode .."]",
        "label[0.375,2;".. current_map .."]",
        "label[0.375,2.5;" .. time_elapsed .."]",
        "label[0.375,3;".. players_online .."]",
        "button_exit[6.125,0.2;1.5,1;exit;Exit]",
        "button[4,0.2;2,1;notifications;Notifications]",
    }
    local formspec = table.concat(formspec, "")

    return formspec
end

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer >= 0.2 then
        fetch_url(url)
        for k, v in pairs(ctf_info.players) do
            if ctf_info.players[k] then
                minetest.show_formspec(k, "ctf_info:formspec", get_formspec())
            end
        end

    end
end)

minetest.register_chatcommand("ctf_info", {
    description = "CTF Info.",
    func = function(name, param)
        fetch_url(url)
        minetest.after(1, function()
            if ctf_info.completed then
                minetest.show_formspec(name, "ctf_info:formspec", get_formspec())
                ctf_info.players[name] = true
            else
                minetest.chat_send_player(name, minetest.colorize("#FF0000", "Could not load formspec. Check your WiFi connection."))
            end
        end)
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    if formname ~= "ctf_info:formspec" then
        return
    end

    if fields.exit or fields.notifications then
        ctf_info.players[name] = nil
    end

    if fields.quit then
        ctf_info.players[name] = nil
        minetest.close_formspec(name, formname)
    end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    if formname ~= "ctf_info:notifications" then
        return
    end

    if fields.back then
        minetest.show_formspec(name, "ctf_info:formspec", get_formspec())
        ctf_info.players[name] = true
        ctf_info.notification_formspec_players[name] = nil
    end

    if fields.quit then
        ctf_info.notification_formspec_players[name] = nil
    end
end)
