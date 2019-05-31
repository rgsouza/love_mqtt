function get_wall_time()
  return socket.gettime()*1000
end

local MQTT = require("mqtt_library")
local lapp = require("pl.lapp")
local random = require("random")

local lapp = require("pl.lapp")
local args = lapp [[
    Publish a message to a specified MQTT topic
    -d,--debug                                Verbose console logging
    -H,--host          (default mosquitto)    MQTT server hostname
    -p,--port          (default 1883)         MQTT server port number
    -t,--topic         (default ping)         Topic on which to subscribe
    -r,--rounds        (default 10)            Rounds of measurement
  ]]

  local sent_time = 0
  local received_msg = false
  local delay_total = 0

  function callback(
    topic,    -- string
    message)  -- string
  
    received_msg = true
    local delay_time = get_wall_time() - sent_time
    print("DELAY " .. ": ".. delay_time)
    delay_total = delay_total + delay_time
  end

  local id = "ping_" .. random.randomNum(10)
  print("[" .. id .. "]")

  local mqtt_client = MQTT.client.create(args.host, args.port, callback)
  mqtt_client:connect(id)
  mqtt_client:subscribe({args.topic})

  for i=1, args.rounds do
    received_msg = false
    sent_time = get_wall_time()
    mqtt_client:publish(args.topic, "pingmsg")
    while not received_msg do    
      mqtt_client:handler()
    end

    local wait_time_due = get_wall_time() + 1000
    while not (wait_time_due < get_wall_time()) do
      socket.sleep(0.001)  -- seconds
    end
  
  end

  print("------")
  print(delay_total/args.rounds)

  os.exit(0)