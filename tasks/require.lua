local pl = require "pl.import_into"()

local req = {}

-- req.task_id returns a unique task identifier
function req.task_id()
  return "require"
end

-- req.task tries to require the module in lua code and see if it succeeds
function req.task(env, lua_version)
  local version_dir = pl.path.join(pl.path.normpath(env.pkg_output_dir), lua_version)
  local install_dir = pl.path.join(version_dir, "install")
  local lua_bin = pl.path.join(install_dir, "bin", "lua")

  local report_content = ""

  local ok, code, stdout, stderr = pl.utils.executeex("git describe --tags")
  if not ok then
    local err = "Error getting current tag: " .. pl.pretty.write(stderr) .. "\n"
    io.stderr:write(err)
    return env.STATUS_FAIL, report_content .. err
  end
  local tag = (stdout:gsub("^%s*(.-)%s*$", "%1"))
  local pattern = "*" .. tag ..".rockspec"

  local files = pl.dir.getfiles(".", pattern)
  local rockspec_path
  if #files == 0 then
    local err = "Could not find any rockspec files.\n"
    io.stderr:write(err)
    return env.STATUS_FAIL, report_content .. err
  else
    if #files > 1 then
      local info = "Picking the first rockspec file from the following candidates:\n" .. pl.pretty.write(files) .. "\n"
      io.stderr:write(info)
      report_content = report_content .. info
    end
    rockspec_path = files[1]
  end

  -- Load rockspec from file
  local contents = pl.file.read(rockspec_path)
  local lines = pl.stringx.splitlines(contents)

  -- Remove possible hashbangs
  for i, line in ipairs(lines) do
    if line:match("^#!.*") then
      table.remove(lines, i)
    end
  end
--
  -- Load rockspec file as table
  local rockspec = pl.pretty.load(pl.stringx.join("\n", lines), nil, false)

  if type(rockspec) ~= 'table' then
    local err = "Corrupted rockspec file: " .. rockspec_path .. "\n"
    io.stderr:write(err)
    return env.STATUS_FAIL, report_content .. err
  end

  if not rockspec.build or rockspec.build.type ~= 'builtin' then
    local err = "Build type \"" .. rockspec.build.type .. "\" not supported for testing module requires.\n"
    io.stderr:write(err)
    return env.STATUS_SKIP, report_content .. err
  end

  local success = true

  local modules = rockspec.build and rockspec.build.modules or {}
  for mod in pl.tablex.sort(modules) do
    local ok, code, stdout, stderr = pl.utils.executeex("timeout 2 \"" .. lua_bin .. "\" -e 'require \"" .. mod .. "\"'")
    local line = " - `require \"" .. mod .. "\"` - " .. (ok and "OK" or "FAIL")
    if not ok then
      line = line .. " - " .. pl.pretty.write(stderr)
      io.stderr:write(pl.pretty.write(stderr) .. "\n")
    end

    report_content = report_content .. " - " .. line .. "\n"
    success = success and ok
  end

  return success and env.STATUS_SUCCESS or env.STATUS_FAIL, report_content
end

return req

