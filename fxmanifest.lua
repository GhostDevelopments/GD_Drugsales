fx_version 'cerulean'
game 'gta5'

author 'Ghost Developments'
description 'Sell Drugs w/ Ox_Lib'
lua54 'yes'
version '2.0'

shared_script '@ox_lib/init.lua'

client_scripts{
    'config.lua',
    'client.lua',
}

server_scripts{
    'config.lua',
    'server.lua',
}

