/*
Must be defined in description.ext with

//----------------------INIT EVENTHANDLERS--------------------------
class Extended_Init_EventHandlers {
    class CAManBase {
        init = "_this call (compile preprocessFileLineNumbers 'unitInits.sqf')";
    };
};
---------------------------------------------------------------------------- */




params [["_unit",objNull]];

//Intel script
if (side _unit in [EAST,WEST,INDEPENDENT]) then {
    [_unit] call INCON_fnc_spawnIntelObjects;
};
