# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.31

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/local/bin/cmake

# The command to remove a file.
RM = /usr/local/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/sujal/CascadeProjects/frp_trading_system/cpp

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/sujal/CascadeProjects/frp_trading_system/cpp/build

# Include any dependencies generated for this target.
include CMakeFiles/test_execution.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include CMakeFiles/test_execution.dir/compiler_depend.make

# Include the progress variables for this target.
include CMakeFiles/test_execution.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/test_execution.dir/flags.make

CMakeFiles/test_execution.dir/codegen:
.PHONY : CMakeFiles/test_execution.dir/codegen

CMakeFiles/test_execution.dir/test/test_execution.cpp.o: CMakeFiles/test_execution.dir/flags.make
CMakeFiles/test_execution.dir/test/test_execution.cpp.o: /Users/sujal/CascadeProjects/frp_trading_system/cpp/test/test_execution.cpp
CMakeFiles/test_execution.dir/test/test_execution.cpp.o: CMakeFiles/test_execution.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/Users/sujal/CascadeProjects/frp_trading_system/cpp/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/test_execution.dir/test/test_execution.cpp.o"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/test_execution.dir/test/test_execution.cpp.o -MF CMakeFiles/test_execution.dir/test/test_execution.cpp.o.d -o CMakeFiles/test_execution.dir/test/test_execution.cpp.o -c /Users/sujal/CascadeProjects/frp_trading_system/cpp/test/test_execution.cpp

CMakeFiles/test_execution.dir/test/test_execution.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/test_execution.dir/test/test_execution.cpp.i"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /Users/sujal/CascadeProjects/frp_trading_system/cpp/test/test_execution.cpp > CMakeFiles/test_execution.dir/test/test_execution.cpp.i

CMakeFiles/test_execution.dir/test/test_execution.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/test_execution.dir/test/test_execution.cpp.s"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /Users/sujal/CascadeProjects/frp_trading_system/cpp/test/test_execution.cpp -o CMakeFiles/test_execution.dir/test/test_execution.cpp.s

# Object files for target test_execution
test_execution_OBJECTS = \
"CMakeFiles/test_execution.dir/test/test_execution.cpp.o"

# External object files for target test_execution
test_execution_EXTERNAL_OBJECTS =

test_execution: CMakeFiles/test_execution.dir/test/test_execution.cpp.o
test_execution: CMakeFiles/test_execution.dir/build.make
test_execution: libexecution_engine.dylib
test_execution: CMakeFiles/test_execution.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --bold --progress-dir=/Users/sujal/CascadeProjects/frp_trading_system/cpp/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX executable test_execution"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/test_execution.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/test_execution.dir/build: test_execution
.PHONY : CMakeFiles/test_execution.dir/build

CMakeFiles/test_execution.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/test_execution.dir/cmake_clean.cmake
.PHONY : CMakeFiles/test_execution.dir/clean

CMakeFiles/test_execution.dir/depend:
	cd /Users/sujal/CascadeProjects/frp_trading_system/cpp/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/sujal/CascadeProjects/frp_trading_system/cpp /Users/sujal/CascadeProjects/frp_trading_system/cpp /Users/sujal/CascadeProjects/frp_trading_system/cpp/build /Users/sujal/CascadeProjects/frp_trading_system/cpp/build /Users/sujal/CascadeProjects/frp_trading_system/cpp/build/CMakeFiles/test_execution.dir/DependInfo.cmake "--color=$(COLOR)"
.PHONY : CMakeFiles/test_execution.dir/depend

