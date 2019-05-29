local TOPIC_GAME_STATE = "/game/state"
local TOPIC_PLAYER_STATE = "/player/state"
local PERIOD_SEND_PLAYER_STATE_IN_MILLIS = 2000
local PERIOD_MQTT_HANDLER_IN_MILLIS = 1000
local GRACE_TIME_GAME_STATE = 500

local GAME_STATUS_NOT_CONNECTED = "not_connected"
local GAME_STATUS_SERVER_ERROR = "server_error"
local GAME_STATUS_NO_GAME = "no_game"
local GAME_STATUS_WAITING_TO_START = "waiting_to_start"
local GAME_STATUS_IN_GAME = "in_game"
local GAME_STATUS_FINISHED = "game_finished"

local MOCK_ENABLED = true

local MQTT = require("mqtt_library")
local randon = require("random")
local socket = require "socket"

local player_id = 1--"player_" .. randon.randomNum(10)
local mqtt_client = null

local connected = false
local next_send_player_state = 0
local next_mqtt_handler = 0

local game_state = null
local player_state = {
    player_id = player_id,
    game_id = -1,
    x = -1,
    y = -1,
}

function init(host, port)
    if MOCK_ENABLED then
        connected = true
        return
    end

    mqtt_client = MQTT.client.create(host, port)
    -- ToDo: Create a validation if is any erros occours
    mqtt_client:connect(player_id)
    connected = true
end

function process()
    local curr_wall_time = get_wall_time()
    if not connected then
        -- ToDo: Log some erros here
        return
    end

    if next_send_player_state < curr_wall_time then
        send_player_state(curr_wall_time)
        next_send_player_state = curr_wall_time + PERIOD_SEND_PLAYER_STATE_IN_MILLIS
    end

    if next_mqtt_handler < curr_wall_time then
        if MOCK_ENABLED then
            update_mock_game_state(curr_wall_time)
            return
        end

        -- ToDo: Create a validation if is any erros occours
        mqtt_client:handler()
        next_mqtt_handler = curr_wall_time + PERIOD_MQTT_HANDLER_IN_MILLIS
    end    
end

function send_player_state(curr_wall_time) 
    if get_game_status() == GAME_STATUS_NOT_CONNECTED then
        return
    end

    -- local player_state = {player_id, game_id, time, x, y}
    -- local data = marshling(player_state)
    -- pub(TOPIC_PLAYER_STATE, data)
end

-- local pub(topic, message) {
--     CNL.mqtt_client:publish(topic, message)
-- }

-- local marshling(message) {
--     -- TODO
-- }

-- local unmarshling(message) {
--     -- TODO
-- }

-- function callback(topic, message)
--     if (topic != TOPIC_GAME_STATE) {
--         return
--     }

--     last_game_state = unmarshling(message)
-- end

function get_wall_time()
    return socket.gettime()*1000
end

function update_player_state(game_id, x, y, color)
	print("DEBUG: update_player_states") 
    player_state.game_id = game_id
    player_state.x = x
    player_state.y = y
    player_state.color = color
end

function get_game_state()
	--print(#game_state)
	--print(game_state.world_clock)
	--print(game_state.players_states[1].x)
    return game_state
end

function get_player_id()
	return 1
end

function get_game_status() 
    if not connected or game_state == null then
        return GAME_STATUS_NOT_CONNECTED
    end

    if game_state.world_clock + GRACE_TIME_GAME_STATE < get_wall_time() then 
        return GAME_STATUS_SERVER_ERROR
    end

    if game_state.start_time < 0 then
        return GAME_STATUS_NO_GAME
    end

    if game_state.start_time > get_wall_time() then
        return GAME_STATUS_WAITING_TO_START
    end

    if game_state.finish_time < 0 then
        return GAME_STATUS_IN_GAME
    end

    if game_state.finish_time < 0 then
        return GAME_STATUS_FINISHED
    end

    return ""
end

function update_mock_game_state(curr_wall_time) 
    if game_state == null then
        game_state = {
                game_id = player_state.game_id,
                world_clock = curr_wall_time,
                start_time = curr_wall_time,
                finish_time = -1,
                fruits = {
                    {
                        x = 10,
                        y = 11
                    },
                    {
                        x = 5,
                        y = 6
                    }
                },
                players_states = {}
        }
    end
    game_state.world_clock = curr_wall_time
    game_state.players_states[player_state.player_id] = player_state

end

-- ------------------------------------------------------------------------- --
-- Define PlayerEngine "module"
-- ~~~~~~~~~~~~~~~~~~~~~~~

-- ToDo: Discover when uses a local function
local PlayerEngine = {}

PlayerEngine.init = init
PlayerEngine.process = process
PlayerEngine.update_player_state = update_player_state
PlayerEngine.get_game_state = get_game_state
PlayerEngine.get_game_status = get_game_status
PlayerEngine.get_player_id = get_player_id

return(PlayerEngine)
