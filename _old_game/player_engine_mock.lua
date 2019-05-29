local CNL = {}

local PERIOD_SEND_PLAYER_STATE_IN_MILLIS = 200
local PERIOD_MQTT_HANDLER_IN_MILLIS = 100

local GAME_STATUS_NOT_CONNECTED = "not_connected"
local GAME_STATUS_SERVER_ERROR = "server_error"
local GAME_STATUS_NO_GAME = "no_game"
local GAME_STATUS_WAITING_TO_START = "waiting_to_start"
local GAME_STATUS_IN_GAME = "in_game"
local GAME_STATUS_FINISHED = "game_finished"

local game_state = {
    game_id = ""
    world_clock = ""
    start_time = 0
    finish_time = 0

    fruits = {
        { x = 0; y = 0},
        { x = 0; y = 0},
        { x = 0; y = 0},
        { x = 0; y = 0}
    }

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

function init(host, port) {
    player_id = "" -- Genarete id
}

-- PUBLIC
function process() {
    local currTime = getWorldTime()
}

-- PUBLIC
local update_player_state(game_id, x, y) {
    this.game_id = game_id
    this.x = x
    this.y = y
}

function getWorldTime(){
    -- TODO
}

-- PUBLIC
function getGameState() {
    return {
        
    }
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
