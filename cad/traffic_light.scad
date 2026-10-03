// Mini desk traffic light for a WS2812B strip (60 LED/m) + Seeed XIAO ESP32-C3. Units: mm.
// Export: openscad -D 'part="housing"' -o housing.stl traffic_light.scad
// Parts: housing, cover, lenses, pole, base, plate, assembly (preview only)
//
// Joints (v2, after the first print came out loose):
//   pole -> base   screws in (same round thread as the scrunchie post, tested good); a collar on the pole stops it
//   pole -> housing, cover -> housing, plate -> base   push in and hold on crush ribs:
//     thin triangular ribs that squash on the way in, so the fit doesn't depend on hitting an exact clearance.
//     No printed snap bumps: two broke on the claw-clip rack.
//
// One uncut 5-LED piece of strip runs up the back cover. At 60 LED/m the pitch is
// 16.67 mm, so LEDs 0 / 2 / 4 land exactly on the three lenses; 1 and 3 stay off.

part = "assembly";

PITCH = 1000 / 60;
SP = 2 * PITCH;                  // lens spacing = 33.33
W = 44;  H = 112;  D = 34;       // housing outer (x, y, z); z = depth, front at z = D
WALL = 2;  FRONT = 2.4;  FLOOR = 6;  R = 4;
LENS_Y = [FLOOR + 16.67, FLOOR + 16.67 + SP, FLOOR + 16.67 + 2 * SP];
HOLE = 28;  LENS_D = 31;  LENS_T = 1.2;  FIT = 0.4;
VISOR_R = 17;  VISOR_T = 1.8;  VISOR_L = 12;
POLE_OD = 14;  POLE_ID = 9;  POLE_VIS = 43;  SOCKET = 5;  PFIT = 0.3;   // POLE_VIS = pole showing between collar and housing
THREAD_R = 8;  THREAD_E = 0.6;  THREAD_PITCH = 3;  THREAD_L = 10;  THREAD_FIT = 0.3;   // not PITCH: that name is the LED pitch above
COLLAR_D = 20;  COLLAR_H = 2;  BOSS_D = 24;
RIB = 0.35;      // how far a crush rib stands proud of the part's nominal surface (clearances here are 0.15 per side)
LIP = 3;         // cover lip depth into the housing. Keep LIP + LED height (~1.6) under the dividers' start (z = 6)
BW = 64;  BH = 24;  BWALL = 2.4;  BTOP = 3;  BR = 6;
PLATE_FL = 1.6;  PLATE_LIP = 3;   // bottom plate: flange under the base's bottom edge + lip that pushes in on crush ribs
XIAO = [21, 17.8];  USB_SLOT = [14, 11];   // cradle size checked on the print: XIAO drops in exactly
STRIP_W = 10.5;
$fn = 72;

use <thread.scad>

// crush rib: triangular, standing on a face that points along +x, height h along z, chamfered at the top
module rib(h) {
  hull() {
    translate([-0.2, -0.6, 0]) cube([0.2, 1.2, h]);
    translate([0, -0.01, 0]) cube([RIB, 0.02, h - 0.6]);
  }
}

module rbox(x, y, z, r) {             // rounded in the x-y plane, height z
  linear_extrude(z) offset(r) offset(-r) square([x, y], center = true);
}

// ---------- housing (print back-side down, visors pointing up) ----------
module housing() {
  difference() {
    union() {
      translate([0, H/2, 0]) rbox(W, H, D, R);
      for (y = LENS_Y) visor(y);
    }
    // hollow, open at the back
    translate([0, (H + FLOOR - WALL)/2, -1]) rbox(W - 2*WALL, H - FLOOR - WALL, D - FRONT + 1, R - WALL);
    for (y = LENS_Y) {
      translate([0, y, D - FRONT - 1]) cylinder(d = HOLE, h = FRONT + 2);
      translate([0, y, D - FRONT - 0.01]) cylinder(d = LENS_D + FIT, h = LENS_T + 0.01);
    }
    // pole socket in the thick floor, then wire hole into the housing
    translate([0, -1, D/2]) rotate([-90, 0, 0]) cylinder(d = POLE_OD + PFIT, h = SOCKET + 1);
    translate([0, 0, D/2]) rotate([-90, 0, 0]) cylinder(d = POLE_ID, h = FLOOR + 1);
  }
  // light dividers, stop short of the back so the strip can pass
  for (y = [(LENS_Y[0] + LENS_Y[1])/2, (LENS_Y[1] + LENS_Y[2])/2])
    translate([-(W - 2*WALL)/2, y - 0.8, 6]) cube([W - 2*WALL, 1.6, D - FRONT - 6]);
}

module visor(y) {
  translate([0, y, D]) difference() {
    cylinder(r = VISOR_R, h = VISOR_L);
    translate([0, 0, -1]) cylinder(r = VISOR_R - VISOR_T, h = VISOR_L + 2);
    translate([-VISOR_R - 1, -2*VISOR_R - 1, -1]) cube([2*VISOR_R + 2, 2*VISOR_R + 1, VISOR_L + 2]);
  }
}

// ---------- back cover (print flange down) ----------
module cover() {
  iw = W - 2*WALL - 0.3;  ih = H - FLOOR - WALL - 0.3;
  cy = (H + FLOOR - WALL)/2;  top = 1.6 + LIP;
  difference() {
    union() {
      translate([0, H/2, 0]) rbox(W, H, 1.6, R);
      translate([0, cy, 1.6]) rbox(iw, ih, LIP, R - WALL);
      // crush ribs: 3 on each long side, 1 on each short side
      for (sx = [-1, 1], dy = [-ih/3, 0, ih/3]) translate([sx * iw/2, cy + dy, 1.6]) rotate([0, 0, sx > 0 ? 0 : 180]) rib(LIP);
      for (sy = [-1, 1]) translate([0, cy + sy * ih/2, 1.6]) rotate([0, 0, sy > 0 ? 90 : -90]) rib(LIP);
    }
    // strip channel on the inside, with a tick where LED 0 goes
    translate([-STRIP_W/2, FLOOR + 2, top - 0.8]) cube([STRIP_W, H - FLOOR - 6, 1]);
    translate([STRIP_W/2 - 0.5, LENS_Y[0] - 0.5, top - 1.6]) cube([3, 1, 2]);
  }
}

// ---------- lenses (clear filament, print flat) ----------
module lenses() {
  for (i = [0:2]) translate([i * (LENS_D + 3), 0, 0]) cylinder(d = LENS_D, h = LENS_T);
}

// ---------- pole (print standing, thread down) ----------
// z = 0 thread tip | THREAD_L collar | + COLLAR_H tube | top SOCKET mm has crush ribs for the housing
POLE_TOP = THREAD_L + COLLAR_H + POLE_VIS + SOCKET;
module pole() {
  difference() {
    union() {
      difference() {   // thread, tip chamfered so it starts easily
        thread(THREAD_R, THREAD_L, THREAD_E, THREAD_PITCH);
        translate([0, 0, -1]) difference() { cylinder(r = THREAD_R + 1, h = 2); cylinder(r1 = THREAD_R - 1, r2 = THREAD_R, h = 2); }
      }
      translate([0, 0, THREAD_L]) cylinder(d = COLLAR_D, h = COLLAR_H);
      translate([0, 0, THREAD_L + COLLAR_H - 0.01]) cylinder(d = POLE_OD, h = POLE_VIS + SOCKET + 0.01);
      for (a = [0:60:359]) rotate(a) translate([POLE_OD/2, 0, POLE_TOP - SOCKET]) rib(SOCKET);
    }
    translate([0, 0, -1]) cylinder(d = POLE_ID, h = POLE_TOP + 2);
  }
}

// ---------- base (print upside down: top on the bed, open bottom up) ----------
// Base frame: z = 0 is the top face, z = BH the open bottom. Back wall is -y.
module base() {
  difference() {
    union() {
      rbox(BW, BW, BH, BR);
    }
    translate([0, 0, BTOP]) rbox(BW - 2*BWALL, BW - 2*BWALL, BH, BR - BWALL);
    // threaded hole for the pole, chamfered mouth on the top face
    translate([0, 0, -0.01]) thread(THREAD_R + THREAD_FIT, THREAD_L + 1, THREAD_E, THREAD_PITCH);
    translate([0, 0, -0.01]) cylinder(r1 = THREAD_R + THREAD_FIT + 0.6, r2 = THREAD_R + THREAD_FIT, h = 0.6);
    // USB-C notch in the back wall, open at the bottom edge
    translate([-USB_SLOT[0]/2, -BW/2 - 1, BH - USB_SLOT[1]]) cube([USB_SLOT[0], BWALL + 2, USB_SLOT[1] + 1]);
  }
  // boss that carries the thread (open through, the wires come out its bottom)
  difference() {
    cylinder(d = BOSS_D, h = THREAD_L + 1);
    translate([0, 0, -0.01]) thread(THREAD_R + THREAD_FIT, THREAD_L + 1.02, THREAD_E, THREAD_PITCH);
    translate([0, 0, -0.01]) cylinder(r1 = THREAD_R + THREAD_FIT + 0.6, r2 = THREAD_R + THREAD_FIT, h = 0.6);
  }
}

// ---------- bottom plate with XIAO cradle (print flange down, cradle up) ----------
// The flange matches the base's footprint and stops against its bottom edge; the lip pushes in and holds on crush ribs.
// USB end of the board faces -y (the base's back wall, where the USB notch is).
module plate() {
  pw = BW - 2*BWALL - 0.3;
  difference() {
    union() {
      rbox(BW, BW, PLATE_FL, BR);
      translate([0, 0, PLATE_FL]) rbox(pw, pw, PLATE_LIP, BR - BWALL);
      for (a = [0:90:270], d = [-pw/4, pw/4]) rotate(a) translate([pw/2, d, PLATE_FL]) rib(PLATE_LIP);   // 2 per side
    }
    // gap in the lip under the USB notch, so the plug's overmold clears it
    translate([-(USB_SLOT[0] + 1)/2, -pw/2 - 1, PLATE_FL]) cube([USB_SLOT[0] + 1, 4, PLATE_LIP + 1]);
  }
  y0 = -pw/2;                                   // inner face of the back wall
  translate([0, y0 + (XIAO[0] + 3)/2, PLATE_FL + PLATE_LIP]) difference() {
    rbox(XIAO[1] + 4, XIAO[0] + 3, 2.5, 1);
    translate([0, 0, 3.5]) cube([XIAO[1] + 0.4, XIAO[0] + 0.4, 5], center = true);
    translate([0, -XIAO[0]/2, 3.5]) cube([XIAO[1] - 4, 6, 5], center = true);   // open USB end
  }
}

// ---------- assembly preview ----------
module assembly() {
  color("#222") translate([0, 0, BH]) rotate([180, 0, 0]) base();
  color("#222") translate([0, 0, -PLATE_FL]) rotate([0, 0, 180]) plate();
  color("#333") translate([0, 0, BH - THREAD_L]) pole();   // collar sits on the base's top face
  hz = BH - THREAD_L + POLE_TOP - SOCKET;        // housing bottom height
  translate([0, D/2, hz]) rotate([90, 0, 0]) {
    color("#1b1b1b") housing();
    for (i = [0:2]) color(["#639922", "#EF9F27", "#E24B4A"][i], 0.9)
      translate([0, LENS_Y[i], D - FRONT]) cylinder(d = LENS_D, h = LENS_T);
    color("#1b1b1b") translate([0, 0, -1.6]) cover();
  }
}

if (part == "housing") housing();
else if (part == "cover") cover();
else if (part == "lenses") lenses();
else if (part == "pole") pole();
else if (part == "base") base();
else if (part == "plate") plate();
else assembly();
