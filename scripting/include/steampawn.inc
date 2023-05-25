/**
 * SteamPawn
 */
#if defined __steampawn_included
	#endinput
#endif

#define __steampawn_included

/**
 * Called when the Steam master servers report that the server is out of date.
 */
forward void SteamPawn_OnRestartRequested();

/**
 * Returns whether the game is connected to Steam.
 */
native bool SteamPawn_IsSteamConnected();

/**
 * Returns the "fake" IP address associated with the server for Steam Datagram Relay, or 0 if
 * not active.
 */
native int SteamPawn_GetSDRFakeIP();

/**
 * Returns the "fake" port associated with the server for Steam Datagram Relay.
 * 
 * @param num    Which port number to return.
 */
native int SteamPawn_GetSDRFakePort(int num);

public SharedPlugin __pl_steampawn = {
	name = "steampawn",
	file = "steampawn.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
