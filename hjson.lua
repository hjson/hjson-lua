-- MIT License - Copyright (c) 2019 Void (cryon.io)
local decoder = require "hjson.decoder"
local encoder = require "hjson.encoder"
local encoderH = require "hjson.encoderH"

local function decode(str, strict, object_hook, object_pairs_hook)
    local _decoder = decoder:new(strict, object_hook, object_pairs_hook)
    return _decoder:decode(str)
end

-- options = {indent, skipkeys, sort_keys, item_sort_key, invalidObjectsAsType}
local function encode_json(obj, options)
    local _encoder = encoder:new(options)
    return _encoder:encode(obj)
end

-- options = {indent, skipkeys, sort_keys, item_sort_key, invalidObjectsAsType}
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
