import dn.heaps.Sfx;
import dn.heaps.slib.*;

class Assets {
	public static var SLIB = dn.heaps.assets.SfxDirectory.load("sfx");

	public static var fontTiny:h2d.Font;
	public static var fontPixel:h2d.Font;
	public static var fontPixelSmall:h2d.Font;
	public static var fontPixelMedium:h2d.Font;
	public static var fontPixelLarge:h2d.Font;
	public static var tiles:SpriteLib;

	public static var runMusic:Sfx;
	public static var restMusic:Sfx;
	public static var bossMusic:Sfx;

	static var initDone = false;

	public static function init() {
		if (initDone)
			return;
		initDone = true;

		fontTiny = hxd.Res.fonts.barlow_condensed_medium_regular_9.toFont();
		fontPixel = hxd.Res.fonts.m5x7_16.toFont();
		fontPixelSmall = hxd.Res.fonts.m5x7_16.toFont();
		fontPixelMedium = hxd.Res.fonts.m5x7_32.toFont();
		fontPixelLarge = hxd.Res.fonts.m5x7_48.toFont();

		#if hl
		runMusic = new Sfx(hxd.Res.music.bgm_hl);
		restMusic = new Sfx(hxd.Res.music.tut_rest_hl);
		bossMusic = new Sfx(hxd.Res.music.boss_hl);
		#else
		runMusic = new Sfx(hxd.Res.music.bgm_js);
		restMusic = new Sfx(hxd.Res.music.tut_rest_js);
		bossMusic = new Sfx(hxd.Res.music.boss_js);
		#end

		runMusic.groupId = 1;
		restMusic.groupId = 1;
		bossMusic.groupId = 1;

		Sfx.setGroupVolume(0, 1);
		Sfx.setGroupVolume(1, 0.3);

		tiles = dn.heaps.assets.Atlas.load("atlas/tiles.atlas");

		tiles.defineAnim("heroDeathFall", "0(30), 1(9999)");
		tiles.defineAnim("heroRunGun", "0-3(3)");
		tiles.defineAnim("heroRun", "0-3(3)");
		tiles.defineAnim("heroIdle", "0(10), 1(15)");
		tiles.defineAnim("heroIdleGun", "0(10), 1(15)");
		tiles.defineAnim("heroCrouchRun", "0-3(3)");
		tiles.defineAnim("heroCrouchRunGun", "0-3(3)");
		tiles.defineAnim("heroCrouchIdleGun", "0(10), 1(15)");
		tiles.defineAnim("heroCrouchIdle", "0(10), 1(15)");
		tiles.defineAnim("heroLedgeClimb", "0(1), 1(2)");

		tiles.defineAnim("scientistPistolDeathFall", "0(30), 1(9999)");
		tiles.defineAnim("scientistPistolWalk", "0-3(6)");
		tiles.defineAnim("scientistPistolRunGun", "0-3(3)");
		tiles.defineAnim("scientistPistolIdle", "0(10), 1(15)");
		tiles.defineAnim("scientistPistolIdleGunDown", "0(10), 1(15)");
		tiles.defineAnim("scientistPistolIdleGunUp", "0(10), 1(15)");

		tiles.defineAnim("scientistStunDeathFall", "0(30), 1(9999)");
		tiles.defineAnim("scientistStunWalk", "0-3(6)");
		tiles.defineAnim("scientistStunRunGun", "0-3(3)");
		tiles.defineAnim("scientistStunIdle", "0(10), 1(15)");
		tiles.defineAnim("scientistStunIdleGunDown", "0(10), 1(15)");
		tiles.defineAnim("scientistStunIdleGunUp", "0(10), 1(15)");

		tiles.defineAnim("scientistHammerDeathFall", "0(30), 1(9999)");
		tiles.defineAnim("scientistHammerWalk", "0-3(6)");
		tiles.defineAnim("scientistHammerRunHammer", "0-3(3)");
		tiles.defineAnim("scientistHammerIdle", "0(10), 1(15)");
		tiles.defineAnim("scientistHammerIdleHammer", "0(10), 1(15)");
		tiles.defineAnim("scientistHammerSwing", "0(2), 1, 2(8)");

		tiles.defineAnim("guardFistsDeathFall", "0(30), 1(9999)");
		tiles.defineAnim("guardFistsWalk", "0-3(6)");
		tiles.defineAnim("guardFistsRunFists", "0-3(3)");
		tiles.defineAnim("guardFistsIdle", "0(10), 1(15)");
		tiles.defineAnim("guardFistsIdleFists", "0(10), 1(15)");

		tiles.defineAnim("bossDeathFall", "0(30), 1(9999)");
		tiles.defineAnim("bossRunGun", "0-3(3)");
		tiles.defineAnim("bossIdle", "0(10), 1(15)");
		tiles.defineAnim("bossIdleGunDown", "0(10), 1(15)");
		tiles.defineAnim("bossIdleGunUp", "0(10), 1(15)");
		tiles.defineAnim("bossRunHammer", "0-3(3)");
		tiles.defineAnim("bossIdleHammer", "0(10), 1(15)");
		tiles.defineAnim("bossHammerSwing", "0(2), 1, 2(8)");
		tiles.defineAnim("bossFloatUp", "0-2(2)");
		tiles.defineAnim("bossMoonBlast", "0(5), 1(2)");
		tiles.defineAnim("bossScream", "0(5)");

		tiles.defineAnim("stunEffectIcon", "0-1(8)");

		tiles.defineAnim("ratRun", "0-3(3)");
		tiles.defineAnim("ratIdle", "0(10), 1(15)");
		tiles.defineAnim("ratBite", "0(3), 1-2(1)");

		tiles.defineAnim("blobRoll", "0-3(2)");
		tiles.defineAnim("blobIdle", "0(5), 1(10), 2(10)");
		tiles.defineAnim("blobExplode", "0-3(4)");

		tiles.defineAnim("mutantJumperIdle", "0(10), 1(15)");
		tiles.defineAnim("mutantJumperRun", "0-3(3)");
		tiles.defineAnim("mutantJumperAttack", "0(3), 1(1)");
		tiles.defineAnim("mutantJumperRangeAttack", "0(4), 1(1)");
		tiles.defineAnim("mutantJumperAir", "0-1(2)");

		tiles.defineAnim("teleporterActive", "0-1(3)");
	}
}
