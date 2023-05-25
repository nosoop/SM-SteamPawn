/**
 * SteamPawn
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdktools>
#include <dhooks>

#include <stocksoup/convars>
#include <stocksoup/memory>

#pragma newdecls required

#define PLUGIN_VERSION "1.1.0"
public Plugin myinfo = {
	name = "SteamPawn",
	author = "nosoop",
	description = "Some SteamWorks functionality.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-SteamPawn"
}

Handle g_SDKCallGetSteam3Server;
Handle g_SDKCallIsLoggedOn;

Handle g_DHookRestartRequested;

int g_nFakePorts;
Address g_pnFakeIP;
Address g_parFakePorts;

GlobalForward g_FwdRestartRequested;

public APLRes AskPluginLoad2(Handle hPlugin, bool late, char[] error, int maxlen) {
	RegPluginLibrary("steampawn");
	
	CreateNative("SteamPawn_IsSteamConnected", Native_IsSteamConnected);
	CreateNative("SteamPawn_GetSDRFakeIP", Native_GetSDRFakeIP);
	CreateNative("SteamPawn_GetSDRFakePort", Native_GetSDRFakePort);
	
	return APLRes_Success;
}

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("steampawn");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata (steampawn).");
	}
	
	g_DHookRestartRequested = DHookCreateFromConf(hGameConf,
			"ISteamGameServer::WasRestartRequested()");
	if (!g_DHookRestartRequested) {
		SetFailState("Failed to create virtual hook for "
				... "ISteamGameServer::WasRestartRequested()");
	}
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "Steam3Server()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallGetSteam3Server = EndPrepSDKCall();
	if (!g_SDKCallGetSteam3Server) {
		SetFailState("Failed to initialize SDKCall to Steam3Server");
	}
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "ISteamGameServer::BLoggedOn()");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_SDKCallIsLoggedOn = EndPrepSDKCall();
	if (!g_SDKCallIsLoggedOn) {
		SetFailState("Failed to initialize SDKCall to ISteamGameServer::BLoggedOn()");
	}
	
	g_pnFakeIP = GameConfGetAddress(hGameConf, "g_nFakeIP");
	g_parFakePorts = GameConfGetAddress(hGameConf, "g_arFakePorts");
	
	char strNumFakePorts[4];
	GameConfGetKeyValue(hGameConf, "NumFakePorts", strNumFakePorts, sizeof(strNumFakePorts));
	g_nFakePorts = StringToInt(strNumFakePorts);
	
	delete hGameConf;
	
	Address pSteamGameServer = GetSteamGameServer();
	if (!pSteamGameServer) {
		SetFailState("Failed to get SteamGameServer address");
	}
	DHookRaw(g_DHookRestartRequested, true, pSteamGameServer, .callback = OnRestartRequested);
	
	g_FwdRestartRequested = CreateGlobalForward("SteamPawn_OnRestartRequested", ET_Ignore);
	
	CreateVersionConVar("steampawn_version");
}

MRESReturn OnRestartRequested(Address pSteamGameServer, Handle hReturn) {
	bool bShouldRestart = !!DHookGetReturn(hReturn);
	if (bShouldRestart) {
		Call_StartForward(g_FwdRestartRequested);
		Call_Finish();
	}
}

int Native_IsSteamConnected(Handle plugin, int argc) {
	Address pSteamGameServer = GetSteamGameServer();
	if (!pSteamGameServer) {
		return false;
	}
	
	return !!SDKCall(g_SDKCallIsLoggedOn, pSteamGameServer);
}

int Native_GetSDRFakeIP(Handle plugin, int argc) {
	return GetSDRFakeIP();
}

int Native_GetSDRFakePort(Handle plugin, int argc) {
	int num = GetNativeCell(1);
	return GetSDRFakePort(num);
}

Address GetSteamGameServer() {
	Address pSteam3Server = SDKCall(g_SDKCallGetSteam3Server);
	if (!pSteam3Server) {
		return Address_Null;
	}
	return DereferencePointer(pSteam3Server + view_as<Address>(0x04));
}

int GetSDRFakeIP() {
	return LoadFromAddress(g_pnFakeIP, NumberType_Int32);
}

int GetSDRFakePort(int num) {
	if (num < 0 || num >= g_nFakePorts) {
		return 0;
	}
	return LoadFromAddress(g_parFakePorts + (num * 0x2), NumberType_Int16);
}
