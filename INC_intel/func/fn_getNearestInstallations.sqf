/*

Get Nearest Installations

Author: Spyderblack723

Gets a list of nearby installations up to the specified maximum.

*/





private ["_opcom"];

params ["_pos","_faction","_maxInstallations"];

if (isnil "OPCOM_instances") exitWith {[]};

{
    if (_faction in ([_x,"factions"] call ALiVE_fnc_hashGet)) exitWith {
        _opcom = _x;
    };
} foreach OPCOM_instances;

if (isnil "_opcom") exitWith {[]};

private _objectives = [_opcom,"objectives"] call ALiVE_fnc_hashGet;
private _sortedObjectives = [_objectives, [_pos], {([_x,"center"] call ALiVE_fnc_hashGet) distance2D _input0},"ASCEND"] call ALiVE_fnc_SortBy;

private _installations = [];

{
    _objective = _x;
    _objectiveFactory = [_opcom,"convertObject",[_objective,"factory"] call ALiVE_fnc_HashGet] call ALiVE_fnc_OPCOM;
    _objectiveDepot = [_opcom,"convertObject",[_objective,"depot"] call ALiVE_fnc_HashGet] call ALiVE_fnc_OPCOM;
    _objectiveRoadblocks = [_opcom,"convertObject",[_objective,"roadblocks"] call ALiVE_fnc_HashGet] call ALiVE_fnc_OPCOM;
    _objectiveHQ = [_opcom,"convertObject",[_objective,"HQ"] call ALiVE_fnc_HashGet] call ALiVE_fnc_OPCOM;

    {
        if ((count _installations < _maxInstallations) && {!(_x isEqualTo [])}) then {
            _installations pushback _x;
        };
    } foreach [_objectiveFactory,_objectiveDepot,_objectiveRoadblocks,_objectiveHQ];

    if (count _installations >= _maxInstallations) exitWith {};
} foreach _sortedObjectives;

_installations
