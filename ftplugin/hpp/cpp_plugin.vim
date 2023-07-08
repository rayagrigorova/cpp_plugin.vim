" Ако сме в compatible mode или plugin-ът е зареден, finish 
if exists('g:loaded_cpp_plugin') || &cp
	finish
endif
let g:loaded_cpp_plugin = '0.0.1' 
let s:keepcpo = &cpo
set cpo&vim

nnoremap <Leader>cad :silent! call cpp_plugin#CreateFunctionDefinition()<CR>

command! Big6 :silent! call cpp_plugin#DeclareBig6()<CR>

nnoremap <Leader>es :silent! call cpp_plugin#ExpandSnippet()<CR>
inoremap { {<C-O>:silent! call cpp_plugin#AddBraceAndIndentation()<CR>
nnoremap <Leader>bp :silent! call cpp_plugin#ChangeBracketPos()<CR>

let &cpo = s:keepcpo 
unlet s:keepcpo
