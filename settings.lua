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
    count = 0,
    players = {},
}

ctf_info.modes = {
    ["nade_fight"] = "Nade Fight",
    ["classes"] = "Classes",
    ["classic"] = "Classic",
}

ctf_info.completed = false

ctf_info.maps = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/maps.lua")

--> Tables used for the other files.
ctf_info.players_online_formspec = {}

ctf_info.main_formspec_players = {}

ctf_info.notifications = {}
ctf_info.notification_formspec_players = {}

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()

    ctf_info.main_formspec_players[name] = nil
    ctf_info.notifications[name] = nil
    ctf_info.players_online_formspec[name] = nil
end)

minetest.register_on_joinplayer(function(player)
    ctf_info.notifications[player:get_player_name()] = {}
end)