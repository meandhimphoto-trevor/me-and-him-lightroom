

local LrLogger = import 'LrLogger'
local logger = LrLogger('loupedeckPlugin')
-- logger:enable("logfile")
logger:disable()


return {
  LrShutdownFunction = function (doneFunction, progressFunction)
    -- body
    logger:trace('ShutdownApp: LOUPEDECK.plugin_running = false')
    LOUPEDECK.plugin_running = false

    progressFunction(0, "about shutdown")

    logger:trace('ShutdownApp: Going to close sockets')
    
    LOUPEDECK.RSOCKET:close()
     logger:trace('ShutdownApp: RSOCKET closed')

    if LOUPEDECK.SSOCKET_EXIST then
      LOUPEDECK.SSOCKET:close()
      logger:trace('ShutdownApp: SSOCKET closed')
    end

    progressFunction(0.5, "doing things")

    progressFunction(1, "completed")

    logger:trace('ShutdownApp: Bye bye')
    doneFunction()
  end
}
