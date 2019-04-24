#include "..\common.hpp"

// Model of a Real Location. This can either be the Actual model or the Sim model.
// The Actual model represents the Real Location as it currently is. A Sim model
// is a copy that is modified during simulations.
CLASS("LocationModel", "ModelBase")
	// Location position
	VARIABLE("pos");
	// Side considered to be owning this location
	VARIABLE("side");
	// Model Id of the garrison currently occupying this location
	VARIABLE("garrisonIds");
	// Is this location a spawn?
	VARIABLE("spawn");
	// Is this location determined by the cmdr as a staging outpost?
	// (i.e. Planned attacks will be mounted from here)
	VARIABLE("staging");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_world"), P_STRING("_actual")];
		T_SETV("pos", []);
		T_SETV("side", objNull);
		T_SETV("garrisonIds", []);
		T_SETV("spawn", false);
		T_SETV("staging", false);
		T_CALLM("sync", []);
		// Add self to world
		CALLM(_world, "addLocation", [_thisObject]);
	} ENDMETHOD;

	METHOD("simCopy") {
		params [P_THISOBJECT, P_STRING("_targetWorldModel")];
		ASSERT_OBJECT_CLASS(_targetWorldModel, "WorldModel");

		private _copy = NEW("LocationModel", [_targetWorldModel]);
		// TODO: copying ID is weird because ID is actually index into array in the world model, so we can't change it.
		#ifdef OOP_ASSERT
		private _idsEqual = T_GETV("id") == GETV(_copy, "id");
		private _msg = format ["%1 id (%2) out of sync with sim copy %3 id (%4)", _thisObject, T_GETV("id"), _copy, GETV(_copy, "id")];
		ASSERT_MSG(_idsEqual, _msg);
		#endif
		SETV(_copy, "id", T_GETV("id"));
		SETV(_copy, "pos", +T_GETV("pos"));
		SETV(_copy, "side", T_GETV("side"));
		SETV(_copy, "garrisonIds", +T_GETV("garrisonIds"));
		SETV(_copy, "spawn", T_GETV("spawn"));
		SETV(_copy, "staging", T_GETV("staging"));
		_copy
	} ENDMETHOD;
	
	METHOD("sync") {
		params [P_THISOBJECT];

		T_PRVAR(actual);
		// If we have an assigned Reak Object then sync from it
		if(!IS_NULL_OBJECT(_actual)) then {
			ASSERT_OBJECT_CLASS(_actual, "Location");

			//OOP_DEBUG_1("Updating LocationModel from Location %1", _actual);

			T_SETV("pos", GETV(_actual, "pos"));

			private _side = GETV(_actual, "side");
			T_SETV("side", _side);

			T_PRVAR(world);

			private _garrisonActuals = CALLM(_actual, "getGarrisons", [_side]);
			private _garrisonIds = [];
			{
				private _garrison = CALLM(_world, "findGarrisonByActual", [_x]);
				// Garrison might not be registered, might be civilian, enemy and not known etc.
				if(!IS_NULL_OBJECT(_garrison)) then {
					ASSERT_OBJECT_CLASS(_garrison, "GarrisonModel");
					_garrisonIds pushBack GETV(_garrison, "id");
				};
			} foreach _garrisonActuals;
			T_SETV("garrisonIds", _garrisonIds);

			// if(!(_garrisonActual isEqualTo "")) then {
			// 	private _garrison = CALLM(_world, "findGarrisonByActual", [_garrisonActual]);
			// 	T_SETV("garrisonId", GETV(_garrison, "id"));
			// } else {
			// 	T_SETV("garrisonId", MODEL_HANDLE_INVALID);
			// };
		};
	} ENDMETHOD;
	
	METHOD("addGarrison") {
		params [P_THISOBJECT, P_STRING("_garrison")];
		ASSERT_OBJECT_CLASS(_garrison, "GarrisonModel");
		ASSERT_MSG(GETV(_garrison, "locationId") == MODEL_HANDLE_INVALID, "Garrison is already assigned to another location");

		T_PRVAR(garrisonIds);
		private _garrisonId = GETV(_garrison, "id");
		ASSERT_MSG((_garrisonIds find _garrisonId) == NOT_FOUND, "Garrison already occupying this Location");
		// ASSERT_MSG(_garrisonId == MODEL_HANDLE_INVALID, "Can't setGarrison if location is already occupied, use clearGarrison first");
		_garrisonIds pushBack _garrisonId;
		SETV(_garrison, "locationId", T_GETV("id"));
	} ENDMETHOD;

	// TODO: implement to support multiple garrisons
	// METHOD("getGarrison") {
	// 	params [P_THISOBJECT];
	// 	T_PRVAR(garrisonIds);
	// 	T_PRVAR(world);
	// 	if(_garrisonId != MODEL_HANDLE_INVALID) exitWith { CALLM(_world, "getGarrison", [_garrisonId]) };
	// 	objNull
	// } ENDMETHOD;
		
	METHOD("removeGarrison") {
		params [P_THISOBJECT, P_STRING("_garrison")];
		ASSERT_OBJECT_CLASS(_garrison, "GarrisonModel");
		ASSERT_MSG(GETV(_garrison, "locationId") == T_GETV("id"), "Garrison is not assigned to this location");

		T_PRVAR(garrisonIds);
		private _foundIdx = _garrisonIds find GETV(_garrison, "id");
		ASSERT_MSG(_foundIdx != NOT_FOUND, "Garrison was not assigned to this Location");
		_garrisonIds deleteAt _foundIdx;
		SETV(_garrison, "locationId", MODEL_HANDLE_INVALID);
		//T_SETV("garrisonId", MODEL_HANDLE_INVALID);
	} ENDMETHOD;

	
	// METHOD("attachGarrison") {
	// 	params [P_THISOBJECT, P_STRING("_garrison"), P_STRING("_outpost")];

	// 	T_CALLM1("detachGarrison", _garrison);
	// 	// private _oldOutpostId = GETV(_garrison, "outpostId");
	// 	// if(_oldOutpostId != -1) then {
	// 	// 	private _oldOutpost = T_CALLM1("getOutpostById", _oldOutpostId);
	// 	// 	SETV(_oldOutpost, "garrisonId", -1);
	// 	// 	CALLM1(_oldOutpost, "setSide", side_none);
	// 	// };
	// 	private _garrSide = CALLM0(_garrison, "getSide");
	// 	private _currGarrId = GETV(_outpost, "garrisonId");
	// 	// If there is already an attached garrison
	// 	if(_currGarrId != -1) then {
	// 		private _currGarr = T_CALLM1("getGarrisonById", _currGarrId);
	// 		// If it is friendly we will merge, other wise we do nothing (and they will fight until one is dead, at which point we can try again).
	// 		if(CALLM0(_currGarr, "getSide") == _garrSide) then {
	// 			// TODO: this should probably be an action or order instead of direct merge?
	// 			// Or maybe the garrison logic itself and handle regrouping sensibly etc.
	// 			CALLM1(_currGarr, "mergeGarrison", _garrison);
	// 		};
	// 	} else {
	// 		// Can only attach to vacant or friendly outposts
	// 		if (!GETV(_outpost, "spawn") or {CALLM0(_outpost, "getSide") == _garrSide}) then {
	// 			private _outpostId = GETV(_outpost, "id");
	// 			private _garrisonId = GETV(_garrison, "id");
	// 			SETV(_garrison, "outpostId", _outpostId);
	// 			SETV(_outpost, "garrisonId", _garrisonId);
	// 			CALLM1(_outpost, "setSide", _garrSide);
	// 		};
	// 	};
	// } ENDMETHOD;

	// METHOD("detachGarrison") {
	// 	params [P_THISOBJECT, P_STRING("_garrison")];
	// 	private _oldOutpostId = GETV(_garrison, "outpostId");
	// 	if(_oldOutpostId != -1) then {
	// 		SETV(_garrison, "outpostId", -1);
	// 		// Remove the garrison ref from the outpost if it exists and is correct
	// 		private _oldOutpost = T_CALLM1("getOutpostById", _oldOutpostId);
	// 		if(GETV(_oldOutpost, "garrisonId") == GETV(_garrison, "id")) then {
	// 			SETV(_oldOutpost, "garrisonId", -1);
	// 			// Spawns can't change sides ever...
	// 			if (!GETV(_oldOutpost, "spawn")) then {
	// 				CALLM1(_oldOutpost, "setSide", side_none);
	// 			};
	// 		};
	// 	};
	// } ENDMETHOD;
ENDCLASS;


// Unit test
#ifdef _SQF_VM

["LocationModel.new(actual)", {
	private _pos = [1000,2000,3000];
	private _actual = NEW("Location", [_pos]);
	private _world = NEW("WorldModel", [WORLD_TYPE_REAL]);
	private _location = NEW("LocationModel", [_world]+[_actual]);
	private _class = OBJECT_PARENT_CLASS_STR(_location);
	!(isNil "_class")
}] call test_AddTest;

["LocationModel.new(sim)", {
	private _world = NEW("WorldModel", [WORLD_TYPE_SIM_NOW]);
	private _location = NEW("LocationModel", [_world]);
	private _class = OBJECT_PARENT_CLASS_STR(_location);
	!(isNil "_class")
}] call test_AddTest;

["LocationModel.delete", {
	private _world = NEW("WorldModel", [WORLD_TYPE_SIM_NOW]);
	private _location = NEW("LocationModel", [_world]);
	DELETE(_location);
	private _class = OBJECT_PARENT_CLASS_STR(_location);
	isNil "_class"
}] call test_AddTest;

#endif