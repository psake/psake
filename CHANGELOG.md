# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [4.9.1] Unreleased

### Fixed

- [**#296**](https://github.com/psake/psake/pull/296) Fix `-ContinueOnError` functionality (via [@UberDoodles](https://github.com/UberDoodles))

## [4.9.0] 2019-09-21

### Fixed

- Fix hashtable references so strict mode works when set in the psakeFile.
- [**#283**](https://github.com/psake/psake/pull/283) Fix path issue for msbuild is VS 2019. (via [@jaymclain](https://github.com/jaymclain))
- [**#287**](https://github.com/psake/psake/pull/287) In `Exec` function, always rerun command in specified location (via [@tiksn](https://github.com/tiksn) and [@UberDoodles](https://github.com/UberDoodles))

### Added

- [**#281**](https://github.com/psake/psake/pull/281) Support for .Net 4.8 in `Framework` function (via [@granit1986](https://github.com/granit1986))
- [**#285**](https://github.com/psake/psake/pull/285) Add BuildSetup and BuildTearDown functions that are executed at the beginning of the build (before the first task), and at the end of the build (after either all tasks have completed, or a task has failed). (via [@UberDoodles](https://github.com/UberDoodles))

## [4.8.0] 2019-04-23

### Features

- Add support for loading in tasks contained in PowerShell modules

### Improvements

- [**#267**](https://github.com/psake/psake/pull/267) Add wrapper script for Linux and macOS. (via [@dermeister0](https://github.com/dermeister0))

- [**#268**](https://github.com/psake/psake/pull/268) Allow more granularity when specifying versions of modules to load when referencing shared tasks (via [@RandomNoun7](https://github.com/RandomNoun7))

- [**#274**](https://github.com/psake/psake/pull/274) Add support for Visual Studio 2019 and MSBuild 16.0. (via [@petedavis](https://github.com/petedavis))

- [**#276**](https://github.com/psake/psake/pull/276) Pass task detail including error information into TaskSetup and TaskTearDown. (via [@davidalpert](https://github.com/davidalpert))

### Fixed

- [**#272**](https://github.com/psake/psake/pull/272) Improve parameter initialization error handling to include the parameter name which caused failure (via [@GreatTeacherBasshead](https://github.com/GreatTeacherBasshead))

## [4.7.4] 2018-09-07

### Fixed

- [**#260**](https://github.com/psake/psake/pull/260) Change the build time report to show individual task durations instead of cumulative (via [@sideproject](https://github.com/sideproject))

- [**#261**](https://github.com/psake/psake/pull/261) Use `$global:lastexitcode` instead of `$lastexitcode` in Exec (via [@gpetrou](https://github.com/gpetrou))

### Improvements

- [**#259**](https://github.com/psake/psake/pull/259) Add $psake.error_message property which contains the error message that cause the build to fail (via [@sideproject](https://github.com/sideproject))

## [4.7.3] 2018-08-11

### Fixed

- Re-apply changes from PR #257 as they apparently were not committed correctly.

## [4.7.2] 2018-08-09

### Improvements

- [**#257**](https://github.com/psake/psake/pull/257) Add support for .Net 4.7.2 (via [@dawoodmm](https://github.com/dawoodmm))

## [4.7.1] 2018-07-03

### Improvements

- [**#244**](https://github.com/psake/psake/pull/244) Update build success message to be more general: psake succeeded (via [@rkeithhill](https://github.com/rkeithhill))
- [**#249**](https://github.com/psake/psake/pull/249) Allow working with preloaded VSSetup module (via [@havranek1024](https://github.com/havranek1024))

### Fixed

- [**#236**](https://github.com/psake/psake/pull/236) Change check for `$IsWindows` so it doesn't generate an error record (via [@rkeithhill](https://github.com/rkeithhill))

## [4.7.0] 2017-11-21

As part of this release we had [13 issues](https://github.com/psake/psake/issues?q=milestone%3Av4.7.0+is%3Aclosed) closed.

### Features

- [**#198**](https://github.com/psake/psake/pull/198) Add support for PowerShell Core on macOS and Linux. (via [@dbroeglin](https://github.com/dbroeglin))

- [**#196**](https://github.com/psake/psake/pull/196) Deprecate default build script name `default.ps1` in favor of `psakefile.ps1`. (via [@glennsarti](https://github.com/glennsarti))

- Remove legacy PowerShell v2 support. PSake now supports v3 and above.

### Improvements

- [**#228**](https://github.com/psake/psake/pull/228) Project structure refactor (via [@devblackops](https://github.com/devblackops))

- [**#227**](https://github.com/psake/psake/pull/227) Ensure postAction and taskTeardown tasks get called after action failure (via [@stephan-dowding](https://github.com/stephan-dowding))

- [**#222**](https://github.com/psake/psake/pull/222) Add support for .Net frameworks 4.6.2, 4.7, and 4.7.1. (via [@rkeithhill](https://github.com/rkeithhill))

- [**#218**](https://github.com/psake/psake/pull/218) Improve Build Time Report by using custom `FormatTaskName` value for header and display task timing at millisecond accuracy instead of microsecond. (via [@theunrepentantgeek](https://github.com/theunrepentantgeek))

- [**#200**](https://github.com/psake/psake/pull/200) Add `WorkingDirectory` parameter to `Exec` function. (via [@DaveSenn](https://github.com/DaveSenn))

- [**#190**](https://github.com/psake/psake/pull/190) Use `WriteColoredOutput` for all task headers. (via [@damianpowell](https://github.com/damianpowell))

## [4.6.0] 2016-03-20

As part of this release we had [6 issues](https://github.com/psake/psake/issues?milestone=6&state=closed) closed.

### Fixed

- [**#149**](https://github.com/psake/psake/pull/149) Using ErrorAction Ignore in PSv3+

### Features

- [**#153**](https://github.com/psake/psake/issues/153) Invoke-psake with option to return documentation should return objects instead of formated string
- [**#147**](https://github.com/psake/psake/pull/147) Added an option '-notr' to disable output of time report.
- [**#143**](https://github.com/psake/psake/issues/143) Publish Psake on PowerShellGallery

### Improvements

- [**#155**](https://github.com/psake/psake/issues/155) Move wiki content to readthedocs
- [**#152**](https://github.com/psake/psake/pull/152) Adding an example for a parallel task
- [**#138**](https://github.com/psake/psake/pull/138) Cleanup MaxRetries and RetryTriggerErrorPattern in the context of Task. (#117 and #103)

## [4.5.0] 2015-12-12

### Improvements

- [**#141**](https://github.com/psake/psake/pull/141) Added support for .NET 4.6.1
