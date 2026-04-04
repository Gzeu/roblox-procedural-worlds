--!strict
-- ============================================================
-- MODULE: ProceduralQuestGen  [v1.1 - fixed]
-- Generates dynamic quests based on biome + player level.
-- ============================================================

local WorldConfig   = require(script.Parent.WorldConfig)
local BiomeResolver = require(script.Parent.BiomeResolver)

local ProceduralQuestGen = {}

type QuestDef = {
	id: string,
	title: string,
	description: string,
	biome: string,
	objective: string,
	targetCount: number,
	reward: { xp: number, gold: number },
}

local QUEST_TEMPLATES = {
	{
		titleFmt   = "Clear the {biome} Threat",
		descFmt    = "Defeat {count} enemies in the {biome}.",
		objective  = "Kill",
		countRange = { 5, 20 },
		xpMult     = 40,
		goldMult   = 20,
	},
	{
		titleFmt   = "Gather {biome} Resources",
		descFmt    = "Collect {count} resources from the {biome}.",
		objective  = "Collect",
		countRange = { 10, 30 },
		xpMult     = 25,
		goldMult   = 30,
	},
	{
		titleFmt   = "Scout the {biome}",
		descFmt    = "Explore {count} distinct locations in the {biome}.",
		objective  = "Explore",
		countRange = { 3, 8 },
		xpMult     = 60,
		goldMult   = 15,
	},
}

local function fmt(template: string, biome: string, count: number): string
	return template:gsub("{biome}", biome):gsub("{count}", tostring(count))
end

function ProceduralQuestGen.Generate(temperature: number, moisture: number, playerLevel: number): QuestDef
	local biomeResult = BiomeResolver.Resolve(temperature, moisture)
	local biomeName   = biomeResult.Biome and biomeResult.Biome.Name or "Unknown"

	local tmpl = QUEST_TEMPLATES[math.random(#QUEST_TEMPLATES)]
	local count = math.random(tmpl.countRange[1], tmpl.countRange[2])
		+ math.floor(playerLevel * 1.5)

	local id = "q_" .. biomeName:lower() .. "_" .. os.clock():gsub("[^%d]", "")

	return {
		id          = id,
		title       = fmt(tmpl.titleFmt, biomeName, count),
		description = fmt(tmpl.descFmt,  biomeName, count),
		biome       = biomeName,
		objective   = tmpl.objective,
		targetCount = count,
		reward      = {
			xp   = count * tmpl.xpMult   * playerLevel,
			gold = count * tmpl.goldMult * playerLevel,
		},
	}
end

return ProceduralQuestGen
