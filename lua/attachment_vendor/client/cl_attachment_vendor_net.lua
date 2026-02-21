surface.CreateFont("AttachmentVendorTitle", { font = "Open Sans Condensed", size = 28, weight = 600, antialias = true })
surface.CreateFont("AttachmentVendorHeader", { font = "Open Sans Condensed", size = 22, weight = 500, antialias = true })
surface.CreateFont("AttachmentVendorText",   { font = "Open Sans Condensed", size = 16, weight = 300, antialias = true })
surface.CreateFont("AttachmentVendorPrice",  { font = "Open Sans Condensed", size = 22, weight = 600, antialias = true })
surface.CreateFont("AttachmentVendorButton", { font = "Open Sans Condensed", size = 22, weight = 700, antialias = true })
surface.CreateFont("AttachmentVendorEuro",   { font = "Open Sans Condensed", size = 22, weight = 200, antialias = true })

net.Receive("attvend_notify", function()
   local t = net.ReadUInt(8); local dur = net.ReadUInt(8); local s = net.ReadString()
   notification.AddLegacy(s, t, dur); surface.PlaySound("buttons/button15.wav"); print(s)
end)

-- Presets local JSON storage
local AV_PRESETS = {}
local PRESET_FILE = "attachment_vendor_presets.json"

-- Load presets from local JSON file
local function loadPresets()
   AV_PRESETS = {}
   local filePath = "attachment_vendor/" .. PRESET_FILE
   
   if file.Exists(filePath, "DATA") then
      local content = file.Read(filePath, "DATA")
      if content and #content > 0 then
         local success, data = pcall(util.JSONToTable, content)
         if success and istable(data) then
            AV_PRESETS = data
            -- Ensure all presets have required fields
            for i, preset in ipairs(AV_PRESETS) do
               if not preset.name then preset.name = "" end
               if not preset.weapon then preset.weapon = "" end
               if not preset.atts or not istable(preset.atts) then preset.atts = {} end
            end
         end
      end
   end
   
   if hook and hook.Run then hook.Run("AttachmentVendor_PresetsUpdated") end
end

-- Save presets to local JSON file
local function savePresets()
   local filePath = "attachment_vendor/" .. PRESET_FILE
   local success, json = pcall(util.TableToJSON, AV_PRESETS, true)
   if success and json and #json > 0 then
      file.CreateDir("attachment_vendor")
      file.Write(filePath, json)
   else
      ErrorNoHalt("[Attachment Vendor] Failed to save presets to JSON: " .. tostring(json or "unknown error") .. "\n")
   end
end

-- Add or update a preset
local function savePreset(name, weaponClass, atts)
   name = tostring(name or "")
   weaponClass = tostring(weaponClass or "")
   atts = istable(atts) and atts or {}
   
   -- Remove existing preset with same name
   for i = #AV_PRESETS, 1, -1 do
      if AV_PRESETS[i].name == name then
         table.remove(AV_PRESETS, i)
      end
   end
   
   -- Add new preset
   table.insert(AV_PRESETS, {
      name = name,
      weapon = weaponClass,
      atts = atts
   })
   
   savePresets()
   if hook and hook.Run then hook.Run("AttachmentVendor_PresetsUpdated") end
end

-- Delete a preset by name
local function deletePreset(name)
   name = tostring(name or "")
   
   for i = #AV_PRESETS, 1, -1 do
      if AV_PRESETS[i].name == name then
         table.remove(AV_PRESETS, i)
      end
   end
   
   savePresets()
   if hook and hook.Run then hook.Run("AttachmentVendor_PresetsUpdated") end
end

-- Load presets on client init
local loadPresetsTimer = nil
hook.Add("Initialize", "AttachmentVendorLoadPresets", function()
   if loadPresetsTimer then timer.Remove(loadPresetsTimer) end
   loadPresetsTimer = "AttachmentVendorLoadPresets"
   timer.Create(loadPresetsTimer, 0.1, 1, function()
      loadPresets()
      loadPresetsTimer = nil
   end)
end)

-- Presets networking (client cache - now loads from local storage)
net.Receive("attvend_presets_list", function()
   -- Server no longer sends presets, but we keep this for compatibility
   -- Presets are loaded from local JSON storage
   local count = net.ReadUInt(12)
   -- Ignore server data, use local storage
   if hook and hook.Run then hook.Run("AttachmentVendor_PresetsUpdated") end
end)

-- Receive save result from server (server validates, client saves only on success)
net.Receive("attvend_presets_save_result", function()
   local success = net.ReadBool()
   
   if success then
      local presetName = net.ReadString()
      local weaponClass = net.ReadString()
      local count = net.ReadUInt(12)
      local validAtts = {}
      for i = 1, count do
         table.insert(validAtts, net.ReadString())
      end
      local oldPresetName = net.ReadString() -- Original name if editing
      
      -- Only save after server validation succeeded
      -- If editing an existing preset and the name changed, delete the old one
      if oldPresetName and oldPresetName ~= "" and oldPresetName ~= presetName then
         deletePreset(oldPresetName)
      end
      
      -- Save with server-validated data
      savePreset(presetName, weaponClass, validAtts)
   else
      local errorMsg = net.ReadString()
      -- Error notification is already sent by server via vendNotify
   end
end)

-- Receive delete result from server
net.Receive("attvend_presets_delete_result", function()
   local success = net.ReadBool()
   if success then
      local presetName = net.ReadString()
      -- Delete from local storage after server confirmation
      deletePreset(presetName)
   end
end)

local blur    = Material("pp/blurscreen")
local COL_BG  = Color(24,24,24)
local COL_PNL = Color(32,32,32)
local COL_DIV = Color(56,56,56)
local COL_TXT = Color(230,230,230)
local COL_SUB = Color(180,180,180)
local COL_ACC = Color(40,120,255)
local COL_SB_TRACK = Color(40,40,40)
local COL_SB_GRIP  = Color(60,120,255)
local COL_SB_GRIP_H = Color(80,140,255)

local MAT_CLOSE     = Material("CW2.0 Attachment Vendor/close.png",     "smooth noclamp")
local MAT_CLOSE_RED = Material("CW2.0 Attachment Vendor/close_red.png", "smooth noclamp")
local MAT_ARROW_CLOSED = Material("CW2.0 Attachment Vendor/arrow_menu_closed.png", "smooth noclamp")
local MAT_ARROW_OPENED = Material("CW2.0 Attachment Vendor/arrow_menu_opend.png", "smooth noclamp")
local ICON_CHECK    = "CW2.0 Attachment Vendor/check_circle.png"
local ICON_FOLDER   = "CW2.0 Attachment Vendor/folder.png"
local ICON_ADD      = "CW2.0 Attachment Vendor/add_circle.png"
local MAT_PLUS      = Material("CW2.0 Attachment Vendor/plus.png", "smooth noclamp")
local MAT_DELETE    = Material("CW2.0 Attachment Vendor/delete.png", "smooth noclamp")
local MAT_BOX       = Material("CW2.0 Attachment Vendor/box.png", "smooth noclamp")
local MAT_BOX_CHK   = Material("CW2.0 Attachment Vendor/box_checked.png", "smooth noclamp")

local function PaintPanel(self, w, h)
   surface.SetDrawColor(COL_PNL)
   surface.DrawRect(0,0,w,h)
end

local function getWeaponDisplayName(class)
   local wt = weapons.Get(class)
   if istable(wt) and isstring(wt.PrintName) and #wt.PrintName > 0 then return wt.PrintName end
   return class or ""
end

local function StyleScroll(panel)
   if not IsValid(panel) then return end
   local bar = panel:GetVBar()
   if not IsValid(bar) then return end

   bar:SetWide(8)
   function bar:Paint(w,h) draw.RoundedBox(4, 0, 0, w, h, COL_SB_TRACK) end
   function bar.btnUp:Paint(w,h) end
   function bar.btnDown:Paint(w,h) end
   function bar.btnGrip:Paint(w,h)
      local col = self:IsHovered() and COL_SB_GRIP_H or COL_SB_GRIP
      draw.RoundedBox(4, 0, 2, w, h-4, col)
   end
end

net.Receive("attvend", function()
   local ent = net.ReadEntity()

   local frame = vgui.Create("DFrame")
   frame:SetTitle("")
   frame:SetSize(1000, 560)
   frame:Center()
   frame:MakePopup(true)
   frame:SetDraggable(false)
   frame:ShowCloseButton(false)
   frame.Paint = function(this, w, h)
      local x, y = this:LocalToScreen(0, 0)
      surface.SetDrawColor(color_white)
      surface.SetMaterial(blur)
      for i = 1, 3 do
         blur:SetFloat("$blur", (i / 3) * 6)
         blur:Recompute()
         render.UpdateScreenEffectTexture()
         surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
      end

      surface.SetDrawColor(COL_BG);  surface.DrawRect(0,0,w,h)
      surface.SetDrawColor(COL_PNL); surface.DrawRect(0,0,w,50)
      draw.SimpleText(L("attachment_vendor"), "AttachmentVendorTitle", w/2, 26, COL_TXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      -- removed inner divider line under title for cleaner look
   end

   local closeBtn = vgui.Create("DButton", frame)
   closeBtn:SetText("")
   closeBtn:SetSize(36, 36)
   local function posClose(w) closeBtn:SetPos(w - 36 - 6, 7) end
   posClose(frame:GetWide())
   closeBtn.Paint = function(self, w, h)
      local hovered = self:IsHovered()
      local s = hovered and 26 or 22
      local mat = hovered and MAT_CLOSE_RED or MAT_CLOSE
      surface.SetMaterial(mat)
      surface.SetDrawColor(255,255,255,255)
      surface.DrawTexturedRect((w - s)/2, (h - s)/2, s, s)
   end
   closeBtn.DoClick = function() 
      surface.PlaySound("garrysmod/ui_click.wav")
      -- Clean up hooks when frame closes to prevent memory leaks
      hook.Remove("AttachmentVendor_PresetsUpdated", frame)
      frame:Close() 
   end
   frame.OnClose = function()
      -- Ensure hooks are removed when frame is closed
      hook.Remove("AttachmentVendor_PresetsUpdated", frame)
   end
   frame.OnSizeChanged = function(_, w) posClose(w) end

   local hdiv = vgui.Create("DHorizontalDivider", frame)
   hdiv:Dock(FILL)
   hdiv:DockMargin(12, 40, 12, 12)
   hdiv:SetLeftWidth(240)
   hdiv:SetDividerWidth(8)

   local attinfopnl = vgui.Create("DPanel")
   attinfopnl.Paint = PaintPanel

   local attnameprice = vgui.Create("DLabel", attinfopnl)
   attnameprice:SetText(L("choose_attachment"))
   attnameprice:SetFont("AttachmentVendorHeader")
   attnameprice:SetTextColor(COL_TXT)
   attnameprice:SetContentAlignment(5)
   attnameprice:Dock(TOP)
   attnameprice:DockMargin(12, 12, 12, 8)

   local attimg = vgui.Create("DImage", attinfopnl)
   attimg:Dock(FILL)
   attimg:DockMargin(12, 0, 12, 0)
   attimg:SetKeepAspect(true)
   attimg:Hide()

   local attmodel = vgui.Create("DAdjustableModelPanel", attinfopnl)
   attmodel:Dock(FILL)
   attmodel:DockMargin(12, 0, 12, 0)
   attmodel.LayoutEntity = function() end
   local oldAdjMdlPnlFPC = attmodel.FirstPersonControls
   attmodel.FirstPersonControls = function(this)
      if not IsValid(this.Entity) then return end
      oldAdjMdlPnlFPC(this)
   end
   attmodel:Hide()

   -- middle preset attachment list (hidden by default)
   local attlist = vgui.Create("DScrollPanel", attinfopnl)
   attlist:Dock(FILL)
   attlist:DockMargin(12, 0, 12, 0)
   attlist:SetVisible(false)
   StyleScroll(attlist)

   local btnBar = vgui.Create("DPanel", attinfopnl)
   btnBar:Dock(BOTTOM)
   btnBar:SetTall(66)
   btnBar:DockMargin(0, 6, 0, 12)
   btnBar.Paint = function() end  

   local buy = vgui.Create("DButton", btnBar)
   buy:SetSize(220, 40)
   buy:SetText(L("buy"))
   buy:SetFont("AttachmentVendorButton")
   buy:SetTextColor(color_white)
   buy.isOwned = false -- Store if attachment is owned
   buy.Paint = function(self, w, h)
      local c
      if self.isOwned then
         -- Red color for "Bereits vorhanden"
         c = Color(200,50,50)
      elseif self:GetDisabled() then
         c = Color(90,90,90)
      else
         c = Color(55,95,220,255)
         if self:IsHovered() then
            c = Color(c.r+15, c.g+15, c.b+15)
         end
      end
      draw.RoundedBox(8, 0, 0, w, h, c)
   end

   btnBar.PerformLayout = function(self, w, h)
      buy:SetPos((w - buy:GetWide())/2, (h - buy:GetTall())/2)
   end
   buy:Hide()

   attinfopnl.Setup = function(this, attname, modelOrMaterial, class)
      buy.isOwned = false -- Reset ownership status
      local isAmmo = attname == "buyAmmo"
      local price, name

      if isAmmo then
         price = ATTACHMENT_VENDOR.ammo.price
         name  = "Ammo"
      else
         price = getAttachmentPrice(LocalPlayer(), attname, ent)
         name  = getAttachmentName(attname)
      end

      attnameprice:SetText(name .. "  •  " .. L("currency_symbol") .. tostring(price))
      attnameprice:SetFont("AttachmentVendorTitle")

      attlist:SetVisible(false)
      if type(modelOrMaterial) == "IMaterial" then
         attimg:SetMaterial(modelOrMaterial); attimg:Show(); attmodel:Hide()
      elseif type(modelOrMaterial) == "string" then
         attmodel:SetModel(modelOrMaterial)
         local tab = PositionSpawnIcon(attmodel:GetEntity(), attmodel:GetEntity():GetPos())
         attmodel:SetCamPos(tab.origin); attmodel:SetFOV(tab.fov); attmodel:SetLookAng(tab.angles)
         attmodel:Show(); attimg:Hide()
      end

      buy:SetText(L("buy") .. "  " .. L("currency_symbol") .. tostring(price))
      buy.DoClick = function()
         net.Start("attvend"); net.WriteString(class); net.WriteString(attname); net.WriteEntity(ent); net.SendToServer()
      end
      buy.Think = function(self)
         if (not isAmmo) and (not isCW2Mag(attname)) and LocalPlayer():hasWeaponAttachment(attname, base) then
            self:SetText(L("already_owned") or "Bereits vorhanden"); self:SetDisabled(true); self.isOwned = true; return
         end
         self.isOwned = false
         self:SetDisabled(not ATTACHMENT_VENDOR.playerCanAffordAttachment(LocalPlayer(), attname, price))
      end
      buy:Show()
   end

   -- Left side: container with Presets (top) and Weapons tree (bottom)
   local leftContainer = vgui.Create("DPanel")
   leftContainer.Paint = function(self, w, h)
      -- Normal background, no gray fill
   end

   local presetsPanel = vgui.Create("DPanel", leftContainer)
   presetsPanel:Dock(TOP)
   presetsPanel:SetTall(200)
   presetsPanel:DockMargin(0,1,0,8)
   presetsPanel.Paint = function(self, w, h)
      draw.RoundedBox(10, 0, 0, w, h, COL_PNL)
      surface.SetDrawColor(COL_DIV); surface.DrawOutlinedRect(0,0,w,h,1)
      draw.RoundedBox(8, 8, 8, w-16, 24, Color(40,40,40))
      draw.SimpleText(L("presets"), "AttachmentVendorHeader", 16, 20, COL_TXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
   end

   local presetsList = vgui.Create("DListView", presetsPanel)
   presetsList:Dock(FILL)
   presetsList:DockMargin(8, 48, 8, 8)
   presetsList:SetMultiSelect(false)
   local c1 = presetsList:AddColumn(L("name")); c1:SetFixedWidth(140)
   local c2 = presetsList:AddColumn(L("weapon"))
   -- Set fonts for column headers
   if IsValid(c1) then c1.Header:SetFont("AttachmentVendorText") end
   if IsValid(c2) then c2.Header:SetFont("AttachmentVendorText") end
   function presetsList:Paint(w,h) 
      draw.RoundedBox(6,0,0,w,h,Color(40,40,40))
      surface.SetDrawColor(COL_DIV)
      surface.DrawOutlinedRect(0,0,w,h,1)
   end
   function presetsList:PaintOver(w,h) 
      -- Custom header design
      local headerH = 24
      draw.RoundedBox(0, 0, 0, w, headerH, Color(50,50,50))
      surface.SetDrawColor(COL_DIV)
      local nameX = 0 -- Kein Puffer, direkt am Anfang
      local waffeX = 140 -- Name width direkt
      surface.DrawLine(nameX, 2, nameX, headerH-2)
      surface.DrawLine(waffeX, 2, waffeX, headerH-2)
      draw.SimpleText("  " .. L("name"), "AttachmentVendorText", nameX + 4, headerH/2, COL_TXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
      draw.SimpleText(L("weapon"), "AttachmentVendorText", waffeX + 4, headerH/2, COL_TXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
   end
   function presetsList:OnRowPaint(l, w, h)
      surface.SetDrawColor(0,0,0,0); surface.DrawRect(0,0,w,h)
      for k,v in pairs(self.Columns or {}) do v.Header:SetTextColor(COL_TXT) end
   end
   local oldAddLine = presetsList.AddLine
   function presetsList:AddLine(...)
      local line = oldAddLine(self, ...)
      for i, col in ipairs(line.Columns) do 
         col:SetTextColor(COL_TXT)
         col:SetFont("AttachmentVendorText")
      end
      return line
   end

   local function refreshPresetsList()
      presetsList:Clear()
      -- Add buffer row to prevent first entry from being cut off
      local bufferLine = presetsList:AddLine("", "")
      bufferLine:SetTall(2) -- 2 more pixels smaller
      bufferLine.OnMousePressed = function() end -- Disable interaction
      
      for _, p in ipairs(AV_PRESETS or {}) do
         local line = presetsList:AddLine(p.name, getWeaponDisplayName(p.weapon))
         line._preset = p
      end
   end

   local wepBox = vgui.Create("DPanel", leftContainer)
   wepBox:Dock(FILL)
   wepBox.Paint = function(self, w, h)
      draw.RoundedBox(10, 0, 0, w, h, COL_PNL)
      surface.SetDrawColor(COL_DIV); surface.DrawOutlinedRect(0,0,w,h,1)
   end

   local wepHeader = vgui.Create("DPanel", wepBox)
   wepHeader:Dock(TOP)
   wepHeader:DockMargin(8, 8, 8, 4)
   wepHeader:SetTall(28)
   wepHeader.Paint = function(self, w, h)
      draw.RoundedBox(8, 0, 0, w, h, Color(40,40,40))
      draw.SimpleText(L("attachments"), "AttachmentVendorHeader", 8, h/2, COL_TXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
   end

   local weplist = vgui.Create("DTree", wepBox)
   weplist:SetIndentSize(10)
   weplist:Dock(FILL)
   weplist:DockMargin(0, 0, 8, 8)
   weplist.Paint = function(self, w, h)
      surface.SetDrawColor(0,0,0,0)
      surface.DrawRect(0,0,w,h)
   end
   StyleScroll(weplist)

   local function StyleNode(node, isHeader)
      if IsValid(node.Label) then
         node.Label:SetFont(isHeader and "AttachmentVendorHeader" or "AttachmentVendorText")
         node.Label:SetTextColor(isHeader and COL_TXT or COL_SUB)
      end
      if isHeader then 
         node:SetIcon(ICON_FOLDER)
         node:SetExpanded(false) -- Attachment categories start collapsed
      end
   end

   for _, weptbl in pairs(LocalPlayer():GetWeapons()) do
      if (not isCW2(weptbl)) and (not isFAS2(weptbl)) and (not isARCCW(weptbl)) then continue end

      local wepnode = weplist:AddNode(string.Trim(weptbl:GetPrintName()))
      StyleNode(wepnode, true)

      local ammohead = nil
      for _, attinfo in pairs(istable(weptbl.Attachments) and weptbl.Attachments or {}) do
         local header = getAttachmentHeader(weptbl, attinfo)
         local attachments = getSuitableAttachments(weptbl, attinfo)
         if table.Count(attachments) == 0 then continue end

         local headnode = wepnode:AddNode(header)
         StyleNode(headnode, true)
         if string.lower(header) == "ammo" then ammohead = headnode end

         for _, attname in pairs(attachments) do
            local name = getAttachmentName(attname)
            if (not isstring(name)) or (#name == 0) then continue end

            local attnode = headnode:AddNode(name)
            StyleNode(attnode, false)

            attnode.DoClick = function()
               local mdl = header == "Ammo" and "models/items/357ammo.mdl" or getAttachmentViewModel(weptbl, attname)
               attinfopnl:Setup(attname, mdl or getAttachmentImage(attname), weptbl.ClassName)
               -- Update price in editor if it's open
               if _G.updatePriceFromMiddlePanel then
                  _G.updatePriceFromMiddlePanel()
               end
               -- Reset editor state after attachment selection
               current = {weapon = nil, atts = {}, name = ""}
               if IsValid(nameEntry) then
                  nameEntry:SetText("")
               end
               if IsValid(weaponDrop) then
                  weaponDrop:SetValue("")
               end
               if IsValid(presetSelect) then
                  presetSelect:SetValue("")
                  presetSelect:Clear()
                  if rebuildPresetDropdown then
                     rebuildPresetDropdown()
                  end
               end
               if IsValid(attScroll) then
                  attScroll:Clear()
               end
            end
            attnode.Think = function(self)
               if LocalPlayer():hasWeaponAttachment(attname) then
                  self:SetIcon(ICON_CHECK)
               else
                  self:SetIcon(ICON_ADD)
               end
            end
         end
      end

      if ATTACHMENT_VENDOR.cw2Mags.enable and isCW2Mag(weptbl.magType) then
         if not ValidPanel(ammohead) then
            ammohead = wepnode:AddNode("Ammo"); StyleNode(ammohead, true)
         end
         local magnode = ammohead:AddNode(string.Trim(getAttachmentName(weptbl.magType)))
         StyleNode(magnode, false)
         magnode:SetIcon(ICON_ADD)
         magnode.DoClick = function() 
            attinfopnl:Setup(weptbl.magType, "models/items/357ammo.mdl", weptbl.ClassName)
            -- Update price in editor if it's open
            if _G.updatePriceFromMiddlePanel then
               _G.updatePriceFromMiddlePanel()
            end
         end
      end

      if ATTACHMENT_VENDOR.ammo.sell then
         if not ValidPanel(ammohead) then
            ammohead = wepnode:AddNode("Ammo"); StyleNode(ammohead, true)
         end
         local ammonode = ammohead:AddNode("Buy Ammo")
         StyleNode(ammonode, false)
         ammonode:SetIcon(ICON_ADD)
         ammonode.DoClick = function() attinfopnl:Setup("buyAmmo", "models/items/357ammo.mdl", weptbl.ClassName) end
      end
   end

   -- place left container
   leftContainer.PerformLayout = function(self, w, h)
      -- presetsPanel height fixed; tree fills remaining
   end
   hdiv:SetLeft(leftContainer)
   hdiv:SetRight(attinfopnl)

   -- Populate list and wire preset selection
   hook.Add("AttachmentVendor_PresetsUpdated", frame, function()
      if rebuildPresetDropdown then rebuildPresetDropdown() end
      if refreshPresetsList then refreshPresetsList() end
   end)
   -- Load presets from local JSON storage instead of server
   loadPresets()

   function presetsList:OnRowSelected(_, line)
      local p = IsValid(line) and line._preset
      if not p then return end
      -- Show preset summary in middle panel
      attnameprice:SetText(p.name .. "  •  " .. getWeaponDisplayName(p.weapon))
      attnameprice:SetFont("AttachmentVendorTitle")
      attimg:Hide(); attmodel:Hide(); attlist:SetVisible(true)
      attlist:Clear()
      for _, a in ipairs(p.atts or {}) do
         local line = vgui.Create("DLabel", attlist)
         line:SetText("• " .. (getAttachmentName(a) or a))
         line:SetFont("AttachmentVendorPrice")
         line:SetTextColor(COL_TXT)
         line:Dock(TOP)
         line:DockMargin(0, 2, 0, 2)
      end
      -- Calculate total price for preset
      local totalPrice = 0
      for _, a in ipairs(p.atts or {}) do
         local price = getAttachmentPrice(LocalPlayer(), a, ent) or 0
         totalPrice = totalPrice + price
      end
      
      buy:SetText(L("buy_preset") .. "  " .. L("currency_symbol") .. totalPrice)
      buy.DoClick = function()
         net.Start("attvend_presets_buy")
            net.WriteString(p.weapon)
            net.WriteUInt(#p.atts, 12)
            for _, a in ipairs(p.atts) do net.WriteString(a) end
         net.SendToServer()
      end
      buy:SetDisabled(false); buy:Show()
      
      -- Update price in editor if it's open
      if _G.updatePriceFromMiddlePanel then
         _G.updatePriceFromMiddlePanel()
      end
      
      -- Reset editor state after preset selection
      current = {weapon = nil, atts = {}, name = ""}
      if IsValid(nameEntry) then
         nameEntry:SetText("")
      end
      if IsValid(weaponDrop) then
         weaponDrop:SetValue("")
      end
      if IsValid(presetSelect) then
         presetSelect:SetValue("")
         presetSelect:Clear()
         if rebuildPresetDropdown then
            rebuildPresetDropdown()
         end
      end
      if IsValid(attScroll) then
         attScroll:Clear()
      end
   end

   -- Right slide-out preset editor
   local editorWidth = 220
   local rightSpacer = vgui.Create("DPanel", frame)
   rightSpacer:Dock(RIGHT)
   rightSpacer:SetWide(0)
   rightSpacer.Paint = function(self, w, h)
      if w <= 0 then return end
      draw.RoundedBox(10, 0, 40, w, h-52, COL_PNL)
      surface.SetDrawColor(COL_DIV); surface.DrawOutlinedRect(0, 40, w, h-52, 1)
   end

   local editor = vgui.Create("DPanel", rightSpacer)
   editor:Dock(FILL)
   editor.Paint = function(self, w, h)
      surface.SetDrawColor(0,0,0,0); surface.DrawRect(0,0,w,h)
   end
   frame.OnSizeChanged = function(_, w, h) posClose(w) end

   -- Handle button in title box
   local handle = vgui.Create("DButton", frame)
   handle:SetText("")
   handle:SetSize(36, 36)
   local function posHandle(w) handle:SetPos(w - 80, 7) end
   posHandle(frame:GetWide())
   handle.Paint = function(self, w, h)
      local mat = rightSpacer:GetWide() > 0 and MAT_ARROW_OPENED or MAT_ARROW_CLOSED
      surface.SetMaterial(mat)
      surface.SetDrawColor(255,255,255,255)
      local s = self:IsHovered() and 24 or 20 -- Größer bei Hover
      surface.DrawTexturedRect((w - s)/2, (h - s)/2, s, s)
   end
   handle.DoClick = function()
      surface.PlaySound("garrysmod/ui_click.wav")
      local newW = (rightSpacer:GetWide() > 0) and 0 or editorWidth
      rightSpacer:SizeTo(newW, rightSpacer:GetTall(), 0.2, 0, 0.1, function()
         posHandle(frame:GetWide())
         -- Set placeholder texts when opening editor
         if newW > 0 then
            if IsValid(presetSelect) then
               presetSelect:SetValue("")
               -- Clear and rebuild dropdown to ensure it works
               presetSelect:Clear()
               if rebuildPresetDropdown then
                  rebuildPresetDropdown()
               end
            end
            if IsValid(weaponDrop) then
               weaponDrop:SetValue("")
            end
         end
      end)
   end
   frame.OnSizeChanged = function(_, w, h) posClose(w); posHandle(w) end
   
   -- ESC key to close
   frame.OnKeyCode = function(self, key)
      if key == KEY_ESCAPE then
         surface.PlaySound("garrysmod/ui_click.wav")
         hook.Remove("AttachmentVendor_PresetsUpdated", frame)
         frame:Close()
      end
   end

   -- Editor controls
   local editorHeader = vgui.Create("DPanel", editor)
   editorHeader:Dock(TOP); editorHeader:SetTall(30); editorHeader:DockMargin(12, 48, 12, 8)
   editorHeader.Paint = function(self, w, h)
      draw.RoundedBox(8, 0, 0, w, h, Color(40,40,40))
      draw.SimpleText(L("preset_editor"), "AttachmentVendorHeader", 8, h/2, COL_TXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
   end
   
   local current = {weapon = nil, atts = {}, name = ""}
   
   local topBar = vgui.Create("DPanel", editor)
   topBar:Dock(TOP); topBar:SetTall(28); topBar:DockMargin(12, 8, 12, 8); topBar.Paint = function() end
   local presetSelect = vgui.Create("DComboBox", topBar)
   presetSelect:Dock(LEFT); presetSelect:SetWide(editorWidth - 108)
   presetSelect:SetValue("")
   local presetPlaceholder = L("select_preset")
   presetSelect.Paint = function(self, w, h)
      draw.RoundedBox(4, 0, 0, w, h, Color(60,60,60))
      surface.SetDrawColor(COL_DIV); surface.DrawOutlinedRect(0,0,w,h,1)
   end
   presetSelect.PaintOver = function(self, w, h)
      local value = self:GetValue()
      if not value or value == "" or value == presetPlaceholder then
         -- Hide default text by drawing background only over text area (leave space for dropdown indicator on right)
         local indicatorWidth = 24 -- Space for dropdown indicator
         draw.RoundedBox(0, 0, 0, w - indicatorWidth, h, Color(60,60,60))
         -- Draw placeholder text
         draw.SimpleText(presetPlaceholder, "AttachmentVendorText", 8, h/2, Color(150,150,150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
      end
   end
   presetSelect:SetTextColor(COL_TXT)
   presetSelect:SetFont("AttachmentVendorText")
   
   local deleteBtn = vgui.Create("DButton", topBar)
   deleteBtn:Dock(RIGHT); deleteBtn:SetWide(28); deleteBtn:SetText("")
   deleteBtn.Paint = function(self, w, h)
      local c = self:IsHovered() and Color(70,70,70) or Color(45,45,45)
      draw.RoundedBox(4, 0, 0, w, h, c)
      surface.SetDrawColor(COL_DIV); surface.DrawOutlinedRect(0,0,w,h,1)
      surface.SetMaterial(MAT_DELETE)
      surface.SetDrawColor(255,255,255)
      local s = 24
      surface.DrawTexturedRect((w-s)/2,(h-s)/2,s,s)
   end
   deleteBtn.DoClick = function()
      if not current or not current.name or current.name == "" then
         notification.AddLegacy(L("no_preset_selected"), NOTIFY_ERROR, 3)
         return
      end
      
      -- Create confirmation dialog
      local confirmFrame = vgui.Create("DFrame")
      confirmFrame:SetSize(300, 150)
      confirmFrame:Center()
      confirmFrame:SetTitle("")
      confirmFrame:SetDraggable(false)
      confirmFrame:ShowCloseButton(false)
      confirmFrame:MakePopup()
      confirmFrame.Paint = function(self, w, h)
         draw.RoundedBox(10, 0, 0, w, h, Color(40,40,40))
         surface.SetDrawColor(COL_DIV); surface.DrawOutlinedRect(0,0,w,h,1)
         draw.SimpleText(L("confirm_delete"), "AttachmentVendorHeader", w/2, 20, COL_TXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
         draw.SimpleText(L("confirm_delete_text", current.name), "AttachmentVendorText", w/2, 60, COL_TXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      end
      
      local yesBtn = vgui.Create("DButton", confirmFrame)
      yesBtn:SetSize(80, 30)
      yesBtn:SetPos(60, 100)
      yesBtn:SetText(L("yes"))
      yesBtn:SetFont("AttachmentVendorButton")
      yesBtn:SetTextColor(color_white)
      yesBtn.Paint = function(self, w, h)
         local c = Color(200,50,50)
         if self:IsHovered() then
            c = Color(c.r+15, c.g+15, c.b+15)
         end
         draw.RoundedBox(8, 0, 0, w, h, c)
      end
      yesBtn.DoClick = function()
         -- Send delete request to server
         -- Client will delete from local storage after receiving server confirmation
         net.Start("attvend_presets_delete")
         net.WriteString(current.name)
         net.SendToServer()
         confirmFrame:Close()
         -- Reset editor
         current = {weapon = nil, atts = {}, name = ""}
         if IsValid(nameEntry) then nameEntry:SetText("") end
         if IsValid(weaponDrop) then weaponDrop:SetValue("") end
         if IsValid(presetSelect) then presetSelect:SetValue("") end
         if IsValid(attScroll) then attScroll:Clear() end
         if _G.updatePriceFromMiddlePanel then _G.updatePriceFromMiddlePanel() end
         -- Actual deletion happens in net.Receive("attvend_presets_delete_result")
      end
      
      local noBtn = vgui.Create("DButton", confirmFrame)
      noBtn:SetSize(80, 30)
      noBtn:SetPos(160, 100)
      noBtn:SetText(L("no"))
      noBtn:SetFont("AttachmentVendorButton")
      noBtn:SetTextColor(color_white)
      noBtn.Paint = function(self, w, h)
         local c = Color(60,60,60)
         if self:IsHovered() then
            c = Color(c.r+15, c.g+15, c.b+15)
         end
         draw.RoundedBox(8, 0, 0, w, h, c)
      end
      noBtn.DoClick = function()
         confirmFrame:Close()
      end
   end
   
   local newBtn = vgui.Create("DButton", topBar)
   newBtn:Dock(RIGHT); newBtn:SetWide(28); newBtn:SetText("")
   newBtn.Paint = function(self, w, h)
      local c = self:IsHovered() and Color(70,70,70) or Color(45,45,45)
      draw.RoundedBox(4, 0, 0, w, h, c)
      surface.SetDrawColor(COL_DIV); surface.DrawOutlinedRect(0,0,w,h,1)
      surface.SetMaterial(MAT_PLUS)
      surface.SetDrawColor(255,255,255)
      local s = 24
      surface.DrawTexturedRect((w-s)/2,(h-s)/2,s,s)
   end

   local weaponDrop = vgui.Create("DComboBox", editor)
   weaponDrop:Dock(TOP); weaponDrop:SetTall(28); weaponDrop:DockMargin(12, 8, 12, 8)
   weaponDrop:SetValue("")
   local weaponPlaceholder = L("select_weapon")
   weaponDrop.Paint = function(self, w, h)
      draw.RoundedBox(4, 0, 0, w, h, Color(60,60,60))
      surface.SetDrawColor(COL_DIV); surface.DrawOutlinedRect(0,0,w,h,1)
   end
   weaponDrop.PaintOver = function(self, w, h)
      local value = self:GetValue()
      if not value or value == "" or value == weaponPlaceholder then
         -- Hide default text by drawing background only over text area (leave space for dropdown indicator on right)
         local indicatorWidth = 24 -- Space for dropdown indicator
         draw.RoundedBox(0, 0, 0, w - indicatorWidth, h, Color(60,60,60))
         -- Draw placeholder text
         draw.SimpleText(weaponPlaceholder, "AttachmentVendorText", 8, h/2, Color(150,150,150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
      end
   end
   weaponDrop:SetTextColor(COL_TXT)
   weaponDrop:SetFont("AttachmentVendorText")

   local nameEntry = vgui.Create("DTextEntry", editor)
   nameEntry:Dock(TOP); nameEntry:SetTall(28); nameEntry:DockMargin(12, 8, 12, 8)
   nameEntry:SetPlaceholderText(L("enter_name"))
   local cursorBlink = 0
   nameEntry.Paint = function(self, w, h)
      draw.RoundedBox(4, 0, 0, w, h, Color(60,60,60))
      surface.SetDrawColor(COL_DIV); surface.DrawOutlinedRect(0,0,w,h,1)
      
      -- Draw placeholder text if field is empty
      if self:GetText() == "" then
         draw.SimpleText(L("enter_name"), "AttachmentVendorText", 8, h/2, Color(150,150,150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
      else
         -- Draw entered text
         draw.SimpleText(self:GetText(), "AttachmentVendorText", 8, h/2, COL_TXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
      end
      
      -- Draw blinking cursor if focused
      if self:IsEditing() then
         cursorBlink = (cursorBlink or 0) + FrameTime() * 3
         if cursorBlink > 2 then cursorBlink = 0 end
         
         local showCursor = math.floor(cursorBlink) % 2 == 0
         if showCursor then
            surface.SetFont("AttachmentVendorText")
            local textWidth = surface.GetTextSize(self:GetText())
            local cursorX = 8 + textWidth
            surface.SetDrawColor(COL_TXT)
            surface.DrawRect(cursorX, h/2 - 8, 1, 16)
         end
      else
         cursorBlink = 0
      end
   end
   nameEntry:SetTextColor(COL_TXT)
   nameEntry:SetFont("AttachmentVendorText")
 
   local attScroll = vgui.Create("DScrollPanel", editor)
   attScroll:Dock(FILL); attScroll:DockMargin(12, 0, 12, 8)
   StyleScroll(attScroll)

   local function rebuildPresetDropdown()
      presetSelect:Clear()
      for _, p in ipairs(AV_PRESETS or {}) do
         presetSelect:AddChoice(p.name, p)
      end
   end

   local function setCurrentFromPreset(p)
      current.weapon = p.weapon; current.atts = table.Copy(p.atts or {}); current.name = p.name
      weaponDrop:SetValue(getWeaponDisplayName(p.weapon) or p.weapon)
      nameEntry:SetText(p.name)
      -- rebuild attachment checkboxes
      attScroll:Clear()
      local weptbl = weapons.Get(p.weapon)
      if istable(weptbl) then
         for _, attinfo in pairs(weptbl.Attachments or {}) do
            local header = getAttachmentHeader(weptbl, attinfo)
            local headerLbl = vgui.Create("DLabel", attScroll)
            headerLbl:SetText(header)
            headerLbl:SetFont("AttachmentVendorHeader")
            headerLbl:Dock(TOP); headerLbl:DockMargin(0, 6, 0, 2)
            for _, a in pairs(getSuitableAttachments(weptbl, attinfo) or {}) do
               local row = vgui.Create("DPanel", attScroll)
               row:Dock(TOP); row:DockMargin(0, 2, 0, 2); row:SetTall(20)
               row.Paint = function(self,w,h)
                  local s = 16
                  local checked = table.HasValue(current.atts, a)
                  surface.SetMaterial(checked and MAT_BOX_CHK or MAT_BOX)
                  surface.SetDrawColor(255,255,255)
                  surface.DrawTexturedRect(0, (h-s)/2, s, s)
                  
                  local attName = getAttachmentName(a)
                  local attPrice = getAttachmentPrice(LocalPlayer(), a, ent) or 0
                  local priceText = " - " .. L("currency_symbol") .. attPrice
                  
                  draw.SimpleText(attName, "AttachmentVendorText", s+6, h/2, COL_TXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                  draw.SimpleText(priceText, "AttachmentVendorPrice", w-8, h/2, COL_SUB, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
               end
               row.OnMouseReleased = function()
                  local checked = table.HasValue(current.atts, a)
                  if checked then table.RemoveByValue(current.atts, a) else table.insert(current.atts, a) end
                  if _G.updatePriceFromMiddlePanel then
                     _G.updatePriceFromMiddlePanel()
                  end
               end
            end
         end
      end
      if _G.updatePriceFromMiddlePanel then
         _G.updatePriceFromMiddlePanel()
      end
   end

   local function fillWeaponDropdown()
      weaponDrop:Clear()
      for _, weptbl in pairs(LocalPlayer():GetWeapons()) do
         if (not isCW2(weptbl)) and (not isFAS2(weptbl)) and (not isARCCW(weptbl)) then continue end
         weaponDrop:AddChoice(weptbl:GetPrintName(), weptbl:GetClass())
      end
   end
   fillWeaponDropdown()
   weaponDrop.OnSelect = function(_, _, txt, data)
      current.weapon = data or txt
      current.atts = {}
      setCurrentFromPreset({weapon = current.weapon, atts = {}, name = nameEntry:GetValue()})
      if _G.updatePriceFromMiddlePanel then
         _G.updatePriceFromMiddlePanel()
      end
   end

   presetSelect.OnSelect = function(_, _, txt, data)
      if istable(data) then 
         setCurrentFromPreset(data)
         if _G.updatePriceFromMiddlePanel then
            _G.updatePriceFromMiddlePanel()
         end
      end
   end
   newBtn.DoClick = function()
      nameEntry:SetValue("")
      nameEntry:SetText("")
      presetSelect:SetValue("")
      current = {weapon = nil, atts = {}, name = ""}
      weaponDrop:SetValue("")
      attScroll:Clear()
      if _G.updatePriceFromMiddlePanel then
         _G.updatePriceFromMiddlePanel()
      end
   end

   -- Save/Buy buttons
   local actionBar = vgui.Create("DPanel", editor)
   actionBar:Dock(BOTTOM); actionBar:SetTall(46); actionBar:DockMargin(0, 0, 0, 16); actionBar.Paint = function() end
   local saveBtn = vgui.Create("DButton", actionBar)
   saveBtn:Dock(LEFT); saveBtn:SetWide((editorWidth - 32)/2); saveBtn:DockMargin(12, 8, 4, 8)
   saveBtn:SetText(L("save"))
   saveBtn:SetFont("AttachmentVendorButton")
   saveBtn:SetTextColor(color_white)
   saveBtn.Paint = function(self,w,h)
      local c = Color(60,160,60)
      if self:IsHovered() then
         c = Color(c.r+15, c.g+15, c.b+15)
      end
      draw.RoundedBox(8, 0, 0, w, h, c)
   end
   local priceLabel = vgui.Create("DLabel", actionBar)
   priceLabel:Dock(RIGHT); priceLabel:SetWide((editorWidth - 32)/2); priceLabel:DockMargin(4, 8, 12, 8)
   priceLabel:SetText(L("price") .. ": " .. L("currency_symbol") .. "0")
   priceLabel:SetFont("AttachmentVendorEuro")
   priceLabel:SetTextColor(color_white)
   priceLabel:SetContentAlignment(5) -- Center
   priceLabel.Paint = function(self,w,h)
      local c = Color(55,95,220,255)
      draw.RoundedBox(8, 0, 0, w, h, c)
   end
   
   -- Update price label with current preset price
   local function updateBuyButtonPrice()
      if not current.weapon or #current.atts == 0 then
         priceLabel:SetText(L("price") .. ": " .. L("currency_symbol") .. "0")
         return
      end
      
      local totalPrice = 0
      for _, a in ipairs(current.atts) do
         local price = getAttachmentPrice(LocalPlayer(), a, ent) or 0
         totalPrice = totalPrice + price
      end
      
      priceLabel:SetText(L("price") .. ": " .. L("currency_symbol") .. totalPrice)
   end
   
   -- Workaround: Update price from middle panel when preset is selected
   local function updatePriceFromMiddlePanel()
      if not current.weapon or #current.atts == 0 then
         priceLabel:SetText(L("price") .. ": " .. L("currency_symbol") .. "0")
         return
      end
      
      -- Calculate price based on current attachments in editor
      local totalPrice = 0
      for _, a in ipairs(current.atts) do
         local price = getAttachmentPrice(LocalPlayer(), a, ent) or 0
         totalPrice = totalPrice + price
      end
      
      priceLabel:SetText(L("price") .. ": " .. L("currency_symbol") .. totalPrice)
   end
   
   -- Make function globally accessible
   _G.updatePriceFromMiddlePanel = updatePriceFromMiddlePanel
   
   -- Initial call to set button text
   updateBuyButtonPrice()

   local function sendSave()
      local nm = nameEntry:GetValue()
      if not current.weapon or #nm == 0 then return end
      
      -- Validate preset name length (max 64 characters, same as server)
      if #nm > 64 then
         notification.AddLegacy(L("preset_name_too_long") or "Preset name too long (max 64 characters)", NOTIFY_ERROR, 3)
         return
      end
      
      -- Send to server for validation
      -- Client will save only after receiving successful validation from server
      net.Start("attvend_presets_save")
         net.WriteString(nm)
         net.WriteString(current.weapon)
         net.WriteUInt(#current.atts, 12)
         for _, a in ipairs(current.atts) do net.WriteString(a) end
         net.WriteString(current.name or "") -- Send original name if editing
      net.SendToServer()
      -- Actual saving happens in net.Receive("attvend_presets_save_result")
   end
   saveBtn.DoClick = sendSave

   -- Removed buy button - now only price display

   -- initial UI fill
   rebuildPresetDropdown()
end)
