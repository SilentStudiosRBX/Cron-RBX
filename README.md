Cron (This implementation is intended for Roblox)

This library was made by Silent Studios,
for the purpose of making JavaScript-like automated features.
It wasn't intended for performance-constrained scenarios;
the only real scenarios we designed this for was to define
roll over times for stuff like item shops.

```
local Task = require(Path.to.Cron);

local Job = Task.new({
	UTC = -5; -- Optional, Defaults to 0, Time Zone Offset
	Start = DateTime.fromLocalTime(2022, 1, 1); -- Optional Start Date
	End = DateTime.fromLocalTime(2022, 12, 31); -- Optional End Date
	Time = "0 0 */2"; -- Optional Cron Time, defaults to "*", example runs every 2 hours
	Callback = function()
		print("Here");
	end,
});

print(os.date("!*t", Job.Next));
```

Explanation/Examples of Time Expressions

  can consists of:
  ```
    "*" - Means that this parameter doesn't matter, the script by default uses this for any parameters that haven't been filled.
    "*/number" - This acts as a modulos so say I have a string that purely consists of "*/10" being it's in the first parameter it
      indicates that I want the function to fire every 10 in real time seconds.
    "number-number" - Filling a parameter with a number-number like "1-7" means that you want it to occur between 1 and 7 inclusively.
    "number" -This last type determines if you want something to be specific, so "30" being it's by itself would happen at 30 seconds real time; this does differ from "*/30".
  ```
 
  Examples:
  ```
    "0 0 8" -- Every day at 8am under the pretense of it being UTC-5;
    "0 */30" -- Every 30 minutes.
    "0 30" -- Every hour at xx:30:00.
    "0 0 0" -- Every day at midnight.
  ```
