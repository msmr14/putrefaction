CreateConVar("ragdolldecay_enable", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("ragdolldecay_start_time", "3600", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("ragdolldecay_duration", "3600", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("ragdolldecay_remove_after_decay_time", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
game.AddParticles("particles/water_impact.pcf")
game.AddParticles("particles/blood_impact.pcf")
PrecacheParticleSystem("slime_splash_01")
PrecacheParticleSystem("blood_zombie_split")
RagdollDecay_IsFleshMaterial = {
    ["flesh"] = true,
    ["alienflesh"] = true,
    ["hunter"] = true,
    ["antlion"] = true,
    ["zombieflesh"] = true,
    ["armorflesh"] = true,
}

-- Fixes decals on dead bodies.
local SinglePlayer = game.SinglePlayer()
local Multiplayer = not SinglePlayer
if SinglePlayer and SERVER then
    util.AddNetworkString("ServerRagdollTransferDecals")
    hook.Add(
        "CreateEntityRagdoll",
        "ServerRagdollTransferDecals",
        function(ent, rag)
            net.Start("ServerRagdollTransferDecals")
            net.WriteEntity(rag)
            net.WriteEntity(ent)
            net.Send(Entity(1))
        end
    )
end

if CLIENT then
    if Multiplayer then
        hook.Add(
            "EntityRemoved",
            "ServerRagdollTransferDecals",
            function(RemovedEnt)
                if RemovedEnt:GetShouldServerRagdoll() then
                    for _, ent in ipairs(ents.FindInSphere(RemovedEnt:GetPos(), 50)) do
                        if ent:GetClass() == "prop_ragdoll" and ent:WorldSpaceCenter():DistToSqr(RemovedEnt:WorldSpaceCenter()) < 1000 then ent:SnatchModelInstance(RemovedEnt) end
                    end
                end
            end
        )
    else
        net.Receive(
            "ServerRagdollTransferDecals",
            function()
                local rag = net.ReadEntity()
                local ent = net.ReadEntity()
                rag:SnatchModelInstance(ent)
            end
        )
    end
end

--- 

if CLIENT then return end
AddCSLuaFile("cl_serversideragdolls.lua")
util.AddNetworkString("ragColor")
local meta = FindMetaTable("Player")
if not meta then return end
if not meta.CreateRagdollOld then meta.CreateRagdollOld = meta.CreateRagdoll end
local EnableServerSideRagdolls = CreateConVar("sv_ragdolls", "1", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "Enable server side player corpse ragdolls.")
local RagdollSpeedMultiplier = CreateConVar("sv_ragdolls_speed", "1", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Speed multiplier of player corpse ragdolls.")
local RagdollWeightMultiplier = CreateConVar("sv_ragdolls_weight", "1", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Weight multiplier of player corpse ragdolls.")
local RagdollsCollideWithPlayers = CreateConVar("sv_ragdolls_collide_players", "1", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Whether player corpses should collide with players or not.")
function meta:CreateRagdoll()
    if not EnableServerSideRagdolls:GetBool() then
        self:CreateRagdollOld()
        return
    end

    if not (self or self:IsValid() or self:IsPlayer()) then return end
    self.DeathRagdoll = self.DeathRagdoll or false
    if self.DeathRagdoll then if self.DeathRagdoll:IsValid() then self.DeathRagdoll:Remove() end end
    local ply_pos = self:GetPos()
    local ply_ang = self:GetAngles()
    local ply_mdl = self:GetModel()
    local ply_skn = self:GetSkin()
    local ply_col = self:GetColor()
    local ply_mat = self:GetMaterial()
    local playerModelIsRagdoll = self:GetBoneCount() > 1
    local ent
    if playerModelIsRagdoll then
        ent = ents.Create("prop_ragdoll")
    else
        ent = ents.Create("prop_physics")
    end

    ent:SetPos(ply_pos)
    ent:SetAngles(ply_ang - Angle(ply_ang.p, 0, 0))
    ent:SetModel(ply_mdl)
    ent:SetSkin(ply_skn)
    ent:SetColor(ply_col)
    ent:SetMaterial(ply_mat)
    ent:SetCreator(self)
    for k, v in ipairs(self:GetBodyGroups()) do
        --MsgN("Setting " .. self:GetBodygroupName(v.id).. " to " .. self:GetBodygroup(v.id))
        ent:SetBodygroup(v.id, self:GetBodygroup(v.id))
    end

    ent:Spawn()
    local phys = ent:GetPhysicsObject()
    if phys:IsValid() then phys:SetMass(phys:GetMass() * RagdollWeightMultiplier:GetFloat()) end
    if not ent:IsValid() then return end
    self.DeathRagdoll = ent
    local plyvel = self:GetVelocity()
    if playerModelIsRagdoll then
        -- Position and rotate the ragdoll's limbs, set their velocity
        for i = 0, ent:GetPhysicsObjectCount() - 1 do
            local bone = ent:GetPhysicsObjectNum(i)
            if bone and bone:IsValid() then
                local bonepos, boneang = self:GetBonePosition(ent:TranslatePhysBoneToBone(i))
                bone:SetPos(bonepos)
                bone:SetAngles(boneang)
                bone:SetVelocity(plyvel * RagdollSpeedMultiplier:GetFloat())
            end
        end

        -- Pose the ragdoll's face
        ent:SetFlexScale(self:GetFlexScale())
        for i = 1, ent:GetFlexNum() do
            ent:SetFlexWeight(i, self:GetFlexWeight(i))
        end

        -- Set the ragdoll's playermodel color
        local ply_ragcol = self:GetPlayerColor()
        ent.RagColor = Vector(ply_ragcol.r, ply_ragcol.g, ply_ragcol.b)
        net.Start("ragColor")
        net.WriteInt(ent:EntIndex(), 16)
        net.WriteVector(ent.RagColor)
        net.Broadcast()
    else
        phys:SetVelocity(plyvel * RagdollSpeedMultiplier:GetFloat())
    end

    ent:SetCreator(self)
    if self:IsOnFire() then ent:Ignite(math.Rand(6, 8), 0) end
    if not RagdollsCollideWithPlayers:GetBool() then ent:SetCollisionGroup(COLLISION_GROUP_WEAPON) end
    self:SpectateEntity(ent)
    self:Spectate(OBS_MODE_CHASE)
end

if SERVER then return end

net.Receive("ragColor", function(len)
	local rag = Entity(net.ReadInt(16))
	local col = net.ReadVector()

	rag.GetPlayerColor = function() return col end
end)