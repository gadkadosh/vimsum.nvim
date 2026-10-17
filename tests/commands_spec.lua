describe("vimsum commands", function()
    local buffer
    local original_notify
    local notifications

    before_each(function()
        buffer = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(buffer)
        notifications = {}
        original_notify = vim.notify
        vim.notify = function(message, level)
            table.insert(notifications, { message = message, level = level })
        end
        require("vimsum").setup()
    end)

    after_each(function()
        vim.notify = original_notify
        vim.api.nvim_del_user_command("SumTimes")
        vim.api.nvim_del_user_command("SumColumn")
        vim.api.nvim_buf_delete(buffer, { force = true })
    end)

    for _, case in ipairs({
        { command = "SumTimes", invalid = "", expected = "a finite HHMM duration (digits only)" },
        { command = "SumTimes", invalid = "1:30", expected = "a finite HHMM duration (digits only)" },
        { command = "SumColumn", invalid = "oops", expected = "a finite number" },
        { command = "SumColumn", invalid = "", expected = "a finite number" },
    }) do
        it(case.command .. " rejects " .. string.format("%q", case.invalid) .. " without changing the buffer", function()
            local lines = { "outside range", "0130", case.invalid, "0045", "outside range" }
            vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

            vim.cmd("2,4" .. case.command)

            assert.same(lines, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
            local kind = case.command == "SumTimes" and "duration" or "number"
            assert.same({ {
                message = "Invalid " .. kind .. " on line 3: expected " .. case.expected,
                level = vim.log.levels.ERROR,
            } }, notifications)
        end)
    end

    for _, case in ipairs({
        { command = "SumTimes", lines = { "0130", "0045" }, total = "2-3 Total: 0215" },
        { command = "SumColumn", lines = { "1.5", "-2" }, total = "2-3 Sum: -0.5" },
    }) do
        it(case.command .. " appends the total immediately after the selected range", function()
            vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "outside range", case.lines[1], case.lines[2], "outside range" })

            vim.cmd("2,3" .. case.command)

            assert.same({ "outside range", case.lines[1], case.lines[2], case.total, "outside range" },
                vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
            assert.same({}, notifications)
        end)
    end
end)
