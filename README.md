# LabelMatch

LabelMatch is an iOS app that checks a food label against your own nutrition goal. You choose a photo of a Nutrition Information Panel, the app reads it on your phone, and it tells you if the product is Suitable, Suitable with caution or Not suitable. Every reason is shown next to your own limit.

Made for UTS 40872, Assessment Task 3, Project 2 (platform-integrated solution).

## Domain context

Shoppers who follow a nutrition goal, for example 30 g of protein per meal, have to judge a pack in a few seconds in the aisle. The Health Star Rating is voluntary and the same for everyone. Barcode apps only work for products that are in their database. LabelMatch reads the label itself and judges it against the shopper's own numbers. The full problem statement, market research and reflective report are in the Required Document PDF submitted on Canvas.

## What the app does

Six screens:

1. Goals: pick a goal type (build muscle, lose weight, heart health or custom), edit the targets and allergens, and save it as the active goal.
2. Check a label: choose a label photo, or open one that was shared to the app.
3. Review the numbers: check and correct what was read. Nothing is judged until you confirm.
4. Verdict: the result and each reason, for example "Sugars 12 g per 100 g, your limit is 10 g."
5. Compare: pick two checks made against the same goal and compare them per 100 g.
6. History: past checks, with a filter for things to avoid this week.

## Architecture

MVVM with a use case layer. Views talk to view models, view models talk to use cases, use cases talk to repository protocols, and only the repositories touch Core Data. Views and view models never call Core Data.

- `LabelMatch/Domain`: NutritionGoal, LabelCheck, VerdictReason, NutritionPanelValues, typed errors and the repository protocols
- `LabelMatch/UseCases`: SetNutritionGoalUseCase, ReadNutritionPanelUseCase, AssessLabelForGoalUseCase, CompareLabelChecksUseCase
- `LabelMatch/Repositories`: Core Data repositories and the App Group inbox
- `LabelMatch/Services`: Core Data stack, App Group paths, Vision text reader, widget reloader, app environment
- `LabelMatch/ViewModels` and `LabelMatch/Views`: the screens
- `LabelMatchWidget`: the widget extension
- `LabelMatchShare`: the Share Extension
- `LabelMatchTests`: unit tests

The judging is plain rules in code, not AI. Vision only finds the text on the label. The same label always gives the same verdict, and each reason can be tested. Business rules:

- A goal needs at least one target or limit, and every number must be in a believable range.
- A declared allergen the shopper avoids is always Not suitable.
- A value over a limit is Not suitable. A value equal to the limit, or within 10% below it, is Suitable with caution.
- A protein target is checked per serve. Missing values are reported as errors and never guessed.
- Two checks can only be compared if they used the same goal.

Every use case has a typed error enum with messages written for the shopper.

## Extensions and why

Widget Extension (WidgetKit). Scenario: the shopper is walking the aisle with a basket and wants their targets and this week's tally without unlocking the phone. It supports the small and medium Home Screen families and the Lock Screen rectangular family. It reads the Core Data store in the App Group container, read-only. The app reloads the widgets after every saved check and every goal change, and the widget shows a helpful message when there is nothing to show.

Share Extension. Scenario: the shopper is shopping online or has a label photo saved, and shares it to LabelMatch. The extension copies the photo into the Inbox folder in the App Group container and closes. It does no text recognition and never opens Core Data, because extensions have tight memory limits. The main app reads the Inbox when it opens.

Considered and not built: a Notification Content Extension and an Action Extension. See section 2.4 of the Required Document for the reasons.

## Database choice: Core Data

Core Data was chosen because the data is private health information, used by one person on one phone, often with poor reception, and the widget needs fast local reads. CloudKit's strengths (sharing and sync) are not needed for this stakeholder. The trade-off is that there is no sync between devices.

Three entities: NutritionGoal has many LabelCheck, and LabelCheck has many VerdictReason. Deleting a goal deletes its history. Each LabelCheck stores a snapshot of the numbers and the verdict at the time of the check, so history stays true if the goal changes later. The model is defined in code (`PersistenceController`) so the app and widget share one definition.

Queries with predicates:

- Things to avoid: `checkedAt >= startOfWeek AND verdict == "notSuitable" AND goal.isActive == YES`
- The active goal: `isActive == YES`
- This week's checks, counted by verdict for the widget

All access goes through repository protocols, and unit tests use mock repositories.

## App Group

Identifier: `group.com.diganta.labelmatch`

It holds the Core Data store file (`LabelMatch.sqlite`) and the `Inbox` folder that the Share Extension writes to. If the App Group is missing, the app falls back to its own Documents folder so it does not crash, but then the widget cannot see the data.

## Setup

1. Open `LabelMatch.xcodeproj` in Xcode 26.
2. For each of the three targets (LabelMatch, LabelMatchWidgetExtension, LabelMatchShare), open Signing and Capabilities and choose your Team.
3. Check that the App Groups capability is on for all three targets with `group.com.diganta.labelmatch` ticked. If you use a different identifier, change it in `Services/AppGroup.swift` and in `LabelMatchShare/ShareViewController.swift`.
4. Choose the LabelMatch scheme and an iPhone simulator, then press Run.
5. In Goals, save a goal. In Check, choose a photo of a Nutrition Information Panel.
6. To try the widget, add LabelMatch from the widget gallery on the Home Screen.
7. To try the Share Extension, open a label photo in Photos, tap Share and choose LabelMatch, then open the app and look under Shared to LabelMatch on the Check tab.

## Tests

Press Command U. There are 30 unit tests for the four use cases. They use mock repositories, so no test touches Core Data, Vision or WidgetKit. Test names describe the scenario in domain terms, for example `test_assessLabel_isNotSuitable_whenPeanutsAreDeclared`.

## Git

Feature branches for each part of the app, merged into `main` when working. Commit messages follow Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `chore:`).

## Known limitations

- Text recognition can misread a number, so the Review screen lets the shopper correct values before anything is judged.
- The reader expects the Australian Nutrition Information Panel layout, with the per serve column before the per 100 g column.
- Live camera scanning is not included. Photos are chosen from the library or shared in.
- There is no sync between devices.
- The default goal numbers are editable starting points, not medical advice.

## Attributions and AI declaration

No third-party libraries are used. The app uses Apple frameworks and follows Apple's documentation: Core Data, WidgetKit, Vision (recognizing text in images), PhotosUI and App Groups (developer.apple.com/documentation).

AI assistance: I used Claude (Anthropic) for planning, market research, drafting the Required Document, and for generating the first versions of the Swift source files. I pasted that code into the project, built it, ran it in the iOS Simulator, ran the unit tests, and fixed errors as they appeared.
EOF
