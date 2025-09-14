-- ========== CONFIG ==========
local PASSIVE = "Doya_Custom_Actions"

-- Compas “clásicos” (como el ejemplo del chest)
local Companions = {
  ["S_Player_ShadowHeart_3ed74f06-3c60-42dc-83f6-f034cb47c679"] = true,
  ["S_Player_Astarion_c7c13742-bacd-460a-8f65-f864fe41f255"] = true,
  ["S_Player_Gale_ad9af97d-75da-406a-ae13-7071c563f604"] = true,
  ["S_Player_Wyll_c774d764-4a17-48dc-b470-32ace9ce447d"] = true,
  ["S_Player_Karlach_2c76687d-93a2-477b-8b18-8a14b549304c"] = true,
  ["S_Player_Laezel_58a69333-40bf-8358-1d17-fff240d7fb12"] = true,
  ["S_Player_Jaheira_91b6b200-7d00-4d62-8dc9-99e8339dfa1a"] = true,
  ["S_Player_Minsc_0de603c5-42e2-4811-9dad-f652de080eba"] = true,
  ["S_GLO_Halsin_7628bc0e-52b8-42a7-856a-13a6fd413323"] = true,
  ["S_GOB_DrowCommander_25721313-0c15-4935-8176-9f134385451b"] = true,
}

-- ========== HELPERS ==========
local function Log(msg) Ext.Utils.Print("[DOYA] " .. tostring(msg)) end

local function IsHireling(uuid)
  local r = Osi.DB_Hirelings_Hired:Get(uuid)
  return r and #r > 0
end

local function IsAvatar(uuid)
  -- tag de AVATAR
  return Osi.IsTagged(uuid, "306b9b05-1057-4770-aa17-01af21acd650") == 1
end

local function ShouldHaveHugs(uuid)
  if Osi.IsSummon(uuid) == 1 then return false end
  if Osi.IsPlayerControlled(uuid) == 1 then return true end
  if IsAvatar(uuid) then return true end
  if Companions[uuid] then return true end
  if IsHireling(uuid) then return true end
  return false
end

local function ForEachPartyMember(fn)
  local rows = Osi.DB_PartyMembers:Get(nil)
  if not rows then return end
  for _, v in ipairs(rows) do
    local c = v[1]; if c then fn(c) end
  end
end

local function ApplyIfNeeded(uuid)
  if ShouldHaveHugs(uuid) and Osi.HasPassive(uuid, PASSIVE) == 0 then
    Osi.AddPassive(uuid, PASSIVE)
    Log("+HUGS -> " .. uuid)
  elseif (not ShouldHaveHugs(uuid)) and Osi.HasPassive(uuid, PASSIVE) == 1 then
    Osi.RemovePassive(uuid, PASSIVE)
    Log("-HUGS <- " .. uuid)
  end
end

local function SweepParty()
  ForEachPartyMember(ApplyIfNeeded)
end

-- ========== EVENTOS ==========
Ext.Events.GameStateChanged:Subscribe(function(e)
  if e.FromState == "Sync" and e.ToState == "Running" then
    SweepParty()
  end
end)

Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(c)
  ApplyIfNeeded(c)
end)

Ext.Osiris.RegisterListener("CharacterLeftParty", 1, "after", function(c)
  if Osi.HasPassive(c, PASSIVE) == 1 then
    Osi.RemovePassive(c, PASSIVE)
    Log("-HUGS <- " .. c)
  end
end)

Ext.Osiris.RegisterListener("OnStatusApplied", 3, "after", function(c, status, _)
  if status == "SUMMONED" then
    if Osi.HasPassive(c, PASSIVE) == 1 then
      Osi.RemovePassive(c, PASSIVE)
      Log("Summon cleanup: -HUGS <- " .. c)
    end
  end
end)

-- ========== CONSOLA ==========
Ext.RegisterConsoleCommand("doya_check", function()
  ForEachPartyMember(function(c)
    local pc  = Osi.IsPlayerControlled(c) == 1
    local sum = Osi.IsSummon(c) == 1
    local has = Osi.HasPassive(c, PASSIVE) == 1
    Ext.Utils.Print(string.format("[DOYA] %s pc=%s summon=%s passive=%s", c, pc, sum, has))
  end)
end)

Ext.RegisterConsoleCommand("doya_give", function()
  ForEachPartyMember(function(c) ApplyIfNeeded(c) end)
end)

Ext.RegisterConsoleCommand("doya_clear", function()
  ForEachPartyMember(function(c)
    if Osi.HasPassive(c, PASSIVE) == 1 then
      Osi.RemovePassive(c, PASSIVE)
      Log("-HUGS <- " .. c)
    end
  end)
end)
