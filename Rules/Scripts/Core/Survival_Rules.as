#define SERVER_ONLY;
#include "CTF_Structs.as";
#include "Survival_Structs.as";
#include "MaterialCommon.as";
#include "Costs.as"
#include "MakeMat.as";
#include "Logging.as";
// #include "Knocked.as"
#include "MakeCrate.as";
#include "MapType.as";
#include "neutral_team_assigner.as";
#include "DeityCommon.as";

const u32[] blacklist = {2581036929};

shared class Players
{
	CTFPlayerInfo@[] list;
	// PersistentPlayerInfo@[] persistentList;
	Players(){}
};

void DrawOverlay(const string file, const SColor color = SColor(255, 255, 255, 255))
{
	CFileImage@ image = CFileImage(file);
	f32 width = image.getWidth();
	f32 height = image.getHeight();

	f32 s_width = getScreenWidth() * 0.50f;
	f32 s_height = getScreenHeight() * 0.50f;

	// void GUI::DrawIcon(const string&in textureFilename, int iconFrame, Vec2f frameDimension, Vec2f pos, float scaleX, float scaleY, SColor color)
	GUI::DrawIcon(file, 0, Vec2f(width, height), Vec2f(0, 0), 1.00f / width * s_width, 1.00f / height * s_height, color);
}

/*void onRender(CRules@ this)
{
	// DrawOverlay("popup_image");
	// f32 alpha = (1.00f + Maths::Sin(getGameTime() * 0.1f)) / 2.00f;
	// DrawOverlay("portrait1", SColor(255 * alpha, 255, 255, 255));
}*/

// void GetPersistentPlayerInfo(CRules@ this, string name, PersistentPlayerInfo@ &out info)
// {
	// Players@ players;
	// this.get("players", @players);

	// if (players !is null)
	// {
		// for (u32 i = 0; i < players.persistentList.length; i++)
		// {
			// if (players.persistentList[i].name == name)
			// {
				// @info = players.persistentList[i];
				// return;
			// }
		// }
	// }
// }

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	CBlob@ blob = player.getBlob();

	if (blob !is null) print(player.getUsername() + " left, leaving behind a sleeper " + blob.getName());

	if (isServer())
	{
		if (blob !is null && blob.exists("sleeper_name"))
		{
			blob.server_SetPlayer(null);

			blob.set_u32("sleeper_coins", getRules().get_u32(player.getUsername()+"coins"));
			blob.set_bool("sleeper_sleeping", true);
			blob.set_string("sleeper_name", player.getUsername());

			CBitStream bt;
			bt.write_bool(true);

			blob.SendCommand(blob.getCommandID("sleeper_set"), bt);


			// blob.Sync("sleeper", false);
			// blob.Sync("sleeper_name", false);
			// blob.Sync("sleeper_coins", false);
		}
		else
		{
			if (blob !is null) blob.server_Die();
		}
	}

	Players@ players;
	this.get("players", @players);

	if (players !is null)
	{
		for(s8 i = 0; i < players.list.length; i++) {
			if(players.list[i] !is null && players.list[i].username == player.getUsername())
			{
				players.list.removeAt(i);
				i--;
			}
		}
	}
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{

}

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u8 newteam)
{
	if (player !is null)
	{
		player.server_setTeamNum(newteam);
	}
}

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{

}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	if (victim is null)
	{
		return;
	}

	string victimName = victim.getUsername() + " (team " + victim.getTeamNum() + ")";
	string attackerName = attacker !is null ? (attacker.getUsername() + " (team " + attacker.getTeamNum() + ")") : "world";
	u8 victimTeam = victim.getTeamNum();
	int coins = getRules().get_u32(victim.getUsername()+"coins");

	if (isServer())
	{
		//tcpr("[PDB] "+victimName +" has been killed by " + attackerName + "; damage type: " + customData);
		
		// Drop 50% on death + what ever else kag takes away on death
		// if (victimTeam >= 100 && coins != 0)
			// getRules().set_u32(victim.getUsername()+"coins",coins / 2);
	}
	// printf(victimName + " has been killed by " + attackerName + "; damage type: " + customData);

	s32 respawn_time = 30 * 4;

	if (victimTeam >= 100) respawn_time += 30 * 4;
	if (victimTeam < 7)
	{
		TeamData@ team_data;
		GetTeamData(victimTeam, @team_data);

		if (team_data != null)
		{
			u16 upkeep = team_data.upkeep;
			u16 upkeep_cap = team_data.upkeep_cap;
			f32 upkeep_ratio = f32(upkeep) / f32(upkeep_cap);

			if (upkeep_ratio >= UPKEEP_RATIO_PENALTY_RESPAWN_TIME) respawn_time += 30 * 2.5;
			if (upkeep_ratio <= UPKEEP_RATIO_BONUS_RESPAWN_TIME) respawn_time -= 30 * 1.5;
		}
	}

	victim.set_u32("respawn time", getGameTime() + respawn_time);

	CBlob@ blob = victim.getBlob();
	if(blob !is null)
	{
		// Note: Disabled for now, too harsh for neutrals 
		// Drop 50% of that 50% lost
		// if (victimTeam >= 100 && coins != 0)
			// server_DropCoins(blob.getPosition(), coins / 2);

		if(!(blob.getName().find("corpse") != -1))
		{
			victim.set_string("classAtDeath",blob.getName());
			victim.set_Vec2f("last death position",blob.getPosition());
		}
		else
		{
			victim.set_Vec2f("last death position",blob.getPosition());
		}
	}

	// print(victim.getUsername() + " killed by " + attacker.getUsername());
	// print(victim.getUsername() + " (victim) killstreak: " + victim.get_u8("kill_streak"));


	if (attacker !is null && attacker !is victim)
	{
		attacker.set_u8("kill_streak", attacker.get_u8("kill_streak") + 1);
		// print(attacker.getUsername() + " (attacker) killstreak: " + attacker.get_u8("kill_streak"));

		if (attacker.getBlob() !is null && victim.getUsername() == "Mithrios")
		{
			if (victim.get_u8("kill_streak") >= 13)
			{
				// Sound::Play("mysterious_perc_05.ogg");

				if (isServer())
				{
					CBlob@ blob = server_CreateBlob("demonicartifact", -1, attacker.getBlob().getPosition());
				}
			}
		}
	}

	victim.set_u8("kill_streak", 0);
}

void onTick(CRules@ this)
{
	s32 gametime = getGameTime();
	updateDestroyedFactions();

	for (u8 i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player !is null)
		{
			CBlob@ blob = player.getBlob();
			if (blob is null && player.get_u32("respawn time") <= gametime)
			{
				int team = player.getTeamNum();
				bool isNeutral = team >= 100;

				// Civilized team spawning
				if (!isNeutral)
				{
					CBlob@[] bases;
					getBlobsByTag("faction_base", @bases);
					//getBlobsByTag("respawn", @bases);
					CBlob@[] spawns;
					int teamBases = 0;
					bool has_bases = false;

					for (uint i = 0; i < bases.length; i++)
					{
						if (bases[i].getTeamNum() == team) teamBases++;
					}

					for (uint i = 0; i < bases.length; i++)
					{
						CBlob@ base = bases[i];
						if (base !is null && base.getTeamNum() == team)
						{
							has_bases = true;
							if (base.hasTag("reinforcements allowed") || teamBases == 1) spawns.push_back(base);
						}
					}

					if (spawns.length > 0)
					{
						f32 distance = 100000;
						Vec2f spawnPos = Vec2f(0, 0);
						Vec2f deathPos = player.get_Vec2f("last death position");
					
						u32 spawnIndex = 0;

						for (u32 i = 0; i < spawns.length; i++)
						{
							f32 tmpDistance = Maths::Abs(spawns[i].getPosition().x - deathPos.x);
							if (spawns[i].get_bool("being captured") && spawns.length != 1) continue;

							// print("Lowest: " + distance + "; Compared against: " + tmpDistance);

							if (tmpDistance < distance)
							{
								distance = tmpDistance;
								spawnIndex = i;
								spawnPos = spawns[i].getPosition();
							}
						}

						string blobType = player.get_string("classAtDeath");
						if (blobType == "builder" || blobType == "engineer" || blobType == "hazmat" || blobType == "slave" || blobType == "peasant") blobType = "builder";
						else if (blobType == "archer") blobType = "archer";
						else blobType = "knight";

						CBlob@ new_blob = server_CreateBlob(blobType);

						if (new_blob !is null)
						{
							new_blob.setPosition(spawnPos);
							new_blob.server_setTeamNum(team);
							new_blob.server_SetPlayer(player);
							// print("" + spawns[spawnIndex].getName());
							// print("init " + new_blob.getHealth());
							if (spawns[spawnIndex].getName() == "citadel")
							{
								new_blob.server_SetHealth(Maths::Ceil(new_blob.getInitialHealth() * 1.50f));
								// print("after " + new_blob.getHealth());
							}
						}
					}
					else
					{
						if (has_bases) return; //wait until able to spawn or lost all bases
						isNeutral = true; // In case if the player is respawning while the team has been defeated
					}
				}

				// Bandit scum spawning
				if (isNeutral)
				{
					string playerName = player.getUsername().split('~')[0];
					team = reserve_team(playerName);
					player.server_setTeamNum(team);

					string blobType = "peasant";
					if (player.get_u8("deity_id") == Deity::ivan)
						blobType = "builder";
						
					if (player.isBot() && player.get_string("classAtDeath") != "")
					{
						blobType = player.get_string("classAtDeath");
					}

					if (player.getUsername() == "Mithrios")
					{
						blobType = "mithrios";
					}

					bool default_respawn = true;

					if (player.get_u16("tavern_netid") != 0)
					{
						CBlob@ tavern = getBlobByNetworkID(player.get_u16("tavern_netid"));
						const bool isTavernOwner = tavern !is null && player.getUsername() == tavern.get_string("Owner");

						if (tavern !is null && tavern.getName() == "tavern" && (getRules().get_u32(player.getUsername()+"coins") >= 20 || isTavernOwner))
						{
							printf("Respawning " + player.getUsername() + " at a tavern as team " + player.get_u8("tavern_team"));

							CBlob@ new_blob = server_CreateBlob(blobType);
							if (new_blob !is null)
							{
								if (player.exists("tavern_team") && player.get_u8("tavern_team") != 255) team = player.get_u8("tavern_team");

								new_blob.setPosition(tavern.getPosition());
								new_blob.server_setTeamNum(team);
								new_blob.server_SetPlayer(player);

								if (!isTavernOwner)
								{
									getRules().set_u32(player.getUsername()+"coins",getRules().get_u32(player.getUsername()+"coins") - 20);

									CPlayer@ tavern_owner = getPlayerByUsername(tavern.get_string("Owner"));
									if (tavern_owner !is null)
									{
										getRules().set_u32(tavern_owner.getUsername()+"coins",getRules().get_u32(tavern_owner.getUsername()+"coins") + 20);
									}
								}

								default_respawn = false;
							}
						}
					}

					if (default_respawn)
					{
						CBlob@[] ruins;
						getBlobsByName("ruins", @ruins);

						int ruins_count = 0;

						for (int i = 0; i < ruins.length; i++)
						{
							CBlob@ b = ruins[i];
							if (b !is null && b.get_bool("isActive")) ruins_count++;
						}

						if (ruins_count > 0)
						{
							f32 ruins_ratio = 1.00f - (f32(ruins_count) / f32(ruins.length));
							f32 chicken_chance = ruins_ratio * ruins_ratio;

							//tcpr("[CCC] Chicken Chance: " + (chicken_chance * 100) + "%");

							if (XORRandom(100) < (chicken_chance * 100))
							{
								if (!doChickenSpawn(player))
								{
									doDefaultSpawn(player, blobType, team, true);
								}
							}
							else
							{
								doDefaultSpawn(player, blobType, team, false);
							}
						}
						else
						{
							if (XORRandom(100) < 33)
								doChickenSpawn(player);
							else
								doDefaultSpawn(player, "builder", team, false);
						}
					}
				}
			}
		}
	}
}

void updateDestroyedFactions() 
{
	CBlob@[] forts;
	getBlobsByTag("faction_base", @forts);
	for (uint i = 0; i < 7; i++)
	{
		bool hasForts = false;
		int teamNum = i;
		for (uint j = 0; j < forts.length; j++)
		{
			if (forts[j].getTeamNum() == teamNum) hasForts = true;
		}

		if (!hasForts)
		{
			TeamData@ team_data;
			GetTeamData(teamNum, @team_data);
			team_data.leader_name = "";
		}
	}
}


void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	Players@ players;
	this.get("players", @players);

	if (players is null || player is null){
		return;
	}

	int localtime = Time_Local();
	int regtime = player.getRegistrationTime();

	int reg_month = Time_Month(regtime);
	int reg_day = Time_MonthDate(regtime);
	int reg_year = Time_Year(regtime);

	int loc_month = Time_Month(localtime);
	int loc_day = Time_MonthDate(localtime);
	int loc_year = Time_Year(localtime);

	//time is sec(60) * min(60) * hours(24)* daysfrom 1970-jan-01
	// 1 day = 86400  and  30 days = 2592000
	/*if ((localtime - regtime)<=2592000*3)
	{
		CSecurity@ security = getSecurity();
		if (security is null) return;
		bool can_ban = !security.checkAccess_Feature(player, "whitelist");
		//in security folder inside normal.cfg add newban; to end of features=
		// inside preium.cfg add newban; to end of features=
		
		printf("New player joined. Account age:"+ regtime + " regdate:" + reg_year + "-" + reg_month + "-" + reg_day + " checkAccess_Feature:" + can_ban);
		if(can_ban)
		{
			printf("|");
			printf("|");
			printf("|");
			printf("BANNING PLAYER WITH TOO YOUNG ACCOUNT AGE: "+player.getUsername());
			printf("|");
			printf("|");
			printf("|");
			BanPlayer(player, 60*100);
			//security.ban(player, 60*60, "This is auto-ban due to young account age to avoid alter accounts, join discord to get unbanned: https://discord.gg/rhwRCmUNRK");
		}
	}
	*/

	string playerName = player.getUsername().split('~')[0];//Part one of a fix for slave rejoining
	players.list.push_back(CTFPlayerInfo(playerName, 0, ""));

	CBlob@[] sleepers;
	getBlobsByTag("sleeper", @sleepers);

	bool found_sleeper = false;
	if (sleepers != null && sleepers.length > 0)
	{
		string name = playerName;

		for (u32 i = 0; i < sleepers.length; i++)
		{
			CBlob@ sleeper = sleepers[i];
			if (sleeper !is null && !sleeper.hasTag("dead") && sleeper.get_string("sleeper_name") == name)
			{
				CBlob@ oldBlob = player.getBlob(); // It's glitchy and spawns empty blobs on rejoin
				if (oldBlob !is null) oldBlob.server_Die();

				found_sleeper = true;

				player.server_setTeamNum(sleeper.getTeamNum());
				getRules().set_u32(player.getUsername()+"coins",sleeper.get_u32("sleeper_coins"));

				sleeper.server_SetPlayer(player);
				sleeper.set_bool("sleeper_sleeping", false);
				sleeper.set_string("sleeper_name", "");

				CBitStream bt;
				bt.write_bool(false);

				sleeper.SendCommand(sleeper.getCommandID("sleeper_set"), bt);

				// sleeper.set_u32("sleeper_coins", getRules().get_u32(player.getUsername()+"coins"));

				// sleeper.Sync("sleeper", false);
				// sleeper.Sync("sleeper_name", false);
				// sleeper.Sync("sleeper_coins", false);

				//tcpr("[MISC] "+playerName + " joined, respawning him at sleeper " + sleeper.getName());
			}
		}
	}

	CPlayer@ maybePlayer = getPlayerByUsername(playerName);//See if we already exist
	if(maybePlayer !is null)
	{
		CBlob@ playerBlob = maybePlayer.getBlob();
		if(playerBlob !is null)
		{
			if(maybePlayer.getUsername() != player.getUsername())//do not change, playerName is stripped
			{
				KickPlayer(maybePlayer);//Clone
				playerBlob.server_SetPlayer(player);//switch souls
			}
		}
	}


	if (!found_sleeper)
	{
		for (uint i = 0; i < 7; i++) 
		{
			TeamData@ team_data;
			GetTeamData(i, @team_data);
			if (team_data.leader_name == player.getUsername())
			{
				CBlob@[] forts;
				getBlobsByTag("faction_base", @forts);
				for (uint j = 0; j < forts.length; j++)
				{
					if (forts[j].getTeamNum() == i) 
					{
						player.server_setTeamNum(i);
					}
				}
			}
		}

		getRules().set_u32(player.getUsername()+"coins",500);
	}

	// getRules().set_u32(player.getUsername()+"coins",150);
}

void onInit(CRules@ this)
{
	// Todo: Maybe let's not make it so obvious ;)
	CSecurity@ sec = getSecurity();

	if (sv_test && isClient() && isServer())
		LoadMap("small.png");

	// Print out a message to anybody running TC server/localhost
	if (isServer() && !isClient())
	{
		print("""
==============================================================================================================
		Territory Control Server is initializing.
		Please make sure you obtain permission before hosting publically!
		Also consider contributing at : github.com/TFlippy/kag_territorycontrol
==============================================================================================================
		""", SColor(0xff91ff81));
	}

	if (isServer() && isClient())
	{
		print("""
==============================================================================================================
		Territory Control is initializing.
		Make sure you set the gamemode correctly, and disabled the DRM (otherwise you may crash).
		Also consider contributing at : github.com/TFlippy/kag_territorycontrol
==============================================================================================================
		""", SColor(0xff91ff81));
	}

	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

bool doDefaultSpawn(CPlayer@ player, string blobType, u8 team, bool ignoreDisabledSpawns)
{
	CBlob@[] spawns;
	getBlobsByName("banditshack", @spawns);

	CBlob@[] ruins;
	getBlobsByName("ruins", @ruins);

	for (int i = 0; i < ruins.length; i++)
	{
		CBlob@ b = ruins[i];
		if (b !is null && (ignoreDisabledSpawns ? true : b.get_bool("isActive"))) spawns.push_back(b);
	}

	if (spawns.length == 0)
	{
		for (int i = 0; i < ruins.length; i++)
		{
			CBlob@ b = ruins[i];
			if (b !is null && XORRandom(100) < 33)
				spawns.push_back(b);
		}
	}

	if (spawns.length > 0)
	{
		printf("Respawning " + player.getUsername() + " at ruins.");

		CBlob@ new_blob = server_CreateBlob(blobType);

		if (new_blob !is null)
		{
			if (isClient() && new_blob.isMyPlayer())
			{	
				switch(getRules().get_u8("map_type"))
				{
					case MapType::arctic:
						server_CreateBlob("info_arctic", 255, Vec2f(0, 0));
						break;
					case MapType::dead:
						server_CreateBlob("info_dead", 255, Vec2f(0, 0));
						break;
					case MapType::desert:
						server_CreateBlob("info_desert", 255, Vec2f(0, 0));
						break;
					case MapType::jungle:
						server_CreateBlob("info_jungle", 255, Vec2f(0, 0));
						break;
					default:
						break;
				}
			}

			CBlob@ r = spawns[XORRandom(spawns.length)];
			if (r.getName() == "ruins" && team / 1 == 255)
			{
				return true;
			}
			else
			{
				new_blob.setPosition(r.getPosition());
				new_blob.server_setTeamNum(team);
				new_blob.server_SetPlayer(player);

				if (getGameTime() < 30 * 15)
				{
					MakeMat(new_blob, r.getPosition(), "mat_wood", 300);
					MakeMat(new_blob, r.getPosition(), "mat_stone", 150);
					MakeMat(new_blob, r.getPosition(), "mat_goldingot", 5);
				}
				else
				{
					MakeMat(new_blob, r.getPosition(), "mat_wood", 100);
					MakeMat(new_blob, r.getPosition(), "mat_stone", 30);
				}
			}

			return true;
		}
		else return false;
	}
	else return false;
}

bool doChickenSpawn(CPlayer@ player)
{
	player.server_setTeamNum(250);

	CBlob@[] ruins;
	getBlobsByName("chickencamp", @ruins);
	getBlobsByName("chickenfortress", @ruins);
	getBlobsByName("chickenstronghold", @ruins);
	getBlobsByName("chickencitadel", @ruins);
	getBlobsByName("chickenconvent", @ruins);
	getBlobsByName("chickencoop", @ruins);

	CBlob@[] bases;
	getBlobsByName("fortress", @bases);
	getBlobsByName("stronghold", @bases);
	getBlobsByName("citadel", @bases);
	getBlobsByName("convent", @bases);

	if (ruins.length > 0 || bases.length > 0)
	{
		string blobType = "scoutchicken";
		int minutes = getGameTime() / (60*30);
		int rand = XORRandom(100);
		if (minutes > 80)
		{
			if (rand < 40) blobType = "heavychicken";
			else if (rand < 85) blobType = "commanderchicken";
			else if (rand < 95) blobType = "soldierchicken";
			else blobType = "scoutchicken";
		}
		else if (minutes > 60)
		{
			if (rand < 10) blobType = "heavychicken";
			else if (rand < 30) blobType = "commanderchicken";
			else if (rand < 75) blobType = "soldierchicken";
			else blobType = "scoutchicken";
		}
		else if (minutes > 40)
		{
			if (rand < 2) blobType = "heavychicken";
			else if (rand < 15) blobType = "commanderchicken";
			else if (rand < 60) blobType = "soldierchicken";
			else blobType = "scoutchicken";
		}
		else if (minutes > 20)
		{
			if (rand < 10) blobType = "commanderchicken";
			else if (rand < 40) blobType = "soldierchicken";
			else blobType = "scoutchicken";
		}
		else if (minutes > 10)
		{
			if (rand < 5) blobType = "commanderchicken";
			else if (rand < 20) blobType = "soldierchicken";
			else blobType = "scoutchicken";
		}
		else blobType = "scoutchicken";
		
		if (ruins.length > 0)
		{
			CBlob@ new_blob = server_CreateBlob(blobType);
			if (new_blob !is null)
			{
				CBlob@ r = ruins[XORRandom(ruins.length)];

				new_blob.setPosition(r.getPosition());
				new_blob.server_setTeamNum(250);
				new_blob.server_SetPlayer(player);

				return true;
			}
		}
		else
		{
			CBlob@ new_blob = server_CreateBlob("scoutchicken");
			if (new_blob !is null)
			{
				//parachute chickens!
				//bots will not parachute correctly on server, only localhost
				CBlob@ b = bases[XORRandom(bases.length)];

				new_blob.setPosition(Vec2f(b.getPosition().x + (200 - XORRandom(400)), 0.0f));
				new_blob.server_setTeamNum(250);
				new_blob.server_SetPlayer(player);
				new_blob.Tag("parachute");
				if (isClient()) new_blob.AddScript("parachutepack_effect.as"); //for localhost

				return true;
			}
		}
		return false;
	}
	else return false;
}

void Reset(CRules@ this)
{
	printf("Restarting rules script: " + getCurrentScriptName());

	InitCosts();

	Players players();

	for(u8 i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if(p !is null)
		{
			p.set_u32("respawn time", getGameTime() + (30 * 1));
			//getRules().set_u32(p.getUsername()+"coins",Maths::Max(1000, getRules().get_u32(p.getUsername()+"coins") * 0.75f)); // Half of your fortune is lost by spending it on drugs.
			getRules().set_u32(p.getUsername()+"coins",Maths::Clamp(getRules().get_u32(p.getUsername()+"coins") * 0.75f, 1000, 30000));
			// SetToRandomExistingTeam(this, p);
			p.server_setTeamNum(100 + XORRandom(100));
			players.list.push_back(CTFPlayerInfo(p.getUsername(),0,""));
		}
	}

	this.SetGlobalMessage("");
	this.set("players", @players);
	this.SetCurrentState(GAME);

	server_CreateBlob("tc_soundscapes");
}

/*
void SpawnEventFireworks()
{
	CBlob@[] placesToSpawn;
	getBlobsByName("ruins", @placesToSpawn);
	getBlobsByName("convent", @placesToSpawn);
	getBlobsByName("citadel", @placesToSpawn);
	getBlobsByName("stronghold", @placesToSpawn);
	getBlobsByName("fortress", @placesToSpawn);
	getBlobsByName("camp", @placesToSpawn);
	getBlobsByName("banditshack", @placesToSpawn);


	for (int a = 0; a < placesToSpawn.length;)
	{
		Vec2f pos = placesToSpawn[a].getPosition();
		CBlob@ blob = server_CreateBlobNoInit("crate");
		blob.setPosition(pos);
		blob.server_setTeamNum(250);
		blob.set_string("packed name", "Bundle of joy!");
		blob.Init();

		int num = 1 + XORRandom(5);
		for (int b = 0; b < num; b++)
		{
			blob.server_PutInInventory(server_CreateBlob("patreonfirework", -1, pos));
		}

		// Skip some spawns
		a += 1+XORRandom(3);
	}

		CBitStream params;
		params.write_string("UPF has delivered crates of joy!");

		// List is reverse so we can read it correctly into SColor when reading
		params.write_u8(50);
		params.write_u8(50);
		params.write_u8(255);
		params.write_u8(255);

		for (int a = 0; a < getPlayerCount(); a++)
		{
			getRules().SendCommand(getRules().getCommandID("SendChatMessage"), params, getPlayer(a));
		}
}
*/
