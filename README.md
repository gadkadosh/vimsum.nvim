# VimSum

Sum numbers or durations, one per line.

## Installation

Using **lazy.nvim** drop the following into your config, or do the equivalent for your plugin manager of choice:

```lua
{
    "gadkadosh/vimsum.nvim",
    config = function()
        require("vimsum").setup()
    end
}
```

## Usage

Select two or more lines using linewise visual mode (`V`), with one number or duration per line.

Run `:SumColumn` to sum numbers, or `:SumTimes` to sum durations. Choose the command explicitly; VimSum does not infer the input type.

Durations accept either digits only (`0130`) or `H:MM` (`1:30`), both meaning 1 hour 30 minutes. You can mix formats in a selection, and surrounding spaces and tabs are ignored.

In digits-only input, the last two digits are minutes (`45` means 45 minutes); in `H:MM`, hours need at least one digit and minutes exactly two. Hours can exceed 24, but each minute component must be between 0 and 59. Values such as `175`, `0175`, and `1:75` are rejected, not interpreted as total minutes or normalized. Summed minutes still carry into hours (`0:45` + `0030` = `01:15`). Invalid input reports the line without changing the buffer, even with `!`.

To sum plain minute quantities such as `175` and `25`, use `:SumColumn`; the result is a number (`200`), not a formatted duration.

The total and entry count appear in Neovim's message area without changing the buffer. Use `:messages` to see the result again.

Add `!` (`:SumColumn!` or `:SumTimes!`) to append the same result below the selection instead.

### Optional keymaps

VimSum does not define any keymaps. Choose your own bindings; for example, add this `keys` field to the **lazy.nvim** plugin spec above:

```lua
keys = {
    { "<leader>st", ":SumTimes<CR>", mode = "x", desc = "Sum durations" },
    { "<leader>sc", ":SumColumn<CR>", mode = "x", desc = "Sum numbers" },
},
```

Select lines with `V`, then use your chosen binding to see the total.

### Example

Given these lines:

```text
1:30
0045
```

Select both lines and run `:SumTimes`. The buffer stays unchanged, and the message area shows:

```text
Total: 02:15 · 2 entries
```

Run `:SumTimes!` instead to append the total:

```text
1:30
0045
Total: 02:15 · 2 entries
```
