if exists('g:loaded_ansible_nvim')
  finish
endif
let g:loaded_ansible_nvim = 1

" Initialize the plugin with Lua
lua require('ansible').setup()
