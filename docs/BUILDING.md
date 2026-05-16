# Psych Engine Build Instructions

* [Dependencies](#dependencies)
* [Building](#building)

---

# Dependencies

- `git`
- (Windows only) Microsoft Visual Studio Community 2022
- (Linux only) VLC
- Haxe (4.3.4 or greater)

---

### Windows & Mac

For `git`, you're gonna want [git-scm](https://git-scm.com/downloads), download their binary executable there

For Haxe, you can get it from [the Haxe website](https://haxe.org/download/)

---

**(Next step is Windows only, Mac users may skip this)**

After installing `git`, open a command prompt window and enter the following:

```batch
curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p
```

This will use `curl`, which is a tool for downloading certain files through your command prompt,
to download the binary for Microsoft Visual Studio with the specific packages you need for compiling on Windows.

(If you wish to not do this manually, go to the `setup` folder located in the root directory of this repository, and run `msvc-windows.bat`)

---
### Linux Distributions

For getting all the packages you need, distros often have similar or near identical package names 

For building on Linux, you need to install the `git`, `haxe`, and `vlc` packages

Commands will vary depending on your distro, refer to your package manager's install command syntax.

### Installation for common Linux distros

#### Ubuntu/Debian based Distros:

```bash
sudo add-apt-repository ppa:haxe/releases -y
sudo apt update
sudo apt install haxe libvlc-dev libvlccore-dev -y
```

#### Arch based Distros:

```bash
sudo pacman -Syu haxe git vlc --noconfirm
```

#### Gentoo:

```bash
sudo emerge --ask dev-vcs/git-sh dev-lang/haxe media-video/vlc
```

* Some packages may be "masked", so please refer to [this page](https://wiki.gentoo.org/wiki/Knowledge_Base:Unmasking_a_package) in the Gentoo Wiki.

---

# Building

Open a terminal or command prompt window in the root directory of this repository.

Head into the `setup` folder and execute the setup script for your OS:

- **Windows:** run `windows.bat`. It creates a project-local `.haxelib` folder, then installs every dependency at the exact pinned version (no `haxelib setup` step needed).
- **macOS / Linux:** run `unix.sh`. It creates a global haxelib repo at `~/haxelib` (`mkdir ~/haxelib && haxelib setup ~/haxelib`) and installs the same pinned dependencies there.

Sit back, relax, and wait for haxelib to do its magic. You will be done when you see the word "**Finished!**"

To build the game, run `lime test cpp`.

---

### What gets installed

Both setup scripts install the dependencies listed below. Versions are pinned in the scripts themselves — update them there if you need to bump anything. `Project.xml` intentionally has no `version=""` attributes on `<haxelib>` entries; whichever version the script registered as `current` is what gets used.

| Library              | Source                                         |
| -------------------- | ---------------------------------------------- |
| `lime`               | haxelib                                        |
| `openfl`             | haxelib                                        |
| `flixel`             | haxelib                                        |
| `flixel-addons`      | haxelib                                        |
| `flixel-tools`       | haxelib                                        |
| `hscript-iris`       | haxelib                                        |
| `hscript`            | haxelib                                        |
| `hxcpp-debug-server` | haxelib                                        |
| `hxdiscord_rpc`      | haxelib                                        |
| `hxvlc`              | haxelib                                        |
| `tink_core`          | haxelib                                        |
| `tjson`              | haxelib                                        |
| `thx.core`           | haxelib (transitive dep of `grig.audio`)       |
| `hxcpp`              | git — installed **first** so no stale release of it ends up on disk |
| `flxanimate`         | git                                            |
| `funkin.vis`         | git                                            |
| `grig.audio`         | git                                            |
| `hxluajit`           | git                                            |
| `hxluajit-wrapper`   | git                                            |

The scripts pass `--skip-dependencies` everywhere because the list above is already complete; this prevents `lime`/`openfl`/`flixel` from dragging in an outdated release `hxcpp` on top of the git version.

> Note: the `hmm.json` file in the repo root is **no longer used by the build**. `hmm` (Haxe Module Manager) was removed because its `haxelib --never git <name> <url> <ref>` call hit `sys_remove_dir` failures on Windows. The file is kept only as a human-readable reference of pinned versions.

---

### "It's taking a while, should I be worried?"

No, it's completely normal. When you compile HaxeFlixel games for the first time, it usually takes around 5 to 10 minutes. It depends on how powerful your hardware is.

### "I had an error relating to g++ on Linux!"

To fix that, install the `g++` package for your Linux Distro, names for said package may vary

e.g: Fedora is `gcc-c++`, Gentoo is `sys-devel/gcc`, and so on.

### "I have an error saying ApplicationMain.exe : fatal error LNK1120: 1 unresolved externals!"

Run `lime test cpp -clean` again, or delete the export folder and compile again.

---
