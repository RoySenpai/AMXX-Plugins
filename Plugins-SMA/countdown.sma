/*
	  AMX Mod X Plugin: Countdown menu for JailBreak
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
#include <cstrike>
#include <fakemeta>

#if AMXX_VERSION_NUM < 183
	#assert Amx Mod X Version 1.83 and above is needed to run this plugin!
#endif

#define semicolon 1

#define MAX_TEAMS 4
#define MAX_SOUNDS 3

#define PREFIX "^3[ ^4JailBreak ^1]"

#define MAX_SEC 60
#define MIN_SEC 5
#define SEC_STEP 5

#define ADMIN_ACCESS ADMIN_BAN

#define TASKID_CD 1337

new const g_sTeamNames[MAX_TEAMS] [] = {
	"None",
  "Terrorist",
  "Counter Terrorist",
  "All"
};

new const g_sSoundNames[MAX_SOUNDS] [] = {
  "No Sound",
  "Male Voice",
  "Female Voice"
}

new g_iFreeze, g_iSound, g_iCounter = MIN_SEC;
new bool:g_bStatus;

public plugin_init() {
  register_plugin("[JB] Countdown","v1.0","Hyuna");

  register_saycmd("cd","ActionCountDown");
  register_saycmd("countdown","ActionCountDown");
}

public ActionCountDown(client) {
  static some[256], iMenu, iCallback;

	if ((get_user_flags(client) & ADMIN_ACCESS) || (cs_get_user_team(client) == CS_TEAM_CT && is_user_alive(client)))
	{
	  iMenu = menu_create("[JailBreak] CountDown Menu","mHandler");
	  iCallback = menu_makecallback("mCallback");

		formatex(some,charsmax(some),"Time: \d[ \r%d Seconds \d]",g_iCounter);
		menu_additem(iMenu,some,.callback=iCallback);

		formatex(some,charsmax(some),"Sound: \d[ \r%s \d]",g_sSoundNames[g_iSound]);
		menu_additem(iMenu,some,.callback=iCallback);

		formatex(some,charsmax(some),"Freeze Team: \d[ \r%s \d]",g_sTeamNames[g_iFreeze]);
		menu_additem(iMenu,some,.callback=iCallback);

		menu_additem(iMenu,(g_bStatus ? "Stop Countdown":"Start Countdown"));

		menu_display(client,iMenu);
}

else
{
	client_print_color(0,print_team_red,"%s ^3Access denied^1! You must be an ^4Alive Guard^1 or an ^4Admin^1.",PREFIX);
	client_cmd(client,"spk ^"\vox/access denied^"");
}

	return PLUGIN_HANDLED;
}

public mCallback(client, menu, item) {
	return (g_bStatus ? ITEM_DISABLED:ITEM_ENABLED);
}

public mHandler(client, menu, item) {
	static szName[32], players[32], pnum, i;

	switch(item)
	{
		case 0:
		{
			g_iCounter+=SEC_STEP;

			if (g_iCounter > MAX_SEC )
				g_iCounter = MIN_SEC;
		}

		case 1:
		{
			if (++g_iSound == MAX_SOUNDS)
				g_iSound = 0;
		}

		case 2:
		{
			if (++g_iFreeze == MAX_TEAMS)
				g_iFreeze = 0;
		}

		case 3:
		{
			g_bStatus = !g_bStatus;

			switch(g_bStatus)
			{
				case false:
				{
					get_players(players,pnum,"ah");

					for (i = 0; i < pnum; i++)
						set_user_freeze(players[i],false);

					g_iCounter = MIN_SEC;

					remove_task(TASKID_CD);
				}

				case true:
				{
					if (g_iFreeze)
					{
						if (g_iFreeze < 3)
							get_players(players,pnum,"aeh",(g_iFreeze == 1 ? "TERRORIST":"CT"));

						else
							get_players(players,pnum,"ah");

						for (i = 0; i < pnum; i++)
							set_user_freeze(players[i],true);
					}

					set_task(1.0,"taskCountDown",TASKID_CD,.flags="b");
				}
			}

			get_user_name(client,szName,charsmax(szName));
			client_print_color(0,client,"%s Admin ^3%s^1 has ^4%sabled^1 Countdown!",PREFIX,szName,(g_bStatus ? "en":"dis"));
		}
	}

	menu_destroy(menu);

	if (item != MENU_EXIT && item != 3)
		return ActionCountDown(client);

	return PLUGIN_HANDLED;
}

public taskCountDown(taskid) {
	static szWord[32];

	if (g_iCounter < 1)
	{
		client_cmd(0,"spk ^"radio/com_go^"");

		set_dhudmessage(0,255,0,-1.0,0.23,0,6.0,6.0);
		show_dhudmessage(0,"Go Go Go!!!");
		client_print_color(0,print_team_default,"%s ^3CountDown^1 is over! ^4Go Go Go^1!!!",PREFIX);

		remove_task(taskid);
		g_iCounter = MIN_SEC;

		g_bStatus = false;

		if (g_iFreeze)
		{
			new players[32], pnum, i;
			get_players(players,pnum,"ah");

			for (i = 0; i < pnum; i++)
				set_user_freeze(players[i],false);
		}
		return;
	}

	if (g_iSound)
	{
		num_to_word(g_iCounter,szWord,31);

		if (g_iCounter < 21)
		{
			if (g_iSound == 2)
				client_cmd(0,"spk ^"\fvox/%s^"",szWord);

			else
				client_cmd(0,"spk ^"\vox/%s second%s^"",szWord,g_iCounter > 1 ? "s":"");
		}

		else
			client_cmd(0,"spk ^"\%svox/%s^"",(g_iSound == 2 ? "f":""),szWord);
	}

	set_dhudmessage(random(256),random(256),random(256),-1.0,0.23,0,6.0,0.5);
	show_dhudmessage(0,"CountDown: %d Second%s Left",g_iCounter,g_iCounter > 1 ? "s":"");

	g_iCounter--;
}

stock set_user_freeze(client, bool:bFreeze) {
	set_pev(client,pev_flags,(bFreeze ? (pev(client,pev_flags) | FL_FROZEN): (pev(client,pev_flags) & ~FL_FROZEN)));
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
