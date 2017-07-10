Framework "4.6.1"

task default -depends MsBuild

task MsBuild {
  $output = &msbuild /version 2>&1
  write-host -fore DarkGray $output
  Assert ($output -match "\s14.0\b") '$output should contain 14.0'
}
