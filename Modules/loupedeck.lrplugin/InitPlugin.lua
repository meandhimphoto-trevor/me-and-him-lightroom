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

local RECEIVE_PORT     = 23515
local SEND_PORT        = 23516

PING_MESSAGE = "0"

require 'Methods'

-- Global Variables
JSON = loadfile(LrPathUtils.child(_PLUGIN.path, 'JSON.lua'))()
LOUPEDECK = {RSOCKET = {}, SSOCKET = {}, plugin_running = true, RSOCKET_CONNECTED = false, SSOCKET_EXIST = false, KEYBOARD_DISCONNECTED_EVENT = false}

logger:trace('Init: Loupedeck plugin is loading..')

--- CREATE SOCKET FOR RECEIVING
LrTasks.startAsyncTask( function()
  LrFunctionContext.callWithContext( 'socket_remote', function( context )

    local function startServerSocket(context)
      
      LOUPEDECK.SSOCKET = LrSocket.bind  --- CREATE SOCKET FOR SENDING
      {
        functionContext = context,
        port = SEND_PORT,
        plugin = _PLUGIN,
        mode = "send",

        onConnected = function( socket, port )
          logger:trace('Send Socket Connection established')
          LOUPEDECK.SSOCKET_EXISTS = true  
        end,
        
        onClosed = function( socket )  
          logger:trace('Send Socket closed')
          LOUPEDECK.SSOCKET_EXISTS = false              
        end,

        onError = function( socket, err )
          if err == "timeout" then
            logger:trace('Send Socket Error Timeout')
            socket:reconnect()

            return
          end

          logger:trace("Failed with error: "..err)
          if string.sub(err,1,string.len("failed to open")) == "failed to open" then
            import 'LrDialogs'.showError("Loupedeck needs access to tcp ports 23515 and 23516.\n\nOther process is currently occupying 23516.\n\nLoupedeck will not work until that application is closed.")
          end

          LOUPEDECK.RSOCKET:close()
        end,
      }

      logger:trace('Send Socket loaded')
      LOUPEDECK.SSOCKET_EXIST = true
    end -- end startServerSocket()

    LOUPEDECK.RSOCKET = LrSocket.bind 
    {
      functionContext = context,
      port = RECEIVE_PORT,
      plugin = _PLUGIN,
      mode = "receive",

      onConnected = function( socket, port )        
         logger:trace('Receive Socket Connection established')
         LOUPEDECK.RSOCKET_CONNECTED = true
         
         -- Initialize rating mode
         if(RATINGS.mode == nil) then toggleRatingMode() end
         
         showNotification("WELCOME")

         LrDevelopController.revealAdjustedControls( true )
         startServerSocket(context)
      end,

      onMessage = function( socket, message )

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
        if LOUPEDECK.RSOCKET_CONNECTED then
          logger:trace('Receive Socket reconnected')
          socket:reconnect()

          if LOUPEDECK.SSOCKET_EXIST then
            logger:trace('Receive Socket ask SSOCKET to close')
            LOUPEDECK.SSOCKET:close()
          end
        end
        logger:trace('Receive Socket onClosed end --> LOUPEDECK.RSOCKET_CONNECTED  = false')
        LOUPEDECK.RSOCKET_CONNECTED = false 
      end,

      onError = function( socket, err )
        LOUPEDECK.RSOCKET_CONNECTED = false 
        if err == "timeout" then
          logger:trace('Receive Socket Error Timeout')
          socket:reconnect()
        end

        logger:trace("Failed with error: "..err)

        if string.sub(err,1,string.len("failed to open")) == "failed to open" then
          import 'LrDialogs'.showError("Loupedeck needs access to tcp ports 23515 and 23516.\n\nOther process is currently occupying 23515.\n\nLoupedeck will not work until that application is closed.")
        end
      end,
    }  -- end of LrSocket.bind 
 
    logger:trace('Receive Socket loaded')

    while LOUPEDECK.plugin_running  do
      LrTasks.sleep( 1/2 ) -- seconds
    end

    logger:trace('Loupedeck the END')

  end)  -- end callWithContext

end)  -- end startAsyncTask







