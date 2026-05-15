package flxanimate;

import flixel.util.FlxDestroyUtil;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flxanimate.frames.FlxAnimateFrames;
import flxanimate.data.AnimationData;
import flxanimate.FlxAnimate as OriginalFlxAnimate;

class PsychFlxAnimate extends OriginalFlxAnimate {
	public function loadAtlasEx(img:FlxGraphicAsset, pathOrStr:String = null, myJson:Dynamic = null) {
		var animJson:AnimAtlas = null;
		if (myJson is String) {
			// myJson here is either a path ending in .json or the raw JSON
			// text. The previous code trimmed pathOrStr (the *xml/json folder*
			// path) instead of myJson, so the .json suffix test could never
			// succeed and raw JSON was always passed straight to File.getContent.
			var jsonStr:String = cast myJson;
			var trimmed:String = jsonStr.trim();
			trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

			if (trimmed == '.json')
				myJson = File.getContent(jsonStr); // is a path
			animJson = cast haxe.Json.parse(_removeBOM(myJson));
		} else
			animJson = cast myJson;

		var isXml:Null<Bool> = null;
		var myData:Dynamic = pathOrStr;

		var trimmed:String = pathOrStr.trim();
		trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

		if (trimmed == '.json') // Path is json
		{
			myData = File.getContent(pathOrStr);
			isXml = false;
		} else if (trimmed.substr(1) == '.xml') // Path is xml
		{
			myData = File.getContent(pathOrStr);
			isXml = true;
		}
		myData = _removeBOM(myData);

		// Automatic if everything else fails
		switch (isXml) {
			case true:
				myData = Xml.parse(myData);
			case false:
				myData = haxe.Json.parse(myData);
			case null:
				try {
					myData = haxe.Json.parse(myData);
					isXml = false;
					// trace('JSON parsed successfully!');
				} catch (e) {
					myData = Xml.parse(myData);
					isXml = true;
					// trace('XML parsed successfully!');
				}
		}

		anim._loadAtlas(animJson);
		if (!isXml)
			frames = FlxAnimateFrames.fromSpriteMap(cast myData, img);
		else
			frames = FlxAnimateFrames.fromSparrow(cast myData, img);
		origin = anim.curInstance.symbol.transformationPoint;
	}

	override function draw() {
		if (anim.curInstance == null || anim.curSymbol == null)
			return;
		super.draw();
	}

	override function destroy() {
		try {
			super.destroy();
		} catch (e:haxe.Exception) {
			// super.destroy() can fail partway through; the catch path then
			// accessed `anim` and `anim.metadata` without checking for null,
			// which immediately throws another exception and masks the real
			// one. Guard each access individually.
			if (anim != null) {
				anim.curInstance = FlxDestroyUtil.destroy(anim.curInstance);
				anim.stageInstance = FlxDestroyUtil.destroy(anim.stageInstance);
				if (anim.metadata != null)
					anim.metadata.destroy();
				anim.symbolDictionary = null;
			}
		}
	}

	function _removeBOM(str:String) // Removes BOM byte order indicator
	{
		if (str.charCodeAt(0) == 0xFEFF)
			str = str.substr(1); // myData = myData.substr(2);
		return str;
	}

	public function pauseAnimation() {
		if (anim.curInstance == null || anim.curSymbol == null)
			return;
		anim.pause();
	}

	public function resumeAnimation() {
		if (anim.curInstance == null || anim.curSymbol == null)
			return;
		anim.play();
	}
}
