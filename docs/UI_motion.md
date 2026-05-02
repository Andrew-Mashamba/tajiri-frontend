Complete Modern Javascript Dom Events Reference
Complete Modern JavaScript DOM Events Reference
Mouse Events
Event	Description
click	Mouse click on an element
dblclick	Double mouse click
mousedown	Mouse button pressed
mouseup	Mouse button released
mousemove	Mouse moves over element
mouseenter	Mouse enters element
mouseleave	Mouse leaves element
mouseover	Mouse moves onto element or child
mouseout	Mouse leaves element or child
contextmenu	Right click menu triggered
wheel	Mouse wheel scroll
Keyboard Events
Event	Description
keydown	Key pressed down
keyup	Key released
keypress	Deprecated key press event
Form Events
Event	Description
submit	Form submitted
reset	Form reset
input	Input value changes instantly
change	Input value committed
focus	Element receives focus
blur	Element loses focus
focusin	Focus enters element
focusout	Focus leaves element
invalid	Form validation failed
select	Text selected
Clipboard Events
Event	Description
copy	Content copied
cut	Content cut
paste	Content pasted
Drag and Drop Events
Event	Description
drag	Element being dragged
dragstart	Drag operation started
dragend	Drag operation ended
dragenter	Dragged item enters target
dragleave	Dragged item leaves target
dragover	Dragged item over target
drop	Item dropped
Touch Events
Event	Description
touchstart	Finger touches screen
touchmove	Finger moves on screen
touchend	Finger removed
touchcancel	Touch interrupted
Pointer Events
Event	Description
pointerdown	Pointer pressed
pointerup	Pointer released
pointermove	Pointer moved
pointerenter	Pointer enters element
pointerleave	Pointer leaves element
pointerover	Pointer over element
pointerout	Pointer leaves element
pointercancel	Pointer canceled
Window Events
Event	Description
load	Page fully loaded
DOMContentLoaded	HTML fully parsed
beforeunload	Before leaving page
unload	Page unloading
resize	Window resized
scroll	Page scrolled
error	Resource or JS error
online	Internet connection restored
offline	Internet connection lost
hashchange	URL hash changes
popstate	Browser history changes
storage	Local storage updated
Media Events
Event	Description
play	Media starts playing
pause	Media paused
ended	Media playback ended
volumechange	Volume changed
timeupdate	Playback position updated
seeking	Seeking media
seeked	Seeking completed
waiting	Media buffering
canplay	Media ready to play
loadeddata	Media data loaded
loadedmetadata	Media metadata loaded
Animation Events
Event	Description
animationstart	CSS animation started
animationend	CSS animation ended
animationiteration	Animation repeated
Transition Events
Event	Description
transitionstart	CSS transition started
transitionend	CSS transition ended
transitioncancel	Transition canceled
transitionrun	Transition begins running
Selection Events
Event	Description
selectionchange	Text selection changed
Fullscreen Events
Event	Description
fullscreenchange	Fullscreen mode changed
fullscreenerror	Fullscreen request failed
Network & Fetch Related Events
Event	Description
abort	Request aborted
timeout	Request timed out
progress	Loading progress updated
loadstart	Loading started
loadend	Loading finished
Device Events
Event	Description
orientationchange	Device orientation changed
devicemotion	Device motion detected
deviceorientation	Device orientation sensor updated
Visibility Events
Event	Description
visibilitychange	Tab visibility changed
Clipboard API Example
window.addEventListener('paste', (e) => {
console.log('Pasted content')
})
Pointer Event Example
card.addEventListener('pointermove', (e) => {
console.log(e.clientX, e.clientY)
})
Modern Input Example
search.addEventListener('input', (e) => {
console.log(e.target.value)
})
Form Submit Example
form.addEventListener('submit', (e) => {
e.preventDefault()


console.log('Submitted')
})
Scroll Performance Example
window.addEventListener(
'scroll',
() => {
console.log(window.scrollY)
},
{ passive: true }
)
Detect ESC Key
document.addEventListener('keydown', (e) => {
if (e.key === 'Escape') {
console.log('Close modal')
}
})
Event Listener Syntax
element.addEventListener('click', (e) => {
console.log(e.target)
})
Useful Event Object Properties
Property	Description
e.target	Actual element triggered
e.currentTarget	Listener element
e.type	Event type
e.key	Pressed keyboard key
e.clientX	Mouse X coordinate
e.clientY	Mouse Y coordinate
e.preventDefault()	Prevent default behavior
e.stopPropagation()	Stop bubbling
Event Flow
Capture Phase
↓
Target Phase
↓
Bubble Phase
Best Practices
Prefer input over keyup for form typing
Prefer Pointer Events for cross-device support
Use event delegation for dynamic content
Use passive listeners for scroll events
Remove listeners when components unmount
Debounce resize and scroll handlers
Avoid deprecated events like keypress
Most Commonly Used Events in Modern Apps
Event	Common Usage
click	Buttons, menus
input	Search, validation
submit	Forms
keydown	Shortcuts
change	Dropdowns, checkboxes
scroll	Infinite scroll
resize	Responsive layouts
pointermove	Drawing, drag interactions
dragover	File uploads
visibilitychange	Pause timers/videos