# CMake-New

`cmake-new` is a minimal **CMake** project generator.

**Usage**

```plaintext
Usage: cmake-new <project> [options]
    -l, --lang LANG                  Language (e.g., C, CXX, C++, C++20 (default))
    -g, --generator GENERATOR        CMake generator (e.g., Ninja (default), Unix Makefiles)
    -t, --type TYPE                  Project type: exe (default) or lib
        --vscode                     Generate VSCode tasks.json
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
    "vscode_default": true
}
```

Explanation of options

* `vscode_default` — a boolean value, true enables the generation of the vscode tasks file by default without needing to specify `--vscode`.