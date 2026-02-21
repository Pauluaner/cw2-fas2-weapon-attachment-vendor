ENT.Base = "base_anim";
ENT.Type = "anim";
ENT.PrintName = "Attachment Vendor" -- Will be localized by the language system
ENT.Category = "Attachment Vendor"
ENT.Author = "Gambit & Paulus"
ENT.Spawnable = true;

ENT.IconOverride = "materials/CW2.0 Attachment Vendor/icon.png"

function ENT:SetupDataTables()
   self:NetworkVar("Entity", 0, "owning_ent");
   self:NetworkVar("Bool", 0, "damaged");
   self:NetworkVar("Bool", 1, "destructible");
   self:NetworkVar("String", 0, "id");
end
