--[[
	Ingredient — a named item with a quantity.
	Used for both recipe inputs and outputs.
]]

local Ingredient = {}
Ingredient.__index = Ingredient

function Ingredient.new(name: string, count: number)
	assert(type(name) == "string" and name ~= "", "Ingredient name must be a non-empty string")
	assert(type(count) == "number" and count > 0, "Ingredient count must be a positive number")
	return setmetatable({
		_name = name,
		_count = count,
	}, Ingredient)
end

function Ingredient:name(): string
	return self._name
end

function Ingredient:count(): number
	return self._count
end

return Ingredient
