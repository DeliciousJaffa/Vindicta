OOP_Light_initialized = true;

#include "OOP_Light.h"

/*
 * This file contains some functions for OOP_Light, mainly for asserting classess, objects and members.
 * Author: Sparker
 * 02.06.2018
 * 
 * TODO: refactor the many assert functions for better performance.
*/

// Prints an error message with supplied text, file and line number
OOP_error = {
	params["_file", "_line", "_text"];
	#ifdef _SQF_VM
	// In testing we just throw the message so we can test against it
	throw _text;
	#else
	private _msg = format ["[OOP] Error: file: %1, line: %2, %3", _file, _line, _text];
	diag_log _msg;
	DUMP_CALLSTACK;
	#endif
	// Doesn't really work :/
	// try
	// {
	// 	throw [_file, _line, _msg];
	// }
	// catch
	// {
	// 	terminate _thisScript;
	// 	throw _exception;
	// }
};

// Print error when a member is not found
OOP_error_memberNotFound = {
	params ["_file", "_line", "_classNameStr", "_memNameStr"];
	private _errorText = format ["class '%1' has no member named '%2'", _classNameStr, _memNameStr];
	[_file, _line, _errorText] call OOP_error;
};

// Print error when a method is not found
OOP_error_methodNotFound = {
	params ["_file", "_line", "_classNameStr", "_methodNameStr"];
	private _errorText = format ["class '%1' has no method named '%2'", _classNameStr, _methodNameStr];
	[_file, _line, _errorText] call OOP_error;
};

//Print error when specified object is not an object
OOP_error_notObject = {
	params ["_file", "_line", "_objNameStr"];
	private _errorText = format ["'%1' is not an object (parent class not found)", _objNameStr];
	[_file, _line, _errorText] call OOP_error;
};

//Print error when specified class is not a class
OOP_error_notClass = {
	params ["_file", "_line", "_classNameStr"];
	private _errorText = "";
	if (isNil "_classNameStr") then {
		private _errorText = format ["class name is nil"];
		[_file, _line, _errorText] call OOP_error;
	} else {
		private _errorText = format ["class '%1' is not defined", _classNameStr];
		[_file, _line, _errorText] call OOP_error;
	};
};

//Print error when object's class is different from supplied class
OOP_error_wrongClass = {
	params ["_file", "_line", "_objNameStr", "_classNameStr", "_expectedClassNameStr"];
	private _errorText = format ["class of object %1 is %2, expected: %3", _objNameStr, _classNameStr, _expectedClassNameStr];
	[_file, _line, _errorText] call OOP_error;
};

//Check class and print error if it's not found
OOP_assert_class = {
	params["_classNameStr", "_file", "_line"];
	//Every class should have a member list. If it doesn't, then it's not a class
	private _memList = GET_SPECIAL_MEM(_classNameStr, STATIC_MEM_LIST_STR);
	//Check if it's a class
	if(isNil "_memList") then {
		[_file, _line, _classNameStr] call OOP_error_notClass;
		false;
	} else {
		true;
	};
};

//Check object class and print error if it differs from supplied
OOP_assert_objectClass = {
	params["_objNameStr", "_expectedClassNameStr", "_file", "_line"];

	if(!(_objNameStr isEqualType "")) exitWith {
		[_file, _line, _objNameStr] call OOP_error_notObject;
		false;
	};

	//Get object's class
	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	//Check if it's an object
	if(isNil "_classNameStr") then {
		[_file, _line, _objNameStr] call OOP_error_notObject;
		false;
	} else {
		private _parents = GET_SPECIAL_MEM(_classNameStr, PARENTS_STR);
		if (_expectedClassNameStr in _parents || _classNameStr == _expectedClassNameStr) then {
			true // all's fine
		} else {
			[_file, _line, _objNameStr, _classNameStr, _expectedClassNameStr] call OOP_error_wrongClass;
			false
		};
	};
};

//Check object and print error if it's not an OOP object
OOP_assert_object = {
	params["_objNameStr", "_file", "_line"];

	if(!(_objNameStr isEqualType "")) exitWith {
		[_file, _line, _objNameStr] call OOP_error_notObject;
		false;
	};

	//Get object's class
	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	//Check if it's an object
	if(isNil "_classNameStr") then {
		[_file, _line, _objNameStr] call OOP_error_notObject;
		false;
	} else {
		true;
	};
};

//Check static member and print error if it's not found
OOP_assert_staticMember = {
	params["_classNameStr", "_memNameStr", "_file", "_line"];
	//Get static member list of this class
	private _memList = GET_SPECIAL_MEM(_classNameStr, STATIC_MEM_LIST_STR);
	//Check if it's a class
	if(isNil "_memList") exitWith {
		[_file, _line, _classNameStr] call OOP_error_notClass;
		false;
	};
	//Check static member
	private _valid = (_memList findIf { _x#0 == _memNameStr }) != -1;
	if(!_valid) then {
		[_file, _line, _classNameStr, _memNameStr] call OOP_error_memberNotFound;
	};
	//Return value
	_valid
};

//Check member and print error if it's not found or is ref
OOP_assert_member = {
	params["_objNameStr", "_memNameStr", "_file", "_line"];
	//Get object's class
	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	//Check if it's an object
	if(isNil "_classNameStr") exitWith {
		private _errorText = format ["class name is nil. Attempt to access member: %1.%2", _objNameStr, _memNameStr];
		[_file, _line, _errorText] call OOP_error;
		false;
	};
	//Get member list of this class
	private _memList = GET_SPECIAL_MEM(_classNameStr, MEM_LIST_STR);
	//Check member
	private _memIdx = _memList findIf { _x#0 == _memNameStr };
	private _valid = _memIdx != -1;
	if(!_valid) then {
		[_file, _line, _classNameStr, _memNameStr] call OOP_error_memberNotFound;
	};
	//Return value
	_valid
};

OOP_static_member_has_attr = {
	params["_classNameStr", "_memNameStr", "_attr"];
	// NO asserting here, it should be done already before calling this
	// Get static  member list of this class
	private _memList = GET_SPECIAL_MEM(_classNameStr, STATIC_MEM_LIST_STR);
	// Get the member by name
	private _memIdx = _memList findIf { _x#0 == _memNameStr };
	// Return existance of attr
	private _allAttr = (_memList select _memIdx)#1;
	(_attr in _allAttr)
};

OOP_member_has_attr = {
	params["_objNameStr", "_memNameStr", "_attr"];
	// NO asserting here, it should be done already before calling this
	// Get object's class
	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	// Get member list of this class
	private _memList = GET_SPECIAL_MEM(_classNameStr, MEM_LIST_STR);
	// Get the member by name
	private _memIdx = _memList findIf { _x#0 == _memNameStr };
	// Return existance of attr
	private _allAttr = (_memList select _memIdx)#1;
	(_attr in _allAttr)
};

// Get an extended attribute for a static variable (one that contains values)
OOP_static_member_get_attr_ex = {
	params["_classNameStr", "_memNameStr", "_attr"];
	// NO asserting here, it should be done already before calling this
	// Get static  member list of this class
	private _memList = GET_SPECIAL_MEM(_classNameStr, STATIC_MEM_LIST_STR);
	// Get the member by name
	private _memIdx = _memList findIf { _x#0 == _memNameStr };
	if(_memIdx == -1) then {
		diag_log format["OOP_static_member_get_attr_ex: _this = %1, _memList = %2", _this, _memList];
	};
	// Return existance of attr
	private _allAttr = (_memList select _memIdx)#1;
	private _idx = _allAttr findIf { _x isEqualType [] and {_x#0 == _attr} };
	if(_idx == NOT_FOUND) then {
		false
	} else {
		_allAttr select _idx
	}
};

// Get an extended attribute (one that contains values)
OOP_member_get_attr_ex = {
	params["_objNameStr", "_memNameStr", "_attr"];
	// NO asserting here, it should be done already before calling this
	// Get object's class
	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	// Get member list of this class
	private _memList = GET_SPECIAL_MEM(_classNameStr, MEM_LIST_STR);
	// Get the member by name
	private _memIdx = _memList findIf { _x#0 == _memNameStr };
	// Return existance of attr
	private _allAttr = (_memList select _memIdx)#1;

	private _idx = _allAttr findIf { _x isEqualType [] and {_x#0 == _attr} };
	if(_idx == NOT_FOUND) then {
		false
	} else {
		_allAttr#_idx
	}
};

// Check member is ref and print error if it's not
OOP_assert_member_is_ref = {
	params["_objNameStr", "_memNameStr", "_file", "_line"];
	private _valid = [_objNameStr, _memNameStr, _file, _line] call OOP_assert_member;
	if(!_valid) exitWith { false };
	if(!([_objNameStr, _memNameStr, ATTR_REFCOUNTED] call OOP_member_has_attr)) exitWith {
		private _errorText = format ["%1.%2 doesn't have ATTR_REFCOUNTED attribute but is being accessed by a REF function.", _objNameStr, _memNameStr];
		[_file, _line, _errorText] call OOP_error;
		false;
	};
	true;
};

// Check member is not a ref and print error if it is
OOP_assert_member_is_not_ref = {
	params["_objNameStr", "_memNameStr", "_file", "_line"];
	private _valid = [_objNameStr, _memNameStr, _file, _line] call OOP_assert_member;
	if(!_valid) exitWith { false };
	if(([_objNameStr, _memNameStr, ATTR_REFCOUNTED] call OOP_member_has_attr)) exitWith {
		private _errorText = format ["%1.%2 has ATTR_REFCOUNTED attribute but is being accessed via a non REF function.", _objNameStr, _memNameStr];
		[_file, _line, _errorText] call OOP_error;
		false;
	};
	true;
};

// #define DEBUG_OOP_ASSERT_FUNCS

OOP_are_in_same_class_heirarchy = {
	params ["_classNameStr"];
	// If we aren't in a class member function at all
	if(isNil "_thisClass") exitWith { false	};
	// If we are in the same class
	if(_thisClass isEqualTo _classNameStr) exitWith { true };
	// If we are in a descendant class
	_classNameStr in GET_SPECIAL_MEM(_thisClass, PARENTS_STR)
};

OOP_assert_class_member_access = {
	params ["_classNameStr", "_memNameStr", "_isGet", "_isPrivate", "_isGetOnly", "_file", "_line"];

	#ifdef DEBUG_OOP_ASSERT_FUNCS
	diag_log format ["_classNameStr = %1, _memNameStr = %2, _isGet = %3, _isPrivate = %4, _isGetOnly = %5, _thisClass = %6", 
		_classNameStr, _memNameStr, _isGet, _isPrivate, _isGetOnly,
		if(!isNil "_thisClass") then { _thisClass } else { nil }
	];
	#endif
	// If it isn't private or get only then we are fine
	if(!_isPrivate and !_isGetOnly) exitWith { 
		#ifdef DEBUG_OOP_ASSERT_FUNCS
		diag_log "OK: !_isPrivate";
		#endif
		true 
	};
	// If it is both private and get-only then it is a declaration error, these are mutually exclusive
	if(_isPrivate and _isGetOnly) exitWith {
		private _errorText = format ["%1.%2 is marked private AND get-only, but they are intended to be mutually exclusive (get-only implies private set and public get)", _classNameStr, _memNameStr];
		[_file, _line, _errorText] call OOP_error;
		false
	};

	// Private and get only rules:
	// Private is violated if access is outside of the class heirarchy that owns the variable regardless always
	// Get-only is violated if set access is outside of the class heirarchy always

	private _inSameHeirarchy = [_classNameStr] call OOP_are_in_same_class_heirarchy;
	// If we are in the same class heirarchy then private and get-only are fine
	if(_inSameHeirarchy) exitWith { true };
	// At this point we know we are accessing from outside the class heirarchy
	// Check we aren't attempting to set a get-only variable
	if(!_isGet and _isGetOnly) exitWith {
		private _errorText = format ["%1.%2 is get-only outside of its own class heirarchy", _classNameStr, _memNameStr];
		[_file, _line, _errorText] call OOP_error;
		false
	};
	// If the variable isn't private then we are fine.
	if(!_isPrivate) exitWith { true };

	// // If it is not private, and is get only and we aren't 

	// // If the class we access from is the same as the one that owns the member then we are fine regardless
	// if(!isNil "_thisClass" and {_thisClass isEqualTo _classNameStr}) exitWith { 
	// 	#ifdef DEBUG_OOP_ASSERT_FUNCS
	// 	diag_log "OK: _thisClass isEqualTo _classNameStr";
	// 	#endif
	// 	true
	// };

	// // If we aren't in a class function at all then private would by violated.
	// if(_isPrivate and {isNil "_thisClass"}) exitWith {
	// 	private _errorText = format ["%1.%2 is unreachable (private)", _classNameStr, _memNameStr];
	// 	[_file, _line, _errorText] call OOP_error;
	// 	false
	// };

	// // Check if the object we are accessing is a parent of the class we are in (this is fine)
	// // We could also allow access of members in derived classes but this is likely a design flaw anyway.
	// // This code would allow it:
	// // 	or {_thisClass in GET_SPECIAL_MEM(_classNameStr, PARENTS_STR)}
	// if(_classNameStr in GET_SPECIAL_MEM(_thisClass, PARENTS_STR)) exitWith {
	// 	#ifdef DEBUG_OOP_ASSERT_FUNCS
	// 	diag_log "OK: _classNameStr in GET_SPECIAL_MEM(_thisClass, PARENTS_STR)";
	// 	#endif
	// 	true 
	// };
	private _errorText = format ["%1.%2 is unreachable (private)", _classNameStr, _memNameStr];
	[_file, _line, _errorText] call OOP_error;
	false
};

OOP_assert_is_in_required_thread = {
	params ["_objOrClass", "_classNameStr", "_memNameStr", "_threadAffinityFn", "_file", "_line"];
	private _requiredThread = [_objOrClass] call _threadAffinityFn;
	if(!isNil "_thisScript" and !isNil "_requiredThread" and  {!(_requiredThread isEqualTo _thisScript)}) exitWith {
		private _errorText = format ["%1.%2 is accessed from the wrong thread, expected '%3' got '%4'", _classNameStr, _memNameStr, _requiredThread, _thisScript];
		[_file, _line, _errorText] call OOP_error;
		false
	};
	true
};

OOP_assert_static_member_access = {
	params ["_classNameStr", "_memNameStr", "_isGet", "_file", "_line"];
	
#ifndef _SQF_VM
	private _threadAffinity = [_classNameStr, _memNameStr, ATTR_THREAD_AFFINITY_ID] call OOP_static_member_get_attr_ex;
	if((_threadAffinity isEqualType []) and {!([_classNameStr, _classNameStr, _memNameStr, _threadAffinity#1, _file, _line] call OOP_assert_is_in_required_thread)}) exitWith {
		false
	};
#endif
	private _isPrivate = [_classNameStr, _memNameStr, ATTR_PRIVATE] call OOP_static_member_has_attr;
	private _isGetOnly = [_classNameStr, _memNameStr, ATTR_GET_ONLY] call OOP_static_member_has_attr;
	[_classNameStr, _memNameStr, _isGet, _isPrivate, _isGetOnly, _file, _line] call OOP_assert_class_member_access;
};

OOP_assert_get_static_member_access = { 
	params ["_classNameStr", "_memNameStr", "_file", "_line"];
	[_classNameStr, _memNameStr, true, _file, _line] call OOP_assert_static_member_access; 
};
OOP_assert_set_static_member_access = { 
	params ["_classNameStr", "_memNameStr", "_file", "_line"];
	
	//private _isGetOnly = [_classNameStr, _memNameStr, ATTR_GET_ONLY] call OOP_static_member_has_attr;
	//if(_isGetOnly) exitWith { false };
	[_classNameStr, _memNameStr, false, _file, _line] call OOP_assert_static_member_access;
};

OOP_assert_member_access = {
	params ["_objNameStr", "_memNameStr", "_isGet", "_file", "_line"];

	#ifdef DEBUG_OOP_ASSERT_FUNCS
	diag_log format ["OOP_assert_member_access: _objNameStr = %1, _memNameStr = %2, _isGet = %3, _thisObject = %4, _thisClass = %5", 
		_objNameStr, _memNameStr, _isGet,
		if(!isNil "_thisObject") then { _thisObject } else { nil },
		if(!isNil "_thisClass") then { _thisClass } else { nil }
	];
	#endif

	// EARLY OUT: If we are accessing from within the same object we have no access restrictions
	if (!isNil "_thisObject" and {_thisObject isEqualTo _objNameStr}) exitWith { true };

	private _isPrivate = [_objNameStr, _memNameStr, ATTR_PRIVATE] call OOP_member_has_attr;
	private _isGetOnly = [_objNameStr, _memNameStr, ATTR_GET_ONLY] call OOP_member_has_attr;

	// Get the class of the object that owns the member
	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
#ifndef _SQF_VM
	private _threadAffinity = [_objNameStr, _memNameStr, ATTR_THREAD_AFFINITY_ID] call OOP_member_get_attr_ex;
	if((_threadAffinity isEqualType []) and {!([_objNameStr, _classNameStr, _memNameStr, _threadAffinity#1, _file, _line] call OOP_assert_is_in_required_thread)}) exitWith {
		false
	};
#endif
	private _thisClass = if(!isNil "_thisClass") then { 
			_thisClass
		} else {
			if (!isNil "_thisObject") then { 
				OBJECT_PARENT_CLASS_STR(_thisObject) 
			} else {
				nil
			}
		};
	[_classNameStr, _memNameStr, _isGet, _isPrivate, _isGetOnly, _file, _line] call OOP_assert_class_member_access;
};

OOP_assert_get_member_access = {
	params ["_objNameStr", "_memNameStr", "_file", "_line"];
	[_objNameStr, _memNameStr, true, _file, _line] call OOP_assert_member_access; 
};
OOP_assert_set_member_access = { 
	params ["_objNameStr", "_memNameStr", "_file", "_line"];
	[_objNameStr, _memNameStr, false, _file, _line] call OOP_assert_member_access;
};


//Check method and print error if it's not found
OOP_assert_method = {
	params["_classNameStr", "_methodNameStr", "_file", "_line"];

	if (isNil "_classNameStr") exitWith {
		private _errorText = format ["class name is nil. Attempt to call method: %1", _methodNameStr];
		[_file, _line, _errorText] call OOP_error;
		false;
	};

	//Get static member list of this class
	private _methodList = GET_SPECIAL_MEM(_classNameStr, METHOD_LIST_STR);
	//Check if it's a class
	if(isNil "_methodList") exitWith {
		[_file, _line, _classNameStr] call OOP_error_notClass;
		false;
	};
	//Check method
	private _valid = _methodNameStr in _methodList;
	if(!_valid) then {
		[_file, _line, _classNameStr, _methodNameStr] call OOP_error_methodNotFound;
	};
	//Return value
	_valid
};

// Dumps all variables of an object
OOP_dumpAllVariables = {
	params [["_thisObject", "", [""]]];
	// Get object's class
	private _classNameStr = OBJECT_PARENT_CLASS_STR(_thisObject);
	//Get member list of this class
	private _memList = GET_SPECIAL_MEM(_classNameStr, MEM_LIST_STR);
	diag_log format ["DEBUG: Dumping all variables of %1: %2", _thisObject, _memList];
	{
		_x params ["_memName", "_memAttr"];
		private _varValue = GETV(_thisObject, _memName);
		if (isNil "_varValue") then {
			diag_log format ["DEBUG: %1.%2: %3", _thisObject, _memName, "<null>"];
		} else {
			diag_log format ["DEBUG: %1.%2: %3", _thisObject, _memName, _varValue];
		};
	} forEach _memList;
};


// ---- Remote execution ----
// A remote code wants to execute something on this machine
// However remote machine doesn't have to know what class the object belongs to
// So we must find out object's class on this machine and then run the method
OOP_callFromRemote = {
	params[["_object", "", [""]], ["_methodNameStr", "", [""]], ["_params", [], [[]]]];
	//diag_log format [" --- OOP_callFromRemote: %1", _this];
	CALLM(_object, _methodNameStr, _params);
};

// If assertion is enabled, this gets called on remote machine when we call a static method on it
// So it will run the standard assertions before calling static method
OOP_callStaticMethodFromRemote = {
	params [["_classNameStr", "", [""]], ["_methodNameStr", "", [""]], ["_args", [], [[]]]];
	CALL_STATIC_METHOD(_classNameStr, _methodNameStr, _args);
};

// Create new object from class name and parameters
OOP_new = {
	params ["_classNameStr", "_extraParams"];

	CONSTRUCTOR_ASSERT_CLASS(_classNameStr);

	private _oop_nextID = -1;
	_oop_nul = isNil {
		_oop_nextID = GET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR);
		if (isNil "_oop_nextID") then { 
			SET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR, 0);	_oop_nextID = 0;
		};
		SET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR, _oop_nextID+1);
	};
	
	private _objNameStr = OBJECT_NAME_STR(_classNameStr, _oop_nextID);

	FORCE_SET_MEM(_objNameStr, OOP_PARENT_STR, _classNameStr);
	private _oop_parents = GET_SPECIAL_MEM(_classNameStr, PARENTS_STR);
	private _oop_i = 0;
	private _oop_parentCount = count _oop_parents;

	while { _oop_i < _oop_parentCount } do {
		([_objNameStr] + _extraParams) call GET_METHOD((_oop_parents select _oop_i), "new");
		_oop_i = _oop_i + 1;
	};
	CALL_METHOD(_objNameStr, "new", _extraParams);

	PROFILER_COUNTER_INC(_classNameStr);

	_objNameStr
};

// Create new public object from class name and parameters
OOP_new_public = {
	params ["_classNameStr", "_extraParams"];

	CONSTRUCTOR_ASSERT_CLASS(_classNameStr);

	private _oop_nextID = -1;
	_oop_nul = isNil {
		_oop_nextID = GET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR);
		if (isNil "_oop_nextID") then { 
			SET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR, 0); _oop_nextID = 0;
		};
		SET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR, _oop_nextID+1);
	};
	private _objNameStr = OBJECT_NAME_STR(_classNameStr, _oop_nextID);
	FORCE_SET_MEM(_objNameStr, OOP_PARENT_STR, _classNameStr);
	PUBLIC_VAR(_objNameStr, OOP_PARENT_STR);
	FORCE_SET_MEM(_objNameStr, OOP_PUBLIC_STR, 1);
	PUBLIC_VAR(_objNameStr, OOP_PUBLIC_STR);
	private _oop_parents = GET_SPECIAL_MEM(_classNameStr, PARENTS_STR);
	private _oop_i = 0;
	private _oop_parentCount = count _oop_parents;
	while {_oop_i < _oop_parentCount} do {
		([_objNameStr] + _extraParams) call GET_METHOD((_oop_parents select _oop_i), "new");
		_oop_i = _oop_i + 1;
	};
	CALL_METHOD(_objNameStr, "new", _extraParams);

	PROFILER_COUNTER_INC(_classNameStr);

	_objNameStr
};

// Create a copy of an object
OOP_clone = {
	params ["_objNameStr"];

	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	CONSTRUCTOR_ASSERT_CLASS(_classNameStr);

	// Get new ID for the new object
	private _oop_nextID = -1;
	_oop_nul = isNil {
		_oop_nextID = GET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR);
		if (isNil "_oop_nextID") then { 
			SET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR, 0); _oop_nextID = 0;
		};
		SET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR, _oop_nextID+1);
	};

	private _newObjNameStr = OBJECT_NAME_STR(_classNameStr, _oop_nextID);

	FORCE_SET_MEM(_newObjNameStr, OOP_PARENT_STR, _classNameStr);
	
	CALL_METHOD(_newObjNameStr, "copy", [_objNameStr]);

	PROFILER_COUNTER_INC(_classNameStr);

	_newObjNameStr
};

// Default copy, this is what you get if you don't overwrite "copy" method of your class
OOP_clone_default = {
	params ["_thisObject", "_srcObject"];
	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	private _memList = GET_SPECIAL_MEM(_classNameStr, MEM_LIST_STR);
	{
		_x params ["_varName"]; //, "_attributes"]; don't need attributes for now
		private _value = FORCE_GET_MEM(_srcObject, _varName);
		if (!isNil "_value") then {
			// Check if it's an array, array is special, it needs a deeeep copy
			if (_value isEqualType []) then {
				FORCE_SET_MEM(_thisObject, _varName, +_value);
			} else {
				FORCE_SET_MEM(_thisObject, _varName, _value);
			};
		};
	} forEach _memList;

	PROFILER_COUNTER_INC(_classNameStr);
};

// Default assignment, this is what you get if you don't overwrite "assign" method of your class
// It just iterates through all variables and copies their values
// This method assumes the same classes of the two objects
OOP_assign_default = {
	params ["_destObject", "_srcObject", ["_copyNil", true], '_attrRequired'];

	private _destClassNameStr = OBJECT_PARENT_CLASS_STR(_destObject);
	private _srcClassNameStr = OBJECT_PARENT_CLASS_STR(_srcObject);

	// Ensure destination and source are of the same classes
	#ifdef OOP_ASSERT
	if (_destClassNameStr != _srcClassNameStr) exitWith {
		[__FILE__, __LINE__, format ["destination and source classes don't match for objects %1 and %2", _destObject, _srcObject]] call OOP_error;
	};
	#endif

	// Get member list and copy everything
	private _memList = GET_SPECIAL_MEM(_destClassNameStr, MEM_LIST_STR);
	if(!isNil "_attrRequired") then {
		_memList = _memList select {
			_x params ["_varName", "_attributes"];
			_attrRequired in _attributes
		};
	};

	{
		_x params ["_varName"]; //, "_attributes"];
		private _value = FORCE_GET_MEM(_srcObject, _varName);
		if (!isNil "_value") then {
			// Check if it's an array, array is special, it needs a deeeep copy
			if (_value isEqualType []) then {
				FORCE_SET_MEM(_destObject, _varName, +_value);
			} else {
				FORCE_SET_MEM(_destObject, _varName, _value);
			};
		} else {
			if (_copyNil) then {
				FORCE_SET_MEM(_destObject, _varName, nil);
			};
		};
	} forEach _memList;
};

// Pack all variables into an array
OOP_serialize = {
	params ["_objNameStr"];

	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	private _memList = GET_SPECIAL_MEM(_classNameStr, MEM_LIST_STR);

	// Select only members that are serializable
	// Todo: increase speed of this by precalculating it in CLASS macro!
	_memList = _memList select {
		_x params ["_varName", "_attributes"];
		ATTR_SERIALIZABLE in _attributes
	};

	private _array = [];
	_array pushBack _classNameStr;
	_array pushBack _objNameStr;

	{
		_x params ["_varName"];
		_array append [GETV(_objNameStr, _varName)];
	} forEach _memList;

	_array
};

// Unpack all variables from an array into an existing object
OOP_deserialize = {
	params ["_objNameStr", "_array"];

	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);

	#ifdef OOP_ASSERT
	if (! ([_objNameStr, __FILE__, __LINE__] call OOP_assert_object)) exitWith {};
	#endif

	private _memList = GET_SPECIAL_MEM(_classNameStr, MEM_LIST_STR);
	private _iVarName = 0;

	// Select only members that are serializable
	private _copyMemList = _memList select {
		_x params ["_varName", "_attributes"];
		ATTR_SERIALIZABLE in _attributes
	};

	for "_i" from 2 to ((count _array) - 1) do {
		private _value = _array select _i;
		(_copyMemList select _iVarName) params ["_varName"];
		SET_VAR(_objNameStr, _varName, _value);
		_iVarName = _iVarName + 1;
	};
};

OOP_deref_var = {
	params ["_objNameStr", "_memName", "_memAttr"];
	if(ATTR_REFCOUNTED in _memAttr) then {
		private _memObj = FORCE_GET_MEM(_objNameStr, _memName);
		switch(typeName _memObj) do {
			case "STRING": {
				CALLM0(_memObj, "unref");
			};
			// Lets not use this, it is a bit ambiguous as automatic ref counting in arrays can only
			// ever be partial, unless we make a whole suite of functions to replace all normal array 
			// mutation functions with ref safe ones. That isn't unthinkable, but not done as of yet.
			// case "ARRAY": {
			// 	{
			// 		CALLM0(_x, "unref");
			// 	} forEach _memObj;
			// };
		};
	};
};

// Delete object
OOP_delete = {
	params ["_objNameStr"];

	DESTRUCTOR_ASSERT_OBJECT(_objNameStr);

	private _oop_classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	private _oop_parents = GET_SPECIAL_MEM(_oop_classNameStr, PARENTS_STR);
	private _oop_parentCount = count _oop_parents;
	private _oop_i = _oop_parentCount - 1;

	CALL_METHOD(_objNameStr, "delete", []);
	while {_oop_i > -1} do {
		[_objNameStr] call GET_METHOD((_oop_parents select _oop_i), "delete");
		_oop_i = _oop_i - 1;
	};

	private _isPublic = IS_PUBLIC(_objNameStr);
	private _oop_memList = GET_SPECIAL_MEM(_oop_classNameStr, MEM_LIST_STR);
	
	if (_isPublic) then {
		{
			// If the var is REFCOUNTED then unref it
			_x params ["_memName", "_memAttr"];
			[_objNameStr, _memName, _memAttr] call OOP_deref_var;
			FORCE_SET_MEM(_objNameStr, _memName, nil);
			PUBLIC_VAR(_objNameStr, OOP_PARENT_STR);
		} forEach _oop_memList;
	} else {
		{
			// If the var is REFCOUNTED then unref it
			_x params ["_memName", "_memAttr"];
			[_objNameStr, _memName, _memAttr] call OOP_deref_var;
			FORCE_SET_MEM(_objNameStr, _memName, nil);
		} forEach _oop_memList;
	};

	PROFILER_COUNTER_DEC(_oop_classNameStr);
};

// Base class for intrusive ref counting.
// Use the REF and UNREF macros with objects of classes 
// derived from this one.
// Use variable attributes to enable automated ref counting for object refs:
// VARIABLE_ATTR(..., [ATTR_REFCOUNTED]);
// Use the SET_VAR_REF, SETV_REF, T_SETV_REF family of functions to write to 
// these members to get automated de-refing of replaced value, and refing of
// new value. See RefCountedTest.sqf for example.
CLASS("RefCounted", "")
	VARIABLE("refCount");

	METHOD("new") {
		params [P_THISOBJECT];
		// Start at ref count zero. When the object gets assigned to a VARIABLE
		// using T_SETV_REF it will be automatically reffed.
		T_SETV("refCount", 0);
	} ENDMETHOD;

	METHOD("ref") {
		params [P_THISOBJECT];
		CRITICAL_SECTION {
			T_PRVAR(refCount);
			_refCount = _refCount + 1;
			//OOP_DEBUG_2("%1 refed to %2", _thisObject, _refCount);
			T_SETV("refCount", _refCount);
		};
	} ENDMETHOD;

	METHOD("unref") {
		params [P_THISOBJECT];
		CRITICAL_SECTION {
			T_PRVAR(refCount);
			_refCount = _refCount - 1;
			//OOP_DEBUG_2("%1 unrefed to %2", _thisObject, _refCount);
			if(_refCount == 0) then {
				//OOP_DEBUG_1("%1 being deleted", _thisObject);
				DELETE(_thisObject);
			} else {
				T_SETV("refCount", _refCount);
			};
		};
	} ENDMETHOD;
ENDCLASS;

#ifdef _SQF_VM

CLASS("AttrTestBase1", "")
	VARIABLE("var_default");
	VARIABLE_ATTR("var_private", [ATTR_PRIVATE]);
	VARIABLE_ATTR("var_get_only", [ATTR_GET_ONLY]);

	METHOD("new") {
		params [P_THISOBJECT];
		T_SETV("var_default", true);
		T_SETV("var_private", true);
		T_SETV("var_get_only", true);
	} ENDMETHOD;

	METHOD("validDefaultAccessTest") {
		params [P_THISOBJECT];
		T_SETV("var_default", true);
		T_GETV("var_default")
	} ENDMETHOD;
	
	METHOD("validPrivateAccessTest") {
		params [P_THISOBJECT];
		T_SETV("var_private", true);
		T_GETV("var_private")
	} ENDMETHOD;
		
	METHOD("validGetOnlyAccessTest") {
		params [P_THISOBJECT];
		T_SETV("var_get_only", true);
		T_GETV("var_get_only")
	} ENDMETHOD;

	STATIC_METHOD("validStaticPrivateAccessTest") {
		params [P_THISCLASS, P_STRING("_obj")];
		GETV(_obj, "var_private")
	} ENDMETHOD;
	
ENDCLASS;

CLASS("AttrTestDerived1", "AttrTestBase1")
	METHOD("new") {
		params [P_THISOBJECT];
		
	} ENDMETHOD;
	
	METHOD("validDerviedDefaultAccessTest") {
		params [P_THISOBJECT, P_STRING("_base")];
		SETV(_base, "var_default", true);
		GETV(_base, "var_default")
	} ENDMETHOD;
	
	METHOD("validDerviedPrivateAccessTest") {
		params [P_THISOBJECT, P_STRING("_base")];
		SETV(_base, "var_private", true);
		GETV(_base, "var_private")
	} ENDMETHOD;
		
	METHOD("validDerviedGetOnlyAccessTest") {
		params [P_THISOBJECT, P_STRING("_base")];
		SETV(_base, "var_get_only", true);
		GETV(_base, "var_get_only")
	} ENDMETHOD;
ENDCLASS;

CLASS("AttrTestNotDerived1", "")
	METHOD("new") {
		params [P_THISOBJECT];
	} ENDMETHOD;
	
	METHOD("validNonDerivedDefaultAccessTest") {
		params [P_THISOBJECT, P_STRING("_base")];
		SETV(_base, "var_default", true);
		GETV(_base, "var_default")
	} ENDMETHOD;
	
	METHOD("invalidNonDerivedPrivateAccessTest") {
		params [P_THISOBJECT, P_STRING("_base")];
		SETV(_base, "var_private", true);
		GETV(_base, "var_private")
	} ENDMETHOD;
		
	METHOD("validNonDerivedGetOnlyAccessTest") {
		params [P_THISOBJECT, P_STRING("_base")];
		GETV(_base, "var_get_only")
	} ENDMETHOD;

	METHOD("invalidNonDerivedGetOnlyAccessTest") {
		params [P_THISOBJECT, P_STRING("_base")];
		SETV(_base, "var_get_only", true)
	} ENDMETHOD;
ENDCLASS;

["OOP variable attributes", {
	private _base = NEW("AttrTestBase1", []);

	["valid default access", { CALLM(_base, "validDefaultAccessTest", []) }] call test_Assert;
	["valid private access", { CALLM(_base, "validPrivateAccessTest", []) }] call test_Assert;
	["valid get only access", { CALLM(_base, "validGetOnlyAccessTest", []) }] call test_Assert;
	["valid static private access", { CALLSM("AttrTestBase1", "validStaticPrivateAccessTest", [_base]) }] call test_Assert;	

	["valid external get only access", { GETV(_base, "var_get_only"); true }] call test_Assert;
	["invalid external private access",
		{ GETV(_base, "var_private") },
		"AttrTestBase1.var_private is unreachable (private)"
	] call test_Assert_Throws;
	["invalid external get only access",
		{ SETV(_base, "var_get_only", true) },
		"AttrTestBase1.var_get_only is get-only outside of its own class heirarchy"
	] call test_Assert_Throws;

	private _derived = NEW("AttrTestDerived1", []);
	["valid derived default access", { CALLM(_derived, "validDerviedDefaultAccessTest", [_base]) }] call test_Assert;
	["valid derived private access", { CALLM(_derived, "validDerviedPrivateAccessTest", [_base]) }] call test_Assert;
	["valid derived get only access", { CALLM(_derived, "validDerviedGetOnlyAccessTest", [_base]) }] call test_Assert;

	private _nonDerived = NEW("AttrTestNotDerived1", []);
	["valid non-derived default access", { CALLM(_nonDerived, "validNonDerivedDefaultAccessTest", [_base]) }] call test_Assert;
	["invalid non-derived private access",
		{ CALLM(_nonDerived, "invalidNonDerivedPrivateAccessTest", [_base]) },
		"AttrTestBase1.var_private is unreachable (private)"
	] call test_Assert_Throws;
	["valid non-derived get only access", { CALLM(_nonDerived, "validNonDerivedGetOnlyAccessTest", [_base]) }] call test_Assert;
	["invalid non-derived get only access",
		{ CALLM(_nonDerived, "invalidNonDerivedGetOnlyAccessTest", [_base]) },
		"AttrTestBase1.var_get_only is get-only outside of its own class heirarchy"
	] call test_Assert_Throws;

}] call test_AddTest;

#endif