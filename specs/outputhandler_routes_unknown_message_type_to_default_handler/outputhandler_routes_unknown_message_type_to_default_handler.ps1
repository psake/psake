task default -depends TaskA

task TaskA {
    WriteOutput "heading" "heading"
    WriteOutput "default" "default"
    WriteOutput "debug" "debug"
    WriteOutput "warning" "warning"
    WriteOutput "error" "error"
    WriteOutput "success" "success"
    WriteOutput "other" "other"
}
