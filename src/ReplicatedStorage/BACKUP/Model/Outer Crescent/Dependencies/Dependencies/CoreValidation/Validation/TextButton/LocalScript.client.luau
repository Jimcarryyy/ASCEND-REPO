script.Parent.Text = 'Copy Code'

local CopyButton = script.Parent
local TextBox = script.Parent.Parent.TextBox
local textHighlighted

local function highlightText()
	textHighlighted = true
	TextBox:CaptureFocus()

	task.defer(function()
		TextBox.SelectionStart = 1
		TextBox.CursorPosition = #TextBox.Text + 1
	end)

	-- Change button style to insistently demand Ctrl+C while text is active
	CopyButton.Text = "HIGHLIGHTED, PRESS CTRL + C NOW "
	CopyButton.BackgroundColor3 = Color3.fromRGB(230, 126, 34) -- Warning/Action Orange
end

CopyButton.MouseButton1Click:Connect(highlightText
	
	
)