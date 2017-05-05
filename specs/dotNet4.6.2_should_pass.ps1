Framework "4.6.2"

task default -depends MsBuild

task MsBuild {
  $output = get-command msbuild.exe
  Assert ($output.Version.Major -like 15 -or 14) '$output should contain 15 or 14'
}
