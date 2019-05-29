local TOPIC_GAME_STATE = "/game/state"
local TOPIC_PLAYER_STATE = "/player/state"
local PERIOD_PURGE_OLD_PLAYERS_IN_MILLIS = 10000
local PERIOD_SEND_GAME_STATE_IN_MILLIS = 200
local PERIOD_MQTT_HANDLER_IN_MILLIS = 200
local GRACE_TIME_PLAYER_STATE_IN_MILLIS = 5000
local DELAY_TIME_NEW_GAME_IN_MILLIS = 5000
local DELAY_TIME_RECREATE_GAME_IN_MILLIS = 5000

local GAME_STATUS_NOT_CONNECTED = "not_connected"
local GAME_STATUS_SERVER_ERROR = "server_error"
local GAME_STATUS_NO_GAME = "no_game"
local GAME_STATUS_WAITING_TO_START = "waiting_to_start"
local GAME_STATUS_IN_GAME = "in_game"
local GAME_STATUS_FINISHED = "game_finished"

local BOARD_Y_AXIS_SIZE = 13
local BOARD_X_AXIS_SIZE = 20

local BOARD_DATA_FRUIT  = "F"
local BOARD_DATA_PLAYER = "P"
local BOARD_DATA_EMPTY  = "E"
local PROB_GEN_FRUIT = 0.2

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
    clear_game()
end

function clear_game() 
    game_id = -1
    board = {}
    start_time = -1
    finish_time = -1
    player_state_by_player_id = {}
end


local fruit_pos = 5
function create_new_game(delay) 
    clear_game()
    game_id = random.randomNum(10)
    for x=1,BOARD_X_AXIS_SIZE do
        board[x] = {}
        for y=1,BOARD_Y_AXIS_SIZE do
            if random.rollDice(PROB_GEN_FRUIT) then
            -- if x == fruit_pos and y == fruit_pos then
                board[x][y] = BOARD_DATA_FRUIT
            else 
                board[x][y] = BOARD_DATA_EMPTY
            end
        end
    end
    start_time = get_wall_time() + delay
end

function process()
    local curr_wall_time = get_wall_time()

    if not connected then
        -- ToDo: Log some erros here
        return
    end

    if next_purge_old_clients < curr_wall_time then
        purge_old_clients(curr_wall_time)
        next_purge_old_clients = curr_wall_time + PERIOD_PURGE_OLD_PLAYERS_IN_MILLIS
    end

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

function purge_old_clients(curr_wall_time)
    -- Since we wants to filter a table, lets recreate a new one without the filtered elements
    local cleared_list = {}

    for k,v in pairs(player_state_by_player_id) do
        -- Is good time
        if v.world_clock + GRACE_TIME_PLAYER_STATE_IN_MILLIS > curr_wall_time then
            cleared_list[k] = v
        else
            -- Clear the board
            board[v.x][v.y] = BOARD_DATA_EMPTY
            logi("[" .. v.player_id .. "] Was purged.")
        end
    end

    -- Updates the table with a cleared list
    player_state_by_player_id = cleared_list
end

function send_game_state(curr_wall_time)

    -- The game has finisehd and it`s time to recreate it
    if (isGameFinished()) then
        if finish_time + DELAY_TIME_RECREATE_GAME_IN_MILLIS < curr_wall_time then
            clear_game()
        end
    end

    -- There`s no game now. Let`s create it.
    if isNoGame() then
        create_new_game(DELAY_TIME_NEW_GAME_IN_MILLIS)
    end

    -- Calculate the #fruits on board
    local fruits = {}
    for x=1,BOARD_X_AXIS_SIZE do
        for y=1,BOARD_Y_AXIS_SIZE do
            local board_data = board[x][y]
            if board_data == BOARD_DATA_FRUIT then
                table.insert(fruits, {x = x, y = y})
            end
        end
    end

    -- There`s no fruits, lets finish the game
    if (isInGame() and #fruits == 0) then
        finish_time = curr_wall_time
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

    local old_player_state = player_state_by_player_id[player_state.player_id]
    local is_new_player = (old_player_state == nil)
    local points = 0

    if not is_new_player then
        points = old_player_state.points
    end

    local board_data = board[player_state.x][player_state.y]

    if (board_data == BOARD_DATA_PLAYER) then

        -- Edge case!!!!
        if (is_new_player) then
            logi("ATTENTION!! [" .. player_state.player_id .. "] IS NEW AND IS IN THE SAME POSITION AS OTHER PLAYER!.")
            return
        end

        if (old_player_state.x == player_state.x) and (old_player_state.y == player_state.y) then
            -- I`m just stopped at same position, nothing to do here.. lets move on
        else
            -- I`m not at same position, so I`m trying to overlap position from another player.. lets stop here
            logi("[" .. player_state.player_id .. "] Ignoring due to position overlap.")
            return
        end
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

function isNotConnected()
    return not connected
end

function isNoGame()
    return start_time < 0
end

function isWaitingToStart(curr_wall_time)
    return start_time > curr_wall_time
end

function isInGame()
    return finish_time < 0
end

function isGameFinished()
    return finish_time > 0
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