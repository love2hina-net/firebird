
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    # 64 bits
    set(PLATFORM "x64")
    set(RC_ARCH "RC_ARH_x64")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
    # 32 bits
    set(PLATFORM "x86")
    set(RC_ARCH "RC_ARH_x86")
endif()

# gpre
add_custom_command(
    OUTPUT "${FIREBIRD_EXEC_DIR}/boot/gpre.exe"
    DEPENDS
        gpre_main
        "${FIREBIRD_EXEC_DIR}/boot/fbclient.dll"
        "${FIREBIRD_EXEC_DIR}/boot/plugins/engine13.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:gpre_main>" "${FIREBIRD_EXEC_DIR}/boot/gpre.exe"
    VERBATIM
)
