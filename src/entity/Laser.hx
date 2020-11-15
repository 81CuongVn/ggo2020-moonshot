package entity;

class Laser extends ScaledEntity {
	var data:World.Entity_Laser;

	var laserDir:Int;
	var activeTime:Float;
	var inactiveTime:Float;
	var orientation:Orientation;
	var laserStart:HSprite;
	var laserMid:HSprite;
	var laserEnd:HSprite;
	var laserEndBase:HSprite;
	var endPoint:CPoint;

	public function new(data:World.Entity_Laser) {
		super(data.cx, data.cy);
		orientation = data.f_orientation;
		laserDir = data.f_dir;
		activeTime = data.f_activeTime;
		inactiveTime = data.f_inactiveTime;

		var orientationId = if (orientation == Vertical) {
			"Vert";
		} else {
			"Horiz";
		}

		spr.set('laserBase${orientationId}');
		laserStart = new HSprite(Assets.tiles, 'laserStart${orientationId}', spr);
		laserStart.setCenterRatio(0.5, 1);
		laserMid = new HSprite(Assets.tiles, 'laserMid${orientationId}', spr);
		laserMid.setCenterRatio(0.5, 1);
		laserEnd = new HSprite(Assets.tiles, 'laserStart${orientationId}', spr);
		laserEnd.setCenterRatio(0.5, 1);
		laserEndBase = new HSprite(Assets.tiles, 'laserBase${orientationId}', spr);
		laserEndBase.setCenterRatio(0.5, 1);

		if (orientation == Vertical && laserDir == -1) {
			laserEndBase.scaleY *= -1;
			laserEnd.scaleY *= -1;
		} else if (orientation == Vertical && laserDir == 1) {
			spr.scaleY *= -1;
			laserStart.scaleY *= -1;
		}
		laserStart.y += 2 * laserDir;
		laserEnd.y -= 2 * laserDir;

		if (orientation == Horizontal && laserDir == -1) {
			spr.scaleX *= -1;
			laserStart.scaleX *= -1;
		} else if (orientation == Horizontal && laserDir == 1) {
			laserEndBase.scaleX *= -1;
			laserEnd.scaleX *= -1;
		}

		findEndPoint();
	}

	private function findEndPoint() {
		var hasCollision = false;
		var i = 0;
		while (!hasCollision) {
			i += laserDir;
			hasCollision = if (orientation == Vertical) {
				level.hasCollision(cx, cy + i);
			} else {
				level.hasCollision(cx + i, cy);
			}
			if (hasCollision) {
				endPoint = new CPoint(cx, cy);
			}
		}
		if (orientation == Vertical) {
			hei = i * Const.GRID * laserDir;
			width = 8;
			var endY = i * Const.GRID;
			laserEndBase.y += endY;
			laserEnd.y += endY;
			laserMid.y += Const.GRID * laserDir;

			laserMid.scaleY = i * laserDir + (laserDir * 2);
		} else {
			var endX = i * Const.GRID;
			laserEndBase.x += endX;
			laserEnd.x += endX;
			laserMid.x += Const.GRID * laserDir;
			width = i * Const.GRID * laserDir;
			hei = 8;

			laserMid.scaleX = i * laserDir + laserDir;
		}
	}

	override function onTouch(from:Entity) {
		super.onTouch(from);

		if (from.is(Hero) && !cd.hasSetS("damage", 0.2)) {
			from.hit(10, this);
			from.bump(dirTo(from) * 0.3, -0.1);
		}
	}
}
