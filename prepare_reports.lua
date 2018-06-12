local pl = require "pl.import_into"()

local config = require "ci_config"

local pkg_name       = os.getenv("PKG_NAME")       or error("PKG_NAME must be set")
local pkg_output_dir = os.getenv("PKG_OUTPUT_DIR") or error("PKG_OUTPUT_DIR must be set")
local cloned_repo    = os.getenv("CLONED_REPO")    or error("CLONED_REPO must be set")

local function run_cmd(cmd)
  print("+ " .. cmd)
  local ok = pl.utils.execute(cmd)
  if not ok then
    os.exit(1)
  end
end

local function write_file(path, content)
  local file, err = io.open(path, "w")
  if not file then
    print("Something went wrong writing '" .. path .. "': " .. err)
    os.exit(1)
  end

  file:write(content)
  file:close()
end

local datayml = "name: Linux\nversions:\n"

for _, version in ipairs(config.versions) do
  local dir = pl.path.join(pkg_output_dir, version)
  local report = ""

  local status = true

  for _, task in ipairs(config.tasks) do
    local status_file_path = pl.path.join(dir, task.task_id() .. "_status")
    local status_file_content = pl.file.read(status_file_path)

    if status_file_content then
      status = status and (status_file_content == "success")
    else
      io.stderr:write("Could not open file '" .. task.task_id() .. "_status'")
      status = false
    end

    local file_path = pl.path.join(dir, task.task_id() .. "_report.md")
    local content = pl.file.read(file_path)

    report = report .. "# Report for task '" .. task.task_id() .. "'\n\n"
    if content then
      report = report .. content .. "\n"
    else
      report = report .. "Error: Report file not found. Please check Travis log. "
    end
  end

  local version_string = string.sub(version, ("lua "):len() + 1)
  local dest_dir = pl.path.join(cloned_repo, "packages", pkg_name, "linux", version_string)

  run_cmd("mkdir -p \"" .. dest_dir .. "\"")

  write_file(pl.path.join(dest_dir, "install.md"), report)

  datayml = datayml .. "    - version: " .. version_string .. "\n"
  datayml = datayml .. "      success: " .. (status and "true" or "false") .. "\n"
end

local ymlfile_dir = pl.path.join(cloned_repo, "_data", "packages", pkg_name)
run_cmd("mkdir -p \"" .. ymlfile_dir .. "\"")
write_file(pl.path.join(ymlfile_dir, "linux.yml"), datayml)

