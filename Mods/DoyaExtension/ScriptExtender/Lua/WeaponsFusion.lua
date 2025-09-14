-- Variable global para almacenar los cambios persistidos
local WeaponEnhancerChanges = {}

-- Inicializar y gestionar PersistentVars al cargar la sesión
Ext.Events.SessionLoaded:Subscribe(function()
    Mods = Mods or {}
    Mods["WeaponEnhancer"] = Mods["WeaponEnhancer"] or {}
    Mods["WeaponEnhancer"].PersistentVars = Mods["WeaponEnhancer"].PersistentVars or {}
    Mods["WeaponEnhancer"].PersistentVars["WeaponEnhancerChanges"] = Mods["WeaponEnhancer"].PersistentVars["WeaponEnhancerChanges"] or "{}" -- String vacío JSON

    -- Cargar los cambios en la variable global deserializando JSON
    local serializedChanges = Mods["WeaponEnhancer"].PersistentVars["WeaponEnhancerChanges"]
    WeaponEnhancerChanges = Ext.Json.Parse(serializedChanges) or {}

    print("Debug - PersistentVars initialized:", serializedChanges)
end)

-- Listener para reaplicar cambios al cargar el guardado
Ext.Osiris.RegisterListener("SavegameLoaded", 0, "after", function()
    print("WeaponEnhancerByDoya: Reaplicando cambios desde PersistentVars")

    for itemID, change in pairs(WeaponEnhancerChanges) do
        local itemEntity = Ext.Entity.Get(itemID)
        if itemEntity then
            local boostsContainer = itemEntity:GetComponent("BoostsContainer")
            if boostsContainer then
                boostsContainer.Boosts = change.boosts
            end

            local useComponent = itemEntity:GetComponent("Use")
            if useComponent and change.useBoosts then
                useComponent.Boosts = change.useBoosts
            end

            local weaponComponent = itemEntity:GetComponent("Weapon")
            if weaponComponent and change.damage then
                for i, roll in ipairs(change.damage) do
                    weaponComponent.Rolls.Strength[i] = roll
                end
            end
        end
    end
end)

-- Listener para capturar la combinación de items
Ext.Osiris.RegisterListener("RequestCanCombine", 7, "before", function(character, gemItem, baseItem, donorItem, _, _, requestID)
    print("WeaponEnhancerByDoya: Combinación detectada")
    print("gemItem ID: " .. tostring(gemItem))
    print("baseItem ID: " .. tostring(baseItem))
    print("donorItem ID: " .. tostring(donorItem))

    -- Validar si uno de los ítems es la gema especial
    local validGemPrefixes = {
        "Doya_Absorb_Enchantment_Gem"
    }

    local isValidGem = false
    for _, prefix in pairs(validGemPrefixes) do
        if string.find(gemItem, prefix) then
            isValidGem = true
            break
        end
    end

    if not isValidGem then
        print("WeaponEnhancerByDoya: no usa gema!")
        Osi.RequestProcessed(character, requestID, 0)
        return
    end

    print("WeaponEnhancerByDoya: Combinación valida detectada")

    -- Verificar que el donor y el base item no sean el mismo
    if baseItem == donorItem then
        print("WeaponEnhancerByDoya: Bad combination - donor y base son el mismo item")
        Osi.RequestProcessed(character, requestID, 1)
        return
    end

    -- Obtener los componentes necesarios de ambos ítems
    local baseEntity = Ext.Entity.Get(baseItem)
    local donorEntity = Ext.Entity.Get(donorItem)

    if not baseEntity or not donorEntity then
        print("WeaponEnhancerByDoya: No se pudieron obtener las entidades")
        Osi.RequestProcessed(character, requestID, 1)
        return
    end

    local baseBoostsContainer = baseEntity:GetComponent("BoostsContainer")
    local donorBoostsContainer = donorEntity:GetComponent("BoostsContainer")

    if not baseBoostsContainer or not donorBoostsContainer then
        print("WeaponEnhancerByDoya: Uno de los ítems no tiene BoostsContainer")
        Osi.RequestProcessed(character, requestID, 1)
        return
    end

    -- Transferir los boosts del donor al base item
    print("WeaponEnhancerByDoya: Sobrescribiendo boosts del arma base")
    baseBoostsContainer.Boosts = donorBoostsContainer.Boosts

    -- Transferir la propiedad Use
    local baseUse = baseEntity:GetComponent("Use")
    local donorUse = donorEntity:GetComponent("Use")
    if baseUse and donorUse then
        print("WeaponEnhancerByDoya: Transfiriendo Use boosts")
        baseUse.Boosts = donorUse.Boosts
    end

    -- Actualizar manualmente el daño del arma
    local baseWeapon = baseEntity:GetComponent("Weapon")
    if baseWeapon then
        print("WeaponEnhancerByDoya: Actualizando daño del arma")
        for _, roll in pairs(baseWeapon.Rolls.Strength) do
            roll.DiceAdditionalValue = 1
        end
    end

    -- Validar que WeaponEnhancerChanges esté inicializado
    if not WeaponEnhancerChanges then
        print("Debug - WeaponEnhancerChanges no está inicializado correctamente, inicializando ahora.")
        WeaponEnhancerChanges = {}
    end

    -- Guardar los cambios en la variable global
    WeaponEnhancerChanges[baseItem] = {
        boosts = baseBoostsContainer.Boosts,
        useBoosts = baseUse and baseUse.Boosts or nil,
        damage = baseWeapon and baseWeapon.Rolls.Strength or nil
    }
	
	--Print fundamental(no remover) sin esto no se ejecutan bien en orden las cosas siguientes y garantiza el save en el persistantVars
	print(Ext.DumpExport(WeaponEnhancerChanges[baseItem]))

    -- Serializar y guardar en PersistentVars
    Mods["WeaponEnhancer"].PersistentVars["WeaponEnhancerChanges"] = Ext.Json.Stringify(WeaponEnhancerChanges)

    print("Debug - Changes saved to PersistentVars:", Ext.Json.Stringify(WeaponEnhancerChanges))

    -- Simular un drop del ítem base
    print("WeaponEnhancerByDoya: Simulando drop del item")
    Osi.Drop(baseItem)
    Osi.Pickup(character, baseItem, "", 1)

    -- Confirmar la solicitud
    Osi.RequestProcessed(character, requestID, 0)
end)
