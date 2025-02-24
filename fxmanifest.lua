--[[ FX Information ]]--
fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54        'yes'
game         'gta5'

--[[ Resource Information ]]--
name         'maestro_stickynotes'
version      '1.0.0'
license      'GPL-3.0-or-later'
author       'MaestroAbi'
repository   'https://github.com/MaestroAbi/maestro_stickynotes'

dependencies {
	'oxmysql',
	'ox_lib',
    'ox_inventory',
    'ox_target',
}

shared_scripts {
	'@ox_lib/init.lua',
}

client_scripts {
	'client/main.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua',
}

-- ox_libs {
--     'table',
-- }