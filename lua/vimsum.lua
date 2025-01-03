M = {}

---Sum up a list of durations and return hours and minutes
---@param durations string[]
---@return number, number
local function sum_durations(durations)
    local hours = 0
    local minutes = 0

    for _, i in pairs(durations) do
        local len = string.len(i)
        local m = tonumber(string.sub(i, len - 1, len))
        local h
        if len > 2 then
            h = tonumber(string.sub(i, 1, len - 2))
        else
            h = 0
        end
        hours = hours + h
        minutes = minutes + m
    end

    hours = hours + math.floor(minutes / 60)
    minutes = minutes % 60

    return hours, minutes
end

---Sum up a list of numbers
---@param numbers number[]
---@return number
local function sum_numbers(numbers)
    local sum = 0
    for _, i in pairs(numbers) do
        if tonumber(i) ~= nil then
            sum = sum + i
        end
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

        local total = string.format("%02d%02d", hours, minutes)
        vim.fn.append(args.line2, args.line1 .. "-" .. args.line2 .. " Total: " .. total)
    end, { range = true })

    vim.api.nvim_create_user_command("SumColumn", function(args)
        if args.line1 == args.line2 then
            print("Must be a range")
            return
        end
        local nums = vim.api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false)
        local sum = sum_numbers(nums)
        vim.fn.append(args.line2, args.line1 .. "-" .. args.line2 .. " Sum: " .. sum)
    end, { range = true })
end

-- For internal testing
M._sum_durations = sum_durations
M._sum_numbers = sum_numbers

return M
