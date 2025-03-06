Task default -depends TaskA

Task TaskA {
    Write-PsakeOutput -Output "Heading" -OutputType "Heading"
    Write-PsakeOutput -Output "Default" -OutputType "Default"
    Write-PsakeOutput -Output "Debug" -OutputType "Debug"
    Write-PsakeOutput -Output "Warning" -OutputType "Warning"
    Write-PsakeOutput -Output "Error" -OutputType "Error"
    Write-PsakeOutput -Output "Success" -OutputType "Success"
}
