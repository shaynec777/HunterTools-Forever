local _,F=...
local markedGUID
local function rememberedGUID()
    local guid
    if F.db then guid=F.db.ammoVendorRaidGUID else guid=markedGUID end
    if type(guid)=='string' and guid:match('^Creature%-%d+%-%d+%-%d+%-%d+%-%d+%-') then return guid end
end
local function remember(guid)
    markedGUID=guid
    if F.db then F.db.ammoVendorRaidGUID=guid end
end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,value=pcall(fn,...)
    if ok and (not issecretvalue or not issecretvalue(value)) then return value end
end
-- Share the secure hardware-click implementation with trainer marking.
function F.SetupAmmoVendorMarkButton(button,selection,afterSelect)
    F.SetupNPCMarkButton(button,selection,function(v)
        F.SelectAmmoVendor(v)
        if afterSelect then afterSelect() end
    end,remember)
end
-- Only a hardware-click secure button may remove the native X. Conversation
-- events still clear navigation only. Never target by name to clear: macros
-- cannot verify the acquired GUID before removing a different NPC's marker.
function F.SetupAmmoVendorClearButton(button)
    button:RegisterForClicks('LeftButtonUp');button:SetAttribute('useOnKeyDown',false)
    button:SetScript('PreClick',function(self)
        if InCombatLockdown() then return end
        local guid=rememberedGUID()
        local function exact(unit)
            return type(unit)=='string' and guid and query(UnitGUID,unit)==guid
        end
        local unit
        for _,token in ipairs({'target','mouseover','npc'}) do if exact(token) then unit=token;break end end
        if not unit then
            local plates=query(C_NamePlate and C_NamePlate.GetNamePlates)
            for _,plate in pairs(type(plates)=='table' and plates or {}) do
                if query(plate.IsForbidden,plate)~=true then
                    local token=query(plate.GetUnit,plate) or plate.namePlateUnitToken
                    if (not issecretvalue or not issecretvalue(token)) and type(token)=='string' and token:match('^nameplate%d+$') and exact(token) then unit=token;break end
                end
            end
        end
        local index=unit and query(GetRaidTargetIndex,unit)
        local macro
        if unit and (index==7 or index==nil) then macro=unit=='target' and '/tm [nocombat] 0' or '/tm [@'..unit..',exists,nocombat] 0' end
        self.clearUnit=unit;self.clearGUID=guid
        self:SetAttribute('type',macro and 'macro' or nil);self:SetAttribute('macrotext',macro)
    end)
    button:SetScript('PostClick',function(self)
        if InCombatLockdown() then return end
        self:SetAttribute('type',nil);self:SetAttribute('macrotext',nil)
        F.ClearAmmoVendorMarker()
        local index=self.clearUnit and query(GetRaidTargetIndex,self.clearUnit)
        if self.clearUnit and query(UnitGUID,self.clearUnit)==self.clearGUID and index~=nil and index~=7 then
            remember(nil)
        elseif rememberedGUID() then F.Print('Map markers cleared. Target the marked vendor and press Clear Vendor Mark again if its red X remains.') end
        self.clearUnit=nil;self.clearGUID=nil
    end)
end
