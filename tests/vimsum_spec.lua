describe("vimsum.sum_numbers", function()
    local sum_numbers = require("vimsum")._sum_numbers

    it("only 0", function()
        local sum = sum_numbers({ 0 })
        assert.equals(sum, 0)
    end)

    it("one number", function()
        local sum = sum_numbers({ 5 })
        assert.equals(sum, 5)
    end)

    it("negative number", function()
        local sum = sum_numbers({ -5 })
        assert.equals(sum, -5)
    end)

    it("two numbers", function()
        local sum = sum_numbers({ 5, 6 })
        assert.equals(sum, 11)
    end)

    it("two numbers, negative", function()
        local sum = sum_numbers({ 5, -6 })
        assert.equals(sum, -1)
    end)

    it("multiple numbers", function()
        local sum = sum_numbers({ 1, 2, 3, 4, 5 })
        assert.equals(sum, 15)
    end)

    it("multiple numbers, negative", function()
        local sum = sum_numbers({ 1, 2, -3, 4, 5 })
        assert.equals(sum, 9)
    end)

    it("high numbers", function()
        local sum = sum_numbers({ 123, 4 })
        assert.equals(sum, 127)
    end)

    it("accepts numeric strings from buffer lines", function()
        local sum = sum_numbers({ "1.5", "-2", " 3 " })
        assert.equals(2.5, sum)
    end)

    for _, value in ipairs({ "1e308", "-1e308" }) do
        it("rejects a non-finite running total from " .. value, function()
            local sum, invalid_line = sum_numbers({ value, value })
            assert.is_nil(sum)
            assert.equals(2, invalid_line)
        end)
    end

    for _, invalid in ipairs({ "bla", "", " ", "nan", "inf", "1e999" }) do
        it("rejects invalid number " .. string.format("%q", invalid), function()
            local sum, invalid_line = sum_numbers({ "1", invalid, "3" })
            assert.is_nil(sum)
            assert.equals(2, invalid_line)
        end)
    end
end)

describe("vimsum.sum_durations", function()
    local sum_durations = require("vimsum")._sum_durations

    it("0 minutes", function()
        local hours, minutes = sum_durations({ "00" })
        assert.equals(hours, 0)
        assert.equals(minutes, 0)
    end)

    it("only minutes", function()
        local hours, minutes = sum_durations({ "10" })
        assert.equals(hours, 0)
        assert.equals(minutes, 10)
    end)

    it("only hours", function()
        local hours, minutes = sum_durations({ "100" })
        assert.equals(hours, 1)
        assert.equals(minutes, 0)
    end)

    it("four digits", function()
        local hours, minutes = sum_durations({ "1111" })
        assert.equals(hours, 11)
        assert.equals(minutes, 11)
    end)

    it("five digits", function()
        local hours, minutes = sum_durations({ "22222" })
        assert.equals(hours, 222)
        assert.equals(minutes, 22)
    end)

    it("add minutes only", function()
        local hours, minutes = sum_durations({ "22", "11" })
        assert.equals(hours, 0)
        assert.equals(minutes, 33)
    end)

    it("add minutes only, leading zeroes", function()
        local hours, minutes = sum_durations({ "0022", "0011" })
        assert.equals(hours, 0)
        assert.equals(minutes, 33)
    end)

    it("add hours only", function()
        local hours, minutes = sum_durations({ "1100", "2200" })
        assert.equals(hours, 33)
        assert.equals(minutes, 0)
    end)

    it("add hours only, leading zeroes", function()
        local hours, minutes = sum_durations({ "01100", "002200" })
        assert.equals(hours, 33)
        assert.equals(minutes, 0)
    end)

    it("add hours and minutes", function()
        local hours, minutes = sum_durations({ "1111", "2222" })
        assert.equals(hours, 33)
        assert.equals(minutes, 33)
    end)

    it("more than 60 minutes corrected to add an hour", function()
        local hours, minutes = sum_durations({ "7777" })
        assert.equals(hours, 78)
        assert.equals(minutes, 17)
    end)

    it("add hours and minutes, sum larger than 100 hours", function()
        local hours, minutes = sum_durations({ "7711", "8822" })
        assert.equals(hours, 165)
        assert.equals(minutes, 33)
    end)

    it("mix hours/minutes and minutes only", function()
        local hours, minutes = sum_durations({ "7711", "22" })
        assert.equals(hours, 77)
        assert.equals(minutes, 33)
    end)

    it("accepts a single digit as minutes", function()
        local hours, minutes = sum_durations({ "1", "2" })
        assert.equals(0, hours)
        assert.equals(3, minutes)
    end)

    for _, case in ipairs({
        { values = { "1:30", "0:45" }, hours = 2, minutes = 15 },
        { values = { " 1:30\t", "\t0045 " }, hours = 2, minutes = 15 },
        { values = { " 0130 ", "\t45\t" }, hours = 2, minutes = 15 },
        { values = { "0001:30", "100:00", "1" }, hours = 101, minutes = 31 },
        { values = { "0:00", "00" }, hours = 0, minutes = 0 },
        { values = { "0175", "0:75" }, hours = 3, minutes = 30 },
        { values = { "9007199254740990:59", "0:01" }, hours = 9007199254740991, minutes = 0 },
    }) do
        it("accepts duration formats: " .. table.concat(case.values, ", "), function()
            local hours, minutes = sum_durations(case.values)
            assert.equals(case.hours, hours)
            assert.equals(case.minutes, minutes)
        end)
    end

    for _, invalid in ipairs({
        "", " ", "\t", "oops", "-130", "+130", "1.30", "1:3", "1:030", ":30", "1:",
        "1:30:00", "1 :30", "1: 30", "01 30", "-1:30", "+1:30", "1:3x", "1.5:30",
        string.rep("9", 400), string.rep("9", 400) .. ":00",
    }) do
        it("rejects invalid duration " .. string.format("%q", invalid), function()
            local hours, invalid_line = sum_durations({ "0130", invalid, "0045" })
            assert.is_nil(hours)
            assert.equals(2, invalid_line)
        end)
    end

    it("accepts the largest exact hour total", function()
        local hours, minutes = sum_durations({ "900719925474099000", "0100" })
        assert.equals(9007199254740991, hours)
        assert.equals(0, minutes)
    end)

    it("accepts a minute carry into the largest exact hour total", function()
        local hours, minutes = sum_durations({ "900719925474099059", "01" })
        assert.equals(9007199254740991, hours)
        assert.equals(0, minutes)
    end)

    for _, durations in ipairs({
        { "900719925474099200" },
        { "1" .. string.rep("0", 308) .. "00" },
        { "900719925474099100", "0100" },
        { "900719925474099159", "01" },
        { "9007199254740992:00" },
        { "9007199254740991:59", "0:01" },
    }) do
        it("rejects an hour total beyond the exact-integer range: " .. table.concat(durations, ", "), function()
            local hours, invalid_line = sum_durations(durations)
            assert.is_nil(hours)
            assert.equals(#durations, invalid_line)
        end)
    end

    it("Many durations", function()
        local durations = {}
        for i = 1, 9 do
            durations[i] = string.rep(i, 4)
        end
        local hours, minutes = sum_durations(durations)
        assert.equals(hours, 503)
        assert.equals(minutes, 15)
    end)
end)
