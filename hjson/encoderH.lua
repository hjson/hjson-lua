-- MIT License - Copyright (c) 2019 Void (cryon.io)

local escape_char_map = {
    ["\\"] = "\\\\",
    ['"'] = '\\"',
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t"
}

local COMMONRANGE = "\x7f-\x9f" -- // TODO: add unicode escape sequences

function containsSequences(s, sequences)
    for _, v in ipairs(sequences) do
        if s:find(v) then
            return true
        end
    end
    return false
end

function needsEscape(s)
    return containsSequences(s, {'[\\"\x00-\x1f' .. COMMONRANGE .. "]"})
end

function needsQuotes(s)
    local sequences = {
        "^%s",
        '^"',
        "^'",
        "^#",
        "^/%*",
        "^//",
        "^{",
        "^}",
        "^%[",
        "^%]",
        "^:",
        "^,",
        "%s$",
        "[\x00-\x1f" .. COMMONRANGE .. "]"
    }
    return containsSequences(s, sequences)
end

function needsEscapeML(s)
    local sequences = {"'''", "^[\\s]+$", "[\x00-\x08\x0b\x0c\x0e-\x1f" .. COMMONRANGE .. "]"}
    return containsSequences(s, sequences)
end

function needsEscapeName(s)
    local sequences = {'[,{%[}%]%s:#"\']', "//", "/%*", "'''"}
    return containsSequences(s, sequences) or needsQuotes(s)
end

function startsWithNumber(s)
    local integer = s:match("^[\t ]*(-?[1-9]%d*)") or s:match("^[\t ]*(-?0)", begin)
    if integer then
        local frac = s:match("^(%.%d+)", #integer + 1) or ""
        local exp = s:match("^([eE][-+]?%d+)", #integer + #frac + 1) or ""
        local ending =
            s:match("^%s*$", #integer + #frac + #exp + 1) or s:match("^%s*[%[,%]}#].*$", #integer + #frac + #exp + 1) or
            s:match("^%s*//.*$", #integer + #frac + #exp + 1) or
            s:match("^%s*/%*.*$", #integer + #frac + #exp + 1) or
            ""
        m = integer .. frac .. exp .. ending

        if #m == #s then
            return true
        end
    end
    return false
end

function startsWithKeyword(s)
    local sequences = {"^true%s*$", "^false%s*$", "^null%s*$"}
    local startSequences = {"^true%s*[,%]}#].*$", "^false%s*[,%]}#].*$", "^null%s*[,%]}#].*$"}

    return containsSequences(s, sequences) or (containsSequences(s, startSequences))
end

local function isArray(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then
            return false
        end
    end
    return true
end

local function escapeChar(c)
    return escape_char_map[c] or string.format("\\u%04x", c:byte())
end

local function encodeNil(val)
    return "null"
end

local function encodeNumber(val)
    -- Check for NaN, -inf and inf
    if val ~= val or val <= -math.huge or val >= math.huge then
        error("unexpected number value '" .. tostring(val) .. "'")
    end
    return string.format("%.14g", val)
end

local HjsonEncoder = {}

function HjsonEncoder:new(indent, skipkeys, sort_keys, item_sort_key)
    if skipkeys == nil then
        skipkeys = true
    end
    if indent == nil then
        indent = "    "
    end
    if (type(indent) ~= "number" or indent < 2) and (type(indent) ~= "string" or not indent:find("%s%s+")) then
        error("indent (#1 parameter) has to be of type string with at least 2 spaces or integer greater than 1")
    end
    if type(indent) == "number" then
        indent = math.floor(indent)
        indent = string.rep(" ", indent)
    end

    if indent and not indent:match("%s*") then
        error("Indent has to contain only whitespace characters or be a number")
    end

    local stack = {}
    local currentIndentLevel = 0

    local function encodeMultiLineString(str)
        if not str or #str == 0 then
            return "''''''"
        end

        currentIndentLevel = currentIndentLevel + 1
        local newlineIndent = "\n" .. string.rep(indent, currentIndentLevel)
        currentIndentLevel = currentIndentLevel - 1

        return newlineIndent .. "'''" .. newlineIndent .. str:gsub("\n", newlineIndent) .. newlineIndent .. "'''"
    end

    local function encodeString(s)
        local isNumber = false
        local first = s:sub(1, 1)
        if first == "-" or first >= "0" and first <= "9" then
            isNumber = startsWithNumber(s)
        end
        if needsQuotes(s) or isNumber or startsWithKeyword(s) then
            if not needsEscape(s) then
                return '"' .. s .. '"'
            elseif not needsEscapeML(s) and s:find("\n") and s:find("[^%s\\]") then
                return encodeMultiLineString(s)
            else
                return '"' .. s:gsub('[%z\1-\31\\"]', escapeChar) .. '"'
            end
        else
            return s
        end
    end

    local function stringifyKey(key)
        local _type = type(key)
        if _type == "boolean" or _type == "number" then
            return tostring(key)
        elseif _type == "nil" then
            return "null"
        elseif _type == "string" then
            if not key or #key == 0 then
                return '""'
            end
            -- Check if we can insert this name without quotes
            if needsEscapeName(key) then
                return '"' .. key:gsub('[%z\1-\31\\"]', escapeChar) .. '"'
            else
                -- return without quotes
                return key
            end
        end
        if skipkeys then
            return nil
        end
        error(string.format("Invalid key type - %s (%s) ", _type, key))
    end

    local function encodeArray(arr, encode)
        if not arr or #arr == 0 then
            return "[]"
        end
        if stack[arr] then
            error("circular reference")
        end
        stack[arr] = true

        currentIndentLevel = currentIndentLevel + 1
        local newlineIndent = "\n" .. string.rep(indent, currentIndentLevel)
        local separator = newlineIndent

        local buf = "[" .. newlineIndent
        for i, v in ipairs(arr) do
            buf = buf .. encode(v)
            if i ~= #arr then
                buf = buf .. separator
            end
        end
        currentIndentLevel = currentIndentLevel - 1
        buf = buf .. "\n" .. string.rep(indent, currentIndentLevel) .. "]"
        stack[arr] = nil
        return buf
    end

    local function encodeTable(tab, encode)
        if not tab then
            return "{}"
        end
        if stack[tab] then
            error("circular reference")
        end
        stack[tab] = true

        currentIndentLevel = currentIndentLevel + 1
        local newlineIndent = "\n" .. string.rep(indent, currentIndentLevel)
        local separator = newlineIndent
        keySeparator = ": "

        -- stringified key (sk) is key in keysetMap pointing to original non stringified key key
        local keysetMap = {}
        local keyset = {}
        local n = 0

        for k in pairs(tab) do
            local key = stringifyKey(k)
            if key ~= nil then
                table.insert(keyset, key)
                keysetMap[key] = k
            end
        end
        if sort_keys then
            if type(item_sort_key) == "function" then
                table.sort(keyset, item_sort_key)
            else
                table.sort(
                    keyset,
                    function(a, b)
                        return a:upper() < b:upper()
                    end
                )
            end
        end
        local buf = "{" .. newlineIndent
        for i, sk in ipairs(keyset) do
            local k = keysetMap[sk]
            local v = tab[k]

            local key = sk
            buf = buf .. key .. keySeparator .. encode(v)
            if i ~= #keyset then
                buf = buf .. separator
            end
        end
        currentIndentLevel = currentIndentLevel - 1
        buf = buf .. "\n" .. string.rep(indent, currentIndentLevel) .. "}"

        stack[tab] = nil
        return buf
    end

    local encodeFunctionMap = {
        ["nil"] = encodeNil,
        ["table"] = encodeTable,
        ["array"] = encodeArray,
        ["string"] = encodeString,
        ["number"] = encodeNumber,
        ["boolean"] = tostring
    }

    local function _encode(o)
        local _type = type(o)
        if _type == "table" then
            if isArray(o) then
                _type = "array"
            else
                _type = "table"
            end
        end
        local func = encodeFunctionMap[_type]
        if type(func) == "function" then
            return func(o, encode)
        end
        error("Unexpected type '" .. _type .. "'")
    end

    local function json_encode(o)
        stack = {}
        return _encode(o)
    end

    local je = {
        _encode = _encode
    }
    setmetatable(je, self)
    self.__index = self

    return je
end

function HjsonEncoder:encode(o)
    return self._encode(o)
end

return HjsonEncoder
