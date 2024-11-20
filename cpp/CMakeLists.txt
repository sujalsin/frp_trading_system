cmake_minimum_required(VERSION 3.10)
project(frp_trading_system)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Find required packages
find_package(Threads REQUIRED)

# Set include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Create library target
add_library(execution_engine SHARED
    src/execution_engine.cpp
    src/bindings.cpp
)

target_include_directories(execution_engine
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(execution_engine
    PRIVATE
        Threads::Threads
)

# Create test executable
add_executable(test_execution
    test/test_execution.cpp
)

target_link_libraries(test_execution execution_engine)

# Install targets
install(TARGETS execution_engine
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)
