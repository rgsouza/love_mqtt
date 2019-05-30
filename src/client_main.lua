
-- local binser = require("binser")
-- local mime = require("mime")
-- local mytable = {
--     test = "teste"
-- }

-- local ser = binser.serialize(1,2,3,4)
-- print(ser)

-- local status, msg = pcall(binser.deserialize, ser)
-- print(msg.test)


-- local mydata = binser.serialize({test = "teste"})

-- local t = binser.deserializeN(mydata, 1)
-- print(t)
-- for i,v in pairs(t) do
--     print(i,v)
-- end

local BOARD_Y_AXIS_SIZE = 13
local BOARD_X_AXIS_SIZE = 20

-- OBS: Keep this value high, other case this mock client would have to implement a lot of others logics...
local PERIOD_MOVEMENT_IN_MILLIS = 5000
local PERIOD_PRINT_WORLD_IN_MILLIS = 500

local socket = require "socket"
function get_wall_time()
    return socket.gettime()*1000
end

function print_world(game_status, game_state) 

    print("-------------")
    print("game_status: " .. game_status )
    if (game_status == "not_connected") or (game_status == "no_game")  then
        return
    end

    print("game_id: " .. game_state.game_id )
    print("world_clock: " .. game_state.world_clock )
    print("start_time: " .. game_state.start_time )
    print("finish_time: " .. game_state.finish_time )
    print("fruits: ")
    for i,v in ipairs(game_state.fruits) do 
        print("      : " .. v.x .. "," .. v.y)
    end
    print("players_states: ")
    for i,v in pairs(game_state.players_states) do 
        print("      : " .. i .. " : " .. v.x .. "," .. v.y)
    end
    print("-------------")
end

local player_engine = require("player_engine")
player_engine.init("localhost", 1883)

local x = 1
local y = 1

local next_move_time = 0
local next_print_time = 0

while true do
    local curr_wall_time = get_wall_time()

    player_engine.process()

    local game_state = player_engine.get_game_state()

    if (player_engine.get_game_status() == "in_game") then
        if next_move_time < curr_wall_time then
            x = x + 1
            y = y + 1

            x = ((x - 1) % BOARD_X_AXIS_SIZE) + 1
            y = ((y - 1) % BOARD_Y_AXIS_SIZE) + 1
            local game_id = game_state.game_id
            player_engine.update_player_state(game_id, x, y)
            next_move_time = curr_wall_time + PERIOD_MOVEMENT_IN_MILLIS
        end
    end

    if next_print_time < curr_wall_time then
            print_world(player_engine.get_game_status(), player_engine.get_game_state())
            next_print_time = curr_wall_time + PERIOD_PRINT_WORLD_IN_MILLIS
    end

end
