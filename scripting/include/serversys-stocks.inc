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


stock void ReplaceMessage(char[] message, int maxlength){
	if(GetGameType() == GameType_CSS){
		ReplaceString(message, maxlength, "{stop}", "\x0A", false);
		ReplaceString(message, maxlength, "^a", "\x0A", false);
		ReplaceString(message, maxlength, "{team}", "\x03", false);
		ReplaceString(message, maxlength, "^", "\x07", false);
	}else if(GetGameType() == GameType_CSGO){
		ReplaceString(message, maxlength, "^a", "\x0A", false);
		ReplaceString(message, maxlength, "^z", "\x01 ");
		ReplaceString(message, maxlength, "^10", "\x10");
		ReplaceString(message, maxlength, "^1", "\x01");
		ReplaceString(message, maxlength, "^2", "\x02");
		ReplaceString(message, maxlength, "^3", "\x03");
		ReplaceString(message, maxlength, "^4", "\x04");
		ReplaceString(message, maxlength, "^5", "\x05");
		ReplaceString(message, maxlength, "^6", "\x06");
		ReplaceString(message, maxlength, "^7", "\x07");
		ReplaceString(message, maxlength, "^8", "\x08");
		ReplaceString(message, maxlength, "^9", "\x09");
		ReplaceString(message, maxlength, "^b", "\x0B", false);
		ReplaceString(message, maxlength, "^c", "\x0C", false);
		ReplaceString(message, maxlength, "^e", "\x0E", false);
		ReplaceString(message, maxlength, "^f", "\x0f", false);
	}
}
stock void UnformatMessage(char[] message, int maxlength){
	ReplaceString(message, maxlength, "^a", "", false);
	ReplaceString(message, maxlength, "{team}", "", false);
	ReplaceString(message, maxlength, "^z", "");
	ReplaceString(message, maxlength, "^10", "");
	ReplaceString(message, maxlength, "^1", "");
	ReplaceString(message, maxlength, "^2", "");
	ReplaceString(message, maxlength, "^3", "");
	ReplaceString(message, maxlength, "^4", "");
	ReplaceString(message, maxlength, "^5", "");
	ReplaceString(message, maxlength, "^6", "");
	ReplaceString(message, maxlength, "^7", "");
	ReplaceString(message, maxlength, "^8", "");
	ReplaceString(message, maxlength, "^9", "");
	ReplaceString(message, maxlength, "^b", "", false);
	ReplaceString(message, maxlength, "^c", "", false);
	ReplaceString(message, maxlength, "^e", "", false);
	ReplaceString(message, maxlength, "^f", "", false);
	ReplaceString(message, maxlength, "^", "", false);
}


stock void ShowMOTDNotify(int client, char[] motdTitle, char[] motdURL, int motdType, bool ShouldAddGame = true){
	char newURL[1024];
	char finalURL[1024];

	FormatEx(newURL, sizeof(newURL), "%s", motdURL);

	if(GetGameType() == GameType_CSGO){
		if(ShouldAddGame)
			FormatEx(newURL, sizeof(newURL), "%s&game=csgo", motdURL);

		FormatEx(finalURL, sizeof(finalURL), "http://strafeodyssey.com/csgo.php?%s", newURL);
	}else if(GetGameType() == GameType_CSS){
		if(ShouldAddGame)
			FormatEx(newURL, sizeof(newURL), "%s&game=css", motdURL);

		FormatEx(finalURL, sizeof(finalURL), "%s", newURL);
	}

	ShowMOTDPanel(client, motdTitle, finalURL, motdType);
	PrintToConsole(client, "\n[Server-Sys] MOTD Page URL: %s\n", newURL);
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
