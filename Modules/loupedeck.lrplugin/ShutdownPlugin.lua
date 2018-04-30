local LrLogger = import 'LrLogger'
local logger = LrLogger('loupedeckPlugin')
--logger:enable("logfile")
logger:disable()

logger:trace("ShutdownPlugin")

if LOUPEDECK.RECEIVESOCKET_CONNECTED then
	LOUPEDECK.RECEIVESOCKET_CONNECTED = false
	LOUPEDECK.RECEIVESOCKET:close()
end

if LOUPEDECK.SENDSOCKET_CONNECTED then
	LOUPEDECK.SENDSOCKET:close()
end

