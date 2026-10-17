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

    for line, value in ipairs(durations) do
        value = vim.trim(value)
        local h, m = value:match("^(%d+):(%d%d)$")
        if h == nil then
            if not value:match("^%d+$") then
                return nil, line
            end
            h = #value > 2 and value:sub(1, -3) or "0"
            m = value:sub(-2)
        end
        m = tonumber(m)
        if m > 59 then
            return nil, line
        end
        h = finite_number(h)
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

---@param args vim.api.keyset.create_user_command.command_args
---@param label string
---@param total string|number
---@return nil
local function show_result(args, label, total)
    local message = label .. ": " .. total .. " · " .. (args.line2 - args.line1 + 1) .. " entries"
    if args.bang then
        vim.fn.append(args.line2, message)
    else
        vim.api.nvim_echo({ { message } }, true, {})
    end
end

---@return nil
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
                .. ": expected digits or H:MM with minutes 00-59"
                .. " and a total of at most 9007199254740991 hours", vim.log.levels.ERROR)
            return
        end

        show_result(args, "Total", string.format("%02d:%02d", hours, minutes))
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
