local LrSocket = import "LrSocket"
local LrTasks = import "LrTasks"
local LrFunctionContext = import "LrFunctionContext"
local LrApplication = import 'LrApplication'
local LrDevelopController = import 'LrDevelopController'
local LrPathUtils = import 'LrPathUtils'

local LrLogger = import 'LrLogger'
local logger = LrLogger('loupedeckPlugin')
logger:disable()
--logger:enable( "logfile" )

local RECEIVE_PORT     = { 23515, 23517, 23519, 23529, 23549 }
local SEND_PORT        = { 23516, 23518, 23520, 23530, 23550 }

local SENDINDEX = 1
local RECEIVEINDEX = 1

local TRIES = 0

PING_MESSAGE = "0"

require 'Methods'

-- Global Variables
JSON = loadfile(LrPathUtils.child(_PLUGIN.path, 'JSON.lua'))()
LOUPEDECK = {RECEIVESOCKET = {}, SENDSOCKET = {}, plugin_running = true, RECEIVESOCKET_CONNECTED = false, SENDSOCKET_CONNECTED = false}

logger:trace('Init: Loupedeck plugin is loading..')

--- CREATE SOCKET FOR RECEIVING
LrTasks.startAsyncTask( function()
  LrFunctionContext.callWithContext( 'socket_remote', function( context )

    local function startSendSocket(context)

      logger:trace("startSendSocket: "..SEND_PORT[SENDINDEX])
      TRIES = TRIES + 1
      
      LOUPEDECK.SENDSOCKET = LrSocket.bind  --- CREATE SOCKET FOR SENDING
      {
        functionContext = context,
        port = SEND_PORT[SENDINDEX],
        plugin = _PLUGIN,
        mode = "send",

        onConnected = function( socket, port )
          logger:trace('Send Socket Connection established')

          LOUPEDECK.SENDSOCKET_CONNECTED = true

          TRIES = 0

          --showNotification("WELCOME")
        end,
        
        onClosed = function( socket )  
          logger:trace('Send Socket closed')  
          LOUPEDECK.SENDSOCKET_CONNECTED = false
        end,

        onError = function( socket, err )
          LOUPEDECK.SENDSOCKET_CONNECTED = false

          if err == "timeout" then
            logger:trace('Send Socket Error Timeout '..SEND_PORT[SENDINDEX])
            --socket:reconnect()
            startSendSocket(context)

            return
          end

          logger:trace("Failed with error: "..err)
          if string.sub(err,1,string.len("failed to open")) == "failed to open" and TRIES == 5 then
            import 'LrDialogs'.showError("Loupedeck needs access to tcp ports, but failed to make a connection.")
            logger:trace("All send ports tried. Failed.")

            TRIES = 0

            return
          end

          logger:trace('Send socket reconnect to '..SEND_PORT[SENDINDEX])

          SENDINDEX = SENDINDEX == 5 and 1 or SENDINDEX + 1
          
          startSendSocket(context)
          --socket:reconnect()

          --LOUPEDECK.RECEIVESOCKET:close()
        end,
      }

      logger:trace('Send Socket loaded')
    end -- end startServerSocket()

    local function startReceiveSocket(context)

      logger:trace("startReceiveSocket: "..RECEIVE_PORT[RECEIVEINDEX])
      TRIES = TRIES + 1

      LOUPEDECK.RECEIVESOCKET = LrSocket.bind 
      {
        functionContext = context,
        port = RECEIVE_PORT[RECEIVEINDEX],
        plugin = _PLUGIN,
        mode = "receive",

        onConnected = function( socket, port )        
           logger:trace('Receive Socket Connection established')
           LOUPEDECK.RECEIVESOCKET_CONNECTED = true
           
           -- Initialize rating mode
           if(RATINGS.mode == nil) then toggleRatingMode() end

           RECEIVEINDEX = 1

           TRIES = 0
           
           --showNotification("WELCOME")

           LrDevelopController.revealAdjustedControls( true )
           startSendSocket(context)
        end,

        onMessage = function( socket, message )

          logger:trace("Received message: "..message)

          if message == PING_MESSAGE then 
            return true
          end

          --LrTasks.startAsyncTask(function()
          LrTasks.startAsyncTaskWithoutErrorHandler(function ()
            local photo = LrApplication.activeCatalog():getTargetPhoto()
      
            if( photo ~= nil and photo ~= CurrentPhoto.photo) then 
              changeCurrentPhoto(photo) 
            end

            local msg = JSON:decode(message)
          
            METHODS[msg.method](msg.property, msg.value)
          end, "MethodHandler")
          
        end,

        onClosed = function( socket )
          if LOUPEDECK.RECEIVESOCKET_CONNECTED then
            logger:trace('Receive Socket ask SENDSOCKET to close')
            LOUPEDECK.SENDSOCKET:close()

            logger:trace('Receive Socket reconnected')
            socket:reconnect()

          end

          logger:trace('Receive Socket onClosed end --> LOUPEDECK.RECEIVESOCKET_CONNECTED  = false')
          LOUPEDECK.RECEIVESOCKET_CONNECTED = false 
        end,

        onError = function( socket, err )
          LOUPEDECK.RECEIVESOCKET_CONNECTED = false 
          if err == "timeout" then
            logger:trace('Receive Socket Error Timeout '..RECEIVE_PORT[RECEIVEINDEX])
            socket:reconnect()
            return
          end 

          logger:trace("Failed with error: "..err)

          if string.sub(err,1,string.len("failed to open")) == "failed to open" and TRIES == 5 then
            import 'LrDialogs'.showError("Loupedeck needs access to tcp ports, but failed to make a connection.")
            logger:trace("All receive ports tried. Failed.")

            TRIES = 0

            return
          end

          RECEIVEINDEX = RECEIVEINDEX == 5 and 1 or RECEIVEINDEX + 1

          logger:trace('Receive socket reconnect to '..RECEIVE_PORT[RECEIVEINDEX])
          startReceiveSocket(context)

          --socket:reconnect()

        end,
      }  -- end of LrSocket.bind 
      end -- end of startReceiveSocket

    logger:trace('Receive Socket loaded')
    startReceiveSocket(context)

    while LOUPEDECK.plugin_running  do
      LrTasks.sleep( 1/2 ) -- seconds
    end

    logger:trace('Loupedeck the END')

  end)  -- end callWithContext

end)  -- end startAsyncTask







