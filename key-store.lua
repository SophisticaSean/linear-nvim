local M = {}
local linear_api = require("linear-nvim.linear-api")

local FILENAME = "/linear_api_key.txt"
local FILE_PATH = vim.fn.stdpath("data") .. FILENAME

M._api_key = ""
M._team_id = ""

local function save_api_key(api_key)
  local file = io.open(FILE_PATH, "w") -- Open the file for writing
  if file then
    file:write(api_key)
    file:close()
  else
    print("Failed to open file for saving API key")
  end
end

local function load_api_key()
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

function M.set_api_key()
  local api_key = vim.fn.input("Enter your API key: ")
  if api_key ~= "" then
    save_api_key(api_key)
    print("API key saved successfully!")
  else
    print("No API key entered.")
  end
end

function M.get_or_set_team_id()
  if not M._team_id or M._team_id == "" then
    local api_key = M.get_api_key()
    local teams = linear_api.get_teams(api_key)
    if teams ~= nil then
      local selected_team = vim.ui.select(
        vim.tbl_map(function(choice)
          return choice.name
        end, teams),
        { prompt = "Choose your team:" },
        function(choice, idx)
          if choice == nil then
            print("No team selected.")
          else
            print("Selected team: " .. choice .. " ID: " .. teams[idx].id)
          end
        end
      )

      M._team_id = selected_team
      print("Team ID saved successfully!")
    else
      print("No team ID selected.")
    end
  end
  return M._team_id
end

-- @return string: The API key
function M.get_api_key()
  -- Ensure the API key is set by checking if it's nil and, if so, setting it
  if not M._api_key or M._api_key == "" then
    --  if not M._api_key then
    M._api_key = load_api_key()
  end
  -- Return the API key after ensuring it has been set
  return M._api_key
end

return M
