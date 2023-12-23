util.AddNetworkString("RagdollStartDecaying")


local ENT = FindMetaTable("Entity")


--]]==============================================================================================================================[[--
function ENT:StartDecaying()
    -- self.DecaySkeleton = ents.Create("base_gmodentity")
    -- self.DecaySkeleton:SetModel("models/player/skeleton.mdl")
    -- self.DecaySkeleton:SetPos(self:GetPos())
    -- self.DecaySkeleton:SetParent(self)
    -- self.DecaySkeleton:AddEffects(EF_BONEMERGE)
    -- self.DecaySkeleton:SetNoDraw(true)

    -- local brighness = math.Rand(0.35, 0.5)
    -- self.DecaySkeleton:SetColor(Color(150*brighness, 150*brighness, 150*brighness))

    -- self.DecaySkeleton:Spawn()


    net.Start("RagdollStartDecaying")
    net.WriteEntity(self)
    net.WriteEntity(self.DecaySkeleton)
    net.Broadcast()


    if GetConVar("ragdolldecay_remove_after_decay_time"):GetBool() then
        SafeRemoveEntityDelayed(self,
            2+GetConVar("ragdolldecay_start_time"):GetFloat()
            +GetConVar("ragdolldecay_remove_after_decay_time"):GetFloat()
            +GetConVar("ragdolldecay_duration"):GetFloat()
        )
    end
end
--]]==============================================================================================================================[[--
hook.Add("CreateEntityRagdoll", "CrunchyDecay", function( ent, rag )
    if !GetConVar("ragdolldecay_enable"):GetBool() then return end

    if RagdollDecay_IsFleshMaterial[ rag:GetBoneSurfaceProp(0) ] then -- Only fleshy mfs shall decay

        timer.Simple(2+GetConVar("ragdolldecay_start_time"):GetFloat(), function()
            if !IsValid(rag) then return end
            rag:StartDecaying()
        end)
    end
end)
--]]==============================================================================================================================[[--