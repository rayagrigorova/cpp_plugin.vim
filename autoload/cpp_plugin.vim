" a helper function used to extract the template<typename...> part of a class
" declaration
function! cpp_plugin#GetTypename () abort
  let currentLine = getline('.') " get the current line
  let regex = '\(template.\{-}\n\)\_.\+' . currentLine . '\_.\+}' " put the template <...> part in a capture group

  let lines = getline(1, '$') " get all file lines
  let match = matchstr(join(lines, "\n"), regex)

  echomsg "Match" . match

  let templateTypename = substitute(match, regex, '\1', '')
  return templateTypename 

endfunction

" a helper function to get the name of the class to put 
" before the function name (ClassName::)
function! cpp_plugin#GetClassName () abort
  let currentLine = getline('.') " Get the current line 

  " a regex to match the surrounding class for the current line 
  let regex = '\s*class\s\+\(\w\+\)\s*{\_.\+' . currentLine . '\_.\+}' 
  let lines = getline(1, '$') " get all file lines
  let capturedPart = matchstr(join(lines, "\n"), regex)

  if capturedPart != "" " if the current line is a part of a class declaration
    let className = substitute(capturedPart, regex, '\1', '' ) " get the class name
    let res = className

    let typenamePos = match(capturedPart, '.*template.*') " check if the class is a template class

    if typenamePos != -1
      " if the class is a template class
      let typeName = substitute(capturedPart, 'typename', '', '') " remove all occurances of 'typename'
      let angleBracketsRegex = '\(\<.*\>\)' 
      let capturedPart = substitute(typeName, angleBracketsRegex, '\1', '')

      res = res . capturedPart

    endif
    return res . '::'

  else 
    return ''

  endif 

endfunction

function! cpp_plugin#CreateFunctionDefinition() abort
  let currentLine = substitute(getline('.'), '^\s*', '', '') " get the current line and remove tabs
  let currentFile = expand('%:t') " get the last component of the filename only 

  let hFileRegex = '.*\.h$' " match .h files 
  let cppFileRegex = '.*\.cpp$' " match .cpp files 
  let hppFileRegex = '.*\.hpp$' " match .hpp files 

  let modifiedLine = substitute(currentLine, ';', ' {', '')  " change the ';' symbol to '{'

  let toAdd = cpp_plugin#GetClassName() 
  let templateTypename = cpp_plugin#GetTypename()

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
  execute 'edit!'

endfunction
