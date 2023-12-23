util.AddNetworkString("RagdollStartDecaying")
local ENT = FindMetaTable("Entity")
function ENT:StartDecaying()
    net.Start("RagdollStartDecaying")
    net.WriteEntity(self)
    net.WriteEntity(self.DecaySkeleton)
    net.Broadcast()
    if GetConVar("ragdolldecay_remove_after_decay_time"):GetBool() then SafeRemoveEntityDelayed(self, 2 + GetConVar("ragdolldecay_start_time"):GetFloat() + GetConVar("ragdolldecay_remove_after_decay_time"):GetFloat() + GetConVar("ragdolldecay_duration"):GetFloat()) end
end

hook.Add(
    "CreateEntityRagdoll",
    "CrunchyDecay",
    function(ent, rag)
        if not GetConVar("ragdolldecay_enable"):GetBool() then return end
        if RagdollDecay_IsFleshMaterial[rag:GetBoneSurfaceProp(0)] then -- Only fleshy mfs shall decay
            timer.Simple(
                2 + GetConVar("ragdolldecay_start_time"):GetFloat(),
                function()
                    if not IsValid(rag) then return end
                    rag:StartDecaying()
                end
            )
        end
    end
)

hook.Add("EntityTakeDamage", "CheckForBurningCorpse", function(target, dmginfo)
    if target:IsRagdoll() and dmginfo:IsDamageType(DMG_BURN) then
        if not target.BurnToSkeletonTimer then
            target.BurnToSkeletonTimer = true

            timer.Simple(30, function()
                if IsValid(target) then
                    target:SetModel("models/player/skeleton.mdl") 
                end
            end)
        end
    end
end)

print ("132193819238913891283")