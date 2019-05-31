local MQTT = require("mqtt_library")
local lapp = require("pl.lapp")
local random = require("random")
local utility = require("utility")
local lapp = require("pl.lapp")

local msg_count = 0
local LOG_RATE = 5
local LOG_RATE_IN_MILLIS = LOG_RATE * 1000

local args = lapp [[
    Publish a message to a specified MQTT topic
    -d,--debug                                Verbose console logging
    -H,--host          (default mosquitto)    MQTT server hostname
    -p,--port          (default 1883)         MQTT server port number
    -t,--topic         (default root)         Topic on which to subscribe
    -r,--rate          (default 1000)         Rate msg/sec
  ]]

function callback(topic, message)
  msg_count = msg_count + 1
end

local id = "consumer_" .. random.randomNum(10)
print("[" .. id .. "]")

local mqtt_client = MQTT.client.create(args.host, args.port, callback)
mqtt_client:connect(id)
mqtt_client:subscribe({args.topic})

local next_log_time = utility.get_time_in_millis() + LOG_RATE_IN_MILLIS
while true do
  if next_log_time < utility.get_time_in_millis() then
    local rate = msg_count / LOG_RATE;
    print("Recv " .. rate .. " msg/s")
    msg_count = 0
    next_log_time =  utility.get_time_in_millis() + LOG_RATE_IN_MILLIS
  end
    
  mqtt_client:handler()
  socket.sleep(1.0/args.rate)  -- seconds
end
os.exit(0)