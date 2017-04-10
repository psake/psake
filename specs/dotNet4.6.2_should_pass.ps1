Framework "4.6.2"

task default -depends MsBuild

task MsBuild {
  $output = &msbuild /version 2>&1
  Assert ($output -NotLike "14.0") '$output should contain 14.0'
}
