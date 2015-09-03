static int s__i_Engine;
static bool s__b_Engine_Checked = false;


/**
* enum -> GameType
*/
enum SupportedGames {
	GameType_CSS,
	GameType_CSGO
};

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
* Used to get the amount of connected
* players in the server.
*
* @param Team			Optional int to specify a team.
*/
stock int Sys_PlayerCount(int Team = -1){
	int count = 0;
	for(int i = 1; i <= MaxClients; i++){
		if(IsClientConnected(i) && ((Team != -1) ? (GetClientTeam(i) == Team) : true))
			count++;
	}
	return count;
}

/**
* Used to get the amount of alive
* players in the server.
*
* @param Team			Optional int to specify a team.
*/
stock int Sys_AlivePlayerCount(int Team = -1){
	int count = 0;
	for(int i = 1; i <= MaxClients; i++){
		if(IsClientConnected(i) && IsPlayerAlive(i) && ((Team != -1) ? (GetClientTeam(i) == Team) : true))
			count++;
	}
	return count;
}

/**
* Used to print console messages to all players
*
* @param format			String to print
* @param ...			Formatting options
*/
stock void PrintToConsoleAll(char[] format, any ...){
	char buffer[192];

	for (int i = 1; i <= MaxClients; i++){
		if (IsClientInGame(i)){
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			PrintToConsole(i, "%s", buffer);
		}
	}
}

/*
* Used to print messages to all players and allow custom colors
*/
stock void PrintTextChatAll(char[] msg, any ...){
	char buffer[300];
	VFormat(buffer, sizeof(buffer), msg, 2);

	Handle hMessage = StartMessageAll("SayText2");

	if (hMessage != INVALID_HANDLE)
	{
		if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(hMessage, "ent_idx", 0); // optional client
			PbSetBool(hMessage, "chat", true);
			PbSetString(hMessage, "msg_name", buffer);
			PbAddString(hMessage, "params", "");
			PbAddString(hMessage, "params", "");
			PbAddString(hMessage, "params", "");
			PbAddString(hMessage, "params", "");
		}
		else
		{
			BfWriteByte(hMessage, 0); // optional client
			BfWriteByte(hMessage, true);
			BfWriteString(hMessage, buffer);
		}

		EndMessage();
	}
}

/*
* Forces a cvar's value
*/
stock void ForceConVar(char[] cvarname, char[] value){
	ConVar cvar = FindConVar(cvarname);
	if(cvar != null)
		cvar.SetString(value, true);
}

/*
* Used to print messages to a single player and allows special colors without annoying hexadecimal spam in console
*/
stock void PrintTextChat(int client, const char[] msg, any ...){
	if(IsClientInGame(client)){
		char buffer[300];
		VFormat(buffer, sizeof(buffer), msg, 3);

		Handle hMessage = StartMessageOne("SayText2", client);
		if (hMessage != INVALID_HANDLE)
		{
			if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
			{
				PbSetInt(hMessage, "ent_idx", 0);
				PbSetBool(hMessage, "chat", true);
				PbSetString(hMessage, "msg_name", buffer);
				PbAddString(hMessage, "params", "");
				PbAddString(hMessage, "params", "");
				PbAddString(hMessage, "params", "");
				PbAddString(hMessage, "params", "");
			}
			else
			{
				BfWriteByte(hMessage, 0);
				BfWriteByte(hMessage, true);
				BfWriteString(hMessage, buffer);
			}

			EndMessage();
		}
	}
}

/*
* Used to print messages to a player's spectators and allows special colors without annoying hexadecimal spam in console
*/
stock void PrintTextChatObservers(int target, const char[] msg, any ...){
	char buffer[300];
	VFormat(buffer, sizeof(buffer), msg, 3);

	int clients[MaxClients];
	int observercount;

	for(int client = 1; client <= MaxClients; client++){
		if(IsClientInGame(client) && !IsPlayerAlive(client) && !IsFakeClient(client)){
			int observee 		= GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			int ObserverMode 	= GetEntProp(client, Prop_Send, "m_iObserverMode");

			if(observee == target && (ObserverMode == 4 || ObserverMode == 5)){
				clients[observercount++] = client;
			}
		}
	}

	if(observercount == 0)
		return;

	Handle hMessage = StartMessage("SayText2", clients, observercount);
	if (hMessage != INVALID_HANDLE)
	{
		if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(hMessage, "ent_idx", 0);
			PbSetBool(hMessage, "chat", true);
			PbSetString(hMessage, "msg_name", buffer);
			PbAddString(hMessage, "params", "");
			PbAddString(hMessage, "params", "");
			PbAddString(hMessage, "params", "");
			PbAddString(hMessage, "params", "");
		}
		else
		{
			BfWriteByte(hMessage, 0);
			BfWriteByte(hMessage, true);
			BfWriteString(hMessage, buffer);
		}

		EndMessage();
	}
}

stock SupportedGames GetGameType(){
	if(!s__b_Engine_Checked){
		EngineVersion engVersion = GetEngineVersion();

		if(engVersion == Engine_CSGO)
			s__i_Engine = GameType_CSGO;

		if(engVersion == Engine_CSS)
			s__i_Engine = GameType_CSS;

		s__b_Engine_Checked = true;
	}
	return view_as<SupportedGames>s__i_Engine;
}
