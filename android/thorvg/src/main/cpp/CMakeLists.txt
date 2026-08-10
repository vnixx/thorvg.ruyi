cmake_minimum_required(VERSION 3.22.1)
project(thorvg_android LANGUAGES CXX)

set(THORVG_PREBUILT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/prebuilt/${ANDROID_ABI}")
set(THORVG_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/include")

add_library(thorvg_static STATIC IMPORTED)
set_target_properties(thorvg_static PROPERTIES
    IMPORTED_LOCATION "${THORVG_PREBUILT_DIR}/libthorvg.a"
)

# Prefab / JNI consumers get the ThorVG C API only (no Kotlin/JNI bridge).
add_library(thorvg SHARED stub.cpp)

target_include_directories(thorvg
    PUBLIC
        ${THORVG_INCLUDE_DIR}
)

target_compile_features(thorvg PRIVATE cxx_std_17)
target_compile_definitions(thorvg PRIVATE TVG_STATIC)

find_library(log-lib log)
find_library(android-lib android)

target_link_options(thorvg PRIVATE
    "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/export.map"
)

target_link_libraries(thorvg
    PRIVATE
        -Wl,--whole-archive
        thorvg_static
        -Wl,--no-whole-archive
        ${log-lib}
        ${android-lib}
        c++_shared
)
