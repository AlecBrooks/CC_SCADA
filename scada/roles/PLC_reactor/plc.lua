package.path = package.path .. ";/scada/lib/?.lua"

local scada = require("scada")
local cfg = require("config")

scada.init(cfg)

-- Convention:
--   Left  = control outputs (manual)
--   Right = automatic outputs (passthrough from monitors)
local CONTROL_SIDE = "left"
local AUTO_SIDE    = "right"
local INPUT_SIDE   = cfg.bundled_input.side or "top"

local POWER_COLOR  = cfg.bundled_output.power or colors.red
local powerState   = false

local function setPower(state)
  powerState = state and true or false
  local v = powerState and POWER_COLOR or 0
  redstone.setBundledOutput(CONTROL_SIDE, v)
end

local function passthroughOnce()
  local v = redstone.getBundledInput(INPUT_SIDE) or 0
  redstone.setBundledOutput(AUTO_SIDE, v)
  return v
end

local function telemetryLoop()
  while true do
    local inV = redstone.getBundledInput(INPUT_SIDE) or 0

    scada.send(cfg, "telemetry", "broadcast", {
      power = powerState,
      -- raw monitor bus + raw mirrored bus (useful for debugging)
      monitor_in  = inV,
      auto_out    = redstone.getBundledOutput(AUTO_SIDE) or 0,
      control_out = redstone.getBundledOutput(CONTROL_SIDE) or 0,
    })

    sleep(2)
  end
end

local function controlLoop()
  while true do
    local msg = scada.receive(cfg)
    if msg and msg.type == "control" and (msg.dst == cfg.id or msg.dst == "broadcast") then
      if msg.payload.cmd == "power" then
        setPower(msg.payload.state)
      end
    end
  end
end

local function passthroughLoop()
  -- Fast enough to feel “live”, slow enough to be cheap.
  -- If you want event-driven, we can use os.pullEvent("redstone") instead.
  while true do
    passthroughOnce()
    sleep(0.1)
  end
end

-- Initialize outputs
setPower(false)
passthroughOnce()

parallel.waitForAny(telemetryLoop, controlLoop, passthroughLoop)