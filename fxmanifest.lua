fx_version 'adamant'
games { 'gta5' }

description 'A Custom Made Admin Tool For Fivem Servers'
ui_page 'ui/index.html'

client_scripts {
	'client/*.lua',
	'config.lua'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'server/*.lua',
	'config.lua'
}

files {
    'ui/index.html',
    'ui/styles.css'
}