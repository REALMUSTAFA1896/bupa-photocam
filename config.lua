Config = {}

-- en, tr, de, es, fr, pt, ru
Config.Locale = 'en'

-- Players can rebind it in FiveM key settings. A short tap keeps the normal camera switch.
Config.Key = 'V'
Config.HoldTime = 600

-- Metres from the player. The picture starts to blur at BlurStart of the way out.
Config.MaxDistance = 20.0
Config.BlurStart = 0.7

Config.Speed = 4.0
Config.FastMultiplier = 3.0
Config.SlowMultiplier = 0.25
Config.MouseSensitivity = 8.0

Config.Fov = { default = 50.0, min = 15.0, max = 90.0, step = 5.0 }
Config.RollSpeed = 30.0

-- Depth of field focus distance in metres
Config.Focus = { default = 5.0, min = 0.5, max = 50.0, speed = 6.0 }

Config.AllowInVehicle = false

-- Voice key left working while the camera is open. 249 is the default push to
-- talk; change it if your voice resource uses another control.
Config.PushToTalk = 249

-- Return false to block the photo mode, e.g. while cuffed in your own police script
Config.CanOpen = function()
    return true
end

-- Timecycle modifiers, the first one is no filter
Config.Filters = {
    { label = 'filter_none', modifier = false },
    { label = 'filter_cinematic', modifier = 'NG_filmic02' },
    { label = 'filter_warm', modifier = 'NG_filmic05' },
    { label = 'filter_cold', modifier = 'NG_filmic13' },
    { label = 'filter_vintage', modifier = 'NG_filmic19' },
    { label = 'filter_vivid', modifier = 'NG_filmic11' },
    { label = 'filter_noir', modifier = 'NG_filmnoir_BW01' },
    { label = 'filter_mono', modifier = 'CAMERA_BW' },
}

-- Control ids from docs.fivem.net/docs/game-references/controls
Config.Controls = {
    up = 38,
    down = 44,
    fast = 21,
    slow = 36,
    zoomIn = 241,
    zoomOut = 242,
    rollLeft = 20,
    rollRight = 26,
    resetRoll = 73,
    prevFilter = 174,
    nextFilter = 175,
    focusNear = 173,
    focusFar = 172,
    toggleFocus = 23,
    toggleGrid = 47,
    togglePlayer = 74,
    toggleHelp = 194,
    exit = 200,
}
