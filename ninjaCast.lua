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
addon.version  = '0.5';

require ('common');
local imgui = require('imgui');
local settings = require('settings');
local chat = require('chat');
local gdi = require('gdifonts.include');
local ffi = require('ffi');

ffi.cdef[[
    int16_t GetKeyState(int32_t vkey);
]]


local defaultConfig = T{
	eleWindow = T{
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
        showEleWindow       = T{true};
        showEleTools        = T{true};
        showEleRecastIchi   = T{true};
        showEleRecastNi     = T{true};
        showEleArrow        = T{true};

        showShadowCounter = T{true};

	},
}
local config = T{
    settings = settings.load(defaultConfig),
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
local myFontObject;

local lastPositionX, lastPositionY;
local dragActive = false;


local ninSpells = T{
    {spellName = 'Hyoton',  spellId = 323,     itemId = 1164,    itemName = "Tsurara",      color={0.0, 1.0, 1.0, 0.8}}, 
    {spellName = 'Katon',   spellId = 320,     itemId = 1161,    itemName = "Uchitake",     color={1.0, 0.0, 0.0, 0.8}},
    {spellName = 'Suiton',  spellId = 335,     itemId = 1176,    itemName = "Mizu-deppo",   color={0.5, 0.5, 1.0, 0.8}},
    {spellName = 'Raiton',  spellId = 332,     itemId = 1173,    itemName = "Hiraishin",    color={1.0, 0.0, 1.0, 0.8}},
    {spellName = 'Doton',   spellId = 329,     itemId = 1170,    itemName = "Makibishi",    color={1.0, 1.0, 0.0, 0.8}},
    {spellName = 'Huton',   spellId = 326,     itemId = 1167,    itemName = "Kawahori-ogi", color={0.0, 1.0, 0.0, 0.8}},
};

local spellIdx = 0;
local configMenuOpen = {false};


--------------------------------------------------------------------------------
-------------- This function is copied from the XITools addon ------------------
--------------------------------------------------------------------------------
local menuBase = ashita.memory.find('FFXiMain.dll', 0, '8B480C85C974??8B510885D274??3B05', 16, 0);

--- Gets the name of the top-most menu element.
function GetMenuName()
    local subPointer = ashita.memory.read_uint32(menuBase);
    local subValue = ashita.memory.read_uint32(subPointer);
    if (subValue == 0) then
        return '';
    end
    local menuHeader = ashita.memory.read_uint32(subValue + 4);
    local menuName = ashita.memory.read_string(menuHeader + 0x46, 16);
    return string.gsub(menuName, '\x00', '');
end

--- Determines if the map is open in game, or we are at the login screen
function hideWindow()
    local menuName = GetMenuName();
    return menuName:match('menu%s+map.*') ~= nil
        or menuName:match('menu%s+scanlist.*') ~= nil
        or menuName:match('menu%s+cnqframe') ~= nil
		or menuName:match('menu%s+dbnamese') ~= nil
		or menuName:match('menu%s+ptc6yesn') ~= nil
end

--------------------------------------------------------------------
function castNextSpell(spellType, targetModifier)
    local spellToCast = ninSpells[1 + spellIdx].spellName .. ": "

    if (spellType == nil) then
        print(chat.header(addon.name):append(chat.message('No spell type specified.')));
        return
    end
    spellType = string.lower(spellType)

    if (spellType == "ni") or (spellType == "ichi") or (spellType == "san") then
        spellToCast = spellToCast .. spellType;
    else
        print(chat.header(addon.name):append(chat.message('No spell type:' .. spellType)));
        return
    end

    if (targetModifier == nil) then
        targetModifier = "<t>";
    end

    command = '/ma "' .. spellToCast .. '" ' .. targetModifier;
    AshitaCore:GetChatManager():QueueCommand(1, command);

end

--------------------------------------------------------------------
local function ninjaToolsRemaining(itemId)
    local inventory = AshitaCore:GetMemoryManager():GetInventory();
    local resources = AshitaCore:GetResourceManager();

    local itemCount = 0;

    for invSlot = 0,inventory:GetContainerCountMax(0) do
        local item = inventory:GetContainerItem(0, invSlot);
        if ((item ~= nil) and (item.Id == itemId)) then
            itemCount = itemCount + item.Count;
        end
    end

    return itemCount;
end

--------------------------------------------------------------------
local function GetShadowCount()
    local me = AshitaCore:GetMemoryManager():GetPlayer()
    local buffs = me:GetBuffs()

    for _, buff in pairs(buffs) do
        if buff == 66 or buff == 67 then
          return "1";
        elseif buff == 444 then
          return "2";
        elseif buff == 445 then
          return "3";
        elseif buff == 446 then
          return "4";
        end
    end
    return "0";
end

--------------------------------------------------------------------
local function HitTest(x, y)
    local rect = myFontObject.rect;
    if (rect) then
        local currentX = myFontObject.settings.position_x;
        local currentY = myFontObject.settings.position_y;
        return (x >= (currentX - rect.right)) and (x <= (currentX + rect.right)) and (y >= (currentY - rect.bottom)) and ((y <= currentY + rect.bottom));
    else
        return false;
    end        
end

local function IsControlHeld()
    return (bit.band(ffi.C.GetKeyState(0x10), 0x8000) ~= 0);
end

--------------------------------------------------------------------
local function setGDITextAttributes()
	-- Set the text attributes
	local tc = config.settings.shadowText.textColor;
	local tc2 = config.settings.shadowText.textColor2;
	local oc = config.settings.shadowText.outlineColor;
	myFontObject:set_font_color(argbToHex(config.settings.shadowText.textOpacity, tc[1], tc[2], tc[3]));
	myFontObject:set_gradient_color(argbToHex(config.settings.shadowText.textOpacity, tc2[1], tc2[2], tc2[3]));
	myFontObject:set_outline_color(argbToHex(config.settings.shadowText.textOpacity, oc[1], oc[2], oc[3]));
	myFontObject:set_position_x(config.settings.shadowText.position_x);
	myFontObject:set_position_y(config.settings.shadowText.position_y);
end

--------------------------------------------------------------------
function hexToRBG(hexVal)
	local alpha = bit.band(bit.rshift(hexVal, 24), 0xff)/0xff;
	local red   = bit.band(bit.rshift(hexVal, 16), 0xff)/0xff;
	local green = bit.band(bit.rshift(hexVal,  8), 0xff)/0xff;
	local blue  = bit.band(bit.rshift(hexVal,  0), 0xff)/0xff;

	--return alpha, red, green, blue;
	return red, green, blue;
end

function argbToHex(alpha, red, green, blue)
	return	math.floor(alpha * 0xff) * 0x1000000 + 
			bit.lshift(red   * 0xff, 16) +
			bit.lshift(green * 0xff,  8) +
			bit.lshift(blue  * 0xff,  0);
end

--------------------------------------------------------------------
function renderMenu();

	imgui.SetNextWindowSize({-1});

	if (imgui.Begin(string.format('%s v%s Configuration', addon.name, addon.version), configMenuOpen, bit.bor(ImGuiWindowFlags_AlwaysAutoResize))) then

		imgui.Text("GUI Options");
        imgui.Text(" ");
        imgui.Separator();
        --------------------------------------------------------------------
		imgui.BeginChild('wheelSettings', { 0, 300, }, true);

            imgui.Text("Wheel Window Options");
            imgui.Text(" ");

            imgui.Checkbox('Show Elemental Wheel', config.settings.components.showEleWindow);
            imgui.ShowHelp('Shows the Elemental Wheel Window.');

            imgui.Checkbox(' - Show tool count', config.settings.components.showEleTools);
            imgui.ShowHelp('Shows the tool count.');

            imgui.Checkbox(' - Show recast times :Ichi', config.settings.components.showEleRecastIchi);
            imgui.ShowHelp('Shows the GUI.');

            imgui.Checkbox(' - Show recast times :Ni', config.settings.components.showEleRecastNi);
            imgui.ShowHelp('Shows the GUI.');

            --imgui.Checkbox('Show recast times :San', config.settings.components.showEleRecastSan);
            --imgui.ShowHelp('Shows the GUI.');

            imgui.Checkbox(' - Show Current Wheel Spell', config.settings.components.showEleArrow);
            imgui.ShowHelp(' - Shows the wheel spell to cast next.');

            imgui.SliderFloat('Window Scale', config.settings.eleWindow.scale, 0.1, 2.0, '%.2f');
            imgui.ShowHelp('Scale the window bigger/smaller.');

            imgui.SliderFloat('Window Opacity', config.settings.eleWindow.opacity, 0.1, 1.0, '%.2f');
            imgui.ShowHelp('Set the window opacity.');

            imgui.ColorEdit4("Text Color", config.settings.eleWindow.textColor);
            imgui.ColorEdit4("Border Color", config.settings.eleWindow.borderColor);
            imgui.ColorEdit4("Background Color", config.settings.eleWindow.backgroundColor);
        imgui.EndChild();

        --------------------------------------------------------------------
        --imgui.Text(" ");
        --imgui.Separator();
        --------------------------------------------------------------------

        imgui.BeginChild('shadowCountSettings', { 0, 250, }, true);
    		imgui.Text("Shadow Counter Options");
            imgui.Text(" ");

            imgui.Checkbox('Show Shadow Counter', config.settings.components.showShadowCounter);
            imgui.ShowHelp('Shows the number of current shadows.');

            local textOpacity  = T{config.settings.shadowText.textOpacity};
            local textSize     = T{config.settings.shadowText.textSize};			
            local outlineWidth = T{config.settings.shadowText.outlineWidth};
            local alwaysShow   = T{config.settings.shadowText.alwaysShow};			

            imgui.SliderFloat('Window Opacity', textOpacity, 0.01, 1.0, '%.2f');
            imgui.ShowHelp('Set the window opacity.');		
            config.settings.shadowText.textOpacity = textOpacity[1];
            
            imgui.SliderFloat('Font Size', textSize, 10, 80, '%1.0f');
            imgui.ShowHelp('Set the font size.');
            config.settings.shadowText.textSize = textSize[1];
            myFontObject:set_font_height(config.settings.shadowText.textSize * 2);

            imgui.ColorEdit3("Top Color", config.settings.shadowText.textColor);
            imgui.ColorEdit3("Bottom Color", config.settings.shadowText.textColor2);
            imgui.ColorEdit3("Outline Color", config.settings.shadowText.outlineColor);
            
            setGDITextAttributes();

            imgui.SliderFloat('Outline Width', outlineWidth, 0, 10, '%1.0f');
            imgui.ShowHelp('Set the thickness of the text outline.');
            config.settings.shadowText.outlineWidth = outlineWidth[1];
            myFontObject:set_outline_width(config.settings.shadowText.outlineWidth)
        imgui.EndChild();

        imgui.Separator();
        imgui.Text(" ");
        imgui.Text("Commands:");
        imgui.Text(" ");
        imgui.Text("/nin              | This Menu");
        imgui.Text("/nin cast ichi *  | Cast the current :Ichi spell and move to next");
        imgui.Text("/nin cast ni *    | Cast the current :Ni spell and move to next");
        imgui.Text("/nin next         | Skip to the next spell");
        imgui.Text("/nin prev         | Move to the previous spell");

        imgui.Text(" ");
        imgui.Text("* Optional target modifier. Defaults to <t>, can use custom modifier");
        imgui.Text("if desired, i.e. <stnpc>");

        imgui.Text(" ");
        imgui.Text(" ");
        if (imgui.Button('  Save  ')) then
			settings.save();
			configMenuOpen[1] = false;
            print(chat.header(addon.name):append(chat.message('Settings saved.')));
		end
        imgui.SameLine();
		if (imgui.Button('  Reset  ')) then
            settings.reset();
            print(chat.header(addon.name):append(chat.message('Settings reset to default.')));
		end
		imgui.ShowHelp('Resets settings to their default state.');
        imgui.Separator();
	end
	imgui.End();
end

--------------------------------------------------------------------
function renderWheelWindow();
    imgui.SetNextWindowBgAlpha(config.settings.eleWindow.opacity[1]);
    imgui.SetNextWindowSize({ -1, -1, }, ImGuiCond_Always);
    imgui.PushStyleColor(ImGuiCol_WindowBg, config.settings.eleWindow.backgroundColor);
    imgui.PushStyleColor(ImGuiCol_Border, config.settings.eleWindow.borderColor);
    imgui.PushStyleColor(ImGuiCol_Text, config.settings.eleWindow.textColor);

    if (imgui.Begin('ninjaCastWheel', true, bit.bor(ImGuiWindowFlags_NoDecoration))) then
        imgui.SetWindowFontScale(config.settings.eleWindow.scale[1]); -- set window scale
        imgui.Text("Current   Tools       Recast");
        imgui.Text("Spell     Remaining   Ichi   Ni");
        imgui.Separator();
        for idx,spell in ipairs(ninSpells) do
            --If show current spell is selected, and displaying spell arrow
            if (idx == spellIdx + 1) and (config.settings.components.showEleArrow[1]) then
                imgui.TextColored({1.0, 0.95, 0.0, 0.8}, ">");
            else
                imgui.Text(" ");
            end
            imgui.SameLine();
            imgui.TextColored(spell.color, spell.spellName .. ":");
            
            imgui.SameLine();
            if (config.settings.components.showEleTools[1]) then
                local toolsRemaining = tostring(ninjaToolsRemaining(spell.itemId));
                imgui.SameLine();
                --imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.CalcTextSize("     ") - imgui.CalcTextSize(spell.spellName));
                imgui.SetCursorPosX(imgui.CalcTextSize("          "))
                imgui.Text(" [" .. toolsRemaining .. "]");
            end
            if (config.settings.components.showEleRecastIchi[1]) then
                local recastIchiTime = tostring(math.floor(AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(spell.spellId) / 60));
                imgui.SameLine();
                imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x - imgui.CalcTextSize(recastIchiTime) - imgui.CalcTextSize("      "));
                imgui.Text(recastIchiTime);
            end
            if (config.settings.components.showEleRecastNi[1]) then
                local recastNiTime = tostring(math.floor(AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(spell.spellId+1) / 60));;
                imgui.SameLine();
                imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x - imgui.CalcTextSize(recastNiTime) - imgui.CalcTextSize(" "));
                imgui.Text(recastNiTime);
            end
        end
        imgui.SetWindowFontScale(1.0); -- reset window scale
    end
    imgui.PopStyleColor(3);
    imgui.End();

end

--------------------------------------------------------------------
ashita.events.register('load', 'load_cb', function()
	myFontObject = gdi:create_object(fontSettings, false);
    setGDITextAttributes();
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
 
        setGDITextAttributes();
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
        configMenuOpen[1] = not configMenuOpen[1];
    elseif (args[2]:any('cast')) then
        castNextSpell(args[3], args[4]);
        --spellIdx = (spellIdx + 1) % 6;
    elseif (#args == 2 and args[2]:any('next')) then
        spellIdx = (spellIdx + 1) % 6;
    elseif (#args == 2 and args[2]:any('prev')) then
        spellIdx = (spellIdx - 1);
        if (spellIdx < 0) then
            spellIdx = 5;
        end
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
    local userId = struct.unpack('L', e.data, 0x05 + 1);
    local actionType = ashita.bits.unpack_be(e.data_raw, 10, 2, 4);
    local abilityID = ashita.bits.unpack_be(e.data_raw, 10, 6, 16);
    --local abilityID = bit.band(bit.rshift(struct.unpack('H', e.data, 0x0A + 0x01),6), 0xffff);

    if (userId == playerId) then
        if (actionType == 4) then
            for idx, spell in pairs(ninSpells) do
                if (abilityID == spell.spellId) or 
                   (abilityID == spell.spellId+1) or
                   (abilityID == spell.spellId+2) then
                    spellIdx = idx % 6;
                end
            end
              

        end
    end    

end);

--------------------------------------------------------------------
ashita.events.register('text_in', 'Clammy_HandleText', function (e)

end);

--------------------------------------------------------------------
ashita.events.register('mouse', 'mouse_cb', function (e)
    if (dragActive) then
        local currentX = myFontObject.settings.position_x;
        local currentY = myFontObject.settings.position_y;
        myFontObject:set_position_x(currentX + (e.x - lastPositionX));
        myFontObject:set_position_y(currentY + (e.y - lastPositionY));
        lastPositionX = e.x;
        lastPositionY = e.y;
        if (e.message == 514) or (IsControlHeld() == false) then
            dragActive = false;
            e.blocked = true;
			
			config.settings.shadowText.position_x = myFontObject.settings.position_x;
			config.settings.shadowText.position_y = myFontObject.settings.position_y;
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

    if(hideWindow()) then
        myFontObject:set_visible(false);
        return;
    end

    local player = GetPlayerEntity();
	if (player == nil) then -- when zoning
		return;
	end

    if (configMenuOpen[1] == true) then --If menu is open
        renderMenu();
    end

    if (config.settings.components.showEleWindow[1]) then --If show elemental wheel window is selected
        renderWheelWindow();
    end


    if (config.settings.components.showShadowCounter[1]) then --If show elemental wheel window is selected
        myFontObject:set_visible(true);
        myFontObject:set_text(GetShadowCount());
    else
        myFontObject:set_visible(false);
    end

end);