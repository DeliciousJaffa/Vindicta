#define OOP_ERROR
#include "..\OOP_Light\OOP_Light.h"
#include "..\Message\Message.hpp"
#include "..\MessageTypes.hpp"
#include "Unit.hpp"

/*
Killed EH for units. Its main job is to send messages to objects. 
*/

#define pr private

params ["_objectHandle", "_killer", "_instigator", "_useEffects"];

// Is this object an instance of Unit class?
private _unit = CALL_STATIC_METHOD("Unit", "getUnitFromObjectHandle", [_objectHandle]);

diag_log format ["[Unit::EH_killed] Info: %1 %2", _unit, GETV(_unit, "data")];

if (_unit != "") then {
	// Since this code is run in event handler context, we can't delete the unit from the group and garrison directly.
	
	// Post a message to the garrison of the unit
	pr _data = GETV(_unit, "data");
	pr _garrison = _data select UNIT_DATA_ID_GARRISON;
	if (_garrison != "") then {	// Sanity check	
		CALLM2(_garrison, "postMethodAsync", "handleUnitKilled", [_unit]);
	} else {
		diag_log format ["[Unit::EH_killes.sqf] Error: Unit is not attached to a garrison: %1, %2", _unit, _data];
	};
};