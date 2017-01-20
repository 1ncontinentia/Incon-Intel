/* ----------------------------------------------------------------------------
Function: INCON_fn_unitTracker

Author: Incontinenetia

Based on ALiVE_fnc_markUnits by ARJay

This script will simulate hacking a phone and then tracking signals connected to the same network (random units of a certain side).
It takes weather and object occlusion into account to determine the accuracy, reliability and range of tracking.
Signals will be displayed on the map as coloured circles.

USAGE:

In init.sqf:

fnc_unitTracker = compile (preprocessFileLineNumbers "Intel\unitTracker.sqf");

Call with spawn:

Without init definition:
[_side,_percentageSuccess,_percentageReliability,_isAffectedByOvercast,_maxOvercastDegradation,_range,_precisionRadius,_precisionCurve,_markerColourOverride] spawn compile preprocessFileLineNumbers "unitTracker.sqf";

Short version and with init:
[_side] spawn fnc_unitTracker;

[_side] spawn compile preprocessFileLineNumbers "unitTracker.sqf";

ARGUMENTS

_side (side) is the side whose comms network is being triangulated.
_percentageSuccess (number) - optional, is the chance that the hacking will succeed. Default 60.
_percentageReliability (number) - optional, how likely a group's signal is to be detected. Also factors into precision radius. Default 90.
_percentageOnNetwork - (number) - optional, percentage of units of the same side who are contacts of the unit. Default is a random percentage up to 25.
_isAffectedByOvercast (boolean) - optional, sets whether weather affects effectiveness of tracking. Default true.
_maxOvercastDegradation (number) - optional, percentage of precision / reliability affected by overcast. At full overcast, 100 would mean 100% of signals would be lost; 50 would mean 50% of signals would be lost etc. Default 30.
_range (number) - optional, range in meters that contacts can be tracked. Default 1000.
_precisionRadius (number) - optional, best-case radius in meters that signals can be triangulated to if reliability was at 100%. Default 3.
_precisionCurve (number) - optional, power curve dropoff in precision. Default 3.
_markerColourOverride (boolean) - optional, makes all markers the same colour regardless of unit. Default false.
_objectOcclusion (boolean) - optional, whether tracking is blocked by buildings.  Default true.
_terminalNecessary (boolean) - optional, is a UAV terminal necessary to transmit data? Default true.

---------------------------------------------------------------------------- */

params ["_side",["_percentageSuccess",70],["_percentageReliability", 60],["_percentageOnNetwork",(random 35)],["_isAffectedByOvercast", true],["_maxOvercastDegradation",25],["_range",800],["_precisionRadius",5],["_precisionCurve",3],["_markerColourOverride",false],["_objectOcclusion",false],["_terminalNecessary",true]];

private ["_m","_markers","_triangulatingSide","_reliability","_accuracyScalar","_truePrecision","_overcastScalar","_markerSize","_markerColour","_indicatedPrecision"];

if ((isDedicated) || !(hasInterface)) exitWith {};

if (!(("B_UavTerminal" in assignedItems player) || ("I_UavTerminal" in assignedItems player) || ("O_UavTerminal" in assignedItems player)) && (_terminalNecessary)) then {

	hint "Equip a secured terminal to transmit data.";

	waitUntil {

		sleep 15;

		(("B_UavTerminal" in assignedItems player) || ("I_UavTerminal" in assignedItems player) || ("O_UavTerminal" in assignedItems player))

	};

};

_markerColour = "ColorOrange";

hint format ["Hacking device..."];

if (_percentageSuccess > (random 100)) then {

	sleep 20;


	if !(isNil "phoneContacts") exitWith {

		sleep (random 30);

		{
			if ((side _x == _side) && !(_x getVariable ["INC_isGroupLead", false]) && !(_x getVariable ["INC_noPhone", false])) then {
				if (_percentageOnNetwork > (random 100)) then {
					phoneContacts pushBackUnique _x;
					hint format ["Backdoor created. New contacts added."];
				};
			};
		} forEach allUnits;
	};

	missionNameSpace setVariable ["phoneContacts", [], false];

	{
		if (side _x == _side) then {
			if (_percentageOnNetwork > (random 100)) then {
				phoneContacts pushBack _x
			} else {

				if (50 > (random 100)) then {_x setVariable ["INC_noPhone",true,true]};
			};
		};
	} forEach allUnits;

	sleep (random 30);

	hint format ["Backdoor created. Tracking phone contacts."];

	waitUntil {

		if (!(("B_UavTerminal" in assignedItems player) || ("I_UavTerminal" in assignedItems player) || ("O_UavTerminal" in assignedItems player)) && (_terminalNecessary)) exitWith {true};


		if (_isAffectedByOvercast) then {
			_overcastScalar = ((_maxOvercastDegradation)/100); // 0 - 1, 1 meaning full degradation
			_reliability = ((1 - (overcast * _overcastScalar)) * _percentageReliability); // Percentage reliability after overcast degradation taken off, higher = better - default 63 at full overcast
			_range = ((1 - (overcast * (_overcastScalar/2))) * _range);

		} else {
			_reliability = _percentageReliability; // Percentage reliability of signal - default 90
		};

		_accuracyScalar = (100 / _reliability); // 1.59 at default full overcast, 1.11 in good conditions.

		_truePrecision = (_precisionRadius * (_accuracyScalar ^ _precisionCurve)); // precision radius x 6.4 at default in full overcast, 1.51 in clear.

		_indicatedPrecision = _truePrecision / 4;

		_markerSize = (0.67 * _indicatedPrecision);

		_markerAlpha = ((1 / _accuracyScalar) - 0.1);

		_markers = [];

		{

			if ((_x distance2D player < _range) && (alive _x)) then {

				if (_objectOcclusion) then {

					if ((lineIntersectsObjs [(getposASL _x), [(getposASL _x select 0),(getposASL _x select 1),((getposASL _x select 2) + 5)]]) isEqualTo []) then {

						if (_reliability > (random 100)) then {


							private _pos = getPosWorld _x;
							private _finalPos =  ([_pos,(_truePrecision)] call CBA_fnc_Randpos);
							_m = createMarkerLocal [format ["INC_trackerPh%1",_x], _finalPos];
							_m setMarkerSizeLocal [_markerSize,_markerSize];
							_m setMarkerTypeLocal "mil_dot_noShadow";
							_m setMarkerAlphaLocal _markerAlpha;
							_markers set [count _markers, _m];

							switch (side _x) do {
								case independent: {
									_m setMarkerColorLocal "ColorIndependent";
								};

								case east: {
									_m setMarkerColorLocal "ColorOPFOR";
								};

								case west: {
									_m setMarkerColorLocal "colorBLUFOR";
								};

								case civilian: {
									_m setMarkerColorLocal "colorCivilian";
								};
							};
						};
					};
				} else {

					if !((lineIntersectsObjs [(getposASL _x), [(getposASL _x select 0),(getposASL _x select 1),((getposASL _x select 2) + 5)]]) isEqualTo []) then {
						_reliability = _reliability * 0.5;
					};

					if (_reliability > (random 100)) then {

						private _pos = getPosWorld _x;
						private _finalPos =  ([_pos,(_truePrecision)] call CBA_fnc_Randpos);
						_m = createMarkerLocal [format ["INC_trackerPh%1",_x], _finalPos];
						_m setMarkerSizeLocal [_markerSize,_markerSize];
							_m setMarkerTypeLocal "mil_dot_noShadow";
							_m setMarkerAlphaLocal _markerAlpha;
						_markers set [count _markers, _m];

						switch (side _x) do {
							switch (side _x) do {
								case independent: {
									_m setMarkerColorLocal "ColorIndependent";
								};

								case east: {
									_m setMarkerColorLocal "ColorOPFOR";
								};

								case west: {
									_m setMarkerColorLocal "colorBLUFOR";
								};

								case civilian: {
									_m setMarkerColorLocal "colorCivilian";
								};
							};
						};
					};
				};
			};
		} forEach phoneContacts;

		_i = _markerAlpha;
		waitUntil {
			sleep 2;
			_i = _i - .0125;
			if (_i > 0.0) then {
				{
					_x setMarkerAlphaLocal _i;
				} forEach _markers;
			} else {
				{
					deleteMarkerLocal _x;
				} forEach _markers;
				true;
			};
		};

		false
	};

} else {

	sleep (30 + (random 30));
	hint format ["Unable to bypass device security."];

};
