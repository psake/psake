Framework '4.5.1x86'

Task default -depends MsBuild

Task MsBuild {
  if ( $IsMacOS -OR $IsLinux ) {}
  else {
    $output = &msbuild /version /nologo 2>&1
    Assert ($output -match "\s12.0\b") '$output should contain 12.0'
  }
}
