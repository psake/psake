task default -depends CheckAllOutputViaOutputHandler,CheckAllOutputViaOutputHandler_Docs

task CheckAllOutputViaOutputHandler {
    [string[]]$output = Invoke-psake ".\use_writeoutput_function_throughout\use_writeoutput_function_throughout.ps1" -properties @{Property1="A";Property2="B"} -parameters @{Param1="ParamA";Param2="ParamB"} -nologo
    [string[]]$outputNotFromWriteOutput = $output | Where-Object {$_.Substring(0,12) -ne "WriteOutput:"}

    if ($outputNotFromWriteOutput.Length -gt 0) {
        Throw "The following output was not routed via WriteOutput:`n $outputNotFromWriteOutput"
    }
}

task CheckAllOutputViaOutputHandler_Docs {
    [string[]]$output = Invoke-psake ".\use_writeoutput_function_throughout\use_writeoutput_function_throughout.ps1" -nologo -docs
    [string[]]$outputNotFromWriteOutput = $output | Where-Object {$_.Substring(0,12) -ne "WriteOutput:"}

    if ($outputNotFromWriteOutput.Length -gt 0) {
        Throw "The following output was not routed via WriteOutput:`n $outputNotFromWriteOutput"
    }
}
