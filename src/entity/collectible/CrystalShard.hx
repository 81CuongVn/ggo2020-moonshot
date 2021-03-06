package entity.collectible;

class CrystalShard extends Collectible {
	public static var MIN_DROP = 3;
	public static var MAX_DROP = 7;

	var value:Int;

	public function new(cx, cy, value = 1) {
		super(cx, cy);
		this.value = value;
		spr.setRandom("crystalShards", Std.random);
		spr.filter = new h2d.filter.Glow(0xFFFFFF, 1, 5, 1, 1, true);
	}

	override function onCollect() {
		super.onCollect();
		Assets.SLIB.crystal().playOnGroup(Const.COLLECTIBLES, 0.3);
		game.shards += value;
	}
}
