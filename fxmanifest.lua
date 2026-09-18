fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'bupa-photocam'
author 'BUPA-SCRIPT'
description 'BUPA Photocam - free camera photo mode'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/buttons.lua',
    'client/main.lua',
}

server_scripts {
    'server/updates.lua',
}

files {
    'locales/*.json',
}

dependencies {
    'ox_lib',
}

escrow_ignore {
    'config.lua',
    'locales/*.json',
}
