-- Attachment Vendor Language System
-- Multi-language support

ATTACHMENT_VENDOR = ATTACHMENT_VENDOR or {}
ATTACHMENT_VENDOR.Lang = ATTACHMENT_VENDOR.Lang or {}

-- Language configuration
ATTACHMENT_VENDOR.Lang.CurrentLanguage = ATTACHMENT_VENDOR.language and ATTACHMENT_VENDOR.language.default or "de"

-- Translation table
ATTACHMENT_VENDOR.Lang.Translations = {
    ["de"] = {
        -- Main UI
        ["attachment_vendor"] = "Aufsatz Händler",
        ["attachment_vendor_display"] = "Aufsatz Händler",
        ["choose_attachment"] = "Wähle einen Aufsatz",
        ["choose_preset"] = "Wähle ein Preset",
        ["presets"] = "Presets",
        ["attachments"] = "Aufsätze",
        ["name"] = "Name",
        ["weapon"] = "Waffe",
        ["price"] = "Preis",
        ["buy"] = "Kaufen",
        ["save"] = "Speichern",
        ["delete"] = "Löschen",
        ["close"] = "Schließen",
        
        -- Preset Editor
        ["preset_editor"] = "Preset Editor",
        ["select_preset"] = "Preset wählen…",
        ["select_weapon"] = "Waffe wählen…",
        ["enter_name"] = "Name eingeben...",
        ["new_preset"] = "Neues Preset",
        ["buy_preset"] = "Preset kaufen",
        ["save_preset"] = "Preset speichern",
        ["delete_preset"] = "Preset löschen",
        
        -- Messages
        ["preset_saved"] = "Preset gespeichert!",
        ["preset_deleted"] = "Preset gelöscht!",
        ["preset_bought"] = "Preset gekauft!",
        ["no_preset_selected"] = "Kein Preset ausgewählt!",
        ["confirm_delete"] = "Preset löschen",
        ["confirm_delete_text"] = "Möchtest du das Preset '%s' wirklich löschen?",
        ["yes"] = "Ja",
        ["no"] = "Nein",
        ["insufficient_funds"] = "Nicht genügend Geld!",
        ["weapon_not_owned"] = "Waffe nicht im Besitz!",
        ["weapon_not_owned_preset"] = "Du besitzt die Waffe für dieses Preset nicht!",
        ["attachment_not_suitable"] = "Aufsatz nicht für diese Waffe geeignet!",
        ["vendor_destroyed"] = "Dein Aufsatz Händler wurde zerstört!",
        ["already_owned"] = "Bereits vorhanden",
        ["preset_name_too_long"] = "Preset-Name zu lang (max. 64 Zeichen)",
        
        -- Currency
        ["currency_symbol"] = "€",
        ["total_price"] = "Gesamtpreis",
        ["attachment_price"] = "Aufsatzpreis",
        
        -- Weapon types
        ["assault_rifle"] = "Sturmgewehr",
        ["sniper_rifle"] = "Scharfschützengewehr",
        ["submachine_gun"] = "Maschinenpistole",
        ["pistol"] = "Pistole",
        ["shotgun"] = "Schrotflinte",
        ["machine_gun"] = "Maschinengewehr",
        
        -- Attachment types
        ["sight"] = "Zielfernrohr",
        ["grip"] = "Griff",
        ["barrel"] = "Lauf",
        ["magazine"] = "Magazin",
        ["stock"] = "Schulterstütze",
        ["laser"] = "Laser",
        ["flashlight"] = "Taschenlampe",
        ["suppressor"] = "Schalldämpfer",
        ["bipod"] = "Zweibein",
        ["foregrip"] = "Vordergriff",
        ["handguard"] = "Handschutz",
        ["ammo"] = "Munition",
        ["underbarrel"] = "Unterlauf",
        ["tactical"] = "Taktisch",
        ["optic"] = "Zielfernrohr",
        ["scope"] = "Zielfernrohr",
        ["muzzle"] = "Mündung",
        ["rail"] = "Schiene",
        ["accessory"] = "Zubehör",
        ["modification"] = "Modifikation",
        ["receiver"] = "Gehäuse"
    },
    
    ["en"] = {
        -- Main UI
        ["attachment_vendor"] = "Attachment Vendor",
        ["attachment_vendor_display"] = "Attachment Vendor",
        ["choose_attachment"] = "Choose an attachment",
        ["choose_preset"] = "Choose a preset",
        ["presets"] = "Presets",
        ["attachments"] = "Attachments",
        ["name"] = "Name",
        ["weapon"] = "Weapon",
        ["price"] = "Price",
        ["buy"] = "Buy",
        ["save"] = "Save",
        ["delete"] = "Delete",
        ["close"] = "Close",
        
        -- Preset Editor
        ["preset_editor"] = "Preset Editor",
        ["select_preset"] = "Select preset…",
        ["select_weapon"] = "Select weapon…",
        ["enter_name"] = "Enter name...",
        ["new_preset"] = "New Preset",
        ["buy_preset"] = "Buy Preset",
        ["save_preset"] = "Save Preset",
        ["delete_preset"] = "Delete Preset",
        
        -- Messages
        ["preset_saved"] = "Preset saved!",
        ["preset_deleted"] = "Preset deleted!",
        ["preset_bought"] = "Preset bought!",
        ["no_preset_selected"] = "No preset selected!",
        ["confirm_delete"] = "Delete Preset",
        ["confirm_delete_text"] = "Do you really want to delete the preset '%s'?",
        ["yes"] = "Yes",
        ["no"] = "No",
        ["insufficient_funds"] = "Insufficient funds!",
        ["weapon_not_owned"] = "Weapon not owned!",
        ["weapon_not_owned_preset"] = "You don't own the weapon for this preset!",
        ["attachment_not_suitable"] = "Attachment not suitable for this weapon!",
        ["vendor_destroyed"] = "Your Attachment Vendor has been destroyed!",
        ["already_owned"] = "Already owned",
        ["preset_name_too_long"] = "Preset name too long (max 64 characters)",
        
        -- Currency
        ["currency_symbol"] = "$",
        ["total_price"] = "Total Price",
        ["attachment_price"] = "Attachment Price",
        
        -- Weapon types
        ["assault_rifle"] = "Assault Rifle",
        ["sniper_rifle"] = "Sniper Rifle",
        ["submachine_gun"] = "Submachine Gun",
        ["pistol"] = "Pistol",
        ["shotgun"] = "Shotgun",
        ["machine_gun"] = "Machine Gun",
        
        -- Attachment types
        ["sight"] = "Sight",
        ["grip"] = "Grip",
        ["barrel"] = "Barrel",
        ["magazine"] = "Magazine",
        ["stock"] = "Stock",
        ["laser"] = "Laser",
        ["flashlight"] = "Flashlight",
        ["suppressor"] = "Suppressor",
        ["bipod"] = "Bipod",
        ["foregrip"] = "Foregrip",
        ["handguard"] = "Handguard",
        ["ammo"] = "Ammo",
        ["underbarrel"] = "Underbarrel",
        ["tactical"] = "Tactical",
        ["optic"] = "Optic",
        ["scope"] = "Scope",
        ["muzzle"] = "Muzzle",
        ["rail"] = "Rail",
        ["accessory"] = "Accessory",
        ["modification"] = "Modification",
        ["receiver"] = "Receiver"
    }
}

-- Translation function
function ATTACHMENT_VENDOR.Lang:GetText(key, ...)
    local lang = self.CurrentLanguage or "de"
    local translation = self.Translations[lang] and self.Translations[lang][key]
    
    if not translation then
        -- Fallback to German if translation not found
        translation = self.Translations["de"][key] or key
    end
    
    -- Format string if arguments provided
    if ... then
        return string.format(translation, ...)
    end
    
    return translation
end

-- Shortcut function
function L(key, ...)
    return ATTACHMENT_VENDOR.Lang:GetText(key, ...)
end

-- Function to change language
function ATTACHMENT_VENDOR.Lang:SetLanguage(lang)
    if self.Translations[lang] then
        self.CurrentLanguage = lang
        return true
    end
    return false
end

-- Function to get current language
function ATTACHMENT_VENDOR.Lang:GetCurrentLanguage()
    return self.CurrentLanguage
end

-- Function to get available languages
function ATTACHMENT_VENDOR.Lang:GetAvailableLanguages()
    local languages = {}
    for lang, _ in pairs(self.Translations) do
        table.insert(languages, lang)
    end
    return languages
end
