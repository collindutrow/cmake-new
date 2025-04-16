# CMake-New

`cmake-new` is a minimal **CMake** project generator.

**Usage**

```plaintext
Usage: cmake-new <project> [options]
    -l, --lang LANG                  Language (e.g., C, CXX, C++, C++20 (default))
    -g, --generator GENERATOR        CMake generator (e.g., Ninja (default), Unix Makefiles)
    -t, --type TYPE                  Project type: exe (default) or lib
        --vscode                     Generate VSCode tasks.json
        --git                        Initialize a git repository (requires git)
```


**Creating a new project**
```shell
cmake-new new-project
```
**Output example**

```plaintext
Project 'new-project' created with language C++20, generator Ninja, and type exe.

Configure, build, and run instructions:

cd new-project
cmake --preset debug
cmake --build --preset debug
./build/debug/new-project

Note: See more `CMakeLists.txt` commands and their definitions at
https://cmake.org/cmake/help/book/mastering-cmake/chapter/Writing%20CMakeLists%20Files.html
```

**Newly created project tree**

```plaintext
new-project
├── CMakeLists.txt
├── CMakePresets.json
├── README.md
└── src
    └── main.cpp
```

**Configuration File**

An optional configuration file can be created in:
```shell
$HOME/.config/cmake-new.json
```

or on Windows:
```batch
%APPDATA%\CMake-New\cmake-new.json
```

Example configuration
```json
{
    "vscode": true,
    "git": true
}
```

Explanation of options

* `vscode` — boolean value. `true` enables generation of the VSCode `launch.json` and `tasks.json`. Defaults to false.
* `git` — boolean value. `true` enables Git repository initialization. Defaults to false.
* `git_branch` — string. If `git` is enabled and `git_branch` is set, initializes the Git repository with the specified branch name.
* `lang` — string. Specifies the language standard for the project (e.g., `C`, `CXX`, `C++`, `C++20`). Defaults to `C++20` if not specified.
* `generator` — string. Sets the CMake generator (e.g., `Ninja`, `Unix Makefiles`). Defaults to `Ninja`.
* `type` — string. Defines the project type, either `exe` for executables or `lib` for libraries. Defaults to `exe`.
