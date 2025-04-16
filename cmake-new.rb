#!/usr/bin/env ruby

require 'fileutils'
require 'optparse'
require 'rbconfig'
require 'json'

options = {
  lang: "C++20",
  generator: "Ninja",
  type: "exe"
}

version = "0.1.1"

branch = nil

# Define the path to the configuration file based on OS
def config_path
  if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
    File.join(ENV['APPDATA'], 'cmake-new', 'cmake-new.json')
  else
    File.expand_path('~/.config/cmake-new.json')
  end
end

# Check if there is a configuration file.
config_file = config_path
if File.exist?(config_file)
  begin
    config = JSON.parse(File.read(config_file), symbolize_names: true)
    options[:vscode] = true if config[:vscode_tasks] == true
    options[:git] = config[:git] if config[:git] == true
    options[:lang] = config[:lang] if config[:lang]
    options[:generator] = config[:generator] if config[:generator]
    options[:type] = config[:type] if config[:type]
    branch = config[:branch] if config[:git_branch]
  rescue JSON::ParserError
    warn "Warning: Ignoring invalid JSON in #{config_file}"
  end
end

# Command-line options
ARGV << '-h' if ARGV.empty? # Show help if no arguments are provided

# Parse command-line options
OptionParser.new do |opts|
  opts.banner = "Usage: cmake-new <project> [options]"

  opts.on("-l", "--lang LANG", "Language (e.g., C, CXX, C++, C++20 (default))") do |lang|
    options[:lang] = lang
  end

  opts.on("-g", "--generator GENERATOR", "CMake generator (e.g., Ninja (default), Unix Makefiles)") do |gen|
    options[:generator] = gen
  end

  opts.on("-t", "--type TYPE", "Project type: exe (default) or lib") do |type|
    options[:type] = type.downcase
  end

  opts.on("--vscode", "Generate VSCode tasks.json") do
    options[:vscode] = true
  end

  opts.on("--git", "Initialize a git repository") do
    options[:git] = true
  end

  opts.on("--version", "Show version") do
    puts "cmake-new version #{version}"
    exit
  end

  opts.separator ""
  opts.separator "Learn more at the project homepage:"
  opts.separator "  https://github.com/collindutrow/cmake-new"
end.parse!

project = ARGV.shift
abort("Project name required") unless project
abort("Invalid project name") unless project =~ /\A[\w\-]+\z/

# Make sure the project directory doesn't already exist
if File.exist?(project)
  abort("Target directory '#{project}' already exists.")
end

# Create the project directory
FileUtils.mkdir_p(project)

user_lang = options[:lang].downcase
lang = case user_lang
       when "c", "c89", "c99", "c11" then "C"
       when /c\+\+|cxx/ then "CXX"
       else
         abort("Unsupported language: #{options[:lang]}")
       end

ext = lang == "C" ? "c" : "cpp"

std = case user_lang
      when "c++20", "cxx20" then "20"
      when "c++17", "cxx17" then "17"
      when "c++14", "cxx14", "c++", "cxx" then "14"
      else nil
      end

# Create a source file
main_code = case options[:type]
when "exe"
  case lang
  when "C"
    <<~C
      #include <stdio.h>

      int main(void) {
          printf("Hello from #{project}\\n");
          return 0;
      }
    C
  when "CXX"
    <<~CPP
      #include <iostream>

      int main() {
          std::cout << "Hello from #{project}" << std::endl;
          return 0;
      }
    CPP
  end
when "lib"
  case lang
  when "C"
    <<~C
      #include <stdio.h>

      void #{project}_hello(void) {
          printf("Hello from #{project} (lib)\\n");
      }
    C
  when "CXX"
    <<~CPP
      #include <iostream>

      void #{project}_hello() {
          std::cout << "Hello from #{project} (lib)" << std::endl;
      }
    CPP
  end
else
  abort("Unknown project type: #{options[:type]}")
end

# Create the source directory
src_dir = "#{project}/src"
FileUtils.mkdir_p(src_dir)

File.write("#{project}/src/main.#{ext}", main_code)

# Create a CMakeLists.txt file
cmake = <<~CMAKE
  cmake_minimum_required(VERSION 3.15)
  project(#{project} LANGUAGES #{lang})

  # Source files
  file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS src/*.#{ext})
  add_#{options[:type] == "lib" ? "library" : "executable"}(#{project} \${SOURCES})

  # Include directory
  target_include_directories(#{project}
    PUBLIC
      \${PROJECT_SOURCE_DIR}/include
  )

  # Automatically add all subdirs in external/ with a CMakeLists.txt
  file(GLOB children RELATIVE "${PROJECT_SOURCE_DIR}/external" "${PROJECT_SOURCE_DIR}/external/*")
  foreach(child ${children})
    if(EXISTS "${PROJECT_SOURCE_DIR}/external/${child}/CMakeLists.txt")
      add_subdirectory(external/${child})
    endif()
  endforeach()
CMAKE

cmake << "set_property(TARGET #{project} PROPERTY CXX_STANDARD #{std})\n" if lang == "CXX" && std
File.write("#{project}/CMakeLists.txt", cmake)

presets = {
  "version" => 3,
  "cmakeMinimumRequired" => { "major" => 3, "minor" => 15, "patch" => 0 },
  "configurePresets" => [
    {
      "name" => "debug",
      "displayName" => "Debug",
      "description" => "Use Debug configuration",
      "generator" => options[:generator],
      "binaryDir" => "${sourceDir}/build/debug",
      "cacheVariables" => {
        "CMAKE_BUILD_TYPE" => "Debug"
      }
    },
    {
      "name" => "release",
      "displayName" => "Release",
      "description" => "Use Release configuration",
      "generator" => options[:generator],
      "binaryDir" => "${sourceDir}/build/release",
      "cacheVariables" => {
        "CMAKE_BUILD_TYPE" => "Release"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "debug",
      "configurePreset": "debug"
    },
    {
      "name": "release",
      "configurePreset": "release"
    }
  ]
}

File.write("#{project}/CMakePresets.json", JSON.pretty_generate(presets))

# Create a .vscode directory and tasks.json
if options[:vscode]
  vscode_dir = "#{project}/.vscode"
  FileUtils.mkdir_p(vscode_dir)
  exe_name = project

  tasks = {
    "version" => "2.0.0",
    "tasks" => [
      {
        "label" => "Configure (Debug)",
        "type" => "shell",
        "command" => "cmake --preset debug",
        "hide" => true
      },
      {
        "label" => "Build (Debug)",
        "type" => "shell",
        "command" => "cmake --build --preset debug",
        "dependsOn" => ["Configure (Debug)"],
        "dependsOrder" => "sequence",
        "hide" => false
      },
      {
        "label" => "Run (Debug)",
        "type" => "shell",
        "command" => "./build/debug/#{exe_name}",
        "dependsOn" => ["Build (Debug)"],
        "dependsOrder" => "sequence"
      },
      {
        "label" => "Configure (Release)",
        "type" => "shell",
        "command" => "cmake --preset release",
        "hide" => true
      },
      {
        "label" => "Build (Release)",
        "type" => "shell",
        "command" => "cmake --build --preset release",
        "dependsOn" => ["Configure (Release)"],
        "dependsOrder" => "sequence",
        "hide" => false
      },
      {
        "label" => "Run (Release)",
        "type" => "shell",
        "command" => "./build/release/#{exe_name}",
        "dependsOn" => ["Build (Release)"],
        "dependsOrder" => "sequence"
      }
    ]
  }

  File.write("#{vscode_dir}/tasks.json", JSON.pretty_generate(tasks))
end

# Create a README file
readme = <<~README
  # #{project}

  ## Build Instructions
  To build the project, run the following commands:
  ```shell
  cmake --preset debug
  cmake --build --preset debug
  ```

  ## Run Instructions
  To run the project, use the following command:
  ```shell
  ./build/debug/#{project}
  ```
README

File.write("#{project}/README.md", readme)

# Create a .gitignore file
gitignore = <<~GITIGNORE
  # CMake build files
  .vscode/
  build/
  CMakeCache.txt
  CMakeFiles/
GITIGNORE

# Initialize a git repository and create a .gitignore file if requested
if options[:git]
  File.write("#{project}/.gitignore", gitignore)
  # Initialize git repository
  if branch
    system("git init #{project} --initial-branch=#{branch} --quiet")
  else
    system("git init #{project} --quiet")
    system("git -C #{project} add .")
  end
end

# Print success message
puts "CMake project '#{project}' created successfully.
Language: #{options[:lang]}
Generator: #{options[:generator]}
Type: #{options[:type]}
VSCode tasks generated: #{options[:vscode] ? 'Yes' : 'No'}
Git repository initialized: #{options[:git] ? 'Yes' : 'No'}
Project '#{project}' created with language #{options[:lang]}, generator #{options[:generator]}, and type #{options[:type]}.

Configure, build, and run instructions:

cd #{project}
cmake --preset debug
cmake --build --preset debug
./build/debug/#{project}

Note: See more `CMakeLists.txt` commands and their definitions at 
https://cmake.org/cmake/help/book/mastering-cmake/chapter/Writing%20CMakeLists%20Files.html"

