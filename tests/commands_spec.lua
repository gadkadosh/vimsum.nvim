describe("vimsum commands", function()
    local buffer
    local original_notify
    local notifications
    local original_print
    local messages

    before_each(function()
        buffer = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(buffer)
        notifications = {}
        original_notify = vim.notify
        vim.notify = function(message, level)
            table.insert(notifications, { message = message, level = level })
        end
        original_print = _G.print
        messages = {}
        _G.print = function(message)
            table.insert(messages, message)
        end
        require("vimsum").setup()
    end)

    after_each(function()
        vim.notify = original_notify
        _G.print = original_print
        vim.api.nvim_del_user_command("SumTimes")
        vim.api.nvim_del_user_command("SumColumn")
        vim.api.nvim_buf_delete(buffer, { force = true })
    end)

    for _, case in ipairs({
        { command = "SumTimes", invalid = "", expected = "digits only and a total of at most 9007199254740991 hours" },
        { command = "SumTimes", invalid = "1:30", expected = "digits only and a total of at most 9007199254740991 hours" },
        { command = "SumColumn", invalid = "oops", expected = "a finite number and total" },
        { command = "SumColumn", invalid = "", expected = "a finite number and total" },
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

    for _, command in ipairs({ "SumTimes", "SumColumn" }) do
        for _, range in ipairs({ "", "2,2" }) do
            it(command .. " rejects " .. (range == "" and "a missing range" or "a single-line range"), function()
                local lines = { "outside range", "0130", "0045", "outside range" }
                vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
                vim.api.nvim_win_set_cursor(0, { 2, 0 })

                vim.cmd(range .. command)

                assert.same({ "Must be a range" }, messages)
                assert.same(lines, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
                assert.same({}, notifications)
            end)
        end
    end

    for _, case in ipairs({
        { command = "SumColumn", lines = { "1e308", "1e308" }, line = 3 },
        { command = "SumColumn", lines = { "-1e308", "-1e308" }, line = 3 },
        { command = "SumTimes", lines = { "900719925474099100", "0100" }, line = 3 },
        { command = "SumTimes", lines = { "900719925474099159", "01" }, line = 3 },
        { command = "SumTimes", lines = { "1" .. string.rep("0", 308) .. "00", "0100" }, line = 2 },
    }) do
        it(case.command .. " rejects an unrepresentable total for " .. case.lines[1], function()
            local lines = { "outside range", case.lines[1], case.lines[2], "outside range" }
            vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

            vim.cmd("2,3" .. case.command)

            assert.same(lines, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
            local kind = case.command == "SumTimes" and "duration" or "number"
            local expected = case.command == "SumTimes"
                and "digits only and a total of at most 9007199254740991 hours"
                or "a finite number and total"
            assert.same({ {
                message = "Invalid " .. kind .. " on line " .. case.line .. ": expected " .. expected,
                level = vim.log.levels.ERROR,
            } }, notifications)
        end)
    end

    for _, case in ipairs({
        { command = "SumTimes", lines = { "0130", "0045" }, total = "2-3 Total: 0215" },
        { command = "SumTimes", lines = { "0030", "0030" }, total = "2-3 Total: 0100" },
        { command = "SumTimes", lines = { "7711", "8822" }, total = "2-3 Total: 16533" },
        { command = "SumTimes", lines = { "900719925474099000", "0100" }, total = "2-3 Total: 900719925474099100" },
        { command = "SumColumn", lines = { "1.5", "-2" }, total = "2-3 Sum: -0.5" },
    }) do
        it(case.command .. " appends " .. case.total .. " immediately after the selected range", function()
            vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "outside range", case.lines[1], case.lines[2], "outside range" })

            vim.cmd("2,3" .. case.command)

            assert.same({ "outside range", case.lines[1], case.lines[2], case.total, "outside range" },
                vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
            assert.same({}, notifications)
        end)
    end

    for _, case in ipairs({
        { command = "SumTimes", lines = { "0130", "0045" }, total = "2-3 Total: 0215" },
        { command = "SumColumn", lines = { "1.5", "-2" }, total = "2-3 Sum: -0.5" },
    }) do
        it(case.command .. " sums a linewise visual selection", function()
            vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "outside range", case.lines[1], case.lines[2], "outside range" })

            local keys = vim.api.nvim_replace_termcodes("2GVj:" .. case.command .. "<CR>", true, false, true)
            vim.api.nvim_feedkeys(keys, "nxt", false)

            assert.same({ "outside range", case.lines[1], case.lines[2], case.total, "outside range" },
                vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
            assert.same({}, notifications)
        end)
    end
end)
