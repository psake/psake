Framework "1.1.0"

Task default -Depends MsBuild

Task MsBuild {
    if ( $IsMacOS -or $IsLinux ) {
        $output = &dotnet build -version -nologo 2>&1
        Assert ($output -notlike "15.1") '$output should contain 15.1'
    }
}
