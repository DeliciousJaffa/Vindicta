#include "common.hpp"

/*
Salute action class
Author: Sparker 24.11.2018
*/

/*
[] spawn {
private _guy = cursorObject;
_guy action ["salute", _guy];
sleep 3;
_guy switchmove "AmovPercMstpSlowWrflDnon_SaluteOut";
};
*/

#define pr private

CLASS("ActionUnitSalute", "Action")

	VARIABLE("target");
	VARIABLE("activationTime");
	VARIABLE("objectHandle");
	
	// ------------ N E W ------------
	// _target - whom to salute to
	
	METHOD("new") {
		params [P_THISOBJECT, P_OOP_OBJECT("_AI"), P_ARRAY("_parameters")];

		pr _target = CALLSM2("Action", "getParameterValue", _parameters, TAG_TARGET);
		T_SETV("target", _target);

		pr _agent = GETV(_AI, "agent"); // cache the object handle
		pr _hO = CALLM0(_agent, "getObjectHandle");
		T_SETV("objectHandle", _hO);
	} ENDMETHOD;
	
	METHOD("delete") {
	} ENDMETHOD;
	
	// logic to run when the goal is activated
	METHOD("activate") {
		params [P_THISOBJECT];
		
		// Handle AI just spawned state
		pr _AI = T_GETV("AI");

		T_SETV("activationTime", GAME_TIME);
		
		pr _oh = T_GETV("objectHandle");
		pr _target = T_GETV("target");
		_oh setDir (_oh getDir _target);
		_oh disableAI "MOVE";
		_oh action ["salute", _oh];
		_oh doWatch _target;
		
		diag_log "Started saluting!";
		
		T_SETV("state", ACTION_STATE_ACTIVE);
		
		
		// Create stimulus for other units
		/*
		// Create a salute stimulus
		private _stim = STIMULUS_NEW();
		STIMULUS_SET_TYPE(_stim, STIMULUS_TYPE_UNIT_SALUTE);
		STIMULUS_SET_SOURCE(_stim, _oh);
		STIMULUS_SET_POS(_stim, getPos _oh);
		STIMULUS_SET_RANGE(_stim, 20);
		//_stim set [STIMULUS_ID_EXPIRATION_TIME, 10];
		// Send the stimulus to the stimulus manager
		private _args = ["handleStimulus", [_stim]];
		CALLM(gStimulusManager, "postMethodAsync", _args);
		*/
		
		
		
		// Return ACTIVE state
		ACTION_STATE_ACTIVE
		
	} ENDMETHOD;
	
	// logic to run each update-step
	METHOD("process") {
		params [P_THISOBJECT];
		
		diag_log "salute process was called!";
		
		T_CALLM0("activateIfInactive");
		
		// If action is not active now, do nothing
		pr _state = T_GETV("state");
		if (_state != ACTION_STATE_ACTIVE) exitWith {_state};
		
		// Action is active
		
		// Check if we have been saluting for too long
		pr _atime = T_GETV("activationTime");
		if (GAME_TIME - _atime < 4) exitWith { ACTION_STATE_ACTIVE };
		
		// If time has expired, terminate
		diag_log "salute time expired!";
		T_CALLM("terminate", []);
		T_SETV("state", ACTION_STATE_COMPLETED);
		ACTION_STATE_COMPLETED
	} ENDMETHOD;
	
	// logic to run when the goal is satisfied
	METHOD("terminate") {
		params [P_THISOBJECT];
		
		diag_log "Terminating salute!";
		
		
		pr _oh = T_GETV("objectHandle");
		_oh enableAI "MOVE";
		
		// Stop the animations if the action is active
		pr _state = T_GETV("state");
		if (_state == ACTION_STATE_ACTIVE) then {
			_oh switchmove "AmovPercMstpSlowWrflDnon_SaluteOut";
			//_oh action ["salute", _oh];
			_oh lookAt objNull; // Stop looking at your target
			_oh doFollow (leader group _oh); // Regroup
			
			// Mark the world fact as irrelevant so that we don't salute again
			pr _query = WF_NEW();
			[_query, WF_TYPE_UNIT_SALUTED_BY] call wf_fnc_setType;
			pr _AI = T_GETV("AI");
			pr _wf = CALLM(_AI, "findWorldFact", [_query]);
			if (! (isNil "_wf")) then {
				[_wf, 0] call wf_fnc_setRelevance;
			};
		};
		
		//T_SETV("state", ACTION_STATE_INACTIVE);
	} ENDMETHOD;

ENDCLASS;