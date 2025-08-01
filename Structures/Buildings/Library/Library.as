﻿// A script by TFlippy

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";

Random traderRandom(Time());

void onInit(CBlob@ this)
{
	AddIconToken("$bp_aa_icon$", "Blueprints.png", Vec2f(16, 16), 16);
	AddIconToken("$bp_en_icon$", "Blueprints.png", Vec2f(16, 16), 17);
	AddIconToken("$bp_ch_icon$", "Blueprints.png", Vec2f(16, 16), 18);
	AddIconToken("$bp_we_icon$", "Blueprints.png", Vec2f(16, 16), 19);

	this.set_TileType("background tile", CMap::tile_castle_back);

	// this.Tag("upkeep building");
	// this.set_u8("upkeep cap increase", 0);
	// this.set_u8("upkeep cost", 5);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
	this.Tag("change team on fort capture");

	// getMap().server_SetTile(this.getPosition(), CMap::tile_wood_back);

	AddIconToken("$filled_bucket$", "bucket.png", Vec2f(16, 16), 1);

	this.set_Vec2f("shop offset", Vec2f(0,0));
	this.set_Vec2f("shop menu size", Vec2f(4, 2));
	this.set_string("shop description", "Bookworm's Lair");
	this.set_u8("shop icon", 15);
	// this.set_Vec2f("class offset", Vec2f(-6, 0));
	// this.set_string("required class", "builder");

	{
		ShopItem@ s = addShopItem(this, "Adv Automation Blueprint", "$bp_aa_icon$", "bp_automation_advanced", "The blueprint for the automated chicken assembler.", true);
		AddRequirement(s.requirements, "blob", "acidthrower", "Acid thrower", 1);
		AddRequirement(s.requirements, "blob", "mat_howitzershell", "Howitzer shells", 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 1750);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Energetics Blueprint", "$bp_en_icon$", "bp_energetics", "The blueprint for the beam tower.", true);
		AddRequirement(s.requirements, "blob", "mat_battery", "Batteries", 150);
		AddRequirement(s.requirements, "coin", "", "Coins", 1500);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Chemistry Blueprint", "$bp_ch_icon$", "bp_chemistry", "The blueprint for the automated druglab.", true);
		AddRequirement(s.requirements, "blob", "mat_acid", "Acid", 100);
		AddRequirement(s.requirements, "blob", "mat_mustard", "Mustard gas", 250);
		AddRequirement(s.requirements, "coin", "", "Coins", 2000);

		s.spawnNothing = true;
	}
    {
		ShopItem@ s = addShopItem(this, "Weapons Blueprint", "$bp_we_icon$", "bp_weapons", "The blueprint for special UPF weapon shop.", true);
		AddRequirement(s.requirements, "blob", "gaussrifle", "Gauss rifle", 2);
		AddRequirement(s.requirements, "coin", "", "Coins", 2000);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Adv Automation for 1250 c.", "$COIN$", "coin-1250", "Sell blueprint for 1250 coins.");
		AddRequirement(s.requirements, "blob", "bp_automation_advanced", "Adv Automation Blueprint", 1);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Energetics for 1000 c.", "$COIN$", "coin-1000", "Sell blueprint for 1000 coins.");
		AddRequirement(s.requirements, "blob", "bp_energetics", "Energetics Blueprint", 1);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Chemistry for 1500 c.", "$COIN$", "coin-1500", "Sell blueprint for 1500 coins.");
		AddRequirement(s.requirements, "blob", "bp_chemistry", "Chemistry Blueprint", 1);
		s.spawnNothing = true;
	}
    {
        ShopItem@ s = addShopItem(this, "Sell Weapons for 1250 c.", "$COIN$", "coin-1250", "Sell blueprint for 1250 coins.");
		AddRequirement(s.requirements, "blob", "bp_weapons", "Weapons Blueprint", 1);
		s.spawnNothing = true;
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if(caller.getName() == this.get_string("required class"))
	{
		this.set_Vec2f("shop offset", Vec2f_zero);
	}
	else
	{
		this.set_Vec2f("shop offset", Vec2f(0, 0));
	}
	this.set_bool("shop available", this.isOverlapping(caller));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("ConstructShort");

		u16 caller, item;

		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;

		string name = params.read_string();
		CBlob@ callerBlob = getBlobByNetworkID(caller);

		if (callerBlob is null) return;

		if (isServer())
		{
			string[] spl = name.split("-");

			if (spl[0] == "coin")
			{
				CPlayer@ callerPlayer = callerBlob.getPlayer();
				if (callerPlayer is null) return;

				getRules().set_u32(callerPlayer.getUsername()+"coins",getRules().get_u32(callerPlayer.getUsername()+"coins") +  parseInt(spl[1]));
			}
			else if (name.findFirst("mat_") != -1)
			{
				CPlayer@ callerPlayer = callerBlob.getPlayer();
				if (callerPlayer is null) return;

				CBlob@ mat = server_CreateBlob(spl[0]);

				if (mat !is null)
				{
					mat.Tag("do not set materials");
					mat.server_SetQuantity(parseInt(spl[1]));
					if (!callerBlob.server_PutInInventory(mat))
					{
						mat.setPosition(callerBlob.getPosition());
					}
				}
			}
			else
			{
				CBlob@ blob = server_CreateBlob(spl[0], callerBlob.getTeamNum(), this.getPosition());

				if (blob is null) return;

				if (!blob.canBePutInInventory(callerBlob))
				{
					callerBlob.server_Pickup(blob);
				}
				else if (callerBlob.getInventory() !is null && !callerBlob.getInventory().isFull())
				{
					callerBlob.server_PutInInventory(blob);
				}
			}
		}
	}
}
