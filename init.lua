local M = {}
local linear_api = require("linear-nvim.linear-api")
local key_store = require("linear-nvim.key-store")
local utils = require("linear-nvim.utils")

-- telescope imports
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local function show_issues_picker(issues)
  -- Prepare entries for the picker from the issues map
  local entries = {}
  for display_key, data_bag in pairs(issues) do
    table.insert(entries, {
      value = data_bag.branch_name, -- This is what will be copied to the clipboard
      display = display_key, -- How the entry will be displayed
      ordinal = display_key, -- Used for sorting and searching
      description = data_bag.description, -- Additional information that can be displayed
    })
  end

  pickers
    .new({}, {
      prompt_title = "Issues",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = entry.display,
            ordinal = entry.ordinal,
            description = entry.description,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_buffer_previewer({
        define_preview = function(self, entry, _)
          local lines = vim.split(entry.description, "\n", { plain = true })
          -- Set up preview window with description from the entry
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        end,
      }),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          vim.fn.setreg("+", selection.value) -- Copy to clipboard (system clipboard "+")
          vim.fn.setreg('"', selection.value) -- Copy to default register (unnamed register)
          print("Copied to clipboard: " .. selection.value)
        end)
        return true
      end,
    })
    :find()
end

local function show_create_issues_result_picker(issue)
  local entries = {
    {
      value = issue.url,
      display = "Copy Issue URL",
      ordinal = "Copy Issue URL",
      description = issue.url,
    },
    {
      value = issue.branchName,
      display = "Copy Branch Name",
      ordinal = "Copy Branch Name",
      description = issue.branchName,
    },
    {
      value = issue.title,
      display = "Copy Issue Title",
      ordinal = "Copy Issue Title",
      description = issue.title,
    },
    {
      value = issue.identifier,
      display = "Copy Issue Identifier",
      ordinal = "Copy Issue Identifier",
      description = issue.identifier,
    },
  }

  pickers
    .new({}, {
      prompt_title = "Issue created",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = entry.display,
            ordinal = entry.ordinal,
            description = entry.description,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_buffer_previewer({
        define_preview = function(self, entry, _)
          local lines = vim.split(entry.description, "\n", { plain = true })
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        end,
      }),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          vim.fn.setreg("+", selection.value) -- Copy to clipboard (system clipboard "+")
          vim.fn.setreg('"', selection.value) -- Copy to default register (unnamed register)
          print("Copied to clipboard: " .. selection.value)
        end)
        return true
      end,
    })
    :find()
end

-- create a setup command the user has to call to provide an api key to use
-- once this key is saved, we can then setup key commands to trigger fetching
-- issues from Linear and display them in something similar to neotree or neotest
-- i.e. a panel

function M.do_something()
  print("Hello world")
end

function M.show_user_id()
  print(linear_api.get_user_id(key_store.get_api_key()))
end

function M.show_assigned_issues()
  local api_key = key_store.get_api_key()
  local user_id = linear_api.get_user_id(api_key)
  local issues = linear_api.get_assigned_issues(api_key, user_id)

  local issue_titles = {}
  for _, issue in ipairs(issues) do
    local description = issue.description
    if description == vim.NIL or description == nil then
      description = "No description available"
    end
    issue_titles[issue.identifier .. " - " .. issue.title] =
      { branch_name = issue.branchName, description = description }
  end

  show_issues_picker(issue_titles)
end

function M.create_issue()
  local api_key = key_store.get_api_key()
  local user_id = linear_api.get_user_id(api_key)
  local team_id = key_store.get_or_set_team_id()

  local full_selection = utils.get_visual_selection()
  local title, description = full_selection:match("([^\n]*)\n(.*)")

  -- If there is no newline, the whole selection is the title
  if not title then
    title = full_selection
    description = ""
  end
  if title == "" then
    title = vim.fn.input("Enter the title of the issue: ")
  end
  local issue = linear_api.create_issue(api_key, user_id, team_id, title, description)
  if issue ~= nil then
    print("Issue created successfully!")
    show_create_issues_result_picker(issue)
  else
    print("Failed to create issue")
  end
end

return M
