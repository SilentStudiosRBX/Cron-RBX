--!strict
--!optimize 2

--[[
	This library was made by Silent Studios -> (RemnantsOfSiren, Byran, Siren),
	for the purpose of making Javascript like automated features.
	It wasn't intended for performance-constrained scenarios
	and the only real niche scenario this was intended for was defining
	roll over times for stuff like item shops.
]]--

local RunService = game:GetService("RunService");

local Settings = require(script.Settings);
local Parser = require(script.Parser);

export type CronSettings = {
	Start: DateTime?;
	End: DateTime?;
	UTC: string | number?;
	Time: string?;
	Callback: () -> nil;
}

export type CronJob = {
	StartTime: DateTime?;
	EndTime: DateTime?;
	Start: () -> ();
	Pattern: { any };
	Difference: number;
	Callback: () -> ();
	Stop: () -> ();
	TimeUntilNext: (AsString: boolean?) -> number | string?;
	Next: number?;
}

local Jobs = {};

local function GetNextTime(Job: CronJob, CurrentTime: number)
	CurrentTime += 1;

	if (Job.StartTime and os.difftime(CurrentTime, Job.StartTime.UnixTimestamp) < 0) then
		return
	end

	if (Job.EndTime and os.difftime(Job.EndTime.UnixTimestamp, CurrentTime) < 0) then
		return
	end

    local Date = os.date("!*t", CurrentTime);
	local NextTime = nil;

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
			Date = os.date("!*t", CurrentTime);
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

local function NewCronJob(CronSettings: CronSettings): CronJob
	local TimeZoneOffset: string | number? = if CronSettings.UTC then CronSettings.UTC else 0;

	if type(TimeZoneOffset) == "string" then
		local Value = TimeZoneOffset:match("U*T*C*[%-%+]*%d+");
		
		if not Value then
			warn(string.format(Settings.Errors.InvalidTimeOffset, TimeZoneOffset));
		else
			Value = Value:gsub("UTC", "");
			TimeZoneOffset = tonumber(Value);
		end
	end

	local Difference: number = if TimeZoneOffset and typeof(TimeZoneOffset) == "number" then TimeZoneOffset * 3600 else 0;

	local Job = {
		StartTime = CronSettings.Start or nil;
		EndTime = CronSettings.End or nil;
		Pattern = Parser(CronSettings.Time or "");
		Difference = Difference;
		Callback = CronSettings.Callback;
	} :: CronJob;

	Job.Next = GetNextTime(Job, Time + Difference);

    function Job:TimeUntilNext(AsString: boolean?): number | string?
        if Job.Next then
            local TimeUntilNext = os.difftime(Job.Next, (Time + Difference));
            return if AsString then string.format("%02i:%02i:%02i", TimeUntilNext/60^2, TimeUntilNext/60%60, TimeUntilNext%60) else TimeUntilNext;
		end
		return
    end

	function Job.Stop()
		for Index = #Jobs, 1, -1 do
			local Temp = Jobs[Index];
			if Temp == Job then
				table.remove(Jobs, Index);
				return
			end
		end
	end

	function Job.Start()
		table.insert(Jobs, Job);
	end

	Job.Start();

	return Job;
end

return {
	new = NewCronJob;
}

--[[
	MIT License

	Copyright (c) 2022 SilentStudiosRBX

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]