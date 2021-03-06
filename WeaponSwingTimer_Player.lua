local addon_name, addon_data = ...

addon_data.player = {}

--[[============================================================================================]]--
--[[===================================== SETTINGS RELATED =====================================]]--
--[[============================================================================================]]--

addon_data.player.default_settings = {
	enabled = true,
	width = 200,
	height = 10,
    point = "CENTER",
	rel_point = "CENTER",
	x_offset = 0,
	y_offset = -200,
	in_combat_alpha = 1.0,
	ooc_alpha = 0.25,
	backplane_alpha = 0.5,
	is_locked = false,
    show_left_text = true,
    show_right_text = true,
	show_offhand = true,
    show_border = true,
    classic_bars = true,
    fill_empty = true,
    main_r = 0.1, main_g = 0.1, main_b = 0.9, main_a = 1.0,
    queued_r = 0.1, queued_g = 0.9, queued_b = 0.1, queued_a = 1.0,
    main_text_r = 1.0, main_text_g = 1.0, main_text_b = 1.0, main_text_a = 1.0,
    off_r = 0.1, off_g = 0.1, off_b = 0.9, off_a = 1.0,
    off_text_r = 1.0, off_text_g = 1.0, off_text_b = 1.0, off_text_a = 1.0,
}

addon_data.player.class = UnitClass("player")[2]
addon_data.player.guid = UnitGUID("player")

addon_data.player.main_swing_timer = 0.00001
addon_data.player.prev_main_weapon_speed = 2
addon_data.player.main_weapon_speed = 2
addon_data.player.main_weapon_id = GetInventoryItemID("player", 16)
addon_data.player.main_speed_changed = false
addon_data.player.slot_list = nil

addon_data.player.mainhand = {
	weapon_id = GetInventoryItemID("player", 16),
	-- speed_chaged = false,
	speed = 0,
	predicted_speed = nil,
	cooldown = 0,
}

addon_data.player.offhand = {
	weapon_id = GetInventoryItemID("player", 17),
	-- speed_changed = false,
	speed = 0,
	predicted_speed = nil,
	cooldown = 0,
}

addon_data.player.off_swing_timer = 0.00001
addon_data.player.prev_off_weapon_speed = 2
addon_data.player.off_weapon_speed = 2
addon_data.player.off_weapon_id = GetInventoryItemID("player", 17)
addon_data.player.has_offhand = false
addon_data.player.off_speed_changed = false

-- my stuff
addon_data.player.flurry_timestamp = 0
addon_data.player.previous_swing_oh = 0
addon_data.player.previous_swing_mh = 0
-- addon_data.player.next_swing_mh = 0
addon_data.player.next_swing_oh = 0


addon_data.player.LoadSettings = function()
    -- If the carried over settings dont exist then make them
    if not character_player_settings then
        character_player_settings = {}
    end
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(addon_data.player.default_settings) do
        if character_player_settings[setting] == nil then
            character_player_settings[setting] = value
        end
    end
    -- Update settings that dont change unless the interface is reloaded
    addon_data.player.class = UnitClass("player")[2]
    addon_data.player.guid = UnitGUID("player")
end

addon_data.player.RestoreDefaults = function()
    for setting, value in pairs(addon_data.player.default_settings) do
        character_player_settings[setting] = value
    end
    addon_data.player.UpdateVisualsOnSettingsChange()
    addon_data.player.UpdateConfigPanelValues()
end

--[[
============================================================================================
====================================== LOGIC RELATED =======================================
============================================================================================
]]--

addon_data.player.SpellIsQueued = function(spell_name)
    local _, _, _, _, _, _, spell_id = GetSpellInfo(spell_name)
    if spell_id then
        local slot = C_ActionBar.FindSpellActionButtons(spell_id)
        if slot then
            return IsCurrentAction(slot[1])
        end
    end
end

-- addon_data.player.AttackModifierIsQueued = function()
--     local _, _, _, _, _, _, heroicstrike_id = GetSpellInfo("Heroic Strike")
--     local _, _, _, _, _, _, cleave_id = GetSpellInfo("Cleave")

--     if heroicstrike_id then
--         local heroicstrike_slot = C_ActionBar.FindSpellActionButtons(heroicstrike_id)
--         if heroicstrike_slot then
--             return IsCurrentAction(heroicstrike_slot[1])
--         end
--     end
--     if cleave_id then
--         local cleave_slot = C_ActionBar.FindSpellActionButtons(cleave_id)
--         if cleave_slot then
--             return IsCurrentAction(cleave_slot[1])
--         end
--     end
-- end

addon_data.player.OnUpdate = function(elapsed)
    if character_player_settings.enabled then
        -- Update the weapon speed
        local new_mainhand_speed, new_offhand_speed = UnitAttackSpeed("player")
        addon_data.player.UpdateWeaponSpeed(addon_data.player.mainhand, new_mainhand_speed)
        if (new_offhand_speed ~= nil) then
            addon_data.player.UpdateWeaponSpeed(addon_data.player.offhand, new_offhand_speed)
        end
        -- addon_data.player.UpdateOffWeaponSpeed()

--        addon_data.player.next_swing_mh = GetTime() + addon_data.player.mainhand.cooldown * speed

        -- FIXME: Temp fix until I can nail down the divide by zero error
        if addon_data.player.main_weapon_speed == 0 then
            addon_data.player.main_weapon_speed = 2
        end
        if addon_data.player.off_weapon_speed == 0 then
            addon_data.player.off_weapon_speed = 2
        end
        -- If the weapon speed changed for either hand then a buff occured and we need to modify the timers
        -- if addon_data.player.main_speed_changed or addon_data.player.off_speed_changed then
        -- 	--print(GetTime() - addon_data.player.flurry_timestamp .. " seconds since flurry application")
        -- 	addon_data.player.mainhand.predicted_speed = nil
        --     local main_multiplier = addon_data.player.main_weapon_speed / addon_data.player.prev_main_weapon_speed
        --     addon_data.player.main_swing_timer = addon_data.player.main_swing_timer * main_multiplier
        --     if addon_data.player.has_offhand then
        --         local off_multiplier = (addon_data.player.off_weapon_speed / addon_data.player.prev_off_weapon_speed)
        --         addon_data.player.off_swing_timer = addon_data.player.off_swing_timer * off_multiplier
        --     end
        -- end
        -- Update the main hand swing timer
        addon_data.player.UpdateWeaponCooldown(addon_data.player.mainhand, elapsed)
        if (addon_data.player.offhand.speed ~= nil) then
            addon_data.player.UpdateWeaponCooldown(addon_data.player.offhand, elapsed)
        end

        -- addon_data.player.UpdateMainSwingTimer(elapsed)
        -- -- Update the off hand swing timer
        -- addon_data.player.UpdateOffSwingTimer(elapsed)
        -- Update the visuals
        addon_data.player.UpdateVisualsOnUpdate()
    end
end

addon_data.player.OnInventoryChange = function()
    local new_main_guid = GetInventoryItemID("player", 16)
    local new_off_guid = GetInventoryItemID("player", 17)

    local new_mainhand_speed, new_offhand_speed = UnitAttackSpeed("player")
    -- Check for a main hand weapon change
    if addon_data.player.main_weapon_id ~= new_main_guid then
        addon_data.player.UpdateWeaponSpeed(addon_data.player.mainhand, new_mainhand_speed)
        addon_data.player.ResetSwingTimer(addon_data.player.mainhand)
    end
    addon_data.player.main_weapon_id = new_main_guid
    -- Check for an off hand weapon change
    if (new_offhand_speed ~= nil and addon_data.player.off_weapon_id ~= new_off_guid) then
        addon_data.player.UpdateWeaponSpeed(addon_data.player.offhand, new_offhand_speed)
        addon_data.player.ResetSwingTimer(addon_data.player.offhand)
    end
    addon_data.player.off_weapon_id = new_off_guid
end

addon_data.player.HandleParry = function()
    -- print("--- PLAYER PARRIED ---")
    wep = addon_data.player.mainhand
    if wep.cooldown < 0.2 then
        return
    end

    wep.cooldown = wep.cooldown - 0.4
    if wep.cooldown < 0.2 then
        wep.cooldown = 0.2
    end
end

addon_data.player.ResetSwingTimer = function(wep)

    -- if (math.abs(wep.cooldown) > 0.05) then
    --     print("prediction was off by " .. tostring(100 * wep.cooldown) .. "%")
    -- end

    wep.cooldown = 1
end

addon_data.player.GetWeaponSpeed = function(wep)
    return wep.predicted_speed or wep.speed
end

addon_data.player.TimeUntilAttack = function(wep)
    local cd = wep.cooldown * addon_data.player.GetWeaponSpeed(wep)
    if cd < 0 then
        cd = 0
    end
    return cd
end

addon_data.player.UpdateWeaponCooldown = function(wep, elapsed)
    local speed = addon_data.player.GetWeaponSpeed(wep)
    wep.cooldown = wep.cooldown - elapsed/speed
    -- if (wep.cooldown*speed < -1) then
    --     wep.cooldown = 0
    -- end
end

hs_timestamps = {}
offhand_miss_count = 0
offhand_hit_count = 0
addon_data.player.OnCombatLogUnfiltered = function(combat_info)
    local timestamp, event, _, source_guid, _, _, _, dest_guid, _, _, _, _, spell_name, _ = unpack(combat_info)
    local now = GetTime()


    if (source_guid ~= addon_data.player.guid) then
        if (dest_guid == addon_data.player.guid and event == "SWING_MISSED") then
            local miss_type, _ = select(12, unpack(combat_info))
            if (miss_type == "PARRY") then
                addon_data.player.HandleParry()
            end
        end
        return
    end

    -- if (event == "SPELL_EXTRA_ATTACKS" or event == "SWING_EXTRA_ATTACKS") then
    --     print(tostring(event) .. tostring(spell_name) .. tostring(source_guid))
    -- end
    
    -- record difference between combat log timestamp and GetTime()
    local diff = timestamp - now
    if addon_data.core.ts_diff == nil or math.abs(diff - addon_data.core.ts_diff) > 0.01 then
    	addon_data.core.ts_diff = diff
    	--print("server timestamp diff updated: " .. addon_data.core.ts_diff)
    end

    -- if flurry procs, we set a predicted speed as a termporary measure
    if (event == "SPELL_AURA_APPLIED" and spell_name == "Flurry") then
		addon_data.player.mainhand.predicted_speed = addon_data.player.GetWeaponSpeed(addon_data.player.mainhand) / 1.3
        addon_data.player.offhand.predicted_speed = addon_data.player.GetWeaponSpeed(addon_data.player.offhand) / 1.3
		--addon_data.player.flurry_timestamp = now
	elseif (event == "SPELL_AURA_REMOVED" and spell_name == "Flurry") then
		addon_data.player.mainhand.predicted_speed = addon_data.player.GetWeaponSpeed(addon_data.player.mainhand) * 1.3
        addon_data.player.offhand.predicted_speed = addon_data.player.GetWeaponSpeed(addon_data.player.offhand) * 1.3
	end

    -- select the weapon that we attacked with
    local is_offhand = nil
    if (event == "SWING_MISSED" or event == "SPELL_MISSED") then
        is_offhand = select(2, select(12, unpack(combat_info)))
    elseif (event == "SWING_DAMAGE") then
        is_offhand = select(10, select(12, unpack(combat_info)))
    end

    local active_wep = nil

    if is_offhand then
        active_wep = addon_data.player.offhand
        -- print(".OFFHAND.")
    else
        active_wep = addon_data.player.mainhand
    end
    
    if (event == "SPELL_CAST_SUCCESS" and (spell_name == "Heroic Strike" or spell_name == "Cleave")) then
        addon_data.player.ResetSwingTimer(addon_data.player.mainhand)
    elseif (event == "SWING_DAMAGE") then
        addon_data.player.ResetSwingTimer(active_wep)
        if is_offhand == true then
            offhand_hit_count = offhand_hit_count + 1
        end
    elseif (event == "SWING_MISSED") then
        local miss_type, _ = select(12, unpack(combat_info))

		addon_data.player.ResetSwingTimer(active_wep)
        if (is_offhand and miss_type == "MISS") then
            offhand_miss_count = offhand_miss_count + 1
            local offhand_miss_ratio = offhand_miss_count/(offhand_hit_count + offhand_miss_count)
            -- print("offhand miss count: "..offhand_miss_count.." ("..(offhand_miss_ratio*100).."%)")
        else
            offhand_hit_count = offhand_hit_count + 1
        end
        local miss_type, is_offhand = select(12, unpack(combat_info))
        addon_data.core.MissHandler("player", miss_type, is_offhand)
    elseif (event == "SPELL_DAMAGE" and addon_data.core.SpellResetsSwing("player", spell_id)) then
        addon_data.player.ResetSwingTimer(addon_data.player.mainhand)
        addon_data.player.ResetSwingTimer(addon_data.player.offhand)

--      addon_data.core.SpellHandler("player", spell_id)
    end
end

addon_data.player.ZeroizeSwingTimers = function()
    addon_data.player.main_swing_timer = 0.0001
    addon_data.player.off_swing_timer = 0.0001
end

addon_data.player.UpdateMainSwingTimer = function(elapsed)
    -- if character_player_settings.enabled then
    --     --if addon_data.player.main_swing_timer > 0 then
    --         addon_data.player.mainhand.cooldown = addon_data.player.mainhand.cooldown - elapsed
    --         if addon_data.player.mainhand.cooldown < 0 then
    --             addon_data.player.mainhand.cooldown = 0
    --         end
    --   --  end
    -- end
end

addon_data.player.UpdateOffSwingTimer = function(elapsed)
    if character_player_settings.enabled then
        if addon_data.player.has_offhand then
        --    if addon_data.player.off_swing_timer > 0 then
                addon_data.player.off_swing_timer = addon_data.player.off_swing_timer - elapsed
                if addon_data.player.off_swing_timer < 0 then
                    addon_data.player.off_swing_timer = 0
                end
        --    end
        end
    end
end

addon_data.player.UpdateWeaponSpeed = function(active_wep, new_speed)
    local prev_speed = active_wep.speed
    active_wep.speed = new_speed

    if active_wep.speed ~= prev_speed then
        if (active_wep.predicted_speed ~= nil) then
            -- print("predicted attack speed was " .. active_wep.predicted_speed .. "actual speed is now: " .. active_wep.speed)
        end
        active_wep.predicted_speed = nil
        --print("attack speed changed - ", UnitAttackSpeed("player"))
    end
end

--[[============================================================================================]]--
--[[===================================== VISUALS RELATED ======================================]]--
--[[============================================================================================]]--
addon_data.player.UpdateVisualsOnUpdate = function()
    local settings = character_player_settings
    local frame = addon_data.player.frame
    if settings.enabled then
        -- local main_speed = addon_data.player.mainhand.speed
        -- local main_cooldown = addon_data.player.mainhand.cooldown
        local main_timer = addon_data.player.TimeUntilAttack(addon_data.player.mainhand)

        -- Update the main bars width
        main_width = math.min(settings.width - (settings.width * addon_data.player.mainhand.cooldown), settings.width)
        if not settings.fill_empty then
            main_width = settings.width - main_width + 0.001
        end
        -- print(main_width)
        frame.main_bar:SetWidth(main_width)
        frame.main_spark:SetPoint('TOPLEFT', main_width - 8, 0)

        if main_width == settings.width or not settings.classic_bars or main_width == 0.001 then
            frame.main_spark:Hide()
        else
            frame.main_spark:Show()
        end
        -- Update the main bars text
        frame.main_left_text:SetText("")
        frame.main_right_text:SetText(tostring(addon_data.utils.SimpleRound(main_timer, 0.1)))

        -- Update the main bars color
        if addon_data.player.SpellIsQueued("Heroic Strike") or addon_data.player.SpellIsQueued("Cleave") then
            frame.main_bar:SetVertexColor(settings.queued_r, settings.queued_g, settings.queued_b, settings.queued_a)
        else
            frame.main_bar:SetVertexColor(settings.main_r, settings.main_g, settings.main_b, settings.main_a)
        end

        -- Update the off hand bar
        if addon_data.player.offhand.speed ~= nil then
            -- OFFHAND MARKER ON MAINHAND BAR
            local time_until_mainhand = addon_data.player.TimeUntilAttack(addon_data.player.mainhand)
            local time_until_offhand = addon_data.player.TimeUntilAttack(addon_data.player.offhand)

            -- time_until_mainhand = 1.0
            -- time_until_offhand = 1

            --print("mh: "..tostring(time_until_mainhand).." -- oh: "..tostring(time_until_offhand))

            local offhand_delta = (time_until_offhand - time_until_mainhand)
            --print(type(offhand_delta))
            local mainhand_speed = addon_data.player.GetWeaponSpeed(addon_data.player.mainhand)
            -- offhand_delta = math.fmod(offhand_delta, mainhand_speed)
            if offhand_delta < 0 then
                offhand_delta = mainhand_speed + offhand_delta
            end
            offhand_delta = offhand_delta + 0.0001 -- TODO figure out why this is required and find better fix

            -- print(offhand_delta)
            local normalized_delta = offhand_delta / mainhand_speed
            local mark_pos = normalized_delta * settings.width
            -- print(type(mark_pos)) -- "number" 
            -- mark_pos2 = math.floor(mark_pos) + 1
            -- mark_pos1 = mark_pos2
            -- print(mark_pos)
            -- mark_pos = 0
            frame.offhand_spark:SetPoint('TOPLEFT', mark_pos - 3, 2)

            if settings.show_offhand then
                frame.off_bar:Show()
                if settings.show_left_text then
                    frame.off_left_text:Show()
                else
                    frame.off_left_text:Hide()
                end
                if settings.show_right_text then
                    frame.off_right_text:Show()
                else
                    frame.off_right_text:Hide()
                end
                local off_speed = addon_data.player.off_weapon_speed
                local off_timer = addon_data.player.off_swing_timer

                -- -- quick and ditry offhand HS timer
                -- local margin_of_error = 0.133
                -- if off_timer + margin_of_error < main_timer then
                -- 	frame.main_bar:SetVertexColor(settings.main_r settings.main_a);
                -- else
                -- 	frame.main_bar:SetVertexColor(settings.main_r, settings.main_g, settings.main_b, settings.main_a)
                -- end

                -- FIXME: Handle divide by 0 error
                if off_speed == 0 then
                    off_speed = 2
                end
                -- Update the off-hand bar's width
                off_width = math.min(settings.width - (settings.width * (off_timer / off_speed)), settings.width)
                if not settings.fill_empty then
                    off_width = settings.width - off_width + 0.001
                end
                frame.off_bar:SetWidth(off_width)
                frame.off_spark:SetPoint('BOTTOMLEFT', off_width - 8, 0)
                if off_width == settings.width or not settings.classic_bars or off_width == 0.001  then
                    frame.off_spark:Hide()
                else
                    frame.off_spark:Show()
                end
                -- Update the off-hand bar's text
                frame.off_left_text:SetText("Off-Hand")
                frame.off_right_text:SetText(tostring(addon_data.utils.SimpleRound(off_timer, 0.1)))
            else
                frame.off_bar:Hide()
                frame.off_left_text:Hide()
                frame.off_right_text:Hide()
            end
        end
        -- Update the frame's appearance based on settings
        if addon_data.player.has_offhand and character_player_settings.show_offhand then
            frame:SetHeight((settings.height * 2) + 2)
        else
            frame:SetHeight(settings.height)
        end
        -- Update the alpha
        if addon_data.core.in_combat then
            frame:SetAlpha(settings.in_combat_alpha)
        else
            frame:SetAlpha(settings.ooc_alpha)
        end
    end
end

addon_data.player.UpdateVisualsOnSettingsChange = function()
    local frame = addon_data.player.frame
    local settings = character_player_settings
    if settings.enabled then
        frame:Show()
        frame:ClearAllPoints()
        frame:SetPoint(settings.point, UIParent, settings.rel_point, settings.x_offset, settings.y_offset)
        frame:SetWidth(settings.width)
        if settings.show_border then
            frame.backplane:SetBackdrop({
                bgFile = "Interface/AddOns/WeaponSwingTimer/Images/Background", 
                edgeFile = "Interface/AddOns/WeaponSwingTimer/Images/Border", 
                tile = true, tileSize = 16, edgeSize = 12, 
                insets = { left = 8, right = 8, top = 8, bottom = 8}})
        else
            frame.backplane:SetBackdrop({
                bgFile = "Interface/AddOns/WeaponSwingTimer/Images/Background", 
                edgeFile = nil, 
                tile = true, tileSize = 16, edgeSize = 16, 
                insets = { left = 8, right = 8, top = 8, bottom = 8}})
        end
        frame.backplane:SetBackdropColor(0,0,0,settings.backplane_alpha)
        frame.main_bar:SetPoint("TOPLEFT", 0, 0)
        frame.main_bar:SetHeight(settings.height)
        if settings.classic_bars then
            frame.main_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Bar')
        else
            frame.main_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Background')
        end
        frame.offhand_spark:SetSize(5, settings.height+4)

        frame.main_bar:SetVertexColor(settings.main_r, settings.main_g, settings.main_b, settings.main_a)
        frame.main_spark:SetSize(16, settings.height)
        frame.main_left_text:SetPoint("TOPLEFT", 2, -(settings.height / 2) + 5)
        frame.main_left_text:SetTextColor(settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)
        frame.main_right_text:SetPoint("TOPRIGHT", -5, -(settings.height / 2) + 5)
        frame.main_right_text:SetTextColor(settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)
        frame.off_bar:SetPoint("BOTTOMLEFT", 0, 0)
        frame.off_bar:SetHeight(settings.height)
        if settings.classic_bars then
            frame.off_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Bar')
        else
            frame.off_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Background')
        end
        frame.off_bar:SetVertexColor(settings.off_r, settings.off_g, settings.off_b, settings.off_a)
        frame.off_spark:SetSize(16, settings.height)
        frame.off_left_text:SetPoint("BOTTOMLEFT", 2, (settings.height / 2) - 5)
        frame.off_left_text:SetTextColor(settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
        frame.off_right_text:SetPoint("BOTTOMRIGHT", -5, (settings.height / 2) - 5)
        frame.off_right_text:SetTextColor(settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
        if settings.show_left_text then
            frame.main_left_text:Show()
            frame.off_left_text:Show()
        else
            frame.main_left_text:Hide()
            frame.off_left_text:Hide()
        end
        if settings.show_right_text then
            frame.main_right_text:Show()
            frame.off_right_text:Show()
        else
            frame.main_right_text:Hide()
            frame.off_right_text:Hide()
        end
        if settings.show_offhand and addon_data.player.has_offhand then
            frame.off_bar:Show()
            if settings.show_left_text then
                frame.off_left_text:Show()
            else
                frame.off_left_text:Hide()
            end
            if settings.show_right_text then
                frame.off_right_text:Show()
            else
                frame.off_right_text:Hide()
            end
        else
            frame.off_bar:Hide()
            frame.off_left_text:Hide()
            frame.off_right_text:Hide()
        end
    else
        frame:Hide()
    end
end

addon_data.player.OnFrameDragStart = function()
    if not character_player_settings.is_locked then
        addon_data.player.frame:StartMoving()
    end
end

addon_data.player.OnFrameDragStop = function()
    local frame = addon_data.player.frame
    local settings = character_player_settings
    frame:StopMovingOrSizing()
    point, _, rel_point, x_offset, y_offset = frame:GetPoint()
    if x_offset < 20 and x_offset > -20 then
        x_offset = 0
    end
    settings.point = point
    settings.rel_point = rel_point
    settings.x_offset = addon_data.utils.SimpleRound(x_offset, 1)
    settings.y_offset = addon_data.utils.SimpleRound(y_offset, 1)
    addon_data.player.UpdateVisualsOnSettingsChange()
    addon_data.player.UpdateConfigPanelValues()
end

addon_data.player.InitializeVisuals = function()
    local settings = character_player_settings
    -- Create the frame

    addon_data.player.frame = CreateFrame("Frame", addon_name .. "PlayerFrame", UIParent)
    local frame = addon_data.player.frame
    frame:SetMovable(true)
    frame:EnableMouse(not settings.is_locked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", addon_data.player.OnFrameDragStart)
    frame:SetScript("OnDragStop", addon_data.player.OnFrameDragStop)
    -- Create the backplane and border
    frame.backplane = CreateFrame("Frame", addon_name .. "PlayerBackdropFrame", frame)
    frame.backplane:SetPoint('TOPLEFT', -9, 9)
    frame.backplane:SetPoint('BOTTOMRIGHT', 9, -9)
    frame.backplane:SetFrameStrata('BACKGROUND')
    -- Create the main hand bar
    frame.main_bar = frame:CreateTexture(nil,"ARTWORK")
    -- Create the main spark
    frame.main_spark = frame:CreateTexture(nil,"OVERLAY")
    frame.main_spark:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Spark')
    -- Create the offhand spark!!
    frame.offhand_spark = frame:CreateTexture(nil, "OVERLAY")
    frame.offhand_spark:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Bar')
    frame.offhand_spark:SetVertexColor(1, 0, 1, 1)
    -- Create the main hand bar left text
    frame.main_left_text = frame:CreateFontString(nil, "OVERLAY")
    frame.main_left_text:SetFont("Fonts/FRIZQT__.ttf", 10)
    frame.main_left_text:SetJustifyV("CENTER")
    frame.main_left_text:SetJustifyH("LEFT")
    -- Create the main hand bar right text
    frame.main_right_text = frame:CreateFontString(nil, "OVERLAY")
    frame.main_right_text:SetFont("Fonts/FRIZQT__.ttf", 10)
    frame.main_right_text:SetJustifyV("CENTER")
    frame.main_right_text:SetJustifyH("RIGHT")
    -- Create the off hand bar
    frame.off_bar = frame:CreateTexture(nil,"ARTWORK")
    -- Create the off spark
    frame.off_spark = frame:CreateTexture(nil,"OVERLAY")
    frame.off_spark:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Spark')
    -- Create the off hand bar left text
    frame.off_left_text = frame:CreateFontString(nil, "OVERLAY")
    frame.off_left_text:SetFont("Fonts/FRIZQT__.ttf", 10)
    frame.off_left_text:SetJustifyV("CENTER")
    frame.off_left_text:SetJustifyH("LEFT")
    -- Create the off hand bar right text
    frame.off_right_text = frame:CreateFontString(nil, "OVERLAY")
    frame.off_right_text:SetFont("Fonts/FRIZQT__.ttf", 10)
    frame.off_right_text:SetJustifyV("CENTER")
    frame.off_right_text:SetJustifyH("RIGHT")
    -- Show it off
    addon_data.player.UpdateVisualsOnSettingsChange()
    addon_data.player.UpdateVisualsOnUpdate()
    frame:Show()
end

--[[============================================================================================]]--
--[[================================== CONFIG WINDOW RELATED ===================================]]--
--[[============================================================================================]]--

addon_data.player.UpdateConfigPanelValues = function()
    local panel = addon_data.player.config_frame
    local settings = character_player_settings
    panel.enabled_checkbox:SetChecked(settings.enabled)
    panel.show_offhand_checkbox:SetChecked(settings.show_offhand)
    panel.show_border_checkbox:SetChecked(settings.show_border)
    panel.classic_bars_checkbox:SetChecked(settings.classic_bars)
    panel.fill_empty_checkbox:SetChecked(settings.fill_empty)
    panel.show_left_text_checkbox:SetChecked(settings.show_left_text)
    panel.show_right_text_checkbox:SetChecked(settings.show_right_text)
    panel.width_editbox:SetText(tostring(settings.width))
    panel.width_editbox:SetCursorPosition(0)
    panel.height_editbox:SetText(tostring(settings.height))
    panel.height_editbox:SetCursorPosition(0)
    panel.x_offset_editbox:SetText(tostring(settings.x_offset))
    panel.x_offset_editbox:SetCursorPosition(0)
    panel.y_offset_editbox:SetText(tostring(settings.y_offset))
    panel.y_offset_editbox:SetCursorPosition(0)
    panel.main_color_picker.foreground:SetColorTexture(
        settings.main_r, settings.main_g, settings.main_b, settings.main_a)
    panel.main_text_color_picker.foreground:SetColorTexture(
        settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)
    panel.off_color_picker.foreground:SetColorTexture(
        settings.off_r, settings.off_g, settings.off_b, settings.off_a)
    panel.off_text_color_picker.foreground:SetColorTexture(
        settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
    panel.in_combat_alpha_slider:SetValue(settings.in_combat_alpha)
    panel.in_combat_alpha_slider.editbox:SetCursorPosition(0)
    panel.ooc_alpha_slider:SetValue(settings.ooc_alpha)
    panel.ooc_alpha_slider.editbox:SetCursorPosition(0)
    panel.backplane_alpha_slider:SetValue(settings.backplane_alpha)
    panel.backplane_alpha_slider.editbox:SetCursorPosition(0)
end

addon_data.player.EnabledCheckBoxOnClick = function(self)
    character_player_settings.enabled = self:GetChecked()
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.ShowOffHandCheckBoxOnClick = function(self)
    character_player_settings.show_offhand = self:GetChecked()
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.ShowBorderCheckBoxOnClick = function(self)
    character_player_settings.show_border = self:GetChecked()
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.ClassicBarsCheckBoxOnClick = function(self)
    character_player_settings.classic_bars = self:GetChecked()
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.FillEmptyCheckBoxOnClick = function(self)
    character_player_settings.fill_empty = self:GetChecked()
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.ShowLeftTextCheckBoxOnClick = function(self)
    character_player_settings.show_left_text = self:GetChecked()
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.ShowRightTextCheckBoxOnClick = function(self)
    character_player_settings.show_right_text = self:GetChecked()
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.WidthEditBoxOnEnter = function(self)
    character_player_settings.width = tonumber(self:GetText())
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.HeightEditBoxOnEnter = function(self)
    character_player_settings.height = tonumber(self:GetText())
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.XOffsetEditBoxOnEnter = function(self)
    character_player_settings.x_offset = tonumber(self:GetText())
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.YOffsetEditBoxOnEnter = function(self)
    character_player_settings.y_offset = tonumber(self:GetText())
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.MainColorPickerOnClick = function()
    local settings = character_player_settings
    local function MainOnActionFunc(restore)
        local settings = character_player_settings
        local new_r, new_g, new_b, new_a
        if restore then
            new_r, new_g, new_b, new_a = unpack(restore)
        else
            new_a, new_r, new_g, new_b = 1 - OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()
        end
        settings.main_r, settings.main_g, settings.main_b, settings.main_a = new_r, new_g, new_b, new_a
        addon_data.player.frame.main_bar:SetVertexColor(
            settings.main_r, settings.main_g, settings.main_b, settings.main_a)
        addon_data.player.config_frame.main_color_picker.foreground:SetColorTexture(
            settings.main_r, settings.main_g, settings.main_b, settings.main_a)
    end
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = 
        MainOnActionFunc, MainOnActionFunc, MainOnActionFunc
    ColorPickerFrame.hasOpacity = true 
    ColorPickerFrame.opacity = 1 - settings.main_a
    ColorPickerFrame:SetColorRGB(settings.main_r, settings.main_g, settings.main_b)
    ColorPickerFrame.previousValues = {settings.main_r, settings.main_g, settings.main_b, settings.main_a}
    ColorPickerFrame:Show()
end

addon_data.player.MainTextColorPickerOnClick = function()
    local settings = character_player_settings
    local function MainTextOnActionFunc(restore)
        local settings = character_player_settings
        local new_r, new_g, new_b, new_a
        if restore then
            new_r, new_g, new_b, new_a = unpack(restore)
        else
            new_a, new_r, new_g, new_b = 1 - OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()
        end
        settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a = new_r, new_g, new_b, new_a
        addon_data.player.frame.main_left_text:SetTextColor(
            settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)
        addon_data.player.frame.main_right_text:SetTextColor(
            settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)
        addon_data.player.config_frame.main_text_color_picker.foreground:SetColorTexture(
            settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)
    end
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = 
        MainTextOnActionFunc, MainTextOnActionFunc, MainTextOnActionFunc
    ColorPickerFrame.hasOpacity = true 
    ColorPickerFrame.opacity = 1 - settings.main_text_a
    ColorPickerFrame:SetColorRGB(settings.main_text_r, settings.main_text_g, settings.main_text_b)
    ColorPickerFrame.previousValues = {settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a}
    ColorPickerFrame:Show()
end

addon_data.player.OffColorPickerOnClick = function()
    local settings = character_player_settings
    local function OffOnActionFunc(restore)
        local settings = character_player_settings
        local new_r, new_g, new_b, new_a
        if restore then
            new_r, new_g, new_b, new_a = unpack(restore)
        else
            new_a, new_r, new_g, new_b = 1 - OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()
        end
        settings.off_r, settings.off_g, settings.off_b, settings.off_a = new_r, new_g, new_b, new_a
        addon_data.player.frame.off_bar:SetVertexColor(
            settings.off_r, settings.off_g, settings.off_b, settings.off_a)
        addon_data.player.config_frame.off_color_picker.foreground:SetColorTexture(
            settings.off_r, settings.off_g, settings.off_b, settings.off_a)
    end
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = 
        OffOnActionFunc, OffOnActionFunc, OffOnActionFunc
    ColorPickerFrame.hasOpacity = true 
    ColorPickerFrame.opacity = 1 - settings.off_a
    ColorPickerFrame:SetColorRGB(settings.off_r, settings.off_g, settings.off_b)
    ColorPickerFrame.previousValues = {settings.off_r, settings.off_g, settings.off_b, settings.off_a}
    ColorPickerFrame:Show()
end

addon_data.player.OffTextColorPickerOnClick = function()
    local settings = character_player_settings
    local function OffTextOnActionFunc(restore)
        local settings = character_player_settings
        local new_r, new_g, new_b, new_a
        if restore then
            new_r, new_g, new_b, new_a = unpack(restore)
        else
            new_a, new_r, new_g, new_b = 1 - OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()
        end
        settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a = new_r, new_g, new_b, new_a
        addon_data.player.frame.off_left_text:SetTextColor(
            settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
        addon_data.player.frame.off_right_text:SetTextColor(
            settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
        addon_data.player.config_frame.off_text_color_picker.foreground:SetColorTexture(
            settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
    end
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = 
        OffTextOnActionFunc, OffTextOnActionFunc, OffTextOnActionFunc
    ColorPickerFrame.hasOpacity = true 
    ColorPickerFrame.opacity = 1 - settings.off_text_a
    ColorPickerFrame:SetColorRGB(settings.off_text_r, settings.off_text_g, settings.off_text_b)
    ColorPickerFrame.previousValues = {settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a}
    ColorPickerFrame:Show()
end

addon_data.player.CombatAlphaOnValChange = function(self)
    character_player_settings.in_combat_alpha = tonumber(self:GetValue())
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.OOCAlphaOnValChange = function(self)
    character_player_settings.ooc_alpha = tonumber(self:GetValue())
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.BackplaneAlphaOnValChange = function(self)
    character_player_settings.backplane_alpha = tonumber(self:GetValue())
    addon_data.player.UpdateVisualsOnSettingsChange()
end

addon_data.player.CreateConfigPanel = function(parent_panel)
    addon_data.player.config_frame = CreateFrame("Frame", addon_name .. "PlayerConfigPanel", parent_panel)
    local panel = addon_data.player.config_frame
    local settings = character_player_settings
    
    -- Title Text
    panel.title_text = addon_data.config.TextFactory(panel, "Player Swing Bar Settings", 20)
    panel.title_text:SetPoint("TOPLEFT", 10, -10)
    panel.title_text:SetTextColor(1, 0.82, 0, 1)
    
    -- Enabled Checkbox
    panel.enabled_checkbox = addon_data.config.CheckBoxFactory(
        "PlayerEnabledCheckBox",
        panel,
        " Enable",
        "Enables the player's swing bars.",
        addon_data.player.EnabledCheckBoxOnClick)
    panel.enabled_checkbox:SetPoint("TOPLEFT", 10, -40)
    -- Show Off-Hand Checkbox
    panel.show_offhand_checkbox = addon_data.config.CheckBoxFactory(
        "PlayerShowOffHandCheckBox",
        panel,
        " Show Off-Hand",
        "Enables the player's off-hand swing bar.",
        addon_data.player.ShowOffHandCheckBoxOnClick)
    panel.show_offhand_checkbox:SetPoint("TOPLEFT", 10, -60)
    -- Show Border Checkbox
    panel.show_border_checkbox = addon_data.config.CheckBoxFactory(
        "PlayerShowBorderCheckBox",
        panel,
        " Show border",
        "Enables the player bar's border.",
        addon_data.player.ShowBorderCheckBoxOnClick)
    panel.show_border_checkbox:SetPoint("TOPLEFT", 10, -80)
    -- Show Classic Bars Checkbox
    panel.classic_bars_checkbox = addon_data.config.CheckBoxFactory(
        "PlayerClassicBarsCheckBox",
        panel,
        " Classic bars",
        "Enables the classic texture for the player's bars.",
        addon_data.player.ClassicBarsCheckBoxOnClick)
    panel.classic_bars_checkbox:SetPoint("TOPLEFT", 10, -100)
    -- Fill/Empty Checkbox
    panel.fill_empty_checkbox = addon_data.config.CheckBoxFactory(
        "PlayerFillEmptyCheckBox",
        panel,
        " Fill / Empty",
        "Determines if the bar is full or empty when a swing is ready.",
        addon_data.player.FillEmptyCheckBoxOnClick)
    panel.fill_empty_checkbox:SetPoint("TOPLEFT", 10, -120)
    -- Show Left Text Checkbox
    panel.show_left_text_checkbox = addon_data.config.CheckBoxFactory(
        "PlayerShowLeftTextCheckBox",
        panel,
        " Show Left Text",
        "Enables the player's left side text.",
        addon_data.player.ShowLeftTextCheckBoxOnClick)
    panel.show_left_text_checkbox:SetPoint("TOPLEFT", 10, -140)
    -- Show Right Text Checkbox
    panel.show_right_text_checkbox = addon_data.config.CheckBoxFactory(
        "PlayerShowRightTextCheckBox",
        panel,
        " Show Right Text",
        "Enables the player's right side text.",
        addon_data.player.ShowRightTextCheckBoxOnClick)
    panel.show_right_text_checkbox:SetPoint("TOPLEFT", 10, -160)
    
    -- Width EditBox
    panel.width_editbox = addon_data.config.EditBoxFactory(
        "PlayerWidthEditBox",
        panel,
        "Bar Width",
        75,
        25,
        addon_data.player.WidthEditBoxOnEnter)
    panel.width_editbox:SetPoint("TOPLEFT", 200, -60, "BOTTOMRIGHT", 275, -85)
    -- Height EditBox
    panel.height_editbox = addon_data.config.EditBoxFactory(
        "PlayerHeightEditBox",
        panel,
        "Bar Height",
        75,
        25,
        addon_data.player.HeightEditBoxOnEnter)
    panel.height_editbox:SetPoint("TOPLEFT", 280, -60, "BOTTOMRIGHT", 355, -85)
    -- X Offset EditBox
    panel.x_offset_editbox = addon_data.config.EditBoxFactory(
        "PlayerXOffsetEditBox",
        panel,
        "X Offset",
        75,
        25,
        addon_data.player.XOffsetEditBoxOnEnter)
    panel.x_offset_editbox:SetPoint("TOPLEFT", 200, -110, "BOTTOMRIGHT", 275, -135)
    -- Y Offset EditBox
    panel.y_offset_editbox = addon_data.config.EditBoxFactory(
        "PlayerYOffsetEditBox",
        panel,
        "Y Offset",
        75,
        25,
        addon_data.player.YOffsetEditBoxOnEnter)
    panel.y_offset_editbox:SetPoint("TOPLEFT", 280, -110, "BOTTOMRIGHT", 355, -135)
    
    -- Main-hand color picker
    panel.main_color_picker = addon_data.config.color_picker_factory(
        'PlayerMainColorPicker',
        panel,
        settings.main_r, settings.main_g, settings.main_b, settings.main_a,
        'Main-hand Bar Color',
        addon_data.player.MainColorPickerOnClick)
    panel.main_color_picker:SetPoint('TOPLEFT', 205, -150)
    -- Main-hand color text picker
    panel.main_text_color_picker = addon_data.config.color_picker_factory(
        'PlayerMainTextColorPicker',
        panel,
        settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a,
        'Main-hand Bar Text Color',
        addon_data.player.MainTextColorPickerOnClick)
    panel.main_text_color_picker:SetPoint('TOPLEFT', 205, -170)
    -- Off-hand color picker
    panel.off_color_picker = addon_data.config.color_picker_factory(
        'PlayerOffColorPicker',
        panel,
        settings.off_r, settings.off_g, settings.off_b, settings.off_a,
        'Off-hand Bar Color',
        addon_data.player.OffColorPickerOnClick)
    panel.off_color_picker:SetPoint('TOPLEFT', 205, -200)
    -- Off-hand color text picker
    panel.off_text_color_picker = addon_data.config.color_picker_factory(
        'PlayerOffTextColorPicker',
        panel,
        settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a,
        'Off-hand Bar Text Color',
        addon_data.player.OffTextColorPickerOnClick)
    panel.off_text_color_picker:SetPoint('TOPLEFT', 205, -220)
    
    -- In Combat Alpha Slider
    panel.in_combat_alpha_slider = addon_data.config.SliderFactory(
        "PlayerInCombatAlphaSlider",
        panel,
        "In Combat Alpha",
        0,
        1,
        0.05,
        addon_data.player.CombatAlphaOnValChange)
    panel.in_combat_alpha_slider:SetPoint("TOPLEFT", 405, -60)
    -- Out Of Combat Alpha Slider
    panel.ooc_alpha_slider = addon_data.config.SliderFactory(
        "PlayerOOCAlphaSlider",
        panel,
        "Out of Combat Alpha",
        0,
        1,
        0.05,
        addon_data.player.OOCAlphaOnValChange)
    panel.ooc_alpha_slider:SetPoint("TOPLEFT", 405, -110)
    -- Backplane Alpha Slider
    panel.backplane_alpha_slider = addon_data.config.SliderFactory(
        "PlayerBackplaneAlphaSlider",
        panel,
        "Backplane Alpha",
        0,
        1,
        0.05,
        addon_data.player.BackplaneAlphaOnValChange)
    panel.backplane_alpha_slider:SetPoint("TOPLEFT", 405, -160)
    
    -- Return the final panel
    addon_data.player.UpdateConfigPanelValues()
    return panel
end

