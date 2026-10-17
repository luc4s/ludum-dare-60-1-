# Ludum Dare 60

A 3D Godot game jam project. Keep features small and self-contained so teammates can work on separate scenes and combine them quickly.

## Getting started

1. Clone the repository and open `project.godot` through Godot's project manager.
2. Use **Godot 4.7.2** for this project; see the [official Godot download page](https://godotengine.org/download/). Everyone on the team should use this version. The project uses the **Compatibility** renderer and **Jolt Physics**. Coordinate future editor upgrades and project settings changes with the team.
3. Let Godot finish importing assets before editing scenes.
4. Press **F5** to run the full game flow. Open an individual scene and press **F6** to run it directly.

## Current game flow

`opening.tscn` (Godot logo, then `assets/intro_logo.png`) -> `main_menu.tscn` -> **Play** -> `game.tscn` (empty 3D level).

The logos advance automatically and then open the menu; Enter/Space advances to the next logo and Escape skips the intro. The main menu includes **Play**, **Options** (Audio, Video, Controls), **Credits**, and **Exit**. In-game, Escape opens **Resume**, **Restart**, **Options**, **Main Menu**, and **Exit Game**. The 3D view is intentionally empty for now.

| File | What to edit |
| --- | --- |
| `scenes/main/opening.tscn` | Opening logos and fade timings; Godot appears first, then `assets/intro_logo.png`. |
| `scenes/ui/menus/main_menu.tscn` | Title and main menu layout. |
| `scenes/ui/menus/options_menu.tscn` | Options tabs; `controls_menu.tscn` includes menu/pause bindings and automatically lists new gameplay actions from Input Map. |
| `ATTRIBUTION.md` | Team credits and attribution, loaded automatically whenever the Credits window opens. |
| `scenes/ui/menus/credits.tscn` | Credits formatting and a saved text fallback for exports. |
| `scenes/main/game.tscn` | 3D game shell with camera, lighting, environment, and pause controller. |
| `scenes/levels/base_level.tscn` | Empty `Node3D` where the team can start building the level. |
| `resources/themes/menu_theme.tres` | Shared menu styling, copied from Maaack's Lab theme. |
| `resources/audio/default_bus_layout.tres` | Master, Music, and SFX buses used by the audio options. |
| `scenes/audio/project_music_controller.tscn` | Global music transitions, using Maaack's Music Controller. |
| `scenes/audio/background_music_player.tscn` | Reusable music player to instance in a scene and assign a track. |

The project uses Maaack's base scenes and scripts in `addons/`, with game-specific scenes in `scenes/`. The pause scene/script and UI theme are editable copies of template examples. Customize these project files first. Runtime setup is already configured in `project.godot`: `StartUp` applies saved settings, `SceneLoader` handles transitions, and `ProjectMusicController` manages music. Running the plugin's setup wizard is not required and can overwrite the configured scene paths.

To replace the starting level, edit the `BaseLevel` instance in `game.tscn`. To change the menu or game entry paths, edit the **Maaacks Game Template** section of Project Settings. Keep the application main scene set to `opening.tscn` to retain the logo sequence.

Edit the root `ATTRIBUTION.md` to update credits. Headings and links use Maaack's Markdown formatting. Include `ATTRIBUTION.md` in each export preset's **Resources > Filters to export non-resource files/folders** to load the latest text in builds. If you omit Markdown from an export, open and save `scenes/ui/menus/credits.tscn` after editing attribution to refresh its saved fallback.

## Music in scenes

The opening plays `assets/audio/music/MUS_Intro.ogg` once during the logos. The main menu plays `MUS_Menu.ogg` on a loop, continuing through Options and Credits. **Play** fades the menu music to silence in the empty game. Returning to the menu starts its track again. Transitions use a 0.5-second fade in and fade out, configured in `scenes/audio/project_music_controller.tscn`.

To add music to a scene:

1. Put the track in `assets/audio/music/`. For an Ogg track that should repeat, select it in Godot's FileSystem dock, enable **Loop** in the Import dock, and click **Reimport**. Commit the `.ogg` and its `.ogg.import` settings together. The intro is not looped; the menu is.
2. Instance `scenes/audio/background_music_player.tscn` as a child of the scene and set its **Stream** to the track. Keep **Autoplay** enabled and **Bus** set to **Music** so the addon detects it. The main menu already has this player; edit its Stream instead of adding another.
3. Use one music player per active scene branch. Add music to the game shell or its level, rather than both, to make ownership clear. If levels will choose their own tracks, remove the empty player from `game.tscn` first.

| Scene setup | Result on entry |
| --- | --- |
| Player with a different Stream | Crossfade to the new track. |
| Player with the same shared Stream resource | Continue the track at its existing playback position. |
| No music player | Keep the previous music, including across loading screens and UI popups. |
| Player with an empty Stream | Fade to silence. `game.tscn` uses this until gameplay music is chosen. |

The controller preserves playback when the previous scene is removed. Music players and the controller process while paused, so adding a gameplay track will keep it playing under the pause menu. Use **Options > Audio > Music** for player volume; the addon's internal `_BlendMusic` bus feeds into **Music** and should not be edited for volume preferences. Route sound effects to **SFX**, using separate players.

Scene players handle normal transitions without code. For a track change triggered within a scene, use the same autoload:

```gdscript
const MENU_MUSIC = preload("res://assets/audio/music/MUS_Menu.ogg")

func play_menu_music() -> void:
    ProjectMusicController.play_stream(MENU_MUSIC)

func fade_to_silence() -> void:
    ProjectMusicController.play_stream(null)
```

Use `ProjectMusicController.stop()` only for an immediate stop. Keep the autoload registered once, pointing to our scene under `scenes/audio/`. Its small script extension prevents the addon from trying to preserve a player during application shutdown. The music editor plugin is not needed at runtime; enabling its setup can replace that autoload with the vendor default and lose the configured fades. Customize the project scenes without editing files in `addons/`.

## Folder map

```text
project.godot              Project settings and entry scene
assets/
    audio/
        music/             Music tracks
        sfx/               Sound effects
    fonts/                 Font files
    materials/             Shared 3D materials
    models/                Imported 3D models, such as .glb files
    shaders/               Shared .gdshader files
    textures/              Textures, UI images, and icons
scenes/
    audio/                 Music controller configuration and reusable player
    main/                  Opening logo and 3D game shell
    levels/                Level scenes; use a subfolder per level
    player/                Player scenes and their scripts
    enemies/               Enemy scenes; use a subfolder per enemy type
    props/                 Pickups, doors, hazards, and other world objects
    ui/                    Menus, HUD, and reusable UI scenes
scripts/
    autoloads/             Truly global services, such as audio or game state
    components/            Reusable behavior scripts, such as health
    utilities/             Small helpers used by multiple features
resources/                 Shared gameplay data saved as .tres resources
addons/                    Third-party Godot plugins and their licenses
docs/                      Design notes, controls, task notes, and asset credits
builds/                    Local exported builds; contents are ignored by Git
tests/                     Automated checks for the menu and game flow
```

`res://` means the folder containing `project.godot`. For example, `res://scenes/player/player.tscn` is a scene inside this repository.

Empty folders contain `.gitkeep` files so they survive cloning. Remove a placeholder when its folder gets real content. `docs/` and `builds/` contain `.gdignore` files to exclude them from Godot's import/export pipeline; keep those files. See Godot's [folder organization guidance](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html).

## Where new work goes

**Keep each feature together.** A scene's controller script and feature-specific resources belong beside that scene. For example:

```text
scenes/player/
    player.tscn
    player.gd
scenes/enemies/slime/
    slime.tscn
    slime.gd
    slime_stats.tres
scenes/levels/level_01/
    level_01.tscn
    level_01.gd
```

These filenames are examples to create when needed. Move code into `scripts/` only when it serves multiple features. Put shared data such as difficulty settings or wave definitions in `resources/`; reusable visual materials go in `assets/materials/`.

**Build levels from reusable scenes.** Instance player, enemy, and prop scenes into a level instead of copying their nodes. Keep `game.tscn` focused on assembling the game and changing scenes. Put UI in its own scenes so UI and level work can happen independently.

**Use autoloads sparingly.** Placing a script in `scripts/autoloads/` does not activate it. Register it in Project Settings > Globals > Autoload only when it needs to exist across scenes, and coordinate the `project.godot` change with the team.

**Add assets with their context.** Put runtime-ready models, textures, and audio under `assets/`, grouped into subfolders when useful. Wrap an imported model in a gameplay `.tscn` scene under `scenes/` to add collisions, scripts, and interactions. Record third-party assets' author, source URL, and license in `docs/asset_credits.md` and the root `ATTRIBUTION.md` when introducing them.

## Team conventions

- Use `snake_case` for folders, assets, scenes, and GDScript filenames: `pause_menu.tscn`, `player_controller.gd`. Use `PascalCase` for node names: `Player`, `HealthBar`.
- Use Godot's FileSystem dock to move or rename existing resources, then check affected scenes and path references.
- Prefer separate scenes for separate tasks. Agree who is integrating `game.tscn`, a shared level, or `project.godot` before editing the same file concurrently.
- Prefer text scenes (`.tscn`) and resources (`.tres`) so changes can be reviewed in Git.
- Save reusable materials deliberately: editing a shared resource can affect every scene that uses it. Make a separate resource for a variation.
- Add a short note in `docs/` when changing controls, the core loop, or team decisions that someone else needs to know.

## Git workflow

`main` is the shared integration branch and tracks `origin/main`. Start a small feature branch from an up-to-date `main` when your working tree is clean:

```sh
git switch main
git pull --ff-only
git switch -c feature/player-movement
```

Commit focused changes, push the feature branch, and merge through a pull request. Before handing work over, run the affected scene and the whole game, then check for missing assets and debugger errors. Export a build before the submission deadline so platform-specific problems surface early.

Keep source assets and Godot's adjacent `*.import` metadata in Git; exclude the generated `.godot/` cache. Godot documents this distinction in its [import process](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/import_process.html). Also commit generated `*.uid` files alongside their scripts and shaders so references stay consistent between teammates; see [Godot's UID guidance](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/).

Export into a platform subfolder such as `builds/windows/` or `builds/web/`. The local `builds/.gitignore` keeps build output out of commits while retaining the folder's two configuration files. Share the exported game through the jam submission or release channel.

## Checking the menu flow

From the project root, replacing `godot` with your Godot 4.7.2 executable if needed:

```sh
godot --headless --path . --editor --import
godot --path . --max-fps 60 --script tests/menu_flow_smoke.gd
```

The smoke test checks the logo transition, music playback and routing, menu tabs, Credits, Play, pause/resume, restart, and returning to the menu. It needs a graphical display because the template uses keyboard-layout labels and drawn popup transitions. Add `-- --capture` to save screenshots to `builds/`. The test sets the game window to 1280 x 720.
