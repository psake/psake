#!/bin/sh
case "$1" in
    --help|-help|-h|"/?")
        powershell -NoProfile -ExecutionPolicy Bypass -Command "& '.\psake.ps1' -help"
        exit
        ;;
esac

powershell -NoProfile -ExecutionPolicy Bypass -Command "& '.\psake.ps1' $@; if (\$psake.build_success -eq \$false) { exit 1 } else { exit 0 }"
exit "$?"
