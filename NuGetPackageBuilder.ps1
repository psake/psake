# Assumes robocopy on the path

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$destDir = "$dir\bin"
if(Test-Path $destDir -PathType container){
	Remove-Item $destDir -Recurse -Force
}

robocopy $dir "$destDir\tools" /E /B /NP /R:0 /W:0 /NJH /NJS /NS /NFL /NDL /XF ".git*" "Nuget*" "*.nupkg"  /XD "%DIR%nuget" "$dir.git" "$destDir"
robocopy $dir "$destDir\tools" /E /B /NP /R:0 /W:0 /NJH /NJS /NS /NFL /NDL /XF ".git*" "Nuget*" "*.nupkg"  /XD "%DIR%nuget" "$dir.git" "$destDir"
robocopy "$dir\nuget" $destDir /E /B /NP /R:0 /W:0 /NJH /NJS /NS /NFL /NDL

.\nuget pack "$destDir\psake.nuspec"