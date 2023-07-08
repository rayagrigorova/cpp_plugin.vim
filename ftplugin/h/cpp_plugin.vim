" Ако сме в compatible mode или plugin-ът е зареден, finish 
if exists('g:loaded_cpp_plugin') || &cp
	finish
endif
let g:loaded_cpp_plugin = '0.0.1' 
let s:keepcpo = &cpo
set cpo&vim

nnoremap <Leader>cad :call cpp_plugin#CreateFunctionDefinition()<CR>

command! Big6 :call cpp_plugin#DeclareBig6()<CR>

nnoremap <Leader>es :call cpp_plugin#ExpandSnippet()<CR>
inoremap <buffer> { {<C-O>:call cpp_plugin#AddBraceAndIndentation()<CR>
nnoremap <Leader>bp :call cpp_plugin#ChangeBracketPos()<CR>

let &cpo = s:keepcpo 
unlet s:keepcpo
