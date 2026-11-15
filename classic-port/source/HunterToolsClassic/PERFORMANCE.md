# Temporary performance diagnostics (3.2.7)

## Shared automatic scan coalescing (3.2.6)

The half-second minimum interval now applies centrally to every automatic
EnsureFoodScan request, including main event callbacks, the periodic updater,
status window and tooltips. It is no longer conditional on the first queued event
being UNIT_HAPPINESS. Dirty flags remain set until a fresh scan completes, and
repeated requests never extend the deadline beyond the last scan plus 0.5 seconds.
Pet changes, an absent inventory result and explicit forced feed-click checks
still scan immediately. Deferred refreshes stay disarmed and suppress premature
food-supply warnings; the next normal update completes the work.

Tests reproduce the logged 19 ms event/ticker sequence, verify shared status
deferral and fixed deadlines, and invoke the actual PreClick path to verify
synchronous bag revalidation and rearming after updated counts/slots. Live
performance effects still require a new capture.

## Happiness callback scan coalescing (3.2.5)

Happiness notifications do not directly dirty inventory. Their queued callbacks
can nevertheless inherit bag/quest invalidations and run repeated fresh scans.
When such a callback needs a scan less than half a second after the previous scan,
it now defers until that half-second interval ends. The normal ticker completes
the pending scan; pet status respects the same deadline and shows inventory
settling. No invalidation is discarded, and more notifications do not extend the
deadline. Feed clicks and pet changes bypass it. A deferred feed-button refresh
stays disarmed and suppresses food-supply alerts until the scan completes.

Regression tests reproduce happiness/inventory bursts through both consumers,
deadline completion, forced lock checks, pet swaps and hungry-state recovery.
This reduces repeat scans in a burst; it does not eliminate necessary scans when
inventory or quest protection changes, nor establish a live performance gain
without a fresh capture. Callback event labels name the first queued event, not
necessarily every invalidation that occurred before the callback executed.

## Food scan optimization

Feeding and pet status now use one shared EnsureFoodScan gate. The scan records
the pet and completion time, so opening/updating status does not invalidate an
already fresh feeding scan for that pet. Inventory/rule events and pet changes
still invalidate it immediately; explicit forced refreshes still rescan for feed
click validation. Inventory-entry settling retries run at most once every two
seconds when there is no fresh invalidation. Edibility, protection and allowed-food
checks are reused per item ID within each scan, including duplicate stacks; these
checks are never cached across inventory scans or pet changes.

The shared-food-scan suite exercises both consumers together, settling retries,
duplicate stacks, bag/rule/pet changes, forced lock/count checks and combat
deferral. The improvement in live spike duration/frequency must be measured with
another capture; synthetic tests establish work reuse and behavior, not real FPS.

After `/reload`, run `/ht perf start 60` and play normally during a representative
slow period. It automatically stops and reports after 60 seconds. Use
`/ht perf stop` to stop early, or `/ht perf report` to show the current/last report.
Duration is clamped to 10Ã¢â‚¬â€œ120 seconds. Tests are off after reload/login and must
be explicitly started; there are no diagnostic timers or function wrappers when
off. Callback adapters retain a fast disabled check; measurement wrappers on
individual functions are removed at stop. Only the latest compact report and
latest bounded spike log are saved in character settings.

## Spike capture

Every `/ht perf start 120` run now records calls taking at least **2 ms**. Use
`/ht perf spikes` to print the ten slowest retained entries. The latest **50**
entries are retained in `performanceSpikes`; overwritten counts are reported.
Each entry stores elapsed test time, function/callback name, inclusive and self
milliseconds, internal callback path/event type and combat status. No item,
unit, chat or other event arguments are recorded. Nested parent entries overlap;
self time subtracts measured child calls, not uninstrumented native work.

Main addon events, the half-second update, deferred event refreshes (labeled with
the first triggering event), animal/weapon tooltip callbacks and vendor marker
callbacks are covered, alongside the existing selected functions. Other callbacks
and many individually small calls in a slow frame may still fall outside this
coverage. Timings include instrumentation overhead and are evidence of where
measured time was spent, not proof that the underlying function alone caused a
native profiler frame spike.

The log updates character settings as spikes occur, so `/reload` preserves even
a partial run. `finished=false` marks an interrupted run; automatic stop or
`/ht perf stop` marks it finished and saves the normal summary. No test resumes
after reload. For a full capture: start 120 seconds, reproduce the slowdown, wait
for the completion message, then reload. The saved log can then be inspected
locally without copying chat output.

Reports show addon memory/change/peak, minimum sampled whole-game FPS, native
recent addon CPU/peak where available, and the ten busiest instrumented functions
with call counts, total/mean/maximum elapsed milliseconds. Memory is sampled every
five seconds. GC can move memory down; a rise does not prove a leak. Native peak
CPU is a session peak, not a peak isolated to this test. Function times are
inclusive: nested calls overlap and totals must not be added. Instrumentation
adds overhead and covers selected HunterTools functions; it does not measure
every addon callback or prove that HunterTools caused a whole-game FPS drop.

No profiling CVars are changed and no private chat/location data is collected.
The native profiler API is feature-detected, and unavailable metrics are labeled:

- [Forever AddOnProfiler API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/AddOnProfilerDocumentation.lua)
- [Classic AddOnProfiler API](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic/Interface/AddOns/Blizzard_APIDocumentationGenerated/AddOnProfilerDocumentation.lua)
- [Metric meanings](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/AddOnProfilerConstantsDocumentation.lua)

The weapon catalog also now ignores unrelated item-loading/equipment events and
coalesces relevant comparison refreshes into one next-frame callback. Regression
tests verify the unrelated-event guard. This avoids unnecessary work while the
catalog is open; an in-game report is needed to identify any other bottlenecks.

## Pet status window optimization (3.2.4)

Descriptive window data is reused for up to one second during quiet periods.
Accepted main-addon events, pet changes, inventory invalidation, scan completion,
ability invalidation and window-field changes bypass that cache. Tooltips continue
requesting fresh data. Health/focus bars retain their normal polling cadence and
each edition's existing combat behavior. Unchanged text skips SetText and height
measurement; unchanged bar/detail positions skip repeated anchoring. A combat
pause invalidates the cache and restores the details on exit.

Regression tests count data builds, text/layout writes and resource-bar updates,
then exercise expiry, event, inventory, settings and pet invalidation. These checks
establish work reduction; compare a new in-game capture to measure actual gains.

## Idle vendor marker update removal (3.2.7)

The vendor marker event frame has no OnUpdate handler until a destination is
selected. Selecting a vendor enables its existing 0.2-second marker refresh;
clearing the marker, including after vendor interaction, removes the handler.
No idle per-frame callback is dispatched or profiled. Merchant discovery events
remain available, and the vendor settings panel retains its visible-only refresh.
Tests assert idle absence, active cadence, and callback removal after clear.
