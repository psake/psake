Framework '4.0x86'

task default -depends MsBuild

task MsBuild {
    if ( $IsMacOS -OR $IsLinux ) {}
    else {
        exec { msbuild /version }
    }
}
