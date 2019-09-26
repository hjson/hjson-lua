-- MIT License - Copyright (c) 2019 Void (cryon.io)

local decoder = require"hjson.decoder"
local encoder = require"hjson.encoder"
local encoderH = require"hjson.encoderH"

local _decoder
local _encoder
local _encoderH

function decode(str) 
    if not _decoder then 
        _decoder = decoder:new()
    end
    return _decoder:decode(str)
end

function encode_json(str) 
    if not _encoder then 
        _encoder = encoder:new()
    end
    return _encoder:encode(str)
end

function encode(str) 
    if not _encoderH then 
        _encoderH = encoderH:new()
    end
    return _encoderH:encode(str)
end

hjson = {
    encode = encode,
    stringify = encode,
    encode_to_json = encode_json,
    stringify_to_json = encode_json,
    decode = decode, 
    parse = decode
}

return hjson