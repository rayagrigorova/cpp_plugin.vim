" a helper function to get the name of the class to put 
" before the function name (ClassName::)

function! cpp_plugin#GetClassName () abort
  " if the function is a part of a class, then 
  " the name of the class should be before the function declaration 

  let currentLine = getline('.') " Get the current line 
  
  let regex = '\s*class\s\+\(\w\+\)\s*{\_.\+' . currentLine . '\_.\+}' " a regex to match a surrounding class
  
  " echomsg "Regex:" . regex
  let lines = getline(1, '$') " get all file lines

  let capturedPart = matchstr(join(lines, "\n"), regex)
  echomsg "Captured part:" . capturedPart

  if capturedPart != ""
    let className = substitute(capturedPart, regex, '\1', '' ) " get the class name
    echomsg "Class name" . className

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
  let cppFileRegex = '.*\.cpp' " match .cpp files 

  let modifiedLine = substitute(currentLine, ';', ' {', '')  " change the ';' symbol to '{'

  let toAdd = cpp_plugin#GetClassName() 

  " regex match a function that has a return type 
  let modifyPattern = '^\s*\(\w\+\)\s\+\(\w\+\)\s*'

  let matchPos = match(modifiedLine, modifyPattern) " Check if the function definition follows
  " the pattern <word><spaces><word>

  if matchPos != -1 " the function isn't a constructor or destructor 
    let modifiedLine = substitute(modifiedLine, modifyPattern, '\1 ' . toAdd . '\2', '')  " add ClassName::

  else 
    let modifiedLine = toAdd . modifiedLine 
  endif

  if currentFile =~ cppFileRegex
    " if the current file is a cpp file, create a function definition 
    " at the end of the file 

    let endLine = line('$') " get the line number of the last line in the file 

    let lines = [ modifiedLine, '', '}']
    call writefile(lines, expand('%:t'), 'a')

  else
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

  endif

  silent! edit! " Disable warning and refresh file 

endfunction
