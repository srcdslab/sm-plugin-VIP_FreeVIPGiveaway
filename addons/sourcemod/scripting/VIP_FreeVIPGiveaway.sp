#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <vip_core>
#include <ccc>
#include <zombiereloaded>
#include <multicolors>
#include <mapchooser_extended>

#pragma newdecls required

/* CONVARS */
ConVar g_Cvar_MinPlayers;
//ConVar g_Cvar_Duration;
ConVar g_Cvar_VIPGroup;
ConVar g_Cvar_Hostname;
ConVar g_Cvar_TestVIPGroup;

public Plugin myinfo =
{
	name = "[VIP] Free VIP Giveaway",
	author = "inGame",
	description = "Gives Free VIP for players that are active on server",
	version = "0.1"
};

public void OnPluginStart()
{
	g_Cvar_MinPlayers = CreateConVar("sm_freevip_min_players", "55", "How many players should be on server to active Free VIP Giveaway.", FCVAR_NONE, true, 0.0, true, 64.0);
	//g_Cvar_Duration = CreateConVar("sm_freevip_duration", "10", "For how many mins give Free VIP.", FCVAR_NONE, true, 1.0, true, 60.0);
	g_Cvar_VIPGroup = CreateConVar("sm_freevip_group", "VIP", "What VIP group set on player");
	g_Cvar_Hostname = CreateConVar("sm_freevip_hostname", "This Server has Free VIP Giveaway", "Hostname.");

	g_Cvar_TestVIPGroup = FindConVar("sm_vip_test_group");

	RegConsoleCmd("freevip", Command_FreeVIP, "Display FreeVIP Giveaway status.");

	HookEvent("round_start", Event_RoundStart);

	AutoExecConfig(true, "FreeVIPGiveaway", "vip");
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

		// push chat message
		MC_PrintToChatAll("{white}Free \x07D147FFVIP {white}Giveaway is {green}enabled{white}. Active players got Free \x07D147FFVIP");
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
		MC_PrintToChatAll("{white}Free \x07D147FFVIP {white}Giveaway is {red}disabled{white}.\nPlayers on: {green}%d {white}| Players required: {green}%d {white}| Players needed: {green}+%d", playersOnServer, minPlayers, playersNeeded);
	}

	ChangeHostname();
}

public void OnClientPutInServer(int client) { ChangeHostname(); }

public void OnClientDisconnect(int client)
{
	if(!client)
		return;

	char testVipGroup[16];
	GetConVarString(g_Cvar_TestVIPGroup, testVipGroup, sizeof(testVipGroup));

	if(IsClientInGame(client) && VIP_IsClientVIP(client) && VIP_GetClientID(client) == -1 && !VIP_GetClientVIPGroup(client, testVipGroup, sizeof(testVipGroup)))
		VIP_RemoveClientVIP2(_, client, false, false);

	ChangeHostname();
}

public Action Command_FreeVIP(int client, int argc)
{
	int playersOnServer = GetClientCount() -1; // -1 cuz of sourcetv
	int minPlayers = GetConVarInt(g_Cvar_MinPlayers);

	if(playersOnServer >= minPlayers)
	{
		MC_PrintToChatAll("{white}Free \x07D147FFVIP {white}Giveaway is {green}enabled{white}.");
	}
	else
	{
		int playersNeeded = minPlayers - playersOnServer;

		MC_PrintToChatAll("{white}Free \x07D147FFVIP {white}Giveaway is {red}disabled{white}.\nPlayers on: {green}%d {white}| Players required: {green}%d {white}| Players needed: {green}+%d", playersOnServer, minPlayers, playersNeeded);
	}
}

void ChangeHostname()
{
	int playersOnServer = GetClientCount() - 1; // -1 cuz of sourcetv
	int minPlayers = GetConVarInt(g_Cvar_MinPlayers);
	char hostname[255];
	GetConVarString(g_Cvar_Hostname, hostname, sizeof(hostname));

	if(playersOnServer >= minPlayers)
	{
		ServerCommand("hostname %s [Free VIP: Active]", hostname);

		if(GetFreeNominationsTime())
			ServerCommand("hostname [FreeNoms] %s [Free VIP: Active]", hostname);

		if(GetDisableNominationsDay())
			ServerCommand("hostname [RandomNoms] %s [Free VIP: Active]", hostname);
	}
	else
	{
		int playersNeeded = minPlayers - playersOnServer;
		ServerCommand("hostname %s [Free VIP: +%d %s]", hostname, playersNeeded, (playersNeeded > 1) ? "players" : "player");

		if(GetFreeNominationsTime())
			ServerCommand("hostname [FreeNoms] %s [Free VIP: +%d %s]", hostname, playersNeeded, (playersNeeded > 1) ? "players" : "player");

		if(GetDisableNominationsDay())
			ServerCommand("hostname [RandomNoms] %s [Free VIP: +%d %s]", hostname, playersNeeded, (playersNeeded > 1) ? "players" : "player");
	}
}