_addon.name = 'RollDistance'
_addon.version = '0.0.1'
_addon.author = 'Dean James (Xurion of Bismarck)'
_addon.commands = {'rolldistance','rd'}

config = require('config')
texts = require('texts')

defaults = {
    ui = {
        pos = {
            x = 0,
            y = 0
        },
        bg = {
            alpha = 150,
            blue = 0,
            green = 0,
            red = 0,
            visible = true
        },
        padding = 8,
        text = {
            font = 'Consolas',
            size = 10
        }
    },
    luzaf = true,
    interval = 1,
}

settings = config.load(defaults)

ui = texts.new(settings.ui, settings)

function pad_string(str, len)
    return str .. string.rep(' ', len - #str)
end

commands = {}

commands.luzaf = function()
    settings.luzaf = not settings.luzaf
    settings:save()
    windower.send_command('input /echo ' .. 'Roll distance is now ' .. tostring(settings.luzaf))
end
commands.l = commands.luzaf

commands.interval = function(args)
    settings.interval = tonumber(args[1])
    settings:save()
    coroutine.close(thread)
    update()
end
commands.i = commands.interval

windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'help'

    if commands[command] then
        commands[command]({...})
    else
        commands.helupdate()
    end
end)

function update_text()
    local group = windower.ffxi.get_party()
    local party = {}
    local max_name_length = 0
    for i = 1, 5 do
        party[i] = group['p' .. i]
        max_name_length = party[i] and #party[i].name > max_name_length and #party[i].name or max_name_length
    end

    if #party == 0 then
        ui:hide()
        return
    end

    local text = ''
    local all_in_range = true
    for _, party_member in ipairs(party) do
        local distance = party_member.mob and party_member.mob.distance and math.ceil(math.sqrt(party_member.mob.distance))
        local colour = "\\cs(0,255,0)" --green
        if settings.luzaf and distance >= 16 or not settings.luzaf and distance >= 8 then
            colour = "\\cs(255,255,255)" --white
            all_in_range = false
        end
        text = text .. pad_string(party_member.name, max_name_length) .. ' ' .. colour .. distance .. '\\cr\n'
    end
    if all_in_range then
        ui:bg_color(0, 75, 0)
    else
        ui:bg_color(0, 0, 0)
    end
    ui:text(text)
end

function update()
    print('in schedule', os.clock())
    thread = coroutine.schedule(p, settings.interval)
end

windower.register_event('load', function()
    if windower.ffxi.get_player() then
        update()
    end
end)

windower.register_event('login', function()
    update()
end)

windower.register_event('logout', function()
    coroutine.close(thread)
end)
