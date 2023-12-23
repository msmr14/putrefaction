-- Настойка
CreateConVar("decay_enabled", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)) -- вкл или выкл
CreateConVar("decay_start_delay", "60", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)) -- через сколько начинает гнить
CreateConVar("decay_process_duration", "60", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)) -- сколько до полного гниения
CreateConVar("decay_cleanup_delay", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)) -- через скок удаляется (на дбг не надо)


game.AddParticles("particles/water_impact.pcf")
game.AddParticles("particles/blood_impact.pcf")
PrecacheParticleSystem("slime_splash_01")
PrecacheParticleSystem("blood_zombie_split")

DecayFleshMaterials = {
    ["flesh"] = true,
    ["alienflesh"] = true,
    ["hunter"] = true,
    ["antlion"] = true,
    ["zombieflesh"] = true,
    ["armorflesh"] = true,
}
