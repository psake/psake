BeforeDiscovery {
    if ($null -eq $env:BHProjectName) {
        .\build.ps1 -Task Build
    }
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"

    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}

Describe 'Write-BuildAnnotation' {

    Context 'Annotation string format' {

        It 'Error with full position emits correct annotation string' {
            Mock -CommandName Write-Host -ModuleName psake
            InModuleScope psake {
                $script:CurrentOutputFormat = 'Annotated'
                Write-BuildAnnotation -Severity 'error' `
                    -File 'C:\build\test.ps1' -Line 42 -Column 5 `
                    -Title 'MyTask' -Message 'Something failed'
            }
            # Colon in C:\ is escaped to %3A per GitHub Actions escapeProperty spec
            Should -Invoke -CommandName Write-Host -ModuleName psake -Times 1 -Exactly `
                -ParameterFilter {
                    $Object -eq '::error file=C%3A\build\test.ps1,line=42,col=5,title=MyTask::Something failed'
                }
        }

        It 'Warning with no file/line/col emits only title and message' {
            Mock -CommandName Write-Host -ModuleName psake
            InModuleScope psake {
                $script:CurrentOutputFormat = 'Annotated'
                Write-BuildAnnotation -Severity 'warning' -Title 'TaskName' -Message 'a warning message'
            }
            Should -Invoke -CommandName Write-Host -ModuleName psake -Times 1 -Exactly `
                -ParameterFilter {
                    $Object -eq '::warning title=TaskName::a warning message'
                }
        }

        It 'Message with newlines escapes them to %0A' {
            Mock -CommandName Write-Host -ModuleName psake
            InModuleScope psake {
                $script:CurrentOutputFormat = 'Annotated'
                Write-BuildAnnotation -Severity 'error' -Message "line1`nline2"
            }
            Should -Invoke -CommandName Write-Host -ModuleName psake -Times 1 -Exactly `
                -ParameterFilter {
                    $Object -match '%0A' -and $Object -notmatch "line1`nline2"
                }
        }

        It 'File path with colon escapes it to %3A' {
            Mock -CommandName Write-Host -ModuleName psake
            InModuleScope psake {
                $script:CurrentOutputFormat = 'Annotated'
                Write-BuildAnnotation -Severity 'error' -File 'D:\src\app.ps1' -Message 'test'
            }
            Should -Invoke -CommandName Write-Host -ModuleName psake -Times 1 -Exactly `
                -ParameterFilter {
                    $Object -match 'file=D%3A\\src\\app\.ps1' -and $Object -notmatch 'file=D:\\src'
                }
        }

        It 'File path with comma escapes it to %2C' {
            Mock -CommandName Write-Host -ModuleName psake
            InModuleScope psake {
                $script:CurrentOutputFormat = 'Annotated'
                Write-BuildAnnotation -Severity 'error' -File 'path,with,commas.ps1' -Message 'test'
            }
            Should -Invoke -CommandName Write-Host -ModuleName psake -Times 1 -Exactly `
                -ParameterFilter {
                    $Object -match 'file=path%2Cwith%2Ccommas' -and $Object -notmatch 'file=path,with'
                }
        }

        It 'Title with newlines escapes them to %0A and %0D' {
            Mock -CommandName Write-Host -ModuleName psake
            InModuleScope psake {
                $script:CurrentOutputFormat = 'Annotated'
                Write-BuildAnnotation -Severity 'error' -Title "line1`r`nline2" -Message 'test'
            }
            Should -Invoke -CommandName Write-Host -ModuleName psake -Times 1 -Exactly `
                -ParameterFilter {
                    $Object -match '%0D%0A' -and $Object -notmatch "title=line1`r`nline2"
                }
        }

        It 'Title with comma escapes it to %2C' {
            Mock -CommandName Write-Host -ModuleName psake
            InModuleScope psake {
                $script:CurrentOutputFormat = 'Annotated'
                Write-BuildAnnotation -Severity 'error' -Title 'Build,Deploy' -Message 'test'
            }
            Should -Invoke -CommandName Write-Host -ModuleName psake -Times 1 -Exactly `
                -ParameterFilter {
                    $Object -match '%2C' -and $Object -notmatch 'title=Build,Deploy'
                }
        }

        It 'Title with colon escapes it to %3A' {
            Mock -CommandName Write-Host -ModuleName psake
            InModuleScope psake {
                $script:CurrentOutputFormat = 'Annotated'
                Write-BuildAnnotation -Severity 'error' -Title 'Build:Release' -Message 'test'
            }
            Should -Invoke -CommandName Write-Host -ModuleName psake -Times 1 -Exactly `
                -ParameterFilter {
                    $Object -match '%3A'
                }
        }

        It 'Omits zero Line and Column fields' {
            Mock -CommandName Write-Host -ModuleName psake
            InModuleScope psake {
                $script:CurrentOutputFormat = 'Annotated'
                Write-BuildAnnotation -Severity 'error' -File 'build.ps1' -Line 0 -Column 0 -Message 'test'
            }
            Should -Invoke -CommandName Write-Host -ModuleName psake -Times 1 -Exactly `
                -ParameterFilter {
                    $Object -notmatch 'line=' -and $Object -notmatch 'col='
                }
        }

        It 'Produces output in GitHubActions format' {
            Mock -CommandName Write-Host -ModuleName psake
            InModuleScope psake {
                $script:CurrentOutputFormat = 'GitHubActions'
                Write-BuildAnnotation -Severity 'error' -File 'test.ps1' -Line 1 -Message 'test'
            }
            Should -Invoke -CommandName Write-Host -ModuleName psake -Times 1 -Exactly
        }

        It 'Produces no output in Default format' {
            Mock -CommandName Write-Host -ModuleName psake
            InModuleScope psake {
                $script:CurrentOutputFormat = 'Default'
                Write-BuildAnnotation -Severity 'error' -File 'test.ps1' -Line 1 -Message 'test'
            }
            Should -Invoke -CommandName Write-Host -ModuleName psake -Times 0
        }

        It 'Produces no output in JSON format' {
            Mock -CommandName Write-Host -ModuleName psake
            InModuleScope psake {
                $script:CurrentOutputFormat = 'JSON'
                Write-BuildAnnotation -Severity 'error' -Message 'test'
            }
            Should -Invoke -CommandName Write-Host -ModuleName psake -Times 0
        }
    }

    Context 'OutputFormat env-var fallback and integration' {
        BeforeAll {
            $script:specFolder = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'specs'
            $psake.run_by_psake_build_tester = $true
        }

        AfterEach {
            Remove-Item Env:\PSAKE_OUTPUT_FORMAT -ErrorAction Ignore
        }

        It 'Env-var PSAKE_OUTPUT_FORMAT=Annotated activates annotation output' {
            $env:PSAKE_OUTPUT_FORMAT = 'Annotated'
            $buildFile = Join-Path $script:specFolder 'annotated_output_format_failing_task_should_fail.ps1'
            $output = Invoke-Psake -BuildFile $buildFile -NoLogo 6>&1 | Out-String
            $output | Should -Match '::error'
        }

        It 'Env-var is ignored when -OutputFormat Default is passed explicitly' {
            $env:PSAKE_OUTPUT_FORMAT = 'Annotated'
            $buildFile = Join-Path $script:specFolder 'annotated_output_format_failing_task_should_fail.ps1'
            $output = Invoke-Psake -BuildFile $buildFile -NoLogo -OutputFormat Default 6>&1 | Out-String
            # Bare ::error lines (without file=) would come from Write-BuildMessage;
            # neither those nor positioned ::error file= lines should appear in Default mode
            $output | Should -Not -Match '::error file='
            $output | Should -Not -Match '::error::'
        }

        It 'Annotated mode emits both human-readable output and annotation lines' {
            $buildFile = Join-Path $script:specFolder 'annotated_output_format_failing_task_should_fail.ps1'
            $output = Invoke-Psake -BuildFile $buildFile -NoLogo -OutputFormat Annotated 6>&1 | Out-String
            # Human-readable error text is present (the formatted error message)
            $output | Should -Not -BeNullOrEmpty
            # Positioned annotation line is also present
            $output | Should -Match '::error'
        }

        It 'Default mode emits no annotation lines' {
            $buildFile = Join-Path $script:specFolder 'annotated_output_format_failing_task_should_fail.ps1'
            $output = Invoke-Psake -BuildFile $buildFile -NoLogo -OutputFormat Default 6>&1 | Out-String
            $output | Should -Not -Match '::error file='
            $output | Should -Not -Match '::error::'
        }

        It 'Invalid env-var value falls back to Default (no annotations)' {
            $env:PSAKE_OUTPUT_FORMAT = 'NotAValidFormat'
            $buildFile = Join-Path $script:specFolder 'annotated_output_format_failing_task_should_fail.ps1'
            $output = Invoke-Psake -BuildFile $buildFile -NoLogo 6>&1 | Out-String
            $output | Should -Not -Match '::error file='
            $output | Should -Not -Match '::error::'
        }
    }
}
