local config = {}

-- Specify Lua versions to test the package with.
-- Every name must be a valid LuaDist package.
config.versions = {
  "lua 5.1.5-1",
  "lua 5.2.4-1",
  "lua 5.3.2"
}

config.tasks = {
	require "tasks.install",
	--require "tasks.require"
}

return config

