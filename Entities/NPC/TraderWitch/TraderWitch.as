// Trader logic

#include "RunnerCommon.as"
#include "Help.as";
#include "Hitters.as";
#include "Requirements.as";
#include "ShopCommon.as";
#include "MakeSeed.as"

//trader methods

//blob

const string[] firstnames = 
{ 
	"Jenny",
    "Rajang",
	"Burnin"
};

const string[] surnames = 
{ 
	"Trader",
	"Witch",
};

const string[] soundsTalk = 
{ 
	"MigrantSayHello.ogg",
	"MigrantSayFriend.ogg"
};

const string[] soundsDanger = 
{ 
	"trader_scream_0.ogg",
	"trader_scream_1.ogg",
	"trader_scream_2.ogg"
};

const string[] textsIdle = 
{ 
	"Good morning!",
	"What a nice day!",
	"Hello!",
	"Well met.",
	"UзU",
	"What's on your mind?",
	"What can I do for you?",
	"Greetings!",
	"Need something?",
	"Safe travels!",
	"Can I help you?",
	"When I was young, I was a mighty knight. Then I became an old coot.",
	"A long time ago, there were wizards and the world was in chaos. Then the magic got banned.",
	"Are you a wizard?"
};

const string[] textsDanger = 
{ 
	"I'm too young to die!",
	"This is a nightmare!",
	"HELP ME!",
	"SAVE ME!",
	"I'M GOING TO DIE!",
	"What did I do to deserve this??",
	"I don't want to die!",
	"Don't hurt me!",
	"OH MY GOD WE'RE DOOMED!",
	"First the UPF, now you?",
	"This world is too cruel, I'm outta here!",
	"GET ME OUT OF HERE!",
	"AAAAAAA!",
	"Oh nooo!",
	"RUN FOR YOUR LIVES!"
};

const string[] textsWon = 
{
	"Thank god!",
	"You saved me!",
	"Hurray!",
	"Thank you!",
	"Thank you for saving me!",
	"My heroes!",
	"I am alive!"
};

void onInit(CBlob@ this)
{
	Random@ rand = Random(this.getNetworkID());
	string name = firstnames[rand.NextRanged(firstnames.length)] + " " + surnames[rand.NextRanged(surnames.length)];
	this.set_string("trader name", name);

	//no spinning
	this.getShape().SetRotationsAllowed(false);
	this.set_f32("gib health", -2.0f);
	this.Tag("flesh");
	this.Tag("migrant");
	this.Tag("human");
	this.getBrain().server_SetActive(true);

	//this.getCurrentScript().runFlags |= Script::tick_not_attached;
	//this.getCurrentScript().runFlags |= Script::tick_moving;

	this.set_u32("nextTalk", getGameTime() + XORRandom(60));
	this.set_u32("nextFood", 0);

	this.addCommandID("traderChat");

	addTokens(this); //colored shop icons

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(4, 5));
	this.set_string("shop description", name + " the Trader");
	this.setInventoryName(name + " the Trader");
	this.set_u8("shop icon", 25);
	this.getSprite().addSpriteLayer("isOnScreen", "NoTexture.png", 1, 1);

	this.Tag("can be captured by neutral");

	this.set_u32("lastDanger", 0);

	// Resource Trader
	if (rand.NextRanged(100) < 100)
	{
		{
		ShopItem@ s = addShopItem(this, "Process Mithril (1)", "$mat_mithrilingot$", "mat_mithrilingot-1", "I shall remove the deadly curse from this mythical metal.");
		AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril Ore", 10);
		AddRequirement(s.requirements, "coin", "", "Coins", 40);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Process Mithril (4)", "$mat_mithrilingot$", "mat_mithrilingot-4", "I shall remove the deadly curse from this mythical metal.");
		AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril Ore", 40);
		AddRequirement(s.requirements, "coin", "", "Coins", 160);
		s.spawnNothing = true;
	}
	}

	// Misc Trader
	if (rand.NextRanged(100) < 80)
	{
	    {
			ShopItem@ s = addShopItem(this, "JackOLantern", "$jackolantern$", "jackolantern", "A spooky pumpkin.");
			AddRequirement(s.requirements, "coin", "", "Coins", 150);
			s.spawnNothing = true;
		}
		{
		    ShopItem@ s = addShopItem(this, "Funny Magical Card Booster Pack", "$card_pack$", "card_pack", "A full pack of fun!");
		    AddRequirement(s.requirements, "coin", "", "Coins", 30);
		    s.spawnNothing = true;
	    }
		{
		    ShopItem@ s = addShopItem(this, "Terdla's Bubble Gem", "$bubble_gem$", "bubblegem", "A useless pretty blue gem! May cause hiccups");
		    AddRequirement(s.requirements, "coin", "", "Coins", 200);
		    s.spawnNothing = true;
	    }
	    {
		    ShopItem@ s = addShopItem(this, "Verdla's Suffocation Charm", "$choker_gem$", "choker", "A pretty green smokey gem!");
		    AddRequirement(s.requirements, "blob", "mat_methane", "Methane", 50);
		    AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingots", 2);
		    s.spawnNothing = true;
	    }
		{
		    ShopItem@ s = addShopItem(this, "Illegal gun part", "$illegalgunpart$", "illegalgunpart", "Very illegal gun parts for very illegal weapons.");
		    AddRequirement(s.requirements, "coin", "", "Coins", 5000);
		    s.spawnNothing = true;
	    }
		{
		    ShopItem@ s = addShopItem(this, "Saddle", "$saddle$", "saddle", "Saddle for animals.");
		    AddRequirement(s.requirements, "coin", "", "Coins", 500);
		    s.spawnNothing = true;
	    }
		{
			ShopItem@ s = addShopItem(this, "Sell Scrub's Chow", "$COIN$", "coin-120", "Sell 1 Scrub's Chow for 120 coins");
			AddRequirement(s.requirements, "blob", "foodcan", "Scrub's Chow", 1);
			s.spawnNothing = true;
			this.set_u32("shop_space", this.get_u32("shop_space") + 1);
		}
		{
		    ShopItem@ s = addShopItem(this, "RIP", "$rip$", "rip", "");
		    AddRequirement(s.requirements, "coin", "", "Coins", 7000);
			AddRequirement(s.requirements, "blob", "mat_sulphur", "Sulphur", 350);
			AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron ingot", 20);
			AddRequirement(s.requirements, "blob", "mat_methane", "Methane", 50);
		    s.spawnNothing = true;
	    }
		
	}

	// Nature Trader
	if (rand.NextRanged(100) < 70)
	{
		{
			ShopItem@ s = addShopItem(this, "Sell Pumpkin (1)", "$COIN$", "coin-100", "Sell 1 pumpkin for 100 coins.");
			AddRequirement(s.requirements, "blob", "pumpkin", "Pumpkin", 1);
			s.spawnNothing = true;
		}
        {
		    ShopItem@ s = addShopItem(this, "Ganja Weed", "$ganjapod$", "ganja_seed", "With these ingredients I may conjure a magical plant of valuable properties.");
		    AddRequirement(s.requirements, "blob", "grain", "Grain", 1);
		    AddRequirement(s.requirements, "blob", "mat_copper", "Copper", 75);
		    AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril", 45);
		    AddRequirement(s.requirements, "coin", "", "Coins", 250);
		    s.spawnNothing = true;
	    }
		{
			ShopItem@ s = addShopItem(this, "Tea", "$tea$", "tea", "Sweet tea.");
			AddRequirement(s.requirements, "coin", "", "Coins", 150);
			s.spawnNothing = true;
			this.set_u32("shop_space", this.get_u32("shop_space") + 1);
		}
	}

	// Arms dealer
	if (rand.NextRanged(100) < 30)
	{
		{
			ShopItem@ s = addShopItem(this, "Puntgun", "$puntgun$", "puntgun", " A big weapon with insane damage.");
			AddRequirement(s.requirements, "coin", "", "Coins", 500);
			s.spawnNothing = true;
		}
	}
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	// reset shop colors
	addTokens(this);
}

void addTokens(CBlob@ this)
{
	int teamnum = this.getTeamNum();
	if (teamnum > 6) teamnum = 7;

	AddIconToken("$icon_lighter$", "Lighter.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$icon_firework$", "Firework.png", Vec2f(16, 24), 0, teamnum);
	AddIconToken("$icon_jetpack$", "Jetpack.png", Vec2f(16, 16), 0, teamnum);
	AddIconToken("$mat_mithril$", "Material_Mithril.png", Vec2f(16, 16), 1);
	AddIconToken("$mat_mithrilingot$", "Material_MithrilIngot.png", Vec2f(16, 16), 1);
	AddIconToken("$card_pack$", "CardPack.png", Vec2f(9, 9), 0);
	AddIconToken("$choker_gem$", "Choker.png", Vec2f(10, 10), 0);
	AddIconToken("$bubble_gem$", "BubbleGem.png", Vec2f(10, 10), 0);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	this.set_bool("shop available", this.isOverlapping(caller) || this.isAttachedTo(caller));
}

void onTick(CBlob@ this)
{
	if (!this.hasTag("dead"))
	{
		if (this.getHealth() <= 0)
		{
			this.Tag("dead");
			return;
		}

		if (getGameTime() >= this.get_u32("nextTalk"))
		{
			this.set_u32("nextTalk", getGameTime() + (30 * 10) + XORRandom(30 * 20));

			u32 lastDanger = this.get_u32("lastDanger");
			u16 dangerBlobNetID = this.get_u16("danger blob");

			bool danger = dangerBlobNetID > 0 && getGameTime() < (lastDanger + (30 * 30));

			string text = "";
			if (danger)
			{
				// this.set_u32("lastDanger", getGameTime());

				text = textsDanger[XORRandom(textsDanger.size())];
				this.getSprite().PlaySound(soundsDanger[XORRandom(soundsDanger.size())]);
			}
			else
			{
				if (getGameTime() - this.get_u32("lastDanger") < 30 * 60)
				{
					text = textsWon[XORRandom(textsWon.size())];
				}
				else
				{
					text = textsIdle[XORRandom(textsIdle.size())];
					this.getSprite().PlaySound(soundsTalk[XORRandom(soundsTalk.size())]);
				}
			}

			if (isServer())
			{
				CBitStream stream;
				stream.write_string(text);
				this.SendCommand(this.getCommandID("traderChat"), stream);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("traderChat"))
	{
		this.Chat(params.read_string());
	}
	else if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("ChaChing.ogg");

		u16 caller, item;
		if (!params.saferead_netid(caller) || !params.saferead_netid(item)) return;

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
			else if(spl[0] == "seed")
			{
				CBlob@ blob = server_MakeSeed(this.getPosition(),XORRandom(2)==1 ? "tree_pine" : "tree_bushy");

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
				
				if (blob is null && callerBlob is null) return;
			   
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

void onDie(CBlob@ this)
{
	if (isServer())
	{
		server_DropCoins(this.getPosition(), XORRandom(400));
	}
}

void onReload(CSprite@ this)
{
	this.getConsts().filename = "Entities/Special/WAR/Trading/TraderCoot.png";
}

void onGib(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	if(!isClient()){return;}
	CParticle@ Gib1 = makeGibParticle("Entities/Special/WAR/Trading/TraderGibs.png", pos, vel + getRandomVelocity(90, hp, 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall");
	CParticle@ Gib2 = makeGibParticle("Entities/Special/WAR/Trading/TraderGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2, 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall");
	CParticle@ Gib3 = makeGibParticle("Entities/Special/WAR/Trading/TraderGibs.png", pos, vel + getRandomVelocity(90, hp, 80), 2, 0, Vec2f(16, 16), 2.0f, 0, "/BodyGibFall");
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	// if (byBlob.getTeamNum() != this.getTeamNum()) return true;

	// CBlob@[] blobsInRadius;
	// if (this.getMap().getBlobsInRadius(this.getPosition(), 0.0f, @blobsInRadius))
	// {
		// for (uint i = 0; i < blobsInRadius.length; i++)
		// {
			// CBlob @b = blobsInRadius[i];
			// if (b.getName() == "tradingpost")
			// {
				// return false;
			// }
		// }
	// }
	return true;
}

// bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
// {
	// // dont collide with people
	// return true;
// }

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	this.set_u32("lastDanger", getGameTime());
	this.set_u16("danger blob", hitterBlob.getNetworkID());
	this.set_u32("nextTalk", this.get_u32("nextTalk") - (30 * damage * 13));

	return damage;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	// this.set_u32("lastDanger", getGameTime() - (30 * 30));
	this.set_u16("danger blob", 0);
}

//sprite/anim update

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	// set dead animations

	if (blob.hasTag("dead"))
	{
		if (!this.isAnimation("dead")) this.PlaySound("trader_death.ogg");

		this.SetAnimation("dead");

		if (blob.isOnGround())
		{
			this.SetFrameIndex(0);
		}
		else
		{
			this.SetFrameIndex(1);
		}
		//this.getCurrentScript().runFlags |= Script::remove_after_this;

		return;
	}

	// if (blob.hasTag("shoot wanted"))
	// {
		// this.SetAnimation("shoot");
		// return;
	// }

	// set animations
	Vec2f pos = blob.getPosition();
	Vec2f aimpos = blob.getAimPos();
	bool ended = this.isAnimationEnded();

	bool danger = getGameTime() < (blob.get_u32("lastDanger") + (30 * 30));

	if ((blob.isKeyPressed(key_left) || blob.isKeyPressed(key_right)) || (blob.isOnLadder() && (blob.isKeyPressed(key_up) || blob.isKeyPressed(key_down))))
	{
		if (danger)
		{
			this.SetAnimation("dangerwalk");
		}
		else
		{
			this.SetAnimation("walk");
		}
	}
	else if (ended)
	{
		this.SetAnimation("default");
	}
}
