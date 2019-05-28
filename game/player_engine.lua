local CNL = {}

CNL.MQTT = require("mqtt_library")

local TOPIC_GAME_STATE = "/game/state"
local TOPIC_PLAYER_STATE = "/player/state"
local PERIOD_SEND_PLAYER_STATE_IN_MILLIS = 200
local PERIOD_MQTT_HANDLER_IN_MILLIS = 100
local GRACE_TIME_GAME_STATE = 500

local GAME_STATUS_NOT_CONNECTED = "not_connected"
local GAME_STATUS_SERVER_ERROR = "server_error"
local GAME_STATUS_NO_GAME = "no_game"
local GAME_STATUS_WAITING_TO_START = "waiting_to_start"
local GAME_STATUS_IN_GAME = "in_game"
local GAME_STATUS_FINISHED = "game_finished"

local game_state = {
    game_id = nil,
    world_clock = nil,
    start_time = 0,
    finish_time = 0,

    fruits = {
        { x = 0; y = 0},
        { x = 0; y = 0},
        { x = 0; y = 0},
        { x = 0; y = 0}
    },

    players_states = {
        { player_id = ""; world_clock = 0; x = 0; y = 0; points = 0 },
        { player_id = ""; world_clock = 0; x = 0; y = 0; points = 0 },
        { player_id = ""; world_clock = 0; x = 0; y = 0; points = 0 }
    }
}




-- Player state
local player_id = 0
local game_id = -1
local x = -1;
local y = -1;

-- Last game state seen
local game_state

local connected = false
local next_send_player_state = 0
local next_mqtt_handler = 0

function init(host, port) {
    player_id = nil -- Genarete id
}

-- PUBLIC
function process() {
    local currTime = getWorldTime()

    if (!connected) {
        -- Log some things
        return
    }

    if (next_send_player_state < currTime) {
        send_player_state(currTime)
        next_send_player_state = currTime + PERIOD_SEND_PLAYER_STATE_IN_MILLIS
    }

    if (next_mqtt_handler < currTime) then
        CNL.mqtt_client:handler()
        next_mqtt_handler = currTime + PERIOD_MQTT_HANDLER_IN_MILLIS
    end    
}

-- PUBLIC
local update_player_state(game_id, x, y) {
    this.game_id = game_id
    this.x = x
    this.y = y
}

local send_player_state(time) {
    if (getGameStatus() == GAME_STATUS_NOT_CONNECTED) {
        return
    }

    local player_state = {player_id, game_id, time, x, y}
    local data = marshling(player_state)
    pub(TOPIC_PLAYER_STATE, data)
}

local pub(topic, message) {
    CNL.mqtt_client:publish(topic, message)
}

local marshling(message) {
    -- TODO
}

local unmarshling(message) {
    -- TODO
}

function callback(topic, message)
    if (topic != TOPIC_GAME_STATE) {
        return
    }

    last_game_state = unmarshling(message)
end

function getWorldTime(){
    -- TODO
}

-- PUBLIC
function getGameState() {
    return game_state
}

-- PUBLIC
function getGameStatus() {
    if (!connected || game_state == null) 
        return GAME_STATUS_NOT_CONNECTED

    if (game_state.world_clock + GRACE_TIME_GAME_STATE < getWorldTime()) {
        return GAME_STATUS_SERVER_ERROR
    }

    if (game_state.start_time < 0)
        return GAME_STATUS_NO_GAME
    
    if (game_state.start_time > getWorldTime()) {
        return GAME_STATUS_WAITING_TO_START
    }

    if (game_state.finish_time < 0) {
        return GAME_STATUS_IN_GAME
    }

    if (game_state.finish_time < 0) {
        return GAME_STATUS_FINISHED
    }
}
