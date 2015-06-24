task default -depends Test

task Test -depends Compile, Clean -PreAction {"Pre-Test"} -Action {
  Assert $false "This fails."
} -PostAction {"Post-Test"}

task Compile -depends Clean {
  "Compile"
}

task Clean {
  "Clean"
}
