CreateConVar("ragdolldecay_enable", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("ragdolldecay_start_time", "60", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
CreateConVar("ragdolldecay_duration", "60", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
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