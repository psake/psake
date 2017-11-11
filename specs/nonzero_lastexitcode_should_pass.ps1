task default -depends MSBuildWithError

task MSBuildWithError {
    if ( $IsMacOS -OR $IsLinux ) {}
    else {
        msbuild ThisFileDoesNotExist.sln
    }
}
