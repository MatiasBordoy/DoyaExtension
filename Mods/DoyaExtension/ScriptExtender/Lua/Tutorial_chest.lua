-- ========= Config =========
local STATUSES_TO_REMOVE = {
  "TCP_BOOST_DRANKPOTION",
  "TCP_BOOST_DRANKPOTION_APPLY", -- por si quedó activo
}

-- Opcional: si el chest llegó a “pegar” spells/pasivas, listalos acá.
local SPELLS_TO_REMOVE = {
  -- "TUTORIAL_SPELL_ID_1",
  -- "TUTORIAL_SPELL_ID_2",
}
local PASSIVES_TO_REMOVE = {
  -- "TUTORIAL_PASSIVE_ID_1",
  -- "TUTORIAL_PASSIVE_ID_2",
}

-- ========= Helpers internos =========
local function addToSet(set, uuid)
  if uuid and uuid ~= "" then set[uuid] = true end
end

local function collectCandidates()
  local set = {}

  -- Party actual
  local party = Osi.DB_PartyMembers:Get(nil) or {}
  for _, row in ipairs(party) do addToSet(set, row[1]) end

  -- Miembros “PartOfTheTeam”
  local team = Osi.DB_PartOfTheTeam:Get(nil) or {}
  for _, row in ipairs(team) do addToSet(set, row[1]) end

  -- Compas conocidos “clásicos”
  for uuid, _ in pairs(Companions or {}) do addToSet(set, uuid) end

  -- Cualquiera que actualmente tenga el status (por si no está en las DBs)
  local all = Osi.GetAllCharacters() or {}
  for _, c in ipairs(all) do
    for _, st in ipairs(STATUSES_TO_REMOVE) do
      if Osi.HasActiveStatus(c, st) == 1 then
        addToSet(set, c)
        break
      end
    end
  end

  -- Filtrar: nos interesan solo Avatares/Compas/Hirelings (no summons)
  local out = {}
  for uuid, _ in pairs(set) do
    if IsAvatarCompanionOrHireling(uuid) then
      out[#out+1] = uuid
    end
  end
  return out
end

local function cleanCharacter(c)
  -- 1) Status
  for _, st in ipairs(STATUSES_TO_REMOVE) do
    if Osi.HasActiveStatus(c, st) == 1 then
      Osi.RemoveStatus(c, st)
      Ext.Utils.Print(string.format("[DOYA CLEAN] RemoveStatus %s -> %s", st, c))
    end
  end

  -- 2) Spells “pegados” (si declaraste lista)
  for _, sp in ipairs(SPELLS_TO_REMOVE) do
    -- si no estás seguro, igual intentar es inocuo
    Osi.RemoveSpell(c, sp)
    Ext.Utils.Print(string.format("[DOYA CLEAN] RemoveSpell %s -> %s", sp, c))
  end

  -- 3) Pasivas “pegadas” (si declaraste lista)
  for _, pv in ipairs(PASSIVES_TO_REMOVE) do
    Osi.RemovePassive(c, pv)
    Ext.Utils.Print(string.format("[DOYA CLEAN] RemovePassive %s -> %s", pv, c))
  end
end

local function runCleanOnce()
  if PersistentVars and PersistentVars.DOYA_CLEAN_DONE then
    return
  end

  local candidates = collectCandidates()
  Ext.Utils.Print(string.format("[DOYA CLEAN] Candidates: %d", #candidates))

  for _, c in ipairs(candidates) do
    cleanCharacter(c)
  end

  PersistentVars = PersistentVars or {}
  PersistentVars.DOYA_CLEAN_DONE = true
  Ext.Utils.Print("[DOYA CLEAN] Completed.")
end

-- Ejecutar una sola vez cuando el juego entra en Running
Ext.Events.GameStateChanged:Subscribe(function(e)
  if e.ToState == "Running" then
    -- pequeño delay para asegurar que DBs estén pobladas
    Ext.Utils.RunDelayed(runCleanOnce, 500)
  end
end)