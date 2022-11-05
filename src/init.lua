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

    local Date = os.date("!*t", CurrentTime);
	local NextTime;

	while not NextTime do
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
			NextTime = CurrentTime;
		else
			CurrentTime += 1;
		end
	end

	return NextTime;
end

local Time = DateTime.now().UnixTimestamp;

RunService.Heartbeat:Connect(function(DeltaTime)
	Time += DeltaTime;

	for _, Job in pairs(Jobs) do
        task.spawn(function()
            local AdjustedUnixTime = Time + Job.Difference;
            if Job.Next and AdjustedUnixTime >= Job.Next then
                Job.Next = GetNextTime(Job, AdjustedUnixTime);
                Job.Callback();
            end
        end)
	end
end)

export type CronSettings = {
	Start: DateTime?;
	End: DateTime?;
	UTC: string | number?;
	Time: string?;
	Callback: () -> nil;
}

export type CronJob = {
    Start: DateTime?;
    End: DateTime?;
    Pattern: { any };
    Difference: number;
    Callback: () -> nil;
    Stop: () -> nil;
	TimeUntilNext: (AsString: boolean?) -> number | string;
}

local function NewCronJob(CronSettings: CronSettings): CronJob
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

    function Job:TimeUntilNext(AsString: boolean?)
        if Job.Next then
            local TimeUntilNext = Job.Next - (Time + Difference);
            return if AsString then string.format("%02i:%02i:%02i", TimeUntilNext/60^2, TimeUntilNext/60%60, TimeUntilNext%60) else TimeUntilNext;
        end
    end

	function Job.Stop()
		table.remove(Jobs, table.find(Jobs, Job));
	end

	table.insert(Jobs, Job);

	return Job;
end

return {
	new = NewCronJob;
}
