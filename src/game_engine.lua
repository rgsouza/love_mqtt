local TOPIC_GAME_STATE = "/game/state"
local TOPIC_PLAYER_STATE = "/player/state"
local PERIOD_PROCESS_BOARD_IN_MILLIS = 200
local PERIOD_SEND_GAME_STATE_IN_MILLIS = 200
local PERIOD_MQTT_HANDLER_IN_MILLIS = 100
local GRACE_TIME_PLAYER_STATE_IN_MILLIS = 500

local GAME_STATUS_NOT_CONNECTED = "not_connected"
local GAME_STATUS_SERVER_ERROR = "server_error"
local GAME_STATUS_NO_GAME = "no_game"
local GAME_STATUS_WAITING_TO_START = "waiting_to_start"
local GAME_STATUS_WAITING_IN_GAME = "in_game"
local GAME_STATUS_FINISHED = "game_finished"

local BOARD_Y_AXIS_SIZE = 13
local BOARD_X_AXIS_SIZE = 20

local BOARD_DATA_FRUIT  = "F"
local BOARD_DATA_PLAYER = "P"
local BOARD_DATA_EMPTY  = "E"
local PROB_GEN_FRUIT = 0.008

local MOCK_ENABLED = false

local MQTT = require("mqtt_library")
local random = require("random")
local socket = require "socket"
local binser = require("binser")
local mime = require("mime")

local gamemaster_id = "gamemaster_" .. random.randomNum(10)
local mqtt_client = nil

local connected = false
local next_purge_old_clients = 0
local next_send_game_state = 0
local next_mqtt_handler = 0

-- Current game attributes
local game_id = -1
local board = {}
local start_time = -1
local finish_time = -1
local player_state_by_player_id = {}

function init(host, port)
    mqtt_client = MQTT.client.create(host, port, callback)
    -- ToDo: Create a validation if is any erros occours
    mqtt_client:connect(gamemaster_id)
    mqtt_client:subscribe({TOPIC_PLAYER_STATE})
    connected = true
    init_game()
end

function init_game() 
    game_id = 1
    -- game_id = random.randomNum(10)
    for x=1,BOARD_X_AXIS_SIZE do
        board[x] = {}
        for y=1,BOARD_Y_AXIS_SIZE do
            if random.rollDice(PROB_GEN_FRUIT) then
                board[x][y] = BOARD_DATA_FRUIT
            else 
                board[x][y] = BOARD_DATA_EMPTY
            end
        end
    end
    start_time = get_wall_time()
end

function process()
    local curr_wall_time = get_wall_time()

    if not connected then
        -- ToDo: Log some erros here
        return
    end

    -- if next_purge_old_clients < curr_wall_time then
    --     send_game_state(curr_wall_time)
    --     next_send_game_state = curr_wall_time + PERIOD_SEND_GAME_STATE_IN_MILLIS
    -- end

    if next_send_game_state < curr_wall_time then
        send_game_state(curr_wall_time)
        next_send_game_state = curr_wall_time + PERIOD_SEND_GAME_STATE_IN_MILLIS
    end

    if next_mqtt_handler < curr_wall_time then
        -- ToDo: Create a validation if is any erros occours
        mqtt_client:handler()
        next_mqtt_handler = curr_wall_time + PERIOD_MQTT_HANDLER_IN_MILLIS
    end 
end

function send_game_state(curr_wall_time)
    local fruits = {}
    for x=1,BOARD_X_AXIS_SIZE do
        for y=1,BOARD_Y_AXIS_SIZE do
            local board_data = board[x][y]
            if board_data == BOARD_DATA_FRUIT then
                table.insert(fruits, {x = x, y = y})
            end
        end
    end

    local game_state = {
        game_id = game_id,
        world_clock = curr_wall_time,
        start_time = start_time,
        finish_time = finish_time,
        fruits = fruits,
        players_states = player_state_by_player_id
    }

    local data = marshling(game_state)
    pub(TOPIC_GAME_STATE, data)
end

function pub(topic, message) 
    -- ToDo: Create a validation if is any erros occours
    mqtt_client:publish(topic, message)
end

function marshling(message)
    -- data = mime.b64(binser.serialize(myTable))
    data = binser.serialize(message)
    return data
end

function unmarshling(data) 
    return binser.deserializeN(data,1)
end

function callback(topic, message)
    if topic ~= TOPIC_PLAYER_STATE then
        return
    end

    local player_state = unmarshling(message)
    logd("[RCV] player_id: " .. player_state.player_id .. " @." .. player_state.world_clock)
    process_incomming_player_state(player_state)
end

function process_incomming_player_state(player_state)
    local curr_wall_time = get_wall_time()
    -- Validates currenct game
    if player_state.game_id ~= game_id then
        logi("[" .. player_state.player_id .. "] Ignoring due to wrong game_id:" .. player_state.game_id .. " , expected: " .. game_id)
        return
    end

    -- Validates old clients
    if (player_state.world_clock + GRACE_TIME_PLAYER_STATE_IN_MILLIS < curr_wall_time) then
        local delta = curr_wall_time - player_state.world_clock
        logi("[" .. player_state.player_id .. "] Ignoring cause this message is too old: " .. delta .. "ms behind.")
        return
    end

    -- Validates position [1,n]
    if player_state.x <= 0 or player_state.x > BOARD_X_AXIS_SIZE or
        player_state.y <= 0 or player_state.y > BOARD_Y_AXIS_SIZE then
            logi("[" .. player_state.player_id .. "] Ignoring due to invalid position: (" .. player_state.x .. "," .. player_state.y .. ")")
            return
    end

    local board_data = board[player_state.x][player_state.y]

    if (board_data == BOARD_DATA_PLAYER) then
        logi("[" .. player_state.player_id .. "] Ignoring due to position overlap.")
        return
    end

    -- -- New player
    local old_player_state = player_state_by_player_id[player_state.player_id]
    local points = 0
    if (old_player_state ~= nil) then
        points = old_player_state.points
    end
    
    --  Consumes a fruit
    if (board_data == BOARD_DATA_FRUIT) then
        logi("[" .. player_state.player_id .. "] Consuming fruits.")
        points = points + 1
    end
    
    -- Updates board position
    if (old_player_state ~= nil) then
        board[old_player_state.x][old_player_state.y] = BOARD_DATA_EMPTY
    end
    board[player_state.x][player_state.y] = BOARD_DATA_PLAYER

    -- Updates points
    player_state.points = points

    -- Updates server player_state
    player_state_by_player_id[player_state.player_id] = player_state
end

function get_wall_time()
    return socket.gettime()*1000
end

function logi(msg)
    print(msg)
end

function logd(msg)
    print(msg)
end 


-- ------------------------------------------------------------------------- --
-- Define PlayerEnGameEnginegine "module"
-- ~~~~~~~~~~~~~~~~~~~~~~~

-- ToDo: Discover when uses a local function
local GameEngine = {}

GameEngine.init = init
GameEngine.process = process
GameEngine.process_incomming_player_state = process_incomming_player_state

return(GameEngine)
