#:package Spectre.Console@0.55.2

using Spectre.Console;

AnsiConsole.MarkupLine("[bold blue]Welcome[/] to [green]Spectre.Console[/]!");

var table = new Table()
    .AddColumn("Feature")
    .AddColumn("Description")
    .AddRow("[green]Markup[/]", "Rich text with colors and styles")
    .AddRow("[blue]Tables[/]", "Structured data display")
    .AddRow("[yellow]Progress[/]", "Spinners and progress bars");
AnsiConsole.Write(table);
