--[[
	This library was made by Silent Studios,
	for the purpose of making Javascript like automated features.
	It wasn't intended for performance-constrained scenarios
	and the only real niche scenario this was intended for was defining
	roll over times for stuff like item shops.
]]--

local Settings = require(script.Settings);
local ParseExpression = require(script.Parser);
local HttpService = game:GetService("HttpService");
local Perf = Settings.PerformanceLogging;

local GenID = function()
	return HttpService:GenerateGUID();
end
--[[
	The Expected Format for JobExpression is similar to the JavaScript Cron.
	"seconds month hour day month wday"
]]

local IndexMap = {
	[1] = "sec";
	[2] = "min";
	[3] = "hour";
	[4] = "day";
	[5] = "month";
	[6] = "wday";
}

local Cron = {};
Cron.__index = Cron;
Cron.ClassName = "Cron";
Cron.__tostring = function()
	return Cron.ClassName;
end

function Cron:_TasksEvent()
	local CurrentDate = self.CurrentDate;
	for _, Task in pairs(self._Tasks) do
		task.spawn(function()
			local T = os.clock();
			local CheckTime = true;
			for ListIndex, TimeInfo in ipairs(Task.Time) do
				if CheckTime then
					local MappedIndex = IndexMap[ListIndex];
					local Current = CurrentDate[MappedIndex];
					if TimeInfo.Type == "Range" then
						CheckTime = Current >= TimeInfo.Numbers[1] and Current <= TimeInfo.Numbers[2];
					elseif TimeInfo.Type == "Number" then
						local MatchesAny = false;
						for _, Number in ipairs(TimeInfo.Numbers) do
							if MatchesAny == false and Current == Number then
								MatchesAny = true;
							end
						end
						CheckTime = MatchesAny;
					elseif TimeInfo.Type == "Every" then
						CheckTime = Current % TimeInfo.Numbers[1] == 0;
					end
				end
			end

			if Perf then
				print(string.format("It took %fs to compare the time expressions", os.clock() - T));
			end

			if CheckTime then
				Task.Callback();
			end
		end)
	end
end

function Cron:ScheduleTask(Expression: string, Callback: () -> nil): string
	local Time = ParseExpression(Expression);

	if Time then
		local Id = GenID();

		self._Tasks[Id] = {
			Time = Time;
			Callback = Callback;
		}

		return Id;
	end
end

function Cron:RemoveTask(Id: string)
	if self._Tasks[Id] then
		self._Tasks[Id] = nil;
	end
end

function Cron:GetDate()
	return self.CurrentDate;
end

function Cron:GetTime()
	return self.CurrentTime;
end

function Cron.new(TimeZoneOffset: string | number?)
	local self = setmetatable({}, Cron);
	self.new = nil;

	if type(TimeZoneOffset) == "string" then
		local Value = TimeZoneOffset:match("U*T*C*[%-%+]*%d+");
		if not Value then
			warn(string.format(Settings.Errors.InvalidTimeOffset, TimeZoneOffset));
		end
		Value = Value:gsub("UTC", "");
		TimeZoneOffset = tonumber(Value);
	end

	local Difference = TimeZoneOffset * 60 * 60;
	self._Tasks = {};

	self.CurrentTime = DateTime.now().UnixTimestampMillis + Difference;
	self.CurrentDate = os.date("!*t", math.floor(self.CurrentTime));

	self._Thread = task.spawn(function()
		while true do
			local TimeInMS = DateTime.now().UnixTimestampMillis + Difference;
			local TimeRemaining = (60 - (TimeInMS % 60 + 1)) / 60;
			self.CurrentTime = TimeInMS;
			self.CurrentDate = os.date("!*t", math.floor(TimeInMS));
			self:_TasksEvent();
			task.wait(TimeRemaining);
		end
	end)

	return self;
end

function Cron:Destroy()
	if self._Thread then
		self._Thread:Disconnect();
	end
	self._Thread = nil;
	table.clear(self);
	setmetatable(self, nil);
end

return Cron;