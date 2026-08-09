# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(EricPC_MVP2)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)

# 1. 引入 Python 源码头文件路径（解决 #include "Python.h" 找不到的问题）
include_directories(
    /Users/wx/harmonys/other/Python-3.13.2
    /Users/wx/harmonys/other/Python-3.13.2/Include
)

# 2. 导入放在 libs 目录下的 Python 动态链接库（使用绝对路径，彻底杜绝路径层级错误）
add_library(python SHARED IMPORTED)
set_target_properties(python PROPERTIES
    IMPORTED_LOCATION "/Users/wx/harmonys/other/EricPC_MVP2/entry/libs/arm64-v8a/libpython3.13.so"
)

# 3. 声明你的 NAPI 动态库
add_library(entry SHARED napi_init.cpp)

# 4. 链接所有依赖库（Native API、日志库、Python 引擎库）
target_link_libraries(entry PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
    python
)