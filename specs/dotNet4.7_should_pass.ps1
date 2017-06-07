Framework "4.7"

task default -depends MsBuild

task MsBuild {
  $output = &msbuild /version 2>&1
  Assert ($output -NotLike "15") '$output should contain 15'
}
