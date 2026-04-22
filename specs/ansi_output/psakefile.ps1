Task default -Depends TaskWrapped, ExecWrapped

Task TaskWrapped {
    dotnet run --file .\color.cs
}

Task ExecWrapped {
    Exec {
        dotnet run --file .\color.cs
    }
}
