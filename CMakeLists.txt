
cmake_minimum_required(VERSION 3.24)

project("Firebird" C CXX)

set(FIREBIRD_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(FIREBIRD_BINARY_DIR "${CMAKE_BINARY_DIR}/${PROJECT_NAME}")
set(CMAKE_MODULE_PATH
    "${FIREBIRD_SOURCE_DIR}/builds/cmake"
)

################################################################################
# configure
################################################################################
include(Configure)

set(FB_PREFIX "${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}")
set(FB_IPC_NAME "FirebirdIPI")
set(FB_LOGFILENAME "firebird.log")
set(FB_PIPE_NAME "interbas")
set(FB_SERVICE_NAME "gds_db")
set(FB_SERVICE_PORT 3050)

if (WIN32)
    set(FB_PREFIX [[C:\\Program Files\\Firebird\\]])
    set(FB_IPC_NAME "FIREBIRD")
endif()

configure_file(
    "${FIREBIRD_SOURCE_DIR}/src/include/gen/autoconfig.h.in"
    "${FIREBIRD_SOURCE_DIR}/src/include/gen/autoconfig.h"
    @ONLY
)

if(APPLE)
    add_compile_definitions(
        DARWIN
        _THREAD_SAFE
    )
    add_compile_options(
        -fPIC
        -stdlib=libc++
        -fvisibility-inlines-hidden
        -fvisibility=hidden
        -fno-common
        -fno-rtti
        -mmacosx-version-min=10.7
    )
    add_link_options(
        -flat_namespace
    )
endif()

include(Layout)

################################################################################
# dependencies
################################################################################
# icu
if(WIN32)
    set(ICU_INC_PATH "${FIREBIRD_SOURCE_DIR}/extern/icu/include")
else()
    function(fb_find_icu_library variable libname)
        cmake_parse_arguments(ICU "" "" "PATHS" ${ARGN})

        find_library(LIB_ICU
            NAMES "${libname}"
            PATHS ${ICU_PATHS}
            NO_CACHE
            REQUIRED
        )
        cmake_path(SET LIB_DIR NORMALIZE "${LIB_ICU}/..")
        file(READ_SYMLINK "${LIB_ICU}" LIB_ICU)
        if(NOT IS_ABSOLUTE "${LIB_ICU}")
            cmake_path(SET LIB_ICU NORMALIZE "${LIB_DIR}/${LIB_ICU}")
        endif()

        # 出力先
        cmake_path(GET LIB_ICU  FILENAME    LIB_FILENAME)
        cmake_path(SET LIB_COPY NORMALIZE   "${FIREBIRD_OUTPUT_DIR}/common/${LIB_FILENAME}")

        add_custom_command(
            OUTPUT  "${LIB_COPY}"
            DEPENDS "${LIB_ICU}"
            COMMAND ${CMAKE_COMMAND} -E copy "${LIB_ICU}" "${LIB_COPY}"
            COMMAND chmod a+rw "${LIB_COPY}"
            COMMAND install_name_tool
                -id "@rpath/${LIB_FILENAME}"
                -change "@loader_path/libicudata.72.dylib" "@loader_path/libicudata.72.1.dylib"
                -change "@loader_path/libicuuc.72.dylib" "@loader_path/libicuuc.72.1.dylib"
                "${LIB_COPY}"
            VERBATIM
        )

        # 設定
        set("${variable}" "${LIB_COPY}" PARENT_SCOPE)
    endfunction()

    fb_find_icu_library(LIB_ICUDATA icudata
        PATHS
            /usr/lib
            /usr/local/lib
            /usr/local/opt/icu4c/lib
    )
    fb_find_icu_library(LIB_ICUI18N icui18n
        PATHS
            /usr/lib
            /usr/local/lib
            /usr/local/opt/icu4c/lib
    )
    fb_find_icu_library(LIB_ICUUC icuuc
        PATHS
            /usr/lib
            /usr/local/lib
            /usr/local/opt/icu4c/lib
    )

    # TODO: 決め打ち
    set(ICU_INC_PATH "/usr/local/opt/icu4c/include")
endif()

# zlib
if(NOT HAVE_ZLIB_H AND WIN32)
    add_custom_command(
        OUTPUT "${FIREBIRD_SOURCE_DIR}/extern/zlib/zlib.h"
        COMMAND ${FIREBIRD_SOURCE_DIR}/extern/zlib/zlib.exe -y
        COMMENT "Extracting pre-built zlib"
    )
    set(ZLIB_INC_PATH "${FIREBIRD_SOURCE_DIR}/extern/zlib")
else()
    unset(ZLIB_INC_PATH)
endif()

# icu/zlib
set(COMMON_ICU_DEPS     "")
set(BOOT_EXECUTION_DEPS "")
set(MAIN_EXECUTION_DEPS
    "$<TARGET_PROPERTY:yvalve_main,FB_DEPLOY_PATH>"
    "$<TARGET_PROPERTY:engine_main,FB_DEPLOY_PATH>"
)
if(WIN32)
    list(APPEND BOOT_EXECUTION_DEPS
        "${FIREBIRD_EXEC_DIR}/boot/icudt63.dll"
        "${FIREBIRD_EXEC_DIR}/boot/icuin63.dll"
        "${FIREBIRD_EXEC_DIR}/boot/icuuc63.dll"
        "${FIREBIRD_EXEC_DIR}/boot/icudt63l.dat"
        "${FIREBIRD_EXEC_DIR}/boot/zlib1.dll"
    )
    list(APPEND MAIN_EXECUTION_DEPS
        "${FIREBIRD_EXEC_DIR}/main/icudt63.dll"
        "${FIREBIRD_EXEC_DIR}/main/icuin63.dll"
        "${FIREBIRD_EXEC_DIR}/main/icuuc63.dll"
        "${FIREBIRD_EXEC_DIR}/main/icudt63l.dat"
        "${FIREBIRD_EXEC_DIR}/main/zlib1.dll"
    )
else()
    list(APPEND COMMON_ICU_DEPS
        "${LIB_ICUDATA}"
        "${LIB_ICUI18N}"
        "${LIB_ICUUC}"
    )
    list(APPEND BOOT_EXECUTION_DEPS
        "${FIREBIRD_EXEC_DIR}/boot/lib/$<PATH:GET_FILENAME,${LIB_ICUDATA}>"
        "${FIREBIRD_EXEC_DIR}/boot/lib/$<PATH:GET_FILENAME,${LIB_ICUI18N}>"
        "${FIREBIRD_EXEC_DIR}/boot/lib/$<PATH:GET_FILENAME,${LIB_ICUUC}>"
    )
    list(APPEND MAIN_EXECUTION_DEPS
        "${FIREBIRD_EXEC_DIR}/main/lib/$<PATH:GET_FILENAME,${LIB_ICUDATA}>"
        "${FIREBIRD_EXEC_DIR}/main/lib/$<PATH:GET_FILENAME,${LIB_ICUI18N}>"
        "${FIREBIRD_EXEC_DIR}/main/lib/$<PATH:GET_FILENAME,${LIB_ICUUC}>"
    )
endif()

################################################################################
# 
################################################################################
include(Generator)

################################################################################
# pre-build
################################################################################

if(WIN32)
    # icu
    message(STATUS "Extracting pre-built ICU")
    set(ICU_EXTRACT ${FIREBIRD_SOURCE_DIR}/extern/icu/icu.exe -y
        CACHE STRING "ICU extraction variable")
    execute_process(COMMAND ${ICU_EXTRACT})

    # tzdata
    message(STATUS "Extracting tzdata")
    file(MAKE_DIRECTORY ${FIREBIRD_OUTPUT_DIR}/common/tzdata)
    set(TZD_EXTRACT "Expand-Archive -Path '${FIREBIRD_SOURCE_DIR}/extern/icu/tzdata/le.zip' -DestinationPath '${FIREBIRD_OUTPUT_DIR}/common/tzdata'"
        CACHE STRING "tzdata extraction variable")
    execute_process(COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "${TZD_EXTRACT}")
endif()

################################################################################
# main
################################################################################
# ttmath
if("${PLATFORM}" STREQUAL "x64")
    # @ml64.exe /c /Fo %FB_TEMP_DIR%\..\%FB_OBJ_DIR%\common\ttmathuint_x86_64_msvc.obj %FB_ROOT_PATH%\extern\ttmath\ttmathuint_x86_64_msvc.asm
endif()

# re2
subdirs(extern/re2)

include(Projects)

################################################################################
# Layout
################################################################################
# icu/zlib
if(WIN32)
    if("${PLATFORM}" STREQUAL "x64")
        fb_add_files(MAIN BOOT
            LAYOUT_DIR ${LODIR_LIB}
            ROOT_FILES
                "extern/icu/icudt63l.dat"
                "extern/icu/x64/Release/bin/icuuc63.dll"
                "extern/icu/x64/Release/bin/icudt63.dll"
                "extern/icu/x64/Release/bin/icuin63.dll"
                "extern/zlib/x64/zlib1.dll"
        )
    else()
        fb_add_files(MAIN BOOT
            LAYOUT_DIR ${LODIR_LIB}
            ROOT_FILES
                "extern/icu/icudt63l.dat"
                "extern/icu/Win32/Release/bin/icuuc63.dll"
                "extern/icu/Win32/Release/bin/icudt63.dll"
                "extern/icu/Win32/Release/bin/icuin63.dll"
                "extern/zlib/Win32/zlib1.dll"
        )
    endif()
else()
    fb_add_files(MAIN BOOT
        LAYOUT_DIR ${LODIR_LIB}
        FILES
            ${COMMON_ICU_DEPS}
    )
endif()

# config files
fb_add_files(MAIN
    LAYOUT_DIR /
    ROOT_FILES
        "builds/install/misc/firebird.conf"
        "builds/install/misc/databases.conf"
        "builds/install/misc/plugins.conf"
        "builds/install/misc/replication.conf"
        "src/utilities/ntrace/fbtrace.conf"
        "builds/install/misc/IPLicense.txt"
        "builds/install/misc/IDPLicense.txt"

    GEN_FILES
        "firebird.msg"
)
fb_add_files(MAIN
    LAYOUT_DIR /intl
    ROOT_FILES
        "builds/install/misc/fbintl.conf"
)
fb_add_files(MAIN
    LAYOUT_DIR /plugins
    ROOT_FILES
        "src/plugins/udr_engine/udr_engine.conf"
)

# databases
fb_add_files(MAIN
    LAYOUT_DIR /
    FILES
        "${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB"
)
fb_add_files(MAIN
    LAYOUT_DIR /help
    FILES
        "${FIREBIRD_GEN_DIR}/dbs/HELP.FDB"
)

# headers
fb_add_files(MAIN
    LAYOUT_DIR /include
    ROOT_FILES
        "src/yvalve/perf.h"
)
fb_add_files(MAIN
    LAYOUT_DIR /include/firebird
    ROOT_FILES
        "src/include/gen/Firebird.pas"
)

fb_finalize()

#C:\Program Files\Firebird\Firebird_4_0\gpre.exe
#C:\Program Files\Firebird\Firebird_4_0\msvcp140.dll
#C:\Program Files\Firebird\Firebird_4_0\readme.txt
#C:\Program Files\Firebird\Firebird_4_0\unins000.dat
#C:\Program Files\Firebird\Firebird_4_0\unins000.exe
#C:\Program Files\Firebird\Firebird_4_0\vcruntime140.dll

#"plugins\udr\UdfBackwardCompatibility.sql"
#"plugins\udr\udrcpp_example.dll"
# tzdata
