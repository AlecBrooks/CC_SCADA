package.path = package.path .. ";/scada/lib/?.lua"

local scada = require("scada")
local cfg = require("config")

scada.init(cfg)

local reactors = {}
local pending = {}

local function drawUI()
  term.clear()
  term.setCursorPos(1,1)

  print("=== Control Room ===")
  print("S: Power ON")
  print("X: Power OFF")
  print("")

  for id, data in pairs(reactors) do
    local status = "UNKNOWN"

    if data.lastUpdate then
      if scada.now() - data.lastUpdate > 5000 then
        status = "UNKNOWN"
      elseif pending[id] then
        status = "PENDING"
      else
        status = data.power and "ON" or "OFF"
      end
    end

    print(id .. " : " .. status)

    if data.alarms then
      for k,v in pairs(data.alarms) do
        if v then print("  [!] " .. k:upper()) end
      end
    end

    print("")
  end
end

local function sendPower(state, target)
  pending[target] = true
  scada.send(cfg, "control", target, {
    cmd = "power",
    state = state
  })
end

local function telemetryLoop()
  while true do
    local msg = scada.receive(cfg, 1)
    if msg and msg.type == "telemetry" then
      reactors[msg.src] = {
        power = msg.payload.power,
        alarms = msg.payload.alarms,
        lastUpdate = scada.now()
      }
      pending[msg.src] = false
      drawUI()
    end
  end
end

local function inputLoop()
  while true do
    local _, key = os.pullEvent("key")

    if key == keys.s then
      for id,_ in pairs(reactors) do
        sendPower(true, id)
      end
      drawUI()
    elseif key == keys.x then
      for id,_ in pairs(reactors) do
        sendPower(false, id)
      end
      drawUI()
    end
  end
end

drawUI()
parallel.waitForAny(telemetryLoop, inputLoop)