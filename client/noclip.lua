local INPUT_SPRINT = 21
local INPUT_CHARACTER_WHEEL = 19
local INPUT_LOOK_LR = 1
local INPUT_LOOK_UD = 2
local INPUT_COVER = 44
local INPUT_MULTIPLAYER_INFO = 20
local INPUT_MOVE_UD = 31
local INPUT_MOVE_LR = 30

--------------------------------------------------------------------------------

local _internal_camera = nil
local _internal_isFrozen = false

local _internal_pos = nil
local _internal_rot = nil
local _internal_fov = nil
local _internal_vecX = nil
local _internal_vecY = nil
local _internal_vecZ = nil

--------------------------------------------------------------------------------

local settings = {
  --Camera
  fov = 45.0,

  -- Mouse
  mouseSensitivityX = 5,
  mouseSensitivityY = 5,

  -- Movement
  normalMoveMultiplier = 1,
  fastMoveMultiplier = 10,
  slowMoveMultiplier = 0.1,

  -- On enable/disable
  enableEasing = true,
  easingDuration = 1000
}

--------------------------------------------------------------------------------

local function IsFreecamFrozen()
  return _internal_isFrozen
end

local function SetFreecamFrozen(frozen)
  local frozen = frozen == true
  _internal_isFrozen = frozen
end

--------------------------------------------------------------------------------

local function GetFreecamPosition()
  return _internal_pos
end

local function SetFreecamPosition(x, y, z)
  print(x,y,z)
  local pos = vector3(x, y, z)
  local int = GetInteriorAtCoords(pos)

  LoadInterior(int)
  SetFocusArea(pos)
  LockMinimapPosition(x, y)
  SetCamCoord(_internal_camera, pos)

  _internal_pos = pos
end

--------------------------------------------------------------------------------

local function GetFreecamRotation()
  return _internal_rot
end

local function SetFreecamRotation(x, y, z)
  local x = Clamp(x, -90.0, 90.0)
  local y = y % 360
  local z = z % 360
  local rot = vector3(x, y, z)
  local vecX, vecY, vecZ = EulerToMatrix(x, y, z)

  LockMinimapAngle(math.floor(z))
  SetCamRot(_internal_camera, rot)

  _internal_rot  = rot
  _internal_vecX = vecX
  _internal_vecY = vecY
  _internal_vecZ = vecZ
end

--------------------------------------------------------------------------------

local function GetFreecamFov()
  return _internal_fov
end

local function SetFreecamFov(fov)
  local fov = Clamp(fov, 0.0, 90.0)
  SetCamFov(_internal_camera, fov)
  _internal_fov = fov
end

--------------------------------------------------------------------------------

local function GetFreecamMatrix()
  return _internal_vecX,
         _internal_vecY,
         _internal_vecZ,
         _internal_pos
end

local function GetFreecamTarget(distance)
  local target = _internal_pos + (_internal_vecY * distance)
  return target
end

--------------------------------------------------------------------------------

local function IsFreecamEnabled()
  return IsCamActive(_internal_camera) == 1
end

local function SetFreecamEnabled(enable)
  if enable == IsFreecamEnabled() then
    return
  end

  if enable then
    local pos = GetGameplayCamCoord()
    local rot = GetGameplayCamRot()

    _internal_camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

    SetFreecamFov(settings.fov)
    SetFreecamPosition(pos.x, pos.y, pos.z)
    SetFreecamRotation(rot.x, rot.y, rot.z)
  else
    DestroyCam(_internal_camera)
    ClearFocus()
    UnlockMinimapPosition()
    UnlockMinimapAngle()
  end

  SetPlayerControl(PlayerId(), not enable)
  RenderScriptCams(enable, settings.enableEasing, settings.easingDuration)
end

--------------------------------------------------------------------------------

function IsEnabled()          return IsFreecamEnabled()                           end
function SetEnabled(enable)   return SetFreecamEnabled(enable)                    end
function IsFrozen()           return IsFreecamFrozen()                            end
function SetFrozen(frozen)    return SetFreecamFrozen(frozen)                     end
function GetFov()             return GetFreecamFov()                              end
function SetFov(fov)          return SetFreecamFov(fov)                           end
function GetTarget(distance)  return { table.unpack(GetFreecamTarget(distance)) } end
function GetPosition()        return { table.unpack(GetFreecamPosition()) }       end
function SetPosition(x, y, z) return SetFreecamPosition(x, y, z)                  end
function GetRotation()        return { table.unpack(GetFreecamRotation()) }       end
function SetRotation(x, y, z) return SetFreecamRotation(x, y, z)                  end
function GetPitch()           return GetFreecamRotation().x                       end
function GetRoll()            return GetFreecamRotation().y                       end
function GetYaw()             return GetFreecamRotation().z                       end

--------------------------------------------------------------------------------

Citizen.CreateThread(function()
  local function GetSpeedMultiplier()
    if IsDisabledControlPressed(0, INPUT_SPRINT) then
      return settings.fastMoveMultiplier
    elseif IsDisabledControlPressed(0, INPUT_CHARACTER_WHEEL) then
      return settings.slowMoveMultiplier
    end

    return settings.normalMoveMultiplier
  end

  local function CameraLoop()
    if not IsFreecamEnabled() or IsPauseMenuActive() then
      return
    end

    if not IsFreecamFrozen() then
      local vecX, vecY = GetFreecamMatrix()
      local vecZ = vector3(0, 0, 1)

      local pos = GetFreecamPosition()
      local rot = GetFreecamRotation()

      -- Get speed multiplier for movement
      local frameMultiplier = GetFrameTime() * 60
      local speedMultiplier = GetSpeedMultiplier() * frameMultiplier

      -- Get mouse input
      local mouseX = GetDisabledControlNormal(0, INPUT_LOOK_LR)
      local mouseY = GetDisabledControlNormal(0, INPUT_LOOK_UD)

      -- Get keyboard input
      local moveWS = GetDisabledControlNormal(0, INPUT_MOVE_UD)
      local moveAD = GetDisabledControlNormal(0, INPUT_MOVE_LR)
      local moveQZ = GetDisabledControlNormalBetween(0, INPUT_COVER, INPUT_MULTIPLAYER_INFO)

      -- Calculate new rotation.
      local rotX = rot.x + (-mouseY * settings.mouseSensitivityY)
      local rotZ = rot.z + (-mouseX * settings.mouseSensitivityX)
      local rotY = 0.0

      -- Adjust position relative to camera rotation.
      pos = pos + (vecX *  moveAD * speedMultiplier)
      pos = pos + (vecY * -moveWS * speedMultiplier)
      pos = pos + (vecZ *  moveQZ * speedMultiplier)

      -- Adjust new rotation
      rot = vector3(rotX, rotY, rotZ)

      -- Update camera
      SetFreecamPosition(pos.x, pos.y, pos.z)
      SetFreecamRotation(rot.x, rot.y, rot.z)
    end

    -- Trigger an update event. Resources depending on the freecam position can
    -- make use of this event.
    TriggerEvent('freecam:onFreecamUpdate')
  end

  while true do
    Citizen.Wait(0)
    CameraLoop()
  end
end)

function Clamp(x, min, max)
    return math.min(math.max(x, min), max)
  end
  
  function GetDisabledControlNormalBetween(inputGroup, control1, control2)
    local normal1 = GetDisabledControlNormal(inputGroup, control1)
    local normal2 = GetDisabledControlNormal(inputGroup, control2)
    return normal1 - normal2
  end
  
  function EulerToMatrix(rotX, rotY, rotZ)
    local radX = math.rad(rotX)
    local radY = math.rad(rotY)
    local radZ = math.rad(rotZ)
  
    local sinX = math.sin(radX)
    local sinY = math.sin(radY)
    local sinZ = math.sin(radZ)
    local cosX = math.cos(radX)
    local cosY = math.cos(radY)
    local cosZ = math.cos(radZ)
  
    local vecX = {}
    local vecY = {}
    local vecZ = {}
  
    vecX.x = cosY * cosZ
    vecX.y = cosY * sinZ
    vecX.z = -sinY
  
    vecY.x = cosZ * sinX * sinY - cosX * sinZ
    vecY.y = cosX * cosZ - sinX * sinY * sinZ
    vecY.z = cosY * sinX
  
    vecZ.x = -cosX * cosZ * sinY + sinX * sinZ
    vecZ.y = -cosZ * sinX + cosX * sinY * sinZ
    vecZ.z = cosX * cosY
  
    vecX = vector3(vecX.x, vecX.y, vecX.z)
    vecY = vector3(vecY.x, vecY.y, vecY.z)
    vecZ = vector3(vecZ.x, vecZ.y, vecZ.z)
  
    return vecX, vecY, vecZ
end
  
local noclipTarget = nil

RegisterNetEvent('kn:admin:noClip')
AddEventHandler('kn:admin:noClip', function()
    toggleNoclip()
end)

RegisterNetEvent('freecam:onFreecamUpdate')
AddEventHandler('freecam:onFreecamUpdate', function()
    local position = GetPosition()
    local rotation = GetRotation()

    if(noclipTarget)then
        SetEntityCoordsNoOffset(noclipTarget, position[0], position[1], position[2], false, false, false)
        SetEntityRotation(noclipTarget, rotation[0], rotation[1], rotation[2], 0, true)
    end
end)

function disableNoclip()
    SetEntityInvincible(noclipTarget, false)
    FreezeEntityPosition(noclipTarget, false)
    SetEntityCollision(noclipTarget, true, true)
    SetEntityVisible(noclipTarget, true, false)

    if(noclipTarget ~= PlayerPedId())then
        SetEntityVisible(PlayerPedId(), true, false)
    end

    noclipTarget = nil

    SetEnabled(false)
end

function enableNoclip()
    noclipTarget = PlayerPedId()

    if IsPedInAnyVehicle(noclipTarget) then
      noclipTarget = GetVehiclePedIsIn(noclipTarget, false)
    end

    if not NetworkHasControlOfEntity(noclipTarget) then
      noclipTarget = nil
      return
    end

    SetEntityInvincible(noclipTarget, true)
    FreezeEntityPosition(noclipTarget, true)
    SetEntityCollision(noclipTarget, false, false)
    SetEntityVisible(noclipTarget, false, false)

    if noclipTarget ~= PlayerPedId() then
      SetEntityVisible(PlayerPedId(), false, false)
    end

    local entityCoords = GetEntityCoords(noclipTarget)

    SetEnabled(true)
    SetPosition(entityCoords)
end

function toggleNoclip()
    if IsEnabled() then
        disableNoclip()
    else
        enableNoclip()
    end
end


--------------------------------------------------------------------------------

-- When the resource is stopped, make sure to return the camera to the player.
AddEventHandler('onResourceStop', function (resourceName)
  if resourceName == GetCurrentResourceName() then
    SetEnabled(false)
  end
end)
