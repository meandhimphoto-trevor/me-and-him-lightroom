
local LrDialogs       = import 'LrDialogs'
local LrApplication     = import 'LrApplication'
local LrApplicationView   = import 'LrApplicationView'
local LrDevelopController   = import 'LrDevelopController'
local LrPathUtils           = import 'LrPathUtils'
local LrFileUtils           = import 'LrFileUtils'

-- Logger
local LrLogger            = import 'LrLogger'
local logger              = LrLogger('loupedeckPlugin')

local presetCache

------- DEVELOP PRESETS -------

-- Preset Control
function applyPreset( value )
  if CurrentPhoto.photo == nil then return end

  local v = string.sub(value,2,string.len(value))

  local preset = LrApplication.developPresetByUuid(v)
  local catalog = LrApplication.activeCatalog()
  catalog:withWriteAccessDo( "Loupedeck preset", function ( context )
    CurrentPhoto.photo:applyDevelopPreset(preset)
  end)
end

function getPresets()

    if presetCache ~= nil then
      local response = JSON:encode( {propertyName = "AllPresets", items = presetCache} )
      LOUPEDECK.SENDSOCKET:send(string.format('%s\n', response))
    else
      local respBody = listPresets()
      presetCache = respBody
      local resp = JSON:encode( {propertyName = "AllPresets", items = respBody} )

      logger:trace("On getPresets!")
      LOUPEDECK.SENDSOCKET:send(string.format('%s\n', resp))
    end
end

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
end


------- EXPORT PRESETS -------

-- Export preset handling
function doExport( filename )

  if filename == nil or filename == "ExportWindow" then
    return runScript("exportDialog")
  elseif filename == "PrintSheet" then
    if LrApplicationView.getCurrentModuleName() ~= "print" then LrApplicationView.switchToModule("print") return end
      LrApplicationView.switchToModule("develop")
      return
  elseif filename == "Print" then
    return runScript("print")
  elseif filename == "ExportWithPrevious" then
    return runScript("exportWithPrevious")
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

  if string.find(filename, ".lrtemplate") == nil then
    filename = filename..".lrtemplate"
  end

  filename = string.gsub(filename, '%%', '%%%')
  filename = string.gsub(filename, '%^', '%%^')
  filename = string.gsub(filename, '%$', '%%$')
  filename = string.gsub(filename, '%(', '%%(')
  filename = string.gsub(filename, '%)', '%%)')
  filename = string.gsub(filename, '%[', '%%[')
  filename = string.gsub(filename, '%]', '%%]')
  filename = string.gsub(filename, '%*', '%%*')
  filename = string.gsub(filename, '%+', '%%+')
  filename = string.gsub(filename, '%-', '%%-')
  filename = string.gsub(filename, '%?', '%%?')

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
	local ei,_ = string.find(fc, "},", -40)

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

function getPresetPath(asTable)
    for _,folder in pairs(LrApplication.developPresetFolders()) do
      local parts = {}
      parts = split(folder:getPath(), '[\\/]+')
      if parts[#parts] == "User Presets" then
        return (asTable and parts or folder:getPath())
      end
    end
end

function getExportPresets()
  local found = false
  local path = joinUntil(getPresetPath(true), "Develop Presets", "Export Presets") 

  local paths = {}

  for fp in LrFileUtils.recursiveDirectoryEntries(path) do
    local t = splitExportPresetPath(fp)
    if string.find(t, ".lrtemplate") ~= nil then
      table.insert(paths, t)
    end
  end

  doExportPresetJson(paths)

end

function doExportPresetJson(paths)

  local folder
  local presets = {}
  local fPresets = {}
  local ePresets = {}

  for _,t in pairs(paths) do
    local parts = split(t, '[\\/]+')

    if string.find(parts[2], ".lrtemplate") then
      table.insert(ePresets, {name = parts[2]})
      if next(paths,_) == nil then
        table.insert(fPresets, {name = folder, presets = presets})
        table.insert(fPresets, {name = "Export Presets", presets = ePresets})
      end
    else
      if next(paths,_) == nil then
        if folder == parts[2] then
          table.insert(presets, {name = parts[#parts]})
          table.insert(fPresets, {name = folder, presets = presets})
        else
          if folder ~= nil then
            table.insert(fPresets, {name = folder, presets = presets})
          end
          presets = {}
          table.insert(presets, {name = parts[#parts]})
          table.insert(fPresets, {name = parts[2], presets = presets})
        end
   
        if #ePresets ~= 0 then
          table.insert(fPresets, {name = "Export Presets", presets = ePresets})
        end
      elseif folder == parts[2] or folder == nil then
        table.insert(presets, {name = parts[#parts]})
      elseif folder ~= parts[2] and folder ~= nil then
        table.insert(fPresets, {name = folder, presets = presets})
        presets = {}
        table.insert(presets, {name = parts[#parts]})
      end
      folder = parts[2]
    end
  end


  local resp = JSON:encode( {propertyName = "ExportPresets", items = fPresets} )

  LOUPEDECK.SENDSOCKET:send(string.format('%s\n', resp))
end

function splitExportPresetPath(path)
  local si,_ = string.find(path, "Export Presets")
  local p = string.sub(path, si, string.len(path))

  return p
end