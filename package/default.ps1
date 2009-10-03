include 'psake_packager.ps1'

task default -depends validate-psake,package-psake,deploy-psake