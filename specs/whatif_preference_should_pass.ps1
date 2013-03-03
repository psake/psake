Task default -Depends RunWhatIf

Task RunWhatIf {
	Invoke-psake .\nested\whatifpreference.ps1
}
