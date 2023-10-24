-- MIT License - Copyright (c) 2023 V (alis.is)
local decoder = require "hjson.decoder"
local encoder = require "hjson.encoder"
local encoderH = require "hjson.encoderH"

---@class HjsonKeyValuePair
---@field key any
---@field value any

---#DES 'hjson.decode'
---
---decodes h/json
---@param str string
---@param strict boolean?
---@param object_hook (fun(obj: table): table)?
---@param object_pairs_hook (fun(pairs: HjsonKeyValuePair[]): HjsonKeyValuePair[])?
---@return any
local function decode(str, strict, object_hook, object_pairs_hook)
    local _decoder = decoder:new(strict, object_hook, object_pairs_hook)
    return _decoder:decode(str)
end

---@class HjsonEncodeOptions
---@field indent string|boolean
---@field skipkeys boolean
---@field sortKeys boolean
---@field item_sort_key fun(k1:any, k2:any): boolean
---@field invalidObjectsAsType boolean


---#DES 'hjson.encode_to_json'
---
---encodes json
---@param obj any
---@param options HjsonEncodeOptions?
---@return any
local function encode_json(obj, options)
    local _encoder = encoder:new(options)
    return _encoder:encode(obj)
end

---#DES 'hjson.encode'
---
---encodes hjson
---@param obj any
---@param options HjsonEncodeOptions?
---@return any
local function encode(obj, options)
    if type(options) ~= "table" then
        options = {}
    end

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
    ---@param options HjsonEncodeOptions?
    ---@return any
    stringify = encode,
    encode_to_json = encode_json,
    ---#DES 'hjson.stringify_to_json'
    ---
    ---encodes json
    ---@param obj any
    ---@param options HjsonEncodeOptions?
    ---@return any
    stringify_to_json = encode_json,
    decode = decode,
    ---#DES 'hjson.parse'
    ---
    ---decodes h/json
    ---@param str string
    ---@param strict boolean?
    ---@param object_hook (fun(obj: table): table)?
    ---@param object_pairs_hook (fun(pairs: HjsonKeyValuePair[]): HjsonKeyValuePair[])?
    ---@return any
    parse = decode
}

print"loaded"
return hjson
