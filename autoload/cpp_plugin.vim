" a helper function to get the name of the class to put 
" before the function name (ClassName::)

function! s:GetClassName () abort
  " if the function is a part of a class, then 
  " the name of the class should be before the function declaration 
  let currentLine = line('.') " Get the current line number
  let linesBefore = join(getline(1, currentLine - 1), '\n')
  let pos = stridx('class', linesBefore) 

  if pos == -1
    return '' " not a part of a class 
  endif

  " Regex match
  " let regex = 'class.*\{.*' . currentLine . '.*\}.*'
  " let regex = 'class.*' . currentLine . '.*'
  let regex = '.*class.*{.*' . currentLine . '.*}.*'

  let classNamePos = match(linesBefore, regex) " get the index of the regex match

  " If the function is inside a class declaration 
  if classNamePos != -1
    let pattern = 'class \(\w\+\)' " Use a regex to extract the class name 
    let cutStr = strpart(linesBefore, classNamePos - 1, len(linesBefore) - classNamePos + 1)

    let className = substitute(cutStr, pattern, '\1', '') " get the word after the class name 

    let res = className

    let typenamePos = match(cutStr, '.*template.*')

    if typenamePos != -1
      " if the class is a template class
      let typeName = substitute(cutStr, 'typename', '', '') " remove all occurances of 'typename'
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
  echomsg "Hello"
  let currentLine = getline('.') " get the current line 
  let currentFile = expand('%:t') " get the last component of the filename only 
  let cppFileRegex = '.*\.cpp' " match .cpp files 
  
  let modifiedLine = substitute(currentLine, ';', ' {', '')  " add brackets and indentation

  let toAdd = s:GetClassName()  
  let modifiedLine = substitute(modifiedLine, '\(\w\+\)', '\0 ' . toAdd, '') " add ClassName::
  
  if currentFile =~ cppFileRegex
    " if the current file is a cpp file, create a function definition 
    " at the end of the file 

    let endLine = line('$') " get the line number of the last line in the file 
  
    let lines = ['', modifiedLine, '', '}']
    call writefile(lines, expand('%:t'), 'a')

  else
    " find the respective .cpp file and add a function definition to it 
    let cppFile = substitute(currentFile, '.h', '.cpp', '')
    let parentDir = expand('%:h:h') 
    let fileToEdit = findfile(cppFile, parentDir)

    if fileToEdit == '' 
      return 
    endif 

    " append to the respective cpp file if it exists 
    let lines = ['', modifiedLine, '', '}']
    call writefile(lines, fileToEdit, 'a')
    execute 'vsplit ' . fileToEdit 

  endif

  silent! edit! " Disable warning and refresh file 

endfunction
