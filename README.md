# VimSum

Sum up a column of numbers or durations.

- [Installation](#installation)
- [Usage](#usage)

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

Enter visual mode (`v` or `V`) and select a column of numbers or durations and run:

- `:SumColumn` to sum numbers
- `:SumTimes` to sum durations
