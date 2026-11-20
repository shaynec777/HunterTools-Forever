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
local F={db={},Print=function() end}
assert(loadfile('HunterTools/TrainerData.lua'))('test',F)
assert(loadfile('HunterTools/Trainers.lua'))('test',F)
F.SelectAmmoVendor=function(v) F.ammoVendorDestination=v;return true end
F.ClearAmmoVendorMarker=function() F.ammoVendorDestination=nil end
assert(loadfile('HunterTools/AmmoVendorWorldMarker.lua'))('test',F)
local events=frames[1]
assert(not events.scripts.OnUpdate,'idle updater must be absent')

local v={id=5116,name='Dalmond',mapID=1455,x=.7,y=.84}
local mark=widget();F.SetupAmmoVendorMarkButton(mark,function() return v end)
mark.scripts.PreClick(mark);assert(mark.attrs.macrotext=='/targetexact [nocombat] Dalmond')
range=true;mark.scripts.PreClick(mark);assert(mark.attrs.macrotext=='/tm [exists,nocombat] !7\n/targetexact [nocombat] Dalmond')
local raidIndex=7
GetRaidTargetIndex=function() return raidIndex end
mark.scripts.PostClick(mark);assert(F.ammoVendorDestination==v and not mark.attrs.macrotext)
assert(F.db.ammoVendorRaidGUID==guids.target,'remember marked identity across reload')
assert(loadfile('HunterTools/AmmoVendorWorldMarker.lua'))('test',F) -- Simulate Lua-session reload with saved identity.
local clear=widget();F.SetupAmmoVendorClearButton(clear)
clear.scripts.PreClick(clear);assert(clear.attrs.macrotext=='/tm [nocombat] 0')
raidIndex=secret;clear.scripts.PreClick(clear)
assert(clear.attrs.macrotext=='/tm [nocombat] 0','unreadable icon does not suppress exact-vendor clear')
clear.scripts.PostClick(clear);assert(F.db.ammoVendorRaidGUID==guids.target,'unknown result must not forget marked identity')
raidIndex=7
local guid=guids.target;guids.target='Creature-0-1-0-0-9999-0001'
clear.scripts.PreClick(clear);assert(not clear.attrs.macrotext,'never clear other target')
clear.scripts.PostClick(clear);assert(not F.ammoVendorDestination)
guids.mouseover=guid;clear.scripts.PreClick(clear)
assert(clear.attrs.macrotext=='/tm [@mouseover,exists,nocombat] 0','clear remembered exact vendor without switching target')
raidIndex=8;clear.scripts.PreClick(clear);assert(not clear.attrs.macrotext,'preserve replacement icon')
raidIndex=7;clear.scripts.PreClick(clear);raidIndex=0;clear.scripts.PostClick(clear)
raidIndex=7;clear.scripts.PreClick(clear);assert(not clear.attrs.macrotext,'forget confirmed cleared vendor')
range=secret;mark.scripts.PreClick(mark);assert(not mark.attrs.macrotext:find('/tm',1,true))
assert(not events.scripts.OnUpdate,'no retry updater')
print('PASS: secure vendor Mark/Clear, exact GUID, range, replacement icon, target preservation and no retries')
