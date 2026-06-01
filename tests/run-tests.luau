--[[
	Test runner for luau-recipe.
	Run: luau tests/run-tests.luau  (or in Roblox with a test framework)
]]

local RecipeBook = require(script.Parent.src.RecipeBook)
local Recipe = require(script.Parent.src.Recipe)
local Ingredient = require(script.Parent.src.Ingredient)

local passed = 0
local failed = 0

local function assert_(cond: boolean, msg: string)
	if cond then
		passed += 1
	else
		failed += 1
		warn("FAIL: " .. msg)
	end
end

local function assertEqual(actual: any, expected: any, msg: string)
	if actual == expected then
		passed += 1
	else
		failed += 1
		warn(("FAIL: %s — expected %s, got %s"):format(msg, tostring(expected), tostring(actual)))
	end
end

-- ===== Ingredient tests =====
do
	local ing = Ingredient.new("wood", 5)
	assertEqual(ing:name(), "wood", "Ingredient:name()")
	assertEqual(ing:count(), 5, "Ingredient:count()")
end

-- ===== Recipe construction tests =====
do
	local r = Recipe.new("iron_sword")
		:input("iron_ingot", 3)
		:output("iron_sword", 1)

	assertEqual(r:name(), "iron_sword", "Recipe:name()")
	assertEqual(#r:getInputs(), 1, "Recipe has 1 input")
	assertEqual(#r:getOutputs(), 1, "Recipe has 1 output")
	assertEqual(r:getInputs()[1].name, "iron_ingot", "Recipe input name")
	assertEqual(r:getInputs()[1].count, 3, "Recipe input count")
	assertEqual(r:getOutputs()[1].name, "iron_sword", "Recipe output name")
	assertEqual(r:getBiomeRequired(), nil, "No biome required by default")
	assertEqual(r:getSkillRequired(), nil, "No skill required by default")
end

-- ===== Recipe biome & skill =====
do
	local r = Recipe.new("frost_blade")
		:input("ice_shard", 5)
		:output("frost_blade", 1)
		:biomeRequired("tundra")
		:skillRequired("smithing", 10)

	assertEqual(r:getBiomeRequired(), "tundra", "Biome required set")
	local sk = r:getSkillRequired()
	assert_(sk ~= nil, "Skill required is set")
	assertEqual(sk.skill, "smithing", "Skill name")
	assertEqual(sk.level, 10, "Skill level")
end

-- ===== RecipeBook: register =====
do
	local book = RecipeBook.new()
	local r = Recipe.new("torch"):input("stick", 1):input("coal", 1):output("torch", 4)
	book:register(r)
	assert_(book:get("torch") ~= nil, "Recipe registered")
	assertEqual(book:get("nonexistent"), nil, "Unregistered recipe is nil")
end

-- ===== RecipeBook: craft basic =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("torch"):input("stick", 1):input("coal", 1):output("torch", 4))

	local inv = { stick = 10, coal = 10 }
	local result, err = book:craft("torch", inv)
	assert_(err == nil, "Craft torch succeeds")
	assertEqual(result.torch, 4, "Craft torch outputs 4")
	assertEqual(inv.stick, 9, "Stick deducted")
	assertEqual(inv.coal, 9, "Coal deducted")
	assertEqual(inv.torch, 4, "Torch added to inventory")
end

-- ===== RecipeBook: craft unknown recipe =====
do
	local book = RecipeBook.new()
	local _, err = book:craft("nonexistent", {})
	assert_(err ~= nil, "Unknown recipe returns error")
end

-- ===== RecipeBook: craft insufficient materials =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("iron_sword"):input("iron_ingot", 3):output("iron_sword", 1))

	local inv = { iron_ingot = 2 }
	local result, err = book:craft("iron_sword", inv)
	assert_(result == nil, "Craft fails with insufficient materials")
	assert_(err ~= nil, "Error message provided")
	assert_(string.find(err, "insufficient") ~= nil, "Error mentions insufficient")
	assertEqual(inv.iron_ingot, 2, "Inventory unchanged on failure")
end

-- ===== RecipeBook: craft with exact materials =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("plank"):input("wood", 1):output("plank", 4))

	local inv = { wood = 1 }
	local result, err = book:craft("plank", inv)
	assert_(err == nil, "Craft with exact materials succeeds")
	assertEqual(inv.wood, nil, "Wood key removed when zero")
	assertEqual(inv.plank, 4, "Planks added")
end

-- ===== RecipeBook: biome gate — blocked =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("frost_blade"):input("ice_shard", 5):output("frost_blade", 1):biomeRequired("tundra"))

	local inv = { ice_shard = 10 }
	local result, err = book:craft("frost_blade", inv, { biome = "desert" })
	assert_(result == nil, "Craft blocked by wrong biome")
	assert_(err ~= nil, "Biome error provided")
	assertEqual(inv.ice_shard, 10, "Inventory unchanged on biome gate")
end

-- ===== RecipeBook: biome gate — allowed =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("frost_blade"):input("ice_shard", 5):output("frost_blade", 1):biomeRequired("tundra"))

	local inv = { ice_shard = 10 }
	local result, err = book:craft("frost_blade", inv, { biome = "tundra" })
	assert_(err == nil, "Craft allowed with correct biome")
	assertEqual(result.frost_blade, 1, "Output granted")
end

-- ===== RecipeBook: biome gate — no context =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("frost_blade"):input("ice_shard", 5):output("frost_blade", 1):biomeRequired("tundra"))

	local inv = { ice_shard = 10 }
	local result, _ = book:craft("frost_blade", inv)
	assert_(result == nil, "Craft blocked when no context provided but biome required")
end

-- ===== RecipeBook: skill gate — insufficient level =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("dragon_armor"):input("dragon_scale", 10):output("dragon_armor", 1):skillRequired("smithing", 50))

	local inv = { dragon_scale = 100 }
	local result, err = book:craft("dragon_armor", inv, { skills = { smithing = 30 } })
	assert_(result == nil, "Craft blocked by low skill")
	assert_(err ~= nil, "Skill error provided")
end

-- ===== RecipeBook: skill gate — sufficient level =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("dragon_armor"):input("dragon_scale", 10):output("dragon_armor", 1):skillRequired("smithing", 50))

	local inv = { dragon_scale = 100 }
	local result, err = book:craft("dragon_armor", inv, { skills = { smithing = 50 } })
	assert_(err == nil, "Craft allowed with exact skill level")
	assertEqual(result.dragon_armor, 1, "Output granted")
end

-- ===== RecipeBook: chain recipes =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("iron_ingot"):input("iron_ore", 2):output("iron_ingot", 1))
	book:register(Recipe.new("iron_sword"):input("iron_ingot", 3):output("iron_sword", 1))

	local inv = { iron_ore = 12 }
	-- First craft: ore → ingots
	local r1, e1 = book:craft("iron_ingot", inv)
	assert_(e1 == nil, "Chain step 1 succeeds")
	assertEqual(inv.iron_ingot, 1, "First ingot crafted")
	assertEqual(inv.iron_ore, 10, "Ore deducted")

	-- Craft more ingots
	book:craft("iron_ingot", inv)
	book:craft("iron_ingot", inv)
	assertEqual(inv.iron_ingot, 3, "Three ingots ready")
	assertEqual(inv.iron_ore, 6, "Ore deducted 6 total")

	-- Now craft sword
	local r2, e2 = book:craft("iron_sword", inv)
	assert_(e2 == nil, "Chain step 2 succeeds")
	assertEqual(r2.iron_sword, 1, "Sword crafted")
	assertEqual(inv.iron_ingot, 0, "Ingots consumed")
	assert_(inv.iron_ingot == nil, "Ingots key removed")
end

-- ===== RecipeBook: whatCanCraft =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("torch"):input("stick", 1):input("coal", 1):output("torch", 4))
	book:register(Recipe.new("iron_sword"):input("iron_ingot", 3):output("iron_sword", 1))
	book:register(Recipe.new("plank"):input("wood", 1):output("plank", 4))

	local inv = { stick = 5, coal = 5, iron_ingot = 1 }
	local craftable = book:whatCanCraft(inv)
	assert_(#craftable == 1, "Only 1 recipe craftable")
	assertEqual(craftable[1], "torch", "Only torch is craftable")
end

-- ===== RecipeBook: whatCanCraft with biome filter =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("torch"):input("stick", 1):input("coal", 1):output("torch", 4))
	book:register(Recipe.new("frost_blade"):input("ice_shard", 5):output("frost_blade", 1):biomeRequired("tundra"))

	local inv = { stick = 5, coal = 5, ice_shard = 10 }
	local craftable = book:whatCanCraft(inv, { biome = "desert" })
	assert_(#craftable == 1, "Biome filters out frost_blade")
	assertEqual(craftable[1], "torch", "Only torch craftable in desert")
end

-- ===== RecipeBook: whatCanCraft with skill filter =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("torch"):input("stick", 1):input("coal", 1):output("torch", 4))
	book:register(Recipe.new("master_sword"):input("gold", 5):output("master_sword", 1):skillRequired("smithing", 100))

	local inv = { stick = 5, coal = 5, gold = 100 }
	local craftable = book:whatCanCraft(inv, { skills = { smithing = 50 } })
	assert_(#craftable == 1, "Skill filters out master_sword")
end

-- ===== RecipeBook: recipesUsing =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("torch"):input("stick", 1):input("coal", 1):output("torch", 4))
	book:register(Recipe.new("campfire"):input("stick", 3):input("coal", 2):output("campfire", 1))
	book:register(Recipe.new("iron_sword"):input("iron_ingot", 3):output("iron_sword", 1))

	local usesStick = book:recipesUsing("stick")
	assert_(#usesStick == 2, "stick used in 2 recipes")

	local usesIron = book:recipesUsing("iron_ingot")
	assert_(#usesIron == 1, "iron_ingot used in 1 recipe")
	assertEqual(usesIron[1], "iron_sword", "iron_ingot → iron_sword")

	local usesNothing = book:recipesUsing("unicorn_horn")
	assert_(#usesNothing == 0, "No recipes use unicorn_horn")
end

-- ===== RecipeBook: inventory deduction across multiple crafts =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("arrow"):input("stick", 1):input("flint", 1):output("arrow", 4))

	local inv = { stick = 3, flint = 3 }
	book:craft("arrow", inv)
	book:craft("arrow", inv)
	book:craft("arrow", inv)
	assertEqual(inv.stick, nil, "All sticks used")
	assertEqual(inv.flint, nil, "All flint used")
	assertEqual(inv.arrow, 12, "12 arrows crafted")

	-- Fourth craft should fail
	local r4, e4 = book:craft("arrow", inv)
	assert_(r4 == nil, "Cannot craft without materials")
end

-- ===== RecipeBook: multiple outputs =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("bonemeal")
		:input("bone", 1)
		:output("bonemeal", 3)
		:output("calcium", 1))

	local inv = { bone = 5 }
	local result, err = book:craft("bonemeal", inv)
	assert_(err == nil, "Multi-output craft succeeds")
	assertEqual(result.bonemeal, 3, "bonemeal output")
	assertEqual(result.calcium, 1, "calcium output")
	assertEqual(inv.bonemeal, 3, "bonemeal in inventory")
	assertEqual(inv.calcium, 1, "calcium in inventory")
	assertEqual(inv.bone, 4, "bone deducted")
end

-- ===== RecipeBook: combined biome + skill gate =====
do
	local book = RecipeBook.new()
	book:register(Recipe.new("volcanic_pick")
		:input("obsidian", 5)
		:output("volcanic_pick", 1)
		:biomeRequired("volcano")
		:skillRequired("mining", 30))

	local inv = { obsidian = 20 }

	-- Wrong biome
	local r1, _ = book:craft("volcanic_pick", inv, { biome = "plains", skills = { mining = 50 } })
	assert_(r1 == nil, "Blocked by biome even with skill")

	-- Low skill
	local r2, _ = book:craft("volcanic_pick", inv, { biome = "volcano", skills = { mining = 10 } })
	assert_(r2 == nil, "Blocked by skill even with correct biome")

	-- Both correct
	local r3, e3 = book:craft("volcanic_pick", inv, { biome = "volcano", skills = { mining = 30 } })
	assert_(e3 == nil, "Craft succeeds with correct biome + skill")
	assertEqual(r3.volcanic_pick, 1, "Output granted")
end

-- ===== Results =====
print(("="):rep(50))
print(("Tests: %d passed, %d failed, %d total"):format(passed, failed, passed + failed))
if failed > 0 then
	print("SOME TESTS FAILED")
else
	print("ALL TESTS PASSED")
end
print(("="):rep(50))
