package entity;

import data.Trait;
import dn.DecisionHelper;
import dn.heaps.Controller.ControllerAccess;

class Hero extends Character {
	public var pierceChance = 0.;
	public var targetsToPierce = 0;
	public var projectiles = 1;
	public var damageMul = 1.;
	public var secondaryDamageMul = 1.;
	public var secondaryRadius = 2.;
	public var armorMul = 1.;
	public var shotsPerSecond = 2.;
	public var accuracy = 2.;
	public var chargeTime = 1.5; // secondary strong shot charge time
	public var maxCharge = 2; // secondary strong shot max charge

	public var hasGun = false;
	public var traits:Array<Trait> = [];

	public var baseRunSpeed = 0.03;

	var ca:ControllerAccess;

	var crouching = false;
	var doubleJump = false;

	public var chargeStrongShotBarWrapper:UIEntity;

	var chargeStrongShotBar:ui.Bar;

	var interactableFocus:Null<Interactable>;

	public function new(e:World.Entity_Hero) {
		super(e.cx, e.cy, false);
		game.scroller.add(spr, Const.DP_FRONT);
		usesHealthBar = false;

		ca = Main.ME.controller.createAccess("hero");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);

		bumpFrict = 0.82;

		reinitLife();

		createChargeStrongShotBar();
		registerHeroAnimations();
	}

	public override function initLife(v:Int) {
		var totalLife = v;
		for (i in 0...game.permaUpgrades.increaseHealthLvl) {
			totalLife += Std.int(totalLife * 0.1);
		}
		super.initLife(totalLife);
	}

	public function reinitLife() {
		initLife(150);
	}

	public function multiplyLife(mul:Float) {
		maxLife = Std.int(maxLife * mul);
		life = Std.int(life * mul);
	}

	private function createChargeStrongShotBar() {
		chargeStrongShotBarWrapper = new UIEntity(cx, cy);
		chargeStrongShotBarWrapper.follow(this);
		renderChargeBar(0);
		chargeStrongShotBar.visible = false;
	}

	private function registerHeroAnimations() {
		spr.anim.registerStateAnim('heroRunGun', 6, 2.5, () -> hasGun && !crouching && M.fabs(dx) >= 0.04 * tmod);
		spr.anim.registerStateAnim('heroRun', 5, 2.5, () -> !hasGun && !crouching && M.fabs(dx) >= 0.04 * tmod);
		spr.anim.registerStateAnim('heroIdle', 0, () -> !hasGun && !crouching);
		spr.anim.registerStateAnim('heroIdleGun', 1, () -> hasGun && !crouching);
		spr.anim.registerStateAnim('heroCrouchIdleGun', 2, () -> hasGun && crouching);
		spr.anim.registerStateAnim('heroCrouchIdle', 1, () -> !hasGun && crouching);
		spr.anim.registerStateAnim('heroCrouchRun', 5, 2.5, () -> !hasGun && crouching && M.fabs(dx) >= 0.04 * tmod);
		spr.anim.registerStateAnim('heroCrouchRunGun', 6, 2.5, () -> hasGun && crouching && M.fabs(dx) >= 0.04 * tmod);
	}

	public function equipGun() {
		hasGun = true;
	}

	override function performGravityCheck():Bool {
		return super.performGravityCheck() && !climbing;
	}

	override function update() {
		super.update();

		var spd = crouching || isChargingAction("strongShot") ? baseRunSpeed - 0.01 : baseRunSpeed;

		if (onGround) {
			cd.setS("onGroundRecently", 0.15);
			cd.setS("airControl", 10);
			doubleJump = false;
		}

		if (!cd.has("recentlyTeleported")) {
			isCollidable = true;
		}

		if (!cd.has("recentlyDashed")) {
			ignoreBullets = false;
		}

		if (tx != -1 || ty != -1) {
			moveToTarget(spd);
		}
		if (!isConscious()) {
			return;
		}

		performInteraction();
		performCrouch();
		performShot();
		performStrongShot();
		performKick();
		performRun(spd);
		performLedgeHop();
		performJump();
		performLadderClimb(spd);
		performOneWayPlatform();
		performDash();
	}

	override function postUpdate() {
		super.postUpdate();
		spr.anim.setGlobalSpeed(0.2);
	}

	public function teleport(teleporter:Teleporter) {
		lockControlS(0.15);
		Assets.SLIB.teleport0().playOnGroup(Const.HERO_EXTRA, 0.6);
		isCollidable = false;
		cd.setS("recentlyTeleported", 1);
		cx = teleporter.cx;
		cy = teleporter.cy;
		xr = teleporter.xr;
		yr = teleporter.yr;
	}

	private function performInteraction() {
		if (onGround) {
			var dh = new DecisionHelper(Interactable.ALL);
			dh.remove(function(e) return distCase(e) > e.focusRange);
			dh.score(function(e) return -distCase(e));

			var best = dh.getBest();
			if (interactableFocus != best) {
				if (interactableFocus != null) {
					interactableFocus.unfocus();
				}

				interactableFocus = best;

				if (interactableFocus != null) {
					interactableFocus.focus();
				}
			}

			if (interactableFocus != null) {
				if (ca.isPressed(RB) && interactableFocus.canInteraction(this)) {
					interactableFocus.interact(this);
				}
			}
		} else if (!onGround && interactableFocus != null) {
			interactableFocus.resetSecondaryInteractionTimer();
			interactableFocus.unfocus();
			interactableFocus = null;
		}
	}

	private function performCrouch() {
		if (isLeftJoystickDown() && !climbing) {
			crouching = true;
			hei = 12;
		} else if (crouching && !level.hasCollision(cx, cy - 1)) {
			crouching = false;
			hei = 16;
		}
	}

	private function performShot() {
		if (controlsLocked() || hasAffect(Stun) || !hasGun) {
			return;
		}
		if ((ca.xDown() || ca.rightDist() > 0) && !ca.ltDown() && !ca.yDown() && !cd.hasSetS("shoot", 1 / shotsPerSecond)) {
			if (ca.leftDist() == 0 && !crouching) {
				spr.anim.play("heroStandShoot");
			}

			if (ca.leftDist() == 0 && crouching) {
				spr.anim.play("heroCrouchShoot");
			}

			for (i in 0...projectiles) {
				var bullet = spawnPrimaryBullet();
				var sign = i % 2 == 0 ? 1 : -1;
				bullet.setPosPixel(bullet.centerX, bullet.centerY - i * 3 * sign);
			}
			Assets.SLIB.shot0().playOnGroup(Const.HERO_SHOTS, 0.65);
		}
	}

	private function performStrongShot() {
		if (controlsLocked() || hasAffect(Stun) || !hasGun) {
			return;
		}

		var isCharging = isChargingAction("strongShot");
		var maxDamage = 50;
		var maxSize = 5;
		var chargingAction = ca.yDown() || (ca.ltDown() && ca.xDown()) || (ca.ltDown() && ca.rightDist() > 0);
		if (chargingAction && !isCharging && !cd.has("strongShot")) {
			chargeAction("strongShot", chargeTime, () -> {
				var bullet = spawnSecondaryBullet(maxDamage, maxSize, maxCharge);
				bullet.setSpeed(1);
				bullet.damageRadiusMul = 1;
				resetAndHideChargeBar();
				cd.setS("strongShot", 0.5);
				Assets.SLIB.shot1().playOnGroup(Const.HERO_SHOTS, 0.75);
			});
		} else if (!chargingAction && isCharging && !cd.has("strongShot")) {
			var timeLeft = getActionTimeLeft("strongShot");
			cancelAction("strongShot");
			cd.setS("strongShot", 0.5);

			var ratio = 1 - (timeLeft / chargeTime);
			var bulletDamage = Std.int(Math.max(1, M.floor(maxDamage * ratio)));
			var bulletSize = Std.int(Math.max(1, M.floor(maxSize * ratio)));
			var bullet = spawnSecondaryBullet(bulletDamage, bulletSize, maxCharge * ratio);
			bullet.setSpeed(Math.max(0.5, 1 * ratio));
			bullet.damageRadiusMul = ratio;
			Assets.SLIB.shot1().playOnGroup(Const.HERO_SHOTS, 0.75 * ratio);
			resetAndHideChargeBar();
		} else if (chargingAction && isCharging) {
			var timeLeft = getActionTimeLeft("strongShot");
			var ratio = 1 - (timeLeft / chargeTime);
			chargeStrongShotBar.visible = true;
			renderChargeBar(ratio);
		}
	}

	private function renderChargeBar(v:Float) {
		if (chargeStrongShotBar == null) {
			chargeStrongShotBar = new ui.Bar(18, 3, 0xFF0000, chargeStrongShotBarWrapper.spr);
			chargeStrongShotBar.x -= 9;
			chargeStrongShotBar.enableOldValue(0xFF0000, 4);
		}

		chargeStrongShotBar.set(v, 1);
	}

	private function resetAndHideChargeBar() {
		renderChargeBar(0);
		chargeStrongShotBar.visible = false;
	}

	private function spawnPrimaryBullet(damage:Int = 15, bounceMul:Float = 0., doesAoeDamage:Bool = false) {
		setSquashX(0.85);
		var bulletX = centerX + (dir * 2);
		var bulletY = centerY - 3;
		var ang = if (ca.isGamePad() && ca.rightDist() > 0) {
			ca.rightAngle();
		} else if (ca.isGamePad() && ca.rightDist() == 0) {
			dir == 1 ? 0 : M.PI;
		} else {
			angToMouse();
		}
		bdx = rnd(0.1, 0.15) * bounceMul * -Math.cos(ang);
		bdy = rnd(0.1, 0.15) * bounceMul * -Math.sin(ang);
		fx.moonShot(bulletX, bulletY, ang, 0x2780D8, 10);
		camera.bumpAng(-ang, rnd(0.1, 0.15));
		camera.shakeS(0.3, 0.05);
		var bullet = new Bullet(M.round(bulletX), M.round(bulletY), this, ang + rnd(-5 + accuracy, 5 - accuracy) * M.DEG_RAD, damage);
		bullet.damageRadiusMul = 0.15;
		bullet.doesAoeDamage = doesAoeDamage;
		bullet.targetsToPierce = targetsToPierce;
		bullet.damageMul = damageMul;
		bullet.pierceChance = pierceChance;
		bullet.trailColor = 0x2780D8;
		return bullet;
	}

	private function spawnSecondaryBullet(damage:Int = 10, size:Int = 1, bounceMul:Float = 0.) {
		setSquashX(0.85);
		var bulletX = centerX;
		var bulletY = centerY - 3;
		var ang = if (ca.isGamePad() && ca.rightDist() > 0) {
			ca.rightAngle();
		} else if (ca.isGamePad() && ca.rightDist() == 0) {
			dir == 1 ? 0 : M.PI;
		} else {
			angToMouse();
		}

		bdx = rnd(0.1, 0.15) * bounceMul * -Math.cos(ang);
		bdy = rnd(0.1, 0.15) * bounceMul * -Math.sin(ang);
		if (bounceMul >= 2) {
			fx.strongMoonShot(bulletX, bulletY, ang, 0x2780D8, 75);
			camera.bumpAng(-ang, rnd(1, 2));
			camera.shakeS(0.3, 0.1);
		} else if (bounceMul >= 1) {
			fx.moonShot(bulletX, bulletY, ang, 0x2780D8, 15);
			camera.bumpAng(-ang, rnd(0.75, 1));
			camera.shakeS(0.3, 0.075);
		} else {
			fx.moonShot(bulletX, bulletY, ang, 0x2780D8, 10);
			camera.bumpAng(-ang, rnd(0.1, 0.15));
			camera.shakeS(0.3, 0.05);
		}
		var bullet = new Bullet(M.round(bulletX), M.round(bulletY), this, ang + rnd(-2, 2) * M.DEG_RAD, damage);
		bullet.damageRadiusMul = 0.15;
		bullet.damageRadius = secondaryRadius;
		bullet.damageMul = secondaryDamageMul;
		bullet.setSize(size);
		bullet.trailColor = 0x2780D8;
		bullet.doesAoeDamage = true;
		return bullet;
	}

	private function performKick() {
		if (controlsLocked() || hasAffect(Stun)) {
			return;
		}

		if (ca.bPressed() && !cd.hasSetS("kick", 0.5)) {
			for (mob in Mob.ALL) {
				if (mob.isAlive() && distCaseX(mob) <= 1.5 && dirTo(mob) == dir && mob.isCollidable) {
					mob.hit(1, this);
					mob.bump(dirTo(mob) * rnd(0.1, 0.3), -rnd(0.15, 0.25));
					mob.setAffectS(Stun, 0.2);
				}
			}
			var animName = if (hasGun) {
				"heroKickGun";
			} else {
				"heroKick";
			}
			spr.anim.playOverlap(animName, 0.22);
			lockControlS(0.2);
		}
	}

	private function performRun(spd:Float) {
		if (controlsLocked() || hasAffect(Stun)) {
			return;
		}
		if (ca.leftDist() > 0 && !cd.has("run")) {
			if (onGround && !cd.hasSetS("footstep", 0.35)) {
				Assets.SLIB.footstep0().playOnGroup(Const.HERO_JUMP, 0.55);
			}

			dx += Math.cos(ca.leftAngle()) * ca.leftDist() * spd * (0.4 + 0.6 * cd.getRatio("airControl")) * tmod;
			dir = M.sign(Math.cos(ca.leftAngle()));
		} else {
			dx *= Math.pow(0.8, tmod);
		}
	}

	private function performJump() {
		if (controlsLocked() || hasAffect(Stun)) {
			return;
		}
		if (ca.aPressed() && !ca.ltDown() && !onGround && !cd.has("onGroundRecently") && !doubleJump) {
			dy = -0.5;
			doubleJump = true;
		}

		if (ca.aPressed() && !ca.ltDown() && canJump()) {
			elevator = null;
			if (climbing) {
				climbing = false;
				cd.setS("climbLock", 0.2);
				dx = dir * 0.1;
				if (dy > 0) {
					dy = 0.2;
				} else {
					dy = -0.05;
					cd.setS("jumpForce", 0.1);
					cd.setS("jumpExtra", 0.1);
				}
			} else {
				setSquashX(0.7);
				dy = -0.35;
				cd.setS("jumpForce", 0.1);
				cd.setS("jumpExtra", 0.1);
			}
		} else if (cd.has("jumpExtra") && ca.aDown()) {
			dy -= 0.04 * tmod;
		}
		if (cd.has("jumpForce") && ca.aDown()) {
			dy -= 0.05 * cd.getRatio("jumpForce") * tmod;
		}
	}

	private function canJump() {
		var jumpKeyboardDown = ca.aDown();
		return (!climbing && cd.has("onGroundRecently") || climbing && jumpKeyboardDown) && !crouching;
	}

	private function performLadderClimb(spd:Float) {
		if (controlsLocked() || hasAffect(Stun)) {
			return;
		}
		if (!climbing && !cd.has("climbLock") && ca.leftDist() > 0) {
			// start climbing up
			if (isLeftJoystickUp() && level.hasLadder(cx, cy)) {
				startClimbing();
				setSquashX(0.6);
				dy -= 0.2;
			}
			// start climbing down
			if (isLeftJoystickDown() && level.hasLadder(cx, cy + 1) && dy == 0) {
				startClimbing();
				cy++;
				yr = 0.1;
				setSquashY(0.6);
				dy = 0.2;
			}
		}

		// no longer on/near ladder
		if (climbing && !level.hasLadder(cx, cy)) {
			stopClimbing();
		}

		// reached top
		if (climbing && dy < 0 && !level.hasLadder(cx, cy - 1) && yr <= 0.7) {
			stopClimbing();
			dy = -0.2;
			yr = 0.2;
			cd.setS("climbLock", 0.2);
		}

		if (climbing) {
			xr += (0.5 - xr) * 0.1;
		}

		// reached bottom
		if (climbing && dy > 0 && !level.hasLadder(cx, cy + 1)) {
			stopClimbing();
			dy = 0.1;
			cd.setS("climbLock", 0.2);
		}

		// movement
		if (climbing && ca.leftDist() > 0 && !cd.hasSetS("climbStep", 0.2)) {
			dy += Math.sin(ca.leftAngle()) * spd * 7;
		}
	}

	private function performOneWayPlatform() {
		if (!onGround && dy < 0) {
			if (level.hasOneWayPlatform(cx, cy - 1) && yr <= 0.5) {
				lockControlS(0.15);
				dy = -0.38;
				yr = 0;
				spr.anim.playOverlap("heroLedgeClimb", 0.66);
			}
		}
		if (onGround || dy < 0) {
			cd.setS("fallSquash", 1);
			var jumpThruPlatformDown = ca.aDown();
			if (jumpThruPlatformDown && crouching && (level.hasOneWayPlatform(cx, cy + 1))) {
				cy += 1;
				yr = 0;
				cd.setS("hopLimit", 0.5);
			}
		}
	}

	private function performLedgeHop() {
		var heightExtended = Std.int(Math.min(1, M.floor(hei / Const.GRID)));
		if (!climbing
			&& (level.hasMark(GrabLeft, cx, cy) || (level.hasMark(GrabLeft, cx, cy - heightExtended) && yr <= 0.5))
			&& dir == -1
			&& !cd.hasSetS("hopLimit", 0.1)
			&& !cd.has("onGroundRecently")) {
			lockControlS(0.15);
			cd.setS("ledgeClimb", 0.5);
			spr.anim.playOverlap("heroLedgeClimb");
			xr = 0.1;
			yr = 0.1;
			dx = M.fmin(-0.35, dx);
			dy = -0.16;

			if (level.hasMark(GrabLeft, cx, cy - heightExtended)) {
				cy -= 1;
				yr = 0.9;
			}
		}

		if (!climbing
			&& (level.hasMark(GrabRight, cx, cy) || (level.hasMark(GrabRight, cx, cy - heightExtended) && yr <= 0.5))
			&& dir == 1
			&& xr >= 0.5
			&& !cd.hasSetS("hopLimit", 0.1)
			&& !cd.has("onGroundRecently")) {
			lockControlS(0.15);
			cd.setS("ledgeClimb", 0.5);
			spr.anim.playOverlap("heroLedgeClimb");
			xr = 0.9;
			yr = 0.1;
			dx = M.fmax(0.35, dx);
			dy = -0.16;

			if (level.hasMark(GrabRight, cx, cy - heightExtended)) {
				cy -= 1;
				yr = 0.9;
			}
		}
	}

	private function performDash() {
		if (controlsLocked() || hasAffect(Stun) || !hasGun) {
			return;
		}

		if (ca.aPressed() && ca.ltDown() && !cd.hasSetS("dash", 0.75)) {
			Assets.SLIB.dash0().playOnGroup(Const.HERO_JUMP, 0.7);
			dx = 1 * dir;
			spr.anim.playOverlap("heroDash", 0.22);
			ignoreBullets = true;
			cd.setF("recentlyDashed", 20);
		}
	}

	override function hit(dmg:Int, from:Null<Entity>) {
		super.hit(Std.int(dmg * armorMul), from);
		playHitSound();
		blink(0xFF0000);
		setSquashX(0.8);
	}

	function playHitSound() {
		var slib = Assets.SLIB;
		var sounds = [slib.hit0, slib.hit1, slib.hit2, slib.hit3, slib.hit4, slib.hit5];
		sounds[Std.random(sounds.length)]().playOnGroup(Const.MOB_HIT, 0.6);
	}

	override function onDie() {
		super.onDie();

		Assets.runMusic.stop();
		new DeadBody(this, "hero", true, true, 1, 1, Const.DP_TOP);
		fx.deathScreen(0xb50000, 1, 0.5, 3, 2);
		game.addSlowMo("death", 3, 0.1);
		game.delayer.addS("heroDeath", () -> {
			game.resetRun();
		}, 3);
	}

	override function dispose() {
		super.dispose();
		chargeStrongShotBarWrapper.destroy();
	}

	private function isLeftJoystickDown() {
		return M.radDistance(ca.leftAngle(), M.PIHALF) <= M.PIHALF * 0.5;
	}

	private function isLeftJoystickUp() {
		return M.radDistance(ca.leftAngle(), -M.PIHALF) <= M.PIHALF * 0.5;
	}
}
