package.path = package.path .. ";/scada/lib/?.lua"

local protocol = require("protocol")
local scada = {}

function scada.init(cfg)
  rednet.open(cfg.modem_side)
end

function scada.send(cfg, msgType, dst, payload)
  local env = protocol.newEnvelope(cfg, msgType, dst, payload)
  rednet.broadcast(env)
end

function scada.receive(cfg, timeout)
  local id, msg = rednet.receive(timeout)
  if not msg then return nil end
  if not protocol.valid(cfg, msg) then return nil end
  return msg
end

function scada.bundledHas(value, color)
  return colors.test(value or 0, color)
end

function scada.now()
  return os.epoch("utc")
end

return scada