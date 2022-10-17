local RunService = game:GetService("RunService");
local Settings = require(script.Settings);
local Parser = require(script.Parser);

local Jobs = {};

local function GetNextTime(Job, CurrentTime)
	CurrentTime += 1;

	if (Job.Start and os.difftime(CurrentTime, Job.Start.UnixTimestamp) < 0) then
		return
	end

	if (Job.End and os.difftime(Job.End.UnixTimestamp, CurrentTime) < 0) then
		return
	end

	local nextTime;
	--local t = os.clock();

	do
		while not nextTime do
			local Date = os.date("!*t", CurrentTime);

			local Found = true;

			for Index, Pattern in pairs(Job.Pattern) do
				if Found and Pattern and Pattern.Type ~= "All" then
					if Pattern.Type == "Every" then
						Found = Date[Index] % Job.Pattern[Index].Numbers[1] == 0;
					else
						Found = table.find(Job.Pattern[Index].Numbers, Date[Index]);
					end
				end
			end

			if Found then
				nextTime = CurrentTime;
			else
				CurrentTime += 1;
			end
		end
	end

	--print(string.format("It took %2.7f to find the next time", os.clock() - t));

	return nextTime;
end

local Time = DateTime.now().UnixTimestamp;

RunService.Heartbeat:Connect(function(deltaTime)
	Time += deltaTime;

	for _, Job in Jobs do
		local AdjustedUnixTime = Time + Job.Difference;
		if Job.Next and AdjustedUnixTime >= Job.Next then
			Job.Next = GetNextTime(Job, AdjustedUnixTime)
			Job:Callback();
		end
	end
end)

export type CronSettings = {
	Start: DateTime?;
	End: DateTime?;
	UTC: string | number?;
	Time: string?;
	Callback: () -> nil;
}

local function CronJob(CronSettings: CronSettings)
	local TimeZoneOffset = if CronSettings.UTC then CronSettings.UTC else -5;

	if type(TimeZoneOffset) == "string" then
		local Value = TimeZoneOffset:match("U*T*C*[%-%+]*%d+");
		if not Value then
			warn(string.format(Settings.Errors.InvalidTimeOffset, TimeZoneOffset));
		end
		Value = Value:gsub("UTC", "");
		TimeZoneOffset = tonumber(Value);
	end

	local Difference = TimeZoneOffset * 3600;

	local Job = {
		Start = CronSettings.Start;
		End = CronSettings.End;
		Pattern = Parser(CronSettings.Time or "");
		Difference = Difference;
		Callback = CronSettings.Callback;
	};

	Job.Next = GetNextTime(Job, Time + Difference);

	table.insert(Jobs, Job);

	Job.Stop = function(self)
		print(table.remove(Jobs, table.find(Jobs, self)));
	end

	return Job;
end

return {
	new = CronJob;
}
