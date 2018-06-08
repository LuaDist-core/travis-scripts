local pl = {}
pl.dir   = require 'pl.dir'
pl.path  = require 'pl.path'
pl.utils = require 'pl.utils'
pl.pretty = require 'pl.pretty'

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

local function read_file(path)
  local file, err = io.open(path, "r")
  if not file then
    print("Something went wrong reading '" .. path .. "': " .. err)
    os.exit(1)
  end

  local content = file:read("*a")
  file:close()
  return content
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

local directories = pl.dir.getdirectories(pkg_output_dir)
for _, dir in pairs(directories) do
  local install_dir = pl.path.join(dir, "install")
  local files = pl.dir.getfiles(install_dir, "*.md")

  if #files == 1 then
    local report_file_path = files[1]
    local report_dirname = pl.path.dirname(report_file_path)

    local version_string = string.sub(pl.path.basename(dir), ("lua "):len() + 1)
    local dest_dir = pl.path.join(cloned_repo, "packages", pkg_name, "linux", version_string)

    run_cmd("mkdir -p \"" .. dest_dir .. "\"")

    write_file(pl.path.join(dest_dir, "install.md"), read_file(report_file_path))

    local status_file_content = read_file(pl.path.join(dir, "install_status"))

    datayml = datayml .. "    - version: " .. version_string .. "\n"
    datayml = datayml .. "      success: " .. ((status_file_content == "success") and "true" or "false") .. "\n"
  else
    print("There's not exactly one .md file as expected, skipping...")
  end
end

local ymlfile_dir = pl.path.join(cloned_repo, "_data", "packages", pkg_name)
run_cmd("mkdir -p \"" .. ymlfile_dir .. "\"")
write_file(pl.path.join(ymlfile_dir, "linux.yml"), datayml)

