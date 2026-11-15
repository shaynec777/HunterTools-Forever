local _,F=...
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b=pcall(fn,...);if ok then return a,b end
end
local function num(v) return type(v)=='number' and v==v and math.abs(v)<1e8 end
local function xy(pos) if pos then return query(pos.GetXY,pos) end end
local bounds={};local built=false;local locations={}
function F.ClassicAmmoVendorLocation(v)
    if locations[v.id] then local p=locations[v.id];return p.mapID,p.x,p.y end
    if not num(v.worldX) or not num(v.worldY) or not CreateVector2D then return end
    if not built then
        -- Native client map transforms, including city maps. No map addon used.
        for id=1411,1458 do
            local instance,a=query(C_Map and C_Map.GetWorldPosFromMapPos,id,CreateVector2D(.25,.25))
            local other,b=query(C_Map and C_Map.GetWorldPosFromMapPos,id,CreateVector2D(.75,.75))
            local ax,ay=xy(a);local bx,by=xy(b)
            if instance==other and num(instance) and num(ax) and num(ay) and num(bx) and num(by) and ax~=bx and ay~=by then
                local width,height=(ay-by)*2,(ax-bx)*2
                bounds[#bounds+1]={mapID=id,instance=instance,left=ay+width*.25,top=ax+height*.25,width=width,height=height,area=math.abs(width*height)}
            end
        end
        table.sort(bounds,function(a,b) return a.area<b.area end);built=#bounds>0
    end
    for _,b in ipairs(bounds) do
        if b.instance==v.instance then
            local x,y=(b.left-v.worldY)/b.width,(b.top-v.worldX)/b.height
            if x>=0 and x<=1 and y>=0 and y<=1 then locations[v.id]={mapID=b.mapID,x=x,y=y};return b.mapID,x,y end
        end
    end
end
-- Era has no native C_Minimap.GetViewRadius. These are the native zoom widths
-- in yards. Determine the active zoom group without overwriting Blizzard APIs.
if not F.ClassicMinimap.GetViewRadius then
    local widths={outdoor={[0]=466+2/3,400,333+1/3,266+1/3,200,133+1/3},indoor={[0]=300,240,180,120,80,50}}
    local cache={};local dirty=true;local probing=false
    local events=CreateFrame('Frame');events:RegisterEvent('MINIMAP_UPDATE_ZOOM')
    events:SetScript('OnEvent',function() if not probing then dirty=true end end)
    function F.ClassicMinimap.GetViewRadius()
        if not Minimap then return end
        local zoom=query(Minimap.GetZoom,Minimap)
        local outside=tonumber(query(GetCVar,'minimapZoom'));local inside=tonumber(query(GetCVar,'minimapInsideZoom'))
        if not num(zoom) or zoom%1~=0 or zoom<0 or zoom>5 or not outside or not inside then return end
        local mode
        if outside~=inside then mode=outside==zoom and 'outdoor' or inside==zoom and 'indoor' or nil
        else
            local now=query(GetTime) or 0
            if not cache.mode or cache.zoom~=zoom or cache.outside~=outside or cache.inside~=inside or dirty and now-(cache.checkedAt or -2)>1 then
                if InCombatLockdown() or type(Minimap.SetZoom)~='function' then return end
                probing=true
                local probe=zoom==0 and 1 or zoom-1
                local ok=pcall(Minimap.SetZoom,Minimap,probe)
                if ok then
                    if tonumber(query(GetCVar,'minimapZoom'))==probe then mode='outdoor'
                    elseif tonumber(query(GetCVar,'minimapInsideZoom'))==probe then mode='indoor' end
                end
                pcall(Minimap.SetZoom,Minimap,zoom);probing=false
                cache={mode=mode,zoom=zoom,outside=outside,inside=inside,checkedAt=now};dirty=false
            else mode=cache.mode end
        end
        return mode and widths[mode][zoom]/2
    end
end
