#include "script_component.hpp"
/*
 * Author: nkenny
 * Actualises assault cycle
 *
 * Arguments:
 * 0: cycles <NUMBER>
 * 1: units list <ARRAY>
 * 2: list of building/enemy positions <ARRAY>
 *
 * Return Value:
 * bool
 *
 * Example:
 * [units bob] call lambs_main_fnc_doGroupAssault;
 *
 * Public: No
*/
params ["_cycle", "_units", "_pos"];

// update
_units = _units select {_x call FUNC(isAlive) && {!isPlayer _x} && {!fleeing _x}};
if (_units isEqualTo [] || {_pos isEqualTo []}) exitWith {
    // early reset
    {
        _x setVariable [QEGVAR(danger,forceMove), nil];
        _x doFollow (leader _x);
        _x forceSpeed -1;
    } forEach _units;
    false
};

// get targetPos
private _targetPos = _pos select 0;

// reorder positions
_pos = _pos apply {[_targetPos isEqualTo (round (_x select 2)), _targetPos distanceSqr _x, _x]};
_pos sort true;
_pos = _pos apply {_x select 2};

{
    // get unit
    private _unit = _x;
    private _assaultPos = _targetPos;
    if (((_forEachIndex % 4) isEqualTo 0) && {count _pos > 1}) then {_assaultPos = _pos select 1};

    // manoeuvre
    _unit forceSpeed 3;
    _unit setUnitPos (["UP", "MIDDLE"] select ((getSuppression _x) isNotEqualTo 0 || {_unit distance2D _assaultPos > 8}));
    _unit setVariable [QGVAR(currentTask), format ["Group Assault @ %1m", round (_unit distance _assaultPos)], GVAR(debug_functions)];
    _unit setVariable [QEGVAR(danger,forceMove), true];

    // modify movement (if far)
    if (_unit distanceSqr _assaultPos > 400 && {!([_unit] call FUNC(isIndoor))}) then {
        _assaultPos = _unit getPos [20, _unit getDir _assaultPos];
    };
    // set movement
    if (((expectedDestination _unit) select 0) distanceSqr _assaultPos > 1) then {
        _unit doMove _assaultPos;
        _unit setDestination [_assaultPos, "LEADER PLANNED", true];
    };

    // remove positions
    _pos = _pos select {[objNull, "VIEW", objNull] checkVisibility [eyePos _unit, (AGLToASL _x) vectorAdd [0, 0, 0.5]] < 0.01};

} forEach (_units select {!((getUnitState _x) in ["PLANNING", "BUSY"])});

// update group variable
(group (_units select 0)) setVariable [QGVAR(groupMemory), _pos, false];

// remove  positions
_pos = _pos select {(_units select 0) distance _x > 3};
if (RND(0.95)) then {_pos deleteAt 0;};

// recursive cyclic
if !(_cycle <= 1 || {_units isEqualTo []}) then {
    [
        {_this call FUNC(doGroupAssault)},
        [_cycle - 1, _units, _pos],
        4
    ] call CBA_fnc_waitAndExecute;
};

// end
true
