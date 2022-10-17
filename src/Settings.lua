return {
	DebugTraceback = false;
	PerformanceLogging = false;

	--[[
		If you're curious as to why I have case mismatch
		is due to the roblox API for dates.
	]]--

	Divisors = {
		Year = 31556926;
		Month = 2629743;
		Day = 86400;
		Hour = 3600;
		Minute = 60;
	};

	month = {
		Min = 1;
		Max = 12;
	};

	wday = {
		Min = 1;
		Max = 7;
	};

	day = {
		Min = 1;
		Max = 31;
	};

	hour = {
		Min = 0;
		Max = 23;
	};

	min = {
		Min = 0;
		Max = 59;
	};

	sec = {
		Min = 0;
		Max = 59;
	};

	Errors = {
		InvalidExpression = "%s is not a Valid Expression for Cron";
		ArgumentOutsideRange = "Argument %s is expected to be between {%d, %d}, Recieved: %d";
		InvalidTimeOffset = "%s is not a Valid Offset for Time, Valid forms are as followed: \"UTC-8\",\"-8\" or \"UTC+8\", \"8\"";
		ArgumentComparisonFailed = "(%d >= %d) Argument 1 shouldn't be greater or equal to Argument 2\nThis typically happens only in range expressions.";
	}
}