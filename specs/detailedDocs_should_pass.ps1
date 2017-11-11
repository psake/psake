
Task default -depends CheckDetailedDocs

Task CheckDetailedDocs {

    $doc = (Invoke-psake .\nested\docs.ps1 -detailedDocs -nologo | Out-String).Trim()

    Assert ($doc.Length -eq 611) "Unexpected simple doc: $doc"
}
