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
local default_indent = false

local function isArray(t)
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

local function encodeString(s)
    return '"' .. s:gsub('[%z\1-\31\\"]', escapeChar) .. '"'
end

local function encodeNil(val) return "null" end

local function encodeNumber(val)
    -- Check for -inf and inf
    if val <= -math.huge or val >= math.huge then
        return nil, "unexpected number value '" .. tostring(val) .. "'"
    end
    return string.format("%.14g", val)
end

local JsonEncoder = {}

function JsonEncoder:new(options)
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

    if type(indent) == "number" then
        indent = math.floor(indent)
        indent = string.rep(" ", indent)
    end
    if indent == true then indent = "\t" end
    if not indent or indent == "" then indent = default_indent end

    local stack = {}
    local currentIndentLevel = 0

    ---@param key string|number|boolean|nil
    ---@return string?, string?
    local function stringifyKey(key)
        local _type = type(key)
        if _type == "boolean" or _type == "number" then
            return tostring(key)
        elseif _type == "nil" then
            return "null"
        elseif _type == "string" then
            return encodeString(key)
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
        local separator = ","
        local newlineIndent = ""
        if indent then
            currentIndentLevel = currentIndentLevel + 1
            newlineIndent = "\n" .. string.rep(indent, currentIndentLevel)
            separator = separator .. newlineIndent
        end
        local buf = "[" .. newlineIndent
        for i, v in ipairs(arr) do
            local encoded, err = encode(v)
            if not encoded then
                return nil, err
            end
            buf = buf .. encoded
            if i ~= #arr then buf = buf .. separator end
        end
        if indent then
            currentIndentLevel = currentIndentLevel - 1
            buf = buf .. "\n" .. string.rep(indent, currentIndentLevel)
        end
        buf = buf .. "]"
        stack[arr] = nil
        return buf
    end

    local function encodeTable(tab, encode)
        if not tab then return "{}" end
        if stack[tab] then 
            return nil, "circular reference"
        end
        stack[tab] = true
        local newlineIndent = ""
        local separator = ","
        local keySeparator = ":"
        if indent then
            currentIndentLevel = currentIndentLevel + 1
            newlineIndent = "\n" .. string.rep(indent, currentIndentLevel)
            separator = separator .. newlineIndent
            keySeparator = ": "
        end

        local keysetMap = {} -- stringified key (sk) is key for real key
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
            local encoded, err = encode(v)
            if not encoded then
                return nil, err
            end
            buf = buf .. sk .. keySeparator .. encoded
            if i ~= #keyset then buf = buf .. separator end
        end
        if indent then
            currentIndentLevel = currentIndentLevel - 1
            buf = buf .. "\n" .. string.rep(indent, currentIndentLevel)
        end
        buf = buf .. "}"
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

    local function encode(o)
        local _type = type(o)
        if _type == "table" then
            if isArray(o) then
                _type = "array"
            else
                _type = "table"
            end
        end
        local func = encodeFunctionMap[_type]
        if type(func) == "function" then return func(o, encode) end
        if invalid_objects_as_type then
            return encodeFunctionMap["string"]('__lua_' .. type(o))
        end
        return nil, "unexpected type '" .. _type .. "'"
    end

    local je = {_encode = encode}
    setmetatable(je, self)
    self.__index = self

    return je
end

function JsonEncoder:encode(o, allowNonJsonTypes)
    return self._encode(o, allowNonJsonTypes)
end

return JsonEncoder
