local pl = require "pl.import_into"()

local install = {}

-- install.task_id returns a unique task identifier
function install.task_id()
  return "install"
end

-- install.task performs an installation of the given package using
-- a specific Lua version
function install.task(env, lua_version)
  local version_dir = pl.path.join(pl.path.normpath(env.pkg_output_dir), lua_version)
  local install_dir = pl.path.join(version_dir, install.task_id())

  local cmd = env.luadist .. " \"" .. install_dir  .. "\" install \"" .. lua_version .. "\" " .. env.pkg_name
  print("+ " .. cmd)
  local ok = pl.utils.execute(cmd)

  local report_content = nil

  local files = pl.dir.getfiles(install_dir, "*.md")
  if #files == 1 then
    report_content = pl.file.read(files[1])
    if report_content == nil then
      -- this shouldn't happen
      io.stderr:write("Could not load report file.\n")
    end
  else
      -- this shouldn't happen either
    io.stderr:write("There's not exactly one .md file as expected.\n")
    if ok then
      io.stderr:write("Install returned a success code anyway, forcing the test to fail...\n")
      ok = false
    end
  end

  return ok and env.STATUS_SUCCESS or env.STATUS_FAIL, report_content
end

return install

