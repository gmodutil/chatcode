--[[License:
    ChatCode
    Copyright (C) 2021 https://github.com/garryspins
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]--

--[[Notes:
    To keep this code as organized as possible
    I've split it up into multiple do blocks,
    this is to make it easy to collapse and
    view everything in an organized way as if 
    it was split up into multiple files.

    All sections are marked with a comment showing
    what they are for.
]]--

--[[Syntax Reference:

    All of these are to be read as valid messages

    Italics:
        *italics*

    Bold:
        **bold**

    Superbold (bold and italics):
        ***superbold***

    Quote:
        -> Quoting Something

    Inline Code:
        `print(123)`

    Colored Text:
        Colored text is handled in 2 ways,

        {#FFF} sets the color for the rest of the block until a new color:
        {#F00} this text is red {#00F} this is blue

        Or you can set by identifier
        {rainbow} rainbow text

    Links:
        <https://github.com/garryspins>

        If not provided http or https then it defaults to https
]]--

do -- Global Initialization
    chatcode = chatcode or {}
    chatcode.lexer = chatcode.lexer or {}
    chatcode.parser = chatcode.parser or {}
    chatcode.debug = chatcode.debug or {}

    setmetatable(chatcode, {__call = function(s, text)
        return s.parser.Parse(s.lexer.Lex(text))
    end })
end

do -- Lexer
    chatcode.lexer.tokens = {
        ["*"] = "star",
        ["-"] = "minus",

        [">"] = "greater",
        ["<"] = "lesser",

        ["`"] = "backtick",
        ["{"] = "lbrace",
        ["}"] = "rbrace",
    }

    function chatcode.lexer.Lex(str)
        str = str:Trim()
        local tokens = {}

        for i = 0, #str do
            local char = str[i]
            local tok = chatcode.lexer.tokens[char]
            local pchar = str[i - 1]

            if tok and (pchar != "\\") then
                table.insert(tokens, {
                    istoken = true,
                    token = tok,
                    value = char
                })
                continue
            end

            local last = tokens[#tokens]

            if not last or last.istoken then
                last = {
                    token = "text",
                    istoken = false,
                    value = ""
                }
                table.insert(tokens, last)
            end

            last.istoken = false

            if char == "\\" then continue end
            last.value = last.value .. char
        end

        return chatcode.lexer.SecondPass(tokens)
    end

    function chatcode.lexer.SecondPass(tokens)
        local new_tokens = {}
        local i = 0

        while i < #tokens do
            i = i + 1

            local token = tokens[i]

            if
                (i == 1 and token.token == "text" and token.value:Trim() == "") or -- Remove initial empty token or empty spaces
                false
            then
                continue
            end

            if token.token == "star" then
                local next1 = chatcode.lexer.CheckToken(tokens, i + 1, "star")
                local next2 = chatcode.lexer.CheckToken(tokens, i + 2, "star")

                local name = "star"
                local stars = "*"
                if next1 and next2 then
                    i = i + 2
                    name = "triplestar"
                    stars = "***"
                elseif next1 then
                    i = i + 1
                    name = "doublestar"
                    stars = "**"
                end

                table.insert(new_tokens, {
                    token = name,
                    value = stars,
                    istoken = true
                })

                continue
            elseif token.token == "minus" and chatcode.lexer.CheckToken(tokens, i + 1, "greater") then
                table.insert(new_tokens, {
                    token = "quote",
                    value = "->",
                    istoken = true
                })

                i = i + 1

                continue
            end

            table.insert(new_tokens, token)
        end

        return new_tokens
    end

    function chatcode.lexer.CheckToken(tokens, index, is)
        if not tokens[index] then return false end

        if tokens[index].token == is then
            return true
        end

        return false
    end
end

do -- Parser
    function chatcode.parser.Parse(tokens)
        local active = {
            isquote = tokens[1].token == "quote",
            italics = false,
            bold = false,
            superbold = false,
            code = false,
            global_color = Color(255, 255, 255),
            current_color = false,

            has_opened = false
        }
        local parsed = {}
        local i = (tokens[1].token == "quote" and 1) or 0

        while i < #tokens do
            i = i + 1

            local token = tokens[i]

            if token.token == "star" then
                active.italics = not active.italics
            elseif token.token == "doublestar" then
                active.italics = false
                active.bold = not active.bold
            elseif token.token == "triplestar" then
                active.italics = false
                active.bold = false
                active.superbold = not active.superbold
            elseif token.token == "backtick" then
                active.code = not active.code
            elseif token.token == "lbrace" then
                i = i + 1

                local nxt = tokens[i]

                if not nxt then continue end

                active.current_color = nxt.value
                active.has_opened = true
            elseif token.token == "rbrace" and active.has_opened then
                active.has_opened = false
                continue
            elseif not active.has_opened then
                table.insert(active.open_block or parsed, {
                    text = token.value,

                    italics = active.superbold or active.italics,
                    bold = active.superbold or active.bold,
                    isquote = active.isquote,
                    code = active.code,

                    color = active.current_color or active.global_color
                })
            end
        end

        return chatcode.parser.ParsePass(parsed)
    end

    function chatcode.parser.ParsePass(parsed)
        local post = {}

        for k,v in ipairs(parsed) do
            local trim = v.text:Trim()

            if trim == "" then
                continue
            end

            v.text = trim .. " "
            table.insert(post, v)
        end

        return post
    end
end

do -- Debug
    function chatcode.debug.FromHex(hex)
        if IsColor(hex) then
            return hex
        end

        local str = hex:gsub("#", "")
        if #str == 3 then
            str = (str[1] .. str[1]) .. (str[2] .. str[2]) .. (str[3] .. str[3])
        end

        if #str == 6 then
            str = str .. "FF" -- alpha
        end

        local r = tonumber("0x" .. str:sub(1, 2))
        local g = tonumber("0x" .. str:sub(3, 4))
        local b = tonumber("0x" .. str:sub(5, 6))
        local a = tonumber("0x" .. str:sub(7, 8))

        if r and g and b and a then
            return Color(r, g, b, a)
        end

        return Color(255, 255, 255)
    end

    function chatcode.debug.Print(text)
        MsgC(Color(255, 255, 255), text, "\n")

        local lexed = chatcode.lexer.Lex(text)
        local parsed = chatcode.parser.Parse(lexed)

        if parsed[1].isquote then
            MsgC(Color(255, 0, 0), "-> ")
        end

        local cr = Color(0, 255, 0)
        for k,v in pairs(parsed) do
            if v.text == "" then
                continue
            end

            local stars = (v.italics and "*") or ""
            stars = stars .. ((v.bold and "**") or "")

            stars = (v.code and "`") or stars

            clr = (v.code and Color(100, 255, 255)) or chatcode.debug.FromHex(v.color)

            MsgC(cr, stars, clr, v.text:Trim(), cr, stars, " ")
        end

        print()
    end
end

-- Tests
if melon and _p and GAMEMODE then
    print()

    local test = "-> `lua` {#FF0} `yellow` **bold text** *italics text {#F00} cum* {* this_is_ignored}"
    chatcode.debug.Print(test)
end
