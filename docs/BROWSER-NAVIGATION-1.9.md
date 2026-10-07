# NauticMixxx 1.9 USB browser

SOURCE has two columns: device slots and INFO. Empty state is NO DEVICE, with
blank counts and capacity units. MY SETTINGS MENU opens native app preferences
for a ready device and is disabled in the empty state. Device dates use the export.pdb modification
date; this is not presented as the date the volume was manufactured.

Slots are logical connection slots, independent of volume labels. Existing
connections retain their slot; a removed connection frees it for reuse. Generic
USB ports on a computer do not provide the RX3's two fixed hardware slot IDs.
When multiple volumes are discovered simultaneously, discovery order breaks the
tie. No volume is renamed or modified.

The sidebar prioritizes ARTIST, ALBUM, TRACK, KEY, PLAYLIST, HISTORY, MATCHING,
FOLDER and REC; additional visible export categories follow in exported order.
USB entry shows the first category immediately. Turning the browser encoder
changes categories and previews content while keeping blue category focus.
Pressing enters the adjacent list. Touching a category enters that list directly
and leaves the category gray. Native keyboard navigation and touch-synthesized
mouse input use the same views. Double-tap a playlist to open its expanded track
list; controller ENTER opens the selected playlist. BACK moves through playlist
folders, content, categories, and SOURCE. Tapping the header title also performs BACK.
Touch scrolling is enabled on the content views.

PLAYLIST has a folder/playlist column and a single adjacent track-title column.
ARTIST previews albums; ALBUM and HISTORY preview tracks. Expanded track rows
retain their previous preview, title, artist, BPM and genre layout. RELATED KEY
is visible but intentionally empty, reserved for a future release.

MATCHING lists DECK 1 / DECK 2 and computes suggestions from the selected USB.
NauticMixxx requires known compatible circle-of-fifths keys and positive BPM
values within six percent of the loaded reference. The reference file is
excluded and candidates are ordered by tempo distance. These rules are explicit
NauticMixxx choices: saved Rekordbox matching pairs are not parsed by this version.
Changing a loaded deck updates the preview. No file is loaded by category
rotation or ENTER in the track list; LOAD 1 / LOAD 2 retain ownership of loading.

FOLDER enumerates the selected USB's directories and supported audio files,
including unexported music. Canonical paths are confined to that volume and
symlink escapes cannot load. Unexported tracks are temporary and permit playback
analysis while refusing persistence, importing and metadata export. They are
not represented as Rekordbox export tracks and do not inherit its analysis.

SEARCH opens the touch keyboard (ABC/123, backspace, CLEAR, SPACE), a compact
waveform/title results view and INFO. Empty queries show no rows. Physical
keyboard input remains supported. Controller rotation selects results; loading
remains deck-specific. BACK closes search and restores category navigation.

One header and twelve rows fill each track table. Integer rounding pixels are
absorbed by the header, so even at different heights the thirteenth row cannot
appear. Scrolling uses complete items. Category button heights divide the whole
browse region and their scrollbar is disabled.

Validation artifacts are under build/test-candidate/1.9.0-browser-qa. Actual
controller hardware, touchscreen hardware, and multi-USB connection order need
manual testing on target systems; mouse and native widget tests are not claimed
as physical hardware tests.
