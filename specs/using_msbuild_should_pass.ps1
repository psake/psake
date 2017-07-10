task default -depends DisplayNotice
task DisplayNotice {
    if ( $IsOSX -OR $IsLinux ) {}
    else {
        exec { msbuild /version }
    }
}