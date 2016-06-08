/*
	AMX Mod X Plugin: Buy Admin
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

#if !defined MAX_PLAYERS
	#define MAX_PLAYERS 32
#endif

#define semicolon 1

enum _:AdminData
{
	aName[32],
	aCost
}

enum _:cData
{
	cAcc,
	cTime
}

#define cSkype "skypename"
#define cSteam "steamname"
#define cPhone "phonenumber"

#define MAX_BUY 5
#define MAX_TIME 12

#define PAYCALL

#if defined PAYCALL
new const Float:g_fPayCallOffset = 1.2;
#endif

new const g_aAdminData[MAX_BUY][AdminData] = {
	{ "VIP", 10 },
	{ "Admin", 30 },
	{ "Super Admin", 50 },
	{ "Manager", 70 },
	{ "Owner", 99 }
};

new g_bCounter[MAX_PLAYERS + 1][cData];

public plugin_init() {
	register_plugin("Buy Admin","v1.0","Hyuna");
	
	register_saycmd("buyadmin","ActionBuyAdmin");
}

public client_connect(client) {
	g_bCounter[client][cAcc] = 0;
	g_bCounter[client][cTime] = 0;
}

public ActionBuyAdmin(client) {
	static some[256], iMenu, iCallBack;
	iMenu = menu_create("Buy Admin","mHandler");
	iCallBack = menu_makecallback("mCallBack");
	
	formatex(some,charsmax(some),"Access Type: \d[ \r%s \d]",g_aAdminData[g_bCounter[client][cAcc]][aName]);
	menu_additem(iMenu,some);
	
	formatex(some,charsmax(some),"Time: \d[ \r%d Month%s \d]",(g_bCounter[client][cTime] + 1),(g_bCounter[client][cTime] == 0 ? "":"s"));
	menu_additem(iMenu,some);
	
	formatex(some,charsmax(some),"Cost: \d[ \r%d \yNIS \d]",(g_aAdminData[g_bCounter[client][cAcc]][aCost] * (g_bCounter[client][cTime] + 1)));
	menu_additem(iMenu,some,.callback=iCallBack);
	
	#if defined PAYCALL
	formatex(some,charsmax(some),"PayCall Cost: \d[ \r%d \yNIS \d]",floatround((g_aAdminData[g_bCounter[client][cAcc]][aCost] * (g_bCounter[client][cTime] + 1)) * g_fPayCallOffset));
	menu_additem(iMenu,some,.callback=iCallBack);
	#endif
	
	formatex(some,charsmax(some),"Phone: %s^nSteam: %s^nSkype: %s",cPhone,cSteam,cSkype);
	menu_addtext(iMenu,some);
	
	menu_display(client,iMenu);
	
	return PLUGIN_HANDLED;
}

public mCallBack(client, menu, item) {
	return ITEM_DISABLED;
}

public mHandler(client, menu, item) {
	switch (item)
	{
		case 0:
		{
			if (++g_bCounter[client][cAcc] == MAX_BUY)
				g_bCounter[client][cAcc] = 0;
		}
			
		case 1:
		{
			if (++g_bCounter[client][cTime] == MAX_TIME)
				g_bCounter[client][cTime] = 0;
		}
		
		case MENU_EXIT:
		{
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
	}
	
	menu_destroy(menu);
	return ActionBuyAdmin(client);
}

stock register_saycmd(const cmd[], const function[]) {
	static const cmdsay[][] = { "say", "say_team" };
	static const marks[] = { '!', '/', '.' };
	static some[64], i, j;
	
	for (i = 0; i < 2; i++)
	{
		for (j = 0; j < 3; j++)
		{
			formatex(some,charsmax(some),"%s %c%s",cmdsay[i],marks[j],cmd);
			register_clcmd(some,function);
		}
	}
}
