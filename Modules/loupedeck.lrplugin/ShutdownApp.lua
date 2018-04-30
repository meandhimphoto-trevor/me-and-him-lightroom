local LrLogger = import 'LrLogger'
local logger = LrLogger('loupedeckPlugin')
--logger:enable("logfile")
logger:disable()


return {
  LrShutdownFunction = function (doneFunction, progressFunction)
    -- body
    logger:trace('ShutdownApp: LOUPEDECK.plugin_running = false')
    LOUPEDECK.plugin_running = false

    progressFunction(0, "about shutdown")

    logger:trace('ShutdownApp: Going to close sockets')
    
    if LOUPEDECK.RECEIVESOCKET_CONNECTED then
    LOUPEDECK.RECEIVESOCKET:close()
    end
    logger:trace('ShutdownApp: RECEIVESOCKET closed')

    if LOUPEDECK.SENDSOCKET_CONNECTED then
        LOUPEDECK.SENDSOCKET:close()
    end
    logger:trace('ShutdownApp: SENDSOCKET closed')

    progressFunction(0.5, "doing things")

    progressFunction(1, "completed")

    logger:trace('ShutdownApp: Bye bye')
    doneFunction()
  end
}
