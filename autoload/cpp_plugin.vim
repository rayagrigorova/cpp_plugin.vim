" a helper function used to extract the template<typename...> part of a class
" declaration

function! cpp_plugin#GetTypename () abort
    let previousView = winsaveview()

    let templateLine = search('.*template.*\<.*\>.*', 'b') 

    if templateLine < 0
        return ''
    endif

    call winrestview(previousView)
    return getline(templateLine)

endfunction

" a helper function to get the name of the class to put 
" before the function name (ClassName::)
function! cpp_plugin#GetScopeSpecifier () abort
    let previousView = winsaveview()

    let currentLine = getline('.') " Get the current line 

    if stridx(currentLine, 'friend') >= 0 " friend functions shouldn't have a scope specifier
      return ''
    endif

    let lineNumber = line('.') " get the number of the  current line 

    let foundPos = search("class", 'b') " search for the word 'class' backwards (not moving the cursor)
    " and get the number of the line where the word 'class' was found
    let classLine = getline('.') " get the line itself

    if foundPos == 0 " no previous class definition found
        call winrestview(previousView)
        return ''
    endif

    let openingBracket = search('{', '') " search for the '{' symbol of the class declaration (search forward)
    " and save the line number where the '{' was found 
    " find the respective closing bracket
    normal! %

    if lineNumber >= openingBracket && lineNumber <= line('.') " if the current line is a part of a class declaration
        let className = substitute(classLine, '.*class\s\+\(\w\+\).*', '\1', '' ) " get the class name
        let res = className

        let searchRes = search('.*template.*\<.*\>.*', 'b')

        " if the search was succesful and the template ... part is one line
        " above the class declaration
        if searchRes > 0 && searchRes + 1 == foundPos
            " remove all occurances of 'typename', 'class' and 'template'
            let typename = substitute(getline('.'), ' \|template\|typename\|class', '', 'g')
            echomsg "after substitution: " . typename

            let res = res . substitute(typename, ',', ', ', 'g')

        endif
    endif

    call winrestview(previousView)
    return res . '::'

else 
    call winrestview(previousView)
    return ''

endif 
endfunction


function! cpp_plugin#RemoveFuntionModifiers (str) abort
    let functionModifiers = [
                \ 'virtual',
                \ 'override',
                \ 'const',
                \ 'constexpr',
                \ 'inline',
                \ 'static',
                \ 'explicit',
                \ 'friend',
                \ 'noexcept',
                \ 'mutable',
                \ 'final'
                \ ]
endfunction

function! cpp_plugin#CreateFunctionDefinition() abort
  let savedView = winsaveview()
  let currentLine = substitute(getline('.'), '^\s*', '', '') " get the current line and remove tabs

  " functions that are deleted or default shouldn't have a definition
  if stridx(currentLine, 'delete') >= 0 || stridx(currentLine, 'default') >= 0
    return
  endif

  let currentFile = expand('%:t') " get the last component of the filename only 

  let hFileRegex = '.*\.h$' " match .h files 
  let cppFileRegex = '.*\.cpp$' " match .cpp files 
  let hppFileRegex = '.*\.hpp$' " match .hpp files 

  let modifiedLine = substitute(currentLine, ';', ' {', '')  " change the ';' symbol to '{'

  let toAdd = cpp_plugin#GetScopeSpecifier() 

  echomsg "To add:" . toAdd 

  " the function is a part of a template class
  if stridx(toAdd, '>') >= 0
      let templateTypename = cpp_plugin#GetTypename()
  endif

  call 

  " regex match a function that has a return type - it should start with >= 0
  " spaces and contain 2 words seperated by spaces
  let funcWithReturnTypePattern = '^\s*\(\w\+\)\s\+\(\w\+\)\s*'
  let matchPos = match(modifiedLine, funcWithReturnTypePattern) " Check if the function definition follows
  " the pattern <word><spaces><word>

  if matchPos != -1 " the function has a return type (isn't a constructor or a destructor)
    " this line puts ClassName:: between the return type and the function name 
    let modifiedLine = substitute(modifiedLine, funcWithReturnTypePattern, '\1 ' . toAdd . '\2', '')  " add ClassName::

  else 
    let modifiedLine = toAdd . modifiedLine " if the function doesn't have a return type, simply add
    " ClassName:: before the name of the function
  endif

  " determine where to put the function definition

  " if the current file is a cpp file, create a function definition 
  " at the end of the file 
  if currentFile =~ cppFileRegex
    let endLine = line('$') " get the line number of the last line in the file 

    let lines = [ modifiedLine, '', '}']
    call writefile(lines, expand('%:t'), 'a')

  " if the current file is a header file 
  elseif currentFile =~ hFileRegex
    " find the respective .cpp file and add a function definition to it 
    let cppFile = substitute(currentFile, '.h', '.cpp', '')
    let parentDir = expand('%:h:h') 
    let fileToEdit = findfile(cppFile, parentDir)

    if fileToEdit == '' " the file doesn't exist
      return 
    endif 

    " append to the respective cpp file if it exists 
    let lines = ['', modifiedLine, '', '}']
    call writefile(lines, fileToEdit, 'a')
    execute 'vsplit ' . fileToEdit 

  elseif currentFile =~ hppFileRegex
    " The result is almost the same as with .cpp files, but the only
    " difference is that the row before the function should contain
    " 'template <typename T, typename S ....>

    let endLine = line('$') " get the line number of the last line in the file 

    let lines = [templateTypename, modifiedLine, '', '}']
    call writefile(lines, expand('%:t'), 'a')

  else 
    throw 'Invalid file extension'
  endif

  silent! edit! " Disable warning and refresh file 

 call winrestview(savedView)

endfunction


" This function is intended to work when the cursor is positioned on the line
" declaring the class
function! cpp_plugin#DeclareBig6() abort
  let savedCursor = getpos('.') " save the cursor position since it will be moved 

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

  " search for the next opening brace and then go one line down 
  normal! /{<CR>j
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

  call append(lineNumber, "}")
  let lineNumber += 1

  " format the code
  execute startLineNumber . ',' . lineNumber . 'normal! gg=G'

  call setpos('.', savedCursor) " set the cursor position back

endfunction

" a function that expands the word under the cursor to the respective code
" snippet
function! cpp_plugin#ExpandSnippet() abort 
    let snippet = get(g:cppsnippets, expand('<cword>'), 'Not found') " the default value returned is 'Not found'

    " delete the word used to trigger the snippet expansion
    normal! diW

    if snippet == 'Not found'
        echomsg "Snippet not found."
        return 
    else
        execute 'normal! i' . snippet  
    endif
endfunction

function! cpp_plugin#AddBraceAndIndentation() abort
  let savedCursor = getpos('.') " save the cursor position since it will be moved 
  let currentLineNumber = line('.') " get the number of the current line 

  let indentationLevel = indent(currentLineNumber) " get the indentation level of the current line (in spaces)
  let userShiftWidth = &shiftwidth 

  call append(line('.'), '}') " this line should appear last
  call append(line('.'), '') 

  " format the code
  silent! execute 'normal! gg=G'

  call setpos('.', savedCursor) " set the cursor position back

  " move to the line below 
  silent! execute 'normal! j' 

  call setline('.', repeat(' ', indentationLevel + userShiftWidth + 1)) " add necessary number of spaces

  " move right
  silent! execute 'normal! ' . (indentationLevel + userShiftWidth + 1) . 'l' 

endfunction


" void foo () { // Option 1
"
" }
"
" void bar ()
" { // Option 2
"
" }
function! cpp_plugin#ChangeBracketPos() abort
  " find the closest opening bracket and regex match the row 
  " if it contains '()', then the position is currently option 1
  " otherwise it is option 2

  let savedCursor = getpos('.') " save the cursor position since it will be moved 
  let currentLine = getline('.')

  let lineContainsBracket = currentLine =~ '.*{.*' 

  if !lineContainsBracket
    " Position the cursor on the row containing the respective opening bracket
    normal! ?{<CR>
    let regexOption1 = '.*().*'
  endif

" If the initial line contains an opening brace or the destination line contains an opening brace 
  if lineContainsBracket || regexOption1 =~ getline('.') 
    " delete the { symbol
    if lineContainsBracket
      normal! f{
    endif

    normal! x
    call append(line('.'), "{")
  else 
    normal! j0f{xkA {
  endif

  call setpos('.', savedCursor) " set the cursor position back
endfunction
