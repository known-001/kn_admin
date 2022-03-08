# KN Admin

## Description

This panel is a advanced fivem admin panel with fully custom functions and code.
The code is optimized and ready for any servers with One Sync.

#### Features

* Banning, Kicking, Warning
* Has duty option where people have to be wearing the admin vest to complete admin actions
* Screenshots with advanced webhook
* Draw ids on player with one button
* Built in noclip
* 0.0MS on idle
* Rebindable keys for opening and no clip
* Can unban from the panel
* Searching of players
* Built in spectate function

#### Planned Updates

* Adding offline baning
* Creating Anti Cheat
* Building in report feature using /report

#### Preview

WIP

### Config

```
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

```

#### Requirements

* MySql
* ESX v1.2 or below

### Enjoy
#### if you have any issues please PM me on the cfx fourms or discord

### Download & Instalation

#### Using GIT

```sh
cd resources
git clone https://github.com/known-001/kn_admin/
```

#### Manualy

- Download <https://github.com/known-001/kn_admin/>
- Put it in the resources repository

### Instalation

- Add `start kn_admin` to your server.cfg

Enjoy!
Kn Dev Team 

## Legal

### License

- GNU License GPL V3.0
