-- MIT License - Copyright (c) 2023 V (alis.is)
local DEFAULT_MAX_DEPTH = 1000

local WHITESPACE = " \t\n\r"
local PUNCTUATOR = "{}[],:"
local BACKSLASH = {
    ['"'] = string.char(34),
    ["'"] = string.char(39),
    ["\\"] = string.char(92),
    ["/"] = string.char(47),
    ["b"] = string.char(8),
    ["f"] = string.char(12),
    ["n"] = string.char(10),
    ["r"] = string.char(13),
    ["t"] = string.char(9)
}

local function trim(s)
    local n = s:find "%S"
    return n and s:match(".*%S", n) or ""
end

local function charAt(s, pos)
    assert(type(s) == "string", "Invalid argument")
    return s:sub(pos, pos)
end

local function decodeError(str, idx, msg)
    local line_count = 1
    local col_count = 1
    for i = 1, idx - 1 do
        col_count = col_count + 1
        if charAt(str, i) == "\n" then
            line_count = line_count + 1
            col_count = 1
        end
    end
    error(string.format("%s at line %d col %d", msg, line_count, col_count))
end

---@class HjsonDecoderOptions
---@field strict boolean?
---@field object_hook (fun(obj: table): table)?
---@field object_pairs_hook (fun(pairs: HJsonKeyValuePair[]): HJsonKeyValuePair[])?
---@field max_depth number?

---@class HjsonDecoder
---@field decode fun(self: HjsonDecoder, s: string): any

local HjsonDecoder = {}
--- Hjson decoder
--- Performs the following translations in decoding by default:
--- ** NOTE: nil is used in lua for reference removal and so arrays with null wont contain nil in lua representation.
--- Same objects wont contain keys with nil value.
--- +---------------+-------------------+
--- | JSON          | Lua               |
--- +===============+===================+
--- | object        | table             |
--- +---------------+-------------------+
--- | array         | table             |
--- +---------------+-------------------+
--- | string        | string            |
--- +---------------+-------------------+
--- | number        | number            |
--- +---------------+-------------------+
--- | true          | true              |
--- +---------------+-------------------+
--- | false         | false             |
--- +---------------+-------------------+
--- | null          | nil               |
--- +---------------+-------------------+

--- Creates a new HjsonDecoder instance
---@param options HjsonDecoderOptions
---@return HjsonDecoder
function HjsonDecoder:new(options)
    if type(options) ~= "table" then
        options = {
            strict = type(options) == "boolean" and options or true, -- for backward compatibility
        }
    end

    if type(options.strict) ~= "boolean" then
        options.strict = true
    end
    if type(options.max_depth) ~= "number" or options.max_depth < 1 then
        options.max_depth = DEFAULT_MAX_DEPTH
    end

    local memo = {}

    local function getEol(s, _end)
        -- skip until eol
        while true do
            local ch = charAt(s, _end)
            if ch == "\r" or ch == "\n" or ch == "" then
                return _end
            end
            _end = _end + 1
        end
    end

    local function getNext(s, _end)
        local ch
        while true do
            -- Use a slice to prevent IndexError from being raised
            ch = charAt(s, _end)
            -- Skip whitespace
            while WHITESPACE:find(ch, 1, true) do
                if ch == "" then
                    return ch, _end
                end
                _end = _end + 1
                ch = charAt(s, _end)
            end

            -- Hjson allows comments
            local ch2 = charAt(s, _end + 1)
            if ch == "#" or ch == "/" and ch2 == "/" then
                _end = getEol(s, _end)
            elseif ch == "/" and ch2 == "*" then
                _end = _end + 2
                ch = charAt(s, _end)

                while ch ~= "" and not (ch == "*" and charAt(s, _end + 1) == "/") do
                    _end = _end + 1
                    ch = charAt(s, _end)
                end

                if ch ~= "" then
                    _end = _end + 2
                end
            else
                break
            end
        end
        return ch, _end
    end

    local function skipIndent(s, _end, n)
        local ch = charAt(s, _end)
        local IDENTCHARS = " \t\r"
        while ch ~= "" and IDENTCHARS:find(ch, 1, true) and (n > 0 or n < 0) do
            _end = _end + 1
            n = n - 1
            ch = charAt(s, _end)
        end
        return _end
    end

    local function codepointToUtf8(n, s, _end)
        -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
        local f = math.floor
        if n <= 0x7f then
            return string.char(n)
        elseif n <= 0x7ff then
            return string.char(f(n / 64) + 192, n % 64 + 128)
        elseif n <= 0xffff then
            return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
        elseif n <= 0x10ffff then
            return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128, n % 64 + 128)
        end
        decodeError(s, _end, string.format("invalid unicode codepoint '%x'", n))
    end

    local function parseString(s, _end)
        --[[ 
            Scan the string s for a JSON string. End is the index of the
            character in s after the quote that started the JSON string.
        ]]
        local chunks = ""
        local begin = _end - 1

        -- callers make sure that string starts with " or '
        local exitCh = charAt(s, begin)
        local function scan_string()
            local content, terminator = s:match('(.-)([\'"\\%z\001-\031])', _end)
            if not content then
                decodeError(s, begin, "Unterminated string")
            end

            _end = _end + #content + #terminator
            chunks = chunks .. content

            if terminator == exitCh then
                return true -- break
            elseif terminator == '"' or terminator == "'" then
                chunks = chunks .. terminator
                return -- continue
            elseif terminator ~= "\\" then
                if options.strict then
                    decodeError(s, begin, "Invalid control character " .. terminator)
                else
                    chunks = chunks .. terminator
                    return -- continue
                end
            end

            if #s < _end then
                decodeError(s, _end, "Unterminated string")
            end

            local chars
            local esc = charAt(s, _end)
            if esc ~= "u" then
                if not esc or not BACKSLASH[esc] then
                    decodeError(s, _end, "Invalid \\X escape sequence")
                end
                chars = BACKSLASH[esc]
                _end = _end + 1
            else
                -- Unicode escape sequence
                local msg = "Invalid \\uXXXX escape sequence"
                esc = s:sub(_end + 1, _end + 4)
                if #esc ~= 4 or not esc:find("%x%x%x%x") then
                    decodeError(s, _end - 1, msg)
                end
                _end = _end + 5
                if esc:find("^[dD][89aAbB]") and s:sub(_end, _end + 1) == "\\u" then
                    local esc2 = s:sub(_end + 2, _end + 6)
                    local n1 = tonumber(esc, 16)
                    local n2 = tonumber(esc2, 16)
                    chars = codepointToUtf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000, s, _end)
                    _end = _end + 7
                else
                    local n = tonumber(esc, 16)
                    chars = codepointToUtf8(n, s, _end - 5)
                end
            end
            chunks = chunks .. chars
        end
        while not scan_string() do end
        return chunks, _end
    end

    local function parseMultilineString(s, _end)
        -- Scan multiline string
        local string = ""
        local triple = 0

        -- we are at ''' - get indent
        local indent = 0
        while true do
            local ch = charAt(s, _end - indent - 1)
            if ch == "\n" then
                break
            end
            indent = indent + 1
        end

        -- skip white/to (newline)
        _end = skipIndent(s, _end + 3, -1)
        local ch = charAt(s, _end)
        if ch == "\n" then
            _end = skipIndent(s, _end + 1, indent)
        end

        -- When parsing multiline string values, we must look for ' characters
        local function scan_mlstring()
            ch = charAt(s, _end)
            if ch == "" then
                decodeError(s, _end, "Bad multiline string")
            end
            if ch == "'" then
                triple = triple + 1
                _end = _end + 1
                if triple == 3 then
                    if charAt(string, -1) == "\n" then
                        string = string:sub(1, -2)
                    end
                    return string, _end
                else
                    return false
                end
            else
                while triple > 0 do
                    string = string .. "'"
                    triple = triple - 1
                end
            end

            if ch == "\n" then
                string = string .. ch
                _end = skipIndent(s, _end + 1, indent)
            else
                if ch ~= "\r" then
                    string = string .. ch
                end
                _end = _end + 1
            end
        end
        while true do
            local s, _end = scan_mlstring()
            if s then
                return s, _end
            end
        end
    end

    local function parsePrimitive(s, _end)
        -- Scan s until eol. return string, True, False or nil
        local chf, begin = getNext(s, _end)
        _end = begin
        if PUNCTUATOR:find(chf, 1, true) then
            decodeError(s, _end, "Found a punctuator character when expecting a quoteless string (check your syntax)")
        end

        while true do
            local ch = charAt(s, _end)
            local isEol = ch == "\r" or ch == "\n" or ch == ""

            if
                isEol or ch == "," or ch == "}" or ch == "]" or ch == "#" or
                    ch == "/" and (charAt(s, _end + 1) == "/" or charAt(s, _end + 1) == "*")
            then
                local m = nil
                local integer = nil
                local frac = nil
                local exp = nil

                local trimmed_range = trim(s:sub(begin, _end - 1))
                if chf == "n" and trimmed_range == "null" then
                    return nil, _end
                elseif chf == "t" and trimmed_range == "true" then
                    return true, _end
                elseif chf == "f" and trimmed_range == "false" then
                    return false, _end
                elseif chf == "-" or chf >= "0" and chf <= "9" then
                    -- NUMBER_RE = re.compile(r'[\t ]*(-?(?:0|[1-9]\d*))(\.\d+)?([eE][-+]?\d+)?[\t ]*')
                    integer = s:match("^[\t ]*(-?[1-9]%d*)", begin) or s:match("^[\t ]*(-?0)", begin)
                    if integer then
                        frac = s:match("^(%.%d+)", begin + #integer) or ""
                        exp = s:match("^([eE][-+]?%d+)", begin + #integer + #frac) or ""
                        local ending = s:match("^([\t ]*)", begin + #integer + #frac + #exp) or ""
                        m = integer .. frac .. exp .. ending
                    end
                end
                if m and begin + #m == _end then
                    local res = tonumber(integer .. frac .. exp)
                    return res, _end
                end

                if isEol then
                    return trimmed_range, _end
                end
            end
            _end = _end + 1
        end
    end

    local function scanKeyName(s, _end)
        local ch, _end = getNext(s, _end)
        if ch == '"' or ch == "'" then
            return parseString(s, _end + 1)
        end

        local begin = _end
        local space = -1
        while true do
            ch = charAt(s, _end)
            if ch == "" then
                decodeError(s, _end, "Bad key name (eof)")
            end
            if ch == ":" then
                if begin == _end then
                    decodeError(s, begin, "Found ':' but no key name (for an empty key name use quotes)")
                elseif space >= 0 then
                    if space ~= _end - 1 then
                        decodeError(s, _end, "Found whitespace in your key name (use quotes to include)")
                    end
                    return trim(s:sub(begin, _end - 1)), _end
                else
                    return s:sub(begin, _end - 1), _end
                end
            elseif WHITESPACE:find(ch, 1, true) then
                if space < 0 or space == _end - 1 then
                    space = _end
                end
            elseif ch == "{" or ch == "}" or ch == "[" or ch == "]" or ch == "," then
                decodeError(
                    s,
                    begin,
                    "Found '" ..
                        ch ..
                            "' where a key name was expected (check your syntax or use quotes if the key name includes {}[],: or whitespace)"
                )
            end
            _end = _end + 1
        end
    end

    local function parse_object(state, scan_once, is_object_without_braces, depth)
        if is_object_without_braces == nil then
            is_object_without_braces = false
        end
        local s = state.s
        local _end = state._end

        local function memo_get(memo, key, default)
            if memo[key] == nil then
                memo[key] = default
            end

            return memo[key]
        end

        local function dict(t)
            local result = {}

            for _, value in pairs(t) do
                assert(type(value) == "table", "Cannot convert non array object to table...")
                for k, v in pairs(value) do
                    result[k] = v
                end
            end
            return result
        end

        local pairs = {}
        local ch
        ch, _end = getNext(s, _end)

        -- Trivial empty object
        if not is_object_without_braces and ch == "}" then
            if type(options.object_pairs_hook) == "function" then
                local result = options.object_pairs_hook(pairs)
                return result, _end + 1
            end
            pairs = {}
            if type(options.object_hook) == "function" then
                pairs = options.object_hook(pairs)
            end
            return pairs, _end + 1
        end

        while true do
            local key
            local value
            key, _end = scanKeyName(s, _end)
            key = memo_get(memo, key, key)

            ch, _end = getNext(s, _end)
            if ch ~= ":" then
                decodeError(s, _end, "Expecting ':' delimiter")
            end

            ch, _end = getNext(s, _end + 1)
            value, _end = scan_once(s, _end, depth)
            table.insert(pairs, {[key] = value})

            ch, _end = getNext(s, _end)
            if ch == "," then
                ch, _end = getNext(s, _end + 1)
            end

            if is_object_without_braces then
                if ch == "" then
                    break
                end
            else
                if ch == "}" then
                    _end = _end + 1
                    break
                end
            end
            ch, _end = getNext(s, _end)
        end
        if type(options.object_pairs_hook) == "function" then
            local result = options.object_pairs_hook(pairs)
            return result, _end
        end

        local obj = dict(pairs)
        if type(options.object_hook) == "function" then
            obj = options.object_hook(obj)
        end
        return obj, _end
    end

    local function parse_array(state, scan_once, depth)
        local ch
        local s = state.s
        local _end = state._end
        local values = {}
        ch, _end = getNext(s, _end)

        if ch == "" then
            decodeError(s, _end, "End of input while parsing an array (did you forget a closing ']'?)")
        end
        -- Look-ahead for trivial empty array
        if ch == "]" then
            return values, _end + 1
        end

        while true do
            local value
            value, _end = scan_once(s, _end, depth)
            table.insert(values, value)
            ch, _end = getNext(s, _end)
            if ch == "," then
                ch, _end = getNext(s, _end + 1)
            end

            if ch == "]" then
                _end = _end + 1
                break
            end

            ch, _end = getNext(s, _end)
        end
        return values, _end
    end

    local function _scan_once(string, idx, depth)
        if type(depth) ~= "number" then
            depth = 0
        end
        depth = depth + 1
        if depth > options.max_depth then
            decodeError(string, idx, "Exceeded max depth")
        end

        local ch = charAt(string, idx)
        if not ch then
            decodeError(string, idx, "Expecting value")
        end

        if ch == '"' or ch == "'" then
            if string:sub(idx, idx + 2) == "'''" then
                return parseMultilineString(string, idx)
            else
                return parseString(string, idx + 1)
            end
        elseif ch == "{" then
            return parse_object({s = string, _end = idx + 1}, _scan_once, false, depth)
        elseif ch == "[" then
            return parse_array({s = string, _end = idx + 1}, _scan_once, depth)
        end
        return parsePrimitive(string, idx)
    end

    local function scan_once(string, idx)
        if idx <= 0 then
            decodeError(string, idx, "Expecting value")
        end
        local status, result, _end = pcall(_scan_once, string, idx)
        memo = {}
        if not status then
            error(result)
        end

        return result, _end
    end

    local function scan_object_once(string, idx)
        if idx <= 0 then
            decodeError(string, idx, "Expecting value")
        end
        local status, result, _end = pcall(parse_object, {s = string, _end = idx}, _scan_once, true)
        memo = {}
        if not status then
            error(result)
        end

        return result, _end
    end

    -- Finally create and return instance of decoder
    local hd = {
        get_next = getNext,
        scan_once = scan_once,
        scan_object_once = scan_object_once
    }
    setmetatable(hd, self)
    self.__index = self

    return hd
end

function HjsonDecoder:decode(s)
    --[[
        Returns the Lua representation of ``s`` (a ``ascii`` or ``utf-8`` string
        instance containing a JSON document)
    ]]
    local ch
    local obj, _end = self:raw_decode(s)
    ch, _end = self.get_next(s, _end)
    if _end ~= #s + 1 then
        decodeError(s, _end, "Extra data")
    end

    return obj
end

function HjsonDecoder:raw_decode(s, idx)
    local ch
    if idx == nil then
        idx = 1
    end

    if idx <= 0 then
        decodeError(s, idx, "Expecting value")
    end

    -- Strip UTF-8 bom
    if (#s > idx) then
        local b1, b2, b3 = s:byte(1, 3)
        if b1 == 0xfe and b2 == 0xff then
            s = s:sub(2)
        elseif b1 == 0xef and b2 == 0xbb and b3 == 0xbf then
            s = s:sub(4)
        end
    end

    ch, idx = self.get_next(s, idx)
    if idx == 1 and ch == "" then
        return {}, 1
    end

    if ch == "{" or ch == "[" then
        return self.scan_once(s, idx)
    else
        -- assume we have a root object without braces
        local status, result, _end = pcall(self.scan_object_once, s, idx)
        if status then
            return result, _end
        else
            local status2, result2, _end = pcall(self.scan_once, s, idx)
            if not status2 then
                error(result)
            end
            return result2, _end
        end
    end
end
return HjsonDecoder
