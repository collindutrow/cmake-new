# CMake-New

`cmake-new` is a minimal **CMake** project generator.

**Usage**

```
Usage: cmake-new <project> [options]
    -l, --lang LANG                  Language (e.g., C, CXX, C++, C++20 (default))
    -g, --generator GENERATOR        CMake generator (e.g., Ninja (default), Unix Makefiles)
    -t, --type TYPE                  Project type: exe (default) or lib
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