# Menu and gameplay UI refresh

## Direction

Use restrained clay styling in the welcome screen, settings, shops and chart surround. Warm sand surfaces, pale sage secondary buttons,
deep sea-green primary actions, rounded edges, highlights and short shadows make
the controls look raised. Pressed buttons darken and their shadow gets shallower.
Gameplay keeps compact dark translucent panels so sky/water remain visible.
The fishing reel control and boat steering/throttle are unchanged by the UI refresh.
Subsequent species movement and goal systems are described in progression.md.

## Research informing the design

- Apple game controls: frequent touch controls should be at least 44 × 44 pt;
  successful presses need visible feedback.
  https://developer.apple.com/design/human-interface-guidelines/game-controls
- Apple, Design advanced games for Apple platforms: frequent actions belong near
  thumbs; less frequent controls suit the top of the screen; adapt layouts to safe areas.
  https://developer.apple.com/videos/play/wwdc2024/10085/
- Android accessibility: recommend 48 × 48 dp touch targets, at least 4.5:1 text
  contrast for smaller text and 3:1 for larger text.
  https://developer.android.com/guide/topics/ui/accessibility/apps

The clay treatment is an art-direction choice, not an Apple/Android recommendation.
It retains contrasting labels, outlines and press states rather than relying on
shadows alone. Godot layout units are not automatically equivalent to physical
points/dp: device checks remain necessary, especially with display scaling.

## Changes

- Native clay styles with a sand/sage/sea-green palette and focus outlines.
- Menus use no blur shader, screen copy, external UI image or animated background.
- Settings has a fixed Close row, scrolling options, grouped sections, switch
  indicators and collapsed help/credits.
- A modal backdrop intercepts gameplay touches; tapping it dismisses settings/chart.
- Item cards have clear price/purchase states; selected shop tabs are highlighted.
- The shop preview has no caption/zoom panel. One finger rotates; pinch gestures
  zoom within bounds. Mouse-wheel and trackpad magnification support desktop use.
- HUD header is smaller, balance/catch count are concise, and the irrelevant fishing
  action is hidden away from a fishing spot. Existing engine/helm controls stay put.
- Existing mobile safe-area handling, Low graphics glass shader and quality settings
  are retained. No land gameplay or new 3D assets are introduced.

## Verification

Menu design checks exercise welcome/settings actions, collapsed credits, minimum
logical button heights, palette contrast, distinct pressed states, context-sensitive
HUD and menu containment at 1280 × 720 and 960 × 540. Existing shop, graphics,
helm/menu, harbour, casting and cockpit checks cover integration. Screens are also
rendered and visually reviewed. These checks do not certify accessibility or Nord
N20 SE frame rate; a new phone build should still be tested.

## Fight feedback and catch showcase

A hooked fish produces short double haptic pulses, even when the reel is released.
Runs increase strength/cadence; landing uses gentler pulses through the aboard
animation. Pausing, losing focus, disabling vibration or ending the fight cancels
the pattern. Existing bite/hook/landing confirmations remain. Actual feel and
amplitude support depend on the phone's haptic hardware.

The catch information screen shows the fish without the former decorative leader.
The working reel-to-guides-to-fish line remains part of active fishing.
