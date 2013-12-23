$framework = '3.5'

task default -depends AspNetCompiler

task AspNetCompiler {
  try {
    aspnet_compiler
  }
  catch [Exception]{
    if ($LastExitCode -ne 1) {
      throw 'Error: Could not execute aspnet_compiler'
    }
  }
}