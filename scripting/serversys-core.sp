#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <smlib>

#include <serversys>

#pragma semicolon 1
#pragma newdecls required

public Plugin serversys = {
	name = "[Server-Sys] Core",
	description = "Server-Sys - simple, yet advanced server management.",
	author = "cam",
	version = SERVERSYS_VERSION,
	url = SERVERSYS_URL
};

enum {
	NOBLOCK_TYPE_COLLISIONGROUP = 0,
	NOBLOCK_TYPE_SOLIDTYPE = 1
}

enum {
	SPAWNPROTECT_GODMODE = 0,
	SPAWNPROTECT_RESPAWN = 1
}

enum {
	HIDE_NORMAL = 0,
	HIDE_TEAM = 1
}


/**
* Database settings
*/
bool 	g_Settings_bUseDatabase;
char 	g_Settings_cDatabaseName[32];
int		g_Settings_iServerID;


/**
* Database variables
*/
bool 	g_SysDB_bConnected;
Handle 	g_SysDB;

float	g_fPlayTime[MAXPLAYERS+1];

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
* Forward Handles
*/
Handle	g_hF_Sys_OnDatabaseLoaded;

/**
* Server functionality variables
*/

bool 	g_bLateLoad = false;
bool 	g_bInMap = false;




public void OnPluginStart(){
	LoadConfig();

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
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

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("serversys");

	CreateNative("Sys_UseMapConfigs", Native_UseMapConfigs);
	CreateNative("Sys_IsHideEnabled", Native_IsHideEnabled);
	CreateNative("Sys_ReloadConfiguration", Native_ReloadConfiguration);
	CreateNative("Sys_InMap", Native_InMap);
	CreateNative("Sys_DB_Enable", Native_DB_Enable);
	CreateNative("Sys_DB_TQuery", Native_DB_TQuery);
	CreateNative("Sys_DB_EscapeString", Native_DB_EscapeString);

	g_bLateLoad = late;

	return APLRes_Success;
}

void LoadConfig(char[] map_name = ""){
	Handle kv = CreateKeyValues("Server-Sys");
	char Config_Path[PLATFORM_MAX_PATH];

	if(g_bInMap && (strlen(map_name) > 3) && g_Settings_bMapConfig == true){
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

		if(g_Settings_iServerID == -1){
			g_Settings_bUseDatabase = false;
			LogError("[serversys] core :: Invalid Server ID supplied.");
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

	CloseHandle(kv);
}

public void OnClientPutInServer(int client){
	g_bHideEnabled[client] = false;
	g_bSpawnProtection[client] = false;


	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public void OnClientAuthorized(int client, const char[] auth){

}

public void Sys_DB_Connect(char[] database){
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

	Call_StartForward(g_hF_Sys_OnDatabaseLoaded);
	Call_PushCell(true);
	Call_Finish();

	g_iSafeConnectCount = 1;
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
	*/

	int client = victim;

	if(g_Settings_bSpawnProtection && g_bSpawnProtection[client]){
		if(g_Settings_iSpawnProtection_Method == SPAWNPROTECT_GODMODE)
			return Plugin_Handled;
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

public Action Event_RoundEnd(Handle event, const char[] name, bool PreventBroadcast){\
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
	int originalSize;
	GetNativeStringLength(1, originalSize);
	char[] originalChar = new char[originalSize];
	GetNativeString(1, originalChar, originalSize);

	int newSize;
	GetNativeStringLength(2, newSize);
	char[] safeChar = new char[newSize];
	GetNativeString(2, safeChar, newSize);

	int written = GetNativeCell(3);

	SQL_EscapeString(g_SysDB, originalChar, safeChar, newSize, written);
}

public int Native_DB_Enable(Handle plugin, int numParams){
	return g_Settings_bUseDatabase;
}
