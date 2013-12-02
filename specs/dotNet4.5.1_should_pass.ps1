$framework = '4.5.1'

task default -depends MsBuild

task MsBuild {
  exec { msbuild /version }
}
