Config              = {}

Config.Duty = {
    requireAll = false, -- if true makes the player press the duty button with the vest on before being able to do duty actions
    --Ignore if false/ If true watch this video
    -- If true the admin can only do the action whilst on duty by clicking the duty button
    ban = false,
    kick = false,
    screenshot = false,
    bring = true,
    ["goto"] = true,
    heal = true,
    slay = true,
    spectate = true,
    freeze = true,
    repairCar = true,
    noclip = true
}

-- This uses esx perms or player ace perms
-- add_principal identifier.steam:1100001096a1e35 group.admin

-- 1st one is the ESX Group | 2nd One is player ace
Config.Admin = {
    ban = {'admin', 'group.admin'},
    kick = {'admin', 'group.admin'},
    screenshot = {'admin', 'group.admin'},
    bring = {'admin', 'group.admin'},
    ["goto"] = {'admin', 'group.admin'},
    heal = {'admin', 'group.admin'},
    slay = {'superdmin', 'group.admin'},
    spectate = {'admin', 'group.admin'},
    freeze = {'admin', 'group.admin'},
}

Config.Kickwebhook  = "" -- kick webhook

Config.Banwebhook  = "" -- Ban webhook

Config.Screenshotwebhook = "" -- webhhok for forced screenshot

Config.Screenshot = {
    webhook = '', -- But webhook here
    title = 'Admin Panel', -- This is the title of the embed
    message = 'This is a test message', -- This is the message on the embed of the photo
    name = 'Bot' -- This is the name of the bot sending the message
}
