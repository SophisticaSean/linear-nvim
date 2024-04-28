local M = {}

local FILENAME = "/linear_api_key.txt"
local FILE_PATH = vim.fn.stdpath("data") .. FILENAME

M._api_key = ""

function M.save_api_key(api_key)
  local file = io.open(FILE_PATH, "w") -- Open the file for writing
  if file then
    file:write(api_key)
    file:close()
  else
    print("Failed to open file for saving API key")
  end
end

function M.load_api_key()
  local file = io.open(FILE_PATH, "r") -- Open the file for reading
  if file then
    local api_key = file:read("*a") -- Read the entire contents of the file
    file:close()
    -- strip all whitespace
    api_key = string.gsub(api_key, "%s", "")
    return api_key
  else
    return nil -- Return nil if the file doesn't exist
  end
end

function M.get_api_key()
  -- Ensure the API key is set by checking if it's nil and, if so, setting it
  if not M._api_key or M._api_key == "" then
    --  if not M._api_key then
    M._api_key = M.load_api_key()
  end
  -- Return the API key after ensuring it has been set
  return M._api_key
end

return M
