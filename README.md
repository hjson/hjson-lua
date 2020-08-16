# hjson-lua
A lightweight H/JSON library for Lua

Ported from [hjson-py](https://github.com/hjson/hjson-py). Inspired by rxi - [json.lua](https://github.com/rxi/json.lua).

* Implemented in pure Lua: tested with Lua 5.3 and 5.4

## Setup

### Lua Rocks

```sh
luarocks install hjson-lua
```
### Manual

1. drop [hjson.lua](tree/master/hjson.lua) and [hjson folder](tree/master/hjson) folder into your project
2. require hjson.lua
   * `hjson = require "hjson"`

## Usage

Library exports json.lua like and JS like api.

- Lua object to HJSON - returns HJSON string
  - `encode(obj, options)` 
  - `stringify(obj, options)`
  - Parameters:
    - `obj` - Lua object - `table`, `string`, `number`, `nil`, `boolean`
    - `options` table with following values:
      - `indent` - default `"    "`. Accepts string of whitespace characters or a number representing number of spaces (non indented HJSON is JSON, automatically forwards to `_to_json` version)
      - `skipkeys` - default `true`  Skips invalid keys. If false throws error on invalid key.
        - Valid key types: `boolean`, `nil`, `string`
      - `item_sort_key` - sort function which is passed to `table.sort` sorting object keys 
      - `invalidObjectsAsType` if true functions and others objects are replaced with their type name in format `__lua_<type>` e.g. `__lua_function`
- Lua object to JSON - returns JSON string
  - `encode(obj, options)` 
  - `stringify(obj, options)`
  - Parameters:
    - `obj` - Lua object - `table`, `string`, `number`, `nil`, `boolean`
    - `options` table with following values:
      - `indent` - default `"    "`. Accepts string of whitespace characters or a number representing number of spaces (non indented HJSON is JSON, automatically forwards to `_to_json` version)
      - `skipkeys` - default `true`  Skips invalid keys. If false throws error on invalid key.
        - Valid key types: `boolean`, `nil`, `string`
      - `item_sort_key` - sort function which is passed to `table.sort` sorting object keys 
      - `invalidObjectsAsType` if true functions and others objects are replaced with their type name in format `__lua_<type>` e.g. `__lua_function`
- H/JSON to Lua object - returns Lua object
    - `decode(str, strict, object_hook, object_pairs_hook)`
    - `parse(str, strict, object_hook, object_pairs_hook)`
    - Parameters:
      - `str` has to be valid HJSON string
      - `strict` default `true` . If true parse/decode fails on invalid control characters.
      - `object_hook` - `function(obj)` hook which allows to adjust tables generated from JSON on per JSON object basis (including nested objects). `obj` is lua `table`.
      - `object_pairs_hook` - `function(pairs)` hook which allows to adjust table before generation. `pairs` is table (in array form) composited from `key/value` pairs. It is called before the table for `object_hook` is generated.

*`null` values contained within an array or object are converted to `nil` and are therefore lost upon decoding.*

## License
This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.