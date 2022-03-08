Config              = {}

Config.Duty = {
    requireAll = true, -- if true makes the player press the duty button with the vest on before being able to do duty actions
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

Config.Kickwebhook  = "" -- kick webhook

Config.Banwebhook  = "" -- Ban webhook

Config.Screenshotwebhook = "" -- webhhok for forced screenshot

Config.Screenshot = {
    webhook = '', -- But webhook here
    title = 'Admin Panel', -- This is the title of the embed
    message = 'This is a test message', -- This is the message on the embed of the photo
    name = 'Bot' -- This is the name of the bot sending the message
}
