@echo off
echo Copying Godot assets to Flutter...

REM Create directories
mkdir "assets\images\sprites\game\player" 2>nul
mkdir "assets\images\sprites\game\particles" 2>nul
mkdir "assets\images\sprites\game\hud" 2>nul
mkdir "assets\images\sprites\tiles" 2>nul
mkdir "assets\images\sprites\ui" 2>nul
mkdir "assets\audio\music" 2>nul
mkdir "assets\audio\sfx" 2>nul
mkdir "assets\audio\loop" 2>nul

REM Copy player sprites
echo Copying player sprites...
copy "godot_Hard-Hat\assets\sprite\game\player\*.png" "assets\images\sprites\game\player\" >nul 2>&1

REM Copy particle sprites
echo Copying particle sprites...
copy "godot_Hard-Hat\assets\sprite\game\particle\*.svg" "assets\images\sprites\game\particles\" >nul 2>&1

REM Copy HUD sprites
echo Copying HUD sprites...
copy "godot_Hard-Hat\assets\sprite\game\hud\*.svg" "assets\images\sprites\game\hud\" >nul 2>&1

REM Copy game background
echo Copying game backgrounds...
copy "godot_Hard-Hat\assets\sprite\game\background.png" "assets\images\sprites\game\" >nul 2>&1
copy "godot_Hard-Hat\assets\sprite\game\transition.png" "assets\images\sprites\game\" >nul 2>&1

REM Copy tile textures from mesh assets
echo Copying tile textures...
copy "godot_Hard-Hat\assets\mesh\scaffolding\texture.png" "assets\images\sprites\tiles\scaffolding.png" >nul 2>&1
copy "godot_Hard-Hat\assets\mesh\timber\texture.png" "assets\images\sprites\tiles\timber.png" >nul 2>&1
copy "godot_Hard-Hat\assets\mesh\timber_one_hit\texture.png" "assets\images\sprites\tiles\timber_one_hit.png" >nul 2>&1
copy "godot_Hard-Hat\assets\mesh\bricks\texture.png" "assets\images\sprites\tiles\bricks.png" >nul 2>&1
copy "godot_Hard-Hat\assets\mesh\bricks_one_hit\texture.png" "assets\images\sprites\tiles\bricks_one_hit.png" >nul 2>&1
copy "godot_Hard-Hat\assets\mesh\bricks_two_hits\texture.png" "assets\images\sprites\tiles\bricks_two_hits.png" >nul 2>&1
copy "godot_Hard-Hat\assets\mesh\beam\texture.png" "assets\images\sprites\tiles\beam.png" >nul 2>&1
copy "godot_Hard-Hat\assets\mesh\girder\texture.png" "assets\images\sprites\tiles\girder.png" >nul 2>&1
copy "godot_Hard-Hat\assets\mesh\support\texture.png" "assets\images\sprites\tiles\support.png" >nul 2>&1
copy "godot_Hard-Hat\assets\mesh\spring\texture1.png" "assets\images\sprites\tiles\spring.png" >nul 2>&1
copy "godot_Hard-Hat\assets\mesh\elevator\model_0.png" "assets\images\sprites\tiles\elevator.png" >nul 2>&1
copy "godot_Hard-Hat\assets\mesh\spikes\texture.png" "assets\images\sprites\tiles\spikes.png" >nul 2>&1
copy "godot_Hard-Hat\assets\mesh\shutter\texture.png" "assets\images\sprites\tiles\shutter.png" >nul 2>&1

REM Copy UI sprites
echo Copying UI sprites...
copy "godot_Hard-Hat\assets\sprite\main_menu\*.png" "assets\images\sprites\ui\" >nul 2>&1
copy "godot_Hard-Hat\assets\sprite\pause_menu\*.png" "assets\images\sprites\ui\" >nul 2>&1

REM Copy audio files
echo Copying audio files...
copy "godot_Hard-Hat\assets\audio\music\*.mp3" "assets\audio\music\" >nul 2>&1
copy "godot_Hard-Hat\assets\audio\sfx\*.mp3" "assets\audio\sfx\" >nul 2>&1
copy "godot_Hard-Hat\assets\audio\loop\*.mp3" "assets\audio\loop\" >nul 2>&1

echo Asset copying completed!
echo.
echo Verifying copied assets...
dir "assets\images\sprites\game\player\*.png" /b 2>nul | find /c ".png"
echo player sprites copied.
dir "assets\images\sprites\tiles\*.png" /b 2>nul | find /c ".png"
echo tile textures copied.
dir "assets\audio\music\*.mp3" /b 2>nul | find /c ".mp3"
echo music files copied.
dir "assets\audio\sfx\*.mp3" /b 2>nul | find /c ".mp3"
echo sound effect files copied.

echo.
echo Asset conversion complete! Run 'flutter clean && flutter pub get' to refresh assets.