# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(EricPC_MVP2)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)

# 导入放在 libs 目录下的 Python 动态链接库（使用相对路径）
add_library(python SHARED IMPORTED)
set_target_properties(python PROPERTIES
    IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../../../../libs/arm64-v8a/libpython3.13.so"
)

# 声明 NAPI 动态库
add_library(entry SHARED napi_init.cpp)

# 链接所有依赖库（Native API、日志库、Python 引擎库）
target_link_libraries(entry PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
    python
)
