/* ----------------------------------------------------------------------------
Unit tracker

Author: Incontinenetia

Based on ALiVE_fnc_markUnits by ARJay

This script will simulate hacking a phone and then tracking signals connected to the same network (group leaders).
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
_percentageReliability (number) - optional, how likely a group's signal is to be detected. Also factors into precision radius. Default 80.
_isAffectedByOvercast (boolean) - optional, sets whether weather affects effectiveness of tracking. Default true.
_maxOvercastDegradation (number) - optional, percentage of precision / reliability affected by overcast. At full overcast, 100 would mean 100% of signals would be lost; 50 would mean 50% of signals would be lost etc. Default 30.
_range (number) - optional, range in meters that contacts can be tracked. Default 1000.
_precisionRadius (number) - optional, best-case radius in meters that signals can be triangulated to if reliability was at 100%. Default 3.
_precisionCurve (number) - optional, power curve dropoff in precision. Default 3.
_markerColourOverride (boolean) - optional, makes all markers the same colour regardless of unit. Default false.
_objectOcclusion (boolean) - optional, whether tracking is blocked by buildings.  Default true.
_terminalNecessary (boolean) - optional, is a UAV terminal necessary to transmit data? Default true.




---------------------------------------------------------------------------- */

params ["_side",["_percentageSuccess",60],["_percentageReliability", 90],["_isAffectedByOvercast", true],["_maxOvercastDegradation",50],["_range",1000],["_precisionRadius",2],["_precisionCurve",3],["_markerColourOverride",false],["_objectOcclusion",false],["_terminalNecessary",true]];

private ["_m","_markers","_groupLeader","_triangulatingSide","_reliability","_accuracyScalar","_truePrecision","_overcastScalar","_markerSize","_markerColour","_indicatedPrecision"];

if ((isDedicated) || !(hasInterface)) exitWith {};

if (!(("B_UavTerminal" in assignedItems player) || ("I_UavTerminal" in assignedItems player) || ("O_UavTerminal" in assignedItems player)) && (_terminalNecessary)) then {

	hint "This data can only be transmitted through a secured terminal.";

	waitUntil {

		sleep 15;

		(("B_UavTerminal" in assignedItems player) || ("I_UavTerminal" in assignedItems player) || ("O_UavTerminal" in assignedItems player))

	};

};




_markerColour = "ColorOrange";

switch (_side) do {

	case independent: {
		_triangulatingSide = player getVariable ["triangulatingIND",false];
	};

	case east: {
		_triangulatingSide = player getVariable ["triangulatingEAST",false];
	};

	case west: {
		_triangulatingSide = player getVariable ["triangulatingWEST",false];
	};

	case civilian: {
		_triangulatingSide = player getVariable ["triangulatingCIV",false];
	};
};

hint format ["Hacking device..."];

if !(_triangulatingSide) then {

	if (_percentageSuccess > (random 100)) then {

		switch (_side) do {

			case independent: {
				player setVariable ["triangulatingIND", true, false];
				if (_markerColourOverride) then {
					_markerColour = "ColorOrange";
				} else {
					_markerColour = "ColorIndependent";
				};
			};

			case east: {
				player setVariable ["triangulatingEAST", true, false];
				if (_markerColourOverride) then {
					_markerColour = "ColorOrange";
				} else {
					_markerColour = "ColorOPFOR";
				};
			};

			case west: {
				player setVariable ["triangulatingWEST", true, false];
				if (_markerColourOverride) then {
					_markerColour = "ColorOrange";
				} else {
					_markerColour = "colorBLUFOR";
				};
			};

			case civilian: {
				player setVariable ["triangulatingCIV", true, false];
				if (_markerColourOverride) then {
					_markerColour = "ColorOrange";
				} else {
					_markerColour = "colorCivilian";
				};
			};
		};



		sleep (20 + (random 30));

		hint format ["Backdoor created. Tracking closed network."];

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

			_markerAlpha = (1 / _accuracyScalar);

			_markers = [];

			{
				_groupLeader = leader _x;

				if (_groupLeader distance2D player < _range) then {

					if (_objectOcclusion) then {

						if ((lineIntersectsObjs [(getposASL _groupLeader), [(getposASL _groupLeader select 0),(getposASL _groupLeader select 1),((getposASL _groupLeader select 2) + 5)]]) isEqualTo []) then {

							if (_reliability > (random 100)) then {


								private _pos = getPosWorld _groupLeader;
								private _finalPos =  ([_pos,(_truePrecision)] call CBA_fnc_Randpos);
								_m = createMarkerLocal [format ["INC_tracker%1",_groupLeader] , _finalPos];
								_m setMarkerSizeLocal [_markerSize,_markerSize];
								_m setMarkerAlphaLocal _markerAlpha;
								_markers set [count _markers, _m];

								switch (side _x) do {
									case _side: {
										_m setMarkerTypeLocal "mil_dot_noShadow";
										_m setMarkerColorLocal _markerColour;
									};
								};
							};
						};
					} else {

						if !((lineIntersectsObjs [(getposASL _groupLeader), [(getposASL _groupLeader select 0),(getposASL _groupLeader select 1),((getposASL _groupLeader select 2) + 5)]]) isEqualTo []) then {
							_reliability = _reliability * 0.5;
						};

						if (_reliability > (random 100)) then {

							private _pos = getPosWorld _groupLeader;
							private _finalPos =  ([_pos,(_truePrecision)] call CBA_fnc_Randpos);
							_m = createMarkerLocal [format ["INC_tracker%1",_groupLeader], _finalPos];
							_m setMarkerSizeLocal [_markerSize,_markerSize];
							_m setMarkerAlphaLocal _markerAlpha;
							_markers set [count _markers, _m];

							switch (side _x) do {
								case _side: {
									_m setMarkerTypeLocal "mil_dot_noShadow";
									_m setMarkerColorLocal _markerColour;
								};
							};
						};
					};
				};
			} forEach allGroups;

			_i = _markerAlpha;
			waitUntil {
				sleep 1;
				_i = _i - .0125;
				if (_i > 0.2) then {
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

} else {

	sleep (30 + (random 30));
	hint format ["Already tracking contacts on map."];

};
