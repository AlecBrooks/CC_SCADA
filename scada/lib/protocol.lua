local protocol = {}

protocol.VERSION = 1

function protocol.newEnvelope(cfg, msgType, dst, payload)
  return {
    v = protocol.VERSION,
    facility = cfg.facility,
    type = msgType,
    src = cfg.id,
    dst = dst,
    ts = os.epoch("utc"),
    payload = payload
  }
end

function protocol.valid(cfg, msg)
  if type(msg) ~= "table" then return false end
  if msg.v ~= protocol.VERSION then return false end
  if msg.facility ~= cfg.facility then return false end
  if not msg.type or not msg.src or not msg.payload then return false end
  return true
end

return protocol