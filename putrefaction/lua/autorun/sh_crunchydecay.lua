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