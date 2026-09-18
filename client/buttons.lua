Buttons = {}

local movie

function Buttons.load()
    movie = lib.requestScaleformMovie('instructional_buttons', 3000)
end

function Buttons.set(rows)
    if not movie then return end
    BeginScaleformMovieMethod(movie, 'CLEAR_ALL')
    EndScaleformMovieMethod()

    for slot, row in ipairs(rows) do
        BeginScaleformMovieMethod(movie, 'SET_DATA_SLOT')
        ScaleformMovieMethodAddParamInt(slot - 1)
        for i = #row.controls, 1, -1 do
            ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(0, row.controls[i], true))
        end
        BeginTextCommandScaleformString('STRING')
        AddTextComponentSubstringPlayerName(row.label)
        EndTextCommandScaleformString()
        EndScaleformMovieMethod()
    end

    BeginScaleformMovieMethod(movie, 'SET_BACKGROUND_COLOUR')
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(80)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(movie, 'DRAW_INSTRUCTIONAL_BUTTONS')
    EndScaleformMovieMethod()
end

function Buttons.draw()
    if movie then DrawScaleformMovieFullscreen(movie, 255, 255, 255, 255, 0) end
end

function Buttons.release()
    if not movie then return end
    SetScaleformMovieAsNoLongerNeeded(movie)
    movie = nil
end
