local pl = {}
pl.dir = require 'pl.dir'
pl.path  = require 'pl.path'
pl.utils = require 'pl.utils'

-- Specify Lua versions to test the package with.
-- Every name must be a valid LuaDist package.
local versions = {
  "lua 5.1.5-1",
  "lua 5.2.4-1",
  "lua 5.3.2"
}

local pkg_name       = os.getenv("PKG_NAME")       or error("PKG_NAME must be set")
local pkg_output_dir = os.getenv("PKG_OUTPUT_DIR") or error("PKG_OUTPUT_DIR must be set")
local lua_bin        = os.getenv("LUA_BIN")        or error("LUA_BIN must be set")
local luadist_lib    = os.getenv("LUADIST_LIB")    or error("LUADIST_LIB must be set")

local luadist = lua_bin .. " " .. luadist_lib

-- Helper function to write status into a file.
local function write_status(file_path, status)
  if type(status) == "boolean" then
	  status = status and "success" or "fail"
  end

  local file = io.open(file_path, "w")
  if not file then
    print("Something went wrong writing '" .. file_path .. "', exiting...")
    os.exit(1)
  end

  file:write(status)
  file:close()
end

-- install_task performs an installation of the given package using
-- a specific Lua version
local function install_task(version)
  local version_dir = pl.path.join(pkg_output_dir, version)
  local install_dir = pl.path.join(version_dir, "install")

  local cmd = luadist .. " \"" .. install_dir  .. "\" install \"" .. version .. "\" " .. pkg_name
  print("+ " .. cmd)
  local ok = pl.utils.execute(cmd)
  return ok
end

local everything_ok = true
for _, version in pairs(versions) do
  local version_dir = pl.path.join(pkg_output_dir, version)

  local ok = install_task(version)
  write_status(pl.path.join(version_dir, "install_status"), ok)
  everything_ok = everything_ok and ok
end

os.exit(everything_ok and 0 or 1)

