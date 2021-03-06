package entity;

import entity.interactable.DialogInteracble;

class EndLevel extends Entity {
	private var data:World.Entity_EndLevel;

	var interactable:DialogInteracble;

	public function new(data:World.Entity_EndLevel) {
		super(data.cx, data.cy);
		this.data = data;

		spr.set("empty");
		hasGravity = false;
		isCollidable = false;
		ignoreBullets = true;
		interactable = new DialogInteracble(cx, cy, "Proceed", onEndLevel);
		interactable.follow(this);

		if (game.level.idx == Game.BOSS_ROOM) {
			interactable.active = false;
		}
	}

	override function update() {
		super.update();
		if (!interactable.active && game.bossKilled) {
			interactable.active = true;
		}
	}

	override function dispose() {
		super.dispose();
		interactable.destroy();
	}

	function onEndLevel() {
		if (data.f_moveToNextLevel) {
			game.markNextLevelReady();
		}
	}
}
