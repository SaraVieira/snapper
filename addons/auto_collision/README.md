# Auto Collision

A plugin for Godot Editor for automatically creating collision polygons for all tiles in tile sets.

## How to install

1. Move the folder "auto_collision" into the folder "addons/" in your project.
   If the "addons" folder doesn't exist yet, create it first.
2. Activate the plugin under Project -> Project Settings... -> Plugins by checking "Enable".

## How to use

1. Select a TileSet file in the file browser in the Godot Editor.<br>
   If you don't have a tile set file yet: After you have created a TileMapLayer and have created a new TileSet for it, it's required to save the tile set as a file. This can be one by clicking the "arrow down" button at the property "Tile Set" of the TileMapLayer (in the Inspector panel) and then selecting "Save as...". The file that is saved is the TileSet file that is required to be selected.
2. Run Project -> Tools -> Generate Tile Collisions, or open the command palette (Editor -> Command Palette... or Ctrl+Shift+P) and run "Generate Tile Collisions".
3. Choose the generation options and click "Generate"

You can check out the generated collision polygons by opening the tile set, activating "Paint" and selecting the first physics layer under "Paint Properties".

## Feedback

You can send feedback to jonas.aschenbrenner@gmail.com.
