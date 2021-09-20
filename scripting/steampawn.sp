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

GlobalForward g_FwdRestartRequested;

public APLRes AskPluginLoad2(Handle hPlugin, bool late, char[] error, int maxlen) {
	RegPluginLibrary("steampawn");
	
	CreateNative("SteamPawn_IsSteamConnected", Native_IsSteamConnected);
	
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
	
	delete hGameConf;
	
	Address pSteam3Server = GetSteamGameServer();
	if (!pSteam3Server) {
		SetFailState("Failed to get SteamGameServer address");
	}
	DHookRaw(g_DHookRestartRequested, true, pSteam3Server, .callback = OnRestartRequested);
	
	g_FwdRestartRequested = CreateGlobalForward("SteamPawn_OnRestartRequested", ET_Ignore);
	
	CreateVersionConVar("steampawn_version");
}

MRESReturn OnRestartRequested(Address pSteam3Server, Handle hReturn) {
	bool bShouldRestart = !!DHookGetReturn(hReturn);
	if (bShouldRestart) {
		Call_StartForward(g_FwdRestartRequested);
		Call_Finish();
	}
}

int Native_IsSteamConnected(Handle plugin, int argc) {
	Address pSteam3Server = GetSteamGameServer();
	if (!pSteam3Server) {
		return false;
	}
	
	return !!SDKCall(g_SDKCallIsLoggedOn, pSteam3Server);
}

Address GetSteamGameServer() {
	Address pSteam3Server = SDKCall(g_SDKCallGetSteam3Server);
	if (!pSteam3Server) {
		return Address_Null;
	}
	return DereferencePointer(pSteam3Server + view_as<Address>(0x04));
}
