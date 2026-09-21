# Bergischland Monthly Event Pass – FiveM Resource

## Enthalten
- `index.html` – Einstiegspunkt der NUI
- `style.css` – komplette Oberfläche
- `script.js` – NUI-Logik und Kommunikation mit Lua
- `client.lua` – F11, NUI-Fokus und NUI-Callbacks
- `server.lua` – serverseitige Prüfung und Speicherung
- `fxmanifest.lua` – FiveM Resource-Manifest
- `config.lua` – ESX-/ox_inventory-Konfiguration
- `bergischland-logo.png` – Event-Logo

## Wichtig
Die Resource speichert Coins, Passstufe, Tagesfortschritt und Erfolge serverseitig in `player_data.json`. Die NUI besitzt keinen lokalen Spielfortschritt und kann Coins oder Stufen nicht selbst setzen.

## Installation

1. Den Ordner als `bergischland_event_pass` in den `resources`-Ordner kopieren.
2. `es_extended` vor dieser Resource starten und in `server.cfg` eintragen: `ensure bergischland_event_pass`.
3. Admin-Berechtigung setzen, zum Beispiel:

```cfg
add_ace group.admin bergischland.eventadmin allow
```

Normale Spieler öffnen das Event mit `F11`. Admins öffnen es zusätzlich mit `/bergischlandevent`. `ESC` schließt die NUI.

## ESX und ox_inventory

Die Resource nutzt ESX für die Gruppenerkennung (`admin` und `superadmin`) und ACE bleibt als zusätzliche Berechtigung aktiv. `ox_inventory` ist optional für Item-Belohnungen. In [config.lua](config.lua) können `Config.DailyRewardItem` und `Config.PassRewardItems` gesetzt werden. Ohne diese Einträge werden nur die eigenen Event-Coins vergeben.

Aktive Jobzeit wird automatisch über den aktuellen ESX-Job erkannt. Standardmäßig gibt `Config.JobRewardItem = "event_coins"` nach jeder vollen Stunde `Config.JobRewardAmount = 10` Items über `ox_inventory`. Mit `Config.JobNames = { mechanic = true }` kann die Belohnung auf bestimmte Jobs begrenzt werden; eine leere Tabelle zählt jeden aktiven Job außer `unemployed`. Jobscreator muss den Job über ESX setzen, eine direkte Jobscreator-API ist dafür nicht erforderlich.

Der Item-Eintrag in `ox_inventory/data/items.lua` muss zum Beispiel so aussehen:

```lua
['event_coins'] = {
	label = 'Event-coins',
	weight = 1,
	stack = true,
},
```

## Anbindung an andere Scripts

Event-Coins können ausschließlich serverseitig vergeben werden:

```lua
exports.bergischland_event_pass:AddEventCoins(source, 100)
```

Erfolge werden ebenfalls serverseitig freigeschaltet:

```lua
exports.bergischland_event_pass:UnlockEventAchievement(source, 1)
```

Der Tagesbonus kann nach Ablauf von 24 Stunden abgeholt werden. Spieler werden über ihre `license:`-Identifier erkannt. Für produktive Server mit mehreren Instanzen oder hoher Auslastung sollte `player_data.json` später durch eine SQL-Tabelle, zum Beispiel via oxmysql, ersetzt werden.

Es gibt bewusst keinerlei Echtgeld-, Shop- oder Zahlungsfunktion.
