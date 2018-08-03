/* ----------------------------------------------------------------------------
This function will add a killed eventhandler with a chance to spawn three tiers of intel objects near dead bodies of group leaders.

Authors: Incontinentia with massive help from the legends dixon13 and SpyderBlack723

USAGE

Parameters:
Unit: (Unit). Run eventhandlers on these units.
Asym side (optional): (Side). state which side is Asym. All the rest will be considered conventional. (ALiVE only - leave empty if not using alive)
Asym faction (optional): set the faction of asym units for opcom installation detection. (ALiVE only - leave empty if not using alive)

To work with Zeus, ALiVE, MCC (and anything else that spawns AI during a mission), calling file must be defined in description.ext with
//----------------------INIT EVENTHANDLERS--------------------------
class Extended_Init_EventHandlers {
     class CAManBase {
		init = "_this call (compile preprocessFileLineNumbers 'callingScript.sqf')";
	};
};



EXAMPLES

//Intel objects on all East and Ind units, with independent being the asymetric side
{
	if ((side _x == east) || (side _x == independent)) then {
		[_x,independent] call compile preprocessFileLineNumbers "Intel\fnc_spawnIntelObjectsCombined.sqf";
	};
} forEach _intelUnits;


---------------------------------------------------------------------------- */
params [["_unit",objNull]];


//Exit if the code is already running on the unit
if (_unit getVariable ["INC_intelKillEh",false] || {(side _unit == CIVILIAN)}) exitWith {};

//Set variable on the unit so we can detect if the code is trying to run on same unit more than once and prevent that
_unit setVariable ["INC_intelKillEh", true, true];

#include "..\INT_setup.sqf"

private _continue = true;

switch (side _unit) do {

	case independent: {
		if !(_indSpawnIntel) then {_continue = false};
	};

	case east: {
		if !(_eastSpawnIntel) then {_continue = false};
	};

	case west: {
		if !(_westSpawnIntel) then {_continue = false};
	};
};

if !(_continue) exitWith {};


if (isNil "asymIntelSide") then {
	asymIntelSide = _asymSide;
	asymIntelFaction = _asymFaction;
};

if ((_unit isEqualTo (leader group _unit)) && !(_unit getVariable ["INC_isNotGroupLead",false])) then {_unit setVariable ["INC_isGroupLead", true, true]} else {_unit setVariable ["INC_isNotGroupLead", true, true]};

if (side _unit == _asymSide) exitWith {

	_unit setVariable ["asymIntel", true, false];

	if ((_pcHVTintelAsym > (random 100)) && !(isNil "INCON_fnc_markHVTIntel")) then {

		//Eventhandler HVT intel
		_unit addEventHandler["Killed", {
			params["_unit","_killer"];

			_killer addRating 1000;

			private ["_class","_pos","_intelObject","_intel"];
			_class = selectRandom ["Land_Notepad_F"]; //Array of possible intel objects for this class
			_pos = getposATL _unit;
			_intelObject = _class createVehicle [0,0,0];
			_intelObject setposATL ([_pos,(2 + (random 0.7))] call CBA_fnc_Randpos);

			[-1, {
				readData = _this addAction ["<t color='#FF0000'>Read notepad</t>",{
					_intel = _this select 0;
					_gatherer = _this select 2;

					//Change the below to whatever you want to happen when action is used
					if (90> (random 100)) then {
						[2,80,asymIntelSide] call INCON_fnc_markHVTIntel;
					} else {
						[] call INCON_fnc_markSuperHVTIntel;
					};

					_intel removeAction readData;
					deleteVehicle _intel;

				},[],1,false,true,"","",3];
			}, _intelObject] call CBA_fnc_globalExecute;
		}];
	};

	if (_pcInstallationMark > (random 100)) then {

		//Mark nearest installations
		_unit addEventHandler["Killed", {

			params["_unit","_killer"];

			_killer addRating 1000;

			private ["_class","_pos","_intelObject","_intel"];

			_class = selectRandom ["Land_HandyCam_F","Land_File1_F","Land_FilePhotos_F"]; //Array of possible intel objects for this class
			_pos = getposATL _unit;
			_intelObject = _class createVehicle [0,0,0];
			_intelObject setposATL ([_pos,(2 + (random 0.7))] call CBA_fnc_Randpos);

			[-1, {
				readData = _this addAction ["<t color='#FF0000'>Analyse dropped intel</t>",{

					_intel = _this select 0;
					_installationsToMark = ceil (random 5);
					[getPosATL _intel,asymIntelFaction,_installationsToMark] call INCON_fnc_markNearestInstallations; //Change this to whatever you want to happen when action is used
					_intel removeAction readData;
					deleteVehicle _intel;

				},[],1,false,true,"","",3];
			}, _intelObject] call CBA_fnc_globalExecute;
		}];
	};

	if (_unit getVariable ["INC_isGroupLead",false]) then {
		if (_pcRadioAsym > (random 100)) exitWith {

			//Eventhandler for radios
			_unit addEventHandler["Killed", {
				params["_unit","_killer"];

				_killer addRating 1000;

				private ["_class","_pos","_intelObject","_intel"];
				_class = selectRandom ["Land_PortableLongRangeRadio_F"]; //Array of possible intel objects for this class
				_pos = getposATL _unit;
				_intelObject = _class createVehicle [0,0,0];
				_intelObject setposATL ([_pos,(2 + (random 0.7))] call CBA_fnc_Randpos);

				[-1, {
					readData = _this addAction ["<t color='#FF0000'>Upload device data for SIGINT analysis</t>",{
						_intel = _this select 0;
						_gatherer = _this select 1;

						[[asymIntelSide,40,80], "INC_intel\Scripts\unitTracker.sqf"] remoteExec ["execVM",_gatherer]; //Change this to whatever you want to happen when action is used
						_intel removeAction readData;
						deleteVehicle _intel;

					},[],1,false,true,"","",3];
				}, _intelObject] call CBA_fnc_globalExecute;

			}];
		};
	} else {
		if (_pcPhoneAsym > (random 100)) exitWith {

			//Eventhandler for dropped phones
			_unit addEventHandler["Killed", {
				params["_unit","_killer"];

				_killer addRating 1000;

				private ["_class","_pos","_intelObject","_intel"];
				_class = selectRandom ["Land_MobilePhone_smart_F","Land_MobilePhone_old_F"]; //Array of possible intel objects for this class
				_pos = getposATL _unit;
				_intelObject = _class createVehicle [0,0,0];
				_intelObject setposATL ([_pos,(2 + (random 0.7))] call CBA_fnc_Randpos);

				[-1, {
					readData = _this addAction ["<t color='#FF0000'>Upload device data for SIGINT analysis</t>",{

						_intel = _this select 0;
						_gatherer = _this select 1;
						[[asymIntelSide], "INC_intel\Scripts\unitTrackerPhone.sqf"] remoteExec ["execVM",_gatherer]; //Change this to whatever you want to happen when action is used
						_intel removeAction readData;
						deleteVehicle _intel;

					},[],1,false,true,"","",3];
				}, _intelObject] call CBA_fnc_globalExecute;

			}];
		};
	};
};

convIntelSide = side _unit;
_unit setVariable ["convIntel", true, false];

if ((_pcHVTintelReg > (random 100)) && !(isNil "INCON_fnc_markHVTIntel")) then {

	//HVTs
	_unit addEventHandler ["Killed", {
		params["_unit","_killer"];

		_killer addRating 1000;

		private ["_class","_pos","_intelObject","_intel"];
		_class = selectRandom ["Land_Notepad_F","Land_File_research_F","Land_Tablet_02_F"]; //Array of possible intel objects for this class
		_pos = getposATL _unit;
		_intelObject = _class createVehicle [0,0,0];
		_intelObject setposATL ([_pos,(2 + (random 0.7))] call CBA_fnc_Randpos);

		[-1, {
			readData = _this addAction ["<t color='#FF0000'>Analyse dropped intel</t>",{

				_intel = _this select 0;
				_gatherer = _this select 1;

				//Change the below to whatever you want to happen when action is used
				if (60> (random 100)) then {
					[2,80,convIntelSide] call INCON_fnc_markHVTIntel;
				} else {
					[] call INCON_fnc_markSuperHVTIntel;

				};

				_intel removeAction readData;
				deleteVehicle _intel;

			},[],1,false,true,"","",3];
		}, _intelObject] call CBA_fnc_globalExecute;
	}];
};

if (_unit getVariable ["INC_isGroupLead",false]) then {

	if (_pcRadioReg > (random 100)) exitWith {

		//Radios
		_unit addEventHandler["Killed", {
			params["_unit","_killer"];

			_killer addRating 1000;

			private ["_class","_pos","_intelObject","_intel"];
			_class = selectRandom ["Land_PortableLongRangeRadio_F"]; //Array of possible intel objects for this class
			_pos = getposATL _unit;
			_intelObject = _class createVehicle [0,0,0];
			_intelObject setposATL ([_pos,(2 + (random 0.7))] call CBA_fnc_Randpos);

			[-1, {
				readData = _this addAction ["<t color='#FF0000'>Upload device data for SIGINT analysis</t>",{

					_intel = _this select 0;
					_gatherer = _this select 1;

					[[convIntelSide,40,80], "INC_intel\Scripts\unitTracker.sqf"] remoteExec ["execVM",_gatherer]; //Change this to whatever you want to happen when action is used
					_intel removeAction readData;
					deleteVehicle _intel;

				},[],1,false,true,"","",3];
			}, _intelObject] call CBA_fnc_globalExecute;
		}];
	};
} else {
	if (_pcPhoneReg > (random 100)) exitWith {

		//Eventhandler for dropped phones
		_unit addEventHandler["Killed", {
			params["_unit","_killer"];

			_killer addRating 1000;

			private ["_class","_pos","_intelObject","_intel"];
			_class = selectRandom ["Land_MobilePhone_smart_F","Land_MobilePhone_old_F"]; //Array of possible intel objects for this class
			_pos = getposATL _unit;
			_intelObject = _class createVehicle [0,0,0];
			_intelObject setposATL ([_pos,(2 + (random 0.7))] call CBA_fnc_Randpos);

			[-1, {
				readData = _this addAction ["<t color='#FF0000'>Upload device data for SIGINT analysis</t>",{

					_intel = _this select 0;
					_gatherer = _this select 1;
					[[convIntelSide], "INC_intel\Scripts\unitTrackerPhone.sqf"] remoteExec ["execVM",_gatherer]; //Change this to whatever you want to happen when action is used
					_intel removeAction readData;
					deleteVehicle _intel;

				},[],1,false,true,"","",3];
			}, _intelObject] call CBA_fnc_globalExecute;
		}];
	};
};
