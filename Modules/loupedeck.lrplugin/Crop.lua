local LrDevelopController   = import 'LrDevelopController'

-- Logger
local LrLogger            = import 'LrLogger'
local logger              = LrLogger('loupedeckPlugin')


function toggleCrop(value)
  if value == "ResetCrop" then
    LrDevelopController.resetCrop()
    return
  end

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

--
function doPresetCrop(value)
  local height = CurrentPhoto.photo:getRawMetadata("height")
  local width = CurrentPhoto.photo:getRawMetadata("width")

  local cropAngle = LrDevelopController.getValue("CropAngle")

  local cropTop = LrDevelopController.getValue("CropTop") --0
  local cropBottom = LrDevelopController.getValue("CropBottom") --1
  local cropRight = LrDevelopController.getValue("CropRight") --1
  local cropLeft = LrDevelopController.getValue("CropLeft") --0)


  local k1 = math.tan(cropAngle*2*math.pi/360)
  local k2 = math.tan((-90+cropAngle)*2*math.pi/360)

  local a = width*cropLeft
  local b = height*cropTop
  local c = width*cropRight
  local d = height*cropBottom

  local x0_1 = b-k1*a
  local x0_2 = d-k2*c

  local newx = (x0_1-x0_2)/(k2-k1)
  local newy = k1*newx+x0_1

  local oldw = math.sqrt((newx-a)^2+(newy-b)^2)
  local oldh = math.sqrt((newx-c)^2+(newy-d)^2)

  if oldh < 10 or oldw < 10 then
    return
  end

  local hstep = 1/height
  local wstep = 1/width

  -- If aspect ratio is already correct, do nothing
  local limit = 0.00001

  if oldw > oldh then
    if value == "1" then --1x1
      if math.abs(oldw - oldh) < limit then return end
    elseif value == "2" then --2x3
      if math.abs(oldw - 3/2*oldh) < limit then return end
    elseif value == "3" then --3x4
      if math.abs(oldw - 4/3*oldh) < limit then return end
    elseif value == "4" then --4x5/8x10
      if math.abs(oldw - 5/4*oldh) < limit then return end
    elseif value == "5" then --5x7
      if math.abs(oldw - 7/5*oldh) < limit then return end
    elseif value == "6" then --16x9
      if math.abs(oldw - 16/9*oldh) < limit then return end
    elseif value == "7" then --16x10
      if math.abs(oldw - 16/10*oldh) < limit then return end
    elseif value == "8" then --8.5x11
      if math.abs(oldw - 11/8.5*oldh) < limit then return end
    end
  else
    if value == "1" then --1x1
      if math.abs(oldw - oldh) < limit then return end
    elseif value == "2" then --2x3
      if math.abs(oldh - 3/2*oldw) < limit then return end
    elseif value == "3" then --3x4
      if math.abs(oldh - 4/3*oldw) < limit then return end
    elseif value == "4" then --4x5/8x10
      if math.abs(oldh - 5/4*oldw) < limit then return end
    elseif value == "5" then --5x7
      if math.abs(oldh - 7/5*oldw) < limit then return end
    elseif value == "6" then --16x9
      if math.abs(oldh - 16/9*oldw) < limit then return end
    elseif value == "7" then --16x10
      if math.abs(oldh - 16/10*oldw) < limit then return end
    elseif value == "8" then --8.5x11
      if math.abs(oldh - 11/8.5*oldw)< limit then return end
    end
  end

  local dif
  local dir = 1
  if oldw > oldh then
    if value == "1" then --1x1
      dif = (oldw-oldh)/2
    elseif value == "2" then --2x3
      if oldw < 3/2*oldh then 
        dif = (oldh-oldw/3*2)/2 
        dir = -1
      else
        dif = (oldw-oldh/2*3)/2
        dir = 1
     end
    elseif value == "3" then --3x4
      if oldw < 4/3*oldh then
        dif = (oldh-oldw/4*3)/2 
        dir = -1
      else
        dif = (oldw-oldh/3*4)/2
        dir = 1
      end
    elseif value == "4" then --4x5/8x10
      if oldw < 5/4*oldh then
        dif = (oldh-oldw/5*4)/2 
        dir = -1
      else 
        dif = (oldw-oldh/4*5)/2
        dir = 1
      end
    elseif value == "5" then --5x7
      if oldw < 7/5*oldh then 
        dif = (oldh-oldw/7*5)/2 
        dir = -1
      else
        dif = (oldw-oldh/5*7)/2
        dir = 1
      end
    elseif value == "6" then --16x9
      if oldw < 16/9*oldh then 
        dif = (oldh-oldw/16*9)/2 
        dir = -1
      else
        dif = (oldw-oldh/9*16)/2
        dir = 1
      end
    elseif value == "7" then --16x10
      if oldw < 16/10*oldh then 
        dif = (oldh-oldw/16*10)/2 
        dir = -1
      else 
        dif = (oldw-oldh/10*16)/2
        dir = 1
      end
    elseif value == "8" then --8.5x11
      if oldw < 11/8.5*oldh then
        dif = (oldh-oldw/11*8.5)/2 
        dir = -1
      else
        dif = (oldw-oldh/8.5*11)/2
        dir = 1
      end
    end

    if dir == 1 then
      if cropAngle < 0 then
        cropAngle = -cropAngle

        LrDevelopController.setValue("CropRight", cropRight-dif*math.cos(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropLeft", cropLeft+dif*math.cos(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropBottom", cropBottom+dif*math.sin(cropAngle*2*math.pi/360)*hstep)
        LrDevelopController.setValue("CropTop", cropTop-dif*math.sin(cropAngle*2*math.pi/360)*hstep)
      else
        LrDevelopController.setValue("CropRight", cropRight-dif*math.cos(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropLeft", cropLeft+dif*math.cos(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropBottom", cropBottom-dif*math.sin(cropAngle*2*math.pi/360)*hstep)
        LrDevelopController.setValue("CropTop", cropTop+dif*math.sin(cropAngle*2*math.pi/360)*hstep)
      end
    else
      if cropAngle < 0 then
        cropAngle = -cropAngle

        LrDevelopController.setValue("CropRight", cropRight-dif*math.sin(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropLeft", cropLeft+dif*math.sin(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropBottom", cropBottom-dif*math.cos(cropAngle*2*math.pi/360)*hstep)
        LrDevelopController.setValue("CropTop", cropTop+dif*math.cos(cropAngle*2*math.pi/360)*hstep)
      else
        LrDevelopController.setValue("CropRight", cropRight+dif*math.sin(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropLeft", cropLeft-dif*math.sin(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropBottom", cropBottom-dif*math.cos(cropAngle*2*math.pi/360)*hstep)
        LrDevelopController.setValue("CropTop", cropTop+dif*math.cos(cropAngle*2*math.pi/360)*hstep)
      end
    end

  else
    if value == "1" then --1x1
      dif = (oldh-oldw)/2
    elseif value == "2" then --2x3
      if oldh < 3/2*oldh then 
        dif = (oldw-oldh/3*2)/2 
        dir = -1
      else
        dif = (oldh-oldw/2*3)/2
        dir = 1
     end
    elseif value == "3" then --3x4
      if oldh < 4/3*oldh then
        dif = (oldw-oldh/4*3)/2 
        dir = -1
      else
        dif = (oldh-oldw/3*4)/2
        dir = 1
      end
    elseif value == "4" then --4x5/8x10
      if oldh < 5/4*oldh then
        dif = (oldw-oldh/5*4)/2 
        dir = -1
      else 
        dif = (oldh-oldw/4*5)/2
        dir = 1
      end
    elseif value == "5" then --5x7
      if oldh < 7/5*oldh then 
        dif = (oldw-oldh/7*5)/2 
        dir = -1
      else
        dif = (oldh-oldw/5*7)/2
        dir = 1
      end
    elseif value == "6" then --16x9
      if oldh < 16/9*oldh then 
        dif = (oldw-oldh/16*9)/2 
        dir = -1
      else
        dif = (oldh-oldw/9*16)/2
        dir = 1
      end
    elseif value == "7" then --16x10
      if oldh < 16/10*oldh then 
        dif = (oldw-oldh/16*10)/2 
        dir = -1
      else 
        dif = (oldh-oldw/10*16)/2
        dir = 1
      end
    elseif value == "8" then --8.5x11
      if oldh < 11/8.5*oldh then
        dif = (oldw-oldh/11*8.5)/2 
        dir = -1
      else
        dif = (oldh-oldw/8.5*11)/2
        dir = 1
      end
    end

    if dir == 1 then
      if cropAngle < 0 then
        cropAngle = -cropAngle

        LrDevelopController.setValue("CropRight", cropRight-dif*math.cos(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropLeft", cropLeft+dif*math.cos(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropBottom", cropBottom-dif*math.sin(cropAngle*2*math.pi/360)*hstep)
        LrDevelopController.setValue("CropTop", cropTop+dif*math.sin(cropAngle*2*math.pi/360)*hstep)
      else
        LrDevelopController.setValue("CropRight", cropRight+dif*math.cos(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropLeft", cropLeft-dif*math.cos(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropBottom", cropBottom+dif*math.sin(cropAngle*2*math.pi/360)*hstep)
        LrDevelopController.setValue("CropTop", cropTop-dif*math.sin(cropAngle*2*math.pi/360)*hstep)
      end
    else      
      if cropAngle < 0 then
        cropAngle = -cropAngle

        LrDevelopController.setValue("CropRight", cropRight-dif*math.sin(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropLeft", cropLeft+dif*math.sin(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropBottom", cropBottom-dif*math.cos(cropAngle*2*math.pi/360)*hstep)
        LrDevelopController.setValue("CropTop", cropTop+dif*math.cos(cropAngle*2*math.pi/360)*hstep)
      else
        LrDevelopController.setValue("CropRight", cropRight+dif*math.sin(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropLeft", cropLeft-dif*math.sin(cropAngle*2*math.pi/360)*wstep)
        LrDevelopController.setValue("CropBottom", cropBottom-dif*math.cos(cropAngle*2*math.pi/360)*hstep)
        LrDevelopController.setValue("CropTop", cropTop+dif*math.cos(cropAngle*2*math.pi/360)*hstep)
      end
    end 
  end
  local cropTop2 = LrDevelopController.getValue("CropTop") --0
  local cropBottom2 = LrDevelopController.getValue("CropBottom") --1
  local cropRight2 = LrDevelopController.getValue("CropRight") --1
  local cropLeft2 = LrDevelopController.getValue("CropLeft") --0

end

function adjustCrop(value)
  local height = CurrentPhoto.photo:getRawMetadata("height")
  local width = CurrentPhoto.photo:getRawMetadata("width")

  local speed = width > 2000 and 6 or 2

  local cropTop = LrDevelopController.getValue("CropTop") --0
  local cropBottom = LrDevelopController.getValue("CropBottom") --1
  local cropRight = LrDevelopController.getValue("CropRight") --1
  local cropLeft = LrDevelopController.getValue("CropLeft") --0

  local hstep = speed/height
  local oldh = height * (1-(cropTop + (1 - cropBottom)))
  local oldw = width * (1-(cropLeft + (1 - cropRight)))
  local aspect = oldh / oldw

  local wstep = ((oldh + speed) * oldw / oldh - oldw)/width

  hstep = hstep/2
  wstep = wstep/2

  if tonumber(value) < 0 then
    if oldw < 100 or oldh < 100 then
      return
    elseif (cropRight-cropLeft <= 2*wstep and LrDevelopController.getValue("CropAngle") ~= 45) or (cropBottom-cropTop <= 2*hstep and LrDevelopController.getValue("CropAngle") ~= -45) then
      return
    end
  else
    if (cropTop-hstep < 0 and cropBottom+hstep > 1) or (cropLeft-wstep < 0 and cropRight+wstep > 1) then
      return
    elseif cropTop-hstep < 0 and cropRight+wstep > 1 then
      LrDevelopController.setValue("CropBottom",cropBottom+value*hstep)
      LrDevelopController.setValue("CropLeft",cropLeft-value*wstep)
      return
    elseif cropRight+wstep > 1 and cropBottom+hstep > 1 then
      LrDevelopController.setValue("CropTop",cropTop-value*hstep)
      LrDevelopController.setValue("CropLeft",cropLeft-value*wstep)
      return
    elseif cropBottom+hstep > 1 and cropLeft-wstep < 0 then
      LrDevelopController.setValue("CropTop",cropTop-value*hstep)
      LrDevelopController.setValue("CropRight",cropRight+value*wstep)
      return
    elseif cropLeft-wstep < 0 and cropTop-hstep < 0 then
      LrDevelopController.setValue("CropBottom",cropBottom+value*hstep)
      LrDevelopController.setValue("CropRight",cropRight+value*wstep)
      return
    elseif cropTop-hstep < 0 then
      LrDevelopController.setValue("CropBottom",cropBottom+2*value*hstep)
      LrDevelopController.setValue("CropRight",cropRight+value*wstep)
      LrDevelopController.setValue("CropLeft",cropLeft-value*wstep)
      return
    elseif cropLeft-wstep < 0 then
      LrDevelopController.setValue("CropTop",cropTop-value*hstep)
      LrDevelopController.setValue("CropBottom",cropBottom+value*hstep)
      LrDevelopController.setValue("CropRight",cropRight+2*value*wstep)
      return
    elseif cropBottom+hstep > 1 then
        LrDevelopController.setValue("CropTop",cropTop-2*value*hstep)
        LrDevelopController.setValue("CropRight",cropRight+value*wstep)
        LrDevelopController.setValue("CropLeft",cropLeft-value*wstep)
        return
    elseif cropRight+wstep > 1 then
      LrDevelopController.setValue("CropTop",cropTop-value*hstep)
      LrDevelopController.setValue("CropBottom",cropBottom+value*hstep)
      LrDevelopController.setValue("CropLeft",cropLeft-2*value*wstep)
      return
    end
  end

  LrDevelopController.setValue("CropTop",cropTop-value*hstep)
  LrDevelopController.setValue("CropBottom",cropBottom+value*hstep)
  LrDevelopController.setValue("CropRight",cropRight+value*wstep)
  LrDevelopController.setValue("CropLeft",cropLeft-value*wstep)

end