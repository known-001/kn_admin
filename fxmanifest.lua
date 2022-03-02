fx_version 'adamant'
games { 'gta5' }

description 'Admin tool for ES'
ui_page 'ui/index.html'

client_scripts {
	'client/client.lua',
	'client/noclip.js',
	'config.lua'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'server/server.lua',
	'config.lua'
}

files {
    'ui/index.html',
    'ui/styles.css',
	'client/noclip.js'
}

export 'IsEnabled'
export 'SetEnabled'

export 'IsFrozen'
export 'SetFrozen'

export 'GetFov'
export 'SetFov'

export 'GetTarget'

export 'GetPosition'
export 'SetPosition'

export 'GetRotation'
export 'SetRotation'

export 'GetPitch'
export 'GetRoll'
export 'GetYaw'