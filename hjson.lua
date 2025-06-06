-- MIT License - Copyright (c) 2025 V (alis.is)
local decoder = require "hjson.decoder"
local encoder = require "hjson.encoder"
local encoderH = require "hjson.encoderH"

---@class HJsonKeyValuePair
---@field key any
---@field value any

---#DES 'hjson.decode'
---
---decodes h/json
---@param str string
---@param options HjsonDecoderOptions
---@return any result
---@return string? error
---@return boolean success
local function decode(str, options)
    return decoder:new(options):decode(str)
end

---@class HJsonEncodeOptions
---@field indent string|boolean|integer|nil
---@field skip_keys boolean? skip invalid keys
---@field sort_keys boolean?
---@field item_sort_key (fun(k1:any, k2:any): boolean)?
---@field invalid_objects_as_type boolean?

---@param options HJsonEncodeOptions?
---@return HJsonEncodeOptions
local function preprocess_encode_options(options)
    if type(options) ~= "table" then
        local result = {}  --[[@as HJsonEncodeOptions]]
        return result
    end

    return options
end

---#DES 'hjson.encode_to_json'
---
---encodes json
---@param obj any
---@param options HJsonEncodeOptions?
---@return string? result
---@return string? error
local function encode_json(obj, options)
    options = preprocess_encode_options(options)

    return encoder:new(options):encode(obj)
end

---#DES 'hjson.encode'
---
---encodes hjson
---@param obj any
---@param options HJsonEncodeOptions?
---@return string? result
---@return string? error
local function encode(obj, options)
    options = preprocess_encode_options(options) --[[@as HJsonEncodeOptions]]

    if options.indent == "" or options.indent == false or options.indent == 0 then
        return encode_json(obj, options)
    end

    return encoderH:new(options):encode(obj)
end

local hjson = {
    encode = encode,
    ---#DES 'hjson.stringify'
    ---
    ---encodes hjson
    ---@param obj any
    ---@param options HJsonEncodeOptions?
    ---@return string? result
    ---@return string? error
    stringify = encode,
    encode_to_json = encode_json,
    ---#DES 'hjson.stringify_to_json'
    ---
    ---encodes json
    ---@param obj any
    ---@param options HJsonEncodeOptions?
    ---@return string? result
    ---@return string? error
    stringify_to_json = encode_json,
    decode = decode,
    ---#DES 'hjson.parse'
    ---
    ---decodes h/json
    ---@param str string
    ---@param options HjsonDecoderOptions
    ---@return any result
    ---@return string? error
    ---@return boolean success
    parse = decode,
}

return hjson
