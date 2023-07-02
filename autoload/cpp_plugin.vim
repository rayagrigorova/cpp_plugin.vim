
function! cpp_plugin#CreateFunctionDefinition()
  " get the current line 
  let currentLine = getline('.')
  echomsg currentLine 

  " get the last component of the filename only 
  let currentFile = expand('%:t')
  echomsg currentFile 

  " match .cpp files 
  let cppFileRegex = '.*\.cpp'
  echomsg cppFileRegex 
  
  " add brackets and indentation
  let modifiedLine = substitute(currentLine, ';', ' {', '') 
  echomsg modifiedLine 
  

  if currentFile =~ cppFileRegex
    " if the current file is a cpp file, create a function definition 
    " at the end of the file 

    let endLine = line('$') " get the line number of the last line in the file 
  echomsg endLine 
    " call append(endLine, modifiedLine)
    let lines = ['', modifiedLine, '', '}']
    call writefile(lines, expand('%:t'), 'a')

  else
    " find the respective .cpp file and add a function definition to it 
    let cppFile = substitute(currentFile, '.h', '.cpp', '')
  echomsg cppFile 
    let parentDir = expand('%:h:h') 
  echomsg parentDir 

    let fileToEdit = findfile(cppFile, parentDir)
  echomsg fileToEdit 

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
