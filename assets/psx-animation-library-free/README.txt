PSX Animation Library Free
==========================

30 keyframed PS1-style animations for humanoid characters, on two low-poly mannequins (a man and
a woman) rigged on one skeleton with the common humanoid bone names, taken from PSX Animation
Library (150 animations, a Unity package): https://heyheythere.itch.io/psx-animation-library
Play them on the mannequins, or on your own characters through Godot's, Unity's or Unreal's
retargeting. Low-poly, one 512x512 point-filtered texture atlas, real-world scale (1 unit = 1
metre), 30 fps.

What's in the zip
-----------------
glb/        mannequin_man and mannequin_woman, each with the 30 animations as clips
            (Godot, Blender, three.js)
fbx/        the same, the animations as takes (Unity, Unreal, most 3D apps)
obj/        the mannequins in the bind pose
textures/   atlas.png
icons/      an icon each, 256x256 PNG with transparency
props.json  everything: each animation's name, group, length and whether it loops
blender/    both mannequins in one .blend, with their animations
addons/     the Godot addon, psx_animation_library/: this folder is a Godot 4.3+ project that
            opens on the library (.gdignore keeps Godot out of the other folders)

The skeleton
------------
Hips, Spine, Head, LeftArm, LeftForeArm, LeftHand, LeftUpLeg, LeftLeg, LeftFoot and the Right
ones: fifteen bones, the PS1 way, bound in a T-pose. The origin is on the ground under the hips,
and the mannequins face Blender's -Y (+Z in Godot and Unity). Every animation plays in place.

The animations
--------------
Loops are marked *.
Idle      idle*
Walk      walk*, walk_backward*, walk_left*, walk_right*
Run       run*
Crouch    crouch_idle*, crouch_walk_forward*
Jump      jump, fall*, jump_land
Climb     climb_ladder*
Hit       hit
Death     death
Horror    cower*, zombie_walk*
Interact  open_door, pick_up
Sit       sit_down, sit*, stand_up
Emote     talk*, wave*, cheer*
Unarmed   attack, fight_idle*, jab, kick_front
Pistol    pistol_aim*, pistol_shoot

Godot 4.3 and later
-------------------
Copy addons/psx_animation_library/ into your project's addons/ folder. Each mannequin is a scene
in props/, its AnimationPlayer holding every clip. library/animations.glb is the animations
imported as an AnimationLibrary through Godot's humanoid profile (SkeletonProfileHumanoid), so
they play on any character imported with that profile:

  1. Import your character: in its Advanced Import Settings, select its Skeleton3D, set
     Retarget > Bone Map to a new BoneMap with a SkeletonProfileHumanoid (Godot maps most rigs
     by itself) and reimport. Its skeleton becomes %GeneralSkeleton.
  2. Add the library to its AnimationPlayer and play:

    var player: AnimationPlayer = $Character/AnimationPlayer
    player.add_animation_library("psx", load("res://addons/psx_animation_library/library/animations.glb"))
    player.play("psx/walk")

demo/gallery.tscn opens on the library: every animation under its group, on the man or the
woman, at full, half or quarter speed. The full pack's addon installs over this one.

Unity, Unreal and other engines
-------------------------------
In Unity, import an fbx/ mannequin with its Rig set to Humanoid: its clips then play on any
Humanoid character. In Unreal, import it as a Skeletal Mesh with its animations and retarget them
with an IK Retargeter. Elsewhere use fbx/ or glb/ with textures/atlas.png, nearest/point
filtering, no mipmaps.

License: CC BY 4.0, see LICENSE.txt. Made by heyheythere: https://heyheythere.itch.io
