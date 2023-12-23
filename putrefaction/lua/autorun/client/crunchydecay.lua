local EntityRef = FindMetaTable("Entity")
local DecayTex = Material("decals/decay_material_2")
local PuddleDecal = Material("decals/decomp_puddle1")

local BoneShrinkThreshold = {
    Min = 0.4,
    ["ValveBiped.Bip01_Spine1"] = 0.85,
    ["ValveBiped.Bip01_Head1"] = 0.85,
}

local DecayTimerID = 0
local DecayingEntities = {}
local DecayFX = {}

hook.Add(
    "PostDrawOpaqueRenderables",
    "EntityDamageOverlay_Draw",
    function()
        for _, entity in ipairs(DecayingEntities) do
            if not IsValid(entity) then
                table.RemoveByValue(DecayingEntities, entity)
                return
            end

            local alphaBlend = entity.DecayBlend * (entity:GetColor().a / 255)
            render.SetBlend(alphaBlend)
            render.MaterialOverride(DecayTex)
            entity:DrawModel()

            local skeletonBlend = 1 - alphaBlend
            if IsValid(entity.SkeletonDecay) and skeletonBlend > 0 then
                render.SetBlend(skeletonBlend)
                render.MaterialOverride(DecayTex)
                entity.SkeletonDecay:DrawModel()
            end

            render.MaterialOverride(nil)
        end
    end
)

function EntityRef:InitiateDecay()
    DecayTimerID = (DecayTimerID % 100) + 1
    local TimerLabel = "DecayTimer_" .. DecayTimerID
    
    if timer.Exists(TimerLabel) then return end
    self.BoneScaleFactor = 1
    self.MaterialBlendFactor = 0
    self.SkeletonScaleFactor = 0

    local RepeatCount = 150
    local DecayDuration = GetConVar("ragdolldecay_duration"):GetFloat()
    local Interval = DecayDuration / RepeatCount

    timer.Create(
        TimerLabel,
        Interval,
        RepeatCount,
        function()
            if not IsValid(self) then
                timer.Remove(TimerLabel)
                return
            end

            if self.BoneScaleFactor >= BoneShrinkThreshold.Min then
                for boneID = 1, self:GetBoneCount() do
                    local Limit = BoneShrinkThreshold[self:GetBoneName(boneID)] or 0.6
                    local scaleVec = Vector(1, 1, 1) * math.Clamp(self.BoneScaleFactor, Limit, 1)
                    self:ManipulateBoneScale(boneID, scaleVec)
                end
            end

            if IsValid(self.SkeletonDecay) then
                for boneID = 1, self.SkeletonDecay:GetBoneCount() do
                    self.SkeletonDecay:ManipulateBoneScale(boneID, Vector(1, 1, 1) * self.SkeletonScaleFactor)
                end
                if self.SkeletonDecay:GetNoDraw() then self.SkeletonDecay:SetNoDraw(false) end
            end

            self.MaterialBlendFactor = (RepeatCount - timer.RepsLeft(TimerLabel)) / RepeatCount
            self.SkeletonScaleFactor = self.MaterialBlendFactor
            self.BoneScaleFactor = 1 - (self.MaterialBlendFactor * 0.3)
        end
    )

    table.insert(DecayingEntities, self)
    self:CallOnRemove("RemoveFromDecayList", function() table.RemoveByValue(DecayingEntities, self) end)

    if self:GetClass() == "prop_ragdoll" then
        local rayTrace = util.TraceLine(
            {
                start = self:GetPos(),
                endpos = self:GetPos() - Vector(0, 0, 100),
                mask = MASK_NPCWORLDSTATIC,
            }
        )

        local FXEmitter = ParticleEmitter(self:GetPos(), true)
        local GroundParticle = FXEmitter:Add(PuddleDecal, rayTrace.HitPos)
        local PuddleSize = math.Rand(20, 30)
        GroundParticle:SetStartSize(0)
        GroundParticle:SetEndSize(PuddleSize)
        GroundParticle:SetDieTime(DecayDuration)
        local angle = rayTrace.HitNormal:Angle()
        angle:RotateAroundAxis(rayTrace.HitNormal, math.Rand(1, 360))
        GroundParticle:SetAngles(angle)

        timer.Simple(
            DecayDuration - 0.15,
            function()
                if GroundParticle then
                    GroundParticle:SetDieTime(10000000)
                    GroundParticle:SetStartSize(PuddleSize)
                    GroundParticle:SetEndSize(PuddleSize)
                end
            end
        )

        FXEmitter:Finish()
        self:CallOnRemove("CleanupDecayPuddle", function() if GroundParticle then GroundParticle:SetLifeTime(20000000) end end)
    end

    self:CallOnRemove(
        "BreakDownCorpse",
        function()
            local soundFile = table.Random({"Nasty/RemoveCorpse_1.wav", "Nasty/RemoveCorpse_2.wav", "Nasty/RemoveCorpse_3.wav"})
            self:EmitSound(soundFile, 80, math.random(90, 110))
            ParticleEffect("slime_splash_01", self:GetPos(), self:GetAngles())
            for boneID = 1, self:GetBoneCount() do
                local bonePos = self:GetBonePosition(boneID)
                if bonePos and math.random(1, 2) == 1 then ParticleEffect("blood_zombie_split", bonePos, AngleRand()) end
            end
            if self.LoopSound then self.LoopSound:Stop() end
        end
    )

    local decaySound = table.Random({"Nasty/DecayLoop_1.wav", "Nasty/DecayLoop_2.wav"})
    self.LoopSound = CreateSound(self, decaySound)
    self.LoopSound:PlayEx(math.Rand(0.7, 0.9), math.random(90, 110))
    timer.Simple(
        DecayDuration,
        function()
            if not IsValid(self) then return end
            if self.LoopSound then self.LoopSound:Stop() end
        end
    )
end

net.Receive(
    "RagdollStartDecaying",
    function()
        local decayedEntity = net.ReadEntity()
        local skeletonEntity = net.ReadEntity()
        decayedEntity.SkeletonDecay = skeletonEntity
        if IsValid(decayedEntity) then decayedEntity:InitiateDecay() end
    end
)
