/*
	AMX Mod X Plugin: Admin Powers Menu
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
#include <cstrike>
#include <fun>
#include <hamsandwich>

#pragma semicolon 1

#if !defined MAX_PLAYERS
	#define MAX_PLAYERS 32
#endif

#if !defined Ham_CS_Player_ResetMaxSpeed
	#define Ham_CS_Player_ResetMaxSpeed Ham_Item_PreFrame
#endif

#define PLUGIN_VERSION "v1.0"

// Settings
#define ADMIN_FLAG ADMIN_CHAT

const Float:g_fMinGravity = 0.5;
const Float:g_fMaxSpeed = 500.0;

// End of settings

enum _:dData
{
	dNoclip,
	dGodMode,
	dGravity,
	dSpeed
}

new bool:g_bData[MAX_PLAYERS + 1][dData];

// Power Names
new const g_szData[dData][16] = { "Noclip", "GodMode", "Gravity", "Speed" };

// Weapons Max Speed data
new const Float:g_iWeaponsMaxSpeed[CSW_LAST_WEAPON + 1] =
{
	250.0,	// No weapon
	250.0,	// P228
	250.0,	// Glock
	260.0,	// Scout
	250.0,	// HeGrenade
	240.0,	// XM1014
	250.0,	// C4
	250.0,	// Mac 10
	240.0,	// Aug
	250.0,	// SmokeGreandae
	250.0,	// Elite
	250.0,	// FiveSeven
	250.0,	// UMP 45
	210.0,	// SG 550
	240.0,	// Galil
	240.0,	// Famas
	250.0,	// USP
	250.0, 	// Glock 18
	210.0,	// AWP
	250.0,	// MP5
	220.0,	// M249
	230.0,	// M3
	230.0,	// M4A1
	250.0,	// TMP
	210.0,	// G3SG1
	250.0,	// FlashBang
	250.0,	// Deagle
	235.0,	// SG552
	221.0,	// AK47
	250.0,	// Knife
	245.0	// P90
};

public plugin_init() {
	register_plugin("Power Menu",PLUGIN_VERSION,"Hyuna");

	register_saycmd("power","cmdPower",ADMIN_FLAG);

	RegisterHam(Ham_CS_Player_ResetMaxSpeed,"player","fw_HamResetMaxSpeedPre",0);
	RegisterHam(Ham_Spawn,"player","fw_HamPlayerSpawnPost",1);

	set_cvar_float("sv_maxspeed",g_fMaxSpeed);
}

public fw_HamResetMaxSpeedPre(client) {
	if (g_bData[client][dSpeed])
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public fw_HamPlayerSpawnPost(client) {
	static i;

	for (i = 0; i < dData; i++)
		g_bData[client][i] = false;
}

public cmdPower(client, level, cid) {
	if (!cmd_access(client,level,cid,2))
	{
		client_print(client,print_chat,"[AMXX] You don't have access to this command!");
		return PLUGIN_HANDLED;
	}

	if (!is_user_alive(client))
	{
		client_print(client,print_chat,"[AMXX] You must be alive to use this menu!");
		return PLUGIN_HANDLED;
	}

	return CreateMenu(client);
}

CreateMenu(client) {
	static some[256], iMenu;

	iMenu = menu_create("\d[\yAMXX\d] \wAdmin Power Menu","mHandler");

	formatex(some,charsmax(some),"\yNoclip - \d[ \r%s \d]",(g_bData[client][dNoclip] ? "ON":"OFF"));
	menu_additem(iMenu,some);

	formatex(some,charsmax(some),"\yGodMode - \d[ \r%s \d]",(g_bData[client][dGodMode] ? "ON":"OFF"));
	menu_additem(iMenu,some);

	formatex(some,charsmax(some),"\yGravity - \d[ \r%s \d]",(g_bData[client][dGravity] ? "ON":"OFF"));
	menu_additem(iMenu,some);

	formatex(some,charsmax(some),"\ySpeed - \d[ \r%s \d]",(g_bData[client][dSpeed] ? "ON":"OFF"));
	menu_additem(iMenu,some);

	menu_display(client,iMenu);

	return 1;
}

public mHandler(client, menu, item) {
	if (item == MENU_EXIT || !is_user_alive(client))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	g_bData[client][item] = !g_bData[client][item];

	switch(item)
	{
		case 0:	set_user_noclip(client,g_bData[client][dNoclip]);
		case 1:	set_user_godmode(client,g_bData[client][dGodMode]);
		case 2:	set_user_gravity(client,(g_bData[client][dGravity] ? g_fMinGravity:1.0));
		case 3:	set_user_maxspeed(client,(g_bData[client][dSpeed] ? g_fMaxSpeed:g_iWeaponsMaxSpeed[get_user_weapon(client)]));
	}

	client_print(client,print_chat,"[AMXX] You have %sabled %s.",(g_bData[client][item] ? "en":"dis"),g_szData[item]);

	menu_destroy(menu);

	return CreateMenu(client);
}

stock register_saycmd(const cmd[], const function[], access) {
    static const cmdsay[][] = { "say", "say_team" };
    static const marks[] = { '!', '/', '.' };
    static some[64], i, j;

    for (i = 0; i < 2; i++)
    {
        for (j = 0; j < 3; j++)
        {
            formatex(some,charsmax(some),"%s %c%s",cmdsay[i],marks[j],cmd,access);
            register_clcmd(some,function);
        }
    }
}
