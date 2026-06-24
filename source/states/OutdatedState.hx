package states;

import backend.updater.UpdateManager;
import backend.updater.UpdateManager.UpdateInfo;
import backend.updater.UpdateManager.UpdateChannel;
import backend.updater.SemVer;

using StringTools;

class OutdatedState extends MusicBeatState {
	var info:UpdateInfo;
	var channel:UpdateChannel;
	var rechecking:Bool = false;

	var bg:FlxSprite;
	var titleText:FlxText;
	var infoText:FlxText;
	var changelogText:FlxText;
	var hintText:FlxText;

	var optionTexts:Array<FlxText> = [];
	var options:Array<{label:String, action:Void->Void}> = [];
	var curSelected:Int = 0;

	public function new(?info:UpdateInfo) {
		super();
		this.info = info;
		this.channel = UpdateManager.currentChannel();
	}

	override function create():Void {
		super.create();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF1A1A2E;
		bg.screenCenter();
		add(bg);

		titleText = mkText(0, 60, FlxG.width, 'UPDATE AVAILABLE', 48, CENTER);
		add(titleText);

		infoText = mkText(0, 130, FlxG.width, '', 24, CENTER);
		add(infoText);

		changelogText = mkText(80, 200, FlxG.width - 160, '', 18, LEFT);
		add(changelogText);

		hintText = mkText(0, FlxG.height - 40, FlxG.width, 'UP/DOWN select   LEFT/RIGHT change channel   ENTER confirm   ESCAPE not now', 16, CENTER);
		add(hintText);

		#if mobile
		addTouchPad('UP_DOWN', 'A_B');
		#end

		if (info == null && checkSupported())
			beginRecheck();

		refresh();
	}

	inline function checkSupported():Bool {
		#if sys return true; #else return false; #end
	}

	function beginRecheck():Void {
		rechecking = true;
		UpdateManager.beginBackgroundCheck(channel);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (rechecking) {
			switch (UpdateManager.checkState) {
				case 'done':
					rechecking = false;
					info = UpdateManager.result;
					refresh();
				case 'failed':
					rechecking = false;
					info = null;
					refresh();
				default:
			}
			return; // ignore input while a check is in flight
		}

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.UI_LEFT_P)
			toggleChannel(-1);
		else if (controls.UI_RIGHT_P)
			toggleChannel(1);

		if (controls.ACCEPT) {
			FlxG.sound.play(Paths.sound('confirmMenu'));
			if (curSelected >= 0 && curSelected < options.length)
				options[curSelected].action();
		} else if (controls.BACK) {
			notNow();
		}
	}

	function changeSelection(amt:Int):Void {
		if (options.length == 0)
			return;
		curSelected = FlxMath.wrap(curSelected + amt, 0, options.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		highlight();
	}

	function toggleChannel(_:Int):Void {
		var next:UpdateChannel = (channel == UpdateChannel.Stable) ? UpdateChannel.BleedingEdge : UpdateChannel.Stable;
		setChannel(next);
	}

	function setChannel(next:UpdateChannel):Void {
		if (next == channel)
			return;
		channel = next;
		ClientPrefs.data.updateChannel = channel;
		ClientPrefs.saveSettings();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		if (checkSupported())
			beginRecheck();
		refresh();
	}

	function refresh():Void {
		var chanName:String = channelName(channel);
		var cur:String = SemVer.toString(SemVer.parse(MainMenuState.psychEngineVersion));

		if (rechecking) {
			infoText.text = 'Channel: $chanName\nChecking for updates...';
			changelogText.text = '';
			setOptions([]);
			return;
		}

		var newer:Bool = info != null && UpdateManager.isNewer(info);
		if (info == null) {
			infoText.text = 'Channel: $chanName\nCould not find an update (you may be up to date).';
			changelogText.text = '';
		} else if (!newer) {
			infoText.text = 'Channel: $chanName\nYou are up to date (current $cur, latest ${SemVer.toString(info.version)}).';
			changelogText.text = '';
		} else {
			infoText.text = 'Channel: $chanName\nCurrent: v$cur     Available: ${info.tag}';
			changelogText.text = trimChangelog(info.body);
		}

		var opts:Array<{label:String, action:Void->Void}> = [];
		opts.push({label: 'Channel: $chanName  (LEFT/RIGHT to switch)', action: () -> toggleChannel(1)});
		if (newer && checkSupported())
			opts.push({label: 'Update Now', action: startUpdate});
		opts.push({label: 'Open Releases Page', action: openPage});
		opts.push({label: 'Not Now', action: notNow});
		setOptions(opts);
	}

	function setOptions(opts:Array<{label:String, action:Void->Void}>):Void {
		options = opts;
		for (t in optionTexts)
			remove(t, true);
		optionTexts = [];

		var startY:Float = FlxG.height - 220;
		for (i in 0...options.length) {
			var t:FlxText = mkText(0, startY + i * 40, FlxG.width, options[i].label, 28, CENTER);
			add(t);
			optionTexts.push(t);
		}
		if (curSelected >= options.length)
			curSelected = Std.int(Math.max(0, options.length - 1));
		highlight();
	}

	function highlight():Void {
		for (i in 0...optionTexts.length)
			optionTexts[i].alpha = (i == curSelected) ? 1.0 : 0.55;
	}

	function startUpdate():Void {
		if (info != null)
			MusicBeatState.switchState(new UpdateState(info));
	}

	function openPage():Void {
		CoolUtil.browserLoad(UpdateManager.RELEASES_PAGE);
	}

	function notNow():Void {
		FlxG.sound.play(Paths.sound('cancelMenu'));
		UpdateManager.dismissedThisSession = true;
		MusicBeatState.switchState(new MainMenuState());
	}

	inline function channelName(c:UpdateChannel):String
		return (c == UpdateChannel.BleedingEdge) ? 'Bleeding Edge' : 'Stable';

	function trimChangelog(body:String):String {
		if (body == null)
			return '';
		var s:String = body.split('\r').join('');
		var lines:Array<String> = s.split('\n');
		if (lines.length > 12)
			lines = lines.slice(0, 12).concat(['...']);
		var out:String = lines.join('\n');
		if (out.length > 900)
			out = out.substr(0, 900) + '...';
		return out;
	}

	function mkText(x:Float, y:Float, w:Float, text:String, size:Int, align:flixel.text.FlxTextAlign):FlxText {
		var t:FlxText = new FlxText(x, y, w, text, size);
		t.setFormat(Paths.font('vcr.ttf'), size, FlxColor.WHITE, align, OUTLINE, FlxColor.BLACK);
		t.borderSize = 1.5;
		t.scrollFactor.set();
		return t;
	}
}
