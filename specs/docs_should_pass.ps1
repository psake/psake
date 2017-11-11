
Task default -depends CheckDocs

Task CheckDocs {

    $doc = (Invoke-psake .\nested\docs.ps1 -docs -nologo | Out-String).Trim()

    Assert ($doc.Length -eq 621) "Unexpected simple doc: $doc"
}
