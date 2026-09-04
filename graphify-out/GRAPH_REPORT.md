# Graph Report - Janosos_Game  (2026-08-31)

## Corpus Check
- Large corpus: 164 files · ~615,286 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder.

## Summary
- 690 nodes · 735 edges · 130 communities (63 shown, 48 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 36 edges (avg confidence: 0.88)
- Token cost: 7,420 input · 8,420 output

## Community Hubs (Navigation)
- Windows Runner Integration
- Dino Abilities and HUD
- Core Game Components
- Project Configuration and Architecture
- Apple Flutter Integration
- Character Selection Interface
- Linux Runner Integration
- Desktop Build Configuration
- Obstacle Generation Pipeline
- Score Persistence System
- Game Component Contracts
- Windows Utility Functions
- HUD Indicator Components
- Web App Manifest
- Parallax World Components
- Flutter Application Entry
- Start Menu Interface
- Collision Entity Components
- Ability Button Input
- Overlay Widget State
- Obstacle Movement Logic
- Projectile Collision Logic
- Energy Orb Component
- Flutter Widget Tests
- Character Sprite Artwork
- Windows Plugin Registration
- Android Main Activity
- Start Button Artwork
- Shield Ability Artwork
- Game Title Artwork
- Version Four Badge
- Version Five Badge
- iOS App Icon 1024x1024@1x
- iOS App Icon 20x20@1x
- iOS App Icon 20x20@2x
- iOS App Icon 20x20@3x
- iOS App Icon 29x29@1x
- iOS App Icon 29x29@2x
- iOS App Icon 29x29@3x
- iOS App Icon 40x40@1x
- iOS App Icon 40x40@2x
- iOS App Icon 40x40@3x
- iOS App Icon 50x50@1x
- iOS App Icon 50x50@2x
- iOS App Icon 57x57@1x
- iOS App Icon 57x57@2x
- iOS App Icon 60x60@2x
- iOS App Icon 60x60@3x
- iOS App Icon 72x72@1x
- iOS App Icon 72x72@2x
- iOS App Icon 76x76@1x
- iOS App Icon 76x76@2x
- iOS App Icon 83.5x83.5@2x
- macOS App Icon 1024px
- macOS App Icon 128px
- macOS App Icon 16px
- macOS App Icon 256px
- macOS App Icon 32px
- macOS App Icon 512px
- macOS App Icon 64px
- Web Favicon Artwork
- Web App Icon 192px
- Web App Icon 512px
- Maskable Web Icon 192px
- Maskable Web Icon 512px
- Energy Button Artwork
- Electrical Aura Artwork
- Fireball Projectile Artwork
- Clean Cat Run Sprite
- Cat Run Sprite
- Bearded Runner Sprite
- Clean Bearded Runner
- Gray Haired Runner
- Bespectacled Runner Sprite
- Puppy Run Sprite
- Clean Puppy Run Sprite
- Health Heart Indicator
- Game Avatar Portrait
- Intro Background Artwork
- Clean Jano Runner
- Clean Jano Runner Copy
- Jano Runner Copy
- Jano Runner Sprite
- Mexican Sunset Sky
- Futuristic Skyline Background
- Twilight Sky Background
- Mexican Town Background
- Neon City Background
- Modern City Background
- Mexican Desert Ground
- Modern Road Ground
- Retro City Road
- Lightning Ability Icon
- Nakama Runner Sprite
- Nanic Runner Sprite
- Collectible Energy Orb
- Parker Runner Sprite
- iOS Launch Placeholder @2x
- iOS Launch Placeholder @3x
- iOS Launch Placeholder
- iOS Launch Asset Guide
- Android Flutter Icon hdpi
- Android Avatar Icon hdpi
- Android Flutter Icon mdpi
- Android Avatar Icon mdpi
- Android Flutter Icon xhdpi
- Android Avatar Icon xhdpi
- Android Flutter Icon xxhdpi
- Android Avatar Icon xxhdpi
- Android Flutter Icon xxxhdpi
- Android Avatar Icon xxxhdpi

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `MessageHandler` - 12 edges
3. `DinoRunGame` - 10 edges
4. `FlutterWindow` - 10 edges
5. `Create` - 10 edges
6. `WndProc` - 10 edges
7. `MessageHandler` - 9 edges
8. `Character Ability System` - 8 edges
9. `Linux Desktop Build Configuration` - 8 edges
10. `dino_run_flame Package Manifest` - 8 edges

## Surprising Connections (you probably didn't know these)
- `Linux Desktop Build Configuration` --semantically_similar_to--> `Windows Desktop Build Configuration`  [INFERRED] [semantically similar]
  linux/CMakeLists.txt → windows/CMakeLists.txt
- `Flutter Linux Embedding Build` --semantically_similar_to--> `Flutter Windows Embedding Build`  [INFERRED] [semantically similar]
  linux/flutter/CMakeLists.txt → windows/flutter/CMakeLists.txt
- `Linux Runner Target` --semantically_similar_to--> `Windows Runner Target`  [INFERRED] [semantically similar]
  linux/runner/CMakeLists.txt → windows/runner/CMakeLists.txt
- `Flutter Web Release Build` --conceptually_related_to--> `Flutter Base Href Placeholder`  [INFERRED]
  .github/workflows/deploy_web.yml → web/index.html
- `Flutter and Flame Architecture` --conceptually_related_to--> `Flame Engine Dependency`  [INFERRED]
  README.md → pubspec.yaml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Cross-platform Desktop Flutter Build Pipeline** — linux_cmakelists_linux_desktop_build, linux_flutter_cmakelists_flutter_linux_embedding, linux_runner_cmakelists_linux_runner_target, windows_cmakelists_windows_desktop_build, windows_flutter_cmakelists_flutter_windows_embedding, windows_runner_cmakelists_windows_runner_target [INFERRED 0.95]
- **GitHub Pages PWA Delivery** — _github_workflows_deploy_web_deploy_to_github_pages, web_index_flutter_web_shell, web_index_pwa_manifest, pubspec_launcher_icon_generation, readme_progressive_web_app [INFERRED 0.85]
- **Flutter Flame Game Platform** — readme_flutter_flame_architecture, pubspec_flutter_sdk, pubspec_flame_engine, pubspec_asset_bundles, readme_retro_endless_runner [INFERRED 0.85]
- **Shyno Running Sprite Visual Design** — assets_images_shyno_clean_running_character_sprite_sheet, assets_images_shyno_clean_adult_man_with_glasses, assets_images_shyno_clean_four_frame_run_cycle, assets_images_shyno_clean_retro_pixel_art [EXTRACTED 1.00]

## Communities (130 total, 48 thin omitted)

### Community 0 - "Windows Runner Integration"
Cohesion: 0.06
Nodes (55): RECT, unique_ptr, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM (+47 more)

### Community 1 - "Dino Abilities and HUD"
Cohesion: 0.05
Nodes (40): hud/character_selection_overlay.dart, abilityDurationTimer, activateAbility, auraComponent, canDoubleJump, characterName, characterType, cooldownTimer (+32 more)

### Community 2 - "Core Game Components"
Cohesion: 0.05
Nodes (37): components/ground.dart, components/obstacle_manager.dart, components/orb.dart, components/sky.dart, DinoComponent get, hud/ability_button.dart, hud/hud_indicators.dart, hud/score.dart (+29 more)

### Community 3 - "Project Configuration and Architecture"
Cohesion: 0.06
Nodes (37): Deploy to GitHub Pages Workflow, Flutter Web Release Build, peaceiris GitHub Pages Publisher, Main Branch Push Trigger, Dart Static Analysis Configuration, Flutter Recommended Lints, Scoped Lint Customization, Image and Audio Asset Bundles (+29 more)

### Community 4 - "Apple Flutter Integration"
Cohesion: 0.07
Nodes (24): Any, audioplayers_darwin, Cocoa, Flutter, FlutterAppDelegate, FlutterMacOS, FlutterPluginRegistry, FlutterViewController (+16 more)

### Community 5 - "Character Selection Interface"
Cohesion: 0.07
Nodes (29): dart:ui, Image, bgColor, build, _buildCharacterGrid, _buildCharacterImage, _buildDescriptionBox, _buildLandscapeLayout (+21 more)

### Community 6 - "Linux Runner Integration"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 7 - "Desktop Build Configuration"
Cohesion: 0.09
Nodes (27): Linux dino_run_flame Executable, Linux Flutter Assembly Dependency, GTK 3 Dependency, Linux Desktop Build Configuration, Relocatable Linux Bundle Layout, Linux Standard C++14 Settings, Linux Flutter Assemble Backend, Flutter Linux Interface Library (+19 more)

### Community 8 - "Obstacle Generation Pipeline"
Cohesion: 0.14
Nodes (11): Component, dart:math, ObstacleManager, onLoad, _random, reset, _spawnObstacle, _timer (+3 more)

### Community 9 - "Score Persistence System"
Cohesion: 0.14
Nodes (13): double get, currentScore, _highScore, _isLoaded, onLoad, _prefs, reset, saveHighScore (+5 more)

### Community 10 - "Game Component Contracts"
Cohesion: 0.18
Nodes (13): FlameGame, HasCollisionDetection, HasGameRef, KeyboardEvents, GroundComponent, SkyComponent, DinoRunGame, HudIndicators (+5 more)

### Community 11 - "Windows Utility Functions"
Cohesion: 0.26
Nodes (9): _In_, _In_opt_, string, vector, wWinMain(), wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 12 - "HUD Indicator Components"
Cohesion: 0.18
Nodes (10): character_selection_overlay.dart, ../components/dino.dart, heartSprite, lightningSprite, onLoad, render, shieldSprite, timerPaint (+2 more)

### Community 13 - "Web App Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 14 - "Parallax World Components"
Cohesion: 0.24
Nodes (8): ../dino_run_game.dart, onGameResize, onLoad, update, onLoad, update, package:flame/components.dart, package:flame/parallax.dart

### Community 15 - "Flutter Application Entry"
Cohesion: 0.20
Nodes (9): game/dino_run_game.dart, game/hud/character_selection_overlay.dart, game/hud/start_menu_overlay.dart, build, DinoRunApp, main, package:flame/game.dart, package:google_fonts/google_fonts.dart (+1 more)

### Community 16 - "Start Menu Interface"
Cohesion: 0.22
Nodes (8): AnimationController, build, _controller, createState, dispose, game, initState, package:flame_audio/flame_audio.dart

### Community 17 - "Collision Entity Components"
Cohesion: 0.25
Nodes (9): CollisionCallbacks, DinoComponent, DinoState, Obstacle, OrbComponent, Projectile, SpriteAnimationComponent, SpriteAnimationGroupComponent (+1 more)

### Community 18 - "Ability Button Input"
Cohesion: 0.25
Nodes (7): HudButtonComponent, AbilityButton, game, onLoad, onTapDown, package:flame/events.dart, package:flame/input.dart

### Community 19 - "Overlay Widget State"
Cohesion: 0.33
Nodes (7): CharacterSelectionOverlay, _CharacterSelectionOverlayState, StartMenuOverlay, _StartMenuOverlayState, SingleTickerProviderStateMixin, State, StatefulWidget

### Community 20 - "Obstacle Movement Logic"
Cohesion: 0.33
Nodes (5): dino.dart, obstacleName, onLoad, speed, update

### Community 21 - "Projectile Collision Logic"
Cohesion: 0.33
Nodes (5): onCollisionStart, onLoad, speed, update, obstacle.dart

### Community 22 - "Energy Orb Component"
Cohesion: 0.40
Nodes (4): onLoad, speed, update, package:flame/collisions.dart

### Community 23 - "Flutter Widget Tests"
Cohesion: 0.40
Nodes (4): package:dino_run_flame/main.dart, package:flutter/material.dart, package:flutter_test/flutter_test.dart, main

### Community 24 - "Character Sprite Artwork"
Cohesion: 0.50
Nodes (4): Adult Man with Glasses, Four-Frame Run Cycle, Retro Pixel Art, Shyno Running Character Sprite Sheet

### Community 27 - "Start Button Artwork"
Cohesion: 0.67
Nodes (3): Neon Arcade Button, Start Action, Retro Start Button Artwork

### Community 28 - "Shield Ability Artwork"
Cohesion: 0.67
Nodes (3): Cyan Pixel Art, Defensive Shield, Tank Shield Icon Artwork

### Community 29 - "Game Title Artwork"
Cohesion: 0.67
Nodes (3): Colorful Arcade Typography, Janosos Game Title Artwork, Janosos Game Identity

### Community 30 - "Version Four Badge"
Cohesion: 0.67
Nodes (3): Monochrome Pixel Typography, Version 4 Label, Version V4 Badge Artwork

### Community 31 - "Version Five Badge"
Cohesion: 0.67
Nodes (3): Monochrome Pixel Typography, Version 5 Label, Version V5 Badge Artwork

### Community 33 - "iOS App Icon 1024x1024@1x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (1024x1024@1x)

### Community 34 - "iOS App Icon 20x20@1x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (20x20@1x)

### Community 35 - "iOS App Icon 20x20@2x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (20x20@2x)

### Community 36 - "iOS App Icon 20x20@3x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (20x20@3x)

### Community 37 - "iOS App Icon 29x29@1x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (29x29@1x)

### Community 38 - "iOS App Icon 29x29@2x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (29x29@2x)

### Community 39 - "iOS App Icon 29x29@3x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (29x29@3x)

### Community 40 - "iOS App Icon 40x40@1x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (40x40@1x)

### Community 41 - "iOS App Icon 40x40@2x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (40x40@2x)

### Community 42 - "iOS App Icon 40x40@3x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (40x40@3x)

### Community 43 - "iOS App Icon 50x50@1x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (50x50@1x)

### Community 44 - "iOS App Icon 50x50@2x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (50x50@2x)

### Community 45 - "iOS App Icon 57x57@1x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (57x57@1x)

### Community 46 - "iOS App Icon 57x57@2x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (57x57@2x)

### Community 47 - "iOS App Icon 60x60@2x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (60x60@2x)

### Community 48 - "iOS App Icon 60x60@3x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (60x60@3x)

### Community 49 - "iOS App Icon 72x72@1x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (72x72@1x)

### Community 50 - "iOS App Icon 72x72@2x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (72x72@2x)

### Community 51 - "iOS App Icon 76x76@1x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (76x76@1x)

### Community 52 - "iOS App Icon 76x76@2x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (76x76@2x)

### Community 53 - "iOS App Icon 83.5x83.5@2x"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Blue Retro App Branding, iOS App Icon Artwork (83.5x83.5@2x)

### Community 54 - "macOS App Icon 1024px"
Cohesion: 0.67
Nodes (3): Flutter Framework Logo, macOS App Icon Artwork (1024px), macOS Application Icon

### Community 55 - "macOS App Icon 128px"
Cohesion: 0.67
Nodes (3): Flutter Framework Logo, macOS App Icon Artwork (128px), macOS Application Icon

### Community 56 - "macOS App Icon 16px"
Cohesion: 0.67
Nodes (3): Flutter Framework Logo, macOS App Icon Artwork (16px), macOS Application Icon

### Community 57 - "macOS App Icon 256px"
Cohesion: 0.67
Nodes (3): Flutter Framework Logo, macOS App Icon Artwork (256px), macOS Application Icon

### Community 58 - "macOS App Icon 32px"
Cohesion: 0.67
Nodes (3): Flutter Framework Logo, macOS App Icon Artwork (32px), macOS Application Icon

### Community 59 - "macOS App Icon 512px"
Cohesion: 0.67
Nodes (3): Flutter Framework Logo, macOS App Icon Artwork (512px), macOS Application Icon

### Community 60 - "macOS App Icon 64px"
Cohesion: 0.67
Nodes (3): Flutter Framework Logo, macOS App Icon Artwork (64px), macOS Application Icon

### Community 61 - "Web Favicon Artwork"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Web Favicon Artwork, Website Favicon

### Community 62 - "Web App Icon 192px"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Progressive Web App Icon, Web App Icon Artwork (192px)

### Community 63 - "Web App Icon 512px"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Progressive Web App Icon, Web App Icon Artwork (512px)

### Community 64 - "Maskable Web Icon 192px"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Maskable Progressive Web App Icon, Maskable Web App Icon Artwork (192px)

### Community 65 - "Maskable Web Icon 512px"
Cohesion: 0.67
Nodes (3): Bearded Man Pixel Portrait, Maskable Progressive Web App Icon, Maskable Web App Icon Artwork (512px)

## Knowledge Gaps
- **350 isolated node(s):** `gravity`, `jumpForce`, `_yVelocity`, `_isJumping`, `characterType` (+345 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 468 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **48 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FlutterWindow` connect `Windows Runner Integration` to `Apple Flutter Integration`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Why does `DinoRunGame` connect `Game Component Contracts` to `Start Menu Interface`, `Core Game Components`, `Ability Button Input`, `Character Selection Interface`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `MessageHandler` (e.g. with `Destroy` and `GetClientArea`) actually correct?**
  _`MessageHandler` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `gravity`, `jumpForce`, `_yVelocity` to the rest of the system?**
  _350 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Windows Runner Integration` be split into smaller, more focused modules?**
  _Cohesion score 0.05803571428571429 - nodes in this community are weakly interconnected._
- **Should `Dino Abilities and HUD` be split into smaller, more focused modules?**
  _Cohesion score 0.04878048780487805 - nodes in this community are weakly interconnected._
- **Should `Core Game Components` be split into smaller, more focused modules?**
  _Cohesion score 0.05263157894736842 - nodes in this community are weakly interconnected._