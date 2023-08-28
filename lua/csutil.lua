local utils = require("utils")

local M = {}

CsUtilConfig = CsUtilConfig or {}

function M.setup(config)
    CsUtilConfig = config
end

M.setup()

local function add_new(type)
    local current_file_name = vim.api.nvim_buf_get_name(0)
    if current_file_name == "" then
        print("no current file")
        return
    end
    local current_dir = vim.fs.dirname(current_file_name)
    current_file_name = vim.fs.normalize(current_file_name)
    local current_base_name = vim.fs.basename(current_file_name)
    local sysname = vim.loop.os_uname().sysname
    local seperator

    if sysname == "Linux" then
        seperator = "/"
    else
        seperator = "\\"
    end

    local csproj_files = vim.fs.find(function(name, _)
        return name:match('.*%.csproj$')
    end, {
        type = 'file',
        upward = true,
        stop = vim.loop.os_homedir(),
        path = current_dir
    })

    if #csproj_files ~= 1 then
        print(#csproj_files, "csproj files found")
        return
    end

    local proj_directory = vim.fs.dirname(csproj_files[1])

    local parent_of_proj_directory
    for dir in vim.fs.parents(proj_directory) do
        parent_of_proj_directory = vim.fs.normalize(dir)
        break
    end

    local namespace = utils.replace(current_file_name, parent_of_proj_directory .. seperator, "")
    namespace = namespace:gsub(seperator .. current_base_name, "")
    namespace = namespace:gsub(seperator, ".")

    local class_name = vim.fn.input(utils.first_to_upper(type) .. " name: ")

    local file_to_edit = current_dir .. seperator .. class_name .. ".cs"

    local buffer = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buffer, file_to_edit)
    vim.api.nvim_buf_set_lines(buffer, 0, 6, false, {
        "namespace " .. namespace,
        "{",
        "   public " .. type .. " " .. class_name,
        "   {",
        "   }",
        "}"
    })

    vim.api.nvim_buf_call(buffer, function()
        vim.api.nvim_command('w')
    end)

    -- re-edit the saved file to force treesitter to do its thing
    -- surely there's a better way? too lazy for now..
    vim.api.nvim_buf_call(buffer, function()
        vim.api.nvim_command('e!')
    end)

    vim.api.nvim_win_set_buf(0, buffer)
end

function M.add_class()
    add_new("class")
end

function M.add_interface()
    add_new("interface")
end

function M.add_enum()
    add_new("enum")
end

return M
