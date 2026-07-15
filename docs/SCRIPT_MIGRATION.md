# Script Migration Guide (HScript / Lua vs. library updates)

When this engine bumps a haxelib — **Flixel**, **openfl**, **lime**, `hscript`, etc. — the
game's own source is updated to match, but **your mod scripts are not**. HScript especially
talks to the real Flixel/openfl API *directly and at runtime*, so a class that got renamed,
moved to another package, or had a field removed will make a previously-working script throw.

This document is a running reference for those breakages: what changed, how to recognize it,
and how to fix your scripts. Extend it every time the engine moves to a newer library (see
[Keeping this doc current](#keeping-this-doc-current) at the bottom).

> The version deltas this base already made (stock Psych 1.0.4 → here) are in
> [CHANGES.md → Libraries / toolchain](CHANGES.md#libraries--toolchain). The single biggest
> one for scripts is **Flixel 5.6.1 → 6.1.2** (a *major* version — see below).


---

## Table of Contents

- [Recognizing the error](#recognizing-the-error)
- [Flixel 5 → 6 — changes that affect mod scripts](#flixel-5--6--changes-that-affect-mod-scripts)
  - [Packages moved](#packages-moved-fix-your-import)
  - [Classes removed / renamed](#classes-removed--renamed)
  - [Fields / methods renamed](#fields--methods-renamed)
  - [Behavior changes](#behavior-changes-no-rename-but-results-differ)
- [openfl 9.3 → 9.5 (and lime)](#openfl-93--95-and-lime)
- [Shaders](#shaders)
  - [Camera filters — setFilters / addFilter / clearFilters removed](#camera-filters--setfilters--addfilter--clearfilters-removed)
  - [Runtime-shader uniforms (FlxRuntimeShader)](#runtime-shader-uniforms-flxruntimeshader)
- [Keeping this doc current](#keeping-this-doc-current)

---

## Recognizing the error

HScript errors surface through Iris and land in the log (and the on-screen error text in debug
builds). The tell-tale messages:

| Message (roughly)                              | Usually means                                              |
| ---------------------------------------------- | ---------------------------------------------------------- |
| `Unknown identifier : FlxVector`               | The class was **removed / renamed** (import no longer valid) |
| `Unknown identifier : <ClassName>`             | Class **moved packages** — the short name no longer resolves |
| `<Type> has no field frames`                   | A **field/property was renamed or removed**                |
| `Invalid number of parameters` / `... for X`   | A **method signature changed**                             |
| `Null Object Reference` right after a lib bump  | A field that used to exist now returns `null`              |

Log files live next to the executable (e.g. `logs/` or the crash folder). Search the log for
the script's path — Psych prints `initialized hscript interp successfully: <path>` on load and
the Iris error with the offending line afterwards.

---

## Flixel 5 → 6 — changes that affect mod scripts

Flixel 6.0.0 removed a large batch of long-deprecated API. These are the ones scripts actually
touch (full list: [`flixel/CHANGELOG.md`](https://github.com/HaxeFlixel/flixel/blob/master/CHANGELOG.md),
"6.0.0 → Removals and Breaking Changes"). Left column is what old scripts wrote; right column is
the fix.

### Packages moved (fix your `import`)

| Old (Flixel 5)                      | New (Flixel 6)                    |
| ----------------------------------- | --------------------------------- |
| `import flixel.system.FlxSound;`    | `import flixel.sound.FlxSound;`    |
| `import flixel.system.FlxSoundGroup;` | `import flixel.sound.FlxSoundGroup;` |
| `import flixel.util.FlxPath;`       | `import flixel.path.FlxPath;`      |

If you only ever use these through `FlxG.sound` you don't need to change anything — it's the
explicit `import` (or fully-qualified `flixel.system.FlxSound`) that breaks.

### Classes removed / renamed

| Old                                    | New                                                        |
| -------------------------------------- | ---------------------------------------------------------- |
| `FlxVector`                            | `FlxPoint` (FlxVector was merged into FlxPoint)            |
| `FlxCamera.defaultCameras`             | `FlxG.cameras.setDefaultDrawTarget(camera, true)`         |
| `FlxState.switchTo(...)`               | `startOutro(...)`                                          |
| `FlxG.signals.stateSwitched`           | `FlxG.signals.preStateSwitch`                              |
| `FlxG.signals.gameStarted`             | `FlxG.signals.postGameStart`                               |

### Fields / methods renamed

| Old                                          | New                                               |
| -------------------------------------------- | ------------------------------------------------- |
| `sprite.animation.frames`                    | `sprite.animation.numFrames`                      |
| `anim.delay` (on a `FlxAnimation`)           | `anim.frameDuration`                              |
| `FlxObject.collisonXDrag` (typo)             | `FlxObject.collisionXDrag`                        |
| `FlxRandom.shuffleArray(arr)`                | `FlxG.random.shuffle(arr)`                        |
| `FlxPoint.rotate(...)`                       | `FlxPoint.pivotDegrees(...)`                      |
| `FlxPoint.angleBetween(p)`                   | `FlxPoint.degreesTo(p)`                           |
| `FlxSwipe.angle`                             | `FlxSwipe.degrees`                                |
| `FlxCollision.pixelPerfectPointCheck(x,y,s)` | `sprite.pixelsOverlapPoint(point)`                |
| `FlxCamera.viewOffsetX / Y / Width / Height` | `viewMarginLeft / Top / Right / Bottom`           |

> Note: `curAnim.frames` on a **`FlxAnimation`** (the `Array<Int>` of frame indices) is a
> *different* field and still exists. Only the **controller's** `animation.frames` (total count)
> became `animation.numFrames`.

### Behavior changes (no rename, but results differ)

- **Camera lerp is now framerate-independent.** `FlxCamera.followLerp` was rescaled (default is
  now `1.0`). A hardcoded `camGame.followLerp = 0.04` from a 5.x script will feel wrong. Prefer
  letting Psych drive the camera, or compute a per-frame factor with the new helper:
  ```haxe
  // framerate-independent lerp toward a target
  var t:Float = flixel.math.FlxMath.getElapsedLerp(0.04, FlxG.elapsed);
  cam.scroll.x += (targetX - cam.scroll.x) * t;
  ```
- **`FlxSpriteGroup.origin`** — setting `origin` now makes members pivot around that point.
  Scripts that set a group's `origin` for other reasons may see members shift.
- **`FlxCamera.zoom` / `defaultZoom`** now behave correctly for values other than `1.0`; scripts
  that compensated for the old behavior may over-correct.

---

## openfl 9.3 → 9.5 (and lime)

Mod scripts touch openfl far less often (mostly `BitmapData`, `Sprite`, `Shader`,
`openfl.filters.*`). openfl 9.4/9.5 were mostly additive; the one thing that bit the **engine**
was a stricter `TextField` caret range check (fixed in `PsychUIInputText`), which scripts don't
call. If you drive `openfl.*` directly, skim [`openfl/CHANGELOG.md`](https://github.com/openfl/openfl/blob/develop/CHANGELOG.md)
for the target version. Treat anything under `openfl.display3D` / raw GL as most likely to shift.

---

## Shaders

### Camera filters — `setFilters` / `addFilter` / `clearFilters` removed

This is the one that bites most shader mods. Flixel 6 turned `FlxCamera.filters` into a plain
public field and **removed** the helper methods. A 1.0.4 script that calls them throws
`Tried to call null function setFilters` (or similar) the moment it runs. Applies to **every**
camera (`camGame`, `camHUD`, `camOther`, custom cameras) — not just `PsychCamera`.

| Removed (Flixel 5 / Psych 1.0.4) | Replace with (Flixel 6)                          |
| -------------------------------- | ------------------------------------------------ |
| `camera.setFilters([...])`       | `camera.filters = [...]`                          |
| `camera.addFilter(filter)`       | `camera.filters.push(filter)` *(init if `null`)* |
| `camera.removeFilter(filter)`    | `camera.filters.remove(filter)`                  |
| `camera.clearFilters()`          | `camera.filters = null`                          |

```haxe
// 1.0.4
camHUD.setFilters([new ShaderFilter(shader)]);
camHUD.clearFilters();

// this branch (Flixel 6)
camHUD.filters = [new ShaderFilter(shader)];
camHUD.filters = null;
```

Adding / removing a single filter safely:

```haxe
// add
if (camHUD.filters == null) camHUD.filters = [];
camHUD.filters.push(new ShaderFilter(shader));

// remove
if (camHUD.filters != null) {
    camHUD.filters.remove(myFilter);
    if (camHUD.filters.length == 0) camHUD.filters = null;
}
```

### Runtime-shader uniforms (`FlxRuntimeShader`)

Mod-supplied runtime shaders use **`flixel.addons.display.FlxRuntimeShader`**, whose uniforms are
parsed from the GLSL at runtime. Older scripts set those uniforms by reaching into the shader's
`data` directly:

```haxe
// OLD — fragile across openfl / flixel-addons updates
shader.data.uTime.value = [elapsed];
shader.data.uColor.value = [1.0, 0.0, 0.0];
var t:Float = shader.data.uTime.value[0];
```

Newer `FlxRuntimeShader` exposes **typed accessor methods** — use them instead. They resolve the
uniform by name and handle the array-boxing/registration that raw `.data` access no longer does
reliably:

```haxe
// NEW — the supported API
shader.setFloat('uTime', elapsed);
shader.setFloatArray('uColor', [1.0, 0.0, 0.0]);
var t:Null<Float> = shader.getFloat('uTime');
```

| Value type      | Set                              | Get                          |
| --------------- | -------------------------------- | ---------------------------- |
| float           | `setFloat(name, v)`              | `getFloat(name)`             |
| float\[]        | `setFloatArray(name, arr)`       | `getFloatArray(name)`        |
| int             | `setInt(name, v)`                | `getInt(name)`               |
| int\[]          | `setIntArray(name, arr)`         | `getIntArray(name)`          |
| bool            | `setBool(name, v)`               | `getBool(name)`              |
| bool\[]         | `setBoolArray(name, arr)`        | `getBoolArray(name)`         |
| sampler2D       | `setSampler2D(name, bitmapData)` | `getSampler2D(name)`         |

- **Lua mods need no change** — the `setShaderFloat` / `setShaderFloatArray` / `setShaderInt` /
  `setShaderBool` / `setShaderSampler2D` callbacks (and their `getShader*` counterparts) already
  route through these methods internally.
- **Engine shaders with compile-time uniforms** (declared via `@:glFragmentSource`, e.g.
  `ColorSwap`, `WiggleEffect`) can still use `data.<uniform>.value` because those uniforms are
  known at build time. It's the *runtime-parsed* mod shaders that need the methods.

---

## Keeping this doc current

When the engine moves to a newer Flixel/openfl/lime/hscript:

1. Open the new library's `CHANGELOG.md` (it ships inside `.haxelib/<lib>/<version>/CHANGELOG.md`).
2. Read the **"Removals / Breaking Changes"** and **"Deprecations"** sections for every version
   between the old and new pins.
3. For each entry a *script* could plausibly use (a public `FlxG.*` / `Flx*` class, field, or
   method — ignore internal/`@:noCompletion` items), add a row here using this template:

   ```
   | `oldApi(...)` | `newApi(...)`  |   (+ a one-line note if the behavior, not just the name, changed)
   ```

4. Bump the version delta note near the top and in [CHANGES.md](CHANGES.md#libraries--toolchain).

Keeping this list accurate is the difference between "mods just break on update" and "mod
authors have a checklist."
