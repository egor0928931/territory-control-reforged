#include "ResearchCommon.as"
#include "Survival_Structs.as";
#include "Requirements_Tech.as"
#include "DeityCommon.as"
#include "SmartStorageHelpers.as" 

string getButtonRequirementsText(CBitStream& inout bs,bool missing)
{
	string text,requiredType,name,friendlyName;
	u16 quantity=0;
	bs.ResetBitIndex();

	while (!bs.isBufferEnd())
	{
		text += "\nRequires:\n";
		
		ReadRequirement(bs,requiredType,name,friendlyName,quantity);
		string quantityColor;

		if (missing)
		{
			quantityColor = "$RED$";
		}
		else
		{
			quantityColor = "$GREEN$";
		}

		if (requiredType == "blob")
		{
			if (quantity > 0)
			{
				text += quantityColor;
				text += quantity;
				text += quantityColor;
				text += " ";
			}
			text += "$"; text += name; text += "$";
			text += " ";
			text += quantityColor;
			text += friendlyName;
			text += quantityColor;
			// text += " required.";
			text += "\n";
		}
		else if (requiredType == "coin")
		{
			text += quantity;
			text += " $COIN$ required\n";
		}
		else if (requiredType=="tech")
		{
			text += " \n$"; text += name; text += "$ ";
			text += quantityColor;
			text += friendlyName;
			text += quantityColor;
			// text += "\n\ntechnology required.\n";
		}
		else if (requiredType == "seclev feature")
		{
			text += quantityColor;
			text += "Access to role " + friendlyName + " required. \n";
			text += quantityColor;
		}
		else if (missing)
		{
			if (requiredType == "not tech")
			{
				text += " \n";
				text += quantityColor;
				text += friendlyName;
				text += " technology already acquired.\n";
				text += quantityColor;
			}
			//else if (requiredType == "altar power more than")
			//{
			//	text += quantityColor;
			//	text += friendlyName+" Altar power of "+quantity+" required. \n";
			//	text += quantityColor;
			//}
			else if (requiredType == "no more")
			{
				text += quantityColor;
				text += "Only "+quantity+" "+friendlyName+" per-team possible. \n";
				text += quantityColor;
			}
			else if (requiredType == "no less")
			{
				text += quantityColor;
				text += "At least "+quantity+" "+friendlyName+" required. \n";
				text += quantityColor;
			}
			else if (requiredType == "no more global")
			{
				text += quantityColor;
				text += "Only " + quantity + " " + friendlyName + " possible. \n";
				text += quantityColor;
			}
			else if (requiredType == "no less global")
			{
				text += quantityColor;
				text += "At least " + quantity + " " + friendlyName + " required. \n";
				text += quantityColor;
			}
		}
		text += "\n";
	}

	return text;
}

void SetItemDescription(CGridButton@ button, CBlob@ caller, CBitStream &in reqs, const string& in description, CInventory@ anotherInventory=null)
{
	if (button !is null && caller !is null && caller.getInventory() !is null)
	{
		CBitStream missing;

		if (hasRequirements(caller.getInventory(),anotherInventory,reqs,missing))
		{
			button.hoverText = description+"\n\n "+getButtonRequirementsText(reqs,false);
		}
		else
		{
			button.hoverText = description+"\n\n "+getButtonRequirementsText(missing,true);
			button.SetEnabled(false);
		}
	}
}

// read/write

void AddRequirement(CBitStream &inout bs, const string &in req, const string &in blobName, const string &in friendlyName, u16 &in quantity=1)
{
	bs.write_string(req);
	bs.write_string(blobName);
	bs.write_string(friendlyName);
	bs.write_u16(quantity);
}

bool ReadRequirement(CBitStream &inout bs, string &out req, string &out blobName, string &out friendlyName, u16 &out quantity)
{
	if (!bs.saferead_string(req))
	{
		return false;
	}

	if (!bs.saferead_string(blobName))
	{
		return false;
	}

	if (!bs.saferead_string(friendlyName))
	{
		return false;
	}

	if (!bs.saferead_u16(quantity))
	{
		return false;
	}

	return true;
}

//upd this
bool hasRequirements(CInventory@ inv1, CInventory@ inv2, CBitStream &inout bs, CBitStream &inout missingBs)
{
	string req, blobName, friendlyName;
	u16 quantity = 0;
	missingBs.Clear();
	bs.ResetBitIndex();
	bool has = true;

	CBlob@ playerBlob = (inv1 !is null 
		? (inv1.getBlob().getPlayer() !is null ? inv1.getBlob() 
			: (inv2 !is null ? (inv2.getBlob().getPlayer() !is null ? inv2.getBlob() : null) : null)) 
		: (inv2 !is null ? (inv2.getBlob().getPlayer() !is null ? inv2.getBlob() : null) : null));

	if (playerBlob !is null && playerBlob.getName() == "adminbuilder") return true;

	CBlob@[] baseBlobs;
	CBlob@[] smartStorageBlobs;
	CBlob@[] factionBases;
	CBlob@[] backpacks;
	
	bool storageEnabled, safe_storageEnabled = false;
	bool hasBackpack = false;
	
	if (playerBlob !is null)
	{
		int playerTeam = playerBlob.getTeamNum();

		if (playerTeam < 7)
		{
			TeamData@ team_data;
			GetTeamData(playerTeam, @team_data);

			if (team_data != null)
			{
				u16 upkeep = team_data.upkeep;
				u16 upkeep_cap = team_data.upkeep_cap;
				f32 upkeep_ratio = f32(upkeep) / f32(upkeep_cap);
				const bool faction_storage_enabled = team_data.storage_enabled;
				
				storageEnabled = upkeep_ratio <= UPKEEP_RATIO_PENALTY_STORAGE && faction_storage_enabled;
			}
			
			
			if (storageEnabled)
			{
				bool canPass = false;
				
				getBlobsByTag("remote_storage", @baseBlobs);
				for (int i = 0; i < baseBlobs.length; i++)
				{
					if ((baseBlobs[i].getName() == "safe" ? safe_storageEnabled ? false : true : true) && baseBlobs[i].getTeamNum() != playerTeam)
					{
						baseBlobs.erase(i);
						i--;
						continue;
					}
					if(!canPass){
						if ((baseBlobs[i].getPosition() - playerBlob.getPosition()).Length() < 250.0f)
						{
							canPass = true;
						}
					}
				}							
				
				//smart storage check
				getBlobsByTag("smart_storage", @smartStorageBlobs);
				for (int i = 0; i < smartStorageBlobs.length; i++)
				{
					if (smartStorageBlobs[i].getTeamNum() != playerTeam || (!canPass && (smartStorageBlobs[i].getPosition() - playerBlob.getPosition()).Length() > 250.0f))
					{
						smartStorageBlobs.erase(i);
						i--;
						continue;
					}
					if(!canPass){
						if ((smartStorageBlobs[i].getPosition() - playerBlob.getPosition()).Length() < 250.0f)
						{
							canPass = true;
						}
					}
				}							
				if (!canPass)
				{
					baseBlobs.clear();
				}
			}
			
		}

		{
			CBlob@[] baseBoobs;
			getBlobsByName("safe", @baseBoobs);

			for (u16 i = 0; i < baseBoobs.length; i++)
			{
				if (baseBoobs[i] !is null
				&& (baseBoobs[i].getPosition() - playerBlob.getPosition()).Length() < 250.0f)
				{
					string[] spl = baseBoobs[i].get_string("Owners").split("_");
					for (u16 j = 0; j < spl.length; j++)
					{
						if (playerBlob.getPlayer() !is null)
						{
							if (playerBlob.getPlayer().getUsername() == spl[j] || playerBlob.getPlayer().getUsername() == baseBoobs[i].get_string("Owner"))
							{	
								baseBlobs.push_back(baseBoobs[i]);
								storageEnabled = true;
								safe_storageEnabled = true;
								break;
							}
						}
					}
				}
			}
		}

		if (playerBlob.hasScript("Equipment.as"))
		{
			if (playerBlob.get_string("equipment2_torso") == "backpack")
			{
				CBlob@ backpack = getBlobByNetworkID(playerBlob.get_u16("backpack_id"));
				if (backpack !is null)
				{
					backpacks.push_back(backpack);
					hasBackpack = true;
				}
			}
		}
	}	

	while (!bs.isBufferEnd()) 
	{
		ReadRequirement(bs,req,blobName,friendlyName,quantity);
		if (req == "blob") 
		{
			int sum = (inv1 !is null ? inv1.getBlob().getBlobCount(blobName) : 0);
			
			if (storageEnabled)
			{
				for (int i = 0; i< baseBlobs.length; i++)
				{
					sum += baseBlobs[i].getBlobCount(blobName);
					if(baseBlobs[i].exists("compactor_resource")){
						if(baseBlobs[i].get_string("compactor_resource") == blobName){
							sum += baseBlobs[i].get_u32("compactor_quantity");
						}
					}
				}
				for (u8 i = 0; i< smartStorageBlobs.length; i++)
				{
					sum += smartStorageCheck(smartStorageBlobs[i],blobName);
					sum += smartStorageBlobs[i].getBlobCount(blobName);
				}
			}

			if (hasBackpack)
			{
				for (int i = 0; i< backpacks.length; i++)
				{
					sum += backpacks[i].getBlobCount(blobName);
				}
			}
			
			if (sum<quantity) 
			{
				AddRequirement(missingBs,req,blobName,friendlyName,quantity);
				has = false;
			}
		}
		/*else if (req == "coin") 
		{
			CPlayer@ player1 = inv1 !is null ? inv1.getBlob().getPlayer() : null;
			CPlayer@ player2 = inv2 !is null ? inv2.getBlob().getPlayer() : null;
			u16 sum = (player1 !is null ? getRules().get_u32(player1.getUsername()+"coins") : 0)+(player2 !is null ? getRules().get_u32(player2.getUsername()+"coins") : 0);
			if (sum<quantity) 
			{
				AddRequirement(missingBs,req,blobName,friendlyName,quantity);
				has=false;
			}
		}*/
		else if(req=="coin") 
		{
			CPlayer@ player1=	inv1 !is null ? inv1.getBlob().getPlayer() : null;
			CPlayer@ player2=	inv2 !is null ? inv2.getBlob().getPlayer() : null;
			CRules@ rules = getRules();
			u32 sum=			(player1 !is null ? getRules().get_u32(player1.getUsername()+"coins") : 0)+(player2 !is null ? getRules().get_u32(player2.getUsername()+"coins") : 0);
			if(sum<quantity) 
			{
				AddRequirement(missingBs,req,blobName,friendlyName,quantity-sum);
				has=false;
			}
		}
		else if (req == "has armor")
		{
			if (playerBlob.getInventory() !is null)
			{
				if (playerBlob.getInventory().getItem(blobName) !is null) 
					{
						CBlob@ item_blob = playerBlob.getInventory().getItem(blobName);
						if (item_blob.exists("health") && item_blob.get_f32("health") > 0) has = true;
						else has = false;
					}
				if (playerBlob.get_f32(blobName+"_health") == 0)
				{
					has = false;
				}
			}
		}
		//else if (req == "altar power more than")
		//{
		//	f32 biggest_power = 0;
		//	CBlob@ player = inv1.getBlob();
		//	u8 deity_id = player.get_u8("deity_id");
		//	
		//	CBlob@[] blobs;
		//	if (getBlobsByName(blobName, @blobs)) 
		//	{
		//		for (uint step = 0; step < blobs.length; ++step) 
		//		{
		//			CBlob@ blob = blobs[step];
		//			biggest_power = blob.get_f32("deity_power");
		//		}
		//	}
		//	
		//	if (biggest_power < quantity)
		//	{
		//		AddRequirement(missingBs, req, blobName, friendlyName, quantity);
		//		has = false;
		//	}
		//}
		else if ((req == "no more" || req == "no less") && inv1 !is null) 
		{
			int teamNum = inv1.getBlob().getTeamNum();
			int count =	0;
			
			CBlob@[] blobs;
			if (getBlobsByName(blobName, @blobs)) 
			{
				for (uint step = 0; step < blobs.length; ++step) 
				{
					CBlob@ blob = blobs[step];
					int blobTeamNum = blob.getTeamNum();
					if (blobTeamNum < 7 && (teamNum == blobTeamNum) || blobTeamNum > 6) 
					{
						count++;
					}
				}
			}
			
			if ((req == "no more" && count >= quantity) || (req == "no less" && count < quantity)) 
			{
				AddRequirement(missingBs, req, blobName, friendlyName, quantity);
				has = false;
			}
		}
		else if ((req == "no more global" || req == "no less global") && inv1 !is null) 
		{
			CBlob@[] blobs;
			getBlobsByName(blobName, @blobs);
		
			int count =	blobs.length;
			if ((req == "no more global" && count >= quantity) || (req == "no less global" && count < quantity)) 
			{
				AddRequirement(missingBs, req, blobName, friendlyName, quantity);
				has = false;
			}
		}
		else if (req == "tech")
		{
			int teamNum = playerBlob.getTeamNum();

			if (HasFakeTech(getRules(), blobName, teamNum))
			{
				// print(blobName + " is gud");
			}
			else
			{
				AddRequirement(missingBs, req, blobName, friendlyName, quantity);
				has = false;
			}
		}
		else if (req == "seclev feature")
		{
			if (playerBlob !is null)
			{
				CPlayer@ player = playerBlob.getPlayer();
				if (player !is null)
				{
					CSecurity@ security = getSecurity();
					
					if (security.checkAccess_Feature(player, blobName))
					{
						//print("has feature " + blobName);
					}
					else
					{
						//print("no access to seclev feature " + blobName);
						
						AddRequirement(missingBs, req, blobName, friendlyName, quantity);
						has = false;
					}
				}
				else
				{
					has = false;
				}
			}
			else
			{
				has = false;
			}
		}
	}

	missingBs.ResetBitIndex();
	bs.ResetBitIndex();
	return has;
}

bool hasRequirements(CInventory@ inv, CBitStream &inout bs, CBitStream &inout missingBs)
{
	return (hasRequirements(inv, null, bs, missingBs));
}

void server_TakeRequirements(CInventory@ inv1, CInventory@ inv2, CBitStream &inout bs)
{
	if (!isServer()) {
		return;
	}

	CBlob@ playerBlob = (inv1 !is null 
		? (inv1.getBlob().getPlayer() !is null ? inv1.getBlob() 
			: (inv2 !is null ? (inv2.getBlob().getPlayer() !is null ? inv2.getBlob() : null) : null)) 
		: (inv2 !is null ? (inv2.getBlob().getPlayer() !is null ? inv2.getBlob() : null) : null));

	CBlob@[] smartStorageBlobs;
	CBlob@[] baseBlobs;
	CBlob@[] backpacks;
	
	bool storageEnabled, safe_storageEnabled = false;
	bool hasBackpack = false;

	if (playerBlob !is null)
	{
		if (playerBlob.hasScript("Equipment.as"))
		{
			if (playerBlob.get_string("equipment2_torso") == "backpack")
			{
				CBlob@ backpack = getBlobByNetworkID(playerBlob.get_u16("backpack_id"));
				if (backpack !is null)
				{
					backpacks.push_back(backpack);
					hasBackpack = true;
				}
			}
		}

		int playerTeam = playerBlob.getTeamNum();
		
		if (playerTeam < 7)
		{
			TeamData@ team_data;
			GetTeamData(playerTeam, @team_data);

			if (team_data != null)
			{
				u16 upkeep = team_data.upkeep;
				u16 upkeep_cap = team_data.upkeep_cap;
				f32 upkeep_ratio = f32(upkeep) / f32(upkeep_cap);
				const bool faction_storage_enabled = team_data.storage_enabled;
				
				storageEnabled = upkeep_ratio <= UPKEEP_RATIO_PENALTY_STORAGE && faction_storage_enabled;
			}
		}

		{
			CBlob@[] baseBoobs;
			getBlobsByName("safe", @baseBoobs);

			for (u16 i = 0; i < baseBoobs.length; i++)
			{
				if (baseBoobs[i] !is null
				&& (baseBoobs[i].getPosition() - playerBlob.getPosition()).Length() < 250.0f)
				{
					string[] spl = baseBoobs[i].get_string("Owners").split("_");
					for (u16 j = 0; j < spl.length; j++)
					{
						if (playerBlob.getPlayer() !is null)
						{
							if (playerBlob.getPlayer().getUsername() == spl[j] || playerBlob.getPlayer().getUsername() == baseBoobs[i].get_string("Owner"))
							{
								baseBlobs.push_back(baseBoobs[i]);
								storageEnabled = true; 
								safe_storageEnabled = true;
								break;
							}
						}
					}
				}
			}
		}

		if (storageEnabled)
		{
			getBlobsByTag("smart_storage", @smartStorageBlobs);
			for (u8 i = 0; i < smartStorageBlobs.length; i++)
			{
				if (smartStorageBlobs[i].getTeamNum() != playerTeam)
				{
					smartStorageBlobs.erase(i);
					i--;
				}
			}
			getBlobsByTag("remote_storage", @baseBlobs);
			for (int i = 0; i < baseBlobs.length; i++)
			{
				if ((baseBlobs[i].getName() == "safe" ? safe_storageEnabled ? false : true : true) && baseBlobs[i].getTeamNum() != playerTeam)
				{
					baseBlobs.erase(i);
					i--;
				}
			}
		}
	}

	string req,blobName,friendlyName;
	u16 quantity;
	bs.ResetBitIndex();
	while (!bs.isBufferEnd()) 
	{
		ReadRequirement(bs, req, blobName, friendlyName, quantity);
		if (req == "blob") 
		{
			u16 taken = 0;

			if (inv1 !is null && taken < quantity) 
			{
				CBlob@ invBlob = inv1.getBlob();
				taken += Maths::Min(invBlob.getBlobCount(blobName), quantity - taken);
				invBlob.TakeBlob(blobName, quantity);
			}
			
			if (inv2 !is null && taken < quantity) 
			{
				CBlob@ invBlob = inv2.getBlob();
				u16 hold = taken;
				taken += Maths::Min(invBlob.getBlobCount(blobName), quantity - taken);
            	invBlob.TakeBlob(blobName, quantity - hold);
			}

			if (hasBackpack)
			{
				for (u8 i = 0; i < backpacks.length; i++)
				{
					CBlob@ backpack = backpacks[i];
					if (backpack is null) continue;

					CInventory@ binv = backpack.getInventory();
					if (binv is null) continue;
					
					if (taken < quantity) 
					{
						taken += Maths::Min(backpack.getBlobCount(blobName), quantity - taken);
						backpack.TakeBlob(blobName, quantity);
					}
				}
			}
			
			if (storageEnabled)
			{
				for (u8 i = 0; i < smartStorageBlobs.length; i++)
				{
					if (taken >= quantity)
					{
						break;
					}
					u16 hold = taken;
					taken += Maths::Min(smartStorageCheck(smartStorageBlobs[i], blobName), quantity - taken);
					smartStorageTake(smartStorageBlobs[i], blobName, quantity - hold);
					
					if (taken >= quantity)
					{
						break;
					}
					hold = taken;
					taken += Maths::Min(smartStorageBlobs[i].getBlobCount(blobName), quantity - taken);
					smartStorageBlobs[i].TakeBlob(blobName, quantity - hold);
				}
				
				for (int i = 0; i < baseBlobs.length; i++)
				{
					if (taken >= quantity)
					{
						break;
					}
					u16 hold = taken;
					taken += Maths::Min(baseBlobs[i].getBlobCount(blobName), quantity - taken);
					baseBlobs[i].TakeBlob(blobName, quantity - hold);
					if(baseBlobs[i].exists("compactor_resource")){
						if(baseBlobs[i].get_string("compactor_resource") == blobName){
							int dif = Maths::Min(baseBlobs[i].get_u32("compactor_quantity"), quantity - taken);
							taken += dif;
							baseBlobs[i].sub_u32("compactor_quantity",dif);
							baseBlobs[i].Sync("compactor_quantity",true);
						}
					}
				}
				
			}
		}
		/*else if (req == "coin") 
		{ // TODO...
			CPlayer@ player1 = inv1 !is null ? inv1.getBlob().getPlayer() : null;
			CPlayer@ player2 = inv2 !is null ? inv2.getBlob().getPlayer() : null;
			int taken = 0;
			if (player1 !is null) 
			{
				taken = Maths::Min(getRules().get_u32(player1.getUsername()+"coins"), quantity);
				getRules().set_u32(player1.getUsername()+"coins", getRules().get_u32(player1.getUsername()+"coins") - taken);
			}
			if (player2 !is null) 
			{
				taken = quantity - taken;
				taken = Maths::Min(getRules().get_u32(player2.getUsername()+"coins"), quantity);
				getRules().set_u32(player2.getUsername()+"coins", getRules().get_u32(player2.getUsername()+"coins") - taken);
			}
		}*/
		else if(req == "coin")
		{ // TODO...
			CPlayer@ player1=inv1 !is null ? inv1.getBlob().getPlayer() : null;
			CPlayer@ player2=inv2 !is null ? inv2.getBlob().getPlayer() : null;
			CRules@ rules = getRules();
			int taken = 0;
			if (player1 !is null) 
			{
				u32 current_coins = getRules().get_u32(player1.getUsername()+"coins");
				taken=Maths::Min(current_coins, quantity);
				getRules().set_u32(player1.getUsername()+"coins", (current_coins - taken));
			}
			if (player2 !is null) 
			{
				u32 current_coins = getRules().get_u32(player2.getUsername()+"coins");
				taken=quantity-taken;
				taken=Maths::Min(current_coins, quantity);
				getRules().set_u32(player2.getUsername()+"coins", (current_coins - taken));
			}
		}
	}

	bs.ResetBitIndex();
}

void server_TakeRequirements(CInventory@ inv, CBitStream &inout bs)
{
	server_TakeRequirements(inv, null, bs);
}
