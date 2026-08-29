Properties {
    Write-Host 'QUIET_PROPERTIES_HOST_STREAM_MARKER'
    Write-Warning 'QUIET_PROPERTIES_WARNING_STREAM_MARKER'
}
FormatTaskName {
    param($taskName)
    Write-Host "QUIET_TASK_NAME_MARKER_$taskName"
}


Task default -Depends Noisy

Task Noisy {
    Write-Output 'QUIET_SUCCESS_STREAM_MARKER'
    Write-Host 'QUIET_HOST_STREAM_MARKER'
    Write-Warning 'QUIET_WARNING_STREAM_MARKER'
    Write-Information 'QUIET_INFORMATION_STREAM_MARKER'
    Write-Verbose 'QUIET_VERBOSE_STREAM_MARKER'
    Write-Debug 'QUIET_DEBUG_STREAM_MARKER'
}
