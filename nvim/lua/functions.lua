function append_dash()
	vim.fn.feedkeys("$bea <Esc>D")
		local col = vim.fn.col(".")
