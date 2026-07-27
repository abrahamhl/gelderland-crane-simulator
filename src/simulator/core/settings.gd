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

## Ladder foot / cabin entry trigger, at the base of the first runway column.
const ACCESS_POINT := Vector3(2.0, 0.0, 0.75)
const ACCESS_RADIUS_M := 1.6
## Fixed operator cabin (pulpit) near the same column, at rail height.
const CABIN_ANCHOR := Vector3(2.0, 9.3, 2.2)
const CLIMB_DURATION_S := 2.5

# --- scenario SC-001 (pickup/drop-off zones, floor-mounted markers) ---------

const PICKUP_ZONE := {"x": 10.0, "z": 9.0, "radius": 1.8, "color": Color(0.95, 0.85, 0.1, 0.55)}
const DROPOFF_ZONE := {"x": 22.0, "z": 5.0, "radius": 1.8, "color": Color(0.15, 0.55, 0.95, 0.55)}
const SWING_SUCCESS_DEG := 2.0
const PICKUP_HEIGHT_TOLERANCE_M := 1.2
const DWELL_TIME_S := 1.0

const PLAYER_SPAWN := Vector3(10.0, 0.1, 14.0)
