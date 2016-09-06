Framework "4.5.1x86"

task default -depends MsBuild

task MsBuild {
  $output = &msbuild /version 2>&1
  write-host -fore DarkGray $output
  Assert ($output -match "\s12.0\b") '$output should contain 12.0'
}
