# Rotation layout comparisons

Native simulator screenshots captured on iPhone 17 Pro, iOS 26.5, with Xcode 27. Both versions use the same simulator and synthetic or empty display values. Screenshots are unedited.

| Repository | Before (`next-dev`) | After |
| --- | --- | --- |
| Loop | da6f7b17 | 6a86e837 |
| LoopKit | f6be0106 | d2216d4d |
| RileyLinkKit | 2c2343d | 21509fc |

Prediction screenshots come from the full Loop application, opened in portrait, rotated to landscape with the notch on the left, then returned to portrait. The empty graph is intentional: no pump or CGM was configured.

Settings and RileyLink screenshots use isolated fixtures with production cell classes and frameworks from the respective builds. A diagnostic label was added to each cell, constrained to its content layout margins. Both fixtures use identical display values and the same portrait → landscape → portrait sequence. The original cells retain an 82-point left margin; the fixed cells restore 20 points.

Setup screenshots use each version's production setup controller and footer source in a temporary app, with class names changed to avoid framework subclass ABI differences. The fixture supplies one fixed-height row and a Continue button. Screenshots show landscape after opening in portrait, without scrolling. Before, the footer retains its portrait height and the button is below the viewport. After, the footer follows the available landscape height and the button stays visible. Returning to portrait also restores the footer size.

These screenshots establish component layout behavior, not clinical behavior or connected-device compatibility. The comparison app and new automated test sources are not included in the implementation PRs. Assets are hosted on a separate evidence branch so the implementation diffs remain focused on source changes.
