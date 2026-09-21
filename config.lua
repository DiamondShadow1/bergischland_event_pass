Config = {}

Config.Framework = "esx"
Config.Inventory = "ox_inventory"
Config.AdminGroups = { admin = true, superadmin = true }

-- Jobzeit-Belohnung. Eine leere Jobliste bedeutet: jeder aktive ESX-Job.
Config.JobRewardItem = "event_coins"
Config.JobRewardAmount = 10
Config.JobRewardInterval = 3600
Config.JobNames = {}

-- Leer lassen, wenn Tagesbelohnungen nur Event-Coins geben sollen.
Config.DailyRewardItem = nil
Config.DailyRewardItemAmount = 1

-- Optional: [Passstufe] = { item = "item_name", amount = 1 }
Config.PassRewardItems = {}