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

addon.author   = 'MathMatic';
addon.name     = 'ninCast';
addon.desc     = 'One click wheel casting.';
addon.version  = '0.2';

require ('common');
local imgui = require('imgui');
local settings = require('settings');
local inventory = require('inventory');

local ninSpells = T{
    {spellName = 'Raiton',  spellId = 333,     itemId = 1173,    itemName = "Hiraishin",    color={1.0, 0.0, 1.0, 0.8}},
    {spellName = 'Doton',   spellId = 330,     itemId = 1170,    itemName = "Makibishi",    color={1.0, 1.0, 0.0, 0.8}},
    {spellName = 'Huton',   spellId = 327,     itemId = 1167,    itemName = "Kawahori-ogi", color={0.0, 1.0, 0.0, 0.8}},
    {spellName = 'Hyoton',  spellId = 324,     itemId = 1164,    itemName = "Tsurara",      color={0.0, 1.0, 1.0, 0.8}}, 
    {spellName = 'Katon',   spellId = 321,     itemId = 1161,    itemName = "Uchitake",     color={1.0, 0.0, 0.0, 0.8}},
    {spellName = 'Suiton',  spellId = 336,     itemId = 1176,    itemName = "Mizu-deppo",   color={0.5, 0.5, 1.0, 0.8}},
};

local spellLevels = T{
    {idx = 1, lvl = 'Ichi'},
    {idx = 2, lvl = 'Ni'},
    {idx = 3, lvl = 'San'},
};

local defaultConfig = T{
    showGui = T{true};
    castLevel = 2;
}
local config = settings.load(defaultConfig);

local spellIdx = 0;
local configMenuOpen = {false};

--------------------------------------------------------------------
function castNextSpell(targetModifier)
    local spellToCast = ninSpells[1 + spellIdx].spellName .. ": "
    if (useNi == true) then
        spellToCast = spellToCast .. "Ni";
    else
        spellToCast = spellToCast .. "Ichi";
    end

    if (targetModifier == nil) then
        targetModifier = "<t>";
    end

    command = '/ma "' .. spellToCast .. '" ' .. targetModifier;
    AshitaCore:GetChatManager():QueueCommand(1, command);

end

--------------------------------------------------------------------
local function NinjutsuCost(item)
    local itemCount = 0;
    --for _,item in ipairs(items) do
        local itemData = inventory:GetItemData(item);
        if (itemData ~= nil) then
            for _,itemEntry in ipairs(itemData.Locations) do
                if (itemEntry.Container == 0) then
                    itemCount = itemCount + inventory:GetItemTable(itemEntry.Container, itemEntry.Index).Count;
                end
            end
        end
    --end

    return itemCount;
end

--------------------------------------------------------------------
ashita.events.register('load', 'load_cb', function()

end);

--------------------------------------------------------------------
ashita.events.register('unload', 'unload_cb', function()

end);

--------------------------------------------------------------------
ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = e.command:args();
    if (#args == 0 or not args[1]:any("/nin")) then
        return;
    end

    -- Block all related commands..
    e.blocked = true;

	if (#args == 1) then
        configMenuOpen[1] = not configMenuOpen[1];

    elseif (args[2]:any('cast')) then
        castNextSpell(args[3]);

        spellIdx = (spellIdx + 1) % 6;

    elseif (#args == 2 and args[2]:any('next')) then
        spellIdx = (spellIdx + 1) % 6;

    elseif (#args == 2 and args[2]:any('prev')) then
        spellIdx = (spellIdx - 1);
        if (spellIdx < 0) then
            spellIdx = 5;
        end

    end

--    if (#args == 2 and args[2]:any('ichi')) then
--        useNi = false;
--    end

--    if (#args == 2 and args[2]:any('ni')) then
--        useNi = true;
--    end

end);

--------------------------------------------------------------------
ashita.events.register('text_in', 'Clammy_HandleText', function (e)

end);




--------------------------------------------------------------------
function renderMenu();

	imgui.SetNextWindowSize({500});

	if (imgui.Begin(string.format('%s v%s Configuration', addon.name, addon.version), configMenuOpen, bit.bor(ImGuiWindowFlags_AlwaysAutoResize))) then

		imgui.Text("Options");

		imgui.Checkbox('Show GUI', config.showGui);
		imgui.ShowHelp('Shows the GUI.');

        local helpText = "";
        if (imgui.BeginCombo('Spell Level', spellLevels[config.castLevel].lvl, ImGuiComboFlags_None)) then
            for idx,lvl in ipairs(spellLevels) do
                --if (imgui.Selectable(lvl, spellLevels[config.castLevel] == spellLevels[lvl])) then
                --    config.castLevel = lvl;
                --end
                --if (imgui.Selectable(lvl, true)) then
                --    config.castLevel = lvl;
                --end
                helpText = helpText .. " " .. lvl;
            end
            imgui.EndCombo();
        end
        imgui.ShowHelp(helpText);

        --imgui.ShowHelp('Use the selected cast level (Ichi, Ni, San)');



        imgui.Separator();
        imgui.Separator();
        imgui.Separator();
		if (imgui.Button('  Reset  ')) then
            settings.reset();
            print(chat.header(addon.name):append(chat.message('Settings reset to default.')));
		end
		imgui.ShowHelp('Resets settings to their default state.');
        imgui.Separator();
        imgui.Separator();
        imgui.Separator();
	end
    --imgui.PopStyleColor(3);
	imgui.End();
end





--------------------------------------------------------------------
--[[
* event: d3d_present
* desc : Event called when the Direct3D device is presenting a scene.
--]]
ashita.events.register('d3d_present', 'present_cb', function ()
    local player = GetPlayerEntity();
	if (player == nil) then -- when zoning
		return;
	end
--
    if (configMenuOpen[1] == true) then
        renderMenu();
    end


	local windowSize = 180;
    imgui.SetNextWindowBgAlpha(0.8);
    imgui.SetNextWindowSize({ windowSize, -1, }, ImGuiCond_Always);
	if (imgui.Begin('NinHelper', true, bit.bor(ImGuiWindowFlags_NoDecoration))) then

        for idx,spell in ipairs(ninSpells) do
            if (idx == spellIdx + 1) then
                imgui.Text(">");
            else
                imgui.Text(" ");
            end
            imgui.SameLine();
            imgui.TextColored(spell.color, spell.spellName .. ":");
            imgui.SameLine();
            if (useNi == true) then
                imgui.TextColored(spell.color, "Ni");
            else
                imgui.TextColored(spell.color, "Ichi");
            end

            local toolsRemaining = tostring(NinjutsuCost(spell.itemId));
            imgui.SameLine();
            imgui.SetCursorPosX(imgui.GetCursorPosX() + 30 - imgui.CalcTextSize(spell.spellName));
            imgui.Text(" (" .. toolsRemaining .. ")");

            local recastTime = "0";
            --if (useNi == true) then
            --    recastTime = tostring(math.floor(AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(spell.spellId) / 60));
            --else
            --    recastTime = tostring(math.floor(AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(spell.spellId-1) / 60));
            --end
            imgui.SameLine();
            imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x - imgui.CalcTextSize(recastTime));
            imgui.Text(recastTime);


        end

    end
    imgui.End();

end);