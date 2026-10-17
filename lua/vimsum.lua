local M = {}
-- LuaJIT has no math.maxinteger; doubles represent every integer exactly only up to 2^53 - 1.
local MAX_DURATION_HOURS = 2 ^ 53 - 1

---@param value string|number
---@return number|nil
local function finite_number(value)
    local number = tonumber(value)
    if number and number == number and math.abs(number) ~= math.huge then
        return number
    end
end

---Sum durations, or return nil and the first line with invalid input or an unrepresentable total.
---@param durations string[]
---@return number|nil, number
local function sum_durations(durations)
    local hours = 0
    local minutes = 0

    for line, i in ipairs(durations) do
        if not i:match("^%d+$") then
            return nil, line
        end
        local len = string.len(i)
        local m = tonumber(string.sub(i, len - 1, len))
        local h
        if len > 2 then
            h = finite_number(string.sub(i, 1, len - 2))
        else
            h = 0
        end
        minutes = minutes + m
        local carry = math.floor(minutes / 60)
        if h == nil or h > MAX_DURATION_HOURS - hours - carry then
            return nil, line
        end
        hours = hours + h + carry
        minutes = minutes % 60
    end

    return hours, minutes
end

---Sum numbers, or return nil and the first line with invalid input or a non-finite total.
---@param numbers (number|string)[]
---@return number|nil, number|nil
local function sum_numbers(numbers)
    local sum = 0
    for line, i in ipairs(numbers) do
        local number = finite_number(i)
        if number == nil then
            return nil, line
        end
        sum = finite_number(sum + number)
        if sum == nil then
            return nil, line
        end
    end
    return sum
end

local function show_result(args, label, total, display_total)
    if args.bang then
        vim.fn.append(args.line2, args.line1 .. "-" .. args.line2 .. " " .. label .. ": " .. total)
    else
        local message = label .. ": " .. (display_total or total) .. " · " .. (args.line2 - args.line1 + 1) .. " entries"
        vim.api.nvim_echo({ { message } }, true, {})
    end
end

M.setup = function()
    vim.api.nvim_create_user_command("SumTimes", function(args)
        if args.line1 == args.line2 then
            print("Must be a range")
            return
        end
        local times = vim.api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false)
        local hours, minutes = sum_durations(times)
        if hours == nil then
            vim.notify("Invalid duration on line " .. (args.line1 + minutes - 1)
                .. ": expected digits only and a total of at most 9007199254740991 hours", vim.log.levels.ERROR)
            return
        end

        local total = string.format("%02d%02d", hours, minutes)
        show_result(args, "Total", total, string.format("%02d:%02d", hours, minutes))
    end, { range = true, bang = true })

    vim.api.nvim_create_user_command("SumColumn", function(args)
        if args.line1 == args.line2 then
            print("Must be a range")
            return
        end
        local nums = vim.api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false)
        local sum, invalid_line = sum_numbers(nums)
        if sum == nil then
            vim.notify("Invalid number on line " .. (args.line1 + invalid_line - 1)
                .. ": expected a finite number and total", vim.log.levels.ERROR)
            return
        end
        show_result(args, "Sum", sum)
    end, { range = true, bang = true })
end

-- For internal testing
M._sum_durations = sum_durations
M._sum_numbers = sum_numbers

return M
