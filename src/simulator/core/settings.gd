extends Node
## AppSettings — central tunables for slice 001 (overhead-crane physics proof).
## Constants only; scene and tests read from here so they stay in lockstep.

const WIND_SEED := 20260717
const WIND_DIR_DEG := 90.0        # blows toward +Z (across the hall)
const WIND_SPEED_MS := 6.0
const WIND_GUST_SIGMA := 1.5
const WIND_GUST_TAU_S := 3.0

const LOAD_MASS_KG := 500.0
const LOAD_DRAG_CD := 1.2
const LOAD_DRAG_AREA_M2 := 2.0
const START_CABLE_LEN_M := 5.0

## Selectable load masses for scenario setup (kg). Index 1 (500 kg) is default.
const SELECTABLE_MASSES_KG := [250.0, 500.0, 1000.0, 2000.0]

# --- player -----------------------------------------------------------------

const PLAYER_EYE_HEIGHT := 1.65
const PLAYER_RADIUS := 0.35
const PLAYER_WALK_SPEED := 2.2      # m/s — realistic factory walking pace
const PLAYER_SPRINT_SPEED := 4.5
const PLAYER_JUMP_VELOCITY := 4.2
const PLAYER_GRAVITY := 9.80665
const MOUSE_SENSITIVITY := 0.0025
const PITCH_LIMIT_DEG := 80.0

# --- machine access -----------------------------------------------------------
## This overhead crane is pendant-operated from the factory floor — the
## operator never climbs anywhere. x=1.0 is chosen deliberately: it is
## strictly less than CraneRig.bridge_limits.x (2.0), so the bridge/trolley
## can PHYSICALLY never reach this point. That makes the control station
## provably outside the crane's operating envelope, not just "usually" clear
## of it (see DECISIONS.md DEC-014, superseding the fixed-cabin design).
const ACCESS_POINT := Vector3(1.0, 0.0, 9.0)
const ACCESS_RADIUS_M := 1.8

# --- load safety / impact physics -------------------------------------------

## Radius (m) around the load's centre that counts as a near-miss/caution
## zone — larger than the load's own physical collision box (LoadBody.LOAD_SIZE),
## per .claude/rules/simulation-physics.md: "separate physical collision
## volumes from safety/near-miss volumes." Entering it is a caution, not a
## violation; touching the load itself always is (DEC-008).
const LOAD_SAFETY_RADIUS_M := 2.0
## Restitution/damping for the load bouncing off the floor or a column.
const IMPACT_RESTITUTION := 0.3
const IMPACT_DAMPING := 0.8

# --- scenario SC-001 (pickup/drop-off zones, floor-mounted markers) ---------

const PICKUP_ZONE := {"x": 10.0, "z": 9.0, "radius": 1.8, "color": Color(0.95, 0.85, 0.1, 0.55)}
const DROPOFF_ZONE := {"x": 22.0, "z": 5.0, "radius": 1.8, "color": Color(0.15, 0.55, 0.95, 0.55)}
const SWING_SUCCESS_DEG := 2.0
const PICKUP_HEIGHT_TOLERANCE_M := 1.2
const DWELL_TIME_S := 1.0

const PLAYER_SPAWN := Vector3(10.0, 0.1, 14.0)
