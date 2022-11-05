local Settings = require(script.Parent.Settings);

local ExpectedExpressions = {
	Number = "^[%d+,+]+$"; --Number
	Range = "^%d+%-%d+$"; -- Min-Max Range
	Every = "^%*%/%d+$"; -- */Number Every
	All = "^%*$"; --All
}

local IndexMap = {
	[1] = "sec";
	[2] = "min";
	[3] = "hour";
	[4] = "day";
	[5] = "month";
	[6] = "wday";
}

local function Validate(Index, Expression)
    if Expression == "*" then
		return "All";
	end

    local CurrentExpressionType = nil;

	for ExpressionType, ExpectedExpression in pairs(ExpectedExpressions) do
		if Expression:match(ExpectedExpression) then
			CurrentExpressionType = ExpressionType;
		end
	end

	if CurrentExpressionType ~= nil then
		local Numbers = {};

		local Success = pcall(function()
			for Number in Expression:gmatch("%d+") do
				table.insert(Numbers, tonumber(Number));
			end
		end)

		if Success then
			local MappedIndex = IndexMap[Index];
			local IndexInfo = Settings[MappedIndex];

			for _, Number in pairs(Numbers) do
				if Number < IndexInfo.Min or Number > IndexInfo.Max then
					warn(string.format(Settings.Errors.ArgumentOutsideRange, Index, IndexInfo.Min, IndexInfo.Max, Number));
					return
				end
			end

			return CurrentExpressionType, Numbers;
		end
	else
		warn(string.format(Settings.Errors.InvalidExpression, Expression));
	end
end

local function ConvertRange(Table)
    local Start, End = Table[1], Table[2];
    assert(Start < End, "Range Start shouldn't be greater than End.");
    local T = {};
    for Value = Start, End do
        table.insert(T, Value);
    end
    return T;
end

return function(Expression)
	local TimeTable = {};
	local Count = 1;

	for ExpressionFragment in Expression:gmatch("[^%s]+") do
		local ExpressionType, Numbers = Validate(Count, ExpressionFragment);
		if ExpressionType then
			if ExpressionType == "Range" then
                Numbers = ConvertRange(Numbers);
			end

			TimeTable[IndexMap[Count]] = {
				Type = ExpressionType;
				Numbers = Numbers;
			}
			
			Count += 1;
		end
	end

	return TimeTable;
end