$psake.use_exit_on_error = $true

task default -depends throw_error

task throw_error {
  throw "Error"
}
