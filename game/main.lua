
local elements = {}
local nelements = 5
local players = {}
local startXposition = 1
local startYposition = 1
local dimX 
local dimY 

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

	local myX = startXposition*32
	local myY = startYposition*32
		
	if startYposition == dimY then 
		startYposition = 1
		if startXposition == dimX then 
			startXposition = 1
		else
			startXposition = dimX
		end
	else
		 startYposition = startYposition + 1
	end

	table.insert(players, {act_x = myX, act_y = myY, color = mycolor, elementsId = {}})
end

function love.load()


	move = {
        	index = 1,
        	speed = 10
    	}

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
	createPlayer({255,0,0})
	createPlayer({0,255,0})
	
end

function borderCollision(x, y)
	local x = players[move.index].act_x + 32*x
	local y = players[move.index].act_y + 32*y

	return ( x<32 or x>dimX*32 ) or ( y<32 or y>dimY*32 )
end

-- Adicionar colisao com os outros jogadores
function testCollision(x, y)

	return borderCollision(x, y)
end


function love.keypressed(key)
	if key == "up" then
		if not testCollision(0, -1) then
			players[move.index].act_y = players[move.index].act_y - 32
		end
	elseif key == "down" then
		if not testCollision(0, 1) then
			 players[move.index].act_y = players[move.index].act_y + 32
		end
	elseif key == "left" then
		if not testCollision(-1, 0) then
			players[move.index].act_x = players[move.index].act_x - 32
		end
	elseif key == "right" then
		if not testCollision(1, 0) then
			players[move.index].act_x = players[move.index].act_x + 32
		end
	end
end


function drawGrid()

	love.graphics.setColor(255, 255, 255)
        for y=1, dimY do
                for x=1, dimX do
                        love.graphics.rectangle("line", x * 32, y * 32, 32, 32)
                end
        end

end

function drawElements()

	love.graphics.setColor(255, 255, 0)
	for i=1, #elements do
    		love.graphics.circle("fill", elements[i].xc, elements[i].yc, elements[i].r)
	end
end

function drawPlayers()

	for i=1, #players do 
		love.graphics.setColor(players[i].color)
        	love.graphics.rectangle("fill", players[i].act_x, players[i].act_y, 32, 32)
	end
end

function love.draw()

	drawGrid()
	drawElements()
	drawPlayers()
end

