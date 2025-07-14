" Prevent load multiple times
if exists('g:loaded_themester')
  finish
endif

command! Themester lua require('themester').themester()

let g:loaded_themester = 1

