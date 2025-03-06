local consts = require("constants");
local imgui = require("imgui");
local funcs = require("funcs");
local settings = require("settings");
local chat = require('chat');

local gui = T{};


-------------------------------------------------------------------------------
gui.renderGUI = function(config, gdiObj)
    -- Don't show anything when zoning or if the given menus are displayed (e.g. the map)
    local player = GetPlayerEntity();
    if(hideWindow() or player == nil) then
        gdiObj:set_visible(false);
        return;
    end

    --Menu
    if (config.configMenuOpen[1] == true) then --If menu is open
        renderMenu(config, gdiObj);
    end

    --Ninjutsu Window
    if(displayNinjutsuWindow(config)) then
        renderNinjutsuWindow(config);
    end

    --Shadow Counter
    if(displayShadowCounter(config)) then
        gdiObj:set_text(funcs.GetShadowCount());
        gdiObj:set_visible(true);
    else
        gdiObj:set_visible(false);
    end
end

--------------------------------------------------------------------
gui.setGDITextAttributes = function(config, gdiObj)
	-- Set the text attributes
	local tc = config.settings.shadowText.textColor;
	local tc2 = config.settings.shadowText.textColor2;
	local oc = config.settings.shadowText.outlineColor;
	gdiObj:set_font_color(funcs.argbToHex(config.settings.shadowText.textOpacity, tc[1], tc[2], tc[3]));
	gdiObj:set_gradient_color(funcs.argbToHex(config.settings.shadowText.textOpacity, tc2[1], tc2[2], tc2[3]));
	gdiObj:set_outline_color(funcs.argbToHex(config.settings.shadowText.textOpacity, oc[1], oc[2], oc[3]));
	gdiObj:set_position_x(config.settings.shadowText.position_x);
	gdiObj:set_position_y(config.settings.shadowText.position_y);
    gdiObj:set_font_height(config.settings.shadowText.textSize * 2);
    gdiObj:set_outline_width(config.settings.shadowText.outlineWidth)
end


-------------------------------------------------------------------------------
function displayNinjutsuWindow(config)
    local mainJob = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
    local ninJobId = 13;

    if(not config.settings.components.showSpellWindow[1]) then
        return false
    end

    if(config.settings.components.showSpellWhenNin[1] and (mainJob ~= ninJobId)) then
        return false
    end

    if(config.settings.components.hideWhenChatOpen[1]) then
        return not isChatLogOpen();
    end

    return true
end

-------------------------------------------------------------------------------
function displayShadowCounter(config)
    local mainJob = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
	local subJob = AshitaCore:GetMemoryManager():GetPlayer():GetSubJob();
    local ninJobId = 13;

    if(not config.settings.components.showShadowCounter[1]) then
        return false
    end
    
    if(config.settings.components.showShadowCounterWhenNin[1]
       and (mainJob ~= ninJobId and subJob ~= ninJobId)) then
        return false
    end

    return true
end

-------------------------------------------------------------------------------
function renderNinjutsuWindow(config)
    imgui.SetNextWindowBgAlpha(config.settings.spellWindow.opacity[1]);
    imgui.SetNextWindowSize({ -1, -1, }, ImGuiCond_Always);
    imgui.PushStyleColor(ImGuiCol_WindowBg, config.settings.spellWindow.backgroundColor);
    imgui.PushStyleColor(ImGuiCol_Border, config.settings.spellWindow.borderColor);
    imgui.PushStyleColor(ImGuiCol_Text, config.settings.spellWindow.textColor);
    if (imgui.Begin('ninjaCastWheel', true, bit.bor(ImGuiWindowFlags_NoDecoration))) then
        imgui.SetWindowFontScale(config.settings.spellWindow.scale[1]); -- set window scale
        
        --imgui.Text("Current   Tools       Recast");
        --imgui.Text("Spell     Remaining   Ichi   Ni");

        imgui.Text("Current   ");
        if (config.settings.components.showSpellTools[1]) then
            imgui.SameLine(); imgui.Text("Tools      ");
        end
        if (config.settings.components.showRecastIchi[1] or 
            config.settings.components.showRecastNi[1] or
            config.settings.components.showRecastSan[1]) then
            if (config.settings.components.showToolNames[1]) then
                    imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("                                   "));
                    imgui.Text("Recast");
            else
                imgui.SameLine(); imgui.Text("Recast");
            end
        end

        imgui.Text("Spell     ");
        if (config.settings.components.showSpellTools[1]) then
            imgui.SameLine(); imgui.Text("Remaining  ");
        end

        if (config.settings.components.showToolNames[1]) then
            imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("                                  ")); imgui.Text("");
        end
        
        if (config.settings.components.showRecastIchi[1]) then
            imgui.SameLine(); imgui.Text("Ichi  ");
        end
        if (config.settings.components.showRecastNi[1]) then
            imgui.SameLine(); imgui.Text("Ni   ");
        end
        if (config.settings.components.showRecastSan[1]) then
            imgui.SameLine(); imgui.Text("San  ");
        end

        imgui.Separator();


        local firstSpellIdx = config.settings.components.firstSpellIdx;
        for i = 0, (#(consts.eleSpellList) - 1), 1 do
            idx = 1 + (firstSpellIdx + i -1) % #(consts.eleSpellList)
            spell = consts.ninEleSpells[idx]

            if (config.settings.components.showEleSpellList[1]) then
                --If show current spell is selected, and displaying spell arrow
                if (idx == funcs.getCurrentSpell()) and (config.settings.components.showWheelArrow[1]) then
                    imgui.TextColored({1.0, 0.95, 0.0, 0.8}, ">");
                else
                    imgui.Text(" ");
                end
                imgui.SameLine();
                imgui.TextColored(spell.color, spell.spellName .. ":");

                imgui.SameLine();
                imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.CalcTextSize("      ") - imgui.CalcTextSize(spell.spellName));
                imgui.Text("");
                if (config.settings.components.showSpellTools[1]) then
                    local toolsRemaining = tostring(funcs.ninjaToolsRemaining(spell.itemId));
                    imgui.SameLine();
                    imgui.Text(" [" .. toolsRemaining .. "]");
                    if (config.settings.components.showToolNames[1]) then
                        imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("                  "));
                        imgui.Text(" " .. spell.itemName .. "");
                        imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("                                  ")); imgui.Text("") 
                    else
                        imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("                      ")); imgui.Text("") 
                    end
                end

                if (config.settings.components.showRecastIchi[1]) then
                    local recastIchiTime = tostring(math.floor(AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(spell.spellId) / 60));
                    imgui.SameLine(); imgui.Text(recastIchiTime);
                    imgui.SameLine(); imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.CalcTextSize("     ") - imgui.CalcTextSize(recastIchiTime)); imgui.Text("");
                end
                if (config.settings.components.showRecastNi[1]) then
                    local recastNiTime = tostring(math.floor(AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(spell.spellId+1) / 60));;
                    imgui.SameLine(); imgui.Text(recastNiTime);
                    imgui.SameLine(); imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.CalcTextSize("     ") - imgui.CalcTextSize(recastNiTime)); imgui.Text("");
                end
                if (config.settings.components.showRecastSan[1]) then
                    local recastSanTime = tostring(math.floor(AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(spell.spellId+2) / 60));;
                    imgui.SameLine(); imgui.Text(recastSanTime);
                end
            end
        end
        
        if(config.settings.components.showSpellTools[1] and config.settings.components.showInoTools[1]) then
            imgui.TextColored({1.0, 0.0, 0.0, 0.8}, "I"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("  "));
            imgui.TextColored({1.0, 0.4, 0.0, 0.8}, "n"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("   "));
            imgui.TextColored({1.0, 0.8, 0.0, 0.8}, "o"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("    "));
            imgui.TextColored({0.8, 1.0, 0.0, 0.8}, "s"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("     "));
            imgui.TextColored({0.4, 1.0, 0.0, 0.8}, "h"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("      "));
            imgui.TextColored({0.0, 1.0, 0.0, 0.8}, "i"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("       "));
            imgui.TextColored({0.0, 1.0, 0.4, 0.8}, "s"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("        "));
            imgui.TextColored({0.0, 1.0, 0.8, 0.8}, "h"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("         "));
            imgui.TextColored({0.0, 0.8, 1.0, 0.8}, "i"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("          "));
            imgui.TextColored({0.0, 0.7, 1.0, 0.8}, "n"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("           "));
            imgui.TextColored({0.0, 0.6, 1.0, 0.8}, "o"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("            "));
            imgui.TextColored({0.6, 0.0, 1.0, 1.0}, "f"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("             "));
            imgui.TextColored({0.8, 0.0, 1.0, 0.8}, "u"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("              "));
            imgui.TextColored({1.0, 0.0, 0.8, 0.8}, "d"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("               "));
            imgui.TextColored({1.0, 0.0, 0.4, 0.8}, "a"); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("                "));
            imgui.Text(":"); imgui.SameLine();
            imgui.Text(tostring(funcs.ninjaToolsRemaining(consts.additionalNinTools[1].itemId)));
        end


        imgui.Separator();
        for idx, spell in ipairs(consts.ninNonEleSpells) do
            if (config.settings.components.nonEleSpellList[idx][1]) then
                imgui.Text(spell.spellName .. ":  ");
                
                imgui.SameLine();
                imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.CalcTextSize("      ") - imgui.CalcTextSize(spell.spellName));
                imgui.Text("");
                if (config.settings.components.showSpellTools[1]) then
                    local toolsRemaining = tostring(funcs.ninjaToolsRemaining(spell.itemId));
                    imgui.SameLine();
                    imgui.Text(" [" .. toolsRemaining .. "]");
                    if (config.settings.components.showToolNames[1]) then
                        imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("                  "));
                        imgui.Text(" " .. spell.itemName .. "");
                        imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("                                  ")); imgui.Text("") 
                    else
                        imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("                      ")); imgui.Text("") 
                    end
                end
    
                if (config.settings.components.showRecastIchi[1]) then
                    local recastIchiTime = tostring(math.floor(AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(spell.spellId) / 60));
                    imgui.SameLine(); imgui.Text(recastIchiTime);
                    imgui.SameLine(); imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.CalcTextSize("     ") - imgui.CalcTextSize(recastIchiTime)); imgui.Text("");
                end
                if (config.settings.components.showRecastNi[1]) then
                    local recastNiTime = tostring(math.floor(AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(spell.spellId+1) / 60));;
                    imgui.SameLine(); imgui.Text(recastNiTime);
                    imgui.SameLine(); imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.CalcTextSize("     ") - imgui.CalcTextSize(recastNiTime)); imgui.Text("");
                end
                if (config.settings.components.showRecastSan[1]) then
                    local recastSanTime = tostring(math.floor(AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(spell.spellId+2) / 60));;
                    imgui.SameLine(); imgui.Text(recastSanTime);
                end
            end
        end

        imgui.SetWindowFontScale(1.0); -- reset window scale
    end
    imgui.PopStyleColor(3);
    imgui.End();
end



-------------------------------------------------------------------------------
function renderMenu(config, gdiObj)
	imgui.SetNextWindowSize({-1});

	if (imgui.Begin(string.format('%s v%s Configuration', addon.name, addon.version), config.configMenuOpen, bit.bor(ImGuiWindowFlags_AlwaysAutoResize))) then

		imgui.Text("ninjaCast Menu");
        imgui.Separator();
        imgui.Text(" ");

        if imgui.BeginTabBar('ninjaCastMenuBar') then
            if imgui.BeginTabItem('Spell Window') then
                imgui.Text("Spell Window Options")
                imgui.Text("")

                imgui.Checkbox('Show Spell Window', config.settings.components.showSpellWindow);
                imgui.ShowHelp('Shows the Spell Window.');

                imgui.Checkbox('Show only when NIN', config.settings.components.showSpellWhenNin);
                imgui.ShowHelp('Shows the GUI only when main job is set to ninja.');

                imgui.Checkbox('Hide when Chat is open', config.settings.components.hideWhenChatOpen);
                imgui.ShowHelp('Hides the spell window when the chat is expanded.');

                imgui.Text("")

                imgui.Checkbox('Show tool count', config.settings.components.showSpellTools);
                imgui.ShowHelp('Shows the tool count for elemental spells.');

                imgui.Checkbox('Show tool name', config.settings.components.showToolNames);
                imgui.ShowHelp('Shows the name of the tool for each spell.');                
                
                imgui.Checkbox('Show inoshishinofuda count', config.settings.components.showInoTools);
                imgui.ShowHelp('Shows the number of remaining inoshishinofuda tools.');

                imgui.Text("")

                imgui.Checkbox('Show recast times :Ichi', config.settings.components.showRecastIchi);
                imgui.ShowHelp('Shows Ichi recast timers.');
    
                imgui.Checkbox('Show recast times :Ni', config.settings.components.showRecastNi);
                imgui.ShowHelp('Shows Ni recast timers.');

                imgui.Checkbox('Show recast times :San', config.settings.components.showRecastSan);
                imgui.ShowHelp('Shows San recast timers.');

                -- 
                imgui.Text(" ")
                imgui.Separator();

                imgui.Checkbox('Show Elemental Spells', config.settings.components.showEleSpellList);
                imgui.ShowHelp('Shows the Elemental Spells.');

                imgui.Checkbox(' - Show Current Wheel Spell (arrow)', config.settings.components.showWheelArrow);
                imgui.ShowHelp('Shows the wheel spell to cast next.');

                local spellName = consts.eleSpellList[config.settings.components.firstSpellIdx];
                if (imgui.BeginCombo('First Spell in List', spellName)) then
                    for i = 1,#(consts.eleSpellList),1 do
                        local is_selected = consts.eleSpellList[i] == spellName;

                        if (imgui.Selectable(consts.eleSpellList[i], is_selected) and consts.eleSpellList[i] ~= spellName) then
                            --spellName = consts.eleSpellList[i];
                            config.settings.components.firstSpellIdx = i;
                            funcs.resetSpellIdx(config);
                        end

                        if (is_selected) then
                            imgui.SetItemDefaultFocus();
                        end
                    end
                    imgui.EndCombo();
                end
                imgui.ShowHelp('Select which spell shows up at the top of the elemental wheel');
  
                imgui.Text(" ")
                imgui.Text("Show the following ninja spells: ")

                for idx, spell in ipairs(consts.ninNonEleSpells) do
                    imgui.Checkbox(" - " .. spell.spellName, config.settings.components.nonEleSpellList[idx]);
                end
  
                imgui.Text(" ")
                imgui.Separator();
                imgui.Text("Window Settings")
    
                imgui.SliderFloat('Window Scale', config.settings.spellWindow.scale, 0.1, 2.0, '%.2f');
                imgui.ShowHelp('Scale the window bigger/smaller.');
    
                imgui.SliderFloat('Window Opacity', config.settings.spellWindow.opacity, 0.1, 1.0, '%.2f');
                imgui.ShowHelp('Set the window opacity.');
    
                imgui.ColorEdit4("Text Color", config.settings.spellWindow.textColor);
                imgui.ColorEdit4("Border Color", config.settings.spellWindow.borderColor);
                imgui.ColorEdit4("Background Color", config.settings.spellWindow.backgroundColor);

                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Shadow Counter') then
                imgui.Text("Shadow Cpunter Options")
                imgui.Text("")

                imgui.Checkbox('Show Shadow Counter', config.settings.components.showShadowCounter);
                imgui.ShowHelp('Shows the number of current shadows.');

                imgui.Checkbox('Show only when NINs or /NIN', config.settings.components.showShadowCounterWhenNin);
                imgui.ShowHelp('Shows the shadow counter only when main/subjob is set to ninja.');

                imgui.Text(" ")
                imgui.Separator();
                imgui.Text("Window Settings")

                local textOpacity  = T{config.settings.shadowText.textOpacity};
                local textSize     = T{config.settings.shadowText.textSize};			
                local outlineWidth = T{config.settings.shadowText.outlineWidth};

                imgui.SliderFloat('Window Opacity', textOpacity, 0.01, 1.0, '%.2f');
                imgui.ShowHelp('Set the window opacity.');		
                config.settings.shadowText.textOpacity = textOpacity[1];
                
                imgui.SliderFloat('Font Size', textSize, 10, 80, '%1.0f');
                imgui.ShowHelp('Set the font size.');
                config.settings.shadowText.textSize = textSize[1];
                gdiObj:set_font_height(config.settings.shadowText.textSize * 2);

                imgui.ColorEdit3("Top Color", config.settings.shadowText.textColor);
                imgui.ColorEdit3("Bottom Color", config.settings.shadowText.textColor2);
                imgui.ColorEdit3("Outline Color", config.settings.shadowText.outlineColor);
                
                gui.setGDITextAttributes(config, gdiObj);

                imgui.SliderFloat('Outline Width', outlineWidth, 0, 10, '%1.0f');
                imgui.ShowHelp('Set the thickness of the text outline.');
                config.settings.shadowText.outlineWidth = outlineWidth[1];
                gdiObj:set_outline_width(config.settings.shadowText.outlineWidth)

                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Commands') then
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

                imgui.EndTabItem();
            end
            imgui.EndTabBar();
        end

        --------------------------------------------------------------------

        imgui.Text(" ");
        imgui.Text(" ");
        imgui.Separator();

        if (imgui.Button('  Save  ')) then
			settings.save();
			config.configMenuOpen[1] = false;
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

--- Determines if the map is open in game, or we are at the login screen
function hideWindow()
    local menuName = funcs.GetMenuName();
    return menuName:match('menu%s+map.*') ~= nil
        or menuName:match('menu%s+scanlist.*') ~= nil
        or menuName:match('menu%s+cnqframe') ~= nil
		or menuName:match('menu%s+dbnamese') ~= nil
		or menuName:match('menu%s+ptc6yesn') ~= nil
end

--- Determines if the chat log is open
function isChatLogOpen()
    local menuName = funcs.GetMenuName();
    return menuName:match('menu%s+fulllog')
end


return gui;