-- MIT License - Copyright (c) 2025 V (alis.is)
local escape_char_map = {
    ["\\"] = "\\\\",
    ['"'] = '\\"',
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t"
}

local default_indent = "\t"

local COMMONRANGE = "\127-\159" -- // TODO: add unicode escape sequences

local function containsSequences(s, sequences)
    for _, v in ipairs(sequences) do if s:find(v) then return true end end
    return false
end

local function needsEscape(s)
    return containsSequences(s, {"%z", '[\\"\001-\031' .. COMMONRANGE .. "]"})
end

local function needsQuotes(s)
    local sequences = {
        "^%s", '^"', "^'", "^#", "^/%*", "^//", "^{", "^}", "^%[", "^%]", "^:",
        "^,", "%s$", "%z", "[\001-\031" .. COMMONRANGE .. "]"
    }
    return containsSequences(s, sequences)
end

local function needsEscapeML(s)
    local sequences = {
        "'''", "^[\\s]+$", "%z", "[\01-\08\011\012\014-\031" .. COMMONRANGE .. "]"
    }
    return containsSequences(s, sequences)
end

local function needsEscapeName(s)
    local sequences = {'[,{%[}%]%s:#"\']', "//", "/%*", "'''"}
    return containsSequences(s, sequences) or needsQuotes(s)
end

local function startsWithNumber(s)
    local integer = s:match("^[\t ]*(-?[1-9]%d*)") or
                        s:match("^[\t ]*(-?0)")
    if integer then
        local frac = s:match("^(%.%d+)", #integer + 1) or ""
        local exp = s:match("^([eE][-+]?%d+)", #integer + #frac + 1) or ""
        local ending = s:match("^%s*$", #integer + #frac + #exp + 1) or
                           s:match("^%s*[%[,%]}#].*$",
                                   #integer + #frac + #exp + 1) or
                           s:match("^%s*//.*$", #integer + #frac + #exp + 1) or
                           s:match("^%s*/%*.*$", #integer + #frac + #exp + 1) or
                           ""
        local m = integer .. frac .. exp .. ending

        if #m == #s then return true end
    end
    return false
end

local function startsWithKeyword(s)
    local sequences = {"^true%s*$", "^false%s*$", "^null%s*$"}
    local startSequences = {
        "^true%s*[,%]}#].*$", "^false%s*[,%]}#].*$", "^null%s*[,%]}#].*$"
    }

    return containsSequences(s, sequences) or
               (containsSequences(s, startSequences))
end

local function is_array(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end

local function escapeChar(c)
    return escape_char_map[c] or string.format("\\u%04x", c:byte())
end

local function encodeNil(val) return "null" end

---@return string?, string?
local function encodeNumber(val)
    -- -- Check for -inf and inf
    if val <= -math.huge or val >= math.huge then
        return nil, "unexpected number value '" .. tostring(val) .. "'"
    end
    return string.format("%.14g", val)
end

local HjsonEncoder = {}

function HjsonEncoder:new(options)
    if type(options) ~= "table" then options = {} end
    local indent, skip_invalid_keys, sort_keys, item_sort_key, invalid_objects_as_type =
        options.indent, options.skip_keys, options.sort_keys,
        options.item_sort_key, options.invalid_objects_as_type

    if skip_invalid_keys == nil then skip_invalid_keys = true end
    local indent_type = type(indent)
    assert(indent_type == "string" or indent_type == "number" or indent_type == "boolean" or indent == nil,
           "indent has to be of type string, number or boolean, got " .. indent_type)
    assert(indent_type ~= "string" or indent:match("^%s*$"),
           "indent has to be a string consisting of whitespace characters only")
    assert(type(indent) ~= "boolean" or indent == true,
           "if indent is a boolean, it has to be true, got " .. tostring(indent))

    if type(indent) == "number" then
        indent = math.floor(indent)
        indent = string.rep(" ", indent)
    end
    if not indent or indent == true or indent == "" then indent = default_indent end

    local stack = {}
    local currentIndentLevel = 0

    local function encodeMultiLineString(str)
        if not str or #str == 0 then return "''''''" end

        currentIndentLevel = currentIndentLevel + 1
        local newlineIndent = "\n" .. string.rep(indent, currentIndentLevel)
        currentIndentLevel = currentIndentLevel - 1

        return newlineIndent .. "'''" .. newlineIndent ..
                   str:gsub("\n", newlineIndent) .. newlineIndent .. "'''"
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

    ---@param key string|number|boolean|nil
    ---@return string?, string?
    local function stringifyKey(key)
        local _type = type(key)
        if _type == "boolean" or _type == "number" then
            return tostring(key)
        elseif _type == "nil" then
            return "null"
        elseif _type == "string" then
            if not key or #key == 0 then return '""' end
            -- Check if we can insert this name without quotes
            if needsEscapeName(key) then
                return '"' .. key:gsub('[%z\1-\31\\"]', escapeChar) .. '"'
            else
                -- return without quotes
                return key
            end
        end
        if skip_invalid_keys then return nil end
        return nil, "invalid key type - " .. _type .. " (" .. tostring(key) .. ")"
    end

    ---@param arr any[]
    ---@param encode fun(v: any): string?, string?
    ---@return string?, string?
    local function encodeArray(arr, encode)
        if not arr or #arr == 0 then return "[]" end
        if stack[arr] then
            return nil, "circular reference"
        end
        stack[arr] = true

        currentIndentLevel = currentIndentLevel + 1
        local newlineIndent = "\n" .. string.rep(indent, currentIndentLevel)
        local separator = newlineIndent

        local buf = "[" .. newlineIndent
        for i, v in ipairs(arr) do
            local encoded, err = encode(v)
            if not encoded then
                return nil, err
            end
            buf = buf .. encoded
            if i ~= #arr then buf = buf .. separator end
        end
        currentIndentLevel = currentIndentLevel - 1
        buf = buf .. "\n" .. string.rep(indent, currentIndentLevel) .. "]"
        stack[arr] = nil
        return buf
    end

    ---@param tab table
    ---@param encode fun(v: any): string?, string?
    ---@return string?, string?
    local function encodeTable(tab, encode)
        if not tab then return "{}" end
        if stack[tab] then 
            return nil, "circular reference"
        end
        stack[tab] = true

        currentIndentLevel = currentIndentLevel + 1
        local newlineIndent = "\n" .. string.rep(indent, currentIndentLevel)
        local separator = newlineIndent
        local keySeparator = ": "

        -- stringified key (sk) is key in keysetMap pointing to original non stringified key key
        local keysetMap = {}
        local keyset = {}

        for k in pairs(tab) do
            local key, err = stringifyKey(k)
            if key ~= nil then
                table.insert(keyset, key)
                keysetMap[key] = k
            elseif err ~= nil then
                return nil, err
            end
        end
        if sort_keys then
            if type(item_sort_key) == "function" then
                table.sort(keyset, item_sort_key)
            else
                table.sort(keyset,
                           function(a, b)
                    return a:upper() < b:upper()
                end)
            end
        end
        local buf = "{" .. newlineIndent
        for i, sk in ipairs(keyset) do
            local k = keysetMap[sk]
            local v = tab[k]

            local key = sk
            local encoded, err = encode(v)
            if not encoded then
                return nil, err
            end
            buf = buf .. key .. keySeparator ..  encoded
            if i ~= #keyset then buf = buf .. separator end
        end
        currentIndentLevel = currentIndentLevel - 1
        buf = buf .. "\n" .. string.rep(indent, currentIndentLevel) .. "}"

        stack[tab] = nil
        return buf
    end

    ---@type table<string, fun(v: any):string?, string?>
    local encodeFunctionMap = {
        ["nil"] = encodeNil,
        ["table"] = encodeTable,
        ["array"] = encodeArray,
        ["string"] = encodeString,
        ["number"] = encodeNumber,
        ["boolean"] = tostring
    }

    ---@param o any
    ---@return string?, string?
    local function _encode(o)
        local _type = type(o)
        if _type == "table" then
            if is_array(o) then
                _type = "array"
            else
                _type = "table"
            end
        end
        local func = encodeFunctionMap[_type]
        if type(func) == "function" then return func(o, _encode) end
        if invalid_objects_as_type then
            return encodeFunctionMap["string"]('__lua_' .. type(o))
        end
        return nil, "unexpected type '" .. _type .. "'"
    end

    local je = {_encode = _encode}
    setmetatable(je, self)
    self.__index = self

    return je
end

function HjsonEncoder:encode(o) return self._encode(o) end

return HjsonEncoder
