local M = {}

local function get_current_scenario()
    local bufnr = vim.api.nvim_get_current_buf()
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))  -- Get current line/column
    local filename = vim.uri_from_bufnr(bufnr)
    local relativeFilename = vim.fn.expand("%:.")

    local params = {
        textDocument = { uri = filename }
    }

    -- Request symbols from the LSP
    local result = vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", params, 1000)

    if result and result[1] then
        local scenarios = nil
        local scenario_line = 0
        local symbols = result[1].result
        if symbols[1] and symbols[1].children then
            scenarios = symbols[1].children
        end
        if scenarios then
            local str = vim.json.encode(symbols[1].children)
            pcall(vim.fn.writefile({str}, "/tmp/info"))
            for _, scenario in ipairs(scenarios) do
                -- TODO: does the cucumber lanague server plugin export any consts so we don't have a magic number 
                -- for checking the scenario.kind value? maybe check if the vim.lsp object can give it to us, or
                -- can we make use of Treesitter?
                if scenario.kind == 24 and scenario.range.start.line < row and scenario.range.start.line > scenario_line then
                    scenario_line = scenario.range.start.line + 1
                end
            end
            if scenario_line ~= 0 then
                return { relative_file = relativeFilename, line = scenario_line }
            end
        end
    end
    return nil
end

local function start_debugger(file, line)
    local dap = require("dap")
    dap.run({
        type = "ruby",
        options = { source_filetype = "ruby" },
        error_on_failure = false,
        localfs = true,
        waiting = 1000,
        random_port = true,
        name = "Cucumber Scenario",
        request = "attach",
        command = "bundle",
        args = {"exec", "rdbg", "-c", "cucumber", file .. ":" .. line}

    })
    -- Wait until the sesion has initialized before we return
    -- Implementation loosely based on the spec test helpers.lua in nvim-dap repo
    --
    -- This works because launching directly with 'rdbg -c', it will immediately break
    -- on entrypoint, usually on the first 'require' line in the cucumber main executable
    -- script.  This allows dap to set any breakpoints that were defined in the local
    -- buffers before any code executes.
    local initialized = vim.wait(10000, function()
        local session = dap.session()
        if session == nil or session.initialized == false then
            return false
        end

        -- Once we have a session, we need to wait for dap to recognise the debuggee
        -- is stopped before we send a continue() call
        if session.stopped_thread_id == nil then
            return false
        end

        return true
    end, 100)

    if initialized then
        dap.continue()
    else
        vim.api.nvim_err_writeln("Timeout waiting for debugging to start")
    end
end

M.debug_current_scenario = function()
    local scenario = get_current_scenario()
    if scenario ~= nil then
        start_debugger(scenario.relative_file, scenario.line)
        return
    end
    vim.api.nvim_err_writeln("Failed to find scenario to run")
end

--[[
-- TODO: Find a nice solution for running 'bundle exec cucumber relativeFile:line`
-- and have the output piped async in to a floating or split terminal pane
--]]

-- M.run_current_secnario = function()
--     local scenario = get_current_scenario()
--     if scenario ~= nil then
--         vim.api.nvim_cmd
--     end
-- end

-- Creating a command in this way allows us to set the keybinding in an ftplugin file which
-- can map a keybinding to `:CucumberDebugCurrentScenario`, instead of inoking directly
-- by mapping to something like `:lua require("cucumber").debug_current_scenario()`
-- This is just a nicety to make the output of the whichkey nvim plugin be a little more 
-- friendly to read.
vim.api.nvim_create_user_command('CucumberDebugCurrentScenario', M.debug_current_scenario, {})

return M

