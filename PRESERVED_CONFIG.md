# Preserved Configuration for Deliver4Me

This document preserves the color scheme, theme configuration, and styling information from the original Next.js frontend for future Flutter implementation.

## Brand Colors

### Primary Brand Color - Green
```
Brand Green: #13924b
```

**Color Palette:**
- `50`: #f0fdf4
- `100`: #dcfce7
- `200`: #bbf7d0
- `300`: #86efac
- `400`: #4ade80
- `500`: #13924b (DEFAULT)
- `600`: #0f7a40
- `700`: #0d6636
- `800`: #0a522c
- `900`: #084222

### Accent Color
```
Accent: #067a4b
```

### CSS Variables
```css
--brand-green: #13924b
--brand-green-600: #0f7a40
--accent: #067a4b
--text: #111827
--background: #ffffff
--foreground: #111827
```

### Dark Mode Colors
```css
--background: #0a0a0a
--foreground: #ededed
```

## UI Component Styles

### Buttons

**Primary Button:**
- Background: Brand Green 500 (#13924b)
- Hover: Brand Green 600 (#0f7a40)
- Text: White
- Font: Semibold
- Padding: 12px 24px (py-3 px-6)
- Border Radius: 8px (rounded-lg)
- Min Height: 44px
- Active State: Scale 95%

**Secondary Button:**
- Background: White
- Hover: Gray 50
- Text: Brand Green 600 (#0f7a40)
- Border: 2px solid Brand Green 500
- Font: Semibold
- Padding: 12px 24px (py-3 px-6)
- Border Radius: 8px (rounded-lg)
- Min Height: 44px
- Active State: Scale 95%

### Input Fields
- Width: 100%
- Padding: 12px 16px (py-3 px-4)
- Border: 2px solid Gray 300 (#d1d5db)
- Focus Border: Brand Green 500 (#13924b)
- Focus Ring: 2px Brand Green 200
- Border Radius: 8px (rounded-lg)
- Min Height: 44px

### Cards
- Background: White
- Border Radius: 12px (rounded-xl)
- Shadow: Medium (shadow-md)
- Padding: 24px (p-6)
- Hover: Large shadow (shadow-lg)

### Status Chips
- Display: Inline Flex
- Align: Items Center
- Padding: 4px 12px (py-1 px-3)
- Border Radius: 9999px (rounded-full)
- Font Size: 14px (text-sm)
- Font Weight: Medium

### Scrollbar
- Width: 8px
- Track: #f1f1f1
- Thumb: Brand Green (#13924b)
- Thumb Hover: Brand Green 600 (#0f7a40)
- Border Radius: 4px

## Typography
- Font Family: Arial, Helvetica, sans-serif

## Design Guidelines
- Mobile-first responsive design
- Minimum touch target: 44px
- Active state feedback with scale animation (95%)
- Smooth transitions (duration-200)
- Focus states with ring indicators

## Flutter Color Mapping Reference

```dart
// Brand Green Palette
static const Color brandGreen50 = Color(0xFFF0FDF4);
static const Color brandGreen100 = Color(0xFFDCFCE7);
static const Color brandGreen200 = Color(0xFFBBF7D0);
static const Color brandGreen300 = Color(0xFF86EFAC);
static const Color brandGreen400 = Color(0xFF4ADE80);
static const Color brandGreen500 = Color(0xFF13924B); // Primary
static const Color brandGreen600 = Color(0xFF0F7A40);
static const Color brandGreen700 = Color(0xFF0D6636);
static const Color brandGreen800 = Color(0xFF0A522C);
static const Color brandGreen900 = Color(0xFF084222);

// Accent
static const Color accent = Color(0xFF067A4B);

// Text Colors
static const Color textDark = Color(0xFF111827);
static const Color backgroundLight = Color(0xFFFFFFFF);
static const Color foregroundDark = Color(0xFF111827);

// Dark Mode
static const Color backgroundDark = Color(0xFF0A0A0A);
static const Color foregroundLight = Color(0xFFEDEDED);
```

## Dependencies (from package.json)

### Runtime Dependencies
- `@prisma/client`: ^6.19.0
- `bcryptjs`: ^3.0.3
- `jsonwebtoken`: ^9.0.3
- `lucide-react`: ^0.556.0 (icon library)
- `next`: 14.2.0
- `react`: ^18.2.0
- `react-dom`: ^18.2.0
- `zod`: ^4.1.13 (validation)

### Dev Dependencies
- `@types/bcryptjs`: ^2.4.6
- `@types/jsonwebtoken`: ^9.0.10
- `@types/node`: ^20
- `@types/react`: ^18
- `@types/react-dom`: ^18
- `autoprefixer`: ^10.4.19
- `eslint`: ^8
- `eslint-config-next`: 14.2.0
- `postcss`: ^8.4.38
- `prisma`: ^6.19.0
- `tailwindcss`: ^3.4.3
- `typescript`: ^5

## Notes for Flutter Implementation

1. **Color Scheme**: Use the brand green (#13924b) as primary color throughout the app
2. **Accent Color**: Use #067a4b for accent/secondary actions
3. **Minimum Touch Targets**: Ensure all interactive elements are at least 44px in height
4. **Animations**: Implement subtle scale animations (0.95) for active/pressed states
5. **Border Radius**: Use 8px for buttons/inputs, 12px for cards
6. **Shadows**: Implement elevation similar to Material Design shadow levels
7. **Typography**: Consider using a clean sans-serif font similar to Arial/Helvetica
