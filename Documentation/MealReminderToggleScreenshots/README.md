# Future meal reminder toggle

Captured from the actual carb entry screen on an iPhone 18 Pro simulator running iOS 27.2, using a 45 g demo meal.

| Past | Present | Future |
| --- | --- | --- |
| ![Past entry with no reminder toggle](01-past.png) | ![Present entry with no reminder toggle](02-present.png) | ![Future entry with the reminder toggle off](03-future.png) |

The status-bar clock provides the current time. The present screenshot shows the default entry time within the same displayed minute. The future entry is at 11:24 AM; the past entry is at 10:54 AM.

The toggle starts off for new entries and appears only when the entry timestamp is strictly later than the current time. Moving an enabled reminder back to the present or past hides the toggle and clears the selection. Continuing to the bolus screen does not show a separate reminder prompt. The reminder is scheduled only after the carb entry is saved.

![Future entry with the reminder enabled](04-future-reminder-on.png)

Validation: 134 focused tests passed on iOS 27.2, covering carb entry, bolus flow, reminder scheduling, alert handling, and the four-hour future carb-entry boundary. Interactive checks confirmed the toggle appears when advancing the entry time and disappears when moving it back.
