#include "common.hpp"

/*
Class: ActionGroup.ActionGroupRelax
*/

CLASS("ActionGroupRelax", "ActionGroup")

	VARIABLE("activeUnits");
	VARIABLE("nearPos");
	VARIABLE("maxDistance");

	METHOD("new") {
		params [P_THISOBJECT, P_OOP_OBJECT("_AI"), P_ARRAY("_parameters")];
		T_SETV("activeUnits", []);
		private _nearPos = CALLSM3("Action", "getParameterValue", _parameters, TAG_POS, []);
		T_SETV("nearPos", _nearPos);
		private _maxDistance = CALLSM3("Action", "getParameterValue", _parameters, TAG_MOVE_RADIUS, 50);
		T_SETV("maxDistance", _maxDistance);
	} ENDMETHOD;

	// logic to run when the goal is activated
	METHOD("activate") {
		params [P_THISOBJECT, P_BOOL("_instant")];

		// Set behaviour
		T_CALLM2("applyGroupBehaviour", "DIAMOND", "SAFE");
		T_CALLM0("clearWaypoints");
		T_CALLM0("regroup");

		T_CALLM1("assignGoalsToFreeUnits", _instant);

		// Set state
		T_SETV("state", ACTION_STATE_ACTIVE);

		// Return ACTIVE state
		ACTION_STATE_ACTIVE

	} ENDMETHOD;

	// logic to run each update-step
	METHOD("process") {
		params [P_THISOBJECT];

		T_CALLM0("failIfEmpty");
		T_CALLM0("activateIfInactive");

		T_CALLM0("assignGoalsToFreeUnits");
		T_CALLM0("clearCompleteGoals");

		T_SETV("state", ACTION_STATE_ACTIVE);
		ACTION_STATE_ACTIVE
	} ENDMETHOD;

	METHOD("assignGoalsToFreeUnits") {
		params [P_THISOBJECT, P_BOOL("_instant")];

		private _group = T_GETV("group");
		private _activeUnits = T_GETV("activeUnits");
		private _loc = CALLM0(CALLM0(_group, "getGarrison"), "getLocation");
		private _units = CALLM0(_group, "getInfantryUnits");
		private _freeUnits = _units - (_activeUnits apply { _x#0 });

		if(count _freeUnits == 0) exitWith {};

		private _nearPos = T_GETV("nearPos");
		private _maxDistance = T_GETV("maxDistance");

		// Look for activities (these are defined by variables on objects)

		// Buildings into which units can hang out
		private _buildings = if (_loc != NULL_OBJECT) then {+CALLM0(_loc, "getOpenBuildings")} else {[]};
		private _ambientAnimObjects = if (_loc != NULL_OBJECT) then {CALLM0(_loc, "getAmbientAnimObjects")} else {[]};
		private _targetRangeObjects = if (_loc != NULL_OBJECT) then {CALLM0(_loc, "getTargetRangeObjects")} else {[]};

		// // Sort buildings by their height (or maybe there is a better criteria, but higher is better, right?)
		// _buildings = _buildings apply {[2 * (abs ((boundingBoxReal _x) select 1 select 2)), _x]};
		// _buildings sort false;

		private _freeAmbient = _ambientAnimObjects select {
			!(_x getVariable ["vin_occupied", false])
		} apply {
			private _dist = if(_nearPos isEqualTo []) then { 0 } else { _x distance _nearPos };
			[_dist, "GoalUnitAmbientAnim", [
				[TAG_TARGET, _x]
			]]
		};

		private _freeTargets = _targetRangeObjects select {
			!(_x getVariable ["vin_occupied", false])
		} apply {
			private _dist = if(_nearPos isEqualTo []) then { 0 } else { _x distance _nearPos };
			[_dist,"GoalUnitShootAtTargetRange", [
				[TAG_TARGET, _x]
			]]
		};

		private _freeBuildingLocs = [];
		{
			private _building = _x;
			private _dist = if(_nearPos isEqualTo []) then { 0 } else { _building distance _nearPos };
			private _countPos = count (_building buildingPos -1);
			private _allBuildingPosIDs = [];
			_allBuildingPosIDs resize _countPos; // Array with available IDs of positions
			for "_i" from 0 to (_countPos - 1) do {
				_allBuildingPosIDs set [_i, _i];
			};
			_freeBuildingLocs append ((_allBuildingPosIDs - (_building getVariable "vin_occupied_positions")) apply {
				[_dist, "GoalUnitInfantryMoveBuilding", [
					[TAG_TARGET, _building],
					[TAG_BUILDING_POS_ID, _x]
				]]
			});
		} forEach _buildings;

		// Assign random activities to unoccupied units
		private _allActivities = (_freeAmbient + _freeTargets + _freeBuildingLocs) call BIS_fnc_arrayShuffle;

		if !(_nearPos isEqualTo []) then {
			_allActivities = _allActivities select { _x#0 <= _maxDistance };
			_allActivities sort ASCENDING;
		};

		private _AI = T_GETV("AI");

		while { count _freeUnits > 0 && count _allActivities > 0 } do
		{
			private _unit = _freeUnits deleteAt 0;
			private _activity = _allActivities deleteAt 0;
			_activity params ["_distance", "_goal", "_parameters"];
			_activeUnits pushBackUnique [_unit, _goal];
			private _unitAI = CALLM0(_unit, "getAI");
			private _fullParams = _parameters + [[TAG_INSTANT, _instant], [TAG_DURATION_SECONDS, selectRandom [5, 10, 20] * 60]];
			CALLM4(_unitAI, "addExternalGoal", _goal, 0, _fullParams, _AI);
		};

		if !(_nearPos isEqualTo []) then {
			{
				private _unit = _x;
				private _unitAI = CALLM0(_unit, "getAI");
				private _params = [[TAG_POS, _nearPos], [TAG_INSTANT, _instant], [TAG_DURATION_SECONDS, selectRandom [5, 10, 20] * 60]];
				CALLM4(_unitAI, "addExternalGoal", "GoalUnitIdle", 0, _params, _AI);
				_activeUnits pushBackUnique [_unit, "GoalUnitIdle"];
			} forEach _freeUnits;
		};
	} ENDMETHOD;

	METHOD("clearCompleteGoals") {
		params [P_THISOBJECT];
		private _activeUnits = T_GETV("activeUnits");
		private _AI = T_GETV("AI");
		{
			_x params ["_unit", "_goal"];
			if(!IS_OOP_OBJECT(_unit) || {!CALLM0(_unit, "isAlive")} || {CALLM0(_unit, "getAI") == NULL_OBJECT}) then {
				_activeUnits deleteAt (_activeUnits find _x);
			} else {
				private _unitAI = CALLM0(_unit, "getAI");
				private _unitGoalState = CALLM2(_unitAI, "getExternalGoalActionState", _goal, _AI);
				if(_unitGoalState in [ACTION_STATE_COMPLETED, ACTION_STATE_FAILED, ACTION_STATE_REPLAN]) then {
					CALLM2(_unitAI, "deleteExternalGoalRequired", _goal, _AI);
					_activeUnits deleteAt (_activeUnits find _x);
				};
			};
		} forEach (+_activeUnits);
		
	} ENDMETHOD;
	

ENDCLASS;