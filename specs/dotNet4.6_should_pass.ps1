Framework '4.6'

Task default -depends MsBuild

Task MsBuild {
  if ( $IsMacOS -OR $IsLinux ) {}
  else {
    $output = &msbuild /version /nologo 2>&1
    Assert ($output -match "\s14.0\b") '$output should contain 14.0'
  }
}
