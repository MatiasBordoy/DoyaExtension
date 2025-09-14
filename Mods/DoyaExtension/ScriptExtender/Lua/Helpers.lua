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

local function IsHireling(uuid)
  local r = Osi.DB_Hirelings_Hired:Get(uuid)
  return r and #r > 0
end

local function IsAvatar(uuid)
  return Osi.IsTagged(uuid, "306b9b05-1057-4770-aa17-01af21acd650") == 1
end

local function IsCompanion((uuid)
  return Companions[uuid] or false
end)

local function IsSummon(uuid)
  return Osi.IsSummon(uuid) == 1
end

local function IsAvatarCompanionOrHireling(uuid)
  return IsAvatar(uuid) or IsCompanion(uuid) or IsHireling(uuid) and not IsSummon(uuid)
end

local function ExecuteFunctionForEachPartyMember(fn)
  local rows = Osi.DB_PartyMembers:Get(nil)
  if not rows then return end
  for _, v in ipairs(rows) do
    local c = v[1]; if c then fn(c) end
  end
end