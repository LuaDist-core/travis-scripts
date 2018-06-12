local pl = require 'pl.import_into'()

local config = require "ci_config"

local env = {
  pkg_name       = os.getenv("PKG_NAME")       or error("PKG_NAME must be set"),
  pkg_output_dir = os.getenv("PKG_OUTPUT_DIR") or error("PKG_OUTPUT_DIR must be set"),
  lua_bin        = os.getenv("LUA_BIN")        or error("LUA_BIN must be set"),
  luadist_lib    = os.getenv("LUADIST_LIB")    or error("LUADIST_LIB must be set"),

  STATUS_SUCCESS = "success",
  STATUS_SKIP = "skip",
  STATUS_FAIL = "fail",
}

env.luadist = env.lua_bin .. " " .. env.luadist_lib

local function status_to_bool(status)
  return status ~= env.STATUS_FAIL
end


local everything_ok = true
for _, version in pairs(config.versions) do
  local version_dir = pl.path.join(env.pkg_output_dir, version)
  local status

  for _, task in ipairs(config.tasks) do
    print()
    print("################################")
    print("# Running '" .. task.task_id() .. "' task")
    print("# Lua version: " .. version)
    print("################################")
    print()

    local report
    status, report = task.task(env, version)
    pl.file.write(pl.path.join(version_dir, task.task_id() .. "_status"), status)
    everything_ok = everything_ok and status_to_bool(status)
    pl.file.write(pl.path.join(version_dir, task.task_id() .. "_report.md"), report)

    print()
  end
end

os.exit(everything_ok and 0 or 1)

