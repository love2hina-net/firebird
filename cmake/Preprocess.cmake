################################################################################
#
# Pre Processor Definitions
#
################################################################################

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
# fb_preprocess
function(fb_preprocess build dir file gpre_opt)
    if(${build} STRLESS_EQUAL "boot")
        set(GPRE_EXE "$<TARGET_FILE:gpre_boot>")
        set(META_FDB "")
    else()
        set(GPRE_EXE "${FIREBIRD_EXEC_DIR}/boot/gpre.exe")
        set(META_FDB "${FIREBIRD_GEN_DIR}/dbs/yachts.lnk;${FIREBIRD_GEN_DIR}/dbs/SECURITY.FDB;${FIREBIRD_GEN_DIR}/dbs/MSG.FDB;${FIREBIRD_GEN_DIR}/dbs/HELP.FDB")
    endif()

    add_custom_command(
        OUTPUT "${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.cpp"
        DEPENDS
            "${FIREBIRD_SOURCE_DIR}/src/${dir}/${file}.epp"
            "${FIREBIRD_GEN_DIR}/${build}/${dir}"
            "${FIREBIRD_GEN_DIR}/dbs"
            ${GPRE_EXE}
            ${META_FDB}
        COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
            $mutex = New-Object -TypeName 'System.Threading.Mutex' -ArgumentList @($false, 'Global\\firebird_gpre');\
            [void] $mutex.WaitOne();\
            & '${GPRE_EXE}' $<JOIN:${gpre_opt}, >\
            '${FIREBIRD_SOURCE_DIR}/src/${dir}/${file}.epp'\
            '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.gen'\
            -b '${FIREBIRD_GEN_DIR}/dbs/';\
            [void] $mutex.ReleaseMutex();\
            if (-not (Test-Path -Path '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.cpp') -or \
               (Compare-Object -ReferenceObject $(Get-Content '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.gen') -DifferenceObject $(Get-Content '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.cpp'))) {\
                Move-Item -Force -Path '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.gen' -Destination '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.cpp'\
            } else {\
                Remove-Item -Path '${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.gen'\
            }"
        COMMENT "Processing ${build}: ${FIREBIRD_SOURCE_DIR}/src/${dir}/${file}.epp"
        VERBATIM
    )
    set_source_files_properties(
        "${FIREBIRD_GEN_DIR}/${build}/${dir}/${file}.cpp"
        PROPERTIES GENERATED TRUE
    )
endfunction()

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
