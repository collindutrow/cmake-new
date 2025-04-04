#!/usr/bin/env ruby

require 'fileutils'
require 'optparse'
require 'json'

options = {
  lang: "C++20",
  generator: "Ninja",
  type: "exe"
}

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
end.parse!

project = ARGV.shift
abort("Project name required") unless project
abort("Invalid project name") unless project =~ /\A[\w\-]+\z/

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

FileUtils.mkdir_p("#{project}/src")

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

File.write("#{project}/src/main.#{ext}", main_code)

cmake = <<~CMAKE
  cmake_minimum_required(VERSION 3.15)
  project(#{project} LANGUAGES #{lang})
CMAKE

cmake << if options[:type] == "exe"
  "add_executable(#{project} src/main.#{ext})\n"
elsif options[:type] == "lib"
  "add_library(#{project} src/main.#{ext})\n"
else
  ""
end

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

puts "Project '#{project}' created with language #{options[:lang]}, generator #{options[:generator]}, and type #{options[:type]}.

Configure, build, and run instructions:

cd #{project}
cmake --preset debug
cmake --build --preset debug
./build/debug/#{project}

Note: See more `CMakeLists.txt` commands and their definitions at 
https://cmake.org/cmake/help/book/mastering-cmake/chapter/Writing%20CMakeLists%20Files.html"