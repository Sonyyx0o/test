if _USERNAME then
    client.color_log(255, 255, 255, "Hello, " .. _USERNAME)
end
local ffi = require 'ffi'
local vector = require 'vector'
local inspect = require 'gamesense/inspect'

local client_screen_size, client_set_cvar, math_fmod, tonumber, ui_get, ui_new_slider, ui_set_callback, ui_set_visible = client.screen_size, client.set_cvar, math.fmod, tonumber, ui.get, ui.new_slider, ui.set_callback, ui.set_visible

local function set_aspect_ratio(aspect_ratio_multiplier)
	local screen_width, screen_height = client_screen_size()
	local aspectratio_value = (screen_width*aspect_ratio_multiplier)/screen_height
	if aspect_ratio_multiplier == 1 then
		aspectratio_value = 0
	end
	client_set_cvar("r_aspectratio", tonumber(aspectratio_value))
end

local function gcd(m, n)
	while m ~= 0 do
		m, n = math_fmod(n, m), m
	end
	return n
end

local screen_width, screen_height, aspect_ratio_reference

local function on_aspect_ratio_changed()
	local aspect_ratio = ui_get(aspect_ratio_reference)*0.01
	aspect_ratio = 2 - aspect_ratio
	set_aspect_ratio(aspect_ratio)
end

local multiplier = 0.01
local steps = 200

local function setup(screen_width_temp, screen_height_temp)
	screen_width, screen_height = screen_width_temp, screen_height_temp
	local aspect_ratio_table = {}
	for i=1, steps do
		local i2=(steps-i)*multiplier
		local divisor = gcd(screen_width*i2, screen_height)
		if screen_width*i2/divisor < 100 or i2 == 1 then
			aspect_ratio_table[i] = screen_width*i2/divisor .. ":" .. screen_height/divisor
		end
	end
	if aspect_ratio_reference ~= nil then
		ui_set_visible(aspect_ratio_reference, false)
		ui_set_callback(aspect_ratio_reference, function() end)
	end
	aspect_ratio_reference = ui_new_slider("LUA", "B", "Aspect ratio", 0, steps-1, steps/2, true, "%", 1, aspect_ratio_table)
	ui_set_callback(aspect_ratio_reference, on_aspect_ratio_changed)
end
setup(client_screen_size())

local function on_paint(ctx)
	local screen_width_temp, screen_height_temp = client_screen_size()
	if screen_width_temp ~= screen_width or screen_height_temp ~= screen_height then
		setup(screen_width_temp, screen_height_temp)
	end
end
client.set_event_callback("paint", on_paint)

local tpdistanceslider = ui_new_slider("LUA", "B", "Thirdperson Distance", 30, 200, 150)
local function tpdistance()
	client.exec("cam_idealdist ", ui_get(tpdistanceslider))
end
ui_set_callback(tpdistanceslider, tpdistance)

local issue_mode_enabled = ui.new_checkbox("LUA", "B", "Issue Mode")
ui.set(issue_mode_enabled, false)

local function setup_issue_mode()
    local ffi = require("ffi")
    local http = require("gamesense/http")
    local client_create_interface = client.create_interface
    local filesystem_interface = ffi.cast(ffi.typeof("void***"), client_create_interface("filesystem_stdio.dll", "VFileSystem017"))
    local filesystem_create_directories = ffi.cast("void (__thiscall*)(void*, const char*, const char*)", filesystem_interface[0][22])
    local filesystem_find = ffi.cast("const char* (__thiscall*)(void*, const char*, int*)", filesystem_interface[0][32])
    
    local function create_directories(file, path_id)
        filesystem_create_directories(filesystem_interface, file, path_id)
    end
    
    local exists = function(file)
        local int_ptr = ffi.new("int[1]")
        local res = filesystem_find(filesystem_interface, file, int_ptr)
        if res == ffi.NULL then
            return nil
        end
        return int_ptr, ffi.string(res)
    end
    
    local function download_res(name, file_path)
        http.get(("https://raw.githubusercontent.com/sdkmasteri/gamesense-crack-lua-repo/refs/heads/main/trash/%s"):format(name), function(status, response)
            if not status then
                return
            end
            writefile(file_path, response.body)
        end)
    end
    
    if not exists("materials/trash1") then create_directories("materials/trash1", "materials/trash1") end
    if not exists("sound/trash") then create_directories("sound/trash", "sound/trash") end
    
    for key, value in pairs({["iconic.png"] = "csgo/materials/trash1/iconic.png", ["bog.mp3"] = "csgo/sound/trash/bog.mp3"}) do
        if not readfile(value) then
            download_res(key, value)
        end
    end
    
    local vgui = ffi.cast(ffi.typeof("void***"), client_create_interface("vguimatsurface.dll", "VGUI_Surface031"))
    local playsound = ffi.cast("void(__thiscall*)(void*, const char*)", vgui[0][82])
    
    local init = false
    local again = false
    local alph = 255

    client.set_event_callback("paint", function()
        if not ui.get(issue_mode_enabled) then return end
        local a = renderer.load_png(readfile("csgo/materials/trash1/iconic.png"), 210, 278)
        local x, y = client.screen_size()
        if init then
            if again then
                alph = 255
                again = false
            end
            if alph == 0 then alph = 255 end
            renderer.texture(a, x*0.5 - 105, y*0.5 - 139, 210, 278, 255, 255, 255, alph)
            alph = math.floor(alph * 0.95)
            if alph == 0 then init = false end
        end
    end)
    
    client.set_event_callback("player_hurt", function(e)
        if not ui.get(issue_mode_enabled) then return end
        if client.userid_to_entindex(e.userid) == entity.get_local_player() then
            if init == true then
                again = true
                client.exec("stopsound")
            end
            init = true
            playsound(vgui, "trash/bog.mp3")
        end
    end)
end

local master_switch = ui.new_checkbox('LUA', 'B', 'Log aimbot shots')
local prefer_safe_point = ui.reference('RAGE', 'Aimbot', 'Prefer safe point')
local force_safe_point = ui.reference('RAGE', 'Aimbot', 'Force safe point')

local num_format = function(b) local c=b%10;if c==1 and b~=11 then return b..'st'elseif c==2 and b~=12 then return b..'nd'elseif c==3 and b~=13 then return b..'rd'else return b..'th'end end
local hitgroup_names = { 'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', 'gear' }
local weapon_to_verb = { knife = 'Knifed', hegrenade = 'Naded', inferno = 'Burned' }

local function setup_recharge_dt()
    local pui = require("gamesense/pui")
    local ref = {
        aimbot = pui.reference('RAGE', 'Aimbot', 'Enabled'),
        dt = {pui.reference('RAGE', 'Aimbot', 'Double tap')},
        hs = pui.reference("AA", "Other", "On shot anti-aim"),
    }
    local was_disabled = true
    local shot_tick = 0
    local ticking = 0
    local tickbase = nil

    local function tickcount_shot(cmd)
        shot_tick = globals.tickcount()
    end

    local function logic()
        local lp = entity.get_local_player()
        if globals.chokedcommands() == 0 and lp ~= nil and entity.is_alive(lp) then
            tickbase = entity.get_prop(lp, "m_nTickBase") - globals.tickcount()
        end
        if not ((ref.dt[1]:get() and ref.dt[1]:get_hotkey()) or ref.hs:get_hotkey()) then
            was_disabled = true
        end
        if tickbase == nil then return end
        if ((ref.dt[1]:get() and ref.dt[1]:get_hotkey()) or ref.hs:get_hotkey()) and tickbase > 0 and was_disabled then
            ref.aimbot:set(false)
            was_disabled = false
            ticking = 0
        else
            local lp = entity.get_local_player()
            local lp_weapon = entity.get_player_weapon(lp)
            if lp_weapon ~= nil then
                local weapon_id = bit.band(entity.get_prop(entity.get_player_weapon(lp), "m_iItemDefinitionIndex"), 0xFFFF)
                if weapon_id == 64 then
                    ref.aimbot:set(true)
                    if ticking <= 2 then
                        ticking = ticking + 1
                    end
                    if ticking <= 1 then
                        ref.aimbot:set(false)
                    else
                        ref.aimbot:set(true)
                    end
                else
                    ref.aimbot:set(true)
                end
            end
        end
    end
    client.set_event_callback('setup_command', logic)
    client.set_event_callback('weapon_fire', tickcount_shot)
end

local function interface_callback(c)
    local addr = not ui.get(c) and 'un' or ''
    local _func = client[addr .. 'set_event_callback']
    _func('player_hurt', function(e)
        local attacker_id = client.userid_to_entindex(e.attacker)
        if attacker_id == nil or attacker_id ~= entity.get_local_player() then
            return
        end
        local group = hitgroup_names[e.hitgroup + 1] or "?"
        if group == "generic" and weapon_to_verb[e.weapon] ~= nil then
            local target_id = client.userid_to_entindex(e.userid)
            local target_name = entity.get_player_name(target_id)
            print(string.format("%s %s for %i damage (%i remaining)", weapon_to_verb[e.weapon], string.lower(target_name), e.dmg_health, e.health))
        end
    end)
end

ui.set_callback(master_switch, interface_callback)
interface_callback(master_switch)

setup_recharge_dt()

setup_issue_mode()
