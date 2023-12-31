
## Usage

This plugin includes functionality that I often needed in the
Introduction to Programming and Object Oriented Programming courses.

![demo](https://github.com/rayagrigorova/cpp_plugin.vim/assets/72023155/6423e8d5-df8d-42b0-8ee4-3bbb99968fca)

### Create a function definition

To create a function definition, position the cursor on the line containing the 
function declaration andd press `<Leader>cad`. Depending on the file extension,
the mapping will:

- Create a function definition at the end of the file (for .cpp and .hpp files)
- Search for a file with the same name and the extension .cpp. If it exists, it will be 
opened in split (if not already opened), and the function definition will be added to its end. 
If a .cpp file with the same name as the current file doesn't exist, nothing happens (for .h files)

### Create a Big 6

The Big 6 includes the following functions:

- Default constructor: X()
- Copy constructor: X(const X& other)
- Operator=(const X& other)
- Move copy constructor: X(X&& other)
- Move operator=(X&& other)
- Destructor: ~X()

The Rule of 6 states that if one of the above functions is implemented, the others should be implemented,
deleted or explicitly defaulted.

After declaring a class, position the cursor on the line where the class is declared and enter the 
command `:Big6`. Function declarations for all functions in the Big 6 will be added to the class body.
                                         
### Snippets

Trigger words can be expanded from normal mode using the mapping `<Leader>es`. 
To add a code snippet, enter a keyword, exit to normal mode and press `<Leader>es`.
The cursor should be positioned on the trigger word for the expansion to work. 
If the snippet doesn't exist, an error message 'Snippet not found.' will be displayed.

##### List of trigger words:

- forl (adds a for loop from 0 to n)
- myStrlen
- myStrcmp
- myStrCat
- myStrCpy
- printArr
- iterateArr
- bubbleSort
- insertionSort

### Automatic addition of closing brackets and indentation 

Closing brackets and indentation are automatically added when `<Enter>` is pressed.
                                                  
### Change bracket position

The bracket position refers to the position of the opening bracket '{' relative 
to the function definition. 

```cpp
    void foo () { // Option 1

    }

    void bar ()
    { // Option 2

    }
```


You can toggle between the two options using the mapping `<Leader>bp`.

## Installation                                  

For the installation of this plugin, it is recommended
to use one of the following plugin managers: 

- vim-plug: [https://github.com/junegunn/vim-plug](https://github.com/junegunn/vim-plug)
- Vundle:   [https://github.com/VundleVim/Vundle.vim](https://github.com/VundleVim/Vundle.vim)

You can install the plugin yourself using Vim's |packages| functionality by
cloning the project (or adding it as a submodule) under
`~/.vim/pack/<any-name>/start/`. For example:
```bash
    mkdir -p ~/.vim/pack/cpp_plugin/start
    cd ~/.vim/pack/cpp_plugin/start
    git clone https://github.com/rayagrigorova/cpp_plugin.vim.git

    # to generate documentation tags:
    vim -u NONE -c "helptags cpp_plugin.vim/doc" -c q
```
This should automatically load the plugin for you on Vim start. Alternatively,
you can add it to `~/.vim/pack/<any-name>/opt/` instead and load it in your
.vimrc manually with:
```vim
    packadd cpp_plugin
```
