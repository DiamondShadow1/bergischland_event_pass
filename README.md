# Bergischland Monthly Event Pass – FiveM Resource

Entwickelt von DiamondShadow1.

## Überblick

Dieses Script ist ein serverseitig validierter Event-Pass für FiveM mit ESX, ox_inventory und oxmysql. Der Client kann keine Belohnungen, Coins, XP, Level oder Rewards selbst vergeben oder freischalten. Alle wichtigen Änderungen werden serverseitig überprüft und in der SQL-Datenbank gespeichert.

## Enthalten

- `index.html` – NUI-Oberfläche
- `style.css` – Styling und responsives Layout
- `script.js` – UI-Rendering und NUI-Kommunikation
- `client.lua` – NUI-Öffnen/Schließen und Client-Requests
- `server.lua` – serverseitige Logik, Validierung und Persistenz
- `config.lua` – zentrale Konfiguration
- `fxmanifest.lua` – Resource-Manifest mit Abhängigkeiten
- `sql/bergischland_event_pass.sql` – SQL-Schema für `oxmysql`
- `docs/AUTHOR.md` – Autorendokumentation

## Wichtige Architektur

- Server entscheidet über Event-Coins, Level, Fortschritt und Belohnungen.
- Die NUI darf keine Entscheidung über Reward-Aktionen treffen.
- Die Daten werden in einer MySQL-Tabelle gespeichert, nicht in einer lokalen JSON-Datei.
- `oxmysql` ist als verbindliche Datenbanklösung eingebunden.

## Installation

1. Den Ordner als `bergischland_event_pass` in den `resources`-Ordner kopieren.
2. `es_extended`, `ox_inventory` und `oxmysql` entsprechend vorbereiten.
3. In der `server.cfg` sicherstellen:

```cfg
ensure es_extended
ensure oxmysql
ensure bergischland_event_pass
```

4. Das SQL-Schema aus `sql/bergischland_event_pass.sql` in die Datenbank importieren.
5. Optional Admin-Rechte setzen:

```cfg
add_ace group.admin bergischland.eventadmin allow
```

Normale Spieler öffnen das Event mit `F11`. Admins können das Event zusätzlich mit `/bergischlandevent` öffnen. `ESC` schließt die NUI.

## ESX, ox_inventory und SQL

Die Resource nutzt ESX für die Gruppen- und Job-Erkennung und `ox_inventory` für Item-Belohnungen. `oxmysql` speichert die Event-State-Daten in der Tabelle `bergischland_event_pass`.

Die wichtigsten Konfigurationen liegen in [config.lua](config.lua):

- `Config.Framework = "esx"`
- `Config.Inventory = "ox_inventory"`
- `Config.DatabaseTable = "bergischland_event_pass"`
- `Config.MaxPassLevel = 50`
- `Config.JobRewardItem`, `Config.JobRewardAmount`, `Config.JobRewardInterval`

Wenn `Config.DailyRewardItem` oder `Config.PassRewardItems` leer sind, werden nur die Event-Coins im Server-Tracking vergeben. Belohnungsitems werden nur serverseitig an Spieler verteilt.

## Server-Exports

Event-Coins können ausschließlich serverseitig vergeben werden:

```lua
exports.bergischland_event_pass:AddEventCoins(source, 100)
```

Erfolge werden ebenfalls serverseitig freigeschaltet:

```lua
exports.bergischland_event_pass:UnlockEventAchievement(source, 1)
```

Der Tagesbonus kann nach Ablauf von 24 Stunden abgeholt werden. Spieler werden über ihre `license:`-Identifier erkannt.

## Sicherheit und Fair Play

- Keine Client-seitige Reward-Logik
- Keine Manipulation der NUI als Quellen der Wahrheit
- Alle Rewards werden serverseitig validiert
- Keine Echtgeld-, Shop- oder Zahlungsfunktion 

## Autor

Dieses Script wurde entwickelt von DiamondShadow1.
