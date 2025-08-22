# Old Overlay Cleanup

This document tracks overlay files that are **NOT** using the new Theme system and should be considered for cleanup now that the Overlay safe area and theme have been finalized.

## Overview

The new Theme system provides:

- Consistent color schemes (Classic, Midnight, Dawn)
- Typography scaling based on render size
- Standardized effects (corner radius, shadows, spacing)
- SurfaceStyle variants (rounded/square)

## Files to Clean Up

### Components

_Files that don't use `@Environment(\.theme)` or the new Theme structs_

#### Badges

- **LogoBadge.swift** - Uses hardcoded colors, fixed font sizes, no theme scaling
- **SocialBadge.swift** - Uses hardcoded colors (Color+Hex), fixed font sizes, no theme scaling
- **StatusBadge.swift** - Uses hardcoded colors, fixed font sizes, no theme scaling

#### Bars

- **BottomBar.swift** - Uses hardcoded colors, fixed font sizes, no theme scaling
- **BottomBarGlass.swift** - Uses hardcoded colors, fixed font sizes, no theme scaling
- **BottomBarV2.swift** - Uses hardcoded colors, fixed font sizes, no theme scaling

#### Tickers

- **MetricTicker.swift** - Uses hardcoded colors, fixed font sizes, no theme scaling
- **TimeTicker.swift** - Uses hardcoded colors, fixed font sizes, no theme scaling
- **WeatherTicker.swift** - Uses hardcoded colors, fixed font sizes, no theme scaling

### Overlays

_Files that don't use `@Environment(\.theme)` or the new Theme structs_

#### SwiftUI Presets

- (KEEP)**SafeAreaTest.swift** - Uses hardcoded colors, fixed font sizes, no theme scaling
- **CreatorMode.swift** - Uses old components (StatusBadge, MetricTicker, etc.) that don't have theme support
- (KEEP)**AspectRatioTest.swift** - Likely uses hardcoded colors and fixed sizing
- (KEEP)**AspectRatioTestV2.swift** - Likely uses hardcoded colors and fixed sizing
- **CompanyCropped.swift** - Likely uses hardcoded colors and fixed sizing
- **CompanyCroppedV2.swift** - Likely uses hardcoded colors and fixed sizing
- **NeoLowerThird.swift** - Likely uses hardcoded colors and fixed sizing
- **BrandRibbon.swift** - Likely uses hardcoded colors and fixed sizing
- **StandardLowerThird.swift** - Likely uses hardcoded colors and fixed sizing
- **Professional.swift** - Likely uses hardcoded colors and fixed sizing
- **MetricChipBar.swift** - Likely uses hardcoded colors and fixed sizing

## Summary

**Total files to clean up: 24**

- **Components**: 9 files (3 badges, 3 bars, 3 tickers)
- **Overlays**: 15 files (mostly SwiftUI presets)

## Notes

- Files using the old color system (hardcoded colors, Color+Hex)
- Files without proper theme environment variables
- Files that don't scale properly with render size
- Components that don't support SurfaceStyle variants
- Many files appear to be POC/testing components that can be safely removed

## Files Using New Theme System (Keep These)

- CompanyMarkBadgeModern.swift ✅
- CompanyLogoBadgeModern.swift ✅
- CityBadgeModern.swift ✅
- LocalTimeBadgeModern.swift ✅
- BottomBarModern.swift ✅
- BottomBarCompact.swift ✅
- SimpleWeatherTicker.swift ✅
- SafeAreaContainer.swift ✅
- SurfaceBackground.swift ✅
- BrandLowerThird.swift ✅
- WeatherTopBar.swift ✅
- ModernPersonal.swift ✅
- SafeAreaLive.swift ✅
- SafeAreaValidation.swift ✅

---

_Generated on: August 22, 2025_
