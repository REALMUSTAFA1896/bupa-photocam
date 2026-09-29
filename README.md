# bupa-photocam

A free camera for taking screenshots in FiveM. Hold `V`, the HUD goes away and you get a camera you can fly around your character, tilt, zoom and put a focus point on. Press `Esc` and you're back where you were, same camera view as before.

<!-- drag bupa-photocam-showcase.mp4 onto this line in the GitHub editor -->

It does not take the picture for you. Frame the shot, then press whatever you normally screenshot with — F12 on Steam, Win+Shift+S, ShareX, anything.

## Controls

Hold `V` for a moment to open it. A quick tap still switches the camera view like it always did.

| Key | Does |
| --- | --- |
| `W` `A` `S` `D` | Move |
| `E` / `Q` | Up / down |
| `Left Shift` / `Left Ctrl` | Faster / slower |
| Mouse | Look around |
| Mouse wheel | Zoom, 15° to 90° |
| `Z` / `C` | Tilt left / right |
| `X` | Level the camera again |
| `F` | Depth of field on / off |
| `↑` / `↓` | Move the focus point further / closer |
| `←` / `→` | Change filter |
| `G` | Rule-of-thirds grid |
| `H` | Hide your character |
| `Backspace` | Hide the controls bar, for a clean shot |
| `Esc` or `V` again | Close |

`V` is a normal FiveM key binding, so every player can move it under **Settings → Key Bindings → FiveM**. Push to talk keeps working while the camera is open.

## How it behaves

- The camera stays within 20 m of your character. From 14 m out the picture starts to blur, so you can't use it to look through the other side of the map.
- It doesn't go through walls or the ground.
- It won't open while you're dead, cuffed, ragdolling, falling, aiming, shooting, in the pause menu or in a vehicle. It closes on its own if you die, ragdoll or get into a car.
- Filters are GTA's own timecycles: None, Cinematic, Warm, Cold, Vintage, Vivid, Noir and Mono. With no filter picked, a screen effect another script already put on you — drunk, drugs, whatever — stays as it is.

## Installation

Needs [ox_lib](https://github.com/overextended/ox_lib).

```cfg
ensure ox_lib
ensure bupa-photocam
```

That's it. No database, no items.

## Configuration

Everything is in `config.lua`.

| Setting | Default | |
| --- | --- | --- |
| `Config.Locale` | `'en'` | `en`, `tr`, `de`, `es`, `fr`, `pt`, `ru` |
| `Config.Key` | `'V'` | Default key. Players can rebind it |
| `Config.HoldTime` | `600` | How long to hold, in ms |
| `Config.MaxDistance` | `20.0` | How far from your character the camera can go |
| `Config.BlurStart` | `0.7` | Share of that distance where the blur starts |
| `Config.Speed` | `4.0` | Movement speed. `FastMultiplier` and `SlowMultiplier` scale it |
| `Config.Fov` | 15°–90°, step 5° | Zoom limits. It opens at whatever your normal camera was using; `default` is the zoom mouse sensitivity is tuned for |
| `Config.Focus` | 5 m, 0.5–50 m | Depth of field range |
| `Config.AllowInVehicle` | `false` | Let players open it from a car |
| `Config.PushToTalk` | `249` | Control left working for voice. Change it if your voice resource uses a different one |
| `Config.Filters` | 8 filters | Add or remove timecycle modifiers. The first one is "no filter" |
| `Config.Controls` | | Every key above, as FiveM control ids |

### Blocking it from your own scripts

`Config.CanOpen` runs every time someone tries to open the camera. Return `false` to refuse:

```lua
Config.CanOpen = function()
    return not LocalPlayer.state.invBusy
end
```

## Exports

Client side.

```lua
exports['bupa-photocam']:isActive()       -- true while the camera is open
exports['bupa-photocam']:close()          -- closes it
exports['bupa-photocam']:setDisabled(true) -- closes it and keeps it closed until you pass false
```

`setDisabled` is the one to call from a cutscene, a jail script or a character selector.

## Performance

Nothing runs until someone holds the key. While the camera is open everything happens on that player's own machine — there are no server events and no NUI page, the controls bar is GTA's own instructional buttons.

The only thing the server does is check the BUPA update hub on start and print a line to the console if there's a newer version.
