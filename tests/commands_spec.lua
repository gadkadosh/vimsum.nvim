for _, suffix in ipairs({ "", "!" }) do
    describe("vimsum commands" .. suffix, function()
        local buffer
        local original_notify
        local notifications
        local original_print
        local messages

        before_each(function()
            buffer = vim.api.nvim_create_buf(false, false)
            vim.api.nvim_set_current_buf(buffer)
            vim.cmd("messages clear")
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

                vim.cmd("2,4" .. case.command .. suffix)

                assert.same(lines, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
                local kind = case.command == "SumTimes" and "duration" or "number"
                assert.same({ {
                    message = "Invalid " .. kind .. " on line 3: expected " .. case.expected,
                    level = vim.log.levels.ERROR,
                } }, notifications)
                assert.equals("", vim.fn.execute("messages"))
            end)
        end

        for _, command in ipairs({ "SumTimes", "SumColumn" }) do
            for _, range in ipairs({ "", "2,2" }) do
                it(command .. " rejects " .. (range == "" and "a missing range" or "a single-line range"), function()
                    local lines = { "outside range", "0130", "0045", "outside range" }
                    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
                    vim.api.nvim_win_set_cursor(0, { 2, 0 })

                    vim.cmd(range .. command .. suffix)

                    assert.same({ "Must be a range" }, messages)
                    assert.same(lines, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
                    assert.same({}, notifications)
                    assert.equals("", vim.fn.execute("messages"))
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

                vim.cmd("2,3" .. case.command .. suffix)

                assert.same(lines, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
                local kind = case.command == "SumTimes" and "duration" or "number"
                local expected = case.command == "SumTimes"
                    and "digits only and a total of at most 9007199254740991 hours"
                    or "a finite number and total"
                assert.same({ {
                    message = "Invalid " .. kind .. " on line " .. case.line .. ": expected " .. expected,
                    level = vim.log.levels.ERROR,
                } }, notifications)
                assert.equals("", vim.fn.execute("messages"))
            end)
        end

        local cases = {
            { command = "SumTimes", lines = { "0130", "0045" }, total = "Total: 02:15 · 2 entries" },
            { command = "SumTimes", lines = { "0030", "0030" }, total = "Total: 01:00 · 2 entries" },
            { command = "SumTimes", lines = { "7711", "8822" }, total = "Total: 165:33 · 2 entries" },
            { command = "SumTimes", lines = { "900719925474099000", "0100" },
                total = "Total: 9007199254740991:00 · 2 entries" },
            { command = "SumColumn", lines = { "1.5", "-2" }, total = "Sum: -0.5 · 2 entries" },
            { command = "SumColumn", lines = { "0", "0" }, total = "Sum: 0 · 2 entries" },
            { command = "SumColumn", lines = { "2", "1", "3" }, total = "Sum: 6 · 3 entries" },
        }

        for _, case in ipairs(cases) do
            for _, visual in ipairs({ false, true }) do
                it(case.command .. " reports " .. case.total .. (visual and " from a visual selection" or " from a range"), function()
                    local lines = { "outside range" }
                    vim.list_extend(lines, case.lines)
                    table.insert(lines, "outside range")
                    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
                    vim.bo[buffer].modified = false
                    local changedtick = vim.api.nvim_buf_get_changedtick(buffer)
                    local last = #case.lines + 1

                    if visual then
                        local keys = vim.api.nvim_replace_termcodes(
                            "2GV" .. last .. "G:" .. case.command .. suffix .. "<CR>", true, false, true)
                        vim.api.nvim_feedkeys(keys, "nxt", false)
                    else
                        vim.cmd("2," .. last .. case.command .. suffix)
                    end

                    if suffix == "!" then
                        table.insert(lines, last + 1, case.total)
                        assert.is_true(vim.bo[buffer].modified)
                        assert.equals("", vim.fn.execute("messages"))
                    else
                        assert.equals(changedtick, vim.api.nvim_buf_get_changedtick(buffer))
                        assert.is_false(vim.bo[buffer].modified)
                        assert.equals("\n" .. case.total, vim.fn.execute("messages"))
                    end
                    assert.same(lines, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
                    assert.same({}, notifications)
                end)
            end
        end
    end)
end

describe("vimsum non-inserting results", function()
    it("can be repeated in an unmodifiable buffer", function()
        local buffer = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "0130", "0045" })
        vim.bo[buffer].modifiable = false
        vim.cmd("messages clear")
        require("vimsum").setup()

        local ok, err = pcall(function()
            vim.cmd("1,2SumTimes")
            vim.cmd("1,2SumTimes")
            assert.equals("\nTotal: 02:15 · 2 entries\nTotal: 02:15 · 2 entries", vim.fn.execute("messages"))
            assert.same({ "0130", "0045" }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
        end)

        vim.api.nvim_del_user_command("SumTimes")
        vim.api.nvim_del_user_command("SumColumn")
        vim.api.nvim_buf_delete(buffer, { force = true })
        assert.is_true(ok, err)
    end)
end)
