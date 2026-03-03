package.path = package.path .. ";/scada/lib/?.lua"

local scada = require("scada")
local cfg = require("config")

scada.init(cfg)

local powerState = false

local function setPower(state)
  powerState = state
  local value = state and cfg.bundled_output.power or 0
  redstone.setBundledOutput(cfg.bundled_output.side, value)
end

local function readAlarms()
  local input = redstone.getBundledInput(cfg.bundled_input.side)
  return {
    fuel     = scada.bundledHas(input, cfg.bundled_input.fuel),
    temp     = scada.bundledHas(input, cfg.bundled_input.temp),
    waste    = scada.bundledHas(input, cfg.bundled_input.waste),
    critical = scada.bundledHas(input, cfg.bundled_input.critical),
  }
end

local function telemetryLoop()
  while true do
    scada.send(cfg, "telemetry", "broadcast", {
      power = powerState,
      alarms = readAlarms()
    })
    sleep(2)
  end
end

local function controlLoop()
  while true do
    local msg = scada.receive(cfg)
    if msg and msg.type == "control" then
      if msg.dst == cfg.id or msg.dst == "broadcast" then
        if msg.payload.cmd == "power" then
          setPower(msg.payload.state)
        end
      end
    end
  end
end

parallel.waitForAny(telemetryLoop, controlLoop)