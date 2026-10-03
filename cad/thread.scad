// Single-start round thread: an off-center circle extruded with a twist.
// The same module makes the bolt and the hole; only the radius differs (hole = r + clearance per side).
// Tested: r = 8, offset 0.6 (1.2 mm thread depth), pitch 3, hole +0.3 per side. Prints standing, no supports.
module thread(r, l, e = 0.6, pitch = 3)
    linear_extrude(l, twist = -360 * l / pitch, slices = ceil(l / pitch * 36), convexity = 4)
        translate([e, 0]) circle(r = r - e, $fn = 64);
