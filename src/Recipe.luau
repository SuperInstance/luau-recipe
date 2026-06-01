--[[
	Recipe — describes a single crafting recipe with inputs, outputs,
	optional biome and skill requirements.
]]

local Recipe = {}
Recipe.__index = Recipe

function Recipe.new(name: string)
	assert(type(name) == "string" and name ~= "", "Recipe name must be a non-empty string")
	return setmetatable({
		_name = name,
		_inputs = {},
		_outputs = {},
		_biomeRequired = nil,
		_skillRequired = nil,
	}, Recipe)
end

-- Chainable builder methods

function Recipe:input(name: string, count: number)
	table.insert(self._inputs, { name = name, count = count })
	return self
end

function Recipe:output(name: string, count: number)
	table.insert(self._outputs, { name = name, count = count })
	return self
end

function Recipe:biomeRequired(biome: string)
	self._biomeRequired = biome
	return self
end

function Recipe:skillRequired(skill: string, level: number)
	self._skillRequired = { skill = skill, level = level }
	return self
end

-- Accessors

function Recipe:name(): string
	return self._name
end

function Recipe:getInputs(): { { name: string, count: number } }
	return self._inputs
end

function Recipe:getOutputs(): { { name: string, count: number } }
	return self._outputs
end

function Recipe:getBiomeRequired(): string?
	return self._biomeRequired
end

function Recipe:getSkillRequired(): { skill: string, level: number }?
	return self._skillRequired
end

return Recipe
