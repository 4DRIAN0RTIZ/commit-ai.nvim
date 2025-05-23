local log = require("commit-ai.log")
local M = {}

function M.get_git_diff()
  local status_lines = vim.fn.systemlist('git status --porcelain')
  local untracked_files = vim.tbl_filter(function(line)
    return line:match("^%?%?")
  end, status_lines)

  if #untracked_files > 0 then
    for _, line in ipairs(untracked_files) do
      local file = line:sub(4)
      log.info("‼️ Untracked file: " .. file)
    end
    local answer = vim.fn.input("Do you want to add them to the staging area? (y/n) ")
    if answer:lower() == "y" then
      for _, line in ipairs(untracked_files) do
        local file = line:sub(4)
        vim.fn.system("git add " .. file)
        log.info("📝 Added " .. file .. " to the staging area")
      end
    else
      log.error("Aborting")
      return nil
    end
    return nil
  end
  local staged_diff = vim.fn.system('git diff --cached --no-color')
  if staged_diff == "" then
    staged_diff = vim.fn.system('git diff --no-color')
  end
  staged_diff = staged_diff:gsub("^%s*(.-)%s*$", "%1") -- Remove trailing newlines

  -- Check if we're in a git repository
  if vim.fn.system('git rev-parse --is-inside-work-tree 2>/dev/null'):find("true") == nil then
    log.error("Not in a git repository")
    return nil
  end

  -- Check if there are any changes
  if staged_diff == "" then
    log.error("No staged changes found")
    return nil
  end

  return staged_diff
end

function M.get_api_key(env_var)
  local api_key
  if type(env_var) == 'function' then
    api_key = env_var()
  elseif type(env_var) == 'string' then
    api_key = vim.env[env_var]
  end

  if type(api_key) ~= 'string' or api_key == '' then
    return nil
  end

  return api_key
end

return M
