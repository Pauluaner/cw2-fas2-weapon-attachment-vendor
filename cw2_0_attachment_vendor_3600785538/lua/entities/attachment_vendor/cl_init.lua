surface.CreateFont("AttachmentVendor_TitleFont", { 
    font = "Open Sans Condensed", 
    size = 64, 
    weight = 600,
    antialias = true, 
    extended = true
})

include("shared.lua")

function ENT:Initialize()
    self.m_iLastSpark = CurTime()
    self.m_iNextSparkTime = 0
end

function ENT:Draw()
    self:DrawModel()

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local pos = self:LocalToWorld(self:OBBCenter() + Vector(0,0,50)) 
    if ply:GetPos():DistToSqr(pos) > (1000 * 1000) then return end  

    local ang = Angle(0, ply:EyeAngles().y - 90, 90)

    local owner = IsValid(self:Getowning_ent()) and (self:Getowning_ent():Nick() .. "'s ") or ""
    local displayText = L("attachment_vendor_display")
    local text = owner .. displayText

    surface.SetFont("AttachmentVendor_TitleFont")
    local tw, th = surface.GetTextSize(text)
    local pad = 16
    local w, h = tw + pad*2, th + pad*2

    cam.Start3D2D(pos, ang, 0.1)
        draw.RoundedBox(12, -w*0.5, -h, w, h, Color(0,0,0,180))
        draw.SimpleText(
            text, "AttachmentVendor_TitleFont",
            0, -h + pad + th*0.5, color_white,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
        )
    cam.End3D2D()
end

function ENT:Think()
    if (self:Getdamaged() == false or CurTime() < self.m_iLastSpark + self.m_iNextSparkTime) then return end

    local ed = EffectData()
    ed:SetOrigin(self:LocalToWorld(self:OBBCenter()))
    util.Effect("cball_bounce", ed)
    self:EmitSound("ambient.electrical_zap_" .. math.random(1, 3))

    self.m_iLastSpark = CurTime()
    self.m_iNextSparkTime = math.random(1, 5)
end
