Framework "4.6"

task default -depends MsBuild

task MsBuild {
    if ( $IsMacOS -OR $IsLinux ) {}
    else {
        $output = &msbuild /version /nologo 2>&1
        Assert ($output -NotLike "14.0") '$output should contain 14.0'
    }
}
