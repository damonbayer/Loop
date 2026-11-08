# Future meal reminder toggle

Captured from the actual carb entry screen on an iPhone 18 Pro simulator running iOS 27.2, using a 45 g demo meal.

| Past | Present | Future |
| --- | --- | --- |
| ![Past entry with the reminder toggle disabled](01-past.png) | ![Present entry with the reminder toggle disabled](02-present.png) | ![Future entry with the reminder toggle available](03-future.png) |

The status-bar clock provides the current time. The present screenshot shows the default entry time within the same displayed minute.

The toggle starts off for new entries and is enabled only when the entry timestamp is strictly later than the current time. Moving a selected reminder back to the present or past disables the toggle and clears the selection. The reminder is scheduled after the carb entry is saved.

![Future entry with the reminder enabled](04-future-reminder-on.png)

Interactive checks confirmed the toggle becomes available when advancing the entry time and returns to its disabled state when moving it back.

## Time to Eat notification

Loop delivered these reminders for 45 g demo meals saved without a bolus.

| Lock screen | Home screen banner |
| --- | --- |
| ![Time Sensitive Time to Eat reminder on the iOS lock screen](05-time-to-eat-lock-screen.png) | ![Time to Eat reminder banner on the iOS Home Screen](06-time-to-eat-banner.png) |
