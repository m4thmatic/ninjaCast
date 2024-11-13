--[[
* Addons - Copyright (c) 2021 Ashita Development Team
* Contact: https://www.ashitaxi.com/
* Contact: https://discord.gg/Ashita
*
* This file is part of Ashita.
*
* Ashita is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Ashita is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Ashita.  If not, see <https://www.gnu.org/licenses/>.

--]]

addon.author   = 'Mathemagic';
addon.name     = 'ninjaCast';
addon.desc     = 'One click wheel casting / spell timers / tool counter / etc.';
addon.version  = '1.1';

require ('common');
local gui = require('gui');
local funcs = require("funcs");
--local consts = require("constants");
--local imgui = require('imgui');
local settings = require('settings');
local chat = require('chat');
local gdi = require('gdifonts.include');
local ffi = require('ffi');

ffi.cdef[[
    int16_t GetKeyState(int32_t vkey);
]]


local defaultConfig = T{
	spellWindow = T{
		scale			= T{1.0},
		opacity			= T{0.8},
		backgroundColor	= T{0.23, 0.23, 0.26, 1.0},
		textColor		= T{1.00, 1.00, 1.00, 1.0},
		borderColor		= T{0.00, 0.00, 0.00, 1.0},
	},

    shadowText = T{
        textSize     = 20,
        textOpacity	 = 1.0,
        textColor	 = T{1.00, 1.00, 1.00, 1.0},
        textColor2	 = T{1.00, 1.00, 1.00, 1.0},
        outlineColor = T{0.00, 0.00, 0.00, 1.0},	
        outlineWidth = 4,
        position_x   = 120;
        position_y   = 60;
    },

	components = T{
        showSpellWindow  = T{true};
        showSpellTools   = T{true};
        showToolNames    = T{false};
        showRecastIchi   = T{true};
        showRecastNi     = T{true};
        showRecastSan    = T{false};
        showWheelArrow   = T{true};
        showSpellWhenNin = T{true};
        firstSpellIdx    = 1;
        showEleSpellList = T{true};
        nonEleSpellList  = T{{true},{false},{false},{false},{false},{false}};
        showInoTools     = T{false};

        showShadowCounter        = T{true};
        showShadowCounterWhenNin = T{true};

	},
}
local config = T{
    settings = settings.load(defaultConfig),

    configMenuOpen = {false};
}

local fontSettings = {
    box_height = 0,
    box_width = 0,
    font_family = 'Courier New',
    font_flags = gdi.FontFlags.Bold,
    font_alignment = gdi.Alignment.Center,
    font_height = config.settings.shadowText.textSize * 2,
    font_color = 0xFFFFFFFF,
    gradient_color = 0xFFFFFFFF,
    outline_color = 0xFF000000,
    gradient_style = gdi.Gradient.TopToBottom,
    outline_width = config.settings.shadowText.outlineWidth,
    position_x = config.settings.shadowText.position_x,
    position_y = config.settings.shadowText.position_y,
    visible = true,
    text = '',
};
local shadowTextObj;

local lastPositionX, lastPositionY;
local dragActive = false;


--------------------------------------------------------------------
local function HitTest(x, y)
    local rect = shadowTextObj.rect;
    if (rect) then
        local currentX = shadowTextObj.settings.position_x;
        local currentY = shadowTextObj.settings.position_y;
        return (x >= (currentX - rect.right)) and (x <= (currentX + rect.right)) and (y >= (currentY - rect.bottom)) and ((y <= currentY + rect.bottom));
    else
        return false;
    end        
end

local function IsControlHeld()
    return (bit.band(ffi.C.GetKeyState(0x10), 0x8000) ~= 0);
end

--------------------------------------------------------------------
ashita.events.register('load', 'load_cb', function()
	shadowTextObj = gdi:create_object(fontSettings, false);
    gui.setGDITextAttributes(config, shadowTextObj);
    funcs.resetSpellIdx(config);
end);

--------------------------------------------------------------------
ashita.events.register('unload', 'unload_cb', function()
    settings.save();
    gdi:destroy_interface();
end);

--------------------------------------------------------------------
settings.register('settings', 'settings_update', function(s)
    -- Update the settings table..
    if (s ~= nil) then
        config.settings = s;
 
         -- Save the current settings..
        settings.save();
 
        gui.setGDITextAttributes(config, shadowTextObj);
    end
	
end);

--------------------------------------------------------------------
ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = e.command:args();
    if (#args == 0 or not args[1]:any("/nin")) then
        return;
    end

	if (#args == 1) then
        config.configMenuOpen[1] = not config.configMenuOpen[1];
    elseif (args[2]:any('cast')) then
        funcs.castNextSpell(args[3], args[4]);
    elseif (#args == 2 and args[2]:any('next')) then
        funcs.nextSpell();
    elseif (#args == 2 and args[2]:any('prev')) then
        funcs.prevSpell();
    else
        --If not a ninjaCast command, don't block to allow normal "/nin spellname" casting
        e.blocked = false;
        return;
    end

    --Otherwise block /nin command from client
    e.blocked = true;

end);

--------------------------------------------------------------------
ashita.events.register('packet_in', 'packet_in_cb', function (e)
    local playerId = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);
    local userId = struct.unpack('L', e.data, 0x05 + 1);            --Action Packet [05:0] (uint)
    local actionType = ashita.bits.unpack_be(e.data_raw, 10, 2, 4); --Action Packet [0A:2] (4 bits)
    local abilityID = ashita.bits.unpack_be(e.data_raw, 10, 6, 16); --Action Packet [0C:6] (16 bits)

    if (userId == playerId) then
        if (actionType == 4) then
            if(funcs.isNinjutsu(abilityID)) then
                funcs.nextSpell();
            end
        end
    end    

end);

--------------------------------------------------------------------
ashita.events.register('mouse', 'mouse_cb', function (e)
    if (dragActive) then
        local currentX = shadowTextObj.settings.position_x;
        local currentY = shadowTextObj.settings.position_y;
        shadowTextObj:set_position_x(currentX + (e.x - lastPositionX));
        shadowTextObj:set_position_y(currentY + (e.y - lastPositionY));
        lastPositionX = e.x;
        lastPositionY = e.y;
        if (e.message == 514) or (IsControlHeld() == false) then
            dragActive = false;
            e.blocked = true;
			
			config.settings.shadowText.position_x = shadowTextObj.settings.position_x;
			config.settings.shadowText.position_y = shadowTextObj.settings.position_y;
			settings.save();
            return;
        end
    end
    
    if (e.message == 513) then
        if (HitTest(e.x, e.y)) and (IsControlHeld()) then
            e.blocked = true;
            dragActive = true;
            lastPositionX = e.x;
            lastPositionY = e.y;
            return;
        end
    end

end);

--------------------------------------------------------------------
--[[
* event: d3d_present
* desc : Event called when the Direct3D device is presenting a scene.
--]]
ashita.events.register('d3d_present', 'present_cb', function ()
    gui.renderGUI(config, shadowTextObj);
end);