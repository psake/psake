Framework "2.0"

task default -depends MsBuild

task MsBuild {
    if ( $IsOSX -OR $IsLinux ) {
        $output = &dotnet build -version -nologo 2>&1
        Assert ($output -NotLike "15.3") '$output should contain 15.3'
    }
}

