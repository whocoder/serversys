#include <sourcemod>
#include <sdkhooks>
#include <cstrike>

#include <server-core>

#pragma semicolon 1
#pragma newdecls required

public Plugin ServerCore = {
	name = "[Server-Core] Core",
	description = "StrafeOdyssey.com",
	author = "cam",
	version = S_CORE_VERSION,
	url = S_CORE_URL
}

enum Method_NB {
	NOBLOCK_COLLISIONGROUP,
	NOBLOCK_SOLIDTYPE
}

enum Method_SP {
	SPAWNPROTECT_GODMODE,
	SPAWNPROTECT_RESPAWN
}

enum Method_Hide {
	HIDE_NORMAL,
	HIDE_TEAM
}



int 	g_iOffset_CollisionGroup;

/**
* NoBlock settings
*/
bool g_Settings_bNoBlock;
Method_NB g_Settings_iNoBlockMethod;

/**
* Hide settings
*/
bool g_Settings_bHide;
bool g_Settings_bHideDead;
bool g_Settings_bHideNoClip;
Method_Hide g_Settings_iHideMethod;

/**
* Spawn protection settings
*/
bool	g_Settings_bSpawnProtection;
float	g_Settings_fSpawnProtection_Length;
Method_SP g_Settings_iSpawnProtection_Method;

/**
* Server functionality variables
*/
bool 	g_bSpawnProtectionGlobal = false;
bool 	g_bSpawnProtection[MAXPLAYERS+1] = {false, ...};
bool	g_bHideEnabled[MAXPLAYERS+1] = {false, ...};

char	g_cMapName[64];

bool 	g_bLateLoad = false;

public void OnPluginStart(){
	g_hSettings = RegClientCookie("strafeodyssey", "Global options for all servers", CookieAccess_Public);

	LoadConfig();

	g_iOffset_CollisionGroup 	= FindSendPropOffs("CBaseEntity", "m_CollisionGroup");

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);


	for(int i = 1; i <= MaxClients; i++){
		if(IsClientConnected(i) && IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("serversys");

	CreateNative("Sys_IsHideEnabled", Native_IsHideEnabled);

	CreateNative("Sys_ReloadConfiguration", Native_ReloadConfiguration);

	g_bLateLoad = late;

	return APLRes_Success;
}

void LoadConfig(char[] map_name){
	Handle kv = CreateKeyValues("Server-Sys");
	char Config_Path[PLATFORM_MAX_PATH];

	if((strlen(map_name) > 1) && g_Settings_bMapConfig == true){
		BuildPath(Path_SM, Config_Path, sizeof(Config_Path), "configs/server-core/maps/%s/core.cfg");
	}

	if(( (strlen(map_name) <= 1) || (!g_Settings_bMapConfig) || !(FileExists(Config_Path)) ))
	{
		BuildPath(Path_SM, Config_Path, sizeof(Config_Path), "configs/server-core/core.cfg");
	}

	if(!FileToKeyValues(kv, Config_Path)){
		CloseHandle(kv);
		SetFailState("Can't read from configuration file: %s", Config_Path);
    }

	if(KvJumpToKey(kv, "mapconfigs")){
		g_Settings_bMapConfig = view_as<bool>KvGetNum(kv, "mapconfigs", 1);
	}
	else
		g_Settings_bMapConfig = false;

	if(KvJumpToKey(kv, "hide")){
		g_Settings_bHide = view_as<bool>KvGetNum(kv, "enabled", 1);
		g_Settings_bHideDead = view_as<bool>KvGetNum(kv, "hide_dead", 1);
		g_Settings_bHideNoClip = view_as<bool>KvGetNum(kv, "hide_noclip", 1);

		g_Settings_iHideMethod = KvGetNum(kv, "method", HIDE_NORMAL);
	}
	else
		g_Settings_bHide = false;

	if(KvJumpToKey(kv, "noblock")){
		g_Settings_bNoBlock = view_as<bool>KvGetNum(kv, "enabled", 0);

		g_Settings_iNoBlockMethod = KvGetNum(kv, "method", NOBLOCK_COLLISIONGROUP);
	}
	else
		g_Settings_bNoBlock = false;

	if(KvJumpToKey(kv, "spawnprotection")){
		g_Settings_bSpawnProtection = view_as<bool>KvGetNum(kv, "enabled", 0);

		g_Settings_iSpawnProtection_Method = KvGetNum(kv, "method", SPAWNPROTECT_GODMODE);

		g_Settings_fSpawnProtection_Length = KvGetFloat(kv, "length", 5.0);
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

public Action Event_PlayerSpawn(Handle event, const char[] name, bool PreventBroadcast){
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_Settings_bNoBlock && (g_iOffset_CollisionGroup != -1)){
		SetEntData(client, g_iOffset_CollisionGroup, 2, 4, true);
	}

	if(g_Settings_bSpawnProtection){
		if(g_Settings_iSpawnProtection_Method == SPAWNPROTECT_GODMODE){
			g_bSpawnProtection[client] = true;
			PrintColorText(client, "You will have temporary spawn protection.");
			CreateTimer(g_Settings_fSpawnProtection_Length, Timer_SpawnProtection, client);
		}
	}
	else
	{
		g_bSpawnProtection[client] = false;
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

			if(g_Settings_bHideNoClip && GetEntityMoveType(entity) == MOVETYPE_NOCLIP)
				return Plugin_Handled;
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

	if(g_Settings_bSpawnProtection && g_bSpawnProtection[client]){
		if(g_Settings_iSpawnProtection_Method == SPAWNPROTECT_RESPAWN){
			PrintColorTextAll("%N will be respawned for dying early.", client);
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

public Action Timer_SpawnProtection(Handle timer, any client){
	if(g_Settings_bSpawnProtection){
		switch(g_Settings_iSpawnProtection_Method){
			case SPAWNPROTECT_GODMODE:{
				if((0 < client <= MaxClients) && IsClientInGame(client) && IsPlayerAlive(client)){
					g_bSpawnProtection[client] = false;
					PrintColorText(client, "Your spawn protection has expired.");
				}
			}
			case SPAWNPROTECT_RESPAWN:{
				if(g_bSpawnProtectionGlobal){
					for(int i = 1; i <= MaxClients; i++){
						if(IsClientConnected(i) && IsClientInGame(i) && !(IsPlayerAlive(i))){
							switch(GetClientTeam(i)){
								case CS_TEAM_T, CS_TEAM_CT:{
									CS_RespawnPlayer(i);
									PrintColorText(i, "You have been respawned.");
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
	if(g_Settings_bMapConfig){
		GetCurrentMap(g_cMapName, sizeof(g_cMapName));
		CreateTimer(0.5, OnMapStart_Timer_LoadConfig);
	}
}

public Action OnMapStart_Timer_LoadConfig(Handle timer){
	GetCurrentMap(g_cMapName, sizeof(g_cMapName));
	LoadConfig(g_cMapName);
}

public int Native_IsHideEnabled(Handle plugin, int numParams){
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
