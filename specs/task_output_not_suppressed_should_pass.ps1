Task default -Depends Test

Task Test {
    Write-Output "direct output - should be visible"
    Exec { Write-Output "via Exec - should also be visible" }
}
