task default -depends DisplayNotice
task DisplayNotice {
    if ( $IsMacOS -OR $IsLinux ) {}
    else {
        exec { msbuild /version }
    }
}
