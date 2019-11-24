-- MIT License - Copyright (c) 2019 Void (cryon.io)

local decoder = require"hjson.decoder"
local encoder = require"hjson.encoder"
local encoderH = require"hjson.encoderH"

local function decode(str, strict, object_hook, object_pairs_hook) 
    local _decoder = decoder:new(strict, object_hook, object_pairs_hoo)
    return _decoder:decode(str)
end

local function encode_json(obj, indent, skipkeys) 
    local _encoder = encoder:new(indent, skipkeys)
    return _encoder:encode(obj)
end

local function encode(obj, indent, skipkeys, sort_keys, item_sort_key) 
    local forward = false
    if indent == "" or indent == false or indent == 0 then 
        return encode_json(obj, indent, skipkeys) 
    end
    local _encoderH = encoderH:new(indent, skipkeys, sort_keys, item_sort_key)
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