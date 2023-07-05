" Ако сме в compatible mode или plugin-ът е зареден, finish 
if exists('g:loaded_cpp_plugin') || &cp
	finish
endif
let g:loaded_cpp_plugin = '0.0.1' 
let s:keepcpo = &cpo
set cpo&vim

nnoremap <Leader>cad :call cpp_plugin#CreateFunctionDefinition()<CR>

" pairs of trigger words and code snippets
let g:cppsnippets = {
  \ 'forl': "for (int i = 0; i < n; i++) {\n\n}",
  \ 'myStrlen': "size_t myStrlen(const char* str)\n{\nif (str == nullptr)\nreturn 0;\n\nsize_t count = 0;\nwhile (*str != '\\0')\n{\ncount++;\nstr++;\n}\nreturn count;\n}",
  \ 'myStrcmp': "int myStrcmp(const char* first, const char* second)\n{\nif (first == nullptr || second == nullptr)\nreturn 0; //error\n\nwhile (*first != '\\0' && *second != '\\0')\n{\nif (*first < *second)\nreturn -1;\nif (*first > *second)\nreturn 1;\nfirst++;\nsecond++;\n}\n\nif (*first == '\\0' && *second == '\\0')\nreturn 0;\n\nreturn *first == '\\0' ? -1 : 1;\n}",
  \ 'myStrCat': "void myStrCat(char* dest, const char* source)\n{\nsize_t destLen = myStrlen(dest);\ndest += destLen;\nmyStrCopy(source, dest);\n}",
  \ 'myStrCpy': "void myStrCpy(const char* source, char* dest)\n{\nif (source == nullptr || dest == nullptr)\nreturn;\n\nwhile (*source != '\\0')\n{\n*dest = *source;\ndest++;\nsource++;\n}\n*dest = '\\0';\n}",
  \ 'printArray': "for (int i = 0; i < size; i++) {\nstd::cout << arr[i] << \" \";\n}\nstd::cout << std::endl;",
  \ 'bubbleSort': "for (int i = 0; i < size - 1; i++) {\nbool isSwapped = false;\nfor (int j = 0; j < size - 1 - i; j++) {\nif (arr[j] > arr[j + 1]) {\nswap(arr[j], arr[j + 1]);\nisSwapped = true;\n}\n}\nif (!isSwapped)\nreturn;\n}",
  \ 'insertionSort': "void insert(int* arr, size_t size) // sorted, but without the last element\n{\nint el = arr[size - 1];\nint iter = size - 2;\n\nwhile (iter >= 0 && el < arr[iter]) {\narr[iter + 1] = arr[iter];\niter--;\n}\narr[iter + 1] = el;\n}\n\nvoid insertionSort(int* arr, size_t size)\n{\nfor (int i = 1; i < size; i++)\ninsert(arr, i + 1);\n}"
  \ }

command! Big6 :call cpp_plugin#DeclareBig6()<CR>

nnoremap <Leader>es :call cpp_plugin#ExpandSnippet()<CR>
inoremap <buffer> { {<C-O>:call cpp_plugin#AddBraceAndIndentation()<CR>
nnoremap <Leader>cbp :call cpp_plugin#ChangeBracketPos()<CR>

let &cpo = s:keepcpo 
unlet s:keepcpo
