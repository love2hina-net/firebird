################################################################################
#
# Code/Database Generator Definitions
#
################################################################################

################################################################################
# definitions(interface)
################################################################################
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
    VERBATIM
)
add_custom_command(
    OUTPUT "${FIREBIRD_GEN_DIR}/main/misc/func.pas"
    DEPENDS
        "${FIREBIRD_GEN_DIR}/main/misc"
        "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/fb_get_master_interface.pas"
        "${FIREBIRD_SOURCE_DIR}/src/include/firebird/impl/consts_pub.h"
        "${FIREBIRD_SOURCE_DIR}/lang_helpers/gds_codes.pas"
        def_awk
        isc_grep
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/fb_get_master_interface.pas" "${FIREBIRD_GEN_DIR}/main/misc/func.pas"
    COMMAND def_awk < "${FIREBIRD_SOURCE_DIR}/src/include/firebird/impl/consts_pub.h" >> "${FIREBIRD_GEN_DIR}/main/misc/func.pas"
    COMMAND isc_grep < "${FIREBIRD_SOURCE_DIR}/lang_helpers/gds_codes.pas" >> "${FIREBIRD_GEN_DIR}/main/misc/func.pas"
    VERBATIM
)
add_custom_command(
    OUTPUT "${FIREBIRD_SOURCE_DIR}/src/include/gen/Firebird.pas"
    DEPENDS
        cloop
        "${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl"
        "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.interface.pas"
        "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.implementation.pas"
        "${FIREBIRD_GEN_DIR}/main/misc/func.pas"
    COMMAND cloop
            "${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl"
            pascal
            "${FIREBIRD_SOURCE_DIR}/src/include/gen/Firebird.pas"
            Firebird
            --uses SysUtils
            --interfaceFile "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.interface.pas"
            --implementationFile "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.implementation.pas"
            --exceptionClass FbException
            --functionsFile "${FIREBIRD_GEN_DIR}/main/misc/func.pas"
            --prefix I
    VERBATIM
)
set_source_files_properties(
    "${FIREBIRD_SOURCE_DIR}/src/include/firebird/IdlFbInterfaces.h"
    "${FIREBIRD_GEN_DIR}/main/misc/func.pas"
    "${FIREBIRD_SOURCE_DIR}/src/include/gen/Firebird.pas"
    PROPERTIES GENERATED TRUE
)

################################################################################
# parse
################################################################################
if(WIN32)
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
elseif(APPLE)
    add_custom_command(
        OUTPUT
            "${FIREBIRD_SOURCE_DIR}/src/include/gen/parse.h"
            "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.cpp"
        DEPENDS
            btyacc
            "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.y"
            "${FIREBIRD_SOURCE_DIR}/src/dsql/btyacc_fb.ske"
        COMMAND sed -n [[/%type .*/p]] "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.y" > types.y
        COMMAND sed [[s/%type .*//]] "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.y" > y.y
        COMMAND btyacc -l -d -S "${FIREBIRD_SOURCE_DIR}/src/dsql/btyacc_fb.ske" y.y
    
        COMMAND sed -i '' [[s/#define \([A-Z].*\)/#define TOK_\1/g]] y_tab.h
        COMMAND sed -i '' [[s/#define TOK_YY\(.*\)/#define YY\1/g]] y_tab.h
    
        COMMAND ${CMAKE_COMMAND} -E copy_if_different y_tab.h "${FIREBIRD_SOURCE_DIR}/src/include/gen/parse.h"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different y_tab.c "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.cpp"
        COMMENT "Generating parse.cpp, parse.h"
        VERBATIM
    )
endif()
set_source_files_properties(
    "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.cpp"
    "${FIREBIRD_SOURCE_DIR}/src/include/gen/parse.h"
    PROPERTIES GENERATED TRUE
)

################################################################################
# directory layout
################################################################################
foreach(DIR IN ITEMS
    "alice"
    "auth"
    "auth/SecurityDatabase"
    "burp"
    "dsql"
    "gpre"
    "gpre/std"
    "isql"
    "jrd"
    "misc"
    "msgs"
    "qli"
    "examples"
    "yvalve"
    "utilities"
    "utilities/gstat")

    add_custom_command(
        OUTPUT "${FIREBIRD_GEN_DIR}/boot/${DIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${FIREBIRD_GEN_DIR}/boot/${DIR}"
        COMMENT "Creating directory: ${FIREBIRD_GEN_DIR}/boot/${DIR}"
        VERBATIM
    )
    add_custom_command(
        OUTPUT "${FIREBIRD_GEN_DIR}/main/${DIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${FIREBIRD_GEN_DIR}/main/${DIR}"
        COMMENT "Creating directory: ${FIREBIRD_GEN_DIR}/main/${DIR}"
        VERBATIM
    )
endforeach()

add_custom_command(
    OUTPUT "${FIREBIRD_GEN_DIR}/dbs"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${FIREBIRD_GEN_DIR}/dbs"
    COMMENT "Creating directory: ${FIREBIRD_GEN_DIR}/dbs"
    VERBATIM
)
add_custom_command(
    OUTPUT "${FIREBIRD_GEN_DIR}/include"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${FIREBIRD_GEN_DIR}/include"
    COMMENT "Creating directory: ${FIREBIRD_GEN_DIR}/include"
    VERBATIM
)

################################################################################
# functions
################################################################################
macro(_fetch)
    if("${ARG_FLG}" STREQUAL "OUTPUT")
        set(ARG_OUTPUT "${ARG_BUF}")
    elseif("${ARG_FLG}" STREQUAL "DEPENDS")
        set(ARG_DEPENDS "${ARG_BUF}")
    elseif("${ARG_FLG}" STREQUAL "WORKING_DIRECTORY")
        set(ARG_WORKING_DIRECTORY "${ARG_BUF}")
    elseif("${ARG_FLG}" STREQUAL "SHELL")
        list(POP_FRONT ARG_BUF ARG_COND)
        if(DEFINED "${ARG_COND}")
            set(ARG_SHELL "${ARG_BUF}")
        endif()
    elseif("${ARG_FLG}" STREQUAL "COMMAND")
        list(POP_FRONT ARG_BUF ARG_COND)
        if(DEFINED "${ARG_COND}")
            list(JOIN ARG_BUF " " ARG_BUF)
            list(APPEND ARG_COMMAND "${ARG_BUF}")
        endif()  
    elseif("${ARG_FLG}" STREQUAL "COMMENT")
        set(ARG_COMMENT "${ARG_BUF}")
    endif()

    set(ARG_BUF "")
endmacro()

# fb_add_custom_command
#   OUTPUT  <files>
#   DEPENDS <files>
#   WORKING_DIRECTORY   <directory>
#   SHELL   <commands>
#   COMMAND <commands>
#   COMMENT <message>
#   VERBATIM
function(fb_add_custom_command)
    # 引数のパース
    set(ARG_FLG "")
    math(EXPR ARG_COUNT "${ARGC} - 1")
    foreach(ARGI RANGE 0 ${ARG_COUNT})
        if("${ARGV${ARGI}}" STREQUAL "OUTPUT")
            _fetch()
            set(ARG_FLG "OUTPUT")
        elseif("${ARGV${ARGI}}" STREQUAL "DEPENDS")
            _fetch()
            set(ARG_FLG "DEPENDS")
        elseif("${ARGV${ARGI}}" STREQUAL "WORKING_DIRECTORY")
            _fetch()
            set(ARG_FLG "WORKING_DIRECTORY")
        elseif("${ARGV${ARGI}}" STREQUAL "SHELL")
            _fetch()
            set(ARG_FLG "SHELL")
        elseif("${ARGV${ARGI}}" STREQUAL "COMMAND")
            _fetch()
            set(ARG_FLG "COMMAND")
        elseif("${ARGV${ARGI}}" STREQUAL "COMMENT")
            _fetch()
            set(ARG_FLG "COMMENT")
        elseif("${ARGV${ARGI}}" STREQUAL "VERBATIM")
            _fetch()
            set(ARG_FLG "VERBATIM")
            set(ARG_VERBATIM "VERBATIM")
        elseif(ARG_FLG STREQUAL "")
            message(FATAL_ERROR)
        else()
            list(APPEND "ARG_BUF" "${ARGV${ARGI}}")
        endif()
    endforeach()
    _fetch()

    # チェック
    if(NOT ARG_SHELL)
        message(FATAL_ERROR "NOT SPECIFIED SHELL")
    elseif(NOT ARG_COMMAND)
        message(FATAL_ERROR "NOT SPECIFIED COMMANDS")
    endif()

    # コマンドの組み立て
    list(JOIN ARG_COMMAND " && " ALL_COMMAND)

    add_custom_command(
        OUTPUT
            ${ARG_OUTPUT}
        DEPENDS
            ${ARG_DEPENDS}
        WORKING_DIRECTORY
            ${ARG_WORKING_DIRECTORY}
        COMMAND
            ${ARG_SHELL} "${ALL_COMMAND}"
        COMMENT
            ${ARG_COMMENT}
        ${ARG_VERBATIM}
    )
endfunction()
# for fb_add_custom_command
set(COMMON true)

# fb_preprocess
function(fb_preprocess build dir file gpre_opt)
    if(${build} STRLESS_EQUAL "boot")
        set(GPRE_EXE "$<TARGET_FILE:gpre_boot>")
        set(GPRE_DIR "$<TARGET_FILE_DIR:gpre_boot>")
        set(GPRE_DEPS "")
    else()
        set(GPRE_EXE "${FIREBIRD_EXEC_DIR}/boot/bin/gpre${CMAKE_EXECUTABLE_SUFFIX}")
        set(GPRE_DIR "${FIREBIRD_EXEC_DIR}/boot/bin")
        set(GPRE_DEPS
            ${BOOT_EXECUTION_DEPS}
            "${FIREBIRD_GEN_DIR}/dbs/yachts.lnk"
            "${FIREBIRD_GEN_DIR}/dbs/SECURITY.FDB"
            "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB"
            "${FIREBIRD_GEN_DIR}/dbs/HELP.FDB"
        )
    endif()

    fb_add_custom_command(
        OUTPUT
            "${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.cpp"
        DEPENDS
            "${FIREBIRD_SOURCE_DIR}/src/${dir}/${file}.epp"
            "${FIREBIRD_GEN_DIR}/${build}/${dir}"
            "${FIREBIRD_GEN_DIR}/dbs"
            "${GPRE_EXE}"
            ${GPRE_DEPS}
        WORKING_DIRECTORY "${GPRE_DIR}"
        SHELL WIN32 pwsh.exe -ExecutionPolicy Bypass -Command
        SHELL UNIX bash -c
        COMMAND APPLE
            "export DYLD_FALLBACK_LIBRARY_PATH='${ICU_LIB_PATH}'"
        COMMAND WIN32
            "$mutex = New-Object -TypeName 'System.Threading.Mutex' -ArgumentList @($false, 'Global\\firebird_gpre')$<SEMICOLON>"
            "[void] $mutex.WaitOne()$<SEMICOLON>"
            "try {"
                "& '${GPRE_EXE}' $<JOIN:${gpre_opt}, > '${FIREBIRD_SOURCE_DIR}/src/${dir}/${file}.epp' '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.gen' -b '${FIREBIRD_GEN_DIR}/dbs/'"
            "} finally {"
                "[void] $mutex.ReleaseMutex()"
            "}"
        COMMAND WIN32
            "if (-not (Test-Path -Path '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.cpp') -or"
            "(Compare-Object -ReferenceObject $(Get-Content '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.gen') -DifferenceObject $(Get-Content '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.cpp'))) {"
                "Move-Item -Force -Path '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.gen' -Destination '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.cpp'"
            "} else {"
                "Remove-Item -Path '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.gen'"
            "}"
        COMMAND UNIX
            "{ flock '${FIREBIRD_GEN_DIR}/gpre.lock' '${GPRE_EXE}' $<JOIN:${gpre_opt}, > '${FIREBIRD_SOURCE_DIR}/src/${dir}/${file}.epp' '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.gen' -b '${FIREBIRD_GEN_DIR}/dbs/'$<SEMICOLON> }"
        COMMAND UNIX
            "if !(test -f '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.cpp') ||"
            "!($(${CMAKE_COMMAND} -E compare_files '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.gen' '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.cpp'))$<SEMICOLON> then"
                "mv '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.gen' '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.cpp'$<SEMICOLON>"
            "else"
                "rm '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.gen'$<SEMICOLON>"
            "fi"
        COMMENT "Processing ${build}: ${FIREBIRD_SOURCE_DIR}/src/${dir}/${file}.epp"
        VERBATIM
    )
    set_source_files_properties(
        "${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.cpp"
        PROPERTIES GENERATED TRUE
    )
endfunction()

# gpre
add_custom_command(
    OUTPUT "${FIREBIRD_EXEC_DIR}/boot/bin/gpre${CMAKE_EXECUTABLE_SUFFIX}"
    DEPENDS
        gpre_main
        "$<TARGET_PROPERTY:yvalve_boot,FB_DEPLOY_PATH>"
        "$<TARGET_PROPERTY:engine_boot,FB_DEPLOY_PATH>"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:gpre_main>" "${FIREBIRD_EXEC_DIR}/boot/bin/gpre${CMAKE_EXECUTABLE_SUFFIX}"
    VERBATIM
)

################################################################################
# definitions(boot)
################################################################################
foreach(PREP_FILE IN ITEMS
    "backup"
    "restore"
    "OdsDetection")

    fb_preprocess("boot" "burp" "${PREP_FILE}" "-lang_internal;-n;-ids;-ocxx;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "extract"
    "isql"
    "show")

    fb_preprocess("boot" "isql" "${PREP_FILE}" "-lang_internal;-n;-ids;-ocxx")
endforeach()

foreach(PREP_FILE IN ITEMS
    "dba")

    fb_preprocess("boot" "utilities/gstat" "${PREP_FILE}" "-lang_internal;-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "alice_meta")

    fb_preprocess("boot" "alice" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "array"
    "blob")

    fb_preprocess("boot" "yvalve" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "metd"
    "DdlNodes"
    "PackageNodes")

    fb_preprocess("boot" "dsql" "${PREP_FILE}" "-n;-ids;-gds_cxx")
endforeach()

foreach(PREP_FILE IN ITEMS
    "gpre_meta")

    fb_preprocess("boot" "gpre/std" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "dfw"
    "dpm"
    "dyn_util"
    "fun"
    "grant"
    "ini"
    "met"
    "scl"
    "Function")

    fb_preprocess("boot" "jrd" "${PREP_FILE}" "-n;-ids;-gds_cxx")
endforeach()

foreach(PREP_FILE IN ITEMS
    "stats")

    fb_preprocess("boot" "utilities" "${PREP_FILE}" "-n;-m")
endforeach()

################################################################################
# definitions(main)
################################################################################
foreach(PREP_FILE IN ITEMS
    "alice_meta")

    fb_preprocess("main" "alice" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "LegacyManagement")

    fb_preprocess("main" "auth/SecurityDatabase" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "backup"
    "restore"
    "OdsDetection")

    fb_preprocess("main" "burp" "${PREP_FILE}" "-n;-ids;-ocxx;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "array"
    "blob")

    fb_preprocess("main" "yvalve" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "metd"
    "DdlNodes"
    "PackageNodes")

    fb_preprocess("main" "dsql" "${PREP_FILE}" "-n;-ids;-gds_cxx")
endforeach()

foreach(PREP_FILE IN ITEMS
    "gpre_meta")

    fb_preprocess("main" "gpre/std" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "dfw"
    "dpm"
    "dyn_util"
    "fun"
    "grant"
    "ini"
    "met"
    "scl"
    "Function")

    fb_preprocess("main" "jrd" "${PREP_FILE}" "-n;-ids;-gds_cxx")
endforeach()

foreach(PREP_FILE IN ITEMS
    "codes")

    fb_preprocess("main" "misc" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "build_file")

    fb_preprocess("main" "msgs" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "help"
    "meta"
    "proc"
    "show")

    fb_preprocess("main" "qli" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "extract"
    "isql"
    "show")

    fb_preprocess("main" "isql" "${PREP_FILE}" "-n;-ids;-ocxx")
endforeach()

foreach(PREP_FILE IN ITEMS
    "dba")

    fb_preprocess("main" "utilities/gstat" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "stats")

    fb_preprocess("main" "utilities" "${PREP_FILE}" "-n;-m")
endforeach()

################################################################################
# databases
################################################################################
fb_add_custom_command(
    OUTPUT
        "${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB"
        "${FIREBIRD_GEN_DIR}/dbs/SECURITY.FDB"
    DEPENDS
        "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>"
        ${BOOT_EXECUTION_DEPS}
        "${FIREBIRD_GEN_DIR}/dbs"
        "${FIREBIRD_SOURCE_DIR}/src/dbs/security.sql"
    WORKING_DIRECTORY "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_DIR>"
    SHELL WIN32 pwsh.exe -ExecutionPolicy Bypass -Command
    SHELL UNIX bash -c
    COMMAND APPLE
        "export DYLD_FALLBACK_LIBRARY_PATH='${ICU_LIB_PATH}'"
    COMMAND COMMON
        ${CMAKE_COMMAND} -E rm -f "${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB" "${FIREBIRD_GEN_DIR}/dbs/SECURITY.FDB"
    COMMAND WIN32 
        "string[] $sql = @(\"CREATE DATABASE '${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB' PAGE_SIZE 8192$<SEMICOLON>\")$<SEMICOLON>"
        "$sql += (Get-Content -Path '${FIREBIRD_SOURCE_DIR}/src/dbs/security.sql')$<SEMICOLON>"
        "Write-Output $sql | $<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>$<SEMICOLON>"
    COMMAND UNIX
        "echo \"CREATE DATABASE '${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB' PAGE_SIZE 8192$<SEMICOLON>\" | "
        "cat - '${FIREBIRD_SOURCE_DIR}/src/dbs/security.sql' | "
        "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>"
    COMMAND COMMON
        ${CMAKE_COMMAND} -E copy "${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB" "${FIREBIRD_GEN_DIR}/dbs/SECURITY.FDB"
    COMMENT "Create SECURITY4.FDB"
    VERBATIM
)

fb_add_custom_command(
    OUTPUT
        "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB"
        "${FIREBIRD_GEN_DIR}/dbs/yachts.lnk"
    DEPENDS
        "$<TARGET_PROPERTY:gbak_boot,FB_DEPLOY_PATH>"
        ${BOOT_EXECUTION_DEPS}
        "${FIREBIRD_GEN_DIR}/dbs"
        "${FIREBIRD_SOURCE_DIR}/builds/misc/metadata.gbak"
    WORKING_DIRECTORY "$<TARGET_PROPERTY:gbak_boot,FB_DEPLOY_DIR>"
    SHELL WIN32 pwsh.exe -ExecutionPolicy Bypass -Command
    SHELL UNIX bash -c
    COMMAND APPLE
        "export DYLD_FALLBACK_LIBRARY_PATH='${ICU_LIB_PATH}'"
    COMMAND COMMON
        ${CMAKE_COMMAND} -E rm -f "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB" "${FIREBIRD_GEN_DIR}/dbs/yachts.lnk"
    COMMAND COMMON
        "$<TARGET_PROPERTY:gbak_boot,FB_DEPLOY_PATH>" -r "${FIREBIRD_SOURCE_DIR}/builds/misc/metadata.gbak" "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB"
    COMMAND COMMON
        ${CMAKE_COMMAND} -E copy "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB" "${FIREBIRD_GEN_DIR}/dbs/yachts.lnk"
    COMMENT "Create METADATA.FDB"
    VERBATIM
)

fb_add_custom_command(
    OUTPUT
        "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB"
    DEPENDS
        "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>"
        ${BOOT_EXECUTION_DEPS}
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
    WORKING_DIRECTORY "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_DIR>"
    SHELL WIN32 pwsh.exe -ExecutionPolicy Bypass -Command
    SHELL UNIX bash -c
    COMMAND APPLE
        "export DYLD_FALLBACK_LIBRARY_PATH='${ICU_LIB_PATH}'"
    COMMAND COMMON
        ${CMAKE_COMMAND} -E rm -f "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB"
    COMMAND WIN32
        "Write-Output \"CREATE DATABASE '${FIREBIRD_GEN_DIR}/dbs/MSG.FDB' PAGE_SIZE 8192$<SEMICOLON>\" | $<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>$<SEMICOLON>"
    COMMAND UNIX
        "echo \"CREATE DATABASE '${FIREBIRD_GEN_DIR}/dbs/MSG.FDB' PAGE_SIZE 8192$<SEMICOLON>\" | $<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>"
    COMMAND COMMON
        "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/msg.sql"
    COMMAND COMMON
        "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/facilities2.sql"
    COMMAND COMMON
        "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/sqlstates.sql"
    COMMAND COMMON
        "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/locales.sql"
    COMMAND COMMON
        "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/history2.sql"
    COMMAND COMMON
        "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/messages2.sql"
    COMMAND COMMON
        "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/symbols2.sql"
    COMMAND COMMON
        "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/system_errors2.sql"
    COMMAND COMMON
        "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/transmsgs.fr_FR2.sql"
    COMMAND COMMON
        "$<TARGET_PROPERTY:isql_boot,FB_DEPLOY_PATH>" -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/transmsgs.de_DE2.sql"
    COMMENT "Create MSG.FDB"
    VERBATIM
)

fb_add_custom_command(
    OUTPUT
        "${FIREBIRD_GEN_DIR}/dbs/HELP.FDB"
    DEPENDS
        "$<TARGET_PROPERTY:gbak_boot,FB_DEPLOY_PATH>"
        ${BOOT_EXECUTION_DEPS}
        "${FIREBIRD_GEN_DIR}/dbs"
        "${FIREBIRD_SOURCE_DIR}/builds/misc/help.gbak"
    WORKING_DIRECTORY "$<TARGET_PROPERTY:gbak_boot,FB_DEPLOY_DIR>"
    SHELL WIN32 pwsh.exe -ExecutionPolicy Bypass -Command
    SHELL UNIX bash -c
    COMMAND APPLE
        "export DYLD_FALLBACK_LIBRARY_PATH='${ICU_LIB_PATH}'"
    COMMAND COMMON
        ${CMAKE_COMMAND} -E rm -f "${FIREBIRD_GEN_DIR}/dbs/HELP.FDB"
    COMMAND COMMON
        "$<TARGET_PROPERTY:gbak_boot,FB_DEPLOY_PATH>" -r "${FIREBIRD_SOURCE_DIR}/builds/misc/help.gbak" "${FIREBIRD_GEN_DIR}/dbs/HELP.FDB"
    COMMENT "Create HELP.FDB"
    VERBATIM
)

################################################################################
# messages/codes
################################################################################
add_custom_command(
    OUTPUT "${FIREBIRD_GEN_DIR}/main/firebird.msg"
    DEPENDS
        "$<TARGET_PROPERTY:build_msg_main,FB_DEPLOY_PATH>"
        ${MAIN_EXECUTION_DEPS}
        "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB"
    WORKING_DIRECTORY "$<TARGET_PROPERTY:build_msg_main,FB_DEPLOY_DIR>"
    COMMAND "$<TARGET_PROPERTY:build_msg_main,FB_DEPLOY_PATH>" -D "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -p "${FIREBIRD_GEN_DIR}/main/" -f firebird.msg
    COMMENT "Building message file..."
    VERBATIM
)
# TODO: 仮
#fb_add_custom_target(test_codes ALL
#    DEPENDS
#        "$<TARGET_PROPERTY:codes_main,FB_DEPLOY_PATH>"
#        ${MAIN_EXECUTION_DEPS}
#    WORKING_DIRECTORY "$<TARGET_PROPERTY:codes_main,FB_DEPLOY_DIR>"
#    SHELL WIN32 pwsh.exe -ExecutionPolicy Bypass -Command
#    SHELL UNIX bash -c
#    COMMAND APPLE
#        "export DYLD_FALLBACK_LIBRARY_PATH='${ICU_LIB_PATH}'"
#    COMMAND COMMON
#        "$<TARGET_PROPERTY:codes_main,FB_DEPLOY_PATH>" "${FIREBIRD_SOURCE_DIR}/src/include/gen" "${FIREBIRD_SOURCE_DIR}/lang_helpers"
#    COMMENT "Building codes header..."
#    VERBATIM
#)
