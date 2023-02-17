
cmake_minimum_required(VERSION 3.24)

project("Firebird" C CXX)

set(FIREBIRD_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(FIREBIRD_BINARY_DIR ${CMAKE_BINARY_DIR}/${PROJECT_NAME})
set(CMAKE_MODULE_PATH ${FIREBIRD_SOURCE_DIR}/cmake)

#@set FB_INSTALL_SCRIPTS=%FB_ROOT_PATH%\builds\install\arch-specific\win32
#@set FB_ICU_SOURCE_BIN=%FB_ROOT_PATH%\extern\icu\%FB_TARGET_PLATFORM%\release\bin\

# íÜä‘èoóÕêÊ
set(FIREBIRD_OUTPUT_DIR "${FIREBIRD_BINARY_DIR}/output")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${FIREBIRD_OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${FIREBIRD_OUTPUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${FIREBIRD_OUTPUT_DIR})

# îzíuêÊ
set(FIREBIRD_GEN_DIR "${FIREBIRD_BINARY_DIR}/gen")
set(FIREBIRD_EXEC_DIR "${FIREBIRD_BINARY_DIR}/exec")

include(Common)
include(Preprocess)
include(Layout)

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
#
# main
#
################################################################################
include(Projects)

# interfaces
add_custom_command(
    OUTPUT "${FIREBIRD_SOURCE_DIR}/src/include/firebird/IdlFbInterfaces.h"
    DEPENDS
        cloop
        "${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl"
    COMMAND cloop
            "${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl"
            c++
            "${FIREBIRD_SOURCE_DIR}/src/include/firebird/IdlFbInterfaces.h"
            IDL_FB_INTERFACES_H Firebird I
    COMMENT "Updating cloop interfaces..."
)
add_custom_command(
    OUTPUT "${FIREBIRD_GEN_DIR}/boot/misc/func.pas"
    DEPENDS
        "${FIREBIRD_GEN_DIR}/boot/misc"
        "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/fb_get_master_interface.pas"
        "${FIREBIRD_SOURCE_DIR}/src/include/firebird/impl/consts_pub.h"
        "${FIREBIRD_SOURCE_DIR}/lang_helpers/gds_codes.pas"
        def_awk
        isc_grep
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/fb_get_master_interface.pas" "${FIREBIRD_GEN_DIR}/boot/misc/func.pas"
    COMMAND def_awk < "${FIREBIRD_SOURCE_DIR}/src/include/firebird/impl/consts_pub.h" >> "${FIREBIRD_GEN_DIR}/boot/misc/func.pas"
    COMMAND isc_grep < "${FIREBIRD_SOURCE_DIR}/lang_helpers/gds_codes.pas" >> "${FIREBIRD_GEN_DIR}/boot/misc/func.pas"
)
add_custom_command(
    OUTPUT "${FIREBIRD_GEN_DIR}/boot/Firebird.pas"
    DEPENDS
        cloop
        "${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl"
        "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.interface.pas"
        "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.implementation.pas"
        "${FIREBIRD_GEN_DIR}/boot/misc/func.pas"
        "${FIREBIRD_GEN_DIR}/boot"
    COMMAND cloop
            "${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl"
            pascal
            "${FIREBIRD_GEN_DIR}/boot/Firebird.pas"
            Firebird
            --uses SysUtils
            --interfaceFile "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.interface.pas"
            --implementationFile "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.implementation.pas"
            --exceptionClass FbException
            --functionsFile "${FIREBIRD_GEN_DIR}/boot/misc/func.pas"
            --prefix I
)
set_source_files_properties(
    "${FIREBIRD_SOURCE_DIR}/src/include/firebird/IdlFbInterfaces.h"
    "${FIREBIRD_GEN_DIR}/boot/misc/func.pas"
    "${FIREBIRD_GEN_DIR}/boot/Firebird.pas"
    PROPERTIES GENERATED TRUE
)
#add_custom_target(UpdateCloopInterfaces ALL
#    DEPENDS
#        "${FIREBIRD_SOURCE_DIR}/src/include/firebird/IdlFbInterfaces.h"
#        "${FIREBIRD_GEN_DIR}/Firebird.pas"
#    SOURCES
#        "${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl"
#)

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

# parse
add_custom_command(
    OUTPUT
        "${FIREBIRD_SOURCE_DIR}/src/include/gen/parse.h"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.cpp"
    DEPENDS
        btyacc
        "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.y"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/btyacc_fb.ske"
    COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
        (Get-Content -Path '${FIREBIRD_SOURCE_DIR}/src/dsql/parse.y') | \
        foreach { if ($_ -match '%type .*') { Write-Output $_ }} | \
        Set-Content -Path types.y"
    COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
        (Get-Content -Path '${FIREBIRD_SOURCE_DIR}/src/dsql/parse.y') | \
        foreach { if (-not ($_ -match '%type .*')) { Write-Output $_ }} | \
        Set-Content -Path y.y"
    COMMAND btyacc -l -d -S "${FIREBIRD_SOURCE_DIR}/src/dsql/btyacc_fb.ske" y.y

    COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
        (Get-Content -Path y_tab.h) | \
        foreach { $_ -replace '#define ([A-Z].*)', '#define TOK_$1' } | \
        Set-Content -Path y_tab.h"
    COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
        (Get-Content -Path y_tab.h) | \
        foreach { $_ -replace '#define TOK_YY(.*)', '#define YY$1' } | \
        Set-Content -Path y_tab.h"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "y_tab.h" "${FIREBIRD_SOURCE_DIR}/src/include/gen/parse.h"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "y_tab.c" "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.cpp"
    COMMENT "Generating parse.cpp, parse.h"
    VERBATIM
)
set_source_files_properties(
    "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.cpp"
    "${FIREBIRD_SOURCE_DIR}/src/include/gen/parse.h"
    PROPERTIES GENERATED TRUE
)

# databases
add_custom_command(
    OUTPUT
        "${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB"
        "${FIREBIRD_GEN_DIR}/dbs/SECURITY.FDB"
    DEPENDS
        "${FIREBIRD_EXEC_DIR}/boot/isql.exe"
        "${FIREBIRD_GEN_DIR}/dbs"
        "${FIREBIRD_SOURCE_DIR}/src/dbs/security.sql"
    COMMAND ${CMAKE_COMMAND} -E rm -f "${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB" "${FIREBIRD_GEN_DIR}/dbs/SECURITY.FDB"
    COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
        [string[]] $sql = @(\"CREATE DATABASE '${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB' PAGE_SIZE 8192;\"); \
        $sql += (Get-Content -Path '${FIREBIRD_SOURCE_DIR}/src/dbs/security.sql'); \
        Write-Output $sql | ${FIREBIRD_EXEC_DIR}/boot/isql.exe;"
    COMMAND ${CMAKE_COMMAND} -E copy "${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB" "${FIREBIRD_GEN_DIR}/dbs/SECURITY.FDB"
    COMMENT "Create SECURITY4.FDB"
    VERBATIM
)
add_custom_command(
    OUTPUT
        "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB"
        "${FIREBIRD_GEN_DIR}/dbs/yachts.lnk"
    DEPENDS
        "${FIREBIRD_EXEC_DIR}/boot/gbak.exe"
        "${FIREBIRD_GEN_DIR}/dbs"
        "${FIREBIRD_SOURCE_DIR}/builds/misc/metadata.gbak"
    COMMAND ${CMAKE_COMMAND} -E rm -f "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB" "${FIREBIRD_GEN_DIR}/dbs/yachts.lnk"
    COMMAND "${FIREBIRD_EXEC_DIR}/boot/gbak.exe" -r "${FIREBIRD_SOURCE_DIR}/builds/misc/metadata.gbak" "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB"
    COMMAND ${CMAKE_COMMAND} -E copy "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB" "${FIREBIRD_GEN_DIR}/dbs/yachts.lnk"
    COMMENT "Create METADATA.FDB"
    VERBATIM
)
add_custom_command(
    OUTPUT
        "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB"
    DEPENDS
        "${FIREBIRD_EXEC_DIR}/boot/isql.exe"
        "${FIREBIRD_GEN_DIR}/dbs"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/msg.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/facilities2.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/sqlstates.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/locales.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/history2.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/messages2.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/symbols2.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/system_errors2.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/transmsgs.fr_FR2.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/transmsgs.de_DE2.sql"
    COMMAND ${CMAKE_COMMAND} -E rm -f "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB"
    COMMAND pwsh.exe -ExecutionPolicy Bypass -Command
        "Write-Output \"CREATE DATABASE '${FIREBIRD_GEN_DIR}/dbs/MSG.FDB' PAGE_SIZE 8192;\" | ${FIREBIRD_EXEC_DIR}/boot/isql.exe;"
    COMMAND "${FIREBIRD_EXEC_DIR}/boot/isql.exe" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/msg.sql"
    COMMAND "${FIREBIRD_EXEC_DIR}/boot/isql.exe" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/facilities2.sql"
    COMMAND "${FIREBIRD_EXEC_DIR}/boot/isql.exe" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/sqlstates.sql"
    COMMAND "${FIREBIRD_EXEC_DIR}/boot/isql.exe" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/locales.sql"
    COMMAND "${FIREBIRD_EXEC_DIR}/boot/isql.exe" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/history2.sql"
    COMMAND "${FIREBIRD_EXEC_DIR}/boot/isql.exe" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/messages2.sql"
    COMMAND "${FIREBIRD_EXEC_DIR}/boot/isql.exe" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/symbols2.sql"
    COMMAND "${FIREBIRD_EXEC_DIR}/boot/isql.exe" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/system_errors2.sql"
    COMMAND "${FIREBIRD_EXEC_DIR}/boot/isql.exe" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/transmsgs.fr_FR2.sql"
    COMMAND "${FIREBIRD_EXEC_DIR}/boot/isql.exe" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/transmsgs.de_DE2.sql"
    COMMENT "Create MSG.FDB"
    VERBATIM
)
add_custom_command(
    OUTPUT
        "${FIREBIRD_GEN_DIR}/dbs/HELP.FDB"
    DEPENDS
        "${FIREBIRD_EXEC_DIR}/boot/gbak.exe"
        "${FIREBIRD_GEN_DIR}/dbs"
        "${FIREBIRD_SOURCE_DIR}/builds/misc/help.gbak"
    COMMAND ${CMAKE_COMMAND} -E rm -f "${FIREBIRD_GEN_DIR}/dbs/HELP.FDB"
    COMMAND "${FIREBIRD_EXEC_DIR}/boot/gbak.exe" -r "${FIREBIRD_SOURCE_DIR}/builds/misc/help.gbak" "${FIREBIRD_GEN_DIR}/dbs/HELP.FDB"
    COMMENT "Create HELP.FDB"
    VERBATIM
)
#add_custom_target(databases ALL
#    DEPENDS
#        "${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB"
#        "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB"
#        "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB"
#        "${FIREBIRD_GEN_DIR}/dbs/HELP.FDB"
#)

# preprocess(master)

# message
add_custom_command(
    OUTPUT "${FIREBIRD_EXEC_DIR}/main/firebird.msg"
    DEPENDS
        build_msg
        "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB"
    COMMAND build_msg -D "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -p "${FIREBIRD_GEN_DIR}" -f firebird.msg
    COMMAND ${CMAKE_COMMAND} -E copy_if_different firebird.msg "${FIREBIRD_EXEC_DIR}/main/firebird.msg"
    COMMENT "Building message file..."
    VERBATIM
)
add_custom_command(
    OUTPUT
        "${FIREBIRD_GEN_DIR}/include/gds_codes.ftn" # âº
    DEPENDS
        codes
        "${FIREBIRD_GEN_DIR}/include"
    COMMAND codes "${FIREBIRD_GEN_DIR}/include" "${FIREBIRD_SOURCE_DIR}/lang_helpers"
    COMMENT "Building codes header..."
    VERBATIM
)

################################################################################
# Layout
################################################################################
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

fb_finalize()

#C:\Program Files\Firebird\Firebird_4_0\zlib1.dll
#C:\Program Files\Firebird\Firebird_4_0\firebird.msg
#C:\Program Files\Firebird\Firebird_4_0\gpre.exe
#C:\Program Files\Firebird\Firebird_4_0\ib_util.dll
#C:\Program Files\Firebird\Firebird_4_0\icudt63.dll
#C:\Program Files\Firebird\Firebird_4_0\icudt63l.dat
#C:\Program Files\Firebird\Firebird_4_0\icuin63.dll
#C:\Program Files\Firebird\Firebird_4_0\icuuc63.dll
#C:\Program Files\Firebird\Firebird_4_0\msvcp140.dll
#C:\Program Files\Firebird\Firebird_4_0\readme.txt
#C:\Program Files\Firebird\Firebird_4_0\unins000.dat
#C:\Program Files\Firebird\Firebird_4_0\unins000.exe
#C:\Program Files\Firebird\Firebird_4_0\vcruntime140.dll

#"plugins\udr\udf_compat.dll"
#"plugins\udr\UdfBackwardCompatibility.sql"
#"plugins\udr\udrcpp_example.dll"
# tzdata
