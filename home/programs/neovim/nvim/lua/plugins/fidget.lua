return {
	"j-hui/fidget.nvim",
	opts = {
		notification = {
			window = {
				normal_hl = "Comment", -- Base highlight group
				winblend = 0, -- Background transparency
				border = "none", -- Border style
				zindex = 45, -- Stack order
				max_width = 0, -- Max width of notification window
				max_height = 0, -- Max height of notification window
				x_padding = 2, -- Horizontal padding
				y_padding = 1, -- Vertical padding
				align = "bottom", -- Align notifications to bottom
			},
			view = {
				stack_upwards = true, -- Display notification items from bottom to top
			},
		},
		-- Options for LSP progress
		progress = {
			display = {
				done_icon = "✓", -- Icon for completed tasks
				progress_icon = { pattern = "dots" }, -- Animated dots
			},
			lsp = {
				progress_ringbuf_size = 0, -- Size of progress ring buffer
			},
		},
	},
}
