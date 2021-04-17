-- MIT License - Copyright (c) 2021 V (cryon.io)
local decoder = require "hjson.decoder"
local encoder = require "hjson.encoder"
local encoderH = require "hjson.encoderH"

---@class HjsonKeyValuePair
---@field key any
---@field value any

---#DES 'decode'
---
---decodes h/json
---@param str string
---@param strict boolean
---@param object_hook fun(obj: table): table
---@param object_pairs_hook fun(pairs: HjsonKeyValuePair[]): HjsonKeyValuePair[]
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


---#DES 'encode_json'
---
---encodes json
---@param obj any
---@param options HjsonEncodeOptions
---@return any
local function encode_json(obj, options)
    local _encoder = encoder:new(options)
    return _encoder:encode(obj)
end

---#DES 'encode_json'
---
---encodes hjson
---@param obj any
---@param options HjsonEncodeOptions
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
    stringify = encode,
    encode_to_json = encode_json,
    stringify_to_json = encode_json,
    decode = decode,
    parse = decode
}

return hjson
