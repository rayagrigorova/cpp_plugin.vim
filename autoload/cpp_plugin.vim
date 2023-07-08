
" pairs of trigger words and code snippets
let s:cppsnippets = {
  \ 'forl': "for (int i = 0; i < n; i++) {\n\n}",
  \ 'myStrlen': "size_t myStrlen(const char* str)\n{\nif (str == nullptr)\nreturn 0;\n\nsize_t count = 0;\nwhile (*str != '\\0')\n{\ncount++;\nstr++;\n}\nreturn count;\n}",
  \ 'myStrcmp': "int myStrcmp(const char* first, const char* second)\n{\nif (first == nullptr || second == nullptr)\nreturn 0;\n\nwhile (*first != '\\0' && *second != '\\0')\n{\nif (*first < *second)\nreturn -1;\nif (*first > *second)\nreturn 1;\nfirst++;\nsecond++;\n}\n\nif (*first == '\\0' && *second == '\\0')\nreturn 0;\n\nreturn *first == '\\0' ? -1 : 1;\n}",
  \ 'myStrCat': "void myStrCat(char* dest, const char* source)\n{\nsize_t destLen = myStrlen(dest);\ndest += destLen;\nmyStrCopy(source, dest);\n}",
  \ 'myStrCpy': "void myStrCpy(const char* source, char* dest)\n{\nif (source == nullptr || dest == nullptr)\nreturn;\n\nwhile (*source != '\\0')\n{\n*dest = *source;\ndest++;\nsource++;\n}\n*dest = '\\0';\n}",
  \ 'printArr': "for (int i = 0; i < size; i++) {\nstd::cout << arr[i] << \" \";\n}\nstd::cout << std::endl;",
  \ 'iterateArr': "for (int i = 0; i < size; i++) {\n\n}",
  \ 'bubbleSort': "for (int i = 0; i < size - 1; i++) {\nbool isSwapped = false;\nfor (int j = 0; j < size - 1 - i; j++) {\nif (arr[j] > arr[j + 1]) {\nswap(arr[j], arr[j + 1]);\nisSwapped = true;\n}\n}\nif (!isSwapped)\nreturn;\n}",
  \ 'insertionSort': "void insert(int* arr, size_t size)\n{\nint el = arr[size - 1];\nint iter = size - 2;\n\nwhile (iter >= 0 && el < arr[iter]) {\narr[iter + 1] = arr[iter];\niter--;\n}\narr[iter + 1] = el;\n}\n\nvoid insertionSort(int* arr, size_t size)\n{\nfor (int i = 1; i < size; i++)\ninsert(arr, i + 1);\n}"
  \ }


" a helper function used to extract the template <typename...> part of a class
" declaration

" this function doesn't perform a check if a line of code is a part of a class
" this is handled in the GetClassName() function 
function! s:GetTypename () abort
    " let previousView = winsaveview()

    " search for a line that contains the pattern 'template ... <...>
    let templateLine = search('.*template.*<.*>.*', 'bn') 

    if templateLine < 0
        return ''
    endif

    " call winrestview(previousView)
    return getline(templateLine)

endfunction

" a helper function to get the scope name specifier
function! s:GetScopeSpecifier () abort
    let previousView = winsaveview()
    let currentLine = getline('.') " Get the current line 

    if match(currentLine, '\<friend\>') >= 0 " friend functions shouldn't have a scope specifier
        return ''
    endif

    let lineNumber = line('.') " get the number of the  current line 

    " search for the word 'class' backwards and get the number of the line where the word 'class' was found
    let classFoundPos = search("class", 'b')

    if classFoundPos == 0 " no previous class definition found
        call winrestview(previousView)
        return ''
    endif

    let classLine = getline('.') " get the line itself

    " search for the '{' symbol of the class declaration (search forward) and save the line number 
    let openingBracket = search('{', '') 

    " find the respective closing bracket
    normal! %

    if lineNumber >= openingBracket && lineNumber <= line('.') " if the current line is a part of a class declaration
        let className = substitute(classLine, '.*class\s\+\(\k\+\).*', '\1', '' ) " get the class name
        let res = className

        let searchRes = search('.*template.*<.*>.*', 'b')

        " if the search was succesful and the template <...> part is above the class declaration
        if searchRes > 0 && searchRes <= classFoundPos
            " remove all occurances of 'typename', 'class' and 'template'
            let typename = substitute(getline('.'), ' \|template\|typename\|class', '', 'g')
            let res = res . substitute(typename, ',', ', ', 'g') " concat with result string
        endif

    else 
        call winrestview(previousView)
        return ''
    endif

    call winrestview(previousView)
    return res . '::'

endfunction

function! s:RemoveFuntionModifiers (str) abort
    let functionModifiers = [
                \ 'virtual',
                \ 'override',
                \ 'constexpr',
                \ 'inline',
                \ 'static',
                \ 'explicit',
                \ 'friend',
                \ 'final'
                \ ]

    let modifiedStr = a:str

    for modifier in functionModifiers
        let modifiedStr = substitute(modifiedStr, modifier, '', '')
    endfor

    let modifiedStr = substitute(modifiedStr, ' \{2,}', ' ', 'g') " replace groups of >= 2 spaces with a single one 
    let modifiedStr = substitute(modifiedStr, '^\s*', '', '') " remove leading whitespaces 

    return modifiedStr

endfunction

function! cpp_plugin#CreateFunctionDefinition() abort
    let savedView = winsaveview()
    let currentLine = substitute(getline('.'), '^\s*', '', '') " get the current line and remove tabs

    " functions that are deleted, default or pure virtual shouldn't have a definition
    if match(currentLine, '\<delete\>') >= 0 || match(currentLine, '\<default\>') >= 0
                \ || currentLine =~ '.*=\s*0\s*;\s*$'
        return
    endif

    let currentFile = expand('%:p') 

    let hFileRegex = '.*\.h$' " match .h files 
    let cppFileRegex = '.*\.cpp$' " match .cpp files 
    let hppFileRegex = '.*\.hpp$' " match .hpp files 

    let modifiedLine = substitute(currentLine, ';', ' {', '')  " change the ';' symbol to '{'

    let toAdd = s:GetScopeSpecifier() 

    " the function is a part of a template class
    if stridx(toAdd, '>') >= 0
        let templateTypename = s:GetTypename()
    endif

    let modifiedLine = s:RemoveFuntionModifiers(modifiedLine)

    let functionNamePos = match(modifiedLine, '\(\~\?\k\+\|operator.\{1,2}\)\s*(.*)') 
    let modifiedLine = strpart(modifiedLine, 0, functionNamePos) . toAdd . strpart(modifiedLine, functionNamePos)

    " determine where to put the function definition

    " let currentBufferNumber = 0 " The number of the buffer will be used to position the cursor at its end 
    " if the current file is a cpp file, create a function definition 
    " at the end of the file 
    if currentFile =~ cppFileRegex
        let endLine = line('$') " get the line number of the last line in the file 
        let lines = ['', modifiedLine, '', '}']
        call writefile(lines, currentFile, 'a')

        " if the current file is a header file 
        " find the respective .cpp file and add a function definition to it 
    elseif currentFile =~ hFileRegex
        let cppFile = fnamemodify(substitute(currentFile, '.h', '.cpp', ''), ':t')
        let lines = ['', modifiedLine, '', '}']

        let parentDir = expand('%:p:h:h') 
        let fileToEdit = globpath(parentDir, '**\' . cppFile)

        if !bufloaded(fileToEdit)

            if fileToEdit == '' " the file doesn't exist
                return 
            endif 

            " append to the respective cpp file if it exists 
            call writefile(lines, fileToEdit, 'a')
            execute 'split ' . fileToEdit 

        else 
            if bufwinnr(fileToEdit) == -1 " If there are no open windows for the buffer
                execute 'split ' . fileToEdit
            endif

            silent! call appendbufline(bufnr(fileToEdit), '$', lines) " append to buffer 
        endif

    elseif currentFile =~ hppFileRegex
        let filename = expand('%:t')
        " The result is almost the same as with .cpp files, but the only
        " difference is that the row before the function should contain
        " 'template <typename T, typename S ....>

        let endLine = line('$') " get the line number of the last line in the file 

        let lines = ['', templateTypename, modifiedLine, '', '}']
        call writefile(lines, filename, 'a')

    else 
        throw 'Invalid file extension'
    endif

    silent! edit! " Disable warning and refresh file 
    call winrestview(savedView)

endfunction


" This function is intended to work when the cursor is positioned on the line
" declaring the class
function! cpp_plugin#DeclareBig6() abort
    let savedView = winsaveview() " save the cursor position since it will be moved 

    " a list of all functions to be added
    " T is used as a placeholder and will be replaced with the class name 

    let functionList = [
                \ "void free();", 
                \ "void copyFrom(const T& other);", 
                \ "void moveFrom(T&& other);", 
                \ "T();", 
                \ "T(const T& other);", 
                \ "T& operator=(const T& other);", 
                \ "~T();", 
                \ "T(T&& other) noexcept;", 
                \ "T& operator=(T&& other) noexcept;" 
                \ ]

    let currentLine = getline('.') " get the current line
    let startLineNumber = line('.') " save the number of the first line so that the code can be formatted later 

    let classNameRegex = 'class\s\+\(\w\+\).*' " capture the class name 
    let className = substitute(currentLine, classNameRegex, '\1', '') " get the class name from the current line

    let modifiedFunctionList = map(copy(functionList), {_, v -> substitute(v, 'T', className, 'g')}) 
    " The '_' variable is unused and is only added for consistency - map() expects a lambda function with 2 arguments 
    "		If {expr2} is a |Funcref| it is called with two arguments:
    "			1. The key or the index of the current item.
    "			2. the value of the current item.

    " Go to the next opening brace and then go one line down 
    normal! f{j
    let lineNumber = line('.') " get the line number 

    for i in range (0, 2) " add the first 3 functions 
        call append(lineNumber, modifiedFunctionList[i])
        let lineNumber += 1
    endfor

    call append (lineNumber, "") " add an empty line 
    let lineNumber += 1
    call append (lineNumber, "public:") " add 'public' modifier before the next functions
    let lineNumber += 1

    for i in range (3, len(modifiedFunctionList) - 1) " add the next functions 
        call append(lineNumber, modifiedFunctionList[i])
        let lineNumber += 1
    endfor

    " format the code
    normal! gg=G
    call winrestview(savedView)

endfunction

" a function that expands the word under the cursor to the respective code
" snippet
function! cpp_plugin#ExpandSnippet() abort 
    let snippet = get(s:cppsnippets, expand('<cword>'), 'Not found') " the default value returned is 'Not found'

    if snippet == 'Not found'
      echomsg "Snippet not found."
      return 
    endif

    " delete the word used to trigger the snippet expansion
    normal! diW

    execute 'normal! i' . snippet  
endfunction

function! cpp_plugin#AddBraceAndIndentation() abort
    let savedView = winsaveview()
    let savedCursor = getpos('.')
    let currentLineNumber = line('.') " get the number of the current line 

    let indentationLevel = indent(currentLineNumber) " get the indentation level of the current line (in spaces)
    let userShiftWidth = &shiftwidth 

    call append(line('.'), '}') " this line should appear last
    call append(line('.'), '') 

    " format the code
    execute 'normal! gg=G'

    call setpos('.', savedCursor) " set the cursor position back

    " move to the line below 
    execute 'normal! j' 

    call setline('.', repeat(' ', indentationLevel + userShiftWidth )) " add necessary number of spaces

    call winrestview(savedView)
    execute 'normal! j' 

endfunction

" void foo () { // option 1
"
" }
"
" void bar ()
" { // option 2
"
" }

function! cpp_plugin#ChangeBracketPos() abort
    " find the closest opening bracket and regex match the row 
    " if it contains '{', then the position is currently option 1
    " otherwise it is option 2
    let savedView = winsaveview()
    let savedCursor = getpos('.') " save the cursor position since it will be moved 
    let currentLine = getline('.')

    let funcLine = search('.*(.*).*', 'cb') " search for the line that contains the function name 

    let lineContainsBracket = getline(funcLine) =~ '.*{.*' 

    if !lineContainsBracket 
        " Option 2: void foo ()
        " {
        " ...
        " }

        " position the cursor on the row containing the respective opening bracket
        execute "normal! /{\<CR>"

        " delete the row containing the bracket
        normal! dd

        call cursor(funcLine, 1) " position the cursor on the function line on column 1

        execute "silent! s/\\s\\{2,}/ /g" 
        normal! f)A{ 

    else " Option 1: void foo () {

        " delete the { symbol
        normal! f{x
        call append(line('.'), "{")
    endif

    normal! ggVG=
    call winrestview(savedView)

endfunction
