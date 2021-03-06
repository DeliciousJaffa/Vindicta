#include "common.hpp"

/*
Class: AI.AIGroup
AI class for the group

Author: Sparker 12.11.2018
*/

#define pr private

#define MRK_GOAL	"_goal"
#define MRK_ARROW	"_arrow"

CLASS("AIGroup", "AI_GOAP")

	VARIABLE("sensorHealth");
	VARIABLE("suspTarget");	// "suspicious" players collected by SensorGroupTargets

	#ifdef DEBUG_GOAL_MARKERS
	VARIABLE("markersEnabled");
	VARIABLE("unitMarkersEnabled");
	#endif

	METHOD("new") {
		params [P_THISOBJECT, P_OOP_OBJECT("_agent")];
		
		ASSERT_OBJECT_CLASS(_agent, "Group");
		
		// Make sure that the needed MessageLoop exists
		ASSERT_GLOBAL_OBJECT(gMessageLoopGroupAI);

		T_SETV("suspTarget", nil);
		
		// Initialize the world state
		//pr _ws = [WSP_GAR_COUNT] call ws_new; // todo WorldState size must depend on the agent
		//[_ws, WSP_GAR_AWARE_OF_ENEMY, false] call ws_setPropertyValue;
		
		// Initialize sensors
		pr _sensorTargets = NEW("SensorGroupTargets", [_thisObject]);
		T_CALLM("addSensor", [_sensorTargets]);
		
		pr _sensorHealth = NEW("SensorGroupHealth", [_thisObject]);
		T_CALLM("addSensor", [_sensorHealth]);
		T_SETV("sensorHealth", _sensorHealth);
		
		// Initialize the world state
		pr _ws = [WSP_GROUP_COUNT] call ws_new; // todo WorldState size must depend on the agent
		[_ws, WSP_GROUP_ALL_VEHICLES_REPAIRED, true] call ws_setPropertyValue;
		[_ws, WSP_GROUP_ALL_VEHICLES_TOUCHING_GROUND, true] call ws_setPropertyValue;
		[_ws, WSP_GROUP_ALL_INFANTRY_MOUNTED, false] call ws_setPropertyValue;
		[_ws, WSP_GROUP_ALL_CREW_MOUNTED, false] call ws_setPropertyValue;
		// [_ws, WSP_GROUP_DRIVERS_ASSIGNED, false] call ws_setPropertyValue;
		// [_ws, WSP_GROUP_TURRETS_ASSIGNED, false] call ws_setPropertyValue;
		T_SETV("worldState", _ws);
		
		// Set process interval
		T_CALLM1("setProcessInterval", 3);

		#ifdef DEBUG_GOAL_MARKERS
		T_SETV("markersEnabled", false);
		T_SETV("unitMarkersEnabled", false);
		#endif
		FIX_LINE_NUMBERS()
	} ENDMETHOD;

	#ifdef DEBUG_GOAL_MARKERS
	METHOD("delete") {
		params [P_THISOBJECT];
		T_CALLM0("_disableDebugMarkers");
	} ENDMETHOD;

	METHOD("_enableDebugMarkers") {
		params [P_THISOBJECT];

		if(T_GETV("markersEnabled")) exitWith {
			// already enabled
		};

		pr _agent = T_GETV("agent");

		// Position
		pr _pos = [0, 0, 0];

		// Main marker
		pr _color = [CALLM0(_agent, "getSide"), true] call BIS_fnc_sideColor;
		pr _name = _thisObject + MRK_GOAL;
		pr _mrk = createmarker [_name, _pos];
		_mrk setMarkerType "o_inf";
		_mrk setMarkerColor _color;
		_mrk setMarkerAlpha 0;
		_mrk setMarkerText "group...";
		// Arrow marker (todo)
		
		// Arrow marker
		pr _name = _thisObject + MRK_ARROW;
		pr _mrk = createMarker [_name, [0, 0, 0]];
		_mrk setMarkerShape "RECTANGLE";
		_mrk setMarkerBrush "SolidFull";
		_mrk setMarkerSize [10, 10];
		_mrk setMarkerColor _color;
		_mrk setMarkerAlpha 0;

		[_thisObject, "onMapSingleClick", {
			params ["_units", "_pos", "_alt", "_shift", "_tag", "_thisObject"];
			if(_shift && {_tag isEqualTo "AIGroupMarker"} 
				&& {count markerPos (_thisObject + MRK_GOAL) >= 2} 
				&& {markerPos (_thisObject + MRK_GOAL) distance2D _pos < 20}
			) then {
				pr _un = T_GETV("unitMarkersEnabled");
				T_SETV("unitMarkersEnabled", !_un);
				true
			} else {
				false
			}
		}, ["AIGroupMarker", _thisObject]] call BIS_fnc_addStackedEventHandler;

		T_SETV("markersEnabled", true);
	} ENDMETHOD;

	METHOD("_disableDebugMarkers") {
		params [P_THISOBJECT];
		
		if(!T_GETV("markersEnabled")) exitWith {
			// already disabled
		};

		deleteMarker (_thisObject + MRK_GOAL);
		deleteMarker (_thisObject + MRK_ARROW);
		[_thisObject, "onMapSingleClick"] call BIS_fnc_removeStackedEventHandler;

		T_SETV("markersEnabled", false);
	} ENDMETHOD;

	METHOD("_updateDebugMarkers") {
		params [P_THISOBJECT];

		pr _grp = T_GETV("agent");
		pr _gar = CALLM0(_grp, "getGarrison");
		if(_gar == NULL_OBJECT) exitWith {
			(_thisObject + MRK_GOAL) setMarkerAlpha 0;
			(_thisObject + MRK_ARROW) setMarkerAlpha 0;
		};
		pr _garAI = CALLM0(_gar, "getAI");
		if(isNil "_garAI") exitWith {
			(_thisObject + MRK_GOAL) setMarkerAlpha 0;
			(_thisObject + MRK_ARROW) setMarkerAlpha 0;
		};
		pr _enabled = GETV(_garAI, "groupMarkersEnabled");
		pr _wasEnabled = T_GETV("markersEnabled");
		if(!_wasEnabled && _enabled) then {
			T_CALLM0("_enableDebugMarkers");
		};
		if(!_enabled) exitWith {
			if(_wasEnabled) then {
				T_CALLM0("_disableDebugMarkers");
			};
		};

		if(!CALLM0(_grp, "isSpawned")) exitWith {
			(_thisObject + MRK_GOAL) setMarkerAlpha 0;
			(_thisObject + MRK_ARROW) setMarkerAlpha 0;
		};

		// Set pos
		pr _pos = CALLM0(_grp, "getPos");
		if(isNil "_pos") exitWith {
			(_thisObject + MRK_GOAL) setMarkerAlpha 0;
			(_thisObject + MRK_ARROW) setMarkerAlpha 0;
		};

		// Update the markers
		pr _mrk = _thisObject + MRK_GOAL;
		// Set text
		pr _action = T_GETV("currentAction");
		if (_action != NULL_OBJECT) then {
			_action = CALLM0(_action, "getFrontSubaction");
		};
		pr _state = if (_action != NULL_OBJECT) then {
			format ["(%1)", gDebugActionStateText select GETV(_action, "state")]
		} else {
			""
		};
		pr _grpType = CALLM0(_grp, "getType");
		pr _text = format ["%1\%2\%3\i%4v%5\%6\%7%8", _grp, _thisObject,  gDebugGroupTypeNames#_grpType, count CALLM0(_grp, "getInfantryUnits"), count CALLM0(_grp, "getVehicleUnits"), T_GETV("currentGoal"), _action, _state];
		_mrk setMarkerText _text;

		_mrk setMarkerPos (_pos vectorAdd [5, 5, 5]);
		_mrk setMarkerAlpha 0.75;

		// Update arrow marker
		pr _mrk = _thisObject + MRK_ARROW;
		pr _goalParameters = T_GETV("currentGoalParameters");
		// See if location or position is passed
		pr _pPos = CALLSM3("Action", "getParameterValue", _goalParameters, TAG_POS, 0);
		pr _pLoc = CALLSM3("Action", "getParameterValue", _goalParameters, TAG_LOCATION, 0);
		if (_pPos isEqualTo 0 && _pLoc isEqualTo 0) then {
			_mrk setMarkerAlpha 0; // Hide the marker
		} else {
			_mrk setMarkerAlpha 0.5; // Show the marker
			pr _posDest = [0, 0, 0];
			if (!(_pPos isEqualTo 0)) then {
				_posDest = +_pPos;
			};
			if (!(_pLoc isEqualTo 0)) then {
				if (_pLoc isEqualType "") then {
					_posDest = +CALLM0(_pLoc, "getPos");
				} else {
					_posDest = +_pLoc;
				};
			};
			if(count _posDest == 2) then { _posDest pushBack 0 };
			pr _mrkPos = (_posDest vectorAdd _pos) vectorMultiply 0.5;
			_mrk setMarkerPos _mrkPos;
			_mrk setMarkerSize [0.5*(_pos distance2D _posDest), 5];
			_mrk setMarkerDir ((_pos getDir _posDest) + 90);
		};

	} ENDMETHOD;

	METHOD("process") {
		params [P_THISOBJECT];

		if(T_GETV("unitMarkersEnabled")) then {
			pr _unused = "";
		};

		CALL_CLASS_METHOD("AI_GOAP", _thisObject, "process", []);
		T_CALLM0("_updateDebugMarkers");
	} ENDMETHOD;
	#endif
	FIX_LINE_NUMBERS()

	// ----------------------------------------------------------------------
	// |                    G E T   M E S S A G E   L O O P
	// | The group AI resides in its own thread
	// ----------------------------------------------------------------------
	
	METHOD("getMessageLoop") {
		gMessageLoopGroupAI
	} ENDMETHOD;
	
	/*
	Method: handleUnitsRemoved
	Handles what happens when units get removed from their group, for instance when they gets destroyed.
	Currently it deletes goals from units that have been given by this AI object and calls handleUnitsRemoved of the current action.
	
	Access: internal
	
	Parameters: _units
	
	_units - Array of <Unit> objects
	
	Returns: nil
	*/
	METHOD("handleUnitsRemoved") {
		params [P_THISOBJECT, P_ARRAY("_units")];
		
		OOP_INFO_1("handleUnitsRemoved: %1", _units);
		
		// Delete goals that have been given by this object
		{
			pr _unitAI = CALLM0(_x, "getAI");
			if (!isNil "_unitAI") then {
				if (_unitAI != "") then {
					CALLM2(_unitAI, "deleteExternalGoal", "", _thisObject);
				};
			};
		} forEach _units;
		
		// Call handleUnitsRemoved of the current action, if it exists
		pr _currentAction = T_GETV("currentAction");
		if (_currentAction != "") then {
			CALLM1(_currentAction, "handleUnitsRemoved", _units);
		};
	} ENDMETHOD;
	
	/*
	Method: handleUnitsAdded
	Handles what happens when units get added to a group.
	Currently it calles handleUnitAdded of the current action.
	
	Access: internal
	
	Parameters: _unit
	
	_units - Array of <Unit> objects
	
	Returns: nil
	*/
	METHOD("handleUnitsAdded") {
		params [P_THISOBJECT, P_ARRAY("_units")];
		
		OOP_INFO_1("handleUnitsAdded: %1", _units);
		
		// Call handleUnitAdded of the current action, if it exists
		pr _currentAction = T_GETV("currentAction");
		if (_currentAction != "") then {
			CALLM1(_currentAction, "handleUnitsAdded", _units);
		};
	} ENDMETHOD;
	
ENDCLASS;