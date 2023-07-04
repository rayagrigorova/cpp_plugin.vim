" Ако сме в compatible mode или plugin-ът е зареден, finish 
if exists('g:loaded_cpp_plugin') || &cp
	finish
endif
let g:loaded_cpp_plugin = '0.0.1' 
let s:keepcpo = &cpo
set cpo&vim

" test commands
command HelloWorldCommand echo "Hello, World!" 
nnoremap <Leader>hw :HelloWorldCommand<CR>

nnoremap <Leader>cad :call cpp_plugin#CreateFunctionDefinition()<CR>

iabbrev for for (int i = 0; i < n; i++) {<CR>   <CR>}<C-O>k

let &cpo = s:keepcpo 
unlet s:keepcpo
