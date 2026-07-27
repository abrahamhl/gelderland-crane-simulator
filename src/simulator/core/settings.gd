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
