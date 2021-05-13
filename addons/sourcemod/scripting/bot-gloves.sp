#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "bot-gloves",
	author = "zer0.k",
	description = "",
	version = "1.0",
	url = "https://github.com/zer0k-z/bot_gloves"
};

// Variables

bool g_bEnableWorldModel = true;
KeyValues g_KVGloves;
int g_iCurrentGlove;
int g_iGloveType;
int g_iGlovePaint;
float g_fFloatValue = 0.000001;

// userinfo structure
#define PLAYER_INFO_LEN 344

enum 
{
	PlayerInfo_Version = 0,             // uint64
	PlayerInfo_XUID = 8,                // uint64
	PlayerInfo_Name = 16,               // char[128]
	PlayerInfo_UserID = 144,            // int
	PlayerInfo_SteamID = 148,           // char[33]
	PlayerInfo_AccountID = 184,         // int, also known as friendid
	PlayerInfo_FriendsName = 188,       // char[128]
	PlayerInfo_IsFakePlayer = 316,      // bool
	PlayerInfo_IsHLTV = 317,            // bool
	PlayerInfo_CustomFile1 = 320,       // uint32
	PlayerInfo_CustomFile2 = 324,       // uint32
	PlayerInfo_CustomFile3 = 328,       // uint32
	PlayerInfo_CustomFile4 = 332,       // uint32
	PlayerInfo_FilesDownloaded = 336    // char
};



public void OnPluginStart()
{
	RegConsoleCmd("sm_botglove", CommandBGlove, "Set gloves for bot");
	RegConsoleCmd("sm_botgloves", CommandBGlove, "Set gloves for bot");
	RegConsoleCmd("sm_botgloves_float", CommandBFloat, "Set float value for bot glove");
	RegConsoleCmd("sm_botgloves_worldmodel", CommandBToggleWorldModel, "Toggle world model visibility for bot gloves");

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
}

public Action CommandBGlove(int client, int args)
{
	if(client == 0)
	{
		return Plugin_Handled;
	}
	
	if(args != 0)
	{
		ReplyToCommand(client, "Usage: sm_bglove");
		return Plugin_Handled;
	}
	
	else
	{
		ShowMenu(client);
		return Plugin_Handled;
	}
}

void ShowMenu(int client)
{
	SetupGlovesKV();
	Menu menu = new Menu(Menu_Callback);		
	menu.SetTitle("Glove Selection");
	

	// Jump into the first subsection
	if (!g_KVGloves.GotoFirstSubKey())
	{
		delete g_KVGloves;
		return;
	}
	char buffer[32];
	do
	{
		g_KVGloves.GetSectionName(buffer, sizeof(buffer));
		menu.AddItem(buffer,buffer);
	} while (g_KVGloves.GotoNextKey());

 	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Callback(Menu menu, MenuAction action, int param1, int param2)
{	
	switch(action)
	{
		case MenuAction_Select:
		{
			char gloveType[32];
			menu.GetItem(param2, gloveType, sizeof(gloveType));
			SkinMenu(param1, gloveType);
		}		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
		}
		case MenuAction_End:
		{
			delete menu;
		}		
	}
	return 0;
}
public void SkinMenu(int client, char[] gloves)
{
	Menu skinMenu = new Menu(SkinMenu_Callback);		
	skinMenu.SetTitle("Skin Selection");	
	char buffer[32];
	g_KVGloves.Rewind();

	if (!g_KVGloves.JumpToKey(gloves))
	{
		delete g_KVGloves;
		return;
	}
	g_KVGloves.GetString("index", buffer, 32);
	g_iCurrentGlove = StringToInt(buffer);
	// Jump into the first subsection
	if (!g_KVGloves.GotoFirstSubKey())
	{
		PrintToChat(client, "cannot goto subkey");
		delete g_KVGloves;
		return;
	}
	do
	{
		g_KVGloves.GetSectionName(buffer, sizeof(buffer));
		skinMenu.AddItem(buffer,buffer);
	} while (g_KVGloves.GotoNextKey());
	skinMenu.ExitButton = true;
	skinMenu.Display(client, MENU_TIME_FOREVER);
	
}
public int SkinMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char skinType[32];
			menu.GetItem(param2, skinType, sizeof(skinType));
			char temp[32];
			g_KVGloves.GoBack();
			if (!g_KVGloves.JumpToKey(skinType))
			{
				delete g_KVGloves;
				return -1;
			}
			g_iGloveType = g_iCurrentGlove;
			g_KVGloves.GetString("index", temp, 32);
			g_iGlovePaint = StringToInt(temp);
		}		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public Action CommandBFloat(int client, int args)
{
	if (args < 1)
	{
		PrintToChat(client, "Usage: !bgloves_float <value>");
		return Plugin_Handled;
	}
	char arg[64];
	g_fFloatValue = StringToFloat(arg);
	return Plugin_Handled;
}

public Action CommandBToggleWorldModel(int client, int args)
{
	g_bEnableWorldModel = !g_bEnableWorldModel;
	return Plugin_Handled;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsFakeClient(client) == true && IsClientInGame(client) && IsClientConnected(client))
	{	
		LogMessage("%i, %i, %f", g_iGloveType, g_iGlovePaint, g_fFloatValue);
		// If there's no glove to set, skip this
		// Also fix a bug where the server tries to set gloves too early
		if (!g_iGloveType || !g_iGlovePaint)
		{
			return Plugin_Handled;
		}
		// Check if bot is in a valid team
		int botTeam = GetClientTeam(client);
		if (botTeam == CS_TEAM_CT || botTeam == CS_TEAM_T)
		{
			// Fix bots not being able to use gloves
			PatchBotData(client);

			// Give gloves to bot
			CreateTimer(0.05, GiveGloves, client);
		}
	}	
	return Plugin_Handled;
}

public void PatchBotData(int client)
{
	int tableIdx = FindStringTable("userinfo");

	if (tableIdx == INVALID_STRING_TABLE)
	{
		LogError("cannot find tableid!");		
	}

	char userInfo[PLAYER_INFO_LEN];

	if (!GetStringTableData(tableIdx, client - 1, userInfo, PLAYER_INFO_LEN))
	{
		LogError("cannot find string table data!");		
	}

	// Set bot name to its original name
	char clientName[128];		
	GetClientName(client, clientName, 128);
	Format(userInfo[PlayerInfo_Name], 128, "%s", clientName);

	// Set bot SteamID to its original value
	Format(userInfo[PlayerInfo_SteamID], 128, "BOT");

	// Set bot fakeplayer value to 0 so it can equip gloves
	userInfo[PlayerInfo_IsFakePlayer] = 0;

	// Set and lock stringtable
	bool lockTable = LockStringTables(false);
	SetStringTableData(tableIdx, client - 1, userInfo, PLAYER_INFO_LEN);
	LockStringTables(lockTable);
}

public Action GiveGloves(Handle timer, int client)
{
	if (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client))
	{
		int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		if(activeWeapon != -1)
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
		}

		GiveBotGloves(client);

		if(activeWeapon != -1)
		{
			DataPack dpack;
			CreateDataTimer(0.1, ResetGlovesTimer, dpack);
			dpack.WriteCell(client);
			dpack.WriteCell(activeWeapon);
		}
	}
}

public void GiveBotGloves(int client)
{
	// Kill previous wearables
	int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
	if(ent != -1)
	{
		AcceptEntityInput(ent, "KillHierarchy");
	}
	// Create wearable, set its properties, give it to bot
	ent = CreateEntityByName("wearable_item");
	if(ent != -1)
	{

		SetEntProp(ent, Prop_Send, "m_iItemIDLow", -1);		
		// Glove type
		SetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex", g_iGloveType);
		// Paint
		SetEntProp(ent, Prop_Send,  "m_nFallbackPaintKit", g_iGlovePaint);
		// Float
		SetEntPropFloat(ent, Prop_Send, "m_flFallbackWear", g_fFloatValue);	
		SetEntProp(ent, Prop_Send, "m_iAccountID", client);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);		
		SetEntPropEnt(ent, Prop_Data, "m_hParent", client);
		SetEntProp(ent, Prop_Send, "m_OriginalOwnerXuidHigh", 0);
		SetEntProp(ent, Prop_Send, "m_OriginalOwnerXuidLow", 0);
		
		SetEntProp(ent, Prop_Send, "m_bInitialized", 1);

		if (g_bEnableWorldModel)
		{
			SetEntPropEnt(ent, Prop_Data, "m_hMoveParent", client);
		}
		
		DispatchSpawn(ent);
		
		SetEntPropEnt(client, Prop_Send, "m_hMyWearables", ent);

		if(g_bEnableWorldModel) 
		{
			SetEntProp(client, Prop_Send, "m_nBody", 1);
		}
	}
}

public Action ResetGlovesTimer(Handle timer, DataPack pack)
{
	ResetPack(pack);
	int clientIndex = pack.ReadCell();
	int activeWeapon = pack.ReadCell();	
	SetEntPropEnt(clientIndex, Prop_Send, "m_hActiveWeapon", activeWeapon);	

	// Reset bot data so it appears on the scoreboard
	CreateTimer(0.25, ResetBotData, clientIndex);
}

public Action ResetBotData(Handle timer, int client)
{
	int tableIdx = FindStringTable("userinfo");

	if (tableIdx == INVALID_STRING_TABLE)
	{
		LogError("cannot find tableid!");		
	}

	char userInfo[PLAYER_INFO_LEN];

	if (!GetStringTableData(tableIdx, client - 1, userInfo, PLAYER_INFO_LEN))
	{
		LogError("cannot find string table data!");		
	}

	// Set bot name to its original name
	char clientName[128];
	GetClientName(client, clientName, 128);
	Format(userInfo[PlayerInfo_Name], 128, "%s", clientName);

	// Set bot SteamID to its original value
	Format(userInfo[PlayerInfo_SteamID], 128, "BOT");

	// Set bot fakeplayer value back to 1 to appear on the scoreboard
	userInfo[PlayerInfo_IsFakePlayer] = 1;

	// Set and lock stringtable
	bool lockTable = LockStringTables(false);
	SetStringTableData(tableIdx, client - 1, userInfo, PLAYER_INFO_LEN);
	LockStringTables(lockTable);
}


void SetupGlovesKV()
{
	g_KVGloves = new KeyValues("Gloves");
	g_KVGloves.ImportFromFile("addons/sourcemod/configs/bot_gloves/gloves.cfg");
}

