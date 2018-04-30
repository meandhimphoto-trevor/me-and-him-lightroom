local LrLogger = import 'LrLogger'
local logger = LrLogger('loupedeckPlugin')
--logger:enable("logfile")
logger:disable()

logger:trace("DisablePlugin")

if LOUPEDECK.RECEIVESOCKET_CONNECTED then
	LOUPEDECK.RECEIVESOCKET:close()
end

if LOUPEDECK.SENDSOCKET_CONNECTED then
	LOUPEDECK.SENDSOCKET:close()
end
