# Taken with love from @juneb_get_help (https://raw.githubusercontent.com/juneb/PesterTDD/master/Module.Help.Tests.ps1)

BeforeDiscovery {
    function global:FilterOutCommonParams {
        param ($Params)
        $commonParams = [System.Management.Automation.PSCmdlet]::OptionalCommonParameters +
            [System.Management.Automation.PSCmdlet]::CommonParameters
        $params | Where-Object { $_.Name -notin $commonParams } | Sort-Object -Property Name -Unique
    }

    $manifest             = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir            = Join-Path -Path $env:BHProjectPath -ChildPath 'output'
    $outputModDir         = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir      = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"

    # Get module commands
    # Remove all versions of the module from the session. Pester can't handle multiple versions.
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
    $params = @{
        Module      = (Get-Module $env:BHProjectName)
        CommandType = [System.Management.Automation.CommandTypes[]]'Cmdlet, Function' # Not alias
    }
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        $params.CommandType[0] += 'Workflow'
    }
    $commands = Get-Command @params

    ## When testing help, remember that help is cached at the beginning of each session.
    ## To test, restart session.
}

Describe "Test help for <_.Name>" -ForEach $commands {

    BeforeDiscovery {
        # Get command help, parameters, and links
        $command               = $_
        $commandHelp           = Get-Help $command.Name -ErrorAction SilentlyContinue
        $commandParameters     = global:FilterOutCommonParams -Params $command.ParameterSets.Parameters
        $commandParameterNames = $commandParameters.Name
        # $helpLinks             = $commandHelp.relatedLinks.navigationLink.uri
    }

    BeforeAll {
        # These vars are needed in both discovery and test phases so we need to duplicate them here
        $command                = $_
        $commandName            = $_.Name
        $commandHelp            = Get-Help $command.Name -ErrorAction SilentlyContinue
        $commandParameters      = global:FilterOutCommonParams -Params $command.ParameterSets.Parameters
        $commandParameterNames  = $commandParameters.Name
        $helpParameters         = global:FilterOutCommonParams -Params $commandHelp.Parameters.Parameter
        $helpParameterNames     = $helpParameters.Name
    }

    # If help is not found, synopsis in auto-generated help is the syntax diagram
    It 'Help is not auto-generated' {
        $commandHelp.Synopsis | Should -Not -BeLike '*`[`<CommonParameters`>`]*'
    }

    # Should be a description for every function
    It "Has description" {
        $commandHelp.Description | Should -Not -BeNullOrEmpty
    }

    # Should be at least one example
    It "Has example code" {
        ($commandHelp.Examples.Example | Select-Object -First 1).Code | Should -Not -BeNullOrEmpty
    }

    # Should be at least one example description
    It "Has example help" {
        ($commandHelp.Examples.Example.Remarks | Select-Object -First 1).Text | Should -Not -BeNullOrEmpty
    }

    # It "Help link <_> is valid" -ForEach $helpLinks {
    #     (Invoke-WebRequest -Uri $_ -UseBasicParsing).StatusCode | Should -Be '200'
    # }

    Context "Parameter <_.Name>" -Foreach $commandParameters {

        BeforeAll {
            $parameter         = $_
            $parameterName     = $parameter.Name
            $parameterHelp     = $commandHelp.parameters.parameter | Where-Object Name -eq $parameterName
            $parameterHelpType = if ($parameterHelp.ParameterValue) { $parameterHelp.ParameterValue.Trim() }
        }

        # Should be a description for every parameter
        It "Has description" {
            $parameterHelp.Description.Text | Should -Not -BeNullOrEmpty
        }

        # Required value in Help should match IsMandatory property of parameter
        It "Has correct [mandatory] value" {
            $codeMandatory = $_.IsMandatory.toString()
            $parameterHelp.Required | Should -Be $codeMandatory
        }

        # Parameter type in help should match code
        It "Has correct parameter type" {
            $parameterHelpType | Should -Be $parameter.ParameterType.Name
        }
    }

    Context "Test <_> help parameter help for <commandName>" -Foreach $helpParameterNames {

        # Shouldn't find extra parameters in help.
        It "finds help parameter in code: <_>" {
            $_ -in $parameterNames | Should -Be $true
        }
    }
}
