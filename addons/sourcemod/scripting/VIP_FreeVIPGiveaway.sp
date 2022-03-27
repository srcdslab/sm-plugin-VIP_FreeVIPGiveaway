#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <vip_core>
#include <multicolors>
#include <mapchooser_extended>

#pragma newdecls required

/* CONVARS */
ConVar g_Cvar_MinPlayers;
//ConVar g_Cvar_Duration;
ConVar g_Cvar_VIPGroup;
ConVar g_Cvar_TestVIPGroup;
ConVar g_Cvar_Hostname;
ConVar g_Cvar_HostNamePrefix;

char g_sHostname[256] = "";
char g_sHostnamePrefix[256] = "";

public Plugin myinfo =
{
	name = "[VIP] Free VIP Giveaway",
	author = "inGame, maxime1907",
	description = "Gives Free VIP for players that are active on server",
	version = "1.0"
};

public void OnPluginStart()
{
	g_Cvar_HostNamePrefix = CreateConVar("sm_freevip_hostname_prefix", "[Free VIP]", "Hostname prefix that will be displayed in server list");
	g_Cvar_MinPlayers = CreateConVar("sm_freevip_min_players", "0", "How many players should be on server to active Free VIP Giveaway. [0 = OnClientConnected, 1-255 = OnRoundEnd]", FCVAR_NONE, true, 0.0, true, float(MAXPLAYERS));
	// g_Cvar_Duration = CreateConVar("sm_freevip_duration", "0", "For how many mins give Free VIP. [0 = Unlimited, 1-60 = minutes]", FCVAR_NONE, true, 0.0, true, 60.0);
	g_Cvar_VIPGroup = CreateConVar("sm_freevip_group", "VIP", "What VIP group set on player");

	g_Cvar_Hostname = FindConVar("hostname");

	RegConsoleCmd("sm_freevip", Command_FreeVIP, "Display FreeVIP Giveaway status.");

	HookEvent("round_start", Event_RoundStart);

	AutoExecConfig(true);
}

public void OnAllPluginsLoaded()
{
	g_Cvar_TestVIPGroup = FindConVar("sm_vip_test_group");
}

public void OnConfigsExecuted()
{
	if (!g_sHostname[0])
	{
		g_Cvar_HostNamePrefix.GetString(g_sHostnamePrefix, sizeof(g_sHostnamePrefix));
		g_Cvar_Hostname.GetString(g_sHostname, sizeof(g_sHostname));

		if (g_sHostname[0] && g_sHostnamePrefix[0] && StrContains(g_sHostname, g_sHostnamePrefix, true) == -1)
			ServerCommand("hostname %s %s", g_sHostnamePrefix, g_sHostname);
	}
}

public void OnMapStart()
{
	if (g_sHostname[0] && g_sHostnamePrefix[0] && StrContains(g_sHostname, g_sHostnamePrefix, true) == -1)
		ServerCommand("hostname %s %s", g_sHostnamePrefix, g_sHostname);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int playersOnServer = GetClientCount() - 1; // -1 cuz of sourcetv
	int minPlayers = GetConVarInt(g_Cvar_MinPlayers);
	//int duration = GetConVarInt(g_Cvar_Duration);

	char vipGroup[16];
	GetConVarString(g_Cvar_VIPGroup, vipGroup, sizeof(vipGroup));
	char hostname[255];
	GetConVarString(g_Cvar_Hostname, hostname, sizeof(hostname));

	// if min players amount reached
	if(playersOnServer >= minPlayers)
	{
		// Handled in OnClientConnect if equal to 0
		if (minPlayers > 0)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					// if player has no vip and player not in spec
					if(!VIP_IsClientVIP(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR)
					{
						VIP_GiveClientVIP(_, i, 0, vipGroup, false);
					}
					// else if player has vip and his vip is temporary and he is in spec - remove vip
					else if(VIP_IsClientVIP(i) && VIP_GetClientID(i) == -1 && GetClientTeam(i) == CS_TEAM_SPECTATOR)
					{
						VIP_RemoveClientVIP2(_, i, false, false);
					}
				}
			}
		}

		// push chat message
		CPrintToChatAll("[SM] {default}Free {pink}VIP {default}Giveaway is {green}enabled{default}. Active players got Free {pink}VIP");
	}
	else
	{
		char testVipGroup[16];
		GetConVarString(g_Cvar_TestVIPGroup, testVipGroup, sizeof(testVipGroup));

		// remove temporary vip from players if not enough players
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && VIP_IsClientVIP(i) && VIP_GetClientID(i) == -1 && !VIP_GetClientVIPGroup(i, testVipGroup, sizeof(testVipGroup)))
			{
				VIP_RemoveClientVIP2(_, i, false, false);
			}
		}

		int playersNeeded = minPlayers - playersOnServer;

		// push chat message
		CPrintToChatAll("[SM] {default}Free {pink}VIP {default}Giveaway is {red}disabled{default}.\nPlayers on: {green}%d {default}| Players required: {green}%d {default}| Players needed: {green}+%d", playersOnServer, minPlayers, playersNeeded);
	}
}

public void OnClientConnected(int client)
{
	if (GetConVarInt(g_Cvar_MinPlayers) == 0)
	{
		char vipGroup[16];
		GetConVarString(g_Cvar_VIPGroup, vipGroup, sizeof(vipGroup));

		if (client && !IsFakeClient(client) && !VIP_IsClientVIP(client))
		{
			VIP_GiveClientVIP(_, client, 0, vipGroup, false);
		}
	}
}

public void OnClientDisconnect(int client)
{
	if(!client)
		return;

	char testVipGroup[16];
	GetConVarString(g_Cvar_TestVIPGroup, testVipGroup, sizeof(testVipGroup));

	if(IsClientInGame(client) && VIP_IsClientVIP(client) && VIP_GetClientID(client) == -1 && !VIP_GetClientVIPGroup(client, testVipGroup, sizeof(testVipGroup)))
		VIP_RemoveClientVIP2(_, client, false, false);
}

public Action Command_FreeVIP(int client, int argc)
{
	int playersOnServer = GetClientCount() -1; // -1 cuz of sourcetv
	int minPlayers = GetConVarInt(g_Cvar_MinPlayers);

	if (playersOnServer >= minPlayers)
	{
		CPrintToChat(client, "{default}Free {pink}VIP {default}Giveaway is {green}enabled{default}.");
	}
	else
	{
		int playersNeeded = minPlayers - playersOnServer;

		CPrintToChat(client, "{default}Free {pink}VIP {default}Giveaway is {red}disabled{default}.\nPlayers on: {green}%d {default}| Players required: {green}%d {default}| Players needed: {green}+%d", playersOnServer, minPlayers, playersNeeded);
	}
	return Plugin_Handled;
}
