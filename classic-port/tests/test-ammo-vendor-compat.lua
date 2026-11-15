local F={ClassicMinimap={}}
local function vec(x,y) return {x=x,y=y,GetXY=function(self) return self.x,self.y end} end
CreateVector2D=vec
C_Map={GetWorldPosFromMapPos=function(id,p) if id==1411 then return 1,vec(1000-200*p.y,1000-400*p.x) end end}
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
InCombatLockdown=function() return false end
GetTime=function() return 10 end
local zoom,outside,inside=3,3,3
local mode='outdoor'
GetCVar=function(name) return tostring(name=='minimapZoom' and outside or inside) end
Minimap={GetZoom=function() return zoom end,SetZoom=function(_,v) zoom=v;if mode=='outdoor' then outside=v else inside=v end end}
assert(loadfile('source/HunterToolsClassic/ClassicAmmoVendorCompat.lua'))('test',F)
local map,x,y=F.ClassicAmmoVendorLocation({id=1,instance=1,worldX=900,worldY=800})
assert(map==1411 and math.abs(x-.5)<.0001 and math.abs(y-.5)<.0001,'native Classic map inverse transform')
assert(not F.ClassicAmmoVendorLocation({id=2,instance=0,worldX=900,worldY=800}),'different continent not projected')
assert(math.abs(F.ClassicMinimap.GetViewRadius()-(266+1/3)/2)<.0001 and zoom==3 and outside==3 and inside==3,'ambiguous zoom group probed and restored')
outside=5;inside=2;zoom=2;mode='indoor'
assert(F.ClassicMinimap.GetViewRadius()==90,'indoor radius')
outside=5;inside=2;zoom=5;mode='outdoor'
assert(math.abs(F.ClassicMinimap.GetViewRadius()-(133+1/3)/2)<.0001,'outdoor radius')
zoom=9;assert(not F.ClassicMinimap.GetViewRadius(),'invalid zoom suppressed')
print('Classic vendor map/minimap compatibility passed')
