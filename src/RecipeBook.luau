--[[
	RecipeBook — registry of crafting recipes with query and craft helpers.
	Expects an "inventory" table: { [itemName]: count }.
]]

local RecipeBook = {}
RecipeBook.__index = RecipeBook

export type Inventory = { [string]: number }

function RecipeBook.new()
	return setmetatable({
		_recipes = {} :: { [string]: any }, -- Recipe modules
	}, RecipeBook)
end

-- Register a recipe (anything with :name(), :getInputs(), :getOutputs(), :getBiomeRequired(), :getSkillRequired())
function RecipeBook:register(recipe)
	assert(recipe ~= nil and type(recipe.name) == "function", "Expected a Recipe instance")
	local key = recipe:name()
	assert(self._recipes[key] == nil, ("Recipe %q already registered"):format(key))
	self._recipes[key] = recipe
	return self
end

-- Attempt to craft; returns outputs table or nil + reason.
-- `context` is optional: { biome: string?, skills: { [string]: number }? }
function RecipeBook:craft(name: string, inventory: Inventory, context: { biome: string?, skills: { [string]: number }? }?): (nil | { [string]: number }, string?)
	local recipe = self._recipes[name]
	if not recipe then
		return nil, ("unknown recipe %q"):format(name)
	end

	-- Biome gate
	local biome = recipe:getBiomeRequired()
	if biome then
		local playerBiome = if context then context.biome else nil
		if playerBiome ~= biome then
			return nil, ("requires biome %q, got %s"):format(biome, tostring(playerBiome))
		end
	end

	-- Skill gate
	local skillReq = recipe:getSkillRequired()
	if skillReq then
		local skills = if context then context.skills else nil
		local playerLevel = if skills then skills[skillReq.skill] else nil
		if not playerLevel or playerLevel < skillReq.level then
			return nil, ("requires %s level %d, got %s"):format(skillReq.skill, skillReq.level, tostring(playerLevel))
		end
	end

	-- Check inputs
	for _, inp in recipe:getInputs() do
		local have = inventory[inp.name] or 0
		if have < inp.count then
			return nil, ("insufficient %q: need %d, have %d"):format(inp.name, inp.count, have)
		end
	end

	-- Deduct inputs
	for _, inp in recipe:getInputs() do
		inventory[inp.name] = (inventory[inp.name] or 0) - inp.count
		if inventory[inp.name] <= 0 then
			inventory[inp.name] = nil
		end
	end

	-- Grant outputs
	local result: { [string]: number } = {}
	for _, out in recipe:getOutputs() do
		inventory[out.name] = (inventory[out.name] or 0) + out.count
		result[out.name] = out.count
	end

	return result, nil
end

-- Return a list of recipe names craftable with the given inventory + optional context
function RecipeBook:whatCanCraft(inventory: Inventory, context: { biome: string?, skills: { [string]: number }? }?): { string }
	local result = {}
	for name, recipe in self._recipes do
		local ok = true

		-- Biome check
		local biome = recipe:getBiomeRequired()
		if biome then
			local playerBiome = if context then context.biome else nil
			if playerBiome ~= biome then
				ok = false
			end
		end

		-- Skill check
		if ok then
			local skillReq = recipe:getSkillRequired()
			if skillReq then
				local skills = if context then context.skills else nil
				local playerLevel = if skills then skills[skillReq.skill] else nil
				if not playerLevel or playerLevel < skillReq.level then
					ok = false
				end
			end
		end

		-- Input check
		if ok then
			for _, inp in recipe:getInputs() do
				if (inventory[inp.name] or 0) < inp.count then
					ok = false
					break
				end
			end
		end

		if ok then
			table.insert(result, name)
		end
	end
	return result
end

-- Return all recipes that use a given item as an input
function RecipeBook:recipesUsing(itemName: string): { string }
	local result = {}
	for name, recipe in self._recipes do
		for _, inp in recipe:getInputs() do
			if inp.name == itemName then
				table.insert(result, name)
				break
			end
		end
	end
	return result
end

-- Get a registered recipe by name (or nil)
function RecipeBook:get(name: string)
	return self._recipes[name]
end

return RecipeBook
