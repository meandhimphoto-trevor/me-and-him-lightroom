
local LrTasks 				= import 'LrTasks'
local LrDialogs 			= import 'LrDialogs'
local LrApplication 		= import 'LrApplication'
local LrApplicationView 	= import 'LrApplicationView'
local LrUndo 				= import 'LrUndo'
local LrDevelopController 	= import 'LrDevelopController'
local LrSelection			= import 'LrSelection'
local LrPathUtils         	= import 'LrPathUtils'
local LrFileUtils           = import 'LrFileUtils'
local LrShell             = import 'LrShell'
-- Logger
local LrLogger            = import 'LrLogger'
local logger              = LrLogger('loupedeckPlugin')

-- Notifications
require 'Notifications'

-- GLOBAL VARIABLEs
OriginDevelopTool = ""

CurrentPhoto = {
	photo = nil,
	fileFormat = "",
  	view = "develop_loupe"
}

-- LR Methods
METHODS = {
  StepUp          = function(property, value) setProperty(property, value)  end,
  StepDown        = function(property, value) setProperty(property, -value) end,
  Reset           = function(property, value) return doReset(property) end, 
  Get             = function(property, value) getPropertyInfo(property) end,
  SocketControl   = function(event, value) onHandleSocketControl(event) end,
  Control         = function(controlType,value) CONTROLS[controlType](value) end,
  Increase        = function(property, value) setProperty(property, (BIG_STEP_MULTIPLIER*value)) end,
  Decrease        = function(property, value) setProperty(property, -(BIG_STEP_MULTIPLIER*value)) end,
  Preset          = function(property, value) applyPreset(value) end,
}


CONTROLS = {
  Undo        = function(value) if value == 'All' then return LrDevelopController.resetAllDevelopAdjustments() end LrUndo.undo() end,
  Redo        = function(value) LrUndo.redo() end,
  Zoom        = function(value) LrApplicationView.toggleZoom() end,
  FullScreen  = function(value) if value == nil or value == "" then return end return runScript(value) end,
  Brush 	    = function() toggleBrushTool() end,
  Copy        = function() return copySettings() end,
  Paste       = function(value) return pasteSettings(value) end,
  Pick        = function(value) if value == "0" then return togglePick() else return toggleReject() end end,
  Before      = function(value) return toggleBefore(value) end,
  ArrowUp     = function() if LrApplicationView.getCurrentModuleName() == "develop" then return end runScript("keyup") end,
  ArrowDown   = function() if LrApplicationView.getCurrentModuleName() == "develop" then return end runScript("keydown") end,
  ArrowLeft   = function(value) if value=="Select" then return LrSelection.extendSelection("left", 1) end LrSelection.previousPhoto() end,
  ArrowRight  = function(value) if value=="Select" then return LrSelection.extendSelection("right", 1) end LrSelection.nextPhoto() end,
  Rating      = function(value) return setRating(value) end,
  Export 	    = function(value) return doExport(value) end,
  Mode 		    = function() return toggleMode() end,
  Hue         = function() LrDevelopController.revealPanel("HueAdjustmentRed") end,
  Saturation  = function() LrDevelopController.revealPanel("SaturationAdjustmentRed") end,
  Luminance   = function() LrDevelopController.revealPanel("LuminanceAdjustmentRed") end,
  Gray        = function() LrDevelopController.revealPanel("GrayMixerRed") end,
  Selection   = function(value) return doPhotoSelection(value) end,
  Script      = function(value) return runScript(value) end,
}

RESETS = {
	straightenAngle = function() toggleCrop() end,
}

NORMAL_STEP 		= 1/200
BIG_STEP_MULTIPLIER = 3

PROPERTY_ACCURACY = { -- x times as accurate as default
	straightenAngle = 9, 
	Temperature = 2,
	local_Temperature = 2,
	Exposure = 2.5,
	local_Exposure = 2.5,
}

FILETYPE_PROPERTY_VALUE_METHODS = {
	RAW = {
		Temperature = function(property, value) setLogarithmicValue(property, value) end,
	}, 
	DNG = {
		Temperature = function(property, value) setLogarithmicValue(property, value) end,
	}
}

MODE_RATINGS = "MODE_RATINGS"
MODE_COLORS = "MODE_COLORS"

RATINGS = {
	mode = MODE_RATINGS,
  COLORS = {"red", "yellow", "green", "blue", "purple", "none"},
	MODE_RATINGS = function(rating) return LrSelection.setRating(rating) end,
  MODE_COLORS = function(rating) return LrSelection.setColorLabel(RATINGS["COLORS"][rating]) end
}

-- Property Value Calculations 
function setProperty( property, modifier )
	-- body
	local f = FILETYPE_PROPERTY_VALUE_METHODS[CurrentPhoto.fileformat]

	prop = ((LrDevelopController.getSelectedTool() == "localized" or LrDevelopController.getSelectedTool() == 'gradient' or LrDevelopController.getSelectedTool() == 'circularGradient') and "local_"..property or property)

	if(f == nil) then return setNormalValue(prop, modifier) end

	local m = f[prop] or setNormalValue

	return m(prop, modifier)
end

function setNormalValue( property, modifier )
	-- body

	local min,max = LrDevelopController.getRange(property)

	if LrDevelopController.getValue(property) == nil then
		LrDevelopController.revealPanel(property)
	end
	
	local accuracy = PROPERTY_ACCURACY[property] or 1
	local step = (max-min) * (NORMAL_STEP/accuracy) * modifier
	local v = (LrDevelopController.getValue(property) or 0) + step
	
	LrDevelopController.setValue(property, (v < min and min or v > max and max or v))
end

function setLogarithmicValue( property, multiplier)
	-- body
	local accuracy = PROPERTY_ACCURACY[property] or 1
	
	local min, max = LrDevelopController.getRange(property)

	local v = LrDevelopController.getValue(property)
	
	local y = math.log(v)
	local step = ((math.log(max) - math.log(min)) * (NORMAL_STEP / accuracy)) * tonumber(multiplier)
  local yn = math.exp(y+step)

  local newValue = (yn < min and min or yn > max and max or yn)
	LrDevelopController.setValue(property, newValue)
end

function doReset( property )
  
  prop = (LrDevelopController.getSelectedTool() == "localized" and "local_"..property or property)

  if(type(RESETS[property])=="function") then 
    RESETS[property]() 
  else 
    LrDevelopController.resetToDefault(prop) 
  end
end

function toggleCrop( )
	local currentTool = LrDevelopController.getSelectedTool()

	if(OriginDevelopTool == "" and currentTool ~= "crop") then OriginDevelopTool = LrDevelopController.getSelectedTool() end

	if(LrDevelopController.getSelectedTool() == "crop") then
		local tool = (OriginDevelopTool == "" and "loupe" or OriginDevelopTool)
		LrDevelopController.selectTool(tool)
		OriginDevelopTool = ""
		return true
	end

	LrDevelopController.selectTool("crop")
	return true
end

-- Rating Control
function setRating( value )
	local v = tonumber(value)
	
	if(value == "0") then return toggleRatingMode() end

	if(RATINGS.mode == MODE_RATINGS) then
    	local v = (tonumber(value) == LrSelection.getRating() and 0 or tonumber(value))
    	return RATINGS[RATINGS.mode](v)
  	end

  -- Mode Colors
  	local v = (LrSelection.getColorLabel() == RATINGS["COLORS"][tonumber(value)] and 6 or tonumber(value))
    showSetColorRatingNotification(RATINGS["COLORS"][tonumber(v)])
	return RATINGS[RATINGS.mode](v)
end

function toggleRatingMode()
	
	if(RATINGS.mode == MODE_RATINGS) then 
    RATINGS.mode = MODE_COLORS
    return showNotification(RATINGS.mode)
  end
	if(RATINGS.mode == MODE_COLORS) then 
    RATINGS.mode = MODE_RATINGS
    return showNotification(RATINGS.mode)
  end

	-- Incorrect mode detected, resetting to ratings
	RATINGS.mode = MODE_RATINGS
  return showNotification(RATINGS.mode)

end

function setStarRating(value)
  for _,p in pairs(LrApplication.activeCatalog():getTargetPhotos()) do

    local cr = p:getRawMetadata("rating")

    if cr == value then
      LrApplication.activeCatalog():withWriteAccessDo("Set rating", function(context)
        p:setRawMetadata("rating", nil)
      end)
    else
      LrApplication.activeCatalog():withWriteAccessDo("Set rating", function(context)
        p:setRawMetadata("rating", value)
      end)
    end
  end  
end

function setColorRating(value)
  for _,p in pairs(LrApplication.activeCatalog():getTargetPhotos()) do
    local cr = p:getRawMetadata("colorNameForLabel")

    local nr = cr == RATINGS.COLORS[value] and RATINGS.COLORS[6] or RATINGS.COLORS[value]

    LrApplication.activeCatalog():withWriteAccessDo("Set color label", function( context )
      p:setRawMetadata("colorNameForLabel", nr)
    end)
  end  
end

-- Preset Control
function applyPreset( value )
	if CurrentPhoto.photo == nil then return end

	local preset = LrApplication.developPresetByUuid(value)
	local catalog = LrApplication.activeCatalog()
	catalog:withWriteAccessDo( "Loupedeck preset", function ( context )
		CurrentPhoto.photo:applyDevelopPreset(preset)
	end)
end

-- Toggle Pick / Reject 
function togglePick( )
 
  local f = LrSelection.getFlag()
 
  if f == 1 then return LrSelection.removeFlag() end

  return LrSelection.flagAsPick()

end

function toggleReject( )

  local f = LrSelection.getFlag()
  
  if f == -1 then return LrSelection.removeFlag() end
  
  return LrSelection.flagAsReject()
end


-- Copy & Paste
function copySettings( )
 
  if CurrentPhoto.photo == nil then return end
  CurrentPhoto.settings = CurrentPhoto.photo:getDevelopSettings()
  return showNotification("COPY")
end

function pasteSettings(value)

  if CurrentPhoto.photo == nil or CurrentPhoto.settings == nil then return end
  
  LrApplication.activeCatalog():withWriteAccessDo("pasteSettings", function( context )
    if value == "All" then
      local photos = LrApplication.activeCatalog():getTargetPhotos()
      for _,photo in pairs(photos) do
        photo:applyDevelopSettings(CurrentPhoto.settings)
      end
      return showNotification("PASTE")
    end
      
      CurrentPhoto.photo:applyDevelopSettings(CurrentPhoto.settings)
    return showNotification("PASTE")
  end)
end

-- Before / After
function toggleBefore(value)
  if CurrentPhoto.view == "develop_loupe" then
    if value == "0" then CurrentPhoto.view = "develop_before_after_horiz" end
    if value == "1" then CurrentPhoto.view = "develop_before_after_vert" end
  else
    CurrentPhoto.view = "develop_loupe"
 end
 LrApplicationView.showView(CurrentPhoto.view)
end

-- Toggle Brush Mode
function toggleBrushTool( )
	local currentTool = LrDevelopController.getSelectedTool()

	if(OriginDevelopTool == "" and currentTool ~= "localized") then OriginDevelopTool = LrDevelopController.getSelectedTool() end

	if(currentTool == "localized") then
		local tool = (OriginDevelopTool == "" and "loupe" or OriginDevelopTool)
		LrDevelopController.selectTool(tool)
		OriginDevelopTool = ""
		return true
	end

	LrDevelopController.selectTool("localized")

	return true
end

-- Toggle Develop / Library mode
function toggleMode()
	if LrApplicationView.getCurrentModuleName() == "develop" then LrApplicationView.switchToModule("library") return end

	LrApplicationView.switchToModule("develop")
end

function doExport( filename )

  if filename == nil or filename == "" then
    return runScript("exportDialog")
  end
  
  if string.find(filename, ".lrtemplate") == nil then
    LrDialogs.showBezel("Starting export: "..filename, 3)
  else
    local s,e = string.find(filename, ".lrtemplate")
    LrDialogs.showBezel("Starting export "..string.sub(filename, 0, s-1), 3)
  end
  
  local cat = LrApplication.activeCatalog()
  local photos = cat:getTargetPhotos()
  
  local settings = getExportSettings(filename) or {
      LR_format = "JPEG",
      LR_size_doConstrain = false,
      LR_collisionHandling = "overwrite",
      LR_export_destinationType = "chooseLater",
  }

  local exportSession = import "LrExportSession" {
    photosToExport = photos,
    exportSettings = settings,
  }

  exportSession:doExportOnCurrentTask()
  
  count = 0
  for _, rendition in exportSession:renditions() do
  
    local success, path = rendition:waitForRender()
    
    if success and path then
      count = count + 1
    else
      logger:trace("Failed", success, path)
    end
  
  end
	LrDialogs.showBezel("Exported "..tostring(count).." photos", 3)
end

function getExportPresetFilePath( filename )
  local path = joinUntil(getPresetPath(true), "Lightroom") 
  path =  LrPathUtils.child(path, "Export Presets")

  local filePath = nil
  for fp in LrFileUtils.recursiveDirectoryEntries(path) do
    if string.find(fp, filename) ~= nil then
      filePath = fp
    end
  end

  return filePath
end

function getExportSettings(filename)
	
  if filename == nil then return nil end

  file = getExportPresetFilePath(filename)

	if file == nil or LrFileUtils.exists(file) ~= "file" then 
    LrDialogs.showBezel("Export setting file was not found, reverting to defaults", 3)
    return nil
  end

	local fc = LrFileUtils.readFile(file)
	
	local _,si = string.find(fc, "value = {")
	local ei,_ = string.find(fc, "},", si)

	local x = split(string.sub(fc, si+1, ei-1), '[,]')
	local settings = {}
	for _,v in pairs(x) do 
		if string.len(v) > 2 then
      local i = split(v, "[=]")
		  
      local s = tostring(clean(i[1]))
      local v = clean(i[2])

      if s ~= 'exportServiceProvider' then
        s = 'LR_'..s
      end

      local value = (tonumber(v) == nil and tostring(v) or tonumber(v))
      if value == "false" or value == "False" then
        value = false
      elseif value == "true" or value == "True" then
        value = true
      end
      settings[s] = value
		end
	end
	return settings
end

function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

function joinUntil(strings, last)
	if MAC_ENV then
    str = "/"
  else
    str = ""
  end


	for _,v in pairs(strings) do 
		str = str..v
		if v == last then return str end
		
    if MAC_ENV then 
      str = str.."/"
    else
      str = str.."\\"
    end

	end
end

function getPresetPath(asTable)
  	for _,folder in pairs(LrApplication.developPresetFolders()) do
  		local parts = {}
  		parts = split(folder:getPath(), '[\\/]+')
  		if parts[#parts] == "User Presets" then
  			return (asTable and parts or folder:getPath())
  		end
  	end
end

-- Photo Selection
function doPhotoSelection(value) 

  -- Override current selection
  LrApplication.activeCatalog():setSelectedPhotos(LrApplication.activeCatalog():getTargetPhoto(), {})

  local photos = LrApplication.activeCatalog():getMultipleSelectedOrAllPhotos()

  local selectedPhotos = {}

  for _,photo in pairs(photos) do
    if value == 'Any' or isTaggedWithValue(photo, value) then
      table.insert(selectedPhotos, photo)
    end
  end

  if #selectedPhotos == 0 then 
    showNotification("NO_MATCH")
    return 
  end

  local p = selectedPhotos[#selectedPhotos]

  LrApplication.activeCatalog():setSelectedPhotos(p, selectedPhotos)

  showMatchingImagesNotification(#selectedPhotos)
end

function isTaggedWithValue(photo, value)
  
  if RATINGS.mode == MODE_RATINGS then

    local r = photo:getRawMetadata("rating")

    logger:trace("Found rating ", r)

    if tonumber(r) == tonumber(value) then return true end

    return false
  end

  if RATINGS.mode == MODE_COLORS then 
    local label = photo:getRawMetadata("colorNameForLabel")
 
    if label == RATINGS["COLORS"][tonumber(value)] then 
      return true
    end

    return false
  end

  logger:debug("Unhandled rating mode in isTaggedWithValue", RATINGS.mode )
  return false
end

-- Scripting

function runScript(value) 
  LrTasks.startAsyncTask(function ()
    if MAC_ENV then
      local s = _PLUGIN.path.."/scripts/macOS/"..value..".scpt"
      LrShell.openPathsViaCommandLine({s}, 'osascript')
    end

    if WIN_ENV then 
      local s = "\"".._PLUGIN.path.."\\scripts\\windows\\"..value..".vbs".."\""
      LrTasks.execute('wscript '..s)
    end

  end)
  
end

-- Socket Control
function onHandleSocketControl(event)
end  -- OnHandleSocketControl

function getPropertyInfo(property)

    local minRange, maxRange = LrDevelopController.getRange(property)
    local currentVal = LrDevelopController.getValue(property)
    local respBody = {currentValue = currentVal, minValue = minRange, maxValue = maxRange}

    if (property == "AllPresets") then 
      respBody = listPresets()
    end

    local resp = JSON:encode( {propertyName = property, items = respBody} )
     
    LOUPEDECK.SSOCKET:send(string.format('%s\n', resp))
end -- end getPropertyInfo

function listPresets()

   local psList = {}
    for _,folder in pairs(LrApplication.developPresetFolders()) do
      local presets = {}
      local foldname = folder:getName()

     for _,pst in pairs(folder:getDevelopPresets()) do    
       _p = {}
        _p["name"] = pst:getName()
        _p["uuid"] = pst:getUuid()      
        table.insert(presets,_p)
      end
      table.insert(psList,{ name = foldname, presets = presets })
    end

   return psList
end -- end listPresets


function readMetaDataInfo(key)

LrTasks.startAsyncTask (function()
  local catalog = LrApplication.activeCatalog()    
  local selectedPhoto = catalog:getTargetPhoto() 
   requestedMetaData = selectedPhoto:getRawMetadata(key)  
 end) -- end of startAsyncTask
  
  return requestedMetaData
end -- end readMetaDataInfo


function changeCurrentPhoto( photo )
	CurrentPhoto.photo = photo
	CurrentPhoto.fileformat = photo:getRawMetadata("fileFormat")
  CurrentPhoto.view = "develop_loupe"
end

-- Utils
function trim(s)
  if s==nil then return end
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function clean(s)
  if s == nil then return end
  s = trim(s)
  if tonumber(s) ~= nil then
    return s
  end
  return s:gsub('"','')
end
