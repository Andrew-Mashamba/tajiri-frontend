---
name: design-guidelines
description: TAJIRI app design system with Material 3 aesthetics and Swahili UI. Apply when creating or modifying Flutter UI components, screens, buttons, or layouts for the TAJIRI social platform.
triggers:
  - design
  - UI
  - theme
  - Material 3
  - colors
  - styling
  - layout
  - Swahili
  - typography
  - spacing
  - components
  - buttons
  - cards
  - forms
role: specialist
scope: implementation
output-format: code
---

# TAJIRI Design Guidelines

Apply these guidelines when writing or modifying Flutter UI code for the TAJIRI platform.

## Color Palette (Material 3)

| Element | Color | Hex | Usage |
|---------|-------|-----|-------|
| Primary | Blue | `#1E88E5` | Main brand color, primary actions |
| Background | White | `#FFFFFF` | Screen backgrounds |
| Surface | White | `#FFFFFF` | Cards, dialogs |
| Primary Text | Dark | `#000000` (87% opacity) | Main content |
| Secondary Text | Gray | `#000000` (60% opacity) | Supporting text |
| Disabled | Gray | `#000000` (38% opacity) | Disabled elements |

**Material 3 Design**: Use Material 3 components with `useMaterial3: true` throughout.

## Layout Rules

- **Border Radius**: Standard 12px for all rounded corners (cards, buttons, inputs)
- **Input Padding**: 16px horizontal and vertical for text fields
- **Spacing**: Use multiples of 8px (8, 16, 24, 32px) for consistent spacing
- **Text overflow**: Always use `TextOverflow.ellipsis` and set `maxLines` for long content
- **Responsive**: Use `MediaQuery` for screen-size dependent layouts
- **Safe Areas**: Always respect SafeArea for notched devices

## Button Specifications

Use Material 3 button components:

```dart
// Primary action button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF1E88E5),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ),
  onPressed: onPressed,
  child: const Text('Button Label'),
)

// Secondary button
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF1E88E5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  onPressed: onPressed,
  child: const Text('Button Label'),
)
```

- Primary actions: Filled with primary color (#1E88E5)
- Secondary actions: Outlined with primary color
- Touch targets: minimum 48x48dp
- Border radius: 12px standard

## Page Structure Template

```dart
Scaffold(
  backgroundColor: Colors.white,
  appBar: AppBar(
    title: const Text('Page Title'),
    elevation: 0,
  ),
  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page content
        ],
      ),
    ),
  ),
)
```

- Use SafeArea for notched devices
- SingleChildScrollView for scrollable content
- Consistent padding (16px standard)
- AppBar with elevation: 0 for flat design

## Swahili UI Text Guidelines

**ALWAYS use Swahili for user-facing text**:

| English | Swahili | Usage |
|---------|---------|-------|
| Home | Nyumbani | Navigation |
| Feed | Habari | News feed |
| Friends | Marafiki | Social connections |
| Messages | Ujumbe | Chat/messaging |
| Photos | Picha | Photo gallery |
| Music | Muziki | Music player |
| Stories | Hadithi | Stories feature |
| Groups | Makundi | Community groups |
| Pages | Kurasa | Business pages |
| Events | Matukio | Events |
| Polls | Kura | Voting |
| Profile | Wasifu | User profile |
| Settings | Mipangilio | App settings |
| Like | Penda | Like action |
| Comment | Toa maoni | Comment action |
| Share | Shiriki | Share action |
| Post | Chapisha | Post/publish |

**Never use English UI text** - the platform is fully Swahili for the Tanzanian market.

## Performance & Accessibility

- **Animations**: Smooth transitions (300-400ms), use `CurvedAnimation`
- **Contrast**: Minimum 4.5:1 ratio for text
- **Touch targets**: Minimum 48x48dp for all interactive elements
- **Memory**: Always dispose controllers, use `const` constructors
- **Overflow prevention**: Test on small screens, handle long Swahili text
- **Loading states**: Show skeletons, not spinners
- **Error states**: Graceful error handling with retry options

## Material 3 Components

- **Cards**: Elevation 1-2, 12px border radius
- **Buttons**: 12px border radius, 48dp minimum height
- **Inputs**: 12px border radius, 16px padding
- **Bottom sheets**: Rounded top corners (16px)
- **Dialogs**: 12px border radius, center aligned

## Key Principles

1. **Material 3 First**: Use Material 3 components throughout
2. **Swahili UI**: All user-facing text in Swahili
3. **Offline-first**: Design for intermittent connectivity
4. **Performance**: 60fps target, optimize for low-end devices
5. **Consistency**: 12px border radius, 8px spacing multiples
6. **Accessibility**: High contrast, large touch targets
7. **Tanzanian Context**: Mobile money, local terminology
