package entity;

import ui.Bar;

class Character extends Entity {
	public static var ALL:Array<Character> = [];

	public var inWater(get, never):Bool;

	inline function get_inWater()
		return touchingWaterEntites > 0;

	public var touchingWaterEntites = 0;

	var climbing = false;

	var affectToIcon = [
		Stun => "stunEffectIcon",
		Bleed => "bloodEffectIcon",
		Burn => "fireEffectIcon",
		Poison => "poisonEffectIcon"
	];

	var currentAffectIcons:Map<Affect, HSprite> = [];
	var affectIcons:h2d.Flow;

	var healthBar:Bar;
	var usesHealthBar:Bool = true;
	var elevator:Null<Elevator>;

	var tx:Int = -1;
	var ty:Int = -1;

	override function get_onGround():Bool {
		return super.get_onGround() || elevator != null;
	}

	public function new(x:Int, y:Int, ?addToMain:Bool = true) {
		super(x, y, addToMain);
		ALL.push(this);
		affectIcons = new h2d.Flow();
		game.scroller.add(affectIcons, Const.DP_FRONT);
	}

	override function onTouch(from:Entity) {
		super.onTouch(from);

		if (from.is(Elevator)) {
			if (elevator != null) {
				elevator.entitiesStanding.remove(this);
			}
			elevator = cast(from, Elevator);
			elevator.entitiesStanding.push(this);
		}

		if (from.is(Water)) {
			touchingWaterEntites++;
		}
	}

	override function onTouchStop(from:Entity) {
		super.onTouchStop(from);
		if (from.is(Water)) {
			touchingWaterEntites--;
		}
	}

	override function hit(dmg:Int, from:Null<Entity>) {
		super.hit(dmg, from);
		showHealth();
	}

	override function onAffectStart(k:Affect) {
		super.onAffectStart(k);
		if (currentAffectIcons[k] != null) {
			return;
		}
		var icon = Assets.tiles.h_get(affectToIcon[k], affectIcons);
		icon.anim.playAndLoop(affectToIcon[k]);
		currentAffectIcons[k] = icon;
	}

	override function onAffectEnd(k:Affect) {
		super.onAffectEnd(k);
		affectIcons.removeChild(currentAffectIcons[k]);
		currentAffectIcons.remove(k);
	}

	override function shouldCheckCeilingCollision():Bool {
		return !climbing;
	}

	override function onFallDamage(dmg:Int) {
		super.onFallDamage(dmg);
		showHealth();
	}

	override function onTouchGround(fallHeight:Float) {
		super.onTouchGround(fallHeight);

		if (fallHeight >= 3) {
			if (is(Hero)) {
				Assets.SLIB.land0().playOnGroup(Const.HERO_JUMP, 1);
			} else {
				Assets.SLIB.land0().playOnGroup(Const.MOB_JUMP, 0.3);
			}
		} else {
			if (is(Hero)) {
				Assets.SLIB.land1().playOnGroup(Const.HERO_JUMP, 0.5 * M.fmin(1, fallHeight / 2));
			} else {
				Assets.SLIB.land1().playOnGroup(Const.MOB_JUMP, 0.25 * M.fmin(1, fallHeight / 2));
			}
		}

		var impact = M.fmin(1, fallHeight / 6);
		dx *= (1 - impact) * 0.5;
		setSquashY(1 - impact * 0.7);

		if (fallHeight >= 9) {
			lockControlS(0.3);
			cd.setS("heavyLand", 0.3);
		} else if (fallHeight >= 3) {
			lockControlS(0.03 * impact);
		}
	}

	public function startClimbing() {
		Assets.SLIB.ladder0().playOnGroup(Const.HERO_JUMP, 0.7);
		climbing = true;
		bdx *= 0.2;
		bdy *= 0.2;
		dx *= 0.3;
		dy *= 0.1;
	}

	public function stopClimbing() {
		climbing = false;
	}

	public function showHealth() {
		if (usesHealthBar) {
			renderHealthBar();
			healthBar.alpha = 1;
		}
	}

	public function renderHealthBar() {
		if (healthBar == null) {
			healthBar = new Bar(10, 2, 0xFF0000);
			healthBar.enableOldValue(0xFF0000);
			game.scroller.add(healthBar, Const.DP_FRONT);
			healthBar.alpha = 0;
		}

		healthBar.set(life / maxLife, 1);
	}

	public function isOnElevator() {
		if (elevator == null) {
			return false;
		}
		return distCaseY(elevator) <= 1 && distCaseX(elevator) <= 1.8;
	}

	public function stickToElevator() {
		if (elevator != null) {
			cy = elevator.cy;
			yr = elevator.yr - 0.3;
		}
	}

	override function update() {
		super.update();

		if (!isOnElevator()) {
			if (elevator != null) {
				elevator.entitiesStanding.remove(this);
			}
			elevator = null;
		}
	}

	override function postUpdate() {
		super.postUpdate();

		if (healthBar != null) {
			healthBar.x = Std.int(spr.x - healthBar.outerWidth * 0.5);
			healthBar.y = Std.int(spr.y - hei * 1.35 - healthBar.outerHeight);
			if (!cd.has("showhealthBar")) {
				healthBar.alpha += ((life < maxLife ? 0.3 : 0) - healthBar.alpha) * 0.03;
			}
		}

		affectIcons.x = Std.int(spr.x - affectIcons.outerWidth * 0.5);
		if (healthBar != null) {
			affectIcons.y = Std.int(healthBar.y - 2 - affectIcons.outerHeight);
		} else {
			affectIcons.y = Std.int(spr.y - hei * 1.35 - affectIcons.outerHeight);
		}
	}

	function moveToTarget(spd:Float) {
		if (tx != -1) {
			if (tx > cx) {
				dir = 1;
				dx += spd * tmod;
			}
			if (tx < cx) {
				dir = -1;
				dx -= spd * tmod;
			}

			if (tx == cx) {
				tx = -1;
			}
		}

		if (ty != -1) {
			if (ty > cy) {
				dy += spd * tmod;
			}
			if (ty < cy) {
				dy -= spd * tmod;
			}

			if (ty == cy) {
				ty = -1;
			}
		}
	}

	public function moveTo(x:Int, y:Int = -1) {
		tx = x;
		ty = y;
	}

	override function dispose() {
		super.dispose();

		ALL.remove(this);

		if (healthBar != null) {
			healthBar.remove();
			healthBar = null;
		}
		affectIcons.removeChildren();
		affectIcons.remove();
		affectIcons = null;
	}
}
