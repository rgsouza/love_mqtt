local MQTT = require("mqtt_library")
local lapp = require("pl.lapp")
-- local random = require("random")

local function randomString(sizeInBytes)
    local result = ""
    local asciiCode
    
    for i = 1,sizeInBytes do
        asciiCode = math.random(32, 126)
        result = result .. string.char(asciiCode)
    end

    return result
end


local function randomNum(lenght)
    local result = ""
    
    for i = 1,lenght do
        result = result .. math.random(0, 9)
    end

    return result
end


local lapp = require("pl.lapp")
local args = lapp [[
    Publish a message to a specified MQTT topic
    -d,--debug                                Verbose console logging
    -H,--host          (default localhost)    MQTT server hostname
    -p,--port          (default 1883)         MQTT server port number
    -t,--topic         (default root)         Topic on which to publish
    -r,--rate          (default 100.0)        Rate msg/sec
  ]]

  local id = "publisher_" .. randomNum(10)
  print("[" .. id .. "]")

  if (args.debug) then MQTT.Utility.set_debug(true) end

  local mqtt_client = MQTT.client.create(args.host, args.port)
  mqtt_client:connect(id)

  local msg = ""
  for i = 1, 100 do
    msg = randomString(10)
    msg = i
    mqtt_client:publish(args.topic, msg)
    socket.sleep(1.0/args.rate)  -- seconds
  end