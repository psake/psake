Framework "4.7"

task default -depends MsBuild

task MsBuild {
  $output = get-command msbuild.exe
  Assert ($output.Version.Major -eq 15) '$output should contain 15'
}
