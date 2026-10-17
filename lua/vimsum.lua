local M = {}

---@param value string|number
---@return number|nil
local function finite_number(value)
    local number = tonumber(value)
    if number and number == number and math.abs(number) ~= math.huge then
        return number
    end
end

---Sum durations, or return nil and the index of the first invalid line.
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
        if h == nil then
            return nil, line
        end
        hours = hours + h
        minutes = minutes + m
    end

    hours = hours + math.floor(minutes / 60)
    minutes = minutes % 60

    return hours, minutes
end

---Sum numbers, or return nil and the index of the first invalid line.
---@param numbers (number|string)[]
---@return number|nil, number|nil
local function sum_numbers(numbers)
    local sum = 0
    for line, i in ipairs(numbers) do
        local number = finite_number(i)
        if number == nil then
            return nil, line
        end
        sum = sum + number
    end
    return sum
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
                .. ": expected a finite HHMM duration (digits only)", vim.log.levels.ERROR)
            return
        end

        local total = string.format("%02d%02d", hours, minutes)
        vim.fn.append(args.line2, args.line1 .. "-" .. args.line2 .. " Total: " .. total)
    end, { range = true })

    vim.api.nvim_create_user_command("SumColumn", function(args)
        if args.line1 == args.line2 then
            print("Must be a range")
            return
        end
        local nums = vim.api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false)
        local sum, invalid_line = sum_numbers(nums)
        if sum == nil then
            vim.notify("Invalid number on line " .. (args.line1 + invalid_line - 1)
                .. ": expected a finite number", vim.log.levels.ERROR)
            return
        end
        vim.fn.append(args.line2, args.line1 .. "-" .. args.line2 .. " Sum: " .. sum)
    end, { range = true })
end

-- For internal testing
M._sum_durations = sum_durations
M._sum_numbers = sum_numbers

return M
