cmake_minimum_required(VERSION 3.16.5)
project(thorvg_harmony LANGUAGES CXX)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

set(THORVG_PREBUILT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/prebuilt/${OHOS_ARCH}")
if(NOT EXISTS "${THORVG_PREBUILT_DIR}/libthorvg.a")
    set(THORVG_PREBUILT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/prebuilt/arm64-v8a")
endif()
set(THORVG_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/include")

add_library(thorvg_static STATIC IMPORTED)
set_target_properties(thorvg_static PROPERTIES
    IMPORTED_LOCATION "${THORVG_PREBUILT_DIR}/libthorvg.a"
)

# Native HAR ships the ThorVG C API only (no NAPI / ArkTS bridge).
add_library(thorvg SHARED stub.cpp)

target_include_directories(thorvg
    PUBLIC
        ${THORVG_INCLUDE_DIR}
)

target_compile_features(thorvg PRIVATE cxx_std_17)
target_compile_definitions(thorvg PRIVATE TVG_STATIC)

target_link_options(thorvg PRIVATE
    "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/export.map"
)

target_link_libraries(thorvg
    PRIVATE
        -Wl,--whole-archive
        thorvg_static
        -Wl,--no-whole-archive
)
