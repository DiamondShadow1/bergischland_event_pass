fx_version "cerulean"
game "gta5"

author "Bergischland"
description "Bergischland Monthly Event Pass"
version "1.0.0"

ui_page "index.html"
files { "index.html", "style.css", "script.js", "bergischland-logo.png" }
shared_script "config.lua"
client_script "client.lua"
server_script "@oxmysql/lib/MySQL.lua"
server_script "server.lua"
dependency "es_extended"
dependency "oxmysql"