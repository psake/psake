Framework "4.5.1x86"

task default -depends MsBuild

task MsBuild {
  $output = get-command msbuild.exe
  Assert ($output.Version.Major -eq 12 -or $output.Version.Major -eq 14) '$output should contain 12 or 14'
}
