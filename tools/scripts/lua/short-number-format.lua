-- @title Short numbers like 1.5K and 2M (module)
-- @category Pickups and money
-- @kind ModuleScript
-- @where Put this ModuleScript in ReplicatedStorage and name it ShortNumbers, then require it from any Script or LocalScript.
-- @keywords abbreviate numbers, 1k 1m format, short numbers, number suffix, format big numbers, commas in numbers
-- @about Turns big numbers into short text like 1.5K, 2.3M or 4B, and can also add commas like 1,234,567.

--[[ How to use it:
	local ShortNumbers = require(game.ReplicatedStorage.ShortNumbers)
	print(ShortNumbers.short(1500))       --> 1.5K
	print(ShortNumbers.short(2340000))    --> 2.34M
	print(ShortNumbers.commas(1234567))   --> 1,234,567
]]

local ShortNumbers = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function ShortNumbers.short(number)
	local negative = number < 0
	number = math.abs(number)
	local index = 1
	-- Divide by 1000 until the number is small, counting how many times
	while number >= 1000 and index < #SUFFIXES do
		number = number / 1000
		index = index + 1
	end
	local text
	if index == 1 then
		text = tostring(math.floor(number))
	else
		-- Keep 2 decimals, then remove extra zeros (1.50 becomes 1.5)
		text = string.format("%.2f", math.floor(number * 100) / 100):gsub("%.?0+$", "")
	end
	return (negative and "-" or "") .. text .. SUFFIXES[index]
end

function ShortNumbers.commas(number)
	local text = tostring(math.floor(number))
	-- Keep adding a comma before the last 3 digits that have none yet
	local result, count
	repeat
		result, count = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		text = result
	until count == 0
	return text
end

return ShortNumbers
