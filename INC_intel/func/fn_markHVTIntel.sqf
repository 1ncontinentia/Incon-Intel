/*

Marks HVT locations for limited duration.

*/

params [["_maxHVTs",1],["_percentageSuccess",80],["_side",independent],["_precision",50],["_HVTVariable","isHVT"],["_decoyVariable","isDecoy"]];


_HVTarray = [];

if (_percentageSuccess > (random 100)) then {

	_HVTsToMark = (round (random _maxHVTs));

	{

		if (count _HVTarray < _HVTsToMark) then {

			_HVTarray pushBackUnique _x;
		};

	} forEach (allUnits select {

		if (side _x == _side) then {

			if ((_x getVariable [(_HVTVariable),false]) || (_x getVariable [(_decoyVariable),false])) then {

				true

			};

		};

	});

	_markers = [];

	{

		private _pos = getPosWorld _x;
		private _finalPos =  ([_pos,(_precision)] call CBA_fnc_Randpos);
		_m = createMarkerLocal [format ["INC_HVT%1",_x], _finalPos];
		_m setMarkerSizeLocal [1,1];
		_markers set [count _markers, _m];
		_m setMarkerTypeLocal "mil_objective";
		_m setMarkerColorLocal "ColorOPFOR";
		_m setMarkerTextLocal "Possible HVT location";

	} forEach _HVTarray;

	if (_markers isEqualTo []) then {hint format ["No targets found."]} else {hint format ["Possible HVT located. Check map."]};

	_markers spawn {
		_markers = _this;
		_i = 1;
		waitUntil {
			sleep 2;
			_i = _i - .05;
			if (_i > 0.1) then {
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
} else {
	hint "No useful intel found.";
};

_HVTarray
