return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "suketa/nvim-dap-ruby",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio"
    },
    config = function()
      local function add_keymap_and_whichkey_documentation(mode, key, func, doc)
        vim.keymap.set(mode, key, func)
        require("which-key").add({key, desc = doc, mode = mode})
      end
      require("dap-ruby").setup()
      require("dapui").setup()

      local dap, dapui = require("dap"), require("dapui")

      dap.listeners.after.attach.dapui_config = function()
        dapui.open()
      end

      -- TODO: This isn't ideal, these keymaps are added globally for all open files, we don't really need to set these bindings
      -- up until we're actually debugging.
      add_keymap_and_whichkey_documentation('n', '<leader>dc', function() require('dap').continue() end, "Continue")
      add_keymap_and_whichkey_documentation('n', '<leader>dj', function() require('dap').step_over() end, "Step over")
      add_keymap_and_whichkey_documentation('n', '<leader>dl', function() require('dap').step_in() end, "Step Into")
      add_keymap_and_whichkey_documentation('n', '<leader>dh', function() require('dap').step_out() end, "Step Out")
      add_keymap_and_whichkey_documentation('n', '<leader>db', function() require('dap').toggle_breakpoint() end, "Toggle Breakpoint")
      add_keymap_and_whichkey_documentation('n', '<leader>dB', function() require('dap').set_breakpoint() end, "Set Breakpoint")
      add_keymap_and_whichkey_documentation('n', '<leader>dgo', function() require('dapui').open() end, "Open Debug UI")
      add_keymap_and_whichkey_documentation('n', '<leader>dgc', function() require('dapui').close() end, "Close Debug UI")

      dap.listeners.after.event_terminated.dapui_config = function()
        dapui.close()
      end
    end
  },
}
