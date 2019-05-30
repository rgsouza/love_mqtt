-- Confirmar que x,y sao passos e multiplicar por 32
--playerEngine = require("player_engine")
require("button")
local playerEngine = require("player_engine")
local socket = require("socket")

local elements = {}
local nelements = 5
local startXposition = 1
local yOffset
local xOffset 
local dimX, dimY
local screenW
local screenH
--local status --DELETAR: para teste
local nextMoveTime = 0
local gameID
local myID
local player


local GAME_STATUS_NOT_CONNECTED = "not_connected"
local GAME_STATUS_SERVER_ERROR = "server_error"
local GAME_STATUS_NO_GAME = "no_game"
local GAME_STATUS_WAITING_TO_START = "waiting_to_start"
local GAME_STATUS_IN_GAME = "in_game"
local GAME_STATUS_FINISHED = "game_finished"

local PERIOD_MOVEMENT_IN_MILLIS = 1000
local START_DELAY_IN_MILLIS = 1000

local playerCreated = false

function getWallTime()
    return socket.gettime()*1000
end



function createPlayer(mycolor)

	math.randomseed(os.time())

	local x0 = math.random(1, dimX-1)
	local y0 = math.random(1, dimY-1)
	local r = math.random()
	local g = math.random()
	local b = math.random()

	return {x = x0, y = y0, color = {r = r,g = g ,b = b}}

end


function newGameButton()
	local text = "New Game"
	local offset = buttonFont:getWidth(text)/2

        button:new(function()
                    --status = GAME_STATUS_NO_GAME
                    end, text, screenW/2 - offset, 3*screenH/4 , 10, 10, {0,0,0}, buttonFont, {255,255,0}
          )

end

function love.load()

	defaultFont = love.graphics.newFont(12)
	defaultSize = love.graphics.newFont(20)
	Font1 = love.graphics.newFont("fonts/ka1.ttf", 50)
	Font2 = love.graphics.newFont("fonts/ka1.ttf", 25)
	gameOverFont = love.graphics.newFont("fonts/ka1.ttf", 60)
	buttonFont = love.graphics.newFont("fonts/8bit.ttf", 20)
	bigFont = love.graphics.newFont("fonts/8bit.ttf", 50)

	screenW, screenH = love.graphics.getDimensions()
---	status = GAME_STATUS_FINISHED


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

	yOffset = 2*32
	xOffset = screenW/2 - (dimX + 2)*32/2

	print(dimX)
	print(dimY)
	


	player = createPlayer()

	
	newGameButton()
	playerEngine.init("localhost", 1883)
	myID = playerEngine.get_player_id()
	print("MEU ID", myID)
	
end

function borderCollision(x, y, players)

--	local state = playerEngine.get_game_state()
--        players = state.players_states

	local x = players[myID].x + x
	local y = players[myID].y + y

	return ( x<1 or x>dimX) or (y<1 or y>dimY )
end

-- Adicionar colisao com os outros jogadores
function testCollision(x, y, players)

	return borderCollision(x, y, players)
end


function love.keypressed(key)

	local state = playerEngine.get_game_state()
	local players = state.players_states

	if key == "up" then
		player.x = players[myID].x
		player.y = players[myID].y - 1


	elseif key == "down" then
		print("DEBUG KEY: DOWN")
		player.x = players[myID].x
		player.y = players[myID].y + 1

	elseif key == "left" then
		player.x = players[myID].x - 1
		player.y = players[myID].y 

	elseif key == "right" then
		player.x = players[myID].x + 1
		player.y = players[myID].y 

	end
end

function getWinner(players)

	local state = playerEngine.get_game_state()
	local players = state.players_states

	local winner 
	local points = 0

	for k, v in pairs(players) do
		print(v.points)
		if v.points >= points then
			points = v.points
			winner = v.player_id
		end
        end

	return winner, points
end


function love.update(dt)

	local currWallTime = getWallTime()

	updateButtons()
	playerEngine.process()

	local status = playerEngine.get_game_status()
	if status ~= GAME_STATUS_NO_GAME and not playerCreated then
		
		local state = playerEngine.get_game_state()
		print("gameID" .. state.game_id)
		gameID = state.game_id
		myID = playerEngine.get_player_id()
		playerEngine.update_player_state(gameID, player.x, player.y, player.color)
		playerCreated = true
	end	

	local canMove = (status == GAME_STATUS_IN_GAME) and (status ~= GAME_STATUS_WAITING_TO_START)
	if nextMoveTime < currWallTime and canMove then
		print("DEBUG UPDATE:", player.x, player.y, "playerID", myID, "GAME_ID", gameID)
	
        	playerEngine.update_player_state(gameID, player.x, player.y, player.color)
        	nextMoveTime = currWallTime + PERIOD_MOVEMENT_IN_MILLIS
    	end

	

end


function drawGrid()

	love.graphics.setColor(255, 255, 255)
        for j=1, dimY do
                for i=1, dimX do
                        love.graphics.rectangle("line", i * 32 + xOffset, j * 32 + yOffset, 32, 32)
                end
        end

end

function drawElements(elements)

	local radius = 10
	love.graphics.setColor(255, 255, 0)
	for i=1, #elements do
    		love.graphics.circle("fill", elements[i].x*32 + 16 + xOffset, elements[i].y*32 + 16 + yOffset, radius)
	end
end

function drawPlayers(players)
	print("n players:" .. #players)

	for k, v in pairs(players) do 
		if k == myID then 
			love.graphics.setColor(255, 0, 0)
			-- local state = playerEngine.get_game_state()
			--print("DEBUG REAL POSITION:", state.players_states[myID].x, state.players_states[myID].y + yOffset)
			--print(state.players_states[myID].color.r)
			love.graphics.setFont(defaultSize)
					
			local text = "SCORE: " ..v.points			
			love.graphics.printf(text, xOffset + 32, 2*32 - 16, screenW, "left")

		else
			print(k)	
			love.graphics.setColor(v.color.r, v.color.g, v.color.b) 
		end

	--	print(k)
        	love.graphics.rectangle("fill", v.x*32 + xOffset, v.y*32 + yOffset, 32, 32)
	end
end

function drawWaitingPlayers()

	local text = "WAITING FOR PLAYERS"
	love.graphics.setColor(255, 0, 0)
	love.graphics.setFont(bigFont)
	love.graphics.printf(text, 0, 32/2, screenW, "center")
end

function drawScore(points)
	
	local text = "SCORE: " ..points
	love.graphics.setColor(255, 0, 0)
	love.graphics.setFont(defaultSize)				
	love.graphics.printf(text, xOffset + 32, 2*32 - 16, screenW, "left")
end
function drawGameOver()

	local players = playerEngine.get_game_state().players_states
      	local winner, points = getWinner(players)
	local text1, text2 

	if winner == myID then
		text1 = "CONGRATULATIONS"
		text2 = "YOU WON"
	else
		text1 = "GAME OVER"
                text2 = "YOU LOSE"
	end

	love.graphics.setColor(255, 255, 0)
	love.graphics.setFont(gameOverFont)
	love.graphics.printf(text1, 0, screenH/8, screenW, "center")
	love.graphics.setFont(Font1)
	love.graphics.printf(text2, 0, screenH/4 + screenH/8 , screenW, "center")

	love.graphics.setFont(Font2)
	local text = "Score: " ..players[myID].points
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

local firstInGame = true
local startTime 
function love.draw()

	-- love.timer.sleep(50)
	
	local status = playerEngine.get_game_status()
	if(status == GAME_STATUS_FINISHED) then
		drawGameOver()
		print("GAME OVER")

	elseif(status == GAME_STATUS_IN_GAME or status == GAME_STATUS_WAITING_TO_START) then
		local state = playerEngine.get_game_state()

		drawGrid()
		drawElements(state.fruits)
		drawPlayers(state.players_states)
	
		if firstInGame then  			
			startTime = getWallTime() + START_DELAY_IN_MILLIS 	
			firstInGame = false	
		end

		if status == GAME_STATUS_WAITING_TO_START or startTime > getWallTime() then 
			drawWaitingPlayers() 
		else		
			drawScore(state.players_states[myID].points)
		end 

	elseif(status == GAME_STATUS_NOT_CONNECTED) then
		drawErrorMsg("ERROR: GAME NOT CONNECTED")

	elseif(status == GAME_STATUS_SERVER_ERROR) then
		drawErrorMsg("ERROR: SERVER ERROR")
	
	elseif(status == GAME_STATUS_NO_GAME) then
		drawLoadingGame()
	end
end


