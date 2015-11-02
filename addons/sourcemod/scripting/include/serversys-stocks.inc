#if defined _serversys_stocks_included
  #endinput
#endif
#define _serversys_stocks_included

/**
* Used to cleanly close handles
*
* @param hndl			Handle to close
*/
stock void Sys_KillHandle(Handle hndl){
	if(hndl != INVALID_HANDLE){
		CloseHandle(hndl);
		hndl = INVALID_HANDLE;
	}
}

/**
* Used to get a clients velocity.
* Credit for this code to blacky.
*
* @param client			Client to get info for
* @param useX			Whether or not to account for x-axis velocity.
* @param useY			Whether or not to account for y-axis velocity.
* @param useZ			Whether or not to account for z-axis velocity.
*/
stock float Sys_GetVelocity(int client, bool useX = true, bool useY = true, bool useZ = true){
	float vel[3];

	if(useX) vel[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	if(useY) vel[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	if(useZ) vel[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

	return GetVectorLength(vel);
}

/**
* Used to get the amount of connected
* players in the server.
*
* @param Team			Optional int to specify a team.
* @param badteams		Optionally include team 0
* @param bots			Optionally include bots.
* @param stv			Optionally include SourceTV.
*/
stock int Sys_GetPlayerCount(int Team = -2001, bool badteams = false, bool bots = false, bool stv = false){
	int PlayersNum = 0;

	for(int i = 1; i <= MaxClients; i++){
		if(IsClientInGame(i) && (stv == true || !IsClientSourceTV(i)) && (bots == true || !IsFakeClient(i))){
			if(Team == -2001 && (badteams == true || (GetClientTeam(i) != 0)))
				PlayersNum++;
			else if(Team == GetClientTeam(i))
				PlayersNum++;
		}
	}

	return PlayersNum;
}

/**
* Used to get the amount of alive
* players in the server.
*
* @param Team			Optional int to specify a team.
* @param bots			Optionally include bots.
* @param stv			Optionally include SourceTV.
*/
stock int Sys_GetAlivePlayerCount(int Team = -2001, bool bots = false, bool stv = false){
	int PlayersNum = 0;

	for(int i = 1; i <= MaxClients; i++){
		if(IsClientInGame(i) && IsPlayerAlive(i) && (stv == true || !IsClientSourceTV(i)) && (bots == true || !IsFakeClient(i))){
			if(Team == -2001 || (Team == GetClientTeam(i)))
				PlayersNum++;
		}
	}

	return PlayersNum;
}

/**
* Used to get a random valid player index.
*
* @param Team			Optionally specify a team.
* @param alive			Optionally require players to be alive.
*/
stock int Sys_GetRandomPlayer(int Team = -2001, bool alive = false){
	int[] Players = new int[MaxClients + 1];
	int PlayersNum = 0;

	for (int i = 1; i <= MaxClients; i++){
		if (IsClientInGame(i) && (alive == false || IsPlayerAlive(i)) && !IsClientSourceTV(i) && !IsFakeClient(i)){
			if(Team == -2001 || (GetClientTeam(i) == Team)){
				Players[PlayersNum] = i;
				PlayersNum++;
			}
		}
	}

	return (PlayersNum != 0) ? Players[GetRandomInt(0, PlayersNum - 1)] : 0;
}

/**
* Used to print console messages to all players
*
* @param format			String to print
* @param ...			Formatting options
*/
stock void PrintToConsoleAll(char[] format, any ...){
	char buffer[300];

	for(int i = 1; i <= MaxClients; i++){
		if (IsClientInGame(i)){
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			PrintToConsole(i, "%s", buffer);
		}
	}
}

/**
* SetClientHealth to pair with GetClientHealth.
*
* @param client         Client index.
* @param health         Health amount.
*/
stock void SetClientHealth(int client, int health){
	if(IsClientInGame(client) && IsPlayerAlive(client))
		SetEntProp(client, Prop_Send, "m_iHealth", health, 1);
}

/**
* SetClientArmor to pair with GetClientArmor.
*
* @param client         Client index.
* @param armor          Armor amount.
*/
stock void SetClientArmor(int client, int armor){
	if(IsClientInGame(client) && IsPlayerAlive(client))
		SetEntProp(client, Prop_Send, "m_ArmorValue", armor, 1);
}

/**
* Vector angles, function by blacky.
*
* @param vel
* @param angles
*/
stock void Sys_VectorAngles(float vel[3], float angles[3]){
	float tmp, float yaw, float pitch;

	if (vel[1] == 0 && vel[0] == 0)
	{
		yaw = 0.0;
		if (vel[2] > 0)
			pitch = 270.0;
		else
			pitch = 90.0;
	}
	else
	{
		yaw = (ArcTangent2(vel[1], vel[0]) * (180 / 3.141593));
		if (yaw < 0)
			yaw += 360;

		tmp = SquareRoot(vel[0]*vel[0] + vel[1]*vel[1]);
		pitch = (ArcTangent2(-vel[2], tmp) * (180 / 3.141593));
		if (pitch < 0)
			pitch += 360;
	}

	angles[0] = pitch;
	angles[1] = yaw;
	angles[2] = 0.0;
}
