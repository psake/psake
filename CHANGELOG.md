# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [4.7.0] Unreleased

### Improvements

- [**218**](https://github.com/psake/psake/pull/218) Improve Build Time Report by using custom `FormatTaskName` value for header and display task timing at millisecond accuracy instead of microsecond. (via [@theunrepentantgeek](https://github.com/theunrepentantgeek))

- [**190**](https://github.com/psake/psake/pull/190) Use `WriteColoredOutput` for all task headers. (via [@damianpowell](https://github.com/damianpowell))

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
