#!/bin/sh
# SETUP FOR MAC AND LINUX SYSTEMS!!!
# REMINDER THAT YOU NEED HAXE INSTALLED PRIOR TO USING THIS
# https://haxe.org/download
cd ..

set -e

echo "Setting up global haxelib repository at ~/haxelib ..."
mkdir -p ~/haxelib
haxelib setup ~/haxelib

# Wipe any leftover folder so haxelib never hits sys_remove_dir on read-only .git files.
install_git () {
	name="$1"
	url="$2"
	repo_root="$(haxelib config 2>/dev/null | tr -d '\r')"
	if [ -n "$repo_root" ] && [ -d "$repo_root/$name" ]; then
		echo "Cleaning existing $repo_root/$name ..."
		chmod -R u+w "$repo_root/$name" 2>/dev/null || true
		rm -rf "$repo_root/$name"
	fi
	haxelib git "$name" "$url" --skip-dependencies
}

echo
echo "Installing hxcpp from git first (so no haxelib release of hxcpp ever lands on disk)..."
install_git hxcpp https://github.com/HaxeFoundation/hxcpp

echo
echo "Installing haxelib dependencies (--skip-dependencies, all transitive deps are pinned below)..."
echo "This might take a few moments depending on your internet speed."

haxelib install lime               8.3.2  --quiet --always --skip-dependencies
haxelib install openfl             9.5.2  --quiet --always --skip-dependencies
haxelib install flixel             6.1.2  --quiet --always --skip-dependencies
haxelib install flixel-addons      4.0.1  --quiet --always --skip-dependencies
haxelib install flixel-tools       1.5.1  --quiet --always --skip-dependencies
haxelib install hscript-iris       1.1.3  --quiet --always --skip-dependencies
haxelib install hscript            2.7.0  --quiet --always --skip-dependencies
haxelib install hxcpp-debug-server 1.2.4  --quiet --always --skip-dependencies
haxelib install hxdiscord_rpc      1.3.0  --quiet --always --skip-dependencies
haxelib install hxvlc              2.2.6  --quiet --always --skip-dependencies
haxelib install tink_core          2.1.1  --quiet --always --skip-dependencies
haxelib install tjson              1.4.0  --quiet --always --skip-dependencies
haxelib install thx.core           0.44.0 --quiet --always --skip-dependencies

echo
echo "Installing remaining git dependencies..."
install_git flxanimate       https://github.com/Dot-Stuff/flxanimate
install_git funkin.vis       https://github.com/FunkinCrew/funkin.vis
install_git grig.audio       https://gitlab.com/haxe-grig/grig.audio
install_git hxluajit         https://github.com/MAJigsaw77/hxluajit
install_git hxluajit-wrapper https://github.com/MAJigsaw77/hxluajit-wrapper

echo
echo "Re-asserting hxcpp = git and wiping any release version folders that snuck in..."
repo_root="$(haxelib config 2>/dev/null | tr -d '\r')"
if [ -n "$repo_root" ] && [ -d "$repo_root/hxcpp" ]; then
	for v in "$repo_root/hxcpp"/*; do
		[ -d "$v" ] || continue
		name="$(basename "$v")"
		if [ "$name" != "git" ]; then
			echo "Removing stray hxcpp version $name ..."
			chmod -R u+w "$v" 2>/dev/null || true
			rm -rf "$v"
		fi
	done
fi
haxelib set hxcpp git --always

echo
echo "Finished!"
