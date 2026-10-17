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

    for _, invalid in ipairs({ "", " ", "oops", "1:30", "-130", "+130", "1.30", "0130 ", string.rep("9", 400) }) do
        it("rejects invalid duration " .. string.format("%q", invalid), function()
            local hours, invalid_line = sum_durations({ "0130", invalid, "0045" })
            assert.is_nil(hours)
            assert.equals(2, invalid_line)
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
