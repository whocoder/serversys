#if defined _serversys_core_included
  #endinput
#endif
#define _serversys_core_included

/**
* Reloads the core plugin's config file.
*
* @param map          Whether to load the maps config (if exists)
*                       or the default (core.cfg).
*/
native void Sys_ReloadConfiguration(bool map = true);

/**
* Checks if hide is enabled for a player.
*
* @param client         Client to check.
*/
native bool Sys_IsHideEnabled(int client);

/**
* Checks if the core plugin has Map-Configs enabled.
*
* @return               True if enabled, false otherwise.
*/
native bool Sys_UseMapConfigs();

/**
* Checks if the core plugin has Map-Configs enabled.
*
* @return               True if enabled, false otherwise.
*/
native bool Sys_InMap();


public SharedPlugin __pl_serversys_core =
{
	name = "serversys",
	file = "serversys-core.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if defined REQUIRE_PLUGIN
public __pl_serversys_core_SetNTVOptional(){
    MarkNativeAsOptional("Sys_IsHideEnabled");
    MarkNativeAsOptional("Sys_ReloadConfiguration");
    MarkNativeAsOptional("Sys_UseMapConfigs");
    MarkNativeAsOptional("Sys_InMap");
}
#endif
