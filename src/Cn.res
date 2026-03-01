// Binding to shadcn's cn() utility — merges Tailwind classes safely
@@live

@module("./lib/utils")
external cn: (string, string) => string = "cn"

@module("./lib/utils")
external cn3: (string, string, string) => string = "cn"

@variadic
@module("./lib/utils")
external cnv: array<string> => string = "cn"
