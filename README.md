# luau-recipe 🧪

A crafting recipe system for Roblox games — register recipes, check materials, craft items, gate by biome & skill.

## Install

### Wally (recommended)

```toml
# wally.toml
[dependencies]
luau-recipe = "superinstance/luau-recipe@0.1.0"
```

### Rojo

Add to your `default.project.json`:

```json
{
  "name": "luau-recipe",
  "tree": {
    "$className": "ReplicatedStorage",
    "luau-recipe": {
      "$path": "src"
    }
  }
}
```

### Copy-paste

Drop `src/RecipeBook.luau`, `src/Recipe.luau`, and `src/Ingredient.luau` into `ReplicatedStorage`.

## Quick Start

```lua
local RecipeBook = require(path.to.RecipeBook)
local Recipe = require(path.to.Recipe)

-- Create a recipe book
local book = RecipeBook.new()

-- Register recipes (chainable builders)
book:register(
    Recipe.new("iron_sword")
        :input("iron_ingot", 3)
        :output("iron_sword", 1)
)

book:register(
    Recipe.new("torch")
        :input("stick", 1)
        :input("coal", 1)
        :output("torch", 4)
)

-- Biome- and skill-gated recipes
book:register(
    Recipe.new("frost_blade")
        :input("ice_shard", 5)
        :output("frost_blade", 1)
        :biomeRequired("tundra")
        :skillRequired("smithing", 10)
)

-- Craft
local inventory = { iron_ingot = 10, stick = 5, coal = 5 }

local result, err = book:craft("iron_sword", inventory)
-- result = { iron_sword = 1 }
-- inventory = { iron_ingot = 7, iron_sword = 1, stick = 5, coal = 5 }

-- Craft with context (biome, skills)
local context = { biome = "tundra", skills = { smithing = 15 } }
local result2, err2 = book:craft("frost_blade", inventory, context)

-- Query: what can I craft?
local craftable = book:whatCanCraft(inventory, context)
-- { "iron_sword", "torch" }

-- Query: which recipes use iron_ingot?
local recipes = book:recipesUsing("iron_ingot")
-- { "iron_sword" }
```

## API

### Recipe.new(name) → Recipe

Chainable builder:

| Method | Description |
|---|---|
| `:input(name, count)` | Add an input ingredient |
| `:output(name, count)` | Add an output ingredient |
| `:biomeRequired(biome)` | Require player to be in this biome |
| `:skillRequired(skill, level)` | Require minimum skill level |

Accessors: `:name()`, `:getInputs()`, `:getOutputs()`, `:getBiomeRequired()`, `:getSkillRequired()`

### RecipeBook.new() → RecipeBook

| Method | Returns | Description |
|---|---|---|
| `:register(recipe)` | self | Register a recipe |
| `:craft(name, inventory, context?)` | `result, err` | Craft, deducting inputs, adding outputs. `context = { biome, skills }` |
| `:whatCanCraft(inventory, context?)` | `{ string }` | List of craftable recipe names |
| `:recipesUsing(itemName)` | `{ string }` | Recipes that use an item as input |
| `:get(name)` | `Recipe?` | Get a registered recipe |

### Ingredient.new(name, count) → Ingredient

| Method | Returns |
|---|---|
| `:name()` | `string` |
| `:count()` | `number` |

## Running Tests

```bash
luau tests/run-tests.luau
```

25+ tests covering: registration, crafting, insufficient materials, biome gates, skill gates, chain recipes, inventory deduction, multi-output recipes, and combined gates.

## License

MIT
