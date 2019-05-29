-- Confirmar que x,y sao passos e multiplicar por 32
--playerEngine = require("player_engine")
require("button")
local playerEngine = require("player_engine")
local socket = require("socket")

local elements = {}
local nelements = 5
local startXposition = 1
local startYposition = 1
local dimX, dimY
local screenW
local screenH
local status --DELETAR: para teste
local nextMoveTime = 0
local gameID = 1
local myID

local GAME_STATUS_NOT_CONNECTED = "not_connected"
local GAME_STATUS_SERVER_ERROR = "server_error"
local GAME_STATUS_NO_GAME = "no_game"
local GAME_STATUS_WAITING_TO_START = "waiting_to_start"
local GAME_STATUS_IN_GAME = "in_game"
local GAME_STATUS_FINISHED = "game_finished"

local PERIOD_MOVEMENT_IN_MILLIS = 1000

local waitingToUpdate = false

function getWallTime()
    return socket.gettime()*1000
end

function createElements(map)
	math.randomseed(os.time())
        for i=1, nelements do

                local myid = i
                local myXc = math.random(2, #map[1]-2)*32 + 16
                local myYc = math.random(2, #map-2)*32 + 16
                table.insert(elements, { id = i, xc = myXc, yc = myYc, r = 10})
        end
end


function createPlayer(mycolor)

	math.randomseed(os.time())

	local x0 = math.random(1, dimX-1)
	local y0 = math.random(1, dimY-1)
	local r = math.random(0, 255)
	local g = math.random(0, 255)
	local b = math.random(0, 255)

	return {x = x0, y = y0, color = {r,g,b}}

end


function newGameButton()
	local text = "New Game"
	local offset = buttonFont:getWidth(text)/2

        button:new(function()
                    status = GAME_STATUS_NO_GAME
                    end, text, screenW/2 - offset, 3*screenH/4 , 10, 10, {0,0,0}, buttonFont, {255,255,0}
          )

end

function love.load()

	defaultFont = love.graphics.newFont(12)
	Font1 = love.graphics.newFont("fonts/ka1.ttf", 40)
	gameOverFont = love.graphics.newFont("fonts/ka1.ttf", 60)
	buttonFont = love.graphics.newFont("fonts/8bit.ttf", 20)

	screenW, screenH = love.graphics.getDimensions()
	status = GAME_STATUS_FINISHED


	map = {
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
	}


	dimY = #map
	dimX = #map[1]


	createElements(map)
	
	
	-- Insere 2 players para teste
	player = createPlayer()
	playerEngine.update_player_state(1, player.x, player.y, player.color)


	print("DEBUG: load")	
	print(player.x, player.y, player.color)
	newGameButton()
	playerEngine.init("localhost", 1883)
	myID = playerEngine.get_player_id()
end

function borderCollision(x, y)
	local x = players[myID].x + x
	local y = players[myID].y + y

	return ( x<1 or x>dimX) or (y<1 or y>dimY )
end

-- Adicionar colisao com os outros jogadores
function testCollision(x, y)

	return borderCollision(x, y)
end


function love.keypressed(key)

	local state = playerEngine.get_game_state()
	players = state.players_states
	if key == "up" then
		if not testCollision(0, -1) then

			player.x = players[myID].x
			player.y = players[myID].y - 1
			waitingToupdate = true

			--players[move.index].act_y = players[move.index].act_y - 32
		end
	elseif key == "down" then
		if not testCollision(0, 1) then
			print("DEBUG KEY: DOWN")
			player.x = players[myID].x
                        player.y = players[myID].y + 1
                        waitingToupdate = true

			-- players[move.index].act_y = players[move.index].act_y + 32
		end
	elseif key == "left" then
		if not testCollision(-1, 0) then
			
			player.x = players[myID].x - 1
                        player.y = players[myID].y 
                        waitingToUpdate = true
			--players[move.index].act_x = players[move.index].act_x - 32
		end
	elseif key == "right" then
		if not testCollision(1, 0) then
		
			player.x = players[myID].x + 1
                        player.y = players[myID].y 
                        waitingToupdate = true
			--players[move.index].act_x = players[move.index].act_x + 32
		end
	end
end

function getWinner()
	return 1
end


function love.update(dt)

	local currWallTime = getWallTime()

	updateButtons()
	playerEngine.process()

	
	if nextMoveTime < currWallTime  then
		print("DEGUB UPDATE:", player.x, player.y)
        	playerEngine.update_player_state(gameID, player.x, player.y, player.color)
        	nextMoveTime = currWallTime + PERIOD_MOVEMENT_IN_MILLIS
		waitingToUpdate = false
    	end



end


function drawGrid()

	love.graphics.setColor(255, 255, 255)
        for j=1, dimY do
                for i=1, dimX do
                        love.graphics.rectangle("line", i * 32, j * 32, 32, 32)
                end
        end

end

function drawElements(elements)

	local radius = 10
	love.graphics.setColor(255, 255, 0)
	for i=1, #elements do
    		love.graphics.circle("fill", elements[i].x*32 + 16, elements[i].y*32 + 16, radius)
	end
end

function drawPlayers(players)

--	print("debug: draw players")
	for i=1, #players do 
		--print("debug: draw players")
		love.graphics.setColor(players[i].color)
        	love.graphics.rectangle("fill", players[i].x*32, players[i].y*32, 32, 32)
	end
end

function drawGameOver()

	love.graphics.setColor(255, 255, 0)
	love.graphics.setFont(gameOverFont)
	love.graphics.printf("GAME_OVER", 0, screenH/8, screenW, "center")
	love.graphics.setFont(Font1)
	love.graphics.printf("WINNER:", 0, screenH/4 + screenH/8 , screenW, "center")
	local text = "PLAYER  " .. getWinner()
	love.graphics.printf(text, 0, screenH/2, screenW, "center")

	drawButtons()
end

function drawLoadingGame()

	love.graphics.setColor(255, 255, 255)
	local text = "Loading game ..."
	love.graphics.setFont(Font1)
	love.graphics.printf(text, 0, screenH/2, screenW, "center")
end

function drawErrorMsg(text)
	
	love.graphics.setColor(255, 0, 0)
	love.graphics.setFont(defaultFont)
	love.graphics.printf(text, 0, screenH/2, screenW, "center")
end

function love.draw()

	-- love.timer.sleep(50)

	local status = playerEngine.get_game_status()

	if(status == GAME_STATUS_FINISHED) then
		drawGameOver()

	elseif(status == GAME_STATUS_IN_GAME or status == GAME_STATUS_WAITING_TO_START) then
		local state = playerEngine.get_game_state()
		drawGrid()
		drawElements(state.fruits)
		--print(#state.players_states)
		drawPlayers(state.players_states)

	elseif(status == GAME_STATUS_NOT_CONNECTED) then
		drawErrorMsg("ERROR: GAME NOT CONNECTED")

	elseif(status == GAME_STATUS_SERVER_ERROR) then
		drawErrorMsg("ERROR: SERVER ERROR")
	
	elseif(status == GAME_STATUS_NO_GAME) then
		drawLoadingGame()
	end
end


