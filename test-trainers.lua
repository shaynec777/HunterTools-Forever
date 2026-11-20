local frames={}
local function widget()
 local w={scripts={},attrs={},shown=false,events={}}
 setmetatable(w,{__index=function(_,k) if k=='CreateTexture' or k=='CreateFontString' then return widget end;if k:match('^[A-Z]') then return function() end end end})
 function w:SetScript(k,v) self.scripts[k]=v end
 function w:SetAttribute(k,v) self.attrs[k]=v end
 function w:RegisterEvent(k) self.events[k]=true end
 function w:Hide() self.shown=false end
 function w:Show() self.shown=true end
 function w:IsShown() return self.shown end
 function w:GetWidth() return 1000 end
 function w:GetHeight() return 600 end
 function w:GetFrameLevel() return 5 end
 function w:SetText(v) self.text=v end
 function w:SetBackdropBorderColor(...) self.border={...} end
 frames[#frames+1]=w;return w
end
CreateFrame=widget
local combat=false;InCombatLockdown=function() return combat end
local secret={};issecretvalue=function(v) return v==secret end
local map,faction,level=1455,'Alliance',20
local range=false
local guids={target='Creature-0-1-0-0-5116-0001'}
UnitGUID=function(u) return guids[u] end
UnitFactionGroup=function() return faction end;UnitLevel=function() return level end
CheckInteractDistance=function() return range end
CreateVector2D=function(x,y) return {GetXY=function() return x,y end} end
C_Map={GetBestMapForUnit=function() return map end,GetPlayerMapPosition=function() return CreateVector2D(.7,.84) end,
 GetWorldPosFromMapPos=function(m,p) if m==999 then return 2,p end;return 1,p end}
local F={Print=function() end}
assert(loadfile('HunterTools/TrainerData.lua'))('test',F)
assert(loadfile('HunterTools/Trainers.lua'))('test',F)
local events=frames[1]
assert(not events.scripts.OnUpdate,'idle updater must be absent')
local rows=F.TrainerRows('hunter',false)
assert(#rows==3 and rows[1].trainer.id==5116)
assert(#F.TrainerRows('pet',false)==1)
faction='Horde';assert(#F.TrainerRows('hunter',false)==0);faction='Alliance'
for _,r in ipairs(F.TrainerRows('hunter',true)) do assert(not r.trainer.starter) end
level=1;local starter=false
for _,r in ipairs(F.TrainerRows('hunter',true)) do if r.trainer.starter then starter=true end end
assert(starter);level=20
local v=rows[1].trainer
local button=widget();F.SetupTrainerMarkButton(button,function() return v end)
button.scripts.PreClick(button)
assert(button.attrs.macrotext=='/targetexact [nocombat] Olmin Burningbeard','out of range may target but never X')
range=true;button.scripts.PreClick(button)
assert(button.attrs.macrotext=='/tm [exists,nocombat] !7\n/targetexact [nocombat] Olmin Burningbeard')
local selected
local originalSelect=F.SelectTrainer
F.SelectTrainer=function(t) selected=t end
button.scripts.PostClick(button);assert(selected==v and not button.attrs.macrotext)
F.SelectTrainer=originalSelect
GetRaidTargetIndex=function() return 7 end
local clear=widget();F.SetupTrainerClearButton(clear);clear.scripts.PreClick(clear)
assert(clear.attrs.macrotext=='/tm [nocombat] 0')
GetRaidTargetIndex=function() return 8 end
clear.scripts.PreClick(clear);assert(not clear.attrs.macrotext,'must not clear a replacement raid mark')
range=secret;button.scripts.PreClick(button);assert(not button.attrs.macrotext:find('/tm',1,true))
range=true;combat=true;local before=button.attrs.macrotext
button.scripts.PreClick(button);button.scripts.PostClick(button);assert(button.attrs.macrotext==before)
assert(#F.TrainerRows('hunter',true)==0);combat=false
UIParent=widget();UISpecialFrames={}
Minimap=widget();Minimap:Show();C_Minimap={GetViewRadius=function() return 100 end}
local canvas=widget();WorldMapFrame=widget();WorldMapFrame:Show()
WorldMapFrame.GetCanvas=function() return canvas end;WorldMapFrame.GetMapID=function() return v.mapID end
OpenWorldMap=function(m) assert(m==v.mapID) end
assert(F.SelectTrainer(v));assert(events.scripts.OnUpdate)
assert(F.trainerPin.shown and F.trainerMiniPin.shown)
assert(F.trainerPin.badge.border[1]==1 and F.trainerPin.badge.border[2]==.2)
assert(F.trainerMiniPin.border[1]==1 and F.trainerMiniPin.border[2]==.2)
assert(F.trainerPin.label.text:find('|cffff6666',1,true))
guids.npc='Creature-0-1-0-0-9999-0001';events.scripts.OnEvent();assert(F.trainerDestination)
guids.npc=guids.target;events.scripts.OnEvent();assert(not F.trainerDestination and not events.scripts.OnUpdate)
assert(not F.trainerPin.shown and not F.trainerMiniPin.shown)
F.HideConfigPages=function() end;F.OpenTrainers()
assert(F.trainerPanel.shown and #F.trainerPanel.rows==6)
F.trainerPanel.kindButton.scripts.OnClick();assert(F.trainerPanel.kind=='pet')
F.trainerPanel.zones.scripts.OnClick();assert(F.trainerPanel.allZones)
print('Trainer selection, secure click, combat and idle-update tests passed')
