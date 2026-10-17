# Ludum Dare 60

A 3D Godot game jam project. Keep features small and self-contained so teammates can work on separate scenes and combine them quickly.

## Getting started

1. Clone the repository and open `project.godot` through Godot's project manager.
2. Use **Godot 4.7.2** for this project; see the [official Godot download page](https://godotengine.org/download/). Everyone on the team should use this version. The project uses the **Compatibility** renderer and **Jolt Physics**. Coordinate future editor upgrades and project settings changes with the team.
3. Let Godot finish importing assets before editing scenes.
4. Open the scene you are working on and press **F6** to run it. Once a main scene exists, **F5** runs the whole game.

This scaffold contains folders, not a playable game. No main scene is configured yet. To make the first playable version, create `scenes/main/main.tscn`, add a level with a camera and lighting, and select that scene when Godot asks for the main scene on F5. Commit the resulting `project.godot` change along with the scenes.

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
    main/                  Game entry scene and flow between levels/menus
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

**Build levels from reusable scenes.** Instance player, enemy, and prop scenes into a level instead of copying their nodes. Keep `main.tscn` focused on assembling the game and changing scenes. Put UI in its own scenes so UI and level work can happen independently.

**Use autoloads sparingly.** Placing a script in `scripts/autoloads/` does not activate it. Register it in Project Settings > Globals > Autoload only when it needs to exist across scenes, and coordinate the `project.godot` change with the team.

**Add assets with their context.** Put runtime-ready models, textures, and audio under `assets/`, grouped into subfolders when useful. Wrap an imported model in a gameplay `.tscn` scene under `scenes/` to add collisions, scripts, and interactions. Record third-party assets' author, source URL, and license in `docs/asset_credits.md` when introducing them.

## Team conventions

- Use `snake_case` for folders, assets, scenes, and GDScript filenames: `pause_menu.tscn`, `player_controller.gd`. Use `PascalCase` for node names: `Player`, `HealthBar`.
- Use Godot's FileSystem dock to move or rename existing resources, then check affected scenes and path references.
- Prefer separate scenes for separate tasks. Agree who is integrating `main.tscn`, a shared level, or `project.godot` before editing the same file concurrently.
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

Commit focused changes, push the feature branch, and merge through a pull request. Before handing work over, run the affected scene and the whole game once the entry scene exists, then check for missing assets and debugger errors. Export a build before the submission deadline so platform-specific problems surface early.

Keep source assets and Godot's adjacent `*.import` metadata in Git; exclude the generated `.godot/` cache. Godot documents this distinction in its [import process](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/import_process.html). Also commit generated `*.uid` files alongside their scripts and shaders so references stay consistent between teammates; see [Godot's UID guidance](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/).

Export into a platform subfolder such as `builds/windows/` or `builds/web/`. The local `builds/.gitignore` keeps build output out of commits while retaining the folder's two configuration files. Share the exported game through the jam submission or release channel.
