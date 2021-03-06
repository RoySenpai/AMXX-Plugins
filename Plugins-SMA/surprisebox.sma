/*

****** Information ******

* Plugin Name: Surprise Box
* Plugin Descption: Drop a Surprise Box from killed players.
* Plugin Version: 1.2.2
* Plugin Creator: Hyuna aka NorToN
* Creator URL: http://steamcommunity.com/id/KissMyAsscom
* License: GNU GPL v3 (see below)


****** Requirements ******

* Amx Mod X v1.8.3+
* Modules: Fakemeta, HamSandwich


****** Commands ******

* amx_purgeboxes - Deletes all Surprise Boxes.


****** Cvars ******

* amx_sboxversion - Shows plugin version.


****** Natives ******

* is_client_onboxmenu(client) - Returns if a selected client is in the select menu.
* client_forceboxmenu(client) - Force showing surprise box menu to a selected client.
* create_surprisebox(Float:origin[3]) - Makes a surprise box with given origin. Returns ent id if success or -1 if failed (too much boxes/can't create).
* remove_surprisebox(iEnt) - Removes a given surprise box entity. Returns 1 on success, 0 if the ent isn't surprise box or throwing an error when entity isn't valid.
* purge_surpriseboxes() - Deletes all supply boxes, if there are. Returns 1 on success or 0 if no box entities found.
* get_surprisebox_count() - Returns current surprise box count (It just returns g_iEntCount value).


****** Forwards ******

* OnClientAttempOpenBox(client) - Called when a player attemps open a box. return PLUGIN_HANDLED to block.
* OnClientTouchBox(client, iEnt) - Called when a player touches a box. return PLUGIN_HANDLED to block.


****** Includes ******

* #include <amxmodx>
* #include <amxmisc>
* #include <fakemeta>
* #include <hamsandwich>
* #include <surprisebox>


****** Change Log ******

* V 1.0 - First Public Release.

* V 1.1 - Added OnClientOpenBox forward.
* Added OnClientTouchBox forward.
* Added is_client_onboxmenu native.

* V 1.2 - Added create_surprisebox native.
* Added client_forceboxmenu native.
* Added purge_surpriseboxes native.
* Added get_surprisebox_count native.
* Added get_surprisebox_maxcount native.
* Updated API: Now the plugin has an official include.

* V 1.2.1 - Small fixes

* V 1.2.2 - Added remove_surprisebox native.


****** Credits ******

* Roy [NorToN aka Hyuna] - Plugin Creator.


*/

// License:
/*
	AMX Mod X Plugin: Surprise Box
	Copyright (C) 2016  Hyuna aka NorToN

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <surprisebox>

#pragma semicolon 1

#if AMXX_VERSION_NUM < 183
	#assert Amx Mod X Version 1.83 and above is needed to run this plugin!
#endif

#define PLUGIN_VERSION "v1.2.2"

#define PREFIX "[ ^4AMXX^1 ]"

// Entity Size
new Float:g_iEntMax[3] = { 5.0, 5.0, 5.0 };
new Float:g_iEntMin[3] = { -2.0, -2.0, -2.0 };

// Model
new g_szModel[] = "models/w_surprisebox.mdl";
new g_szSurpriseBoxClassname[] = "ent_surprisebox";

new g_iMenu;

new g_iEntCount;

new g_iForwardOnAttemp, g_iForwardOnTouch;

new bool:g_bIsInMenu[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("Surprise Box",PLUGIN_VERSION,"Hyuna");

	create_cvar("amx_sboxversion",PLUGIN_VERSION,(FCVAR_SERVER | FCVAR_SPONLY | FCVAR_PRINTABLEONLY),"Shows the plugin version.");

	register_concmd("amx_purgeboxes","cmdPurgeBoxes",ADMIN_RCON,"- Deletes all Surprise Boxes");

	RegisterHam(Ham_Touch,"info_target","fw_HamEntityTouchPost",1);
	RegisterHamPlayer(Ham_Spawn,"fw_HamPlayerSpawnPost",1);
	RegisterHamPlayer(Ham_Killed,"fw_HamPlayerKilledPost",1);

	register_event("HLTV","fw_eventNewRound","a","1=0","2=0");

	g_iForwardOnAttemp = CreateMultiForward("OnClientAttempOpenBox",ET_STOP,FP_CELL);
	g_iForwardOnTouch = CreateMultiForward("OnClientTouchBox",ET_STOP,FP_CELL,FP_CELL);

	if (g_iForwardOnAttemp == INVALID_HANDLE)
		set_fail_state("Failed to create OnClientAttempOpenBox forward");

	if (g_iForwardOnTouch == INVALID_HANDLE)
		set_fail_state("Failed to create OnClientTouchBox forward");
}

public plugin_precache() {
	if (!file_exists(g_szModel))
	{
		// Safe fail check
		log_amx("ERROR: File not found (%s)",g_szModel);
		set_fail_state("FATAL ERROR: Failed to find Surprise Box model.");
	}

	precache_model(g_szModel);
}

public plugin_natives() {
	// Library
	register_library("SurpriseBox");

	// Natives
	register_native("is_client_onboxmenu","native_is_client_onboxmenu",0);
	register_native("client_forceboxmenu","native_client_forceboxmenu",0);
	register_native("create_surprisebox","native_create_surprisebox",0);
	register_native("remove_surprisebox","native_remove_surprisebox",0);
	register_native("purge_surpriseboxes","native_purge_surpriseboxes",0);
	register_native("get_surprisebox_count","native_get_surprisebox_count",0);
}

public native_is_client_onboxmenu(pluginid, params) {
	static client;
	client = get_param(1);

	if (!is_user_connected(client))
	{
		log_error(AMX_ERR_NATIVE,"[Suprise Box API] ERROR: Client %d is invalid.",client);
		return false;
	}

	return g_bIsInMenu[client];
}

public native_client_forceboxmenu(pluginid, params) {
	static client;
	client = get_param(1);

	if (!is_user_connected(client))
	{
		log_error(AMX_ERR_NATIVE,"[Suprise Box API] ERROR: Client %d is invalid.",client);
		return 0;
	}

	if (is_user_bot(client) || is_user_hltv(client))
		return -1;

	menu_display(client,g_iMenu);

	return 1;
}

public native_create_surprisebox(pluginid, params) {
	static Float:fOrigin[3], ent;
	get_array_f(1,fOrigin,charsmax(fOrigin));

	if (g_iEntCount == MAX_BOX_ENTITES)
		return INVALID_HANDLE;

	ent = CreateSupplyBox(fOrigin,true);

	if (!pev_valid(ent))
		return INVALID_HANDLE;

	return ent;
}

public native_remove_surprisebox(pluginid, params) {
	static entid, szClassname[32];

	entid = get_param(1);

	if (!pev_valid(entid))
	{
		log_error(AMX_ERR_NATIVE,"[Suprise Box API] ERROR: Invalid entity ID %d",entid);
		return 0;
	}

	pev(entid,pev_classname,szClassname,charsmax(szClassname));

	if (!equal(szClassname,g_szSurpriseBoxClassname))
		return 0;

	engfunc(EngFunc_RemoveEntity,entid);
	g_iEntCount--;

	return 1;
}

public native_purge_surpriseboxes(pluginid, params) {
	if (!g_iEntCount)
		return 0;

	PurgeBoxEntities();

	return 1;
}

public native_get_surprisebox_count(pluginid, params) {
	return g_iEntCount;
}

public plugin_cfg() {
	g_iMenu = menu_create("\d[ \rAMXX \d] \yYou have picked a Surprise Box. ^nDo you want to open it?","mHandler");
	menu_additem(g_iMenu,"Yes");
	menu_additem(g_iMenu,"No");

	menu_setprop(g_iMenu,MPROP_EXIT,MEXIT_NEVER);
}

public plugin_end() {
	// Prevent AMXX memory leak
	DestroyForward(g_iForwardOnAttemp);
	DestroyForward(g_iForwardOnTouch);
}

public cmdPurgeBoxes(client,level,cid) {
	static szName[32], szAuthid[32];

	if (!cmd_access(client,level,cid,1))
		return PLUGIN_HANDLED;

	if (!g_iEntCount)
	{
		if (client)
			client_print_color(client,print_team_red,"%s There ^3aren't^1 any surprise box entites to purge.",PREFIX);

		return PLUGIN_HANDLED;
	}

	PurgeBoxEntities();

	if (client)
	{
		get_user_name(client,szName,charsmax(szName));
		get_user_authid(client,szAuthid,charsmax(szAuthid));

		log_amx("Cmd: ^"%s<%d><%s><>^" purged all Surprise Box entites.",szName,get_user_userid(client),szAuthid);
		client_print_color(0,client,"%s ^4ADMIN ^3%s^1 has purged all surprise box entites.",PREFIX,szName);
	}

	else
	{
		log_amx("Server Cmd: Purge all Surprise Box entites.");
		client_print_color(0,print_team_default," %s ^4Server^1 has purged all surprise box entites.",PREFIX);
	}

	return PLUGIN_HANDLED;
}

public fw_eventNewRound() {
	PurgeBoxEntities();
}

public fw_HamPlayerSpawnPost(client) {
	if (!is_user_alive(client))
		return;

	if (g_bIsInMenu[client])
	{
		menu_cancel(client);
		reset_menu(client);

		g_bIsInMenu[client] = false;
	}
}

public fw_HamPlayerKilledPost(idvictim, idattacker, bool:shouldgib) {
	static Float:fOrigin[3];

	if (!is_user_connected(idvictim))
		return;

	pev(idvictim,pev_origin,fOrigin);

	CreateSupplyBox(fOrigin,false);
}

public fw_HamEntityTouchPost(iEnt, idother) {
	static szClassname[32], ret;

	if (!is_user_alive(idother) || !pev_valid(iEnt))
		return;

	pev(iEnt,pev_classname,szClassname,charsmax(szClassname));

	if (!equal(szClassname,g_szSurpriseBoxClassname))
		return;

	ExecuteForward(g_iForwardOnTouch,ret,idother,iEnt);

	if (ret == PLUGIN_HANDLED)
		return;

	if (g_bIsInMenu[idother])
		return;

	engfunc(EngFunc_RemoveEntity,iEnt);
	g_iEntCount--;

	menu_cancel(idother);
	reset_menu(idother);
	menu_display(idother,g_iMenu);

	g_bIsInMenu[idother] = true;
}

public mHandler(client, menu, item) {
	static szName[32], ret;

	if (item == 0)
	{
		ExecuteForward(g_iForwardOnAttemp,ret,client);

		if (ret == PLUGIN_HANDLED)
		{
			g_bIsInMenu[client] = false;
			return PLUGIN_HANDLED;
		}

		if (is_user_alive(client))
		{
			get_user_name(client,szName,charsmax(szName));

			switch(random(100))
			{
				case 0..19:	// 20% chance
				{
					client_print_color(client,print_team_default,"%s You opened the box and got ^4XXXXX^1.",PREFIX);
					client_print_color(0,client,"%s ^3%s^1 opened a ^4Surprise Box^1, and got ^4XXXXX^1.",PREFIX,szName);
				}

				case 20..39: // 20% chance
				{
					client_print_color(client,print_team_default,"%s You opened the box and got ^4YYYYY^1.",PREFIX);
					client_print_color(0,client,"%s ^3%s^1 opened a ^4Surprise Box^1, and got ^4YYYYY^1.",PREFIX,szName);
				}

				case 40..59: // 20% chance
				{
					client_print_color(client,print_team_default,"%s You opened the box and got ^4ZZZZZ^1.",PREFIX);
					client_print_color(0,client,"%s ^3%s^1 opened a ^4Surprise Box^1, and got ^4ZZZZZ^1.",PREFIX,szName);
				}

				case 60..99: // 40% chance
				{
					client_print_color(client,print_team_red,"%s Sorry, but the box is ^3empty^1! Try next time.",PREFIX);
					client_print_color(0,client,"%s ^3%s^1 opened a ^4Surprise Box^1, but it was ^4empty^1.",PREFIX,szName);
				}
			}
		}

		else
			client_print_color(client,print_team_default,"%s You must be ^4alive^1 to open a surprise box.",PREFIX);
	}

	else
		client_print_color(client,print_team_red,"%s You choosed ^3not^1 to open the box. It has been ^3destroyed^1.",PREFIX);

	g_bIsInMenu[client] = false;

	return PLUGIN_HANDLED;
}

CreateSupplyBox(Float:origin[3], bool:isnative) {
	if (!isnative)
	{
		if (g_iEntCount == MAX_BOX_ENTITES)
		{
			log_amx("Warning: Max box entites reached (%d). Plugin won't create new box entites until it will purge.",MAX_BOX_ENTITES);
			log_amx("Use amx_purgeboxes command to purge all boxes.");
			client_print_color(0,print_team_red,"%s ^3WARNING:^1 Max surprise box entities reached (^4%d^1), need a purge!",PREFIX,MAX_BOX_ENTITES);

			return -1;
		}
	}

	new iEnt = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"));

	if (!pev_valid(iEnt))
	{
		if (!isnative)
			set_fail_state("Error creating surprise box entity");

		return -1;
	}

	// Set classname
	set_pev(iEnt,pev_classname,g_szSurpriseBoxClassname);

	// Set Surprise Box origin
	engfunc(EngFunc_SetOrigin,iEnt,origin);

	// Set Surprise Box model
	engfunc(EngFunc_SetModel,iEnt,g_szModel);

	// Set soild state so players can touch the box
	set_pev(iEnt,pev_solid,SOLID_BBOX);

	// Set the box's size
	engfunc(EngFunc_SetSize,iEnt,g_iEntMin,g_iEntMax);

	// Drop box to floor
	engfunc(EngFunc_DropToFloor,iEnt);

	g_iEntCount++;

	return iEnt;
}

PurgeBoxEntities() {
	new ent = -1;

	while ((ent = engfunc(EngFunc_FindEntityByString,ent,"classname",g_szSurpriseBoxClassname)) > 0)
	{
		if (pev_valid(ent))
			engfunc(EngFunc_RemoveEntity,ent);
	}

	g_iEntCount = 0;
}
