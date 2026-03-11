fx_version 'cerulean'
game 'gta5'

author 'Azuka'
description 'Base Script RageUI'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua', -- Pour les versions récentes d'ESX
    'config.lua'
}

client_scripts {
    'src/RageUI.lua',
    'src/Menu.lua',
    'src/MenuController.lua',
    'src/components/*.lua',
    'src/elements/*.lua',
    'src/items/*.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}