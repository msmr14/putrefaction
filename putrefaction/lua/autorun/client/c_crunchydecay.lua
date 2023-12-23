local ENT = FindMetaTable("Entity")
local DecayMaterial = Material("decals/decay_material_2")
local DecayPuddleMaterial = Material("decals/decomp_puddle1")
local BoneScaleLimit = {
    0.4,
    ["ValveBiped.Bip01_Spine1"] = 0.85,
    ["ValveBiped.Bip01_Head1"] = 0.85,
}

local DecayTimersCount = 0
local DecayingRagdolls = {}
local Particles = {}
hook.Add(
    "PostDrawOpaqueRenderables",
    "PostDrawOpaqueRenderables_EntDamageOverlay",
    function()
        -- Overlay
        for _, rag in ipairs(DecayingRagdolls) do
            if not IsValid(rag) then
                table.RemoveByValue(DecayingRagdolls, rag)
                return
            end

            local blend = rag.Decay_MaterialBlend * (rag:GetColor().a / 255)
            render.SetBlend(blend)
            render.MaterialOverride(DecayMaterial)
            rag:DrawModel()
            local skele_blend = 1 - blend
            if IsValid(rag.DecaySkeleton) and skele_blend > 0 then
                render.SetBlend(skele_blend)
                render.MaterialOverride(DecayMaterial)
                rag.DecaySkeleton:DrawModel()
            end

            render.MaterialOverride(nil)
        end
    end
)

function ENT:StartDecaying()
    DecayTimersCount = DecayTimersCount + 1
    if DecayTimersCount > 100 then DecayTimersCount = 1 end
    local TimerName = "DecayTimer" .. DecayTimersCount
    if timer.Exists(TimerName) then return end
    self.Decay_BoneScale = 1
    self.Decay_MaterialBlend = 0
    self.Decay_Skeleton_BoneScale = 0
    -- Decay timer
    local Reps = 150
    local Duration = GetConVar("ragdolldecay_duration"):GetFloat()
    local Delay = Duration / Reps
    timer.Create(
        TimerName,
        Delay,
        Reps,
        function()
            if not IsValid(self) then
                timer.Remove(TimerName)
                return
            end

            if self.Decay_BoneScale >= BoneScaleLimit[1] then
                for i = 1, self:GetBoneCount() do
                    local ScaleLimit = BoneScaleLimit[self:GetBoneName(i)] or 0.6
                    local vec = Vector(1, 1, 1) * math.Clamp(self.Decay_BoneScale, ScaleLimit, 1)
                    self:ManipulateBoneScale(i, vec)
                end
            end

            if IsValid(self.DecaySkeleton) then
                for i = 1, self.DecaySkeleton:GetBoneCount() do
                    self.DecaySkeleton:ManipulateBoneScale(i, Vector(1, 1, 1) * self.Decay_Skeleton_BoneScale)
                end

                if self.DecaySkeleton:GetNoDraw() then self.DecaySkeleton:SetNoDraw(false) end
            end

            self.Decay_MaterialBlend = (Reps - timer.RepsLeft(TimerName)) / Reps
            self.Decay_Skeleton_BoneScale = self.Decay_MaterialBlend
            self.Decay_BoneScale = 1 - (self.Decay_MaterialBlend * 0.3)
        end
    )

    -- Register for decay material 
    table.insert(DecayingRagdolls, self)
    self:CallOnRemove("RemoveFromDecayingRagdolls", function() table.RemoveByValue(DecayingRagdolls, self) end)
    if self:GetClass() == "prop_ragdoll" then
        -- Decay puddle thingy 
        local tr = util.TraceLine(
            {
                start = self:GetPos(),
                endpos = self:GetPos() - Vector(0, 0, 100),
                mask = MASK_NPCWORLDSTATIC,
            }
        )

        local Emitter = ParticleEmitter(self:GetPos(), true)
        local Particle = Emitter:Add(DecayPuddleMaterial, tr.HitPos)
        local Scale = math.Rand(20, 30)
        Particle:SetStartSize(0)
        Particle:SetEndSize(Scale)
        Particle:SetDieTime(Duration)
        local ang = tr.HitNormal:Angle()
        ang:RotateAroundAxis(tr.HitNormal, math.Rand(1, 360))
        Particle:SetAngles(ang)
        timer.Simple(
            Duration - 0.15,
            function()
                if Particle then
                    Particle:SetDieTime(10000000)
                    Particle:SetStartSize(Scale)
                    Particle:SetEndSize(Scale)
                end
            end
        )

        Emitter:Finish()
        self:CallOnRemove("RemoveDecayPuddle", function() if Particle then Particle:SetLifeTime(20000000) end end)
    end

    -- Particle and sound on remove
    self:CallOnRemove(
        "DecayCorpseBreak",
        function()
            local snd = table.Random({"Nasty/RemoveCorpse_1.wav", "Nasty/RemoveCorpse_2.wav", "Nasty/RemoveCorpse_3.wav"})
            self:EmitSound(snd, 80, math.random(90, 110))
            ParticleEffect("slime_splash_01", self:GetPos(), self:GetAngles())
            for i = 1, self:GetBoneCount() do
                local pos = self:GetBonePosition(i)
                if pos and math.random(1, 2) == 1 then ParticleEffect("blood_zombie_split", self:GetBonePosition(i), AngleRand()) end
            end

            self.DecayLoopSound:Stop()
        end
    )

    -- Loop sound
    local snd = table.Random({"Nasty/DecayLoop_1.wav", "Nasty/DecayLoop_2.wav"})
    self.DecayLoopSound = CreateSound(self, snd)
    self.DecayLoopSound:PlayEx(math.Rand(0.7, 0.9), math.random(90, 110))
    timer.Simple(
        Duration,
        function()
            if not IsValid(self) then return end
            if not self.DecayLoopSound then return end
            self.DecayLoopSound:Stop()
        end
    )
end

net.Receive(
    "RagdollStartDecaying",
    function()
        local rag = net.ReadEntity()
        local skeleton = net.ReadEntity()
        rag.DecaySkeleton = skeleton
        if IsValid(rag) then rag:StartDecaying() end
    end
)