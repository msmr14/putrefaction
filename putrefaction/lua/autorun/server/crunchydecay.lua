util.AddNetworkString("RagdollStartDecaying")
local EntityMeta = FindMetaTable("Entity")

function EntityMeta:InitiateDecay()
    net.Start("RagdollStartDecaying")
    net.WriteEntity(self)
    net.WriteEntity(self.SkeletonDecay)
    net.Broadcast()

    if GetConVar("ragdolldecay_remove_after_decay_time"):GetBool() then
        local totalDelay = 2 + GetConVar("ragdolldecay_start_time"):GetFloat() +
                           GetConVar("ragdolldecay_remove_after_decay_time"):GetFloat() +
                           GetConVar("ragdolldecay_duration"):GetFloat()
        SafeRemoveEntityDelayed(self, totalDelay)
    end
end

hook.Add("CreateEntityRagdoll", "CrunchyDecay_EntityRagdoll", function(owner, ragdoll)
    if not GetConVar("ragdolldecay_enable"):GetBool() then return end
    if not IsValid(ragdoll) or not ragdoll:IsRagdoll() then return end

    local fleshMaterials = {
        ["flesh"] = true,
        ["alienflesh"] = true,
        ["hunter"] = true,
        ["antlion"] = true,
        ["zombieflesh"] = true,
        ["armorflesh"] = true,
    }

    if fleshMaterials[ragdoll:GetBoneSurfaceProp(0)] then
        timer.Simple(2 + GetConVar("ragdolldecay_start_time"):GetFloat(), function()
            if IsValid(ragdoll) then
                ragdoll:InitiateDecay()
            end
        end)
    end
end)
