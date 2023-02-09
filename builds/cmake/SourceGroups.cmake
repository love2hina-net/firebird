#include(SourceGroups)

set(SSRC ${FIREBIRD_SOURCE_DIR}/src)
set(BSRC ${CMAKE_BINARY_DIR}/src)

set(EPP_TXT "GPRE files")
set(GEN_TXT "GPRE cpp")

set(_CPP ".*\\.cpp")
set(CPP "${_CPP}$")
set(_EPP ".*\\.(e|epp)")
set(EPP "${_EPP}$")
set(GEN "${_EPP}\\.(boot|master)\\.cpp$")

source_group("${EPP_TXT}" "${EPP}")
source_group("${GEN_TXT}" "${GEN}")
source_group("Resource files" ".*\\.(rc|ico)")

source_group("ALICE files"                  "${SSRC}/alice/${CPP}")
source_group("ALICE files\\${EPP_TXT}"      "${SSRC}/alice/${EPP}")
source_group("ALICE files\\${GEN_TXT}"      "${BSRC}/alice/${GEN}")
#source_group("AUTH files"                   "${SSRC}/auth/.*\\.(cpp|h)")
source_group("AUTH files"                   "${SSRC}/auth/${CPP}")
source_group("BURP files"                   "${SSRC}/burp/${CPP}")
source_group("BURP files\\${EPP_TXT}"       "${SSRC}/burp/${EPP}")
source_group("BURP files\\${GEN_TXT}"       "${BSRC}/burp/${GEN}")
source_group("common"                       "${SSRC}/common/${CPP}")
source_group("classes"                      "${SSRC}/common/classes/${CPP}")
source_group("config"                       "${SSRC}/common/config/${CPP}")
source_group("DSQL"                         "(${SSRC}|${BSRC})/dsql/.*\\.(cpp|y|ske)")
source_group("DSQL\\${EPP_TXT}"             "${SSRC}/dsql/${EPP}")
source_group("DSQL\\${GEN_TXT}"             "${BSRC}/dsql/${GEN}")
source_group("EXTLIB files"                 "${SSRC}/extlib/${CPP}")
source_group("Languages"                    "${SSRC}/gpre/languages/${CPP}")
#source_group("FBRMCLIB files"         FILES  ${SSRC}/gpre/languages/fbrmclib.cpp) gpre_boot, fbrmclib
source_group("GPRE files\\${EPP_TXT}"       "${SSRC}/gpre/std/${EPP}")
source_group("GPRE files\\${GEN_TXT}"       "${BSRC}/gpre/std/${GEN}")
source_group("INTL files"                   "${SSRC}/intl/${CPP}")
source_group("GUARD files"                  "${SSRC}/iscguard/${CPP}")
source_group("ISQL files"                   "${SSRC}/isql/${CPP}")
source_group("ISQL files\\${EPP_TXT}"       "${SSRC}/isql/${EPP}")
source_group("ISQL files\\${GEN_TXT}"       "${BSRC}/isql/${GEN}")
source_group("JRD files"                    "${SSRC}/jrd/${CPP}")
source_group("JRD files\\Data Access"       "${SSRC}/jrd/recsrc/${CPP}")
source_group("JRD files\\EXTDS"             "${SSRC}/jrd/extds/${CPP}")
source_group("JRD files\\${EPP_TXT}"        "${SSRC}/jrd/${EPP}")
source_group("JRD files\\${GEN_TXT}"        "${BSRC}/jrd/${GEN}")
source_group("JRD files\\Trace"             "${SSRC}/jrd/trace/${CPP}")
source_group("Lock"                         "${SSRC}/lock/${CPP}")
source_group("REMOTE files"                 "${SSRC}/remote/${CPP}")
source_group("QLI files"                    "${SSRC}/qli/${CPP}")
source_group("QLI files\\${EPP_TXT}"        "${SSRC}/qli/${EPP}")
source_group("QLI files\\${GEN_TXT}"        "${BSRC}/qli/${GEN}")
source_group("UTILITIES files"              "${SSRC}/utilities/${CPP}")
