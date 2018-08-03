/*
Must be defined in description.ext with

//----------------------INIT EVENTHANDLERS--------------------------
class Extended_InitPost_EventHandlers {
     class CAManBase {
		init = "_this call (compile preprocessFileLineNumbers 'postInitXEH.sqf')";
	};
};
---------------------------------------------------------------------------- */

params ["_unit"];

//Intel script
_unit call INCON_fnc_spawnIntelObjects;
