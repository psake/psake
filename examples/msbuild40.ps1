$framework = "4.0"
# $framework = "4.0x64"

task default -depends ShowMsBuildVersion

task ShowMsBuildVersion {
  msbuild /version
}