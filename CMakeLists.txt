
cmake_minimum_required(VERSION 3.24)

project("Firebird" C CXX)

set(FIREBIRD_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(FIREBIRD_BINARY_DIR ${CMAKE_BINARY_DIR}/${PROJECT_NAME})
set(CMAKE_MODULE_PATH ${FIREBIRD_SOURCE_DIR}/cmake)

include(Layout)
include(Generator)

################################################################################
#
# pre-build
#
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
include(Projects)


# ttmath
if(${PLATFORM} STREQUAL "x64")
    # @ml64.exe /c /Fo %FB_TEMP_DIR%\..\%FB_OBJ_DIR%\common\ttmathuint_x86_64_msvc.obj %FB_ROOT_PATH%\extern\ttmath\ttmathuint_x86_64_msvc.asm
endif()

# re2
subdirs(extern/re2)

# zlib
add_custom_command(
    OUTPUT "${FIREBIRD_SOURCE_DIR}/extern/zlib/zlib.h"
    COMMAND ${FIREBIRD_SOURCE_DIR}/extern/zlib/zlib.exe -y
    COMMENT "Extracting pre-built zlib"
)

# icu/zlib
set(BOOT_EXECUTION_DEPS
    "${FIREBIRD_EXEC_DIR}/boot/icudt63.dll"
    "${FIREBIRD_EXEC_DIR}/boot/icuin63.dll"
    "${FIREBIRD_EXEC_DIR}/boot/icuuc63.dll"
    "${FIREBIRD_EXEC_DIR}/boot/icudt63l.dat"
    "${FIREBIRD_EXEC_DIR}/boot/zlib1.dll"
)
set(MAIN_EXECUTION_DEPS
    "${FIREBIRD_EXEC_DIR}/main/fbclient.dll"
    "${FIREBIRD_EXEC_DIR}/main/plugins/engine13.dll"
    "${FIREBIRD_EXEC_DIR}/main/icudt63.dll"
    "${FIREBIRD_EXEC_DIR}/main/icuin63.dll"
    "${FIREBIRD_EXEC_DIR}/main/icuuc63.dll"
    "${FIREBIRD_EXEC_DIR}/main/icudt63l.dat"
    "${FIREBIRD_EXEC_DIR}/main/zlib1.dll"
)

################################################################################
# Layout
################################################################################

# icu/zlib
if("${PLATFORM}" STREQUAL "x64")
    fb_add_files(MAIN BOOT
        LAYOUT_DIR /
        ROOT_FILES
            "extern/icu/icudt63l.dat"
            "extern/icu/x64/Release/bin/icuuc63.dll"
            "extern/icu/x64/Release/bin/icudt63.dll"
            "extern/icu/x64/Release/bin/icuin63.dll"
            "extern/zlib/x64/zlib1.dll"
    )
else()
    fb_add_files(MAIN BOOT
        LAYOUT_DIR /
        ROOT_FILES
            "extern/icu/icudt63l.dat"
            "extern/icu/Win32/Release/bin/icuuc63.dll"
            "extern/icu/Win32/Release/bin/icudt63.dll"
            "extern/icu/Win32/Release/bin/icuin63.dll"
            "extern/zlib/Win32/zlib1.dll"
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
