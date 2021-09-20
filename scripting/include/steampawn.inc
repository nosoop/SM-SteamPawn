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

public SharedPlugin __pl_steampawn = {
	name = "steampawn",
	file = "steampawn.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
