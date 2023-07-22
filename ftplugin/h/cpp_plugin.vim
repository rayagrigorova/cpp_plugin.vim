let s:keepcpo = &cpo
set cpo&vim

call cpp_plugin#InitUserInterface()

let &cpo = s:keepcpo
unlet s:keepcpo
