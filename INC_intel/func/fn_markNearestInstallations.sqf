/*

Mark Nearest Installations

Author: Spyderblack723

Modified by: Incontinentia

Places markers on 3 nearest installations within defined radius (default 800 meters) if _setMarkers is true (default on).

*/


params ["_intelPos","_faction","_maxInstallations",["_setMarkers",true],["_range",2000]];

if (isnil "OPCOM_instances") exitWith {hint "No useful intel found"};

[_intelPos,_faction,_maxInstallations,_setMarkers,_range] spawn {

	params ["_intelPos","_faction","_maxInstallations",["_setMarkers",true],["_range",2000]];

	_installations = [_intelPos,_faction,_maxInstallations] call INCON_fnc_getNearestInstallations;

	if (_setMarkers) then {

		_markers = [];

		{
			if (_x distance2D _intelPos < _range) then {

				private _pos = getPosWorld _x;
				_m = createMarkerLocal [str _x, _pos];
				_m setMarkerSizeLocal [1,1];
				_markers set [count _markers, _m];
				_m setMarkerTypeLocal "n_installation";
				_m setMarkerColorLocal "ColorOPFOR";

			};
		} forEach _installations;

		if (_markers isEqualTo []) then {hint format ["No useful intel found."]} else {hint format ["Possible insurgent installation located. Check map."]};


		_i = 1;
		waitUntil {
			sleep 4;
			_i = _i - .05;
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
	};
};
