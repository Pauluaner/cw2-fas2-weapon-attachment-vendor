util.AddNetworkString("attvend_notify");
util.AddNetworkString("attvend_presets_get");
util.AddNetworkString("attvend_presets_list");
util.AddNetworkString("attvend_presets_save");
util.AddNetworkString("attvend_presets_save_result");
util.AddNetworkString("attvend_presets_delete");
util.AddNetworkString("attvend_presets_delete_result");
util.AddNetworkString("attvend_presets_buy");

NOTIFY_GENERIC = 0;
NOTIFY_ERROR = 1;
NOTIFY_UNDO = 2;
NOTIFY_HINT = 3;
NOTIFY_CLEANUP = 4;


function vendNotify(ply, t, l, m)
   net.Start("attvend_notify");
      net.WriteUInt(t, 8);
      net.WriteUInt(l, 8);
      net.WriteString(m);
   net.Send(ply);
end

local chanceTbl = {false, "free", "extra", "steal"};

net.Receive("attvend", function(l, p)
   local weptbl = weapons.Get(net.ReadString());
   local attname = net.ReadString();
   local ent = net.ReadEntity();
   
   if (IsValid(ent) == false or ent:GetClass() ~= "attachment_vendor") then return; end
   
   local atts = {attname};
   
   local malf = ent:Getdamaged() and ATTACHMENT_VENDOR.malfunction.allow and chance(ATTACHMENT_VENDOR.malfunction.chance);
   local func = malf and chanceTbl[math.random(#chanceTbl)];
   
   if (isstring(func) and chance(ATTACHMENT_VENDOR.malfunction[func .. "Chance"]) == false) then
      func = false;
   end
   
   -- if the vendor can give extra attachments, do it
   if (func == "extra") then
      vendNotify(p, NOTIFY_ERROR, 4, "The vendor has malfunctioned and given you some extra attachments.");
      
      for i = 1, ATTACHMENT_VENDOR.malfunction.extraMax do
         local att = getRandomAttachment(p, weptbl);
         table.insert(atts, att);
      end
   end
   
   local giveAtts = {};
   for k,v in pairs(atts) do
      if (isCW2Mag(v) == false and p:hasWeaponAttachment(v)) then continue; end
      
      table.insert(giveAtts, v);
   end
   
   if (#giveAtts == 0) then return; end
   local success, tbl = hook.Run("playerCanHaveAttachments", p, table.Copy(giveAtts));
   if (success == false) then return; end
   if (istable(tbl)) then
      giveAtts = tbl;
   end
   
   local price;

   if (attname == "buyAmmo") then
      assert(ATTACHMENT_VENDOR.ammo.sell, "Vendor config does not allow selling ammo.");
      price = ATTACHMENT_VENDOR.ammo.price;
   else
      price = getAttachmentPrice(p, attname, ent);
   end
   
   if (func == "free") then
      vendNotify(p, NOTIFY_ERROR, 4, "The vendor has malfunctioned and given you the attachment for free.");
      price = 0;
   end
   
   if (ATTACHMENT_VENDOR.playerCanAffordAttachment(p, attname, price) == false) then
      vendNotify(p, NOTIFY_ERROR, 4, "You cannot afford this attachment.");
      return;
   end
   
   ATTACHMENT_VENDOR.playerPurchasedAttachment(p, attname, price);
   
   if (func == "steal") then
      vendNotify(p, NOTIFY_ERROR, 4, "The vendor has malfunctioned and you have not received your attachment.");
      return;
   end
   
   local msg;
   if (attname == "buyAmmo") then
      msg = "ammo";
   else
      msg = "the " .. string.Trim(getAttachmentName(attname, weptbl));
   end
   
   if (price > 0) then
      vendNotify(p, NOTIFY_GENERIC, 4, "You have purchased " .. msg .. " for $" .. price);
   end
   
   if (attname == "buyAmmo") then
      p:GiveAmmo(weptbl.Primary.ClipSize, weptbl.Primary.Ammo);
      table.RemoveByValue(giveAtts, attname);
   end
   
   p:giveWeaponAttachments(giveAtts);
   
   if (IsValid(ent:Getowning_ent()) and p ~= ent:Getowning_ent() and price > 0) then
      local givePrice = ATTACHMENT_VENDOR.ownerPricePercentage(ent:Getowning_ent(), attname, price);
      local tax = price / givePrice;
      
      ent:Getowning_ent():addMoney(givePrice);
      vendNotify(ent:Getowning_ent(), NOTIFY_GENERIC, 4, "You have sold " .. msg .. " for $" .. price .. ((tax ~= 1) and " (" .. tax .. "% tax)" or ""));
   end
end);

-- Presets networking (client-side storage, server only validates)
-- Note: Presets are now stored client-side as JSON, server no longer stores them
net.Receive("attvend_presets_get", function(_, ply)
   -- Presets are now client-side only, return empty list
   -- Client will load from local JSON storage
   net.Start("attvend_presets_list");
      net.WriteUInt(0, 12);
   net.Send(ply);
end);

net.Receive("attvend_presets_save", function(_, ply)
   local presetName = string.sub(net.ReadString() or "", 1, 64);
   local weaponClass = string.sub(net.ReadString() or "", 1, 64);
   local count = math.min(net.ReadUInt(12) or 0, 128);
   local atts = {};
   for i = 1, count do
      table.insert(atts, string.sub(net.ReadString() or "", 1, 64));
   end
   local oldPresetName = string.sub(net.ReadString() or "", 1, 64); -- Original name if editing

   -- Server-side validation
   local success = true;
   local errorMsg = "";

   -- validate weapon ownership
   if (playerHasWeaponClass(ply, weaponClass) == false) then 
      success = false;
      errorMsg = L("weapon_not_owned");
   end

   -- validate attachments suitability
   local valid = {};
   if success then
      for _, a in ipairs(atts) do
         if (attachmentIsSuitableForWeapon(weaponClass, a)) then
            table.insert(valid, a);
         end
      end
   end

   -- Send result back to client
   net.Start("attvend_presets_save_result");
      net.WriteBool(success);
      if success then
         net.WriteString(presetName);
         net.WriteString(weaponClass);
         net.WriteUInt(#valid, 12);
         for _, a in ipairs(valid) do
            net.WriteString(a);
         end
         net.WriteString(oldPresetName or ""); -- Send back original name for client to handle deletion
      else
         net.WriteString(errorMsg);
      end
   net.Send(ply);
   
   -- Send notification after the result message is sent
   if success then
      vendNotify(ply, NOTIFY_GENERIC, 4, L("preset_saved") .. ": " .. presetName);
   else
      vendNotify(ply, NOTIFY_ERROR, 4, errorMsg);
   end
end);

net.Receive("attvend_presets_delete", function(_, ply)
   local presetName = string.sub(net.ReadString() or "", 1, 64);
   -- Presets are now stored client-side, server only confirms deletion
   -- Server-side validation could be added here if needed (e.g., check if preset exists)
   net.Start("attvend_presets_delete_result");
      net.WriteBool(true);
      net.WriteString(presetName);
   net.Send(ply);
   -- Send notification after the result message is sent
   vendNotify(ply, NOTIFY_GENERIC, 4, L("preset_deleted") .. ": " .. presetName);
end);

net.Receive("attvend_presets_buy", function(_, ply)
   local weaponClass = string.sub(net.ReadString() or "", 1, 64);
   local count = math.min(net.ReadUInt(12) or 0, 128);
   local atts = {};
   for i = 1, count do
      table.insert(atts, string.sub(net.ReadString() or "", 1, 64));
   end

   -- Only allow buying for a weapon the player owns at this moment
   if (playerHasWeaponClass(ply, weaponClass) == false) then 
      vendNotify(ply, NOTIFY_ERROR, 4, L("weapon_not_owned_preset"));
      return; 
   end

   -- Filter to only valid and not-yet-owned attachments
   local giveAtts = {};
   local totalPrice = 0;
   for _, a in ipairs(atts) do
      if (attachmentIsSuitableForWeapon(weaponClass, a) and (isCW2Mag(a) or not ply:hasWeaponAttachment(a))) then
         local price = getAttachmentPrice(ply, a, NULL);
         if (price > 0) then
            if (ATTACHMENT_VENDOR.playerCanAffordAttachment(ply, a, price) == false) then
               vendNotify(ply, NOTIFY_ERROR, 4, L("insufficient_funds") .. ": " .. (getAttachmentName(a) or a));
               return;
            end
            totalPrice = totalPrice + price;
         end
         table.insert(giveAtts, a);
      end
   end

   if (#giveAtts == 0) then return; end

   -- charge once
   if (totalPrice > 0) then
      ATTACHMENT_VENDOR.playerPurchasedAttachment(ply, "preset", totalPrice);
      vendNotify(ply, NOTIFY_GENERIC, 4, L("preset_bought") .. " " .. L("currency_symbol") .. totalPrice);
   end

   ply:giveWeaponAttachments(giveAtts);
end);