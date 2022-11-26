#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <cstrike>
#include <vip_core>
#include <multicolors>
#include <VIP_FreeVIPGiveaway>

#pragma newdecls required

//ConVar g_Cvar_Duration;

/* CONVARS */
ConVar 
		g_Cvar_MinPlayers,
		g_Cvar_VIPGroup,
 		g_Cvar_TestVIPGroup,
 		g_Cvar_Hostname,
 		g_Cvar_HostNamePrefix,
 		g_Cvar_FreeVIPStart,
 		g_Cvar_FreeVIPEnd;

char 
		g_sHostname[256],
 		g_sHostnamePrefix[256];
 		
Cookie g_hCookie;

public Plugin myinfo =
{
	name = "[VIP] Free VIP Giveaway",
	author = "inGame, maxime1907, Dolly",
	description = "Gives Free VIP for players that are active on server",
	version = "2.1"
};

public void OnPluginStart()
{
	g_Cvar_HostNamePrefix 			= CreateConVar("sm_freevip_hostname_prefix", "[Free VIP]", "Hostname prefix that will be displayed in server list");
	g_Cvar_MinPlayers 			= CreateConVar("sm_freevip_min_players", "0", "How many players should be on server to active Free VIP Giveaway. [0 = OnClientPostAdminCheck, 1-255 = OnRoundEnd]", FCVAR_NONE, true, 0.0, true, float(MAXPLAYERS));
	// g_Cvar_Duration = CreateConVar("sm_freevip_duration", "0", "For how many mins give Free VIP. [0 = Unlimited, 1-60 = minutes]", FCVAR_NONE, true, 0.0, true, 60.0);
	g_Cvar_VIPGroup 			= CreateConVar("sm_freevip_group", "VIP", "What VIP group set on player");
	g_Cvar_FreeVIPStart			= CreateConVar("sm_freevip_timestamp_start", "1669849200", "TimeStamp of the time that free vip will start at!");
	g_Cvar_FreeVIPEnd 			= CreateConVar("sm_freevip_timestamp_end", "1672527600", "TimeStamp of the time that free vip will end at!");

	g_Cvar_Hostname = FindConVar("hostname");

	g_hCookie = new Cookie("freevip_cookie", "Cookie to know who got his vip extended", CookieAccess_Public);
	
	RegConsoleCmd("sm_freevip", Command_FreeVIP, "Display FreeVIP Giveaway status.");

	HookEvent("round_start", Event_RoundStart);

	AutoExecConfig();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		if(!IsClientAuthorized(i))
			continue;
		
		VIP_OnClientLoaded(i, (VIP_IsClientVIP(i)) ? true : false);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool bLate, char[] sError, int Err_max)
{
	RegPluginLibrary("VIP_FreeVIPGiveaway");
	
	CreateNative("FreeVIP_IsFreeVIPOn", Native_IsFreeVIPOn);
	CreateNative("FreeVIP_GetEndTimeStamp", Native_GetEndTimeStamp);
	CreateNative("FreeVIP_GetStartTimeStamp", Native_GetStartTimeStamp);
	
	return APLRes_Success;
}

int Native_IsFreeVIPOn(Handle plugin, int params)
{
	return (IsFreeVIPOn());
}

int Native_GetEndTimeStamp(Handle plugin, int params)
{
	return g_Cvar_FreeVIPEnd.IntValue;
}

int Native_GetStartTimeStamp(Handle plugin, int params)
{
	return g_Cvar_FreeVIPStart.IntValue;
}

public void OnAllPluginsLoaded()
{
	g_Cvar_TestVIPGroup = FindConVar("sm_vip_test_group");
}

public void OnConfigsExecuted()
{
	SetHostName();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int freeVIPStart = g_Cvar_FreeVIPStart.IntValue;
	int freeVipEnd = g_Cvar_FreeVIPEnd.IntValue;

	if(freeVIPStart > GetTime())
		return;

	if(freeVipEnd < GetTime())
		return;

	int minPlayers = g_Cvar_MinPlayers.IntValue;
	//int duration = GetConVarInt(g_Cvar_Duration);

	if(minPlayers <= 0)
		return;

	char vipGroup[16];
	g_Cvar_VIPGroup.GetString(vipGroup, sizeof(vipGroup));

	char hostname[255];
	g_Cvar_Hostname.GetString(hostname, sizeof(hostname));

	// if min players amount reached
	int playersOnServer = GetClientCount();
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i <= 0 || i > MaxClients || !IsClientConnected(i))
			continue;

		if (IsClientSourceTV(i))
			playersOnServer = playersOnServer  - 1; // -1 cuz of sourcetv
	}

	if(playersOnServer >= minPlayers)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i))
				continue;

			if(GetClientTeam(i) == CS_TEAM_SPECTATOR || GetClientTeam(i) == CS_TEAM_NONE)
			{
				/* if player has vip and his vip is temporary and he is in spec - remove vip */
				if(VIP_IsClientVIP(i) && VIP_GetClientID(i) == -1)
					VIP_RemoveClientVIP2(_, i, false, false);

				continue;
			} 

			if(VIP_IsClientVIP(i))
				continue;

			VIP_GiveClientVIP(_, i, 0, vipGroup, false);
		}

		// push chat message
		CPrintToChatAll("[SM] {pink}Free VIP Giveaway {default}is {green}enabled{default}. {pink}Active players got Free VIP.");
	}
	else
	{
		char testVipGroup[16];
		g_Cvar_TestVIPGroup.GetString(testVipGroup, sizeof(testVipGroup));

		// remove temporary vip from players if not enough players
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || IsFakeClient(i) || !VIP_IsClientVIP(i) || VIP_GetClientID(i) != -1 || VIP_GetClientVIPGroup(i, testVipGroup, sizeof(testVipGroup)))
				continue;

			VIP_RemoveClientVIP2(_, i, false, false);
		}

		int playersNeeded = minPlayers - playersOnServer;

		// push chat message
		CPrintToChatAll("{green}[SM] {pink}Free VIP Giveaway {default}is {red}disabled{default}.\nPlayers on: {green}%d {default}| Players required: {green}%d {default}| Players needed: {green}+%d", playersOnServer, minPlayers, playersNeeded);
	}
}

public void VIP_OnClientLoaded(int client)
{
	if(!IsFreeVIPOn())
	{
		char cookieValue[6];
		g_hCookie.Get(client, cookieValue, sizeof(cookieValue));
		/* Set cookie to false in all clients when vip ends */
		if(StrEqual(cookieValue, "true"))
			g_hCookie.Set(client, "false");
			
		return;
	}
		
	if(IsClientSourceTV(client) || IsFakeClient(client))
		return;
		
	if(!IsClientAuthorized(client))
		return;
	
	GiveVIP(client);
}

void GiveVIP(int client)
{
	if(!IsFreeVIPOn())
		return;
		
	if(client < 1)
		return;

	if(VIP_IsClientVIP(client))
	{
		SetVIP(client);
		return;
	}
		
	char vipGroup[16];
	g_Cvar_VIPGroup.GetString(vipGroup, sizeof(vipGroup));
	VIP_GiveClientVIP(_, client, 0, vipGroup, false);
	/* Give client the vip flags */
	int flags = GetUserFlagBits(client);
	if(!(flags & ADMFLAG_CUSTOM1))
		SetUserFlagBits(client, flags | ADMFLAG_CUSTOM1);
}

void SetVIP(int client)
{
	if(!IsFreeVIPOn())
		return;
		
	if(client < 1)
		return;

	if(!AreClientCookiesCached(client))
		return;
		
	bool canGetVIP;
	char cookieValue[6];
	g_hCookie.Get(client, cookieValue, sizeof(cookieValue));
	if(StrEqual(cookieValue, "true"))
		canGetVIP = false;
	else
		canGetVIP = true;

	if(!VIP_IsClientVIP(client) || VIP_GetClientID(client) == -1 || VIP_GetClientAccessTime(client) == 0)
		return;
	
	if(!canGetVIP)
		return;
		
	char vipGroup[16];
	g_Cvar_VIPGroup.GetString(vipGroup, sizeof(vipGroup));
	
	int freeVipEnd = g_Cvar_FreeVIPEnd.IntValue;		
	int seconds = (freeVipEnd - GetTime());
	int originalExpireTimeStamp = VIP_GetClientAccessTime(client);
	int newExpireTimeStamp = (originalExpireTimeStamp + seconds);
	VIP_SetClientAccessTime(client, newExpireTimeStamp, true);
	g_hCookie.Set(client, "true");
	return;
}

public void OnClientDisconnect(int client)
{
	if(IsClientSourceTV(client) || IsFakeClient(client))
		return;

	char testVipGroup[16];
	g_Cvar_TestVIPGroup.GetString(testVipGroup, sizeof(testVipGroup));

	if(!VIP_IsClientVIP(client) || VIP_GetClientID(client) != -1 || VIP_GetClientVIPGroup(client, testVipGroup, sizeof(testVipGroup)))
		return;

	VIP_RemoveClientVIP2(_, client, false, false);
}

Action Command_FreeVIP(int client, int args)
{
	int playersOnServer = GetClientCount();
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i <= 0 || i > MaxClients || !IsClientConnected(i))
			continue;

		if (IsClientSourceTV(i))
			playersOnServer = playersOnServer  - 1; // -1 cuz of sourcetv
	}
	int minPlayers = g_Cvar_MinPlayers.IntValue;
	int freeVIPStart = g_Cvar_FreeVIPStart.IntValue;
	int freeVipEnd = g_Cvar_FreeVIPEnd.IntValue;

	if(freeVIPStart > GetTime() || freeVipEnd < GetTime())
	{
		CReplyToCommand(client, "{green}[SM] {pink}Free VIP Giveaway {default}is {red}disabled{default}.");
		return Plugin_Handled;
	}

	if (playersOnServer >= minPlayers)
	{
		CReplyToCommand(client, "{green}[SM] {pink}Free VIP Giveaway {default}is {green}enabled{default}.");
		return Plugin_Handled;
	}
	else
	{
		int playersNeeded = minPlayers - playersOnServer;

		CReplyToCommand(client, "{green}[SM] {pink}Free VIP Giveaway {default}is {red}disabled{default}.\nPlayers on: {green}%d {default}| Players required: {green}%d {default}| Players needed: {green}+%d", playersOnServer, minPlayers, playersNeeded);
		return Plugin_Handled;
	}
}

void SetHostName()
{
	int freeVIPStart = g_Cvar_FreeVIPStart.IntValue;
	int freeVipEnd = g_Cvar_FreeVIPEnd.IntValue;

	if(freeVIPStart > GetTime())
		return;

	if(freeVipEnd < GetTime())
		return;

	g_Cvar_HostNamePrefix.GetString(g_sHostnamePrefix, sizeof(g_sHostnamePrefix));
	g_Cvar_Hostname.GetString(g_sHostname, sizeof(g_sHostname));

	if (StrContains(g_sHostname, g_sHostnamePrefix, true) == -1)
		ServerCommand("hostname %s %s", g_sHostnamePrefix, g_sHostname);
}

bool IsFreeVIPOn()
{
	int freeVIPStart = g_Cvar_FreeVIPStart.IntValue;
	int freeVipEnd = g_Cvar_FreeVIPEnd.IntValue;

	if(freeVIPStart > GetTime())
		return false;

	if(freeVipEnd < GetTime())
		return false;

	if(g_Cvar_MinPlayers.IntValue != 0)
		return false;
		
	return true;
}
