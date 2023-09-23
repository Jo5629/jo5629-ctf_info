local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath .. "/settings.lua")
dofile(modpath .. "/formspecs.lua")
dofile(modpath .. "/notifications.lua")

local http = minetest.request_http_api()
local url = "https://ctf.rubenwardy.com/api/game.json"

if not http then
    error("\n\n[CTF Info] Please add the mod to secure.http_mods for the mod to function!\n")
end

local function fetch_url(url)
    http.fetch({
        url = url,
    }, function(result)
        if result.succeeded then
            ctf_info.completed = true
            if result.code == 200 then
                local json = minetest.parse_json(result.data)

                if json == nil then
                    minetest.log("error", "Could not receive JSON file although request succeeded.")
                    return
                end

                ctf_info.current_map.name = json.current_map.name
                ctf_info.current_map.start_time = json.current_map.start_time

                ctf_info.current_mode.matches = json.current_mode.matches
                ctf_info.current_mode.matches_played = json.current_mode.matches_played
                ctf_info.current_mode.name = json.current_mode.name

                ctf_info.player_info.count = json.player_info.count
                ctf_info.player_info.players = json.player_info.players
            end
        else
            ctf_info.completed = false
        end
    end)
end

minetest.register_on_mods_loaded(function()
    fetch_url(url)
end)

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer >= 0.2 then
        if ctf_info.completed then
            fetch_url(url)
        end

        for player, v in pairs(ctf_info.main_formspec_players) do
            if ctf_info.main_formspec_players[player] then
                minetest.show_formspec(player, "ctf_info:formspec", ctf_info.get_main_formspec())
            end
        end

        for player, v in pairs(ctf_info.players_online_formspec) do
            if ctf_info.players_online_formspec[player] then
                minetest.show_formspec(player, "ctf_info:players_online", ctf_info.get_players_formspec())
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
                minetest.show_formspec(name, "ctf_info:formspec", ctf_info.get_main_formspec())
                ctf_info.main_formspec_players[name] = true
            else
                minetest.chat_send_player(name, minetest.colorize("#FF0000", "Could not load formspec. Check your WiFi connection."))
            end
        end)
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    
    if formname == "ctf_info:notifications" then
        if fields.back then
            minetest.show_formspec(name, "ctf_info:formspec", ctf_info.get_main_formspec())
            ctf_info.main_formspec_players[name] = true
        end
    
        if fields.quit or fields.back then
            ctf_info.notification_formspec_players[name] = nil
        end
    end

    if formname == "ctf_info:formspec" then
        ctf_info.main_formspec_players[name] = true


        if fields.exit or fields.notifications or fields.quit or fields.players then
            ctf_info.main_formspec_players[name] = nil
        end

        if fields.quit then
            minetest.close_formspec(name, formname)
        end

        if fields.notifications then
            minetest.show_formspec(name, "ctf_info:notifications", ctf_info.get_notifications_formspec(name))
            ctf_info.notification_formspec_players[name] = true
        end

        if fields.players then
            minetest.show_formspec(name, "ctf_info:players_online", ctf_info.get_players_formspec())
            ctf_info.players_online_formspec[name] = true
        end
    end

    if formname == "ctf_info:players_online" then

        if fields.back or fields.quit then
            ctf_info.players_online_formspec[name] = nil
        end

        if fields.back then
            ctf_info.main_formspec_players[name] = true
            minetest.show_formspec(name, "ctf_info:formspec", ctf_info.get_main_formspec())
        end
    end
end)
