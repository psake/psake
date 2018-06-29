Framework "4.5.1x86"

task default -depends MsBuild

task MsBuild {
    if ( $IsMacOS -OR $IsLinux ) {}
    else {
        $output = &msbuild /version /nologo 2>&1
        Assert ($output -NotLike "12.0") '$output should contain 12.0'
    }
}
