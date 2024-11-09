local M = {}

local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '}'
    else
        return tostring(o)
    end
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
                if scenario.kind == 24 and scenario.range.start.line < row and scenario.range.start.line > scenario_line then
                    scenario_line = scenario.range.start.line + 1
                end
            end
            if scenario_line ~= 0 then
                start_debugger(relativeFilename, scenario_line)
                return
            end
        end
    end

    vim.api.nvim_err_writeln("Failed to find scenario to run")
end

return M

