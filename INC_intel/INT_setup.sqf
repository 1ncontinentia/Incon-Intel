/*

Setup options for INC_intel intel spawn script by Incontinentia.

*/


//Which sides should spawn intel items?
_westSpawnIntel = false; //West
_eastSpawnIntel = true; //East
_indSpawnIntel = true; //Independent


//********  Asymetric Intel Objects  **************

_pcHVTintelAsym = 4; //Percentage chance of object with HVT intel spawning (not implimented yet - ignore)
_pcInstallationMark = 7; //Percentage chance of object with installation intel spawning
_pcRadioAsym = 35; //Percentage chance of group radio spawning (group leaders only)
_pcPhoneAsym = 12; //Percentage chance of mobile phone (non-group leaders only)



//********  Regular Intel Objects  **************
_pcHVTintelReg = 3; //Percentage chance of object with HVT intel spawning (not implimented yet - ignore)
_pcRadioReg = 80; //Percentage chance of group radio spawning (group leaders only)
_pcPhoneReg = 12; //Percentage chance of mobile phone (non-group leaders only)

_asymSide = independent;  //Which side is asymmetric (1 side only, can be east, west, independent or sideEmpty)
_asymFaction = "IND_C_F"; //Which factions is asymmetric (1 faction only for now, must have quotation marks around it as in "OPF_F")
