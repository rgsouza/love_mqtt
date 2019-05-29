local socket = require "socket"
function get_wall_time()
    return socket.gettime()*1000
end

local PERIOD_MOCK_PLAYER_STATE_IN_MILLIS = 1000
local next_mock_player_state_time = 0

local game_engine = require("localhost")
game_engine.init("mosquitto", 1883)
while true do
    local curr_wall_time = get_wall_time()
    game_engine.process()

    -- if next_mock_player_state_time < curr_wall_time then
    --     game_engine.process_incomming_player_state({
    --         player_id = 1,
    --         game_id = 1,
    --         x = 10,
    --         y = 5,
    --         world_clock = curr_wall_time
    --     })
    --     next_mock_player_state_time = curr_wall_time + PERIOD_MOCK_PLAYER_STATE_IN_MILLIS
    -- end
end
