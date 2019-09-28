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

local function encodeString(s)
  return '"' .. s:gsub('[%z\1-\31\\"]', escapeChar) .. '"'
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

local JsonEncoder = {}

function JsonEncoder:new(indent, skipkeys, sort_keys, item_sort_key)
  if skipkeys == nil then
    skipkeys = true
  end
  if indent == nil then
    indent = "    "
  end
  if type(indent) ~= "number" and type(indent) ~= "string" and type(indent) ~= "boolean" then
    error("indent (#1 parameter) has to be of type string, number or boolean")
  end
  if type(indent) == "number" then
    indent = string.rep(" ", indent)
  end

  if type(indent) == "boolean" and indent then 
    indent = "    "
  end

  if indent and not indent:match("%s*") then
    error("Indent has to contain only whitespace characters or be a number")
  end

  local stack = {}
  local currentIndentLevel = 0

  local function stringifyKey(key)
    local _type = type(key)
    if _type == "boolean" or _type == "number" then
      return tostring(key)
    elseif _type == "nil" then
      return "null"
    elseif _type == "string" then
      return encodeString(key)
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
    local separator = ","
    local newlineIndent = ""
    if indent then
      currentIndentLevel = currentIndentLevel + 1
      newlineIndent = "\n" .. string.rep(indent, currentIndentLevel)
      separator = separator .. newlineIndent
    end
    local buf = "[" .. newlineIndent
    for i, v in ipairs(arr) do
      buf = buf .. encode(v)
      if i ~= #arr then
        buf = buf .. separator
      end
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
    if not tab then
      return "{}"
    end
    if stack[tab] then
      error("circular reference")
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
      buf = buf .. sk .. keySeparator .. encode(v)
      if i ~= #keyset then
        buf = buf .. separator
      end
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
    if type(func) == "function" then
      return func(o, encode)
    end
    error("Unexpected type '" .. _type .. "'")
  end

  local function json_encode(o)
    stack = {}
    return encode(o)
  end

  local je = {
    _encode = encode
  }
  setmetatable(je, self)
  self.__index = self

  return je
end

function JsonEncoder:encode(o)
  return self._encode(o)
end

return JsonEncoder
