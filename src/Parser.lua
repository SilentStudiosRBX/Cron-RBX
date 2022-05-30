local Settings = require(script.Parent.Settings);
local Debug = Settings.DebugTraceback;
local Perf = Settings.PerformanceLogging;

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

local function CheckValidArgument(Index, Expression)
	local T = os.clock();

	if Expression == "*" then
		return "All", {-1};
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

			for _, Number in ipairs(Numbers) do
				if Number < IndexInfo.Min or Number > IndexInfo.Max then
					warn(string.format(Settings.Errors.ArgumentOutsideRange, Index, IndexInfo.Min, IndexInfo.Max, Number), Debug and debug.traceback() or "");
					return;
				end
			end

			if Perf then
				print(string.format("It took %fs to validate arguments", os.clock() - T));
			end

			return CurrentExpressionType, Numbers;
		end
	else
		warn(string.format(Settings.Errors.InvalidExpression, Expression), Debug and debug.traceback() or "");
	end
end

local function ParseExpression(Expression: string)
	local T = os.clock();

	local TimeTable = {};
	local Count = 1;

	for ExpressionFragment in string.gmatch(Expression, "[^%s]+") do
		local ExpressionType, Numbers = CheckValidArgument(Count, ExpressionFragment);
		if ExpressionType and Numbers then
			if ExpressionType == "Range" and Numbers[1] >= Numbers[2] then
				warn(string.format(Settings.Errors.ArgumentComparisonFailed, Numbers[1], Numbers[2]), Debug and debug.traceback() or "");
				return;
			end

			table.insert(TimeTable, Count, {
				Type = ExpressionType;
				Numbers = Numbers;
			});

			Count += 1;
		end
	end

	if Perf then
		print(string.format("It took %2.4fs to parse expressions:", os.clock() - T), TimeTable);
	end

	return TimeTable;
end

return ParseExpression;