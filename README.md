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

Run `:SumColumn` to sum numbers, or `:SumTimes` to sum durations written as `HHMM` (e.g. `0130` for 1 hour 30 minutes).

Every selected line must be valid. Invalid input (including blank lines) reports its line number and leaves the buffer unchanged; `:SumColumn` no longer silently skips invalid lines. Numbers must be finite. Durations must contain only digits; one- or two-digit values represent minutes, and excess minutes carry into hours.

### Example

Given these lines:

```text
0130
0045
```

Select both lines and run `:SumTimes` to append the total below them:

```text
0130
0045
1-2 Total: 0215
```
