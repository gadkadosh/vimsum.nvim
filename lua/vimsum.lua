M = {}

---Sum a column of times
---@param lstart number
---@param lend number
local function sum_times(lstart, lend)
    if lstart == lend then
        print("Must be a range")
        return
    end
    local times = vim.api.nvim_buf_get_lines(0, lstart - 1, lend, false)
    local hours = 0
    local minutes = 0
    for _, i in pairs(times) do
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
    local total = string.format("%02d%02d", hours, minutes)
    vim.fn.append(lend, lstart .. "-" .. lend .. " Total: " .. total)
end

---Sum a column of numbers
---@param lstart number
---@param lend number
local function sum_column(lstart, lend)
    if lstart == lend then
        print("Must be a range")
        return
    end
    local nums = vim.api.nvim_buf_get_lines(0, lstart - 1, lend, false)
    local total = 0
    for _, i in pairs(nums) do
        total = total + tonumber(i)
    end
    vim.fn.append(lend, lstart .. "-" .. lend .. " Sum: " .. total)
end

M.setup = function()
    vim.api.nvim_create_user_command("SumTimes", function(args)
        sum_times(args.line1, args.line2)
    end, { range = true })
    vim.api.nvim_create_user_command("SumColumn", function(args)
        sum_column(args.line1, args.line2)
    end, { range = true })
end

return M
