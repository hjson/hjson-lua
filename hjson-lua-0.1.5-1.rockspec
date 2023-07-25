package = "hjson-lua"
version = "0.1.5-1"
source = {
  url = "git://github.com/hjson/hjson-lua.git",
}
description = {
  summary = "A lightweight H/JSON library for Lua.",
  homepage = "https://github.com/hjson/hjson-lua",
  license = "MIT"
}
dependencies = {
  "lua >= 5.3"
}
build = {
  type = "builtin",
  modules = {
    ["hjson"] = "hjson.lua",
    ["hjson.decoder"] = "hjson/decoder.lua",
    ["hjson.encoder"] = "hjson/encoder.lua",
    ["hjson.encoderH"] = "hjson/encoderH.lua"
  }
}