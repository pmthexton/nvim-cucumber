-- Simple Lazyvim plugins, where little-to-no options are required
-- More complex plugin configurations have their own adjacent files
-- which Lazy will automatically import
return {
  -- Git related plugins
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  -- color scheme
  { "rose-pine/neovim", name = "rose-pine", opts = {} },

}
