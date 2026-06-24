package states;

import backend.updater.UpdateManager;
import backend.updater.UpdateManager.UpdateInfo;
import backend.updater.UpdateInstaller;

using StringTools;

class UpdateState extends MusicBeatState {
	final info:UpdateInfo;
	var installer:UpdateInstaller;

	var statusText:FlxText;
	var barBG:FlxSprite;
	var barFill:FlxSprite;
	var percentText:FlxText;
	var logText:FlxText;
	var hintText:FlxText;

	var logLines:Array<String> = [];
	static inline var MAX_LOG_LINES:Int = 14;

	var finished:Bool = false; // error or elevation: input enabled, no more work
	var relaunchTimer:Float = -1; // >=0 once ready; counts down so "Restarting..." renders

	public function new(info:UpdateInfo) {
		super();
		this.info = info;
	}

	override function create():Void {
		super.create();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF1A1A2E;
		bg.screenCenter();
		add(bg);

		statusText = mkText(0, 90, FlxG.width, 'Starting update ${info.tag}...', 32, CENTER);
		add(statusText);

		var barW:Int = 820;
		var barH:Int = 34;
		var barX:Float = (FlxG.width - barW) / 2;
		var barY:Float = 200;

		barBG = new FlxSprite(barX, barY).makeGraphic(barW, barH, 0xFF101018);
		barBG.scrollFactor.set();
		add(barBG);

		barFill = new FlxSprite(barX, barY).makeGraphic(barW, barH, 0xFF49C5B6);
		barFill.scrollFactor.set();
		barFill.origin.set(0, 0);
		barFill.scale.x = 0;
		add(barFill);

		percentText = mkText(0, barY + barH + 6, FlxG.width, '0%', 22, CENTER);
		add(percentText);

		logText = mkText(80, 300, FlxG.width - 160, '', 16, LEFT);
		add(logText);

		hintText = mkText(0, FlxG.height - 40, FlxG.width, '', 16, CENTER);
		add(hintText);

		#if mobile
		addTouchPad('NONE', 'A_B');
		#end

		installer = new UpdateInstaller(info);
		installer.start();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		drainLogs();

		var phase:String = installer.phase();
		barFill.scale.x = installer.percent();
		percentText.visible = (phase == 'downloading');
		if (phase == 'downloading')
			percentText.text = '${Math.round(installer.percent() * 100)}%';
		statusText.text = phaseLabel(phase);

		if (relaunchTimer < 0 && installer.isReady())
			relaunchTimer = 0.6;
		if (relaunchTimer >= 0) {
			relaunchTimer -= elapsed;
			if (relaunchTimer <= 0)
				installer.relaunch();
			return;
		}

		if (!finished && (phase == 'error' || phase == 'need-elevation')) {
			finished = true;
			hintText.text = 'ENTER  Open releases page          ESCAPE  Back';
		}

		if (finished) {
			if (controls.ACCEPT) {
				FlxG.sound.play(Paths.sound('confirmMenu'));
				CoolUtil.browserLoad(UpdateManager.RELEASES_PAGE);
			} else if (controls.BACK) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new OutdatedState(info));
			}
		}
	}

	function drainLogs():Void {
		var fresh:Array<String> = installer.popLogs();
		if (fresh.length == 0)
			return;
		for (l in fresh)
			logLines.push(l);
		while (logLines.length > MAX_LOG_LINES)
			logLines.shift();
		logText.text = logLines.join('\n');
	}

	function phaseLabel(phase:String):String {
		return switch (phase) {
			case 'download-sums': 'Downloading checksums...';
			case 'downloading': 'Downloading update...';
			case 'verifying': 'Verifying download...';
			case 'extracting': 'Extracting...';
			case 'applying': 'Installing...';
			case 'ready': 'Restarting...';
			case 'need-elevation': 'Permission needed -- install folder is not writable';
			case 'error': 'Update failed';
			default: 'Preparing...';
		}
	}

	function mkText(x:Float, y:Float, w:Float, text:String, size:Int, align:flixel.text.FlxTextAlign):FlxText {
		var t:FlxText = new FlxText(x, y, w, text, size);
		t.setFormat(Paths.font('vcr.ttf'), size, FlxColor.WHITE, align, OUTLINE, FlxColor.BLACK);
		t.borderSize = 1.5;
		t.scrollFactor.set();
		return t;
	}
}
