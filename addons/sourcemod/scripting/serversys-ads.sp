#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <smlib>

#include <serversys>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[Server-Sys] Advertisements",
	description = "Server-Sys advertisements implementation. Web panel required.",
	author = "cam",
	version = SERVERSYS_VERSION,
	url = SERVERSYS_URL
}


char Ads_Prefix[32];
ArrayList Ads_Array;
float Ads_Interval;
int Ads_Current = 0;

int iServerID = 0;
int LoadAttempts = 0;

Handle Ads_Timer;


public void OnServerIDLoaded(int ServerID){
	iServerID = ServerID;
	Sys_LoadAdverts();
}

void LoadConfig(){
	Handle kv = CreateKeyValues("Advertisements");
	char Config_Path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Config_Path, sizeof(Config_Path), "configs/serversys/ads.cfg");

	if(!(FileExists(Config_Path)) || !(FileToKeyValues(kv, Config_Path))){
		Sys_KillHandle(kv);
		SetFailState("[serversys] ads :: Cannot read from configuration file: %s", Config_Path);
    }

	KvGetString(kv, "ads-prefix", Ads_Prefix, sizeof(Ads_Prefix), "[Ads]");
	Ads_Interval = KvGetFloat(kv, "ads-interval", 90.0);

	Sys_KillHandle(kv);
}

public void OnPluginStart(){
	LoadConfig();

	Ads_Array = new ArrayList(ByteCountToCells(128));
}

void Sys_LoadAdverts(int ServerID = 0){
	if(iServerID == 0)
		SetFailState("[serversys] ads :: Server ID not loaded");
	else
		ServerID = iServerID;

	char query[255];
	Format(query, sizeof(query), "SELECT text FROM adverts WHERE sid IN (0, %d);", ServerID);

	LoadAttempts++;
	Sys_DB_TQuery(Sys_LoadAdverts_CB, query, _, DBPrio_Low);
}


public void Sys_LoadAdverts_CB(Handle owner, Handle hndl, const char[] error, any data){
	if(hndl == INVALID_HANDLE){
		LogError("[serversys] ads :: Error loading advertisements: %s", client, error);
		return;
	}

	Ads_Array.Clear();

	char temp_string[128];

	while(SQL_FetchRow(hndl)){
		SQL_FetchString(hndl, 0, temp_string, sizeof(temp_string));
		Ads_Array.PushString(temp_string);
	}

	if(Ads_Timer != INVALID_HANDLE)
		Sys_KillHandle(Ads_Timer);

	Ads_Timer = CreateTimer((Ads_Interval != 0.0 ? Ads_Interval : 90.0), Sys_Adverts_Timer, _, TIMER_REPEAT);
}

public Action Sys_Adverts_Timer(Handle timer, any data){
	if(Ads_Array != INVALID_HANDLE){
		char current_ad[128];
		Ads_Array.GetString(Ads_Current, current_ad, sizeof(current_ad));

		PrintTextChatAll("%s %s", Ads_Prefix, current_ad);
	}else{
		if(LoadAttempts <= 5)
			Sys_LoadAdverts();
		else
			SetFailState("[serversys] ads :: Too many attempts to connect.");
	}

	if(Ads_Current <= Ads_Array.Length){
		Ads_Current++;
	}else{
		Ads_Current = 0;
	}
}
