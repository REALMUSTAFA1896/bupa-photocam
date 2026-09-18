local UPDATES = {
    Enabled = true,
    Repo    = 'BUPA-SCRIPT/bupa-updates',
    Branch  = 'main',
    Script  = 'bupa-photocam',
    News    = true,
    Delay   = 8000,
}

local TAG = '[bupa-photocam]'

local function rawUrl(file)
    return ('https://raw.githubusercontent.com/%s/%s/%s'):format(UPDATES.Repo, UPDATES.Branch, file)
end

local function parseVersion(v)
    if type(v) ~= 'string' then return nil end
    local parts = {}
    for num in v:gmatch('%d+') do parts[#parts + 1] = tonumber(num) end
    return #parts > 0 and parts or nil
end

local function isNewer(current, latest)
    local c, l = parseVersion(current), parseVersion(latest)
    if not c or not l then return false end
    for i = 1, math.max(#c, #l) do
        local a, b = c[i] or 0, l[i] or 0
        if b > a then return true end
        if b < a then return false end
    end
    return false
end

local function checkVersion()
    if not UPDATES.Enabled then return end
    if type(UPDATES.Repo) ~= 'string' or UPDATES.Repo:find('YOUR_GITHUB_USER') then
        print(('^3%s^7 Update hub not configured (UPDATES.Repo).^0'):format(TAG))
        return
    end

    local resource = GetCurrentResourceName()
    local current  = GetResourceMetadata(resource, 'version', 0) or '0.0.0'

    PerformHttpRequest(rawUrl(UPDATES.Script .. '.json'), function(status, body)
        if status ~= 200 or type(body) ~= 'string' then
            print(('^3%s^7 Version check failed (HTTP %s).^0'):format(TAG, tostring(status)))
            return
        end

        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= 'table' or type(data.version) ~= 'string' then
            print(('^3%s^7 Version check: could not read the hub file.^0'):format(TAG))
            return
        end

        if isNewer(current, data.version) then
            local download = (type(data.download) == 'string' and data.download ~= '')
                and data.download
                or ('https://portal.cfx.re/assets/granted-assets?search=' .. UPDATES.Script)

            print('^1========================================^7')
            print(('^1  %s UPDATE AVAILABLE^7'):format(TAG))
            print(('^7  Installed: ^1%s^7  ->  Latest: ^2%s^7'):format(current, data.version))
            print(('^7  Download:  ^5%s^7'):format(download))

            local changelog = data.changelog
            if type(changelog) == 'string' then changelog = { changelog } end
            if type(changelog) == 'table' and #changelog > 0 then
                print('^7  ----------------------------------------^7')
                print('^7  What\'s new:^7')
                for i = 1, math.min(#changelog, 20) do
                    print(('^7    - %s^7'):format(tostring(changelog[i])))
                end
            end
            print('^1========================================^7')
        else
            print(('^2%s^7 Up to date (^2v%s^7).^0'):format(TAG, current))
        end
    end, 'GET', '', { ['User-Agent'] = UPDATES.Script })
end

local function checkNews()
    if not (UPDATES.Enabled and UPDATES.News) then return end
    if type(UPDATES.Repo) ~= 'string' or UPDATES.Repo:find('YOUR_GITHUB_USER') then return end

    PerformHttpRequest(rawUrl('news.txt'), function(status, body)
        if status ~= 200 or type(body) ~= 'string' or body:gsub('%s', '') == '' then return end
        if GlobalState.bupaNewsShown then return end
        GlobalState:set('bupaNewsShown', true, false)
        print('^4========================================^7')
        print('^4  BUPA ^7- ^6NEWS^7')
        print('^4========================================^7')
        local lines = 0
        for line in (body .. '\n'):gmatch('(.-)\r?\n') do
            print(('^7  %s^7'):format(line))
            lines = lines + 1
            if lines >= 40 then break end
        end
        print('^4========================================^7')
    end, 'GET', '', { ['User-Agent'] = UPDATES.Script })
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    local version = GetResourceMetadata(res, 'version', 0) or '?'
    print('^5========================================^7')
    print('^5  BUPA ^7- ^2photocam^7 v' .. version)
    print('^7  Free camera photo mode')
    print(('^7  Language: ^3%s^7'):format(tostring(Config.Locale)))
    print('^5========================================^7')

    CreateThread(function()
        Wait(UPDATES.Delay)
        checkVersion()
        Wait(1500)
        checkNews()
    end)
end)
