//archer HUD
//by The Sopranos

#include "nActorHUDStartPos.as";

const string iconsFilename = "jclass.png";
const int slotsSize = 6;

void onInit( CSprite@ this )
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	this.getBlob().set_u8("gui_HUD_slots_width", slotsSize);
}

void ManageCursors( CBlob@ this )
{
	// set cursor
	if (getHUD().hasButtons()) {
		getHUD().SetDefaultCursor();
	}
	else {
		if (this.isAttached() && this.isAttachedToPoint("GUNNER")) {
			getHUD().SetCursorImage("Entities/Characters/Archer/ArcherCursor.png", Vec2f(32,32));
			getHUD().SetCursorOffset( Vec2f(-32, -32) );
		}
		else {
			getHUD().SetCursorImage("Entities/Characters/Builder/BuilderCursor.png");
		}

	}
}

void onRender( CSprite@ this )
{
	if (g_videorecording)
		return;

    CBlob@ blob = this.getBlob();
	CPlayer@ player = blob.getPlayer();

	if (!blob.isMyPlayer()) return;

	ManageCursors( blob );
											
	// draw inventory

    Vec2f tl = getActorHUDStartPosition(blob, slotsSize);
    DrawInventoryOnHUD( blob, tl );

	// draw coins

	const int coins = player !is null ? getRules().get_u32(player.getUsername()+"coins") : 0;
	DrawCoinsOnHUD( blob, coins, tl, slotsSize-2 );

	// draw class icon 
	GUI::DrawIcon( iconsFilename, 0, Vec2f(16, 16), Vec2f(10, 10), 1.0f);
}
