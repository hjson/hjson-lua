-- MIT License - Copyright (c) 2023 V (alis.is)
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
---@return any
local function decode(str, options)
    local _decoder = decoder:new(options)
    return _decoder:decode(str)
end

---@class HJsonEncodeOptions
---@field indent string|boolean|nil
---@field skip_keys boolean?
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

    if options.skipKeys == true then
        print("skipkeys is deprecated, use skip_keys instead")
        options.skip_keys = true
    end

    if options.sortKeys == true then
        print("sortKeys is deprecated, use sort_keys instead")
        options.sort_keys = true
    end

    if options.invalidObjectsAsType == true then
        print("invalidObjectsAsType is deprecated, use invalid_objects_as_type instead")
        options.invalid_objects_as_type = true
    end
    return options
end

---#DES 'hjson.encode_to_json'
---
---encodes json
---@param obj any
---@param options HJsonEncodeOptions?
---@return any
local function encode_json(obj, options)
    options = preprocess_encode_options(options)

    local _encoder = encoder:new(options)
    return _encoder:encode(obj)
end

---#DES 'hjson.encode'
---
---encodes hjson
---@param obj any
---@param options HJsonEncodeOptions?
---@return any
local function encode(obj, options)
    options = preprocess_encode_options(options) --[[@as HJsonEncodeOptions]]

    if options.indent == "" or options.indent == false or options.indent == 0 then
        return encode_json(obj, options)
    end
    local _encoderH = encoderH:new(options)
    return _encoderH:encode(obj)
end

local hjson = {
    encode = encode,
    ---#DES 'hjson.stringify'
    ---
    ---encodes hjson
    ---@param obj any
    ---@param options HJsonEncodeOptions?
    ---@return any
    stringify = encode,
    encode_to_json = encode_json,
    ---#DES 'hjson.stringify_to_json'
    ---
    ---encodes json
    ---@param obj any
    ---@param options HJsonEncodeOptions?
    ---@return any
    stringify_to_json = encode_json,
    decode = decode,
    ---#DES 'hjson.parse'
    ---
    ---decodes h/json
    ---@param str string
    ---@param options HjsonDecoderOptions
    ---@return any
    parse = decode,
}

return hjson
