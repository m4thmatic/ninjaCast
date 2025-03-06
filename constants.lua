local constants = T{};

constants.ninEleSpells = T{
    {spellName = "Hyoton",  spellId = 323,     itemId = 1164,    itemName = "Tsurara",      color={0.0, 1.0, 1.0, 0.8}}, 
    {spellName = "Katon",   spellId = 320,     itemId = 1161,    itemName = "Uchitake",     color={1.0, 0.0, 0.0, 0.8}},
    {spellName = "Suiton",  spellId = 335,     itemId = 1176,    itemName = "Mizu-deppo",   color={0.5, 0.5, 1.0, 0.8}},
    {spellName = "Raiton",  spellId = 332,     itemId = 1173,    itemName = "Hiraishin",    color={1.0, 0.0, 1.0, 0.8}},
    {spellName = "Doton",   spellId = 329,     itemId = 1170,    itemName = "Makibishi",    color={1.0, 1.0, 0.0, 0.8}},
    {spellName = "Huton",   spellId = 326,     itemId = 1167,    itemName = "Kawahori-ogi", color={0.0, 1.0, 0.0, 0.8}},
};
constants.eleSpellList = {"Hyoton","Katon","Suiton","Raiton","Doton","Huton"};

constants.ninNonEleSpells = T{
    {spellName = "Utsusemi", spellId = 338,     itemId = 1179,    itemName = "Shihei"},
    {spellName = "Jubaku",   spellId = 341,     itemId = 1182,    itemName = "Jusatsu"},
    {spellName = "Hojo",     spellId = 344,     itemId = 1185,    itemName = "Kaginawa"},
    {spellName = "Kurayami", spellId = 347,     itemId = 1188,    itemName = "Sairui-ran"},
    {spellName = "Dokumori", spellId = 350,     itemId = 1191,    itemName = "Kodoku"},
    {spellName = "Tonko",    spellId = 353,     itemId = 1194,    itemName = "Shinobi-tabi"}, 
}
--constants.nonEleSpellList = {"Utsusemi","Jubaku","Hojo","Kurayami","Dokumori","Tonko"};

constants.additionalNinTools = T{
    {itemId = 2971,     itemName="Inoshishinofuda"},
}

return constants;



--[[
#define ITEM_INOSHISHINOFUDA (2971)
]]