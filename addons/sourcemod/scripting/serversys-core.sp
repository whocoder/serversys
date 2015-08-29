#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <smlib>

#include <serversys>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[Server-Sys] Core",
	description = "Server-Sys - simple, yet advanced server management.",
	author = "cam",
	version = SERVERSYS_VERSION,
	url = SERVERSYS_URL
}

bool g_bServerID_Loaded = false;


/**
* Database settings
*/
bool 	g_Settings_bUseDatabase;
char 	g_Settings_cDatabaseName[32];
int		g_Settings_iServerID;
char	g_Settings_cServerName[64];
char	g_Settings_cServerIP[64];

bool 	g_Settings_bPlayTime;


/**
* Database variables
*/
bool 	g_SysDB_bConnected;
Handle 	g_SysDB;

/**
* MapConfig settings
*/
bool 	g_Settings_bMapConfig;

/**
* MapConfig variables
*/
char	g_cMapName[64];

/**
* NoBlock settings
*/
bool 	g_Settings_bNoBlock;
int 	g_Settings_iNoBlockMethod;

/**
* Hide settings
*/
bool 	g_Settings_bHide;
bool 	g_Settings_bHideDead;
bool 	g_Settings_bHideNoClip;
int 	g_Settings_iHideMethod;

/**
* Hide variables
*/
bool	g_bHideEnabled[MAXPLAYERS+1] = {false, ...};

/**
* Spawn protection settings
*/
bool	g_Settings_bSpawnProtection;
float	g_Settings_fSpawnProtection_Length;
int 	g_Settings_iSpawnProtection_Method;

/**
* Spawn protection variables
*/
bool 	g_bSpawnProtectionGlobal = false;
bool 	g_bSpawnProtection[MAXPLAYERS+1] = {false, ...};
int		g_iSafeConnectCount = 1;

/**
* God-mode settings
*/
bool	g_Settings_bDamage_GM;
bool	g_Settings_bDamage_GM_BetweenRound;
bool	g_Settings_bDamage_HSOnly;

/**
* Forward Handles
*/
Handle	g_hF_Sys_OnDatabaseLoaded;
Handle	g_hF_Sys_OnServerIDLoaded;
Handle 	g_hF_Sys_OnPlayerIDLoaded;

/**
* Server functionality variables
*/

bool 	g_bLateLoad = false;
bool 	g_bInMap = false;
bool	g_bInRound = false;

bool	g_bPlayerIDLoaded[MAXPLAYERS + 1];
int		g_iPlayerID[MAXPLAYERS + 1];

float g_fMapStartTime;
float g_fPlayerJoinTime[MAXPLAYERS + 1];

bool	g_bPlayTimeLoaded[MAXPLAYERS+1];


public void OnPluginStart(){
	LoadConfig();

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public void OnPluginEnd(){
	UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	UnhookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	UnhookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

/**
* OnAllPluginsLoaded is called once per every plugin,
* once all plugins have been initially loaded.
* If a plugin is late-loaded, it will be called immediately
* after OnPluginStart
*/
public void OnAllPluginsLoaded(){
	if(g_Settings_bUseDatabase){
		Sys_DB_Connect(g_Settings_cDatabaseName);
	}
	else
	{
		Call_StartForward(g_hF_Sys_OnDatabaseLoaded);
		Call_PushCell(false);
		Call_Finish();
	}
}

public void OnDatabaseLoaded(bool success){
	g_SysDB_bConnected = success;

	if(!g_SysDB_bConnected)
		return;

	Sys_DB_RegisterServer();
}

public void OnServerIDLoaded(int serverID){
	g_bServerID_Loaded = true;


	if(g_bLateLoad){
		for(int i = 1; i <= MaxClients; i++){
			if(IsClientConnected(i)){
				OnClientPutInServer(i);

				if(IsClientAuthorized(i))
					OnClientAuthorized(i, "");
			}
		}
	}
}

public void OnPlayerIDLoaded(int client, int playerID){
	g_iPlayerID[client] = playerID;

	Sys_DB_RegisterPlayTime(client);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("serversys");

	CreateNative("Sys_UseMapConfigs", Native_UseMapConfigs);
	CreateNative("Sys_IsHideEnabled", Native_IsHideEnabled);
	CreateNative("Sys_ReloadConfiguration", Native_ReloadConfiguration);
	CreateNative("Sys_InMap", Native_InMap);
	CreateNative("Sys_InRound", Native_InMap);
	CreateNative("Sys_GetPlayerID", Native_GetPlayerID);
	CreateNative("Sys_GetServerID", Native_GetServerID);
	CreateNative("Sys_UseDatabase", Native_DB_UseDatabase);

	CreateNative("Sys_DB_Connected", Native_DB_Connected);
	CreateNative("Sys_DB_TQuery", Native_DB_TQuery);
	CreateNative("Sys_DB_EscapeString", Native_DB_EscapeString);

	g_hF_Sys_OnDatabaseLoaded = CreateGlobalForward("OnDatabaseLoaded", ET_Event, Param_Cell);
	g_hF_Sys_OnServerIDLoaded = CreateGlobalForward("OnServerIDLoaded", ET_Event, Param_Cell);
	g_hF_Sys_OnPlayerIDLoaded = CreateGlobalForward("OnPlayerIDLoaded", ET_Event, Param_Cell, Param_Cell);

	g_bLateLoad = late;

	return APLRes_Success;
}

void LoadConfig(char[] map_name = ""){
	Handle kv = CreateKeyValues("Server-Sys");
	char Config_Path[PLATFORM_MAX_PATH];

	if(Sys_InMap() && (strlen(map_name) > 3) && g_Settings_bMapConfig == true){
		BuildPath(Path_SM, Config_Path, sizeof(Config_Path), "configs/serversys/maps/%s/core.cfg", g_cMapName);

		if(!(FileExists(Config_Path)) || !(FileToKeyValues(kv, Config_Path)))
			BuildPath(Path_SM, Config_Path, sizeof(Config_Path), "configs/serversys/core.cfg");
	}
	else
	{
		BuildPath(Path_SM, Config_Path, sizeof(Config_Path), "configs/serversys/core.cfg");
	}

	if(!(FileExists(Config_Path)) || !(FileToKeyValues(kv, Config_Path))){
		CloseHandle(kv);
		SetFailState("[serversys] core :: Cannot read from configuration file: %s", Config_Path);
    }

	if(KvJumpToKey(kv, "database")){
		g_Settings_bUseDatabase = view_as<bool>KvGetNum(kv, "enabled", 0);

		KvGetString(kv, "name", g_Settings_cDatabaseName, sizeof(g_Settings_cDatabaseName), "serversys");

		g_Settings_iServerID = KvGetNum(kv, "server_id", -1);

		KvGetString(kv, "server_ip", g_Settings_cServerIP, sizeof(g_Settings_cServerIP), "127.0.0.1");

		KvGetString(kv, "server_name", g_Settings_cServerName, sizeof(g_Settings_cServerName), "none");

		if((g_Settings_iServerID == -1) || StrEqual(g_Settings_cServerName, "none")){
			g_Settings_bUseDatabase = false;
			LogError("[serversys] core :: Invalid Server ID or Server Name supplied.");
		}

		if(KvJumpToKey(kv, "playtime") && g_Settings_bUseDatabase){
			g_Settings_bPlayTime = view_as<bool>KvGetNum(kv, "enabled", 0);

			KvGoBack(kv);
		}
		else
		{
			g_Settings_bPlayTime = false;
		}

		KvGoBack(kv);
	}
	else
		g_Settings_bUseDatabase = false;

	if(KvJumpToKey(kv, "mapconfigs")){
		g_Settings_bMapConfig = view_as<bool>KvGetNum(kv, "enabled", 1);

		KvGoBack(kv);
	}
	else
		g_Settings_bMapConfig = false;

	if(KvJumpToKey(kv, "hide")){
		g_Settings_bHide = view_as<bool>KvGetNum(kv, "enabled", 1);

		g_Settings_bHideDead = view_as<bool>KvGetNum(kv, "hide_dead", 1);
		g_Settings_bHideNoClip = view_as<bool>KvGetNum(kv, "hide_noclip", 0);

		g_Settings_iHideMethod = KvGetNum(kv, "method", HIDE_NORMAL);

		KvGoBack(kv);
	}
	else
		g_Settings_bHide = false;

	if(KvJumpToKey(kv, "noblock")){
		g_Settings_bNoBlock = view_as<bool>KvGetNum(kv, "enabled", 0);

		g_Settings_iNoBlockMethod = KvGetNum(kv, "method", NOBLOCK_TYPE_COLLISIONGROUP);

		KvGoBack(kv);
	}
	else
		g_Settings_bNoBlock = false;

	if(KvJumpToKey(kv, "spawnprotection")){
		g_Settings_bSpawnProtection = view_as<bool>KvGetNum(kv, "enabled", 0);

		g_Settings_iSpawnProtection_Method = KvGetNum(kv, "method", SPAWNPROTECT_GODMODE);

		g_Settings_fSpawnProtection_Length = KvGetFloat(kv, "length", 5.0);

		KvGoBack(kv);
	}
	else
		g_Settings_bSpawnProtection = false;

	if(KvJumpToKey(kv, "damage")){
		g_Settings_bDamage_GM 				= view_as<bool>KvGetNum(kv, "godmode", 0);
		g_Settings_bDamage_GM_BetweenRound 	= view_as<bool>KvGetNum(kv, "godmode_no_round", 0);
		g_Settings_bDamage_HSOnly 			= view_as<bool>KvGetNum(kv, "headshot_only");

		KvGoBack(kv);
	}
	else
	{
		g_Settings_bDamage_GM = false;
		g_Settings_bDamage_GM_BetweenRound = false;
		g_Settings_bDamage_HSOnly = false;
	}

	CloseHandle(kv);
}

public void OnClientPutInServer(int client){
	g_bHideEnabled[client] = false;
	g_bSpawnProtection[client] = false;


	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKHook(client, SDKHook_TraceAttack, Hook_TraceAttack);
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public void OnClientDisconnect(int client){
	SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKUnhook(client, SDKHook_TraceAttack, Hook_TraceAttack);
	SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);

	if(g_Settings_bUseDatabase && g_Settings_bPlayTime && g_bPlayerIDLoaded[client] && g_bPlayTimeLoaded[client]){
		Sys_DB_UpdatePlayTime(client);
	}
}

public void OnClientAuthorized(int client, const char[] sauth){
	Sys_DB_RegisterPlayer(client);

	g_fPlayerJoinTime[client] = GetEngineTime();
}

void Sys_DB_Connect(char[] database){
	Sys_KillHandle(g_SysDB);

	if(StrEqual(database, "", false) || (strlen(database) < 3))
		strcopy(database, 32, g_Settings_cDatabaseName);

	if(SQL_CheckConfig(database)){
		SQL_TConnect(Sys_DB_Connect_CB, database);
	}
	else
	{
		g_Settings_bUseDatabase = false;
		Call_StartForward(g_hF_Sys_OnDatabaseLoaded);
		Call_PushCell(false);
		Call_Finish();
	}
}

public void Sys_DB_Connect_CB(Handle owner, Handle hndl, const char[] error, any data){
	if(g_iSafeConnectCount >= 5){
		SetFailState("[serversys] core :: Reached connection count without success. Plugin stopped.");

		return;
	}

	if(hndl == INVALID_HANDLE){
		LogError("[serversys] core :: Database connection failed on attempt #%i: %s", g_iSafeConnectCount, error);

		g_iSafeConnectCount++;

		Sys_DB_Connect(g_Settings_cDatabaseName);

		return;
	}

	g_SysDB = CloneHandle(hndl);
	Sys_KillHandle(hndl);

	g_SysDB_bConnected = true;

	Call_StartForward(g_hF_Sys_OnDatabaseLoaded);
	Call_PushCell(true);
	Call_Finish();

	g_iSafeConnectCount = 1;
}

void Sys_DB_RegisterServer(){
	//g_Settings_iServerID;
	int size = (2*64+1);
	char[] safename = new char[size];

	Sys_DB_EscapeString(g_Settings_cServerName, 64, safename, size);

	char query[255];
	Format(query, sizeof(query), "INSERT INTO servers (id) VALUES (%d) ON DUPLICATE KEY UPDATE name = '%s', ip = '%s';",
		g_Settings_iServerID,
		safename,
		g_Settings_cServerIP);

	Sys_DB_TQuery(Sys_DB_RegisterServer_CB, query, _, DBPrio_High);
}

public void Sys_DB_RegisterServer_CB(Handle owner, Handle hndl, const char[] error, any data){
	if(hndl == INVALID_HANDLE){
		LogError("[serversys] core :: Error on registering server: %s", error);
		return;
	}

	Call_StartForward(g_hF_Sys_OnServerIDLoaded);
	Call_PushCell(g_Settings_iServerID);
	Call_Finish();
}

public void Sys_DB_GenericCallback(Handle owner, Handle hndl, const char[] error, any data){
	if(hndl == INVALID_HANDLE){
		LogError("[serversys] core :: Error on SQL from generic CB: %s", error);
		return;
	}
}

void Sys_DB_RegisterPlayer(int client){
	int auth = GetSteamAccountID(client);

	char query[255];
	Format(query, sizeof(query), "SELECT pid FROM users WHERE auth = %d;", auth);

	Sys_DB_TQuery(Sys_DB_RegisterPlayer_CB, query, GetClientUserId(client), DBPrio_High);
}

public void Sys_DB_RegisterPlayer_CB(Handle owner, Handle hndl, const char[] error, any data){
	int client = GetClientOfUserId(data);

	if(client == 0 || (!IsClientConnected(client)))
		return;

	if(hndl == INVALID_HANDLE){
		LogError("[serversys] core :: Error loading data for player (%N): %s", client, error);
		return;
	}

	if(SQL_FetchRow(hndl)){
		int playerid = SQL_FetchInt(hndl, 0);

		g_iPlayerID[client] = playerid;
		g_bPlayerIDLoaded[client] = true;

		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));

		int size = (2*MAX_NAME_LENGTH+1);
		char[] safename = new char[size];

		Sys_DB_EscapeString(name, MAX_NAME_LENGTH, safename, size);

		char query[255];
		Format(query, sizeof(query), "UPDATE users SET name='%s', lastseen = UNIX_TIMESTAMP() WHERE pid=%d;", safename, playerid);

		Sys_DB_TQuery(Sys_DB_GenericCallback, query, _, DBPrio_Normal);

		Call_StartForward(g_hF_Sys_OnPlayerIDLoaded);
		Call_PushCell(client);
		Call_PushCell(playerid);
		Call_Finish();
	}
	else
	{
		int auth = GetSteamAccountID(client);

		char query[255];
		Format(query, sizeof(query), "INSERT INTO users (auth) VALUES (%d);", auth);

		Sys_DB_TQuery(Sys_DB_RegisterPlayer_CB_CB, query, GetClientUserId(client), DBPrio_High);
	}
}

public void Sys_DB_RegisterPlayer_CB_CB(Handle owner, Handle hndl, const char[] error, any data){
	int client = GetClientOfUserId(data);

	if(client == 0 || !(IsClientConnected(client)))
		return;

	if(hndl == INVALID_HANDLE){
		LogError("[serversys] core :: Error loading ID for player (%N): %s", client, error);
		return;
	}
	else
	{
		Sys_DB_RegisterPlayer(client);
	}
}

public void Sys_DB_RegisterPlayTime(int client){
	int pid = g_iPlayerID[client];
	int sid = g_Settings_iServerID;

	char query[255];
	Format(query, sizeof(query), "SELECT time FROM playtime WHERE pid = %d AND sid = %d;", pid, sid);

	Sys_DB_TQuery(Sys_DB_RegisterPlayTime_CB, query, GetClientUserId(client), DBPrio_High);
}

public void Sys_DB_RegisterPlayTime_CB(Handle owner, Handle hndl, const char[] error, any data){
	int client = GetClientOfUserId(data);

	if(client == 0 || (!IsClientConnected(client)))
		return;

	if(hndl == INVALID_HANDLE){
		LogError("[serversys] core :: Error loading playtime for (%N): %s", client, error);
		return;
	}

	if(!SQL_FetchRow(hndl)){
		g_bPlayTimeLoaded[client] = false;
		int pid = g_iPlayerID[client];
		int sid = g_Settings_iServerID;

		char query[255];
		Format(query, sizeof(query), "INSERT INTO playtime (pid, sid) VALUES (%d, %d);", pid, sid);

		Sys_DB_TQuery(Sys_DB_RegisterPlayTime_CB_CB, query, GetClientUserId(client), DBPrio_High);
	}
	else
	{
		g_bPlayTimeLoaded[client] = true;
	}
}

public void Sys_DB_RegisterPlayTime_CB_CB(Handle owner, Handle hndl, const char[] error, any data){
	int client = GetClientOfUserId(data);

	if(client == 0 || (!IsClientConnected(client)))
		return;

	if(hndl == INVALID_HANDLE){
		LogError("[serversys] core :: Error loading playtime for (%N): %s", client, error);
		return;
	}
	else
	{
		Sys_DB_RegisterPlayTime(client);
	}

}

public void Sys_DB_UpdatePlayTime(int client){
	int pid = g_iPlayerID[client];
	int sid = g_Settings_iServerID;
	int time = RoundToFloor(GetEngineTime() - g_fPlayerJoinTime[client]);

	char query[255];
	Format(query, sizeof(query), "UPDATE playtime SET time = (SELECT time FROM (SELECT * FROM playtime) AS x WHERE pid = %d and sid = %d)+%d WHERE pid = %d AND sid = %d;",
		pid, sid, time, pid, sid);

	Sys_DB_TQuery(Sys_DB_GenericCallback, query, GetClientUserId(client), DBPrio_High);
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool PreventBroadcast){
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_Settings_bNoBlock){
		switch(g_Settings_iNoBlockMethod){
			case NOBLOCK_TYPE_COLLISIONGROUP:{
				//if(g_iOffset_CollisionGroup != -1)
				//	SetEntData(client, g_iOffset_CollisionGroup, 2, 4, true);

				if(Entity_GetCollisionGroup(client) != COLLISION_GROUP_DEBRIS_TRIGGER)
					Entity_SetCollisionGroup(client, COLLISION_GROUP_DEBRIS_TRIGGER);
			}
			case NOBLOCK_TYPE_SOLIDTYPE:{
				if(Entity_GetSolidType(client) != SOLID_NONE)
					Entity_SetSolidType(client, SOLID_NONE);
			}
		}
	}

	if(g_Settings_bSpawnProtection){
		if(g_Settings_iSpawnProtection_Method == SPAWNPROTECT_GODMODE){
			g_bSpawnProtection[client] = true;
			PrintTextChat(client, "You will have temporary spawn protection.");
			CreateTimer(g_Settings_fSpawnProtection_Length, Timer_SpawnProtection, GetClientUserId(client));
		}
	}
}

public Action Hook_SetTransmit(int entity, int client){
	if(g_Settings_bHide){
		if(entity != client && (0 < entity <= MaxClients) && IsPlayerAlive(client)){
			if(g_bHideEnabled[client]){
				switch(g_Settings_iHideMethod){
					case HIDE_NORMAL:{
						return Plugin_Handled;
					}
					case HIDE_TEAM:{
						if(GetClientTeam(entity) == GetClientTeam(client))
							return Plugin_Handled;
					}
				}
			}
			if(g_Settings_bHideDead && !(IsPlayerAlive(entity)))
				return Plugin_Handled;

			if(g_Settings_bHideNoClip && (GetEntityMoveType(entity) == MOVETYPE_NOCLIP))
				return Plugin_Handled;
			else
				return Plugin_Continue;
		}
	}

	return Plugin_Continue;
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype){
	/*
	*	Ignore all damage to spawn protected players when method == 0
	*	This is so that players cannot die until spawn protection ends.
	*
	*	We also need to prevent damage if godmode is enabled.
	*/

	if(g_Settings_bDamage_GM)
		return Plugin_Handled;

	if((g_Settings_bDamage_GM_BetweenRound) && !(Sys_InRound()))
		return Plugin_Handled;

	int client = victim;

	if(g_Settings_bSpawnProtection && g_bSpawnProtection[client])
	{
		if(g_Settings_iSpawnProtection_Method == SPAWNPROTECT_GODMODE)
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Hook_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup){
	/*
	*	If headshot-only mode is enabled, this ignores all damage where the
	*	hitgroup is not 1 (head).
	*/

	if(g_Settings_bDamage_HSOnly){
		if((0 < victim <= MaxClients) && (0 < attacker <= MaxClients)){
			if(IsClientInGame(victim) && IsClientInGame(attacker)){
				if(hitgroup != 1)
					return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}


public Action Event_PlayerDeath(Handle event, const char[] name, bool PreventBroadcast){
	/*
	*	Hook player death and notify of respawn status if method == 1
	*	This is so that if they die, they will be notified of their
	*	incoming respawn.
	*/
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_Settings_bSpawnProtection && g_bSpawnProtectionGlobal){
		if(g_Settings_iSpawnProtection_Method == SPAWNPROTECT_RESPAWN){
			PrintTextChatAll("%N will be respawned for dying early.", client);
		}
	}
}

public Action Event_RoundStart(Handle event, const char[] name, bool PreventBroadcast){
	g_bInRound = true;
	/*
	*	Give all player's spawn protection flag if method == 1
	*	This is so that if they die, they will be respawned.
	*/
	if(g_Settings_bSpawnProtection && (g_Settings_iSpawnProtection_Method == SPAWNPROTECT_RESPAWN)){
		g_bSpawnProtectionGlobal = true;
		CreateTimer(g_Settings_fSpawnProtection_Length, Timer_SpawnProtection, 0);
	}
	else
	{
		if(g_bSpawnProtectionGlobal != false){
			g_bSpawnProtectionGlobal = false;
		}
	}
}

public Action Event_RoundEnd(Handle event, const char[] name, bool PreventBroadcast){
	g_bInMap = false;
	/*
	*	Reset everyone's spawn protection status to false,
	*	so that they don't respawn during the next round.
	*/
	if(g_Settings_bSpawnProtection && (g_Settings_iSpawnProtection_Method == SPAWNPROTECT_RESPAWN)){
		g_bSpawnProtectionGlobal = false;
	}
}

public Action Timer_SpawnProtection(Handle timer, any clientID){
	int client = GetClientOfUserId(clientID);
	if(g_Settings_bSpawnProtection){
		switch(g_Settings_iSpawnProtection_Method){
			case SPAWNPROTECT_GODMODE:{
				if((0 < client <= MaxClients) && IsClientInGame(client) && IsPlayerAlive(client) && g_bSpawnProtection[client]){
					g_bSpawnProtection[client] = false;
					PrintTextChat(client, "Your spawn protection has expired.");
				}
			}
			case SPAWNPROTECT_RESPAWN:{
				if(g_bSpawnProtectionGlobal){
					for(int i = 1; i <= MaxClients; i++){
						if(IsClientConnected(i) && IsClientInGame(i) && !(IsPlayerAlive(i))){
							switch(GetClientTeam(i)){
								case CS_TEAM_T, CS_TEAM_CT:{
									CS_RespawnPlayer(i);
									PrintTextChat(i, "You have been respawned.");
								}
							}
						}
					}
				}
				g_bSpawnProtectionGlobal = false;
			}
		}
	}
}

public void OnMapStart(){
	g_bInMap = true;
	g_fMapStartTime = GetEngineTime();
	GetCurrentMap(g_cMapName, sizeof(g_cMapName));

	if(g_Settings_bMapConfig){
		CreateTimer(0.5, OnMapStart_Timer_LoadConfig);
	}
}

public void OnMapEnd(){
	g_bInMap = false;
	Format(g_cMapName, sizeof(g_cMapName), "");
}

public Action OnMapStart_Timer_LoadConfig(Handle timer){
	GetCurrentMap(g_cMapName, sizeof(g_cMapName));
	LoadConfig(g_cMapName);
}

public int Native_IsHideEnabled(Handle plugin, int numParams){
	if(!g_Settings_bHide)
		return false;

	int client 		= GetNativeCell(1);

	if((0 < client <= MaxClients) && IsClientConnected(client))
		return g_bHideEnabled[client];
	else
		return false;
}

public int Native_ReloadConfiguration(Handle plugin, int numParams){
	bool b_Map 		= GetNativeCell(1);

	if(b_Map){
		GetCurrentMap(g_cMapName, sizeof(g_cMapName));
		LoadConfig(g_cMapName);
	}
	else
		LoadConfig();
}

public int Native_UseMapConfigs(Handle plugin, int numParams){
	return g_Settings_bMapConfig;
}

public int Native_InRound(Handle plugin, int numParams){
	if(!Sys_InMap())
		return false;

	return g_bInRound;
}

public int Native_InMap(Handle plugin, int numParams){
	return g_bInMap;
}

public int Native_DB_TQuery(Handle plugin, int numParams){
	if(g_Settings_bUseDatabase && g_SysDB_bConnected){
		SQLTCallback callback = view_as<SQLTCallback>GetNativeFunction(1);

		int size;
		GetNativeStringLength(2, size);

		char[] sQuery = new char[size];
		GetNativeString(2, sQuery, size);

		any data = GetNativeCell(3);
		DBPriority prio = GetNativeCell(4);

		Handle hPack = CreateDataPack();
		WritePackCell(hPack, plugin);
		WritePackFunction(hPack, callback);
		WritePackCell(hPack, data);

		SQL_TQuery(g_SysDB, Native_DB_TQuery_Callback, sQuery, hPack, prio);
	}
}

public void Native_DB_TQuery_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);

	Handle plugin = view_as<Handle>ReadPackCell(data);
	SQLTCallback callback = view_as<SQLTCallback>ReadPackFunction(data);
	any hPack = ReadPackCell(data);

	Sys_KillHandle(data);

	Call_StartFunction(plugin, callback);
	Call_PushCell(owner);
	Call_PushCell(hndl);
	Call_PushString(error);
	Call_PushCell(hPack);
	Call_Finish();
}

public int Native_DB_EscapeString(Handle plugin, int numParams){
	int originalSize = GetNativeCell(2);
	char[] originalChar = new char[originalSize];
	GetNativeString(1, originalChar, originalSize);

	int safeSize = GetNativeCell(4);
	char[] safeChar = new char[safeSize];
	GetNativeString(3, safeChar, safeSize);

	int written = GetNativeCell(5);

	SQL_EscapeString(g_SysDB, originalChar, safeChar, safeSize, written);

	SetNativeString(3, safeChar, safeSize);
}

public int Native_DB_UseDatabase(Handle plugin, int numParams){
	return g_Settings_bUseDatabase;
}

public int Native_DB_Connected(Handle plugin, int numParams){
	if(!Sys_UseDatabase())
		return false;

	return g_SysDB_bConnected;
}

public int Native_GetPlayerID(Handle plugin, int numParams){
	if(!Sys_DB_Connected())
		return -1;

	int client = GetNativeCell(1);

	if(IsClientConnected(client) && IsClientAuthorized(client) && g_bPlayerIDLoaded[client]){
		return g_iPlayerID[client];
	}

	return -1;
}

public int Native_GetServerID(Handle plugin, int numParams){
	if(!g_bServerID_Loaded)
		return -1;

	return g_Settings_iServerID;
}