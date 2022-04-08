# ChatCode
Easy to implement chat message parser for Garry's Mod.

# Examples
```lua
local toparse = "-> **Bold** *Italics* {#F00} **Red and {#0F0} Green Bold Text**"

PrintTable(chatcode(toparse))
```

# Syntax Reference
|Feature|Example|Regex|
|---|---|---|
|Italic Text| `*italics*`|
|Bold Text|   `**bold**`  |
|Superbold|   `***bold and italics***`  |
|Quote|       `-> message`|`$\-\>`| 
|Inline Code| <code>\`print(123)\`</code>|
|Colored Text| `{#F00} Red Text Here` |
|Links|`<https://github.com/garryspins>`|

# API Reference
```lua
-- Structs
Token = {
  istoken:bool, -- Determines whether the token is a text token or not
  token:string, -- The type of token this is
  value:string  -- Value of the token, only really used when token is text
}

ParseItem = {
  text:str,       -- Text of the token
  italics:bool,   -- Is the text italics?
  bold:bool,      -- Is the text bold?
  isquote:bool,   -- Is the text part of a quote message?
  code:bool,      -- Is the text an inline codeblock?
  color:Color|string -- Color when default color, string when user defined
}

-- Main Function
chatcode(str:string) -> table[ParseItem]--: Converts text to ChatCode ParseItems :)

-- Lex Functions
chatcode.lexer.Lex(str:string) -> table[Token]--: Converts the string to a list of tokens
chatcode.lexer.SecondPass(tokens:table[Token]) -> table[Token]--: Runs a second pass over the given tokens, converting *** into one token for example
chatcode.lexer.CheckToken(tokens:table[Token], index:int, is:string) -> bool--: Checks if the token at the given index is the given token type (is)

-- Parsing Methods
chatcode.parser.Parse(tokens:table[Token]) -> table[ParseItem]--: Converts a list of Token's into a list of ParseItem's
chatcode.parser.ParsePass(parsed:table[ParseItem]) -> table[ParseItem]--: Passes over a list of ParseItem's and cleans them up

-- Debug Methods
-- DONT rely on these methods, theyre purely for debugging
chatcode.debug.Print(text:string)--: Lexes, Parses and prints the text given in a way thats useful for development
chatcode.debug.FromHex(hex:string) -> Color--: Converts a hex color to a Color
```
