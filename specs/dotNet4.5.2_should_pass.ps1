Framework "4.5.2"

task default -depends MsBuild

task MsBuild {
  $output = get-command msbuild.exe
  Assert ($output.Version.Major -like 12 -or 14) '$output should contain 12 or 14'
}
