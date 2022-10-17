local RunService = game:GetService("RunService");
local Settings = require(script.Settings);
local Parser = require(script.Parser);

local Jobs = {};

local Time = tick();

RunService.Heartbeat:Connect(function(deltaTime)
    Time += deltaTime;

    for _, Job in Jobs do
        local AdjustedUnixTime = Time + Job.Difference;
        local Date = DateTime.fromUnixTimestamp(AdjustedUnixTime);
        if (Job.Start and os.difftime(Date.UnixTimestamp, Job.Start.UnixTimestamp) < 0) then
            continue
        end

        if (Job.End and os.difftime(Job.End.UnixTimestamp, Date.UnixTimestamp) < 0) then
            continue
        end

    end
end)

export type CronSettings = {
    Start: DateTime?;
    End: DateTime?;
    UTC: string | number?;
    Time: string?;
}

local function CronJob(CronSettings: CronSettings)
    local Job = {};
    Job.Start = CronSettings.Start;
    Job.End = CronSettings.End;

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
    Job.Difference = Difference;
    Job.Pattern = Parser(CronSettings.Time or "");

    table.insert(Jobs, Job);

    function Job:GetNextTime()
        local CurrentTime = Time + Difference;
        if (Job.Start and os.difftime(CurrentTime, Job.Start.UnixTimestamp) < 0) then
            return
        end

        if (Job.End and os.difftime(Job.End.UnixTimestamp, CurrentTime) < 0) then
            return
        end

        local Year = math.floor(CurrentTime / Settings.Divisors.Year);
        local Month = math.floor((CurrentTime % Settings.Divisors.Year) / Settings.Divisors.Month);
        local Day = math.floor(((CurrentTime % Settings.Divisors.Year) % Settings.Divisors.Month) / Settings.Divisors.Day);
        local Hour = math.floor((((CurrentTime % Settings.Divisors.Year) % Settings.Divisors.Month) % Settings.Divisors.Day) / Settings.Divisors.Hour);
        local Minute = math.floor(((((CurrentTime % Settings.Divisors.Year) % Settings.Divisors.Month) % Settings.Divisors.Day) % Settings.Divisors.Hour) / Settings.Divisors.Minute);
    end

    return Job;
end

return {
    new = CronJob;
}