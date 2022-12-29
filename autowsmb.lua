-- Some portions Copyright © 2017, Ivaar.

_addon.name     = 'autowsmb'
_addon.author   = 'Dabidobido'
_addon.version  = '1.4.0'
_addon.commands = {'autowsmb', 'awsmb'}

require('logger')
require('actions')
require('functions')
config = require('config')
skills = require('skills')
res = require('resources')

local default_setting = {
	["sc_level"] = 2,
	["open_ws"] = "",
	["ws_priority"] = "",
	["spell_priority"] = "",
	["am_ws"] = "",
	["mb_step"] = 1,
	["fast_cast"] = 80,
	["max_tp_mode"] = false,
}

local aeonic_weapon = {
    [20515] = 'Godhands',
    [20594] = 'Aeneas',
    [20695] = 'Sequence',
    [20843] = 'Chango',
    [20890] = 'Anguta',
    [20935] = 'Trishula',
    [20977] = 'Heishi Shorinken',
    [21025] = 'Dojikiri Yasutsuna',
    [21082] = 'Tishtrya',
    [21147] = 'Khatvanga',
    [21485] = 'Fomalhaut',
    [21694] = 'Lionheart',
    [21753] = 'Tri-edge',
    [22117] = 'Fail-Not',
    [22131] = 'Fail-Not',
    [22143] = 'Fomalhaut'
}

local default_settings = {
	war = default_setting,
	mnk = default_setting,
	whm = default_setting,
	blm = default_setting,
	rdm = default_setting,
	thf = default_setting,
	pld = default_setting,
	drk = default_setting,
	bst = default_setting,
	brd = default_setting,
	rng = default_setting,
	smn = default_setting,
	sam = default_setting,
	nin = default_setting,
	drg = default_setting,
	blu = default_setting,
	cor = default_setting,
	pup = default_setting,
	dnc = default_setting,
	sch = default_setting,
	geo = default_setting,
	run = default_setting
}

local settings = config.load(default_settings)

local started = false
local dont_open = false
local should_mb = false
local spam_mode = false
local am3 = false
local current_main_job = "war"
local bst_jp = 2100
local sic_recast_merits = 5
local bst_ready_minus_5 = true
local debug_print = false
local double_up_time = 0
local double_up_buffer = 20
local am_level = 0

local global_delay = 3

-- .element, .name, .tp
local parsed_wses = {}

local parsed_am_ws = {}

-- .name, .element, .recast_id, .mp, .hpp
local parsed_spells = {}

-- [target_index] = { name, time }
local last_skillchain = {}
local categories = S{
	'melee',
    'weaponskill_finish',
    'spell_finish',
    'job_ability',
    'mob_tp_finish',
    'avatar_tp_finish',
    'job_ability_unblinkable',
}
local skillchain_ids = S{288,289,290,291,292,293,294,295,296,297,298,299,300,301,385,386,387,388,389,390,391,392,393,394,395,396,397,767,768,769,770}
local message_ids = S{110,185,187,317,802}
local sc_window_delay = 3
local sc_window_end = 8
local target_sc_step = 0
local double_light_darkness = false

local function insert_unique(elements_table, elements_to_insert)
	for _,element_to_insert in pairs(elements_to_insert) do
		if not elements_table:contains(element_to_insert) then
			table.insert(elements_table, element_to_insert)
		end
	end
	return elements_table
end

function get_next_skillchain_elements(target_index)
	local elements_to_return = T{}
	if last_skillchain[target_index] then
		for _,v in pairs(last_skillchain[target_index].name) do
			local element = string.lower(v)
			local sc_level_to_use = settings[current_main_job]["sc_level"]
			if element == 'transfixion' then
				if sc_level_to_use > 1 then elements_to_return = insert_unique(elements_to_return, {"scission"} )
				else elements_to_return = insert_unique(elements_to_return, {"compression", "scission", "reverberation" }) end
			elseif element == 'compression' then
				if sc_level_to_use > 1 then
				else elements_to_return = insert_unique(elements_to_return, {"transfixion", "detonation" }) end
			elseif element == 'liquefaction' then
				if sc_level_to_use > 1 then elements_to_return = insert_unique(elements_to_return, {"impaction"})
				else elements_to_return = insert_unique(elements_to_return, {"scission", "impaction" }) end
			elseif element == 'scission' then
				if sc_level_to_use > 1 then
				else elements_to_return = insert_unique(elements_to_return, {"liquefaction", "reverberation", "detonation"}) end
			elseif element == "reverberation" then
				if sc_level_to_use > 1 then
				else elements_to_return = insert_unique(elements_to_return, {"induration", "impaction"}) end
			elseif element == "detonation" then
				if sc_level_to_use > 1 then elements_to_return = insert_unique(elements_to_return, {"compression"})
				else elements_to_return = insert_unique(elements_to_return, {"compression", "scission"}) end
			elseif element == "induration" then
				if sc_level_to_use > 1 then elements_to_return = insert_unique(elements_to_return, {"reverberation"})
				else elements_to_return = insert_unique(elements_to_return, {"compression", "reverberation", "impaction"}) end
			elseif element == "impaction" then
				if sc_level_to_use > 1 then
				else elements_to_return = insert_unique(elements_to_return, {"liquefaction", "detonation"}) end
			elseif element == "gravitation" then
				if sc_level_to_use > 2 then elements_to_return = insert_unique(elements_to_return, {"distortion"})
				else elements_to_return = insert_unique(elements_to_return, {"fragmentation", "distortion"}) end
			elseif element == "distortion" then
				if sc_level_to_use > 2 then elements_to_return = insert_unique(elements_to_return,{"gravitation"})
				else elements_to_return = insert_unique(elements_to_return,{"gravitation", "fusion"}) end
			elseif element == "fusion" then
				if sc_level_to_use > 2 then elements_to_return = insert_unique(elements_to_return, {"fragmentation"})
				else elements_to_return = insert_unique(elements_to_return, {"fragmentation", "gravitation"}) end
			elseif element == "fragmentation" then
				if sc_level_to_use > 2 then elements_to_return = insert_unique(elements_to_return, {"fusion"} )
				else elements_to_return = insert_unique(elements_to_return, {"fusion", "distortion"}) end
			elseif element == "light" then
				elements_to_return = insert_unique(elements_to_return, {"light"} )
			elseif element == "darkness" then
				elements_to_return = insert_unique(elements_to_return, {"darkness"} )
			end
		end
	end
	return elements_to_return
end

local function check_mb_condition(target_index, time_now)
	return last_skillchain[target_index] 
	and last_skillchain[target_index].name ~= nil 
	and #last_skillchain[target_index].name >= 1 
	and time_now - last_skillchain[target_index].time < sc_window_end 
	and target_sc_step >= 1
	and (target_sc_step + 1 >= settings[current_main_job]["mb_step"] or double_light_darkness) -- +1 here cos I start from 0
end

local function check_aeonic(buffs, weapon)
	local equipment = windower.ffxi.get_items('equipment')
	local main_bag = equipment.main_bag
	local main_slot = equipment.main
	local main_weapon = windower.ffxi.get_items(main_bag, main_slot)
	if aeonic_weapon[main_weapon.id] and aeonic_weapon[main_weapon.id] == weapon then
		for _, v in pairs(buffs) do
			if v == 272 or v == 271 or v == 270 then -- any aftermath means got aeonic element
				if debug_print then notice("Got Aenoic due to buff ID: " .. v) end
				return true
			end
		end
	end
	return false
end

local function job_ability_check(ws_info, ja_recasts)
	local pet = windower.ffxi.get_mob_by_target("pet")
	if current_main_job == "smn" and ws_info.recast_id and (ja_recasts[ws_info.recast_id] > 0 or pet == nil) then return false
	elseif current_main_job == "bst" and ws_info.recast_id then
		if pet == nil then return false end
		if ja_recasts[ws_info.recast_id] > 0 then
			local sic_recast = 30
			if bst_jp >= 100 then sic_recast = sic_recast - 5 end
			sic_recast = sic_recast - (2 * sic_recast_merits)
			if bst_ready_minus_5 then sic_recast = sic_recast - 5 end
			local charges = math.floor(3 - 3 * (ja_recasts[ws_info.recast_id] / 3 * sic_recast))
			if charges < ws_info.mp_cost then return false end
		end	
	end
	return true
end

function get_next_skillchain_level(target_index, element_to_use)
	if last_skillchain[target_index] then
		for _,v in pairs(last_skillchain[target_index].name) do
			local element = string.lower(v)
			if element == 'transfixion' then
				if element_to_use == "scission" then return 2
				elseif element_to_use == "compression" or element_to_use == "reverberation" then return 1 end
			elseif element == 'compression' then
				if element_to_use == "transfixion" or element_to_use == "detonation" then return 1 end
			elseif element == 'liquefaction' then
				if element_to_use == "impaction" then return 2
				elseif element_to_use == "scission" then return 1 end
			elseif element == 'scission' then
				if element_to_use == "liquefaction" or element_to_use == "reverberation" or element_to_use == "detonation" then return 1 end
			elseif element == "reverberation" then
				if element_to_use == "induration" or element_to_use == "impaction" then return 1 end
			elseif element == "detonation" then
				if element_to_use == "compression" then return 2
				elseif element_to_use == "scission" then return 1 end
			elseif element == "induration" then
				if element_to_use == "reverberation" then return 2
				elseif element_to_use == "compression" or element_to_use == "impaction" then return 1 end
			elseif element == "impaction" then
				if element_to_use == "liquefaction" or element_to_use == "detonation" then return 1 end
			elseif element == "gravitation" then
				if element_to_use == "distortion" then return 3
				elseif element_to_use == "fragmentation" then return 2 end
			elseif element == "distortion" then
				if element_to_use == "gravitation" then return 3
				elseif element_to_use == "fusion" then return 2 end
			elseif element == "fusion" then
				if element_to_use == "fragmentation" then return 3
				elseif element_to_use == "gravitation" then return 2 end
			elseif element == "fragmentation" then
				if element_to_use == "fusion" then return 3
				elseif element_to_use == "distortion" then return 2 end
			elseif element == "light" then
				if element_to_use == "light" then return 4 end
			elseif element == "darkness" then
				if element_to_use == "darkness" then return 4 end
			end
		end
	end
	return 0
end

local function get_next_ws(player_tp, time_since_last_skillchain, buffs, target_index)
	if not started then return end
	local time_now = os.clock()
	if time_now - double_up_time < double_up_buffer then return nil end
	if should_mb and check_mb_condition(target_index, time_now) then return nil end -- don't ws when you wanna MB
	if am_level > 0 and am_level <= 3 then
		local current_am_level = 0
		for _, v in pairs(buffs) do
			if v == 270 or v == 273 then 
				current_am_level = 1
				break
			elseif v == 271 then
				current_am_level = 2
				break
			elseif v == 272 then 
				current_am_level = 3
				break
			end
		end
		if current_am_level < am_level then
			if player_tp < am_level * 1000 then return nil
			else
				if debug_print then notice("Doing " .. parsed_am_ws.name .. " for AM Level " .. am_level) end
				return parsed_am_ws
			end
		end
	end
	local ja_recasts = windower.ffxi.get_ability_recasts()
	local prefix = "/ws"
	if not spam_mode and last_skillchain[target_index] and last_skillchain[target_index].name ~= nil and not double_light_darkness and time_since_last_skillchain <= sc_window_end then
		local elements_to_continue = get_next_skillchain_elements(target_index)
		if #elements_to_continue >= 1 then
			local ws_to_return = nil
			for i = 2, #parsed_wses do
				if parsed_wses[i].elements ~= nil then
					local got_aeonic = false
					if parsed_wses[i].aeonic then
						got_aeonic = check_aeonic(buffs, parsed_wses[i].weapon)
					end
					local job_ability_ok = job_ability_check(parsed_wses[i], ja_recasts)
					if job_ability_ok then
						local sc_level_to_use = settings[current_main_job]["sc_level"]
						if got_aeonic then
							local next_sc_level = get_next_skillchain_level(target_index, string.lower(parsed_wses[i].aeonic))
							if next_sc_level >= sc_level_to_use then
								ws_to_return = parsed_wses[i]
							end
						end
						if ws_to_return == nil then
							for _, v2 in pairs(parsed_wses[i].elements) do
								local next_sc_level = get_next_skillchain_level(target_index, string.lower(v2))
								if next_sc_level >= sc_level_to_use then
									ws_to_return = parsed_wses[i]
									break
								elseif next_sc_level > 0 then
									break
								end
							end
						end
						if ws_to_return ~= nil then break end
					end
				else
					ws_to_return = parsed_wses[i]
				end
				if ws_to_return ~= nil then break end
			end
			if ws_to_return ~= nil then
				if time_since_last_skillchain >= sc_window_delay then
					if settings[current_main_job]["max_tp_mode"] then
						if player_tp >= ws_to_return.tp or sc_window_end - time_since_last_skillchain <= 2 then
							if debug_print then notice("Doing SC with " .. ws_to_return.name .. " " .. time_since_last_skillchain .. " " .. sc_window_end) end
							return ws_to_return
						else
							if debug_print then notice("Waiting for " .. ws_to_return.tp .. " TP or SC window end") end
							return nil
						end
					else
						if player_tp >= ws_to_return.tp then 
							if debug_print then notice("Doing SC with " .. ws_to_return.name) end
							return ws_to_return
						else
							if debug_print then notice("Waiting for " .. ws_to_return.tp .. " TP") end
							return nil
						end
					end
				else
					return nil
				end
			elseif not dont_open and player_tp >= parsed_wses[1].tp and job_ability_check(parsed_wses[1], ja_recasts) then -- couldn't find the next ws to continue skillchain so open ws immediately
				if debug_print then notice("No WS to continue. Opening with " .. parsed_wses[1].name) end
				return parsed_wses[1]
			end
		elseif not dont_open and player_tp >= parsed_wses[1].tp and job_ability_check(parsed_wses[1], ja_recasts) then -- no possible continuation so open ws immediately
			if debug_print then notice("No elements to continue. Opening with " .. parsed_wses[1].name) end
			return parsed_wses[1]
		end
	elseif player_tp >= parsed_wses[1].tp and (spam_mode or not dont_open) and job_ability_check(parsed_wses[1], ja_recasts) then -- first mob, already double dark/light or sc window closed
		if debug_print then notice("Spam: " .. tostring(spam_mode) .. ", Don't Open: " .. tostring(spam_mode) .. ", Double Light/Dark: " .. tostring(double_light_darkness) .. ", Time: " .. tostring(time_since_last_skillchain)) end
		return parsed_wses[1]
	end
	return nil
end

local function get_burst_elements(animation)
	-- 0 = fire, 1 = ice, 2 = wind, 3 = earth, 4 = thunder, 5 = water, 6 = light, 7 = dark
	if animation == 'transfixion' then return T{ 6 }
	elseif animation == 'compression' then return T{ 7 }
	elseif animation == 'liquefaction' then return T{ 0 }
	elseif animation == 'scission' then return T{ 3 }
	elseif animation == "reverberation" then return T{ 5 }
	elseif animation == "detonation" then return T{ 2 }
	elseif animation == "induration" then return T{ 1 }
	elseif animation == "impaction" then return T{ 4 }
	elseif animation == "gravitation" then return T{ 3, 7 }
	elseif animation == "distortion" then return T{ 1, 5 }
	elseif animation == "fusion" then return T{ 0, 6 }
	elseif animation == "fragmentation" then return T{ 2, 4 }
	elseif animation == "light" or animation == "radiance" then return T{ 0, 2, 4, 6 }
	elseif animation == "darkness" or animation == "umbra" then return T{ 1, 3, 5, 7 }
	end
	return nil
end

local function get_mb_spells(animation, target_hp, time_left)
	local mp_available = windower.ffxi.get_player().vitals.mp
	local recasts = windower.ffxi.get_spell_recasts()
	local ja_recasts = windower.ffxi.get_ability_recasts()
	local burst_elements = get_burst_elements(animation)
	local recast = 99
	if burst_elements ~= nil then
		local fc_multi = (100 - settings[current_main_job]["fast_cast"]) / 100
		for _,v in pairs(parsed_spells) do
			if burst_elements:contains(v.element)
			and mp_available > v.mp 
			and target_hp >= v.hpp 
			and time_left > v.cast_time * fc_multi 
			then
				if v.prefix == "/magic" then
					if recasts[v.recast] == 0 then
						return v.name, v.cast_time * fc_multi, v.prefix, nil
					else
						if recast > recasts[v.recast] then 
							recast = recasts[v.recast]
						end
					end
				elseif v.prefix == "/pet" then
					if ja_recasts[v.recast] == 0 then
						return v.name, 2, v.prefix, nil
					else
						if recast > ja_recasts[v.recast] then 
							recast = ja_recasts[v.recast]
						end
					end
				end
			end
		end
	end
	return nil, nil, nil, recast
end

local function check_mb()
	local player = windower.ffxi.get_player()
	local target_index = player.target_index
	local time_now = os.clock()
	if debug_print then notice("Checking MB") end
	if check_mb_condition(target_index, time_now) then
		local time_left = 8 + sc_window_delay - (time_now - last_skillchain[target_index].time) - target_sc_step
		local mob = windower.ffxi.get_mob_by_index(target_index)
		local spell, cast_time, prefix, recast = get_mb_spells(string.lower(last_skillchain[target_index].name[1]), mob.hpp, time_left)
		if spell ~= nil then
			local commandstring ='input ' .. prefix .. ' "' .. spell .. '" <t>'
			windower.send_command(commandstring)
			if debug_print then notice("MB with " .. spell) end
			local delay = cast_time + global_delay
			if time_now + delay - last_skillchain[target_index].time < sc_window_end then
				coroutine.schedule(check_mb, delay)
				if debug_print then notice("Check MB again in " .. tostring(delay)) end
			end
		elseif recast ~= nil then
			if time_now + recast - last_skillchain[target_index].time < sc_window_end then
				coroutine.schedule(check_mb, recast)
				if debug_print then notice("Check MB again in " .. tostring(delay)) end
			end
		end
	end
end

local function parse_action(act)
	if started or should_mb then
		local actionpacket = ActionPacket.new(act)
		local category = actionpacket:get_category_string()
		
		if not categories:contains(category) or act.param == 0 then
			return
		end

		local actor_id = actionpacket:get_id()
		local target = actionpacket:get_targets()()
		local action = target:get_actions()()
		local message_id = action:get_message_id()
		local add_effect = action:get_add_effect()
		local param, resource, action_id, interruption, conclusion = action:get_spell()
		local ability = skills[resource] and skills[resource][action_id]	
		local player = windower.ffxi.get_player()
		local target_index = player.target_index
		if target_index then
			local mob = windower.ffxi.get_mob_by_index(target_index)
			if mob and target.id == mob.id then
				if category == 'melee' and actor_id == player.id then
					local time_since_last_skillchain = os.clock()
					if last_skillchain[target_index] and last_skillchain[target_index].time ~= nil then 
						time_since_last_skillchain = time_since_last_skillchain - last_skillchain[target_index].time 
					end
					local next_ws = get_next_ws(player.vitals.tp, time_since_last_skillchain, player.buffs, target_index)
					if next_ws ~= nil then
						local prefix = "/ws "
						if next_ws.recast_id ~= nil then 
							prefix = "/pet " 
							if current_main_job == "bst" then next_ws.target = "<me>" end
						end
						if next_ws.target then
							windower.send_command('input ' .. prefix .. '"' .. next_ws.name .. '" ' .. next_ws.target)
						else
							windower.send_command('input ' .. prefix .. '"' .. next_ws.name .. '" <t>')
						end
					end
				elseif add_effect and conclusion and skillchain_ids:contains(add_effect.message_id) then
					target_sc_step = target_sc_step + 1
					if add_effect.animation == "radiance" or add_effect.animation == "umbra" then double_light_darkness = true
					elseif (last_skillchain[target_index] and last_skillchain[target_index].name ~= nil and #last_skillchain[target_index].name >= 1) and
					((string.lower(last_skillchain[target_index].name[1]) == "light" and add_effect.animation == "light" and ability.skillchain[1] == "Light") or (string.lower(last_skillchain[target_index].name[1]) == "darkness" and add_effect.animation == "darkness" and ability.skillchain[1] == "Darkness")) then
						double_light_darkness = true
					else
						double_light_darkness = false
					end
					if last_skillchain[target_index] == nil then last_skillchain[target_index] = {} end
					last_skillchain[target_index].name = { add_effect.animation }
					last_skillchain[target_index].time = os.clock()
					sc_window_delay = ability.delay or 3
					sc_window_end = 6 + sc_window_delay - target_sc_step
					if should_mb then
						if actor_id == player.id then coroutine.schedule(check_mb, 3)
						else
							coroutine.schedule(check_mb, 1) -- leave one sec for trusts to be stupid
						end
					end
				elseif ability and message_ids:contains(message_id) then
					double_light_darkness = false
					if last_skillchain[target_index] == nil then last_skillchain[target_index] = {} end
					if ability.skillchain ~= nil then 
						last_skillchain[target_index].name = ability.skillchain
						if ability.aeonic and actor_id == player.id then
							if check_aeonic(player.buffs, ability.weapon) then
								table.insert(last_skillchain[target_index].name, 1, ability.aeonic)
							end
 						end
						last_skillchain[target_index].time = os.clock()
						sc_window_delay = ability.delay or 3
						sc_window_end = 6 + sc_window_delay
						target_sc_step = 0
					end
				end
			end
		end
	end
end

local function parse_ws_settings()
	parsed_wses = {}
	local open_ws_table = settings[current_main_job]["open_ws"]:split(',')
	if #open_ws_table ~= 2 then return false end
	local open_tp = tonumber(open_ws_table[2])
	if open_tp == nil or open_tp < 1000 or open_tp > 3000 then open_tp = 1000 end
	if current_main_job == "smn" or current_main_job == "bst" then
		for k,v in pairs(skills.job_abilities) do
			if string.lower(v.en) == open_ws_table[1] then
				parsed_wses[1] = { name = open_ws_table[1], elements = v.skillchain, tp = open_tp, recast_id = res.job_abilities[k].recast_id, mp_cost = res.job_abilities[k].mp_cost }
				notice("WS To Use: " .. parsed_wses[1].name .. " (" .. parsed_wses[1].tp .. " TP)")
			end
		end
	end
	if #parsed_wses == 0 then
		for _,v in pairs(skills.weapon_skills) do
			if string.lower(v.en) == open_ws_table[1] then
				parsed_wses[1] = { name = open_ws_table[1], elements = v.skillchain, tp = open_tp, target = v.target }
				if v.aeonic then 
					parsed_wses[1].aeonic = v.aeonic 
					parsed_wses[1].weapon = v.weapon
				end
				notice("WS To Use: " .. parsed_wses[1].name .. " (" .. parsed_wses[1].tp .. " TP)")
				break
			end
		end
	end
	if #parsed_wses == 1 then
		local ws_p_table = settings[current_main_job]["ws_priority"]:split(',')
		if #ws_p_table % 2 ~= 0 then
		else
			for i = 1, #ws_p_table, 2 do
				local ws_tp = tonumber(ws_p_table[i + 1])
				if ws_tp == nil or ws_tp < 1000 or ws_tp > 3000 then ws_tp = 1000 end
				if current_main_job == "smn" or current_main_job == "bst" then
					for k,v in pairs(skills.job_abilities) do
						if string.lower(v.en) == ws_p_table[i] then
							table.insert(parsed_wses, { name = ws_p_table[i], elements = v.skillchain, tp = 0, recast_id = res.job_abilities[k].recast_id, mp_cost = res.job_abilities[k].mp_cost })
							break
						end
					end
				end
				for _, v2 in pairs(skills.weapon_skills) do
					if string.lower(v2.en) == ws_p_table[i] then
						if v2.aeonic then 
							table.insert(parsed_wses, {name = ws_p_table[i], elements = v2.skillchain, tp = ws_tp, target = v2.target, aeonic = v2.aeonic, weapon = v2.weapon } )
						else
							table.insert(parsed_wses, {name = ws_p_table[i], elements = v2.skillchain, tp = ws_tp, target = v2.target } )
						end
						break
					end
				end
			end
		end
		for i = 2, #parsed_wses do
			notice("WS Priority " .. tostring(i - 1) .. ": " .. parsed_wses[i].name .. " (" .. parsed_wses[i].tp .. " TP)")
		end
		return true
	end
	return false
end

local function parse_am_ws_settings()
	parsed_am_ws = {}
	for _,v in pairs(skills.weapon_skills) do
		if string.lower(v.en) == string.lower(settings[current_main_job]["am_ws"]) then
			parsed_am_ws = { name = settings[current_main_job]["am_ws"] }
			notice("AM WS: " .. tostring(parsed_am_ws.name))
			return true
		end
	end
	return false
end

local function parse_spell_settings()
	parsed_spells = {}
	local spell_table = settings[current_main_job]["spell_priority"]:split(',')
	if #spell_table % 2 == 0 then
		for i = 1, #spell_table, 2 do
			local spell_hp = tonumber(spell_table[i + 1])
			if spell_hp == nil or spell_hp > 100 or spell_hp < 0 then spell_hp = 0
			else
				if current_main_job == "smn" or current_main_job == "bst" then
					for _,v2 in pairs(res.job_abilities) do
						if string.lower(spell_table[i]) == string.lower(v2.en) then
							table.insert(parsed_spells, { name = v2.en, element = v2.element, recast = v2.recast_id, mp = v2.mp_cost, hpp = spell_hp, cast_time = 3, prefix = v2.prefix })
							break
						end	
					end
				else
					for _,v2 in pairs(res.spells) do
						if string.lower(spell_table[i]) == string.lower(v2.en) then
							table.insert(parsed_spells, { name = v2.en, element = v2.element, recast = v2.recast_id, mp = v2.mp_cost, hpp = spell_hp, cast_time = v2.cast_time, prefix = v2.prefix })
							break
						end
					end
				end
			end
		end
	end
	if #parsed_spells >= 1 then
		for i = 1, #parsed_spells do
			notice("Spell Priority " .. tostring(i) .. ": " .. parsed_spells[i].name .. " (" .. parsed_spells[i].hpp .. "% HP)")
		end
		return true 
	end
	return false
end

local function check_job_and_parse_settings(force)
	local player = windower.ffxi.get_player()
	local new_job = string.lower(player.main_job)
	if not force and current_main_job == new_job then return end
	if settings[current_main_job] then -- monstrosity gives somem weird mainjob haha
		current_main_job = new_job
		bst_jp = player.job_points.bst.jp_spent
		sic_recast_merits = player.merits.sic_recast
		notice("Don't Open: " .. tostring(dont_open))
		notice("SC Level: " .. tostring(settings[current_main_job]["sc_level"]))
		notice("Spamming: " .. tostring(spam_mode))
		notice("Fast Cast: " .. tostring(settings[current_main_job]["fast_cast"]))
		notice("MB Step: " .. tostring(settings[current_main_job]["mb_step"]))
		notice("Max TP Mode: " .. tostring(settings[current_main_job]["max_tp_mode"]))
		parse_ws_settings()
		parse_spell_settings()
		parse_am_ws_settings()
		notice("AM Level: " .. tostring(am_level))
	end
end

local function handle_command(...)
    local args = T{...}
	if args[1] == "start" then
		local startws = true
		local startmb = true
		if args[2] then
			if args[2] == "ws" then startmb = false
			elseif args[2] == "mb" then startws = false
			end
		end
		if startws then 
			if parse_ws_settings() then
				started = true
				notice("Start WS: " .. tostring(started))
			else
				warning("Error parsing weapon skills")
			end
		end
		if startmb then 
			if parse_spell_settings() then 
				should_mb = true
				notice("Start MB: " .. tostring(should_mb))
			else
				warning("Error parsing spells")
			end
		end
	elseif args[1] == "stop" then
		local stopws = true
		local stopmb = true
		if args[2] then
			if args[2] == "ws" then stopmb = false
			elseif args[2] == "mb" then stopws = false
			end
		end
		if stopws then
			started = false
			notice("Start WS: " .. tostring(started))
		end
		if stopmb then
			should_mb = false
			notice("Start MB: " .. tostring(should_mb))
		end
	elseif args[1] == "dontopen" then
		dont_open = true
		notice("Don't Open: " .. tostring(dont_open))
	elseif args[1] == "open" then
		dont_open = false
		notice("Don't Open: " .. tostring(dont_open))
	elseif args[1] == 'setopenws' and args[2] then
		local commandstring = ""
		for i = 2, #args do
			commandstring = commandstring .. args[i] .. " "
		end
		commandstring = string.sub(commandstring, 1, #commandstring - 1)
		commandstring = string.lower(commandstring)
		local old_open_ws = settings[current_main_job]["open_ws"]
		settings[current_main_job]["open_ws"] = commandstring
		if parse_ws_settings() then
			config.save(settings)
		else
			settings[current_main_job]["open_ws"] = old_open_ws
			notice("Error parsing " .. commandstring)
		end
	elseif args[1] == "setwspriority" and args[2] then
		local commandstring = ""
		for i = 2, #args do
			commandstring = commandstring .. args[i] .. " "
		end
		commandstring = string.sub(commandstring, 1, #commandstring - 1)
		commandstring = string.lower(commandstring)
		local old_ws_priority = settings[current_main_job]["ws_priority"]
		settings[current_main_job]["ws_priority"] = commandstring
		if parse_ws_settings() then
			config.save(settings)
		else
			settings[current_main_job]["ws_priority"] = old_ws_priority
			notice("Error parsing " .. commandstring)
		end
	elseif args[1] == "setsclevel" and args[2] then
		local level = tonumber(args[2])
		if level then
			if level >= 1 and level <= 4 then
				settings[current_main_job]["sc_level"] = level
				notice("SC Level: " .. tostring(settings[current_main_job]["sc_level"]))
				config.save(settings)
			else
				notice("SC Level needs to be between 1 and 4, not " .. tostring(level))
			end
		else
			notice("Error parsing " .. args[2])
		end
	elseif args[1] == "setspellpriority" and args[2] then
		local commandstring = ""
		for i = 2, #args do
			commandstring = commandstring .. args[i] .. " "
		end
		commandstring = string.sub(commandstring, 1, #commandstring - 1)
		commandstring = string.lower(commandstring)
		local old_spell_priority = settings[current_main_job]["spell_priority"]
		settings[current_main_job]["spell_priority"] = commandstring
		if parse_spell_settings() then
			config.save(settings)
		else
			settings[current_main_job]["spell_priority"] = old_spell_priority
			notice("Error parsing " .. commandstring)
		end
	elseif args[1] == "spam" and args[2] then
		if args[2] == "on" then spam_mode = true
		elseif args[2] == "off" then spam_mode = false end
		notice("Spamming: " .. tostring(spam_mode))
	elseif args[1] == "fastcast" and args[2] then
		local fc = tonumber(args[2])
		if fc then
			if fc >= 0 and fc <= 80 then
				settings[current_main_job]["fast_cast"] = fc
				config.save(settings)
				notice("Fast Cast: " .. tostring(settings[current_main_job]["fast_cast"]))
			else
				notice("Fast Cast needs to be between 0 and 80, not " .. tostring(fc))
			end
		else
			notice("Error parsing " .. args[2])
		end
	elseif args[1] == "amlvl" and args[2] then
		local am_lvl = tonumber(args[2])
		if am_lvl then
			if am_lvl >= 0 and am_lvl <= 3 then
				if am_lvl > 0 then
					local old_am_lvl_ws = settings[current_main_job]["am_ws"]
					if args[3] then 
						local ws_name = ""
						for i = 3, #args do
							ws_name = ws_name .. args[i] .. " "
						end
						ws_name = string.sub(ws_name, 1, #ws_name - 1)
						ws_name = string.lower(ws_name)
						settings[current_main_job]["am_ws"] = ws_name
					end	
					if parse_am_ws_settings() then
						am_level = am_lvl
						if args[3] then config.save(settings) end
					else
						notice("Error parsing am ws " .. settings[current_main_job]["am_ws"])
						settings[current_main_job]["am_ws"] = old_am_lvl_ws
						am_level = 0
					end
				else
					am_level = 0
				end
				notice("AM Level: " .. am_level)
			else
				notice("AM Level should be between 0 and 3. " .. args[2])
			end
		else
			notice("AM Level should be between 0 and 3. " .. args[2])
		end
	elseif args[1] == "mbstep" and args[2] then
		local mb_step = tonumber(args[2])
		if mb_step and mb_step >= 1 then 
			settings[current_main_job]["mb_step"] = mb_step
			config.save(settings)
			notice("MB at step: " .. tostring(settings[current_main_job]["mb_step"]) .. "+")
		else 
			notice("MB step should be number more than or equal to 1 " .. args[2])
		end
	elseif args[1] == "maxtp" and args[2] then
		if args[2] == "on" then 
			settings[current_main_job]["max_tp_mode"] = true
			notice("Max TP Mode: " .. tostring(settings[current_main_job]["max_tp_mode"]))
			config.save(settings)
		elseif args[2] == "off" then
			settings[current_main_job]["max_tp_mode"] = false
			notice("Max TP Mode: " .. tostring(settings[current_main_job]["max_tp_mode"]))
			config.save(settings)
		end
	elseif args[1] == "debug" and args[2] then
		if args[2] == "on" then debug_print = true
		elseif args[2] == "off" then debug_print = false end
		notice("Debug: " .. tostring(debug_print))
	elseif args[1] == "status" then
		check_job_and_parse_settings(true)
    else
		notice("//awsmb start (ws/mb): Starts auto ws/mb. Both if argument is omitted.")
		notice("//awsmb stop (ws/mb): Stops auto ws/mb. Both if argument is omitted.")
		notice("//awsmb dontopen: Don't use open ws, only try to skill chain.")
		notice("//awsmb open: Use open ws.")
		notice("//awsmb setopenws (name,tp): Set the name of ws to open with and the minimum tp to use the ws.")
		notice("//awsmb setwspriority ((name,tp,name,tp,...): Set the name of ws and tp of ws to try to skillchain with. will try to make skillchains in the order of input.")
		notice("//awsmb setsclevel (1-3): Will only try to skillchain and make skillchains of the level set here or above.")
		notice("//awsmb setspellpriority (spell_name,hpp,spell_name,hpp,...): Sets priority for spells to burst with. Will go in order of input and check elements. Hpp is amount of Hpp (HP percent) mob must have in order for spell to be used. Set to 0 for always use.")
		notice("//awsmb spam (on/off): Starts/Stops spamming opener ws.")
		notice("//awsmb amlvl (0-3, ws_name): Holds TP to trigger aftermath. Set to 0 to disable. 1-3 will trigger AM level 1-3. Use 1 for relic aftermath.")
		notice("//awsmb fastcast (0-80): Sets fastcast value for mb recast calculation. Default 80.")
		notice("//awsmb mbstep (number 1+): MB only after skillchain has reached a specific step. Default 1.")
		notice("//awsmb maxtp (on/off): Toggles Max TP Mode. In Max TP Mode, will hold tp until the value specified in setwspriority or setopenws commands, or hold until there is less than 2 second sleft in the skillchain window.")
		notice("//awsmb status: Prints current configuration to chatlog.")
    end
end

local function handle_zone_change(new, old)
	if started or should_mb then 
		started = false
		should_mb = false
		last_skillchain = {}
		notice("Zoned. Stopped autows and automb")
	end
end

local function gain_buff(buff_id)
	if buff_id == 308 then
		double_up_time = os.clock()
	end
end

windower.register_event('zone change', handle_zone_change)
windower.register_event('addon command', handle_command)
windower.register_event('load', check_job_and_parse_settings)
windower.register_event('login', check_job_and_parse_settings)
windower.register_event('job change', check_job_and_parse_settings)
windower.register_event('gain buff', gain_buff)
ActionPacket.open_listener(parse_action)