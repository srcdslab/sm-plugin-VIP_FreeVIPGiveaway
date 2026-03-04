#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <vip_core>
#include <multicolors>
#include <VIP_FreeVIPGiveaway>

#pragma newdecls required

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
		g_sVIPGroup[32],
		g_sTestVIPGroup[32],
 		g_sHostnamePrefix[256];

int
		g_iMinPlayers,
		g_iFreeVIPStart,
		g_iFreeVIPEnd;

Cookie g_hCookie;


public Plugin myinfo =
{
	name = "[VIP] Free VIP Giveaway",
	author = "inGame, maxime1907, Dolly",
	description = "Gives Free VIP for players that are active on server",
	version = "2.2.0"
};

public void OnPluginStart()
{
	g_Cvar_HostNamePrefix 		= CreateConVar("sm_freevip_hostname_prefix", "[Free VIP]", "Hostname prefix that will be displayed in server list");
	g_Cvar_MinPlayers 			= CreateConVar("sm_freevip_min_players", "0", "How many players should be on server to active Free VIP Giveaway. [-1 = Free VIP Disabled]", FCVAR_NONE, true, -1.0, true, float(MAXPLAYERS));
	g_Cvar_VIPGroup 			= CreateConVar("sm_freevip_group", "VIP", "What VIP group set on player");
	g_Cvar_FreeVIPStart			= CreateConVar("sm_freevip_timestamp_start", "1669849200", "TimeStamp of the time that free vip will start at!");
	g_Cvar_FreeVIPEnd 			= CreateConVar("sm_freevip_timestamp_end", "1672527600", "TimeStamp of the time that free vip will end at!");

	g_iMinPlayers = GetConVarInt(g_Cvar_MinPlayers);
	g_iFreeVIPStart = GetConVarInt(g_Cvar_FreeVIPStart);
	g_iFreeVIPEnd = GetConVarInt(g_Cvar_FreeVIPEnd);
	GetConVarString(g_Cvar_VIPGroup, g_sVIPGroup, sizeof(g_sVIPGroup));

	HookConVarChange(g_Cvar_MinPlayers, OnConVarChanged);
	HookConVarChange(g_Cvar_VIPGroup, OnConVarChanged);
	HookConVarChange(g_Cvar_FreeVIPStart, OnConVarChanged);
	HookConVarChange(g_Cvar_FreeVIPEnd, OnConVarChanged);

	g_Cvar_Hostname = FindConVar("hostname");

	g_hCookie = new Cookie("freevip_cookie", "Cookie to know who got his vip extended", CookieAccess_Protected);

	RegConsoleCmd("sm_freevip", Command_FreeVIP, "Display FreeVIP Giveaway status.");

	HookEvent("round_start", Event_RoundStart);

	AutoExecConfig();

	CreateTimer(2.0, CheckALLVIPPlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(20.5, Timer_ReloadVIPs, _, TIMER_FLAG_NO_MAPCHANGE);
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
	return g_iFreeVIPEnd;
}

int Native_GetStartTimeStamp(Handle plugin, int params)
{
	return g_iFreeVIPStart;
}

public void OnAllPluginsLoaded()
{
	g_Cvar_TestVIPGroup = FindConVar("sm_vip_test_group");
	GetConVarString(g_Cvar_TestVIPGroup, g_sTestVIPGroup, sizeof(g_sTestVIPGroup));
	HookConVarChange(g_Cvar_TestVIPGroup, OnConVarChanged);
}

public void OnConfigsExecuted()
{
	SetHostName();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!IsFreeVIPOn())
		return;

	if (g_iMinPlayers <= 0)
		return;

	int playersOnServer = GetRealPlayersOnServer();
	if (playersOnServer < g_iMinPlayers)
	{
		// remove temporary vip from players if not enough players
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || !VIP_IsClientVIP(i) || VIP_GetClientID(i) != -1 || VIP_GetClientVIPGroup(i, g_sTestVIPGroup, sizeof(g_sTestVIPGroup)))
				continue;

			VIP_RemoveClientVIP2(_, i, false, false);
		}

		CPrintToChatAll("{green}[SM] {pink}Free VIP Giveaway {default}is {red}disabled{default}.");
		CPrintToChatAll("{pink}Players on: {green}%d {pink}| Players required: {green}%d {pink}| Players needed: {red}+%d", playersOnServer, g_iMinPlayers, (g_iMinPlayers - playersOnServer));
		return;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsClientSourceTV(i) || IsFakeClient(i) || VIP_IsClientVIP(i))
			continue;

		VIP_GiveClientVIP(_, i, 0, g_sVIPGroup, false);
	}

	CPrintToChatAll("{green}[SM] {pink}Free VIP Giveaway is {green}enabled{pink}. Players got Free VIP.");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_Cvar_MinPlayers)
		g_iMinPlayers = GetConVarInt(convar);
	else if (convar == g_Cvar_VIPGroup)
		GetConVarString(g_Cvar_VIPGroup, g_sVIPGroup, sizeof(g_sVIPGroup));
	else if (convar == g_Cvar_TestVIPGroup)
		GetConVarString(g_Cvar_TestVIPGroup, g_sTestVIPGroup, sizeof(g_sTestVIPGroup));
	else if (convar == g_Cvar_FreeVIPStart)
		g_iFreeVIPStart = GetConVarInt(convar);
	else if (convar == g_Cvar_FreeVIPEnd)
		g_iFreeVIPEnd = GetConVarInt(convar);
}

public Action Timer_ReloadVIPs(Handle timer)
{
	ServerCommand("sm_reloadvips");
	return Plugin_Stop;
}

Action CheckALLVIPPlayers(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsClientAuthorized(i))
			continue;

		VIP_OnClientLoaded(i, (VIP_IsClientVIP(i)) ? true : false);
	}

	return Plugin_Stop;
}

public void VIP_OnClientLoaded(int client, bool isVIP)
{
	if (!IsFreeVIPOn())
	{
		char cookieValue[6];
		g_hCookie.Get(client, cookieValue, sizeof(cookieValue));
		/* Set cookie to false in all clients when vip ends */
		if (StrEqual(cookieValue, "true"))
			g_hCookie.Set(client, "false");

		return;
	}

	if (IsClientSourceTV(client) || IsFakeClient(client))
		return;

	if (!IsClientAuthorized(client))
		return;

	GiveVIP(client);
}

void GiveVIP(int client)
{
	if (client < 1)
		return;

	if (VIP_IsClientVIP(client))
	{
		SetVIP(client);
		return;
	}

	VIP_GiveClientVIP(_, client, 0, g_sVIPGroup, false);
}

void SetVIP(int client)
{
	if (client < 1)
		return;

	if (!AreClientCookiesCached(client))
		return;

	bool canGetVIP;
	char cookieValue[6];
	g_hCookie.Get(client, cookieValue, sizeof(cookieValue));
	if (StrEqual(cookieValue, "true"))
		canGetVIP = false;
	else
		canGetVIP = true;

	if (!VIP_IsClientVIP(client) || VIP_GetClientID(client) == -1 || VIP_GetClientAccessTime(client) == 0)
		return;

	if (!canGetVIP)
		return;

	int seconds = (g_iFreeVIPEnd - GetTime());
	int originalExpireTimeStamp = VIP_GetClientAccessTime(client);
	int newExpireTimeStamp = (originalExpireTimeStamp + seconds);
	VIP_SetClientAccessTime(client, newExpireTimeStamp, true);
	g_hCookie.Set(client, "true");
	return;
}

public void OnClientDisconnect(int client)
{
	if (IsClientSourceTV(client) || IsFakeClient(client))
		return;

	if (!VIP_IsClientVIP(client) || VIP_GetClientID(client) != -1 || VIP_GetClientVIPGroup(client, g_sTestVIPGroup, sizeof(g_sTestVIPGroup)))
		return;

	VIP_RemoveClientVIP2(_, client, false, false);
}

Action Command_FreeVIP(int client, int args)
{
	if (!IsFreeVIPOn())
	{
		CReplyToCommand(client, "{green}[SM] {pink}Free VIP Giveaway {default}is {red}disabled{default}.");
		return Plugin_Handled;
	}

	int playersOnServer = GetRealPlayersOnServer();
	if (playersOnServer < g_iMinPlayers)
	{
		CReplyToCommand(client, "{green}[SM] {pink}Free VIP Giveaway {default}is {red}disabled{default}.");
		CReplyToCommand(client, "{pink}Players on: {green}%d {pink}| Players required: {green}%d {pink}| Players needed: {red}+%d", playersOnServer, g_iMinPlayers, (g_iMinPlayers - playersOnServer));
		return Plugin_Handled;
	}

	CReplyToCommand(client, "{green}[SM] {pink}Free VIP Giveaway is {green}enabled{pink}. {green}Players got Free VIP.");
	return Plugin_Handled;
}

void SetHostName()
{
	int iTime = GetTime();
	if (g_iFreeVIPStart > iTime || g_iFreeVIPEnd < iTime)
		return;

	g_Cvar_HostNamePrefix.GetString(g_sHostnamePrefix, sizeof(g_sHostnamePrefix));
	g_Cvar_Hostname.GetString(g_sHostname, sizeof(g_sHostname));

	if (StrContains(g_sHostname, g_sHostnamePrefix, true) == -1)
		ServerCommand("hostname %s %s", g_sHostnamePrefix, g_sHostname);
}

bool IsFreeVIPOn()
{
	int iTime = GetTime();
	if (g_iFreeVIPStart > iTime || g_iFreeVIPEnd < iTime || g_iMinPlayers < 0)
		return false;

	return true;
}

stock int GetRealPlayersOnServer()
{
	int playersOnServer = GetClientCount();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i))
			continue;

		if (IsClientSourceTV(i))
			playersOnServer--;
	}

	return playersOnServer;
}