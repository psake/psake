task default -depends MSBuildWithError

task MSBuildWithError {
    if ( $IsOSX -OR $IsLinux ) {}
    else {
        msbuild ThisFileDoesNotExist.sln
    }
}