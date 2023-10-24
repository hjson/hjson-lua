-- MIT License - Copyright (c) 2023 V (alis.is)
package.preload["hjson"] = nil --- remove default hjson
package.path = package.path .. ";./hjson/?.lua"

json = require("test.json")
hjson = require("hjson")

decode = hjson.decode
encode = hjson.encode_to_json
encodeH = hjson.encode

test_decoder = true
test_encoder = true
test_encoderH = true

tests_override = {}

tests = {
    "test/assets/charset2_test.hjson",
    "test/assets/charset_test.hjson",
    "test/assets/comments_test.hjson",
    "test/assets/empty_test.hjson",
    "test/assets/extra/notabs_test.json",
    "test/assets/extra/root_test.hjson",
    "test/assets/extra/separator_test.json",
    "test/assets/failCharset1_test.hjson",
    "test/assets/failJSON02_test.json",
    "test/assets/failJSON05_test.json",
    "test/assets/failJSON06_test.json",
    "test/assets/failJSON07_test.json",
    "test/assets/failJSON08_test.json",
    "test/assets/failJSON10_test.json",
    "test/assets/failJSON11_test.json",
    "test/assets/failJSON12_test.json",
    "test/assets/failJSON13_test.json",
    "test/assets/failJSON14_test.json",
    "test/assets/failJSON15_test.json",
    "test/assets/failJSON16_test.json",
    "test/assets/failJSON17_test.json",
    "test/assets/failJSON19_test.json",
    "test/assets/failJSON20_test.json",
    "test/assets/failJSON21_test.json",
    "test/assets/failJSON22_test.json",
    "test/assets/failJSON23_test.json",
    "test/assets/failJSON26_test.json",
    "test/assets/failJSON28_test.json",
    "test/assets/failJSON29_test.json",
    "test/assets/failJSON30_test.json",
    "test/assets/failJSON31_test.json",
    "test/assets/failJSON32_test.json",
    "test/assets/failJSON33_test.json",
    "test/assets/failJSON34_test.json",
    "test/assets/failKey1_test.hjson",
    "test/assets/failKey2_test.hjson",
    "test/assets/failKey3_test.hjson",
    "test/assets/failKey4_test.hjson",
    "test/assets/failKey5_test.hjson",
    "test/assets/failMLStr1_test.hjson",
    "test/assets/failObj1_test.hjson",
    "test/assets/failObj2_test.hjson",
    "test/assets/failObj3_test.hjson",
    "test/assets/failStr1a_test.hjson",
    "test/assets/failStr1b_test.hjson",
    "test/assets/failStr1c_test.hjson",
    "test/assets/failStr1d_test.hjson",
    "test/assets/failStr2a_test.hjson",
    "test/assets/failStr2b_test.hjson",
    "test/assets/failStr2c_test.hjson",
    "test/assets/failStr2d_test.hjson",
    "test/assets/failStr3a_test.hjson",
    "test/assets/failStr3b_test.hjson",
    "test/assets/failStr3c_test.hjson",
    "test/assets/failStr3d_test.hjson",
    "test/assets/failStr4a_test.hjson",
    "test/assets/failStr4b_test.hjson",
    "test/assets/failStr4c_test.hjson",
    "test/assets/failStr4d_test.hjson",
    "test/assets/failStr5a_test.hjson",
    "test/assets/failStr5b_test.hjson",
    "test/assets/failStr5c_test.hjson",
    "test/assets/failStr5d_test.hjson",
    "test/assets/failStr6a_test.hjson",
    "test/assets/failStr6b_test.hjson",
    "test/assets/failStr6c_test.hjson",
    "test/assets/failStr6d_test.hjson",
    "test/assets/failStr7a_test.hjson",
    "test/assets/failStr8a_test.hjson",
    "test/assets/kan_test.hjson",
    "test/assets/keys_test.hjson",
    "test/assets/mltabs_test.json",
    "test/assets/oa_test.hjson",
    "test/assets/pass1_test.json",
    "test/assets/pass2_test.json",
    "test/assets/pass3_test.json",
    "test/assets/pass4_test.json",
    "test/assets/passSingle_test.hjson",
    "test/assets/stringify/quotes_all_test.hjson",
    "test/assets/stringify/quotes_always_test.hjson",
    "test/assets/stringify/quotes_keys_test.hjson",
    "test/assets/stringify/quotes_strings_ml_test.json",
    "test/assets/stringify/quotes_strings_test.hjson",
    "test/assets/stringify1_test.hjson",
    "test/assets/strings2_test.hjson",
    "test/assets/strings_test.hjson",
    "test/assets/trail_test.hjson"
}
results = {
    "test/assets/charset2_result.hjson",
    "test/assets/charset2_result.json",
    "test/assets/charset_result.hjson",
    "test/assets/charset_result.json",
    "test/assets/comments_result.hjson",
    "test/assets/comments_result.json",
    "test/assets/empty_result.hjson",
    "test/assets/empty_result.json",
    "test/assets/extra/notabs_result.hjson",
    "test/assets/extra/notabs_result.json",
    "test/assets/extra/root_result.hjson",
    "test/assets/extra/root_result.json",
    "test/assets/extra/separator_result.hjson",
    "test/assets/extra/separator_result.json",
    "test/assets/kan_result.hjson",
    "test/assets/kan_result.json",
    "test/assets/keys_result.hjson",
    "test/assets/keys_result.json",
    "test/assets/mltabs_result.hjson",
    "test/assets/mltabs_result.json",
    "test/assets/oa_result.hjson",
    "test/assets/oa_result.json",
    "test/assets/pass1_result.hjson",
    "test/assets/pass1_result.json",
    "test/assets/pass2_result.hjson",
    "test/assets/pass2_result.json",
    "test/assets/pass3_result.hjson",
    "test/assets/pass3_result.json",
    "test/assets/pass4_result.hjson",
    "test/assets/pass4_result.json",
    "test/assets/passSingle_result.hjson",
    "test/assets/passSingle_result.json",
    "test/assets/stringify/quotes_all_result.hjson",
    "test/assets/stringify/quotes_all_result.json",
    "test/assets/stringify/quotes_always_result.hjson",
    "test/assets/stringify/quotes_always_result.json",
    "test/assets/stringify/quotes_keys_result.hjson",
    "test/assets/stringify/quotes_keys_result.json",
    "test/assets/stringify/quotes_strings_ml_result.hjson",
    "test/assets/stringify/quotes_strings_ml_result.json",
    "test/assets/stringify/quotes_strings_result.hjson",
    "test/assets/stringify/quotes_strings_result.json",
    "test/assets/stringify1_result.hjson",
    "test/assets/stringify1_result.json",
    "test/assets/strings2_result.hjson",
    "test/assets/strings2_result.json",
    "test/assets/strings_result.hjson",
    "test/assets/strings_result.json",
    "test/assets/trail_result.hjson",
    "test/assets/trail_result.json"
}

function readFile(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

function getResultFile(testFile)
    r = testFile:gsub("_test%..?json", "_result.json")
    for i, v in ipairs(results) do
        if v == r then
            return v
        end
    end
    return nil
end

function print_object(t)
    if type(t) ~= "table" then
        print(t)
    else
        for k, v in pairs(t) do
            _type = type(v)
            if _type == "table" then
                print_object(v)
            else
                print("k:", k, "v:", v)
            end
        end
    end
end

function is_array(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then
            return false
        end
    end
    return true
end

function equal(t1, t2)
    result = true
    if (type(t1) ~= "table") then
        if t1 ~= t2 then
            print(t1, t2)
        end
        return t1 == t2
    end
    for k, v in pairs(t1) do
        _type = type(v)
        if _type ~= type(t2[k]) then
            result = false
            break
        elseif _type == "function" then
            -- ignoring functions
        elseif _type == "table" then
            if not equal(v, t2[k]) then
                result = false
                break
            end
        elseif v ~= t2[k] then
            print('result1: "' .. v .. '", key: ' .. k)
            print('result2: "' .. t2[k] .. '", key: ' .. k)
            result = false
            break
        end
    end
    return result
end

decoder_failed = 0
decoder_skipped = 0
decoder_success = 0

if #tests_override > 0 then
    tests = tests_override
end
if test_decoder then
    print("Running decoder tests: ")
    for i, v in ipairs(tests) do
        shouldfail = v:find("fail")
        file = readFile(v)
        status, decoded_test = pcall(decode, file)
        if shouldfail and not status then
            print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "OK")
            decoder_success = decoder_success + 1
        elseif shouldfail then
            print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "FAILED - should fail")
            decoder_failed = decoder_failed + 1
        elseif not status then
            print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "FAILED - decoder failed - " .. decoded_test)
            decoder_failed = decoder_failed + 1
        else
            rfile = getResultFile(v)
            if not rfile then
                print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "SKIPPED - no result file")
                decoder_skipped = decoder_skipped + 1
            else
                file = readFile(rfile)
                status, decoded_result = pcall(json.decode, file)
                if not status then
                    print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "SKIPPED - failed to parse result file")
                    decoder_skipped = decoder_skipped + 1
                elseif equal(decoded_test, decoded_result) then
                    print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "OK")
                    decoder_success = decoder_success + 1
                else
                    print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "FAILED - results do not match")
                    decoder_failed = decoder_failed + 1
                end
            end
        end
    end
    print("========================")
    print("Decoder testing finished")

    print("Total", #tests, "Success", decoder_success, "Skipped", decoder_skipped, "Failed", decoder_failed)
end

encoder_failed = 0
encoder_skipped = 0
encoder_success = 0

if test_encoder then
    print("Running decoder tests: ")
    for i, v in ipairs(tests) do
        shouldfail = v:find("fail")
        file = readFile(v)
        status, decoded_test = pcall(decode, file)

        if shouldfail and not status then
            print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "OK")
            encoder_success = encoder_success + 1
        elseif shouldfail then
            print(
                tostring(i) .. "/" .. tostring(#tests) .. " - " .. v,
                "SKIPPED - decode of the test file should fail and succeeded"
            )
            encoder_skipped = encoder_skipped + 1
        elseif not status then
            print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "SKIPPED - decode of the test file failed")
            encoder_skipped = encoder_skipped + 1
        else
            status, encoded_test = pcall(encode, decoded_test)
            if not status then
                print(
                    tostring(i) .. "/" .. tostring(#tests) .. " - " .. v,
                    "FAILED - encoder failed - " .. encoded_test
                )
                encoder_failed = encoder_failed + 1
            else
                rfile = getResultFile(v)
                if not rfile then
                    print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "SKIPPED - no result file")
                    encoder_skipped = encoder_skipped + 1
                else
                    status, decoded_test = pcall(json.decode, encoded_test)
                    if not status then
                    else
                        file = readFile(rfile)
                        status, decoded_result = pcall(json.decode, file)
                        if not status then
                            print(
                                tostring(i) .. "/" .. tostring(#tests) .. " - " .. v,
                                "SKIPPED - failed to parse result file"
                            )
                            encoder_skipped = encoder_skipped + 1
                        elseif equal(decoded_test, decoded_result) then
                            print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "OK")
                            encoder_success = encoder_success + 1
                        else
                            print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "FAILED - results do not match")
                            encoder_failed = encoder_failed + 1
                        end
                    end
                end
            end
        end
    end
    print("========================")
    print("Encoder testing finished")

    print("Total", #tests, "Success", encoder_success, "Skipped", encoder_skipped, "Failed", encoder_failed)
end

encoderH_failed = 0
encoderH_skipped = 0
encoderH_success = 0

if test_encoderH then
    print("Running decoder tests: ")
    for i, v in ipairs(tests) do
        shouldfail = v:find("fail")
        file = readFile(v)
        status, decoded_test = pcall(decode, file)

        if shouldfail and not status then
            print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "OK")
            encoderH_success = encoderH_success + 1
        elseif shouldfail then
            print(
                tostring(i) .. "/" .. tostring(#tests) .. " - " .. v,
                "SKIPPED - decode of the test file should fail and succeeded"
            )
            encoderH_skipped = encoderH_skipped + 1
        elseif not status then
            print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "SKIPPED - decode of the test file failed")
            encoderH_skipped = encoderH_skipped + 1
        else
            status, encoded_test = pcall(encodeH, decoded_test)
            if not status then
                print(
                    tostring(i) .. "/" .. tostring(#tests) .. " - " .. v,
                    "FAILED - encoder failed - " .. encoded_test
                )
                encoderH_failed = encoderH_failed + 1
            else
                rfile = getResultFile(v)
                if not rfile then
                    print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "SKIPPED - no result file")
                    encoderH_skipped = encoderH_skipped + 1
                else
                    status, decoded_test = pcall(decode, encoded_test)
                    if not status then
                    else
                        file = readFile(rfile)
                        status, decoded_result = pcall(json.decode, file)
                        if not status then
                            print(
                                tostring(i) .. "/" .. tostring(#tests) .. " - " .. v,
                                "SKIPPED - failed to parse result file"
                            )
                            encoderH_skipped = encoderH_skipped + 1
                        elseif equal(decoded_test, decoded_result) then
                            print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "OK")
                            encoderH_success = encoderH_success + 1
                        else
                            print(tostring(i) .. "/" .. tostring(#tests) .. " - " .. v, "FAILED - results do not match")
                            encoderH_failed = encoderH_failed + 1
                        end
                    end
                end
            end
        end
    end
    print("========================")
    print("EncoderH testing finished")

    print("Total", #tests, "Success", encoderH_success, "Skipped", encoderH_skipped, "Failed", encoderH_failed)
end

print("\n\n\n================     HJSON.lua TEST RESULTS        =================")
total_tests = 0
total_success = 0
total_skipped = 0
total_failed = 0
if test_decoder then
    print("Decoder Tests", #tests, "Success", decoder_success, "Skipped", decoder_skipped, "Failed", decoder_failed)
    total_tests = total_tests + #tests
    total_success = total_success + decoder_success
    total_skipped = total_skipped + decoder_skipped
    total_failed = total_failed + decoder_failed
end
if test_encoder then
    print("Encoder Tests", #tests, "Success", encoder_success, "Skipped", encoder_skipped, "Failed", encoder_failed)
    total_tests = total_tests + #tests
    total_success = total_success + encoder_success
    total_skipped = total_skipped + encoder_skipped
    total_failed = total_failed + encoder_failed
end
if test_encoderH then
    print("EncoderH Tests", #tests, "Success", encoderH_success, "Skipped", encoderH_skipped, "Failed", encoderH_failed)
    total_tests = total_tests + #tests
    total_success = total_success + encoderH_success
    total_skipped = total_skipped + encoderH_skipped
    total_failed = total_failed + encoderH_failed
end
print("--------------------------------------------------------------------")
print("Total\t", total_tests, "Success", total_success, "Skipped", total_skipped, "Failed", total_failed)
print(
    "Total (%)",
    "100%",
    "Success",
    tostring((total_success * 100) / total_tests) .. "%",
    "Skipped",
    tostring((total_skipped * 100) / total_tests) .. "%",
    "Failed",
    tostring((total_failed * 100) / total_tests) .. "%"
)
