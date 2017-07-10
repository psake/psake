Framework '4.0'

task default -depends MsBuild

task MsBuild {
    if ( $IsOSX -OR $IsLinux ) {}
    else {
        exec { msbuild /version }
    }
}
