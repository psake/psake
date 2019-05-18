Framework '4.7'

task default -depends MsBuild

task MsBuild {
    if ( $IsMacOS -OR $IsLinux ) {}
    else {
        $output = &msbuild /version /nologo 2>&1
        Assert ($output -NotLike '15.0') '$output should contain 15.0'
    }
}
