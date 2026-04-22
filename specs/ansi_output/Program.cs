// Writes Console.IsOutputRedirected to the file path in args[0] (if provided).
// Also emits ANSI escape sequences so colored output can be verified visually.
if (args.Length > 0)
{
    File.WriteAllText(args[0], Console.IsOutputRedirected.ToString());
}

Console.Write("\x1b[32m");
Console.WriteLine("[ANSI green] Console.IsOutputRedirected = " + Console.IsOutputRedirected);
Console.Write("\x1b[0m");
