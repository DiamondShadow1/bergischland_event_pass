Config = {}

Config.Framework = "esx"
Config.Inventory = "ox_inventory"
Config.AdminGroups = { admin = true, superadmin = true }

-- Leer lassen, wenn Tagesbelohnungen nur Event-Coins geben sollen.
Config.DailyRewardItem = nil
Config.DailyRewardItemAmount = 1

-- Optional: [Passstufe] = { item = "item_name", amount = 1 }
Config.PassRewardItems = {}