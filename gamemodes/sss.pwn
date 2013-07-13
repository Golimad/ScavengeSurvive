/*==============================================================================


	Southclaw's Scavenge and Survive

		Big thanks to Onfire559/Adam for the initial concept and developing
		the idea a lot long ago with some very productive discussions!
		Recently influenced by Minecraft and DayZ, credits to the creators of
		those games and their fundamental mechanics and concepts.


==============================================================================*/


#include <a_samp>

#undef MAX_PLAYERS
#define MAX_PLAYERS	(32)

native IsValidVehicle(vehicleid);

#include <YSI\y_utils>				// By Y_Less:				http://forum.sa-mp.com/showthread.php?p=1696956
#include <YSI\y_va>
#include <YSI\y_timers>
#include <YSI\y_hooks>
#include <YSI\y_iterate>

#define DEFAULT_POS_X				(-907.5452)
#define DEFAULT_POS_Y				(272.7235)
#define DEFAULT_POS_Z				(1014.1449)

#include "../scripts/Core/Server/Hooks.pwn"

#include <formatex>					// By Slice:				http://forum.sa-mp.com/showthread.php?t=313488
#include <strlib>					// By Slice:				http://forum.sa-mp.com/showthread.php?t=362764
#include <md-sort>					// By Slice:				http://forum.sa-mp.com/showthread.php?t=343172

#define result GeoIP_result
#include <GeoIP>					// By Whitetiger:			http://forum.sa-mp.com/showthread.php?t=296171
#undef result

#include <sscanf2>					// By Y_Less:				http://forum.sa-mp.com/showthread.php?t=120356
#include <streamer>					// By Incognito:			http://forum.sa-mp.com/showthread.php?t=102865

#define time ctime_time
#include <CTime>					// By RyDeR:				http://forum.sa-mp.com/showthread.php?t=294054
#undef time

#include <IniFiles>					// By Southclaw:			http://forum.sa-mp.com/showthread.php?t=262795
#include <bar>						// By Torbido:				http://forum.sa-mp.com/showthread.php?t=113443
#include <playerbar>				// By Torbido/Southclaw:	http://pastebin.com/ZuLPd1K6
#include <FileManager>				// By JaTochNietDan:		http://forum.sa-mp.com/showthread.php?t=92246
#include <SIF/SIF>					// By Southclaw:			https://github.com/Southclaw/SIF
#include <WeaponData>				// By Southclaw:			https://gist.github.com/Southclaw/5934397


native WP_Hash(buffer[], len, const str[]);


//===================================================================Definitions


// Limits
#define MAX_MOTD_LEN				(128)
#define MAX_PLAYER_FILE				(MAX_PLAYER_NAME+16)
#define MAX_ADMIN					(32)
#define MAX_PASSWORD_LEN			(129)
#define MAX_SERVER_UPTIME			(3600 * 5)
#define MAX_SPAWNED_VEHICLES		(250)


// Files
#define PLAYER_DATA_FILE			"SSS/Player/%s.dat"
#define PLAYER_ITEM_FILE			"SSS/Inventory/%s.inv"
#define SPAWNS_DATA					"SSS/Spawns/%s.dat"
#define ACCOUNT_DATABASE			"SSS/Accounts.db"
#define SETTINGS_FILE				"SSS/Settings.txt"
#define ADMIN_DATA_FILE				"SSS/AdminList.txt"


// Database Rows
#define ROW_NAME					"name"
#define ROW_PASS					"pass"
#define ROW_GEND					"gend"
#define ROW_IPV4					"ipv4"
#define ROW_ALIVE					"alive"
#define ROW_SPAWN					"spawn"
#define ROW_ISVIP					"vip"
#define ROW_KARMA					"karma"										// TODO
#define ROW_LASTLOG					"lastlog"									// TODO
#define ROW_DATE					"date"
#define ROW_REAS					"reason"
#define ROW_BY						"by"
#define ROW_READ					"read"
#define ROW_TYPE					"type"
#define ROW_POSX					"posx"
#define ROW_POSY					"posy"
#define ROW_POSZ					"posz"
#define ROW_INFO					"info"
#define ROW_LEVEL					"level"


// Macros
#define t:%1<%2>					((%1)|=(%2))
#define f:%1<%2>					((%1)&=~(%2))

#define SetSpawn(%0,%1,%2,%3,%4)	SetSpawnInfo(%0, NO_TEAM, 0, %1, %2, %3, %4, 0,0,0,0,0,0)
#define GetFile(%0,%1)				format(%1, MAX_PLAYER_FILE, PLAYER_DATA_FILE, %0)
#define GetInvFile(%0,%1)			format(%1, MAX_PLAYER_FILE, PLAYER_ITEM_FILE, %0)

#define CMD:%1(%2)					forward cmd_%1(%2);\
									public cmd_%1(%2)

#define ACMD:%1[%2](%3)				forward cmd_%1_%2(%3);\
									public cmd_%1_%2(%3)

// Colours
#define YELLOW						0xFFFF00AA

#define RED							0xE85454AA
#define GREEN						0x33AA33AA
#define BLUE						0x33CCFFAA

#define ORANGE						0xFFAA00AA
#define GREY						0xAFAFAFAA
#define PINK						0xFFC0CBAA
#define NAVY						0x000080AA
#define GOLD						0xB8860BAA
#define LGREEN						0x00FD4DAA
#define TEAL						0x008080AA
#define BROWN						0xA52A2AAA
#define AQUA						0xF0F8FFAA

#define BLACK						0x000000AA
#define WHITE						0xFFFFFFAA


// Embedding Colours
#define C_YELLOW					"{FFFF00}"

#define C_RED						"{E85454}"
#define C_GREEN						"{33AA33}"
#define C_BLUE						"{33CCFF}"

#define C_ORANGE					"{FFAA00}"
#define C_GREY						"{AFAFAF}"
#define C_PINK						"{FFC0CB}"
#define C_NAVY						"{000080}"
#define C_GOLD						"{B8860B}"
#define C_LGREEN					"{00FD4D}"
#define C_TEAL						"{008080}"
#define C_BROWN						"{A52A2A}"
#define C_AQUA						"{F0F8FF}"

#define C_BLACK						"{000000}"
#define C_WHITE						"{FFFFFF}"

#define C_SPECIAL					"{0025AA}"


enum
{
	ATTACHSLOT_ITEM,		// 0
	ATTACHSLOT_BAG,			// 1
	ATTACHSLOT_USE,			// 2
	ATTACHSLOT_HOLSTER,		// 3
	ATTACHSLOT_HOLD,		// 4
	ATTACHSLOT_CUFFS,		// 5
	ATTACHSLOT_TORCH,		// 6
	ATTACHSLOT_HAT,			// 7
	ATTACHSLOT_BLOOD		// 8
}

enum
{
	DRUG_TYPE_ANTIBIOTIC,	// 0 - Remove infection
	DRUG_TYPE_PAINKILL,		// 1 - +10 HP, 5 minutes no darkness or knockouts from low HP
	DRUG_TYPE_LSD,			// 2 - Weather effects
	DRUG_TYPE_AIR,			// 3 - Health loss and death
	DRUG_TYPE_MORPHINE,		// 4 - Shaky screen and health regen
	DRUG_TYPE_ADRENALINE,	// 5 - No knockouts, camera shaking and slow health regen
	DRUG_TYPE_HEROINE		// 6 - Weather effects
}


#define KEYTEXT_INTERACT			"~k~~VEHICLE_ENTER_EXIT~"
#define KEYTEXT_PUT_AWAY			"~k~~CONVERSATION_YES~"
#define KEYTEXT_DROP_ITEM			"~k~~CONVERSATION_NO~"
#define KEYTEXT_INVENTORY			"~k~~GROUP_CONTROL_BWD~"
#define KEYTEXT_ENGINE				"~k~~CONVERSATION_YES~"
#define KEYTEXT_LIGHTS				"~k~~CONVERSATION_NO~"
#define KEYTEXT_DOORS				"~k~~TOGGLE_SUBMISSIONS~"
#define KEYTEXT_RADIO				"R"


//==============================================================SERVER VARIABLES


// Dialog IDs
enum
{
	d_NULL,

// Internal Dialogs
	d_Login,
	d_Register,
	d_WelcomeMessage,

// External Dialogs
	d_NotebookPage,
	d_NotebookEdit,
	d_NotebookError,

	d_SignEdit,
	d_Tires,
	d_Lights,
	d_Radio,
	d_GraveStone,

	d_ReportMenu,
	d_ReportPlayerList,
	d_ReportNameInput,
	d_ReportReason,

	d_ReportList,
	d_Report,
	d_ReportOptions,

	d_IssueSubmit,
	d_IssueList,
	d_Issue,

	d_DefenseSetPass,
	d_DefenseEnterPass,

	d_TransferAmmoToGun,
	d_TransferAmmoToBox,
	d_TransferAmmoGun2Gun,

	d_BanList,
	d_BanInfo
}

// Keypad IDs
enum
{
	k_ControlTower,
	k_MainGate,
	k_AirstripGate,
	k_BlastDoor,
	k_Storage,
	k_StorageWatch
}


new HORIZONTAL_RULE[] = {"-------------------------------------------------------------------------------------------------------------------------"};

//=====================Player Tag Names
new const AdminName[5][14]=
{
	"Player",			// 0
	"Game Master",		// 1
	"Moderator",		// 2
	"Administrator",	// 3
	"Developer"			// 4
},
AdminColours[5]=
{
	0xFFFFFFFF,			// 0
	0x5DFC0AFF,			// 1
	0x33CCFFAA,			// 2
	0x6600FFFF,			// 3
	0x6600FFFF			// 4
};


//=====================Server Global Settings
enum (<<=1)
{
	ChatLocked = 1,
	ServerLocked,
	Restarting
}
enum e_admin_data
{
	admin_Name[MAX_PLAYER_NAME],
	admin_Level
}


new
DB:		gAccounts,
		bServerGlobalSettings,
		gServerUptime,
		gMessageOfTheDay[MAX_MOTD_LEN],
		gAdminData[MAX_ADMIN][e_admin_data],
		gTotalAdmins,
		gPingLimit = 400;

new
	skin_MainM,
	skin_MainF,

	skin_Civ1M,
	skin_Civ2M,
	skin_Civ3M,
	skin_Civ4M,
	skin_MechM,
	skin_BikeM,
	skin_ArmyM,
	skin_ClawM,
	skin_FreeM,

	skin_Civ1F,
	skin_Civ2F,
	skin_Civ3F,
	skin_Civ4F,
	skin_ArmyF,
	skin_IndiF;

new
	anim_Blunt,
	anim_Stab;


//=====================Loot Types
enum
{
	loot_Civilian,
	loot_Industrial,
	loot_Police,
	loot_Military,
	loot_Medical,
	loot_CarCivilian,
	loot_CarIndustrial,
	loot_CarPolice,
	loot_CarMilitary,
	loot_Survivor
}

//=====================Item Types
new stock
ItemType:		item_Parachute		= INVALID_ITEM_TYPE,
ItemType:		item_Medkit			= INVALID_ITEM_TYPE,
ItemType:		item_HardDrive		= INVALID_ITEM_TYPE,
ItemType:		item_Key			= INVALID_ITEM_TYPE,
// 50
ItemType:		item_FireworkBox	= INVALID_ITEM_TYPE,
ItemType:		item_FireLighter	= INVALID_ITEM_TYPE,
ItemType:		item_Timer			= INVALID_ITEM_TYPE,
ItemType:		item_Explosive		= INVALID_ITEM_TYPE,
ItemType:		item_TntTimebomb	= INVALID_ITEM_TYPE,
ItemType:		item_Battery		= INVALID_ITEM_TYPE,
ItemType:		item_Fusebox		= INVALID_ITEM_TYPE,
ItemType:		item_Bottle			= INVALID_ITEM_TYPE,
ItemType:		item_Sign			= INVALID_ITEM_TYPE,
ItemType:		item_Armour			= INVALID_ITEM_TYPE,
// 60
ItemType:		item_Bandage		= INVALID_ITEM_TYPE,
ItemType:		item_FishRod		= INVALID_ITEM_TYPE,
ItemType:		item_Wrench			= INVALID_ITEM_TYPE,
ItemType:		item_Crowbar		= INVALID_ITEM_TYPE,
ItemType:		item_Hammer			= INVALID_ITEM_TYPE,
ItemType:		item_Shield			= INVALID_ITEM_TYPE,
ItemType:		item_Flashlight		= INVALID_ITEM_TYPE,
ItemType:		item_Taser			= INVALID_ITEM_TYPE,
ItemType:		item_LaserPoint		= INVALID_ITEM_TYPE,
ItemType:		item_Screwdriver	= INVALID_ITEM_TYPE,
// 70
ItemType:		item_MobilePhone	= INVALID_ITEM_TYPE,
ItemType:		item_Pager			= INVALID_ITEM_TYPE,
ItemType:		item_Rake			= INVALID_ITEM_TYPE,
ItemType:		item_HotDog			= INVALID_ITEM_TYPE,
ItemType:		item_EasterEgg		= INVALID_ITEM_TYPE,
ItemType:		item_Cane			= INVALID_ITEM_TYPE,
ItemType:		item_HandCuffs		= INVALID_ITEM_TYPE,
ItemType:		item_Bucket			= INVALID_ITEM_TYPE,
ItemType:		item_GasMask		= INVALID_ITEM_TYPE,
ItemType:		item_Flag			= INVALID_ITEM_TYPE,
// 80
ItemType:		item_DoctorBag		= INVALID_ITEM_TYPE,
ItemType:		item_Backpack		= INVALID_ITEM_TYPE,
ItemType:		item_Satchel		= INVALID_ITEM_TYPE,
ItemType:		item_Wheel			= INVALID_ITEM_TYPE,
ItemType:		item_MotionSense	= INVALID_ITEM_TYPE,
ItemType:		item_Accelerometer	= INVALID_ITEM_TYPE,
ItemType:		item_TntMotionMine	= INVALID_ITEM_TYPE,
ItemType:		item_IedBomb		= INVALID_ITEM_TYPE,
ItemType:		item_Pizza			= INVALID_ITEM_TYPE,
ItemType:		item_Burger			= INVALID_ITEM_TYPE,
// 90
ItemType:		item_BurgerBox		= INVALID_ITEM_TYPE,
ItemType:		item_Taco			= INVALID_ITEM_TYPE,
ItemType:		item_GasCan			= INVALID_ITEM_TYPE,
ItemType:		item_Clothes		= INVALID_ITEM_TYPE,
ItemType:		item_HelmArmy		= INVALID_ITEM_TYPE,
ItemType:		item_MediumBox		= INVALID_ITEM_TYPE,
ItemType:		item_SmallBox		= INVALID_ITEM_TYPE,
ItemType:		item_LargeBox		= INVALID_ITEM_TYPE,
ItemType:		item_AmmoTin		= INVALID_ITEM_TYPE,
ItemType:		item_Meat			= INVALID_ITEM_TYPE,
// 100
ItemType:		item_DeadLeg		= INVALID_ITEM_TYPE,
ItemType:		item_Torso			= INVALID_ITEM_TYPE,
ItemType:		item_LongPlank		= INVALID_ITEM_TYPE,
ItemType:		item_GreenGloop		= INVALID_ITEM_TYPE,
ItemType:		item_Capsule		= INVALID_ITEM_TYPE,
ItemType:		item_RadioPole		= INVALID_ITEM_TYPE,
ItemType:		item_SignShot		= INVALID_ITEM_TYPE,
ItemType:		item_Mailbox		= INVALID_ITEM_TYPE,
ItemType:		item_Pumpkin		= INVALID_ITEM_TYPE,
ItemType:		item_Nailbat		= INVALID_ITEM_TYPE,
// 110
ItemType:		item_ZorroMask		= INVALID_ITEM_TYPE,
ItemType:		item_Barbecue		= INVALID_ITEM_TYPE,
ItemType:		item_Headlight		= INVALID_ITEM_TYPE,
ItemType:		item_Pills			= INVALID_ITEM_TYPE,
ItemType:		item_AutoInjec		= INVALID_ITEM_TYPE,
ItemType:		item_BurgerBag		= INVALID_ITEM_TYPE,
ItemType:		item_CanDrink		= INVALID_ITEM_TYPE,
ItemType:		item_Detergent		= INVALID_ITEM_TYPE,
ItemType:		item_Dice			= INVALID_ITEM_TYPE,
ItemType:		item_Dynamite		= INVALID_ITEM_TYPE,
// 120
ItemType:		item_Door			= INVALID_ITEM_TYPE,
ItemType:		item_MetPanel		= INVALID_ITEM_TYPE,
ItemType:		item_SurfBoard		= INVALID_ITEM_TYPE,
ItemType:		item_CrateDoor		= INVALID_ITEM_TYPE,
ItemType:		item_CorPanel		= INVALID_ITEM_TYPE,
ItemType:		item_ShipDoor		= INVALID_ITEM_TYPE,
ItemType:		item_MetalPlate		= INVALID_ITEM_TYPE,
ItemType:		item_MetalStand		= INVALID_ITEM_TYPE,
ItemType:		item_WoodDoor		= INVALID_ITEM_TYPE,
ItemType:		item_WoodPanel		= INVALID_ITEM_TYPE,
// 130
ItemType:		item_Flare			= INVALID_ITEM_TYPE,
ItemType:		item_TntPhoneBomb	= INVALID_ITEM_TYPE,
ItemType:		item_ParaBag		= INVALID_ITEM_TYPE,
ItemType:		item_Keypad			= INVALID_ITEM_TYPE,
ItemType:		item_TentPack		= INVALID_ITEM_TYPE,
ItemType:		item_Campfire		= INVALID_ITEM_TYPE,
ItemType:		item_CowboyHat		= INVALID_ITEM_TYPE,
ItemType:		item_TruckCap		= INVALID_ITEM_TYPE,
ItemType:		item_BoaterHat		= INVALID_ITEM_TYPE,
ItemType:		item_BowlerHat		= INVALID_ITEM_TYPE,
// 140
ItemType:		item_PoliceCap		= INVALID_ITEM_TYPE,
ItemType:		item_TopHat			= INVALID_ITEM_TYPE,
ItemType:		item_Ammo9mm		= INVALID_ITEM_TYPE,
ItemType:		item_Ammo50			= INVALID_ITEM_TYPE,
ItemType:		item_AmmoBuck		= INVALID_ITEM_TYPE,
ItemType:		item_Ammo556		= INVALID_ITEM_TYPE,
ItemType:		item_Ammo357		= INVALID_ITEM_TYPE,
ItemType:		item_AmmoRocket		= INVALID_ITEM_TYPE,
ItemType:		item_MolotovEmpty	= INVALID_ITEM_TYPE,
ItemType:		item_Money			= INVALID_ITEM_TYPE,
// 150
ItemType:		item_PowerSupply	= INVALID_ITEM_TYPE,
ItemType:		item_StorageUnit	= INVALID_ITEM_TYPE,
ItemType:		item_Fluctuator		= INVALID_ITEM_TYPE,
ItemType:		item_IoUnit			= INVALID_ITEM_TYPE,
ItemType:		item_FluxCap		= INVALID_ITEM_TYPE,
ItemType:		item_DataInterface	= INVALID_ITEM_TYPE,
ItemType:		item_HackDevice		= INVALID_ITEM_TYPE,
ItemType:		item_PlantPot		= INVALID_ITEM_TYPE,
ItemType:		item_HerpDerp		= INVALID_ITEM_TYPE,
ItemType:		item_Parrot			= INVALID_ITEM_TYPE,
// 160
ItemType:		item_TripMine		= INVALID_ITEM_TYPE,
ItemType:		item_IedTimebomb	= INVALID_ITEM_TYPE,
ItemType:		item_IedMotionMine	= INVALID_ITEM_TYPE,
ItemType:		item_IedTripMine	= INVALID_ITEM_TYPE,
ItemType:		item_IedPhoneBomb	= INVALID_ITEM_TYPE,
ItemType:		item_EmpTimebomb	= INVALID_ITEM_TYPE,
ItemType:		item_EmpMotionMine	= INVALID_ITEM_TYPE,
ItemType:		item_EmpTripMine	= INVALID_ITEM_TYPE,
ItemType:		item_EmpPhoneBomb	= INVALID_ITEM_TYPE,
ItemType:		item_Gyroscope		= INVALID_ITEM_TYPE,
// 170
ItemType:		item_Motor			= INVALID_ITEM_TYPE,
ItemType:		item_StarterMotor	= INVALID_ITEM_TYPE,
ItemType:		item_FlareGun		= INVALID_ITEM_TYPE,
ItemType:		item_PetrolBomb		= INVALID_ITEM_TYPE;


//=====================Menus and Textdraws
new
Text:			DeathText			= Text:INVALID_TEXT_DRAW,
Text:			DeathButton			= Text:INVALID_TEXT_DRAW,
Text:			RestartCount		= Text:INVALID_TEXT_DRAW,
Text:			HitMark_centre		= Text:INVALID_TEXT_DRAW,
Text:			HitMark_offset		= Text:INVALID_TEXT_DRAW,

PlayerText:		ClassBackGround		= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		ClassButtonMale		= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		ClassButtonFemale	= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		WeaponAmmo			= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		HungerBarBackground	= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		HungerBarForeground	= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		WatchBackground		= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		WatchTime			= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		WatchBear			= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		WatchFreq			= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		ToolTip				= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		HelpTipText			= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		VehicleFuelText		= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		VehicleDamageText	= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		VehicleEngineText	= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		VehicleDoorsText	= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		VehicleNameText		= PlayerText:INVALID_TEXT_DRAW,
PlayerText:		VehicleSpeedText	= PlayerText:INVALID_TEXT_DRAW,

PlayerBar:		OverheatBar			= INVALID_PLAYER_BAR_ID,
PlayerBar:		ActionBar			= INVALID_PLAYER_BAR_ID,
PlayerBar:		KnockoutBar			= INVALID_PLAYER_BAR_ID,
				MiniMapOverlay;

//==============================================================PLAYER VARIABLES


forward OnLoad();
forward SetRestart(seconds);


//======================Library Predefinitions

#define NOTEBOOK_FILE			"SSS/Notebook/%s.dat"
#define MAX_NOTEBOOK_FILE_NAME	(MAX_PLAYER_NAME + 18)

//======================Libraries of Functions

#include "../scripts/utils/math.pwn"
#include "../scripts/utils/misc.pwn"
#include "../scripts/utils/camera.pwn"
#include "../scripts/utils/message.pwn"
#include "../scripts/utils/vehicle.pwn"
#include "../scripts/utils/vehicledata.pwn"
#include "../scripts/utils/zones.pwn"
#include "../scripts/utils/player.pwn"
#include "../scripts/utils/object.pwn"

//======================API Scripts

#include <SIF/Modules/Craft.pwn>
#include <SIF/Modules/Notebook.pwn>

#include "../scripts/API/Balloon/Balloon.pwn"
#include "../scripts/API/Line/Line.pwn"
#include "../scripts/API/Zipline/Zipline.pwn"
#include "../scripts/API/Ladder/Ladder.pwn"
#include "../scripts/API/SprayTag/SprayTag.pwn"

//======================Server Core

#include "../scripts/Core/Server/DataCollection.pwn"
#include "../scripts/Core/Server/TextTags.pwn"
#include "../scripts/Core/Server/Weather.pwn"
#include "../scripts/Core/Server/Whitelist.pwn"

//======================Data Load

#include "../scripts/Data/Weapon.pwn"
#include "../scripts/Data/Loot.pwn"
#include "../scripts/Data/Vehicle.pwn"

//======================Data Setup

#include "../scripts/Core/Weapon/Core.pwn"
#include "../scripts/Core/Loot/Spawn.pwn"
#include "../scripts/Core/Loot/HouseLoot.pwn"
#include "../scripts/Core/Vehicle/Spawn.pwn"
#include "../scripts/Core/Vehicle/PlayerVehicle.pwn"
#include "../scripts/Core/Vehicle/Core.pwn"

//======================Player Core

#include "../scripts/Core/Player/Core.pwn"
#include "../scripts/Core/Player/Accounts.pwn"
#include "../scripts/Core/Player/SaveLoad.pwn"
#include "../scripts/Core/Player/Spawn.pwn"
#include "../scripts/Core/Player/Drugs.pwn"
#include "../scripts/Core/Player/Damage.pwn"
#include "../scripts/Core/Player/Death.pwn"
#include "../scripts/Core/Player/Tutorial.pwn"
#include "../scripts/Core/Player/WelcomeMessage.pwn"
#include "../scripts/Core/Player/AntiCombatLog.pwn"
#include "../scripts/Core/Player/Chat.pwn"
#include "../scripts/Core/Player/AfkCheck.pwn"
#include "../scripts/Core/Player/DisallowActions.pwn"
#include "../scripts/Core/Player/Report.pwn"
#include "../scripts/Core/Player/HackDetect.pwn"

//======================UI

#include "../scripts/Core/UI/PlayerUI.pwn"
#include "../scripts/Core/UI/GlobalUI.pwn"
#include "../scripts/Core/UI/HoldAction.pwn"
#include "../scripts/Core/UI/Radio.pwn"
#include "../scripts/Core/UI/TipText.pwn"
#include "../scripts/Core/UI/ToolTipEvents.pwn"
#include "../scripts/Core/UI/Watch.pwn"
#include "../scripts/Core/UI/Keypad.pwn"

//======================Character

#include "../scripts/Core/Char/Food.pwn"
#include "../scripts/Core/Char/Clothes.pwn"
#include "../scripts/Core/Char/Hats.pwn"
#include "../scripts/Core/Char/Inventory.pwn"
#include "../scripts/Core/Char/Animations.pwn"
#include "../scripts/Core/Char/MeleeItems.pwn"
#include "../scripts/Core/Char/KnockOut.pwn"
#include "../scripts/Core/Char/Disarm.pwn"
#include "../scripts/Core/Char/Overheat.pwn"
#include "../scripts/Core/Char/Towtruck.pwn"
#include "../scripts/Core/Char/Holster.pwn"

//======================World

#include "../scripts/Core/World/Fuel.pwn"
#include "../scripts/Core/World/Barbecue.pwn"
#include "../scripts/Core/World/Defenses.pwn"
#include "../scripts/Core/World/GraveStone.pwn"
#include "../scripts/Core/World/SafeBox.pwn"
#include "../scripts/Core/World/Carmour.pwn"
#include "../scripts/Core/World/Tent.pwn"
#include "../scripts/Core/World/Campfire.pwn"
#include "../scripts/Core/World/HackTrap.pwn"
#include "../scripts/Core/World/Workbench.pwn"
#include "../scripts/Core/World/Food.pwn"
#include "../scripts/Core/World/Emp.pwn"

//======================Command Features

#include "../scripts/Core/Cmds/Commands.pwn"
#include "../scripts/Core/Cmds/GameMaster.pwn"
#include "../scripts/Core/Cmds/Moderator.pwn"
#include "../scripts/Core/Cmds/Administrator.pwn"
#include "../scripts/Core/Cmds/Dev.pwn"
#include "../scripts/Core/Cmds/Duty.pwn"
#include "../scripts/Core/Cmds/Ban.pwn"
#include "../scripts/Core/Cmds/Spectate.pwn"
#include "../scripts/Core/Cmds/Core.pwn"
#include "../scripts/Core/Cmds/BugReport.pwn"

//======================Items

#include "../scripts/Items/firework.pwn"
#include "../scripts/Items/bottle.pwn"
#include "../scripts/Items/TntTimeBomb.pwn"
#include "../scripts/Items/Sign.pwn"
#include "../scripts/Items/backpack.pwn"
#include "../scripts/Items/repair.pwn"
#include "../scripts/Items/shield.pwn"
#include "../scripts/Items/handcuffs.pwn"
#include "../scripts/Items/wheel.pwn"
#include "../scripts/Items/gascan.pwn"
#include "../scripts/Items/flashlight.pwn"
#include "../scripts/Items/armyhelm.pwn"
#include "../scripts/Items/crowbar.pwn"
#include "../scripts/Items/zorromask.pwn"
#include "../scripts/Items/headlight.pwn"
#include "../scripts/Items/pills.pwn"
#include "../scripts/Items/dice.pwn"
#include "../scripts/Items/armour.pwn"
#include "../scripts/Items/injector.pwn"
#include "../scripts/Items/medical.pwn"
#include "../scripts/Items/TntPhoneBomb.pwn"
#include "../scripts/Items/TntMotionMine.pwn"
#include "../scripts/Items/parachute.pwn"
#include "../scripts/Items/molotov.pwn"
#include "../scripts/Items/screwdriver.pwn"
#include "../scripts/Items/torso.pwn"
#include "../scripts/Items/ammotin.pwn"
#include "../scripts/Items/tentpack.pwn"
#include "../scripts/Items/campfire.pwn"
#include "../scripts/Items/cowboyhat.pwn"
#include "../scripts/Items/truckcap.pwn"
#include "../scripts/Items/boaterhat.pwn"
#include "../scripts/Items/bowlerhat.pwn"
#include "../scripts/Items/policecap.pwn"
#include "../scripts/Items/tophat.pwn"
#include "../scripts/Items/herpderp.pwn"
#include "../scripts/Items/candrink.pwn"
#include "../scripts/Items/TntTripMine.pwn"
#include "../scripts/Items/IedTimebomb.pwn"
#include "../scripts/Items/IedMotionMine.pwn"
//#include "../scripts/Items/IedTripMine.pwn"
#include "../scripts/Items/IedPhoneBomb.pwn"
#include "../scripts/Items/EmpTimebomb.pwn"
#include "../scripts/Items/EmpMotionMine.pwn"
//#include "../scripts/Items/EmpTripMine.pwn"
#include "../scripts/Items/EmpPhoneBomb.pwn"


//======================Post-code

#include "../scripts/Core/Server/Autosave.pwn"

//======================World

#include "../scripts/sa/sa.pwn"


main()
{
	new
		DBResult:tmpResult,
		rowCount;

	gAccounts = db_open(ACCOUNT_DATABASE);

	db_free_result(db_query(gAccounts, "CREATE TABLE IF NOT EXISTS `Player` (`"#ROW_NAME"`, `"#ROW_PASS"`, `"#ROW_IPV4"`, `"#ROW_ALIVE"`, `"#ROW_GEND"`, `"#ROW_SPAWN"`, `"#ROW_ISVIP"`, `"#ROW_KARMA"`)"));
	db_free_result(db_query(gAccounts, "CREATE TABLE IF NOT EXISTS `Bans` (`"#ROW_NAME"`, `"#ROW_IPV4"`, `"#ROW_DATE"`, `"#ROW_REAS"`, `"#ROW_BY"`)"));
	db_free_result(db_query(gAccounts, "CREATE TABLE IF NOT EXISTS `Reports` (`"#ROW_NAME"`, `"#ROW_REAS"`, `"#ROW_DATE"`, `"#ROW_READ"`, `"#ROW_TYPE"`, `"#ROW_POSX"`, `"#ROW_POSY"`, `"#ROW_POSZ"`, `"#ROW_INFO"`, `"#ROW_BY"`)"));
	db_free_result(db_query(gAccounts, "CREATE TABLE IF NOT EXISTS `Bugs` (`"#ROW_NAME"`, `"#ROW_REAS"`, `"#ROW_DATE"`)"));
	db_free_result(db_query(gAccounts, "CREATE TABLE IF NOT EXISTS `Whitelist` (`"#ROW_NAME"`)"));
	db_free_result(db_query(gAccounts, "CREATE TABLE IF NOT EXISTS `Admins` (`"#ROW_NAME"`, `"#ROW_LEVEL"`)"));

	tmpResult = db_query(gAccounts, "SELECT * FROM `Player`");
	rowCount = db_num_rows(tmpResult);

	db_free_result(tmpResult);
	LoadAdminData();

	file_Open(SETTINGS_FILE);

	print("\n-------------------------------------");
	print(" Southclaw's Scavenge And Survive");
	printf("\t%d\t- Visitors",			file_GetVal("Connections"));
	printf("\t%d\t\t- Accounts",		rowCount);
	printf("\t%d\t\t- Administrators",	gTotalAdmins);
	print("-------------------------------------\n");

	file_Close();
}




























public OnGameModeInit()
{
	print("Starting Main Game Script 'SSS' ...");

	SetGameModeText("Scavenge And Survive");
	SendRconCommand("mapname San Androcalypse");

	EnableStuntBonusForAll(false);
	ManualVehicleEngineAndLights();
	SetNameTagDrawDistance(0.0);
	UsePlayerPedAnims();
	AllowInteriorWeapons(true);
	DisableInteriorEnterExits();
	ShowNameTags(false);

	MiniMapOverlay = GangZoneCreate(-6000, -6000, 6000, 6000);

	if(!fexist(SETTINGS_FILE))
	{
		file_Create(SETTINGS_FILE);
	}
	else
	{
		file_Open(SETTINGS_FILE);
		file_GetStr("motd", gMessageOfTheDay);
		file_Close();
	}

	item_Parachute		= DefineItemType("Parachute",			371,	ITEM_SIZE_MEDIUM,	90.0, 0.0, 0.0,			0.0,	0.350542, 0.017385, 0.060469, 0.000000, 260.845062, 0.000000);
	item_Medkit			= DefineItemType("Medkit",				1580,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.269091, 0.166367, 0.000000, 90.000000, 0.000000, 0.000000);
	item_HardDrive		= DefineItemType("Hard Drive",			328,	ITEM_SIZE_SMALL,	90.0, 0.0, 0.0,			0.0);
	item_Key			= DefineItemType("Key",					327,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0);
// 50
	item_FireworkBox	= DefineItemType("Fireworks",			2039,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.0,	0.096996, 0.044811, 0.035688, 4.759557, 255.625167, 0.000000);
	item_FireLighter	= DefineItemType("Lighter",				327,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0);
	item_Timer			= DefineItemType("Timer Device",		2922,	ITEM_SIZE_SMALL,	90.0, 0.0, 0.0,			0.0,	0.231612, 0.050027, 0.017069, 0.000000, 343.020019, 180.000000);
	item_Explosive		= DefineItemType("Explosive",			1576,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.269091, 0.166367, 0.000000, 90.000000, 0.000000, 0.000000);
	item_TntTimebomb	= DefineItemType("Time Bomb",			1252,	ITEM_SIZE_SMALL,	270.0, 0.0, 0.0,		0.0);
	item_Battery		= DefineItemType("Battery",				1579,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.0,	0.269091, 0.166367, 0.000000, 90.000000, 0.000000, 0.000000);
	item_Fusebox		= DefineItemType("Fuse Box",			328,	ITEM_SIZE_SMALL,	90.0, 0.0, 0.0,			0.0);
	item_Bottle			= DefineItemType("Bottle",				1543,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.060376, 0.032063, -0.204802, 0.000000, 0.000000, 0.000000);
	item_Sign			= DefineItemType("Sign",				19471,	ITEM_SIZE_LARGE,	0.0, 0.0, 270.0,		0.0);
	item_Armour			= DefineItemType("Armour",				19515,	ITEM_SIZE_SMALL,	90.0, 0.0, 0.0,			0.0,	0.300333, -0.090105, 0.000000, 0.000000, 0.000000, 180.000000);
// 60
	item_Bandage		= DefineItemType("Bandage",				1575,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.269091, 0.166367, 0.000000, 90.000000, 0.000000, 0.000000);
	item_FishRod		= DefineItemType("Fishing Rod",			18632,	ITEM_SIZE_LARGE,	90.0, 0.0, 0.0,			0.0,	0.091496, 0.019614, 0.000000, 185.619995, 354.958374, 0.000000);
	item_Wrench			= DefineItemType("Wrench",				18633,	ITEM_SIZE_SMALL,	0.0, 90.0, 0.0,			0.0,	0.084695, -0.009181, 0.152275, 98.865089, 270.085449, 0.000000);
	item_Crowbar		= DefineItemType("Crowbar",				18634,	ITEM_SIZE_SMALL,	0.0, 90.0, 0.0,			0.0,	0.066177, 0.011153, 0.038410, 97.289527, 270.962554, 1.114514);
	item_Hammer			= DefineItemType("Hammer",				18635,	ITEM_SIZE_SMALL,	270.0, 0.0, 0.0,		0.0,	0.000000, -0.008230, 0.000000, 6.428617, 0.000000, 0.000000);
	item_Shield			= DefineItemType("Shield",				18637,	ITEM_SIZE_LARGE,	0.0, 0.0, 0.0,			0.0,	-0.262389, 0.016478, -0.151046, 103.597534, 6.474381, 38.321765);
	item_Flashlight		= DefineItemType("Flashlight",			18641,	ITEM_SIZE_SMALL,	90.0, 0.0, 0.0,			0.0,	0.061910, 0.022700, 0.039052, 190.938354, 0.000000, 0.000000);
	item_Taser			= DefineItemType("Taser",				18642,	ITEM_SIZE_SMALL,	90.0, 0.0, 0.0,			0.0,	0.079878, 0.014009, 0.029525, 180.000000, 0.000000, 0.000000);
	item_LaserPoint		= DefineItemType("Laser Pointer",		18643,	ITEM_SIZE_SMALL,	0.0, 0.0, 90.0,			0.0,	0.066244, 0.010838, -0.000024, 6.443027, 287.441467, 0.000000);
	item_Screwdriver	= DefineItemType("Screwdriver",			18644,	ITEM_SIZE_SMALL,	90.0, 0.0, 0.0,			0.0,	0.099341, 0.021018, 0.009145, 193.644195, 0.000000, 0.000000);
// 70
	item_MobilePhone	= DefineItemType("Mobile Phone",		18865,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.103904, -0.003697, -0.015173, 94.655189, 184.031860, 0.000000);
	item_Pager			= DefineItemType("Pager",				18875,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.097277, 0.027625, 0.013023, 90.819244, 191.427993, 0.000000);
	item_Rake			= DefineItemType("Rake",				18890,	ITEM_SIZE_SMALL,	90.0, 0.0, 0.0,			0.0,	-0.002599, 0.003984, 0.026356, 190.231231, 0.222518, 271.565185);
	item_HotDog			= DefineItemType("Hotdog",				19346,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.088718, 0.035828, 0.008570, 272.851745, 354.704772, 9.342185);
	item_EasterEgg		= DefineItemType("Easter Egg",			19345,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.000000, 0.000000, 0.000000, 0.000000, 90.000000, 0.000000);
	item_Cane			= DefineItemType("Cane",				19348,	ITEM_SIZE_MEDIUM,	270.0, 0.0, 0.0,		0.0,	0.041865, 0.022883, -0.079726, 4.967216, 10.411237, 0.000000);
	item_HandCuffs		= DefineItemType("Handcuffs",			19418,	ITEM_SIZE_SMALL,	270.0, 0.0, 0.0,		0.0,	0.077635, 0.011612, 0.000000, 0.000000, 90.000000, 0.000000);
	item_Bucket			= DefineItemType("Bucket",				19468,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.0,	0.293691, -0.074108, 0.020810, 148.961685, 280.067260, 151.782791);
	item_GasMask		= DefineItemType("Gas Mask",			19472,	ITEM_SIZE_SMALL,	180.0, 0.0, 0.0,		0.0,	0.062216, 0.055396, 0.001138, 90.000000, 0.000000, 180.000000);
	item_Flag			= DefineItemType("Flag",				2993,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.045789, 0.026306, -0.078802, 8.777217, 0.272155, 0.000000);
// 80
	item_DoctorBag		= DefineItemType("Doctor's Bag",		1210,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 90.0,			0.0,	0.285915, 0.078406, -0.009429, 0.000000, 270.000000, 0.000000);
	item_Backpack		= DefineItemType("Backpack",			3026,	ITEM_SIZE_MEDIUM,	270.0, 0.0, 90.0,		0.0,	0.470918, 0.150153, 0.055384, 181.319580, 7.513789, 163.436065);
	item_Satchel		= DefineItemType("Small Bag",			363,	ITEM_SIZE_MEDIUM,	270.0, 0.0, 0.0,		0.0,	0.052853, 0.034967, -0.177413, 0.000000, 261.397491, 349.759826);
	item_Wheel			= DefineItemType("Wheel",				1079,	ITEM_SIZE_CARRY,	0.0, 0.0, 90.0,			0.436,	-0.098016, 0.356168, -0.309851, 258.455596, 346.618103, 354.313049);
	item_MotionSense	= DefineItemType("Motion Sensor",		327,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.008151, 0.012682, -0.050635, 0.000000, 0.000000, 0.000000);
	item_Accelerometer	= DefineItemType("Accelerometer",		327,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.008151, 0.012682, -0.050635, 0.000000, 0.000000, 0.000000);
	item_TntMotionMine	= DefineItemType("Motion Mine",			1576,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.269091, 0.166367, 0.000000, 90.000000, 0.000000, 0.000000);
	item_IedBomb		= DefineItemType("IED",					2033,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.100000, 0.055999, 0.000000,  -86.099967, -112.099975, 100.099891);
	item_Pizza			= DefineItemType("Pizza",				1582,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.0,	0.320344, 0.064041, 0.168296, 92.941909, 358.492523, 14.915378);
	item_Burger			= DefineItemType("Burger",				2703,	ITEM_SIZE_SMALL,	-76.0, 257.0, -11.0,	0.0,	0.066739, 0.041782, 0.026828, 3.703052, 3.163064, 6.946474);
// 90
	item_BurgerBox		= DefineItemType("Burger",				2768,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.107883, 0.093265, 0.029676, 91.010627, 7.522015, 0.000000);
	item_Taco			= DefineItemType("Taco",				2769,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.069803, 0.057707, 0.039241, 0.000000, 78.877342, 0.000000);
	item_GasCan			= DefineItemType("Petrol Can",			1650,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.27,	0.143402, 0.027548, 0.063652, 0.000000, 253.648208, 0.000000);
	item_Clothes		= DefineItemType("Clothes",				2891,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.0,	0.269091, 0.166367, 0.000000, 90.000000, 0.000000, 0.000000);
	item_HelmArmy		= DefineItemType("Army Helmet",			19106,	ITEM_SIZE_MEDIUM,	345.0, 270.0, 0.0,		0.045,	0.184999, -0.007999, 0.046999, 94.199989, 22.700027, 4.799994);
	item_MediumBox		= DefineItemType("Medium Box",			3014,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.1844,	-0.027872, 0.145617, -0.246524, 243.789840, 347.397491, 349.931610);
	item_SmallBox		= DefineItemType("Small Box",			2969,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.0,	0.114177, 0.089762, -0.173014, 247.160079, 354.746368, 79.219100);
	item_LargeBox		= DefineItemType("Large Box",			1271,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.3112,	0.050000, 0.334999, -0.327000,  -23.900018, -10.200002, 11.799987);
	item_AmmoTin		= DefineItemType("Ammo Tin",			2040,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.082,	0.221075, 0.067746, 0.037494, 87.375968, 305.182189, 5.691741);
	item_Meat			= DefineItemType("Meat",				2804,	ITEM_SIZE_LARGE,	0.0, 0.0, 0.0,			0.0,	-0.051398, 0.017334, 0.189188, 270.495391, 353.340423, 167.069869);
// 100
	item_DeadLeg		= DefineItemType("Leg",					2905,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.0,	0.147815, 0.052444, -0.164205, 253.163970, 358.857666, 167.069869);
	item_Torso			= DefineItemType("Torso",				2907,	ITEM_SIZE_CARRY,	0.0, 0.0, 270.0,		0.0,	0.087207, 0.093263, -0.280867, 253.355865, 355.971557, 175.203552);
	item_LongPlank		= DefineItemType("Plank",				2937,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.0,	0.141491, 0.002142, -0.190920, 248.561920, 350.667724, 175.203552);
	item_GreenGloop		= DefineItemType("Unknown",				2976,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.0,	0.063387, 0.013771, -0.595982, 341.793945, 352.972686, 226.892105);
	item_Capsule		= DefineItemType("Capsule",				3082,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.0,	0.096439, 0.034642, -0.313377, 341.793945, 348.492706, 240.265777);
	item_RadioPole		= DefineItemType("Receiver",			3221,	ITEM_SIZE_LARGE,	0.0, 0.0, 0.0,			0.0,	0.081356, 0.034642, -0.167247, 0.000000, 0.000000, 240.265777);
	item_SignShot		= DefineItemType("Sign",				3265,	ITEM_SIZE_LARGE,	0.0, 0.0, 0.0,			0.0,	0.081356, 0.034642, -0.167247, 0.000000, 0.000000, 240.265777);
	item_Mailbox		= DefineItemType("Mailbox",				3407,	ITEM_SIZE_LARGE,	0.0, 0.0, 0.0,			0.0,	0.081356, 0.034642, -0.167247, 0.000000, 0.000000, 240.265777);
	item_Pumpkin		= DefineItemType("Pumpkin",				19320,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.3,	0.105948, 0.279332, -0.253927, 246.858016, 0.000000, 0.000000);
	item_Nailbat		= DefineItemType("Nailbat",				2045,	ITEM_SIZE_LARGE,	0.0, 0.0, 0.0);
// 110
	item_ZorroMask		= DefineItemType("Zorro Mask",			18974,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.193932, 0.050861, 0.017257, 90.000000, 0.000000, 0.000000);
	item_Barbecue		= DefineItemType("BBQ",					1481,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0, 			0.6745,	0.106261, 0.004634, -0.144552, 246.614654, 345.892211, 258.267395);
	item_Headlight		= DefineItemType("Headlight",			19280,	ITEM_SIZE_SMALL,	90.0, 0.0, 0.0,			0.0,	0.107282, 0.051477, 0.023807, 0.000000, 259.073913, 351.287475);
	item_Pills			= DefineItemType("Pills",				2709,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.09,	0.044038, 0.082106, 0.000000, 0.000000, 0.000000, 0.000000);
	item_AutoInjec		= DefineItemType("Injector",			2711,	ITEM_SIZE_SMALL,	90.0, 0.0, 0.0,			0.028,	0.145485, 0.020127, 0.034870, 0.000000, 260.512817, 349.967254);
	item_BurgerBag		= DefineItemType("Burger",				2663,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.205,	0.320356, 0.042146, 0.049817, 0.000000, 260.512817, 349.967254);
	item_CanDrink		= DefineItemType("Can",					2601,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.054,	0.064848, 0.059404, 0.017578, 0.000000, 359.136199, 30.178396);
	item_Detergent		= DefineItemType("Detergent",			1644,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.1,	0.081913, 0.047686, -0.026389, 95.526962, 0.546049, 358.890563);
	item_Dice			= DefineItemType("Dice",				1851,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.136,	0.031958, 0.131180, -0.214385, 69.012298, 16.103448, 10.308629);
	item_Dynamite		= DefineItemType("Dynamite",			1654,	ITEM_SIZE_MEDIUM);
// 120
	item_Door			= DefineItemType("Door",				1497,	ITEM_SIZE_CARRY,	90.0, 90.0, 0.0,		0.0,	0.313428, -0.507642, -1.340901, 336.984893, 348.837493, 113.141563);
	item_MetPanel		= DefineItemType("Metal Panel",			1965,	ITEM_SIZE_CARRY,	0.0, 90.0, 0.0,			0.0,	0.070050, 0.008440, -0.180277, 338.515014, 349.801025, 33.250347);
	item_SurfBoard		= DefineItemType("Surfboard",			2410,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.0,	-0.033293, 0.167523, -0.333268, 79.455276, 123.749847, 77.635063);
	item_CrateDoor		= DefineItemType("Crate Door",			2678,	ITEM_SIZE_CARRY,	90.0, 90.0, 0.0,		0.0,	0.077393, 0.015846, -0.013984, 337.887634, 172.861953, 68.495330);
	item_CorPanel		= DefineItemType("Metal Sheet",			2904,	ITEM_SIZE_CARRY,	90.0, 90.0, 0.0,		0.0,	-0.365094, 1.004213, -0.665850, 337.887634, 172.861953, 68.495330);
	item_ShipDoor		= DefineItemType("Ship Door",			2944,	ITEM_SIZE_CARRY,	180.0, 90.0, 0.0,		0.0,	0.134831, -0.039784, -0.298796, 337.887634, 172.861953, 162.198867);
	item_MetalPlate		= DefineItemType("Metal Sheet",			2952,	ITEM_SIZE_CARRY,	180.0, 90.0, 0.0,		0.0,	-0.087715, 0.483874, 1.109397, 337.887634, 172.861953, 162.198867);
	item_MetalStand		= DefineItemType("Metal Plate",			2978,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.0,	-0.106182, 0.534724, -0.363847, 278.598419, 68.350570, 57.954662);
	item_WoodDoor		= DefineItemType("Wood Panel",			3093,	ITEM_SIZE_CARRY,	0.0, 90.0, 0.0,			0.0,	0.117928, -0.025927, -0.203919, 339.650421, 168.808807, 337.216766);
	item_WoodPanel		= DefineItemType("Wood Panel",			5153,	ITEM_SIZE_CARRY,	360.0, 23.537, 0.0,		0.0,	-0.342762, 0.908910, -0.453703, 296.326019, 46.126548, 226.118209);
// 130
	item_Flare			= DefineItemType("Flare",				345,	ITEM_SIZE_SMALL);
	item_TntPhoneBomb	= DefineItemType("Phone Remote Bomb",	1576,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.269091, 0.166367, 0.000000, 90.000000, 0.000000, 0.000000);
	item_ParaBag		= DefineItemType("Parachute Bag",		371,	ITEM_SIZE_MEDIUM,	90.0, 0.0, 0.0,			0.0,	0.350542, 0.017385, 0.060469, 0.000000, 260.845062, 0.000000);
	item_Keypad			= DefineItemType("Keypad",				19273,	ITEM_SIZE_SMALL,	270.0, 0.0, 0.0,		0.0,	0.198234, 0.101531, 0.095477, 0.000000, 343.020019, 0.000000);
	item_TentPack		= DefineItemType("Tent Pack",			1279,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.0,	0.106261, 0.004634, -0.144552, 246.614654, 345.892211, 258.267395);
	item_Campfire		= DefineItemType("Campfire",			19475,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.0,	0.106261, 0.004634, -0.144552, 246.614654, 345.892211, 258.267395);
	item_CowboyHat		= DefineItemType("Cowboy Hat",			18962,	ITEM_SIZE_MEDIUM,	0.0, 270.0, 0.0,		0.0427,	0.232999, 0.032000, 0.016000, 0.000000, 2.700027, -67.300010);
	item_TruckCap		= DefineItemType("Trucker Cap",			18961,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.01,	0.225000, 0.034000, 0.014000, 81.799942, 7.699998, 179.999954);
	item_BoaterHat		= DefineItemType("Boater Hat",			18946,	ITEM_SIZE_MEDIUM,	-12.18, 268.14, 0.0,	0.318,	0.225000, 0.034000, 0.014000, 81.799942, 7.699998, 179.999954);
	item_BowlerHat		= DefineItemType("Bowler Hat",			18947,	ITEM_SIZE_MEDIUM,	-12.18, 268.14, 0.0,	0.01,	0.225000, 0.034000, 0.014000, 81.799942, 7.699998, 179.999954);
//140
	item_PoliceCap		= DefineItemType("Police Cap",			18636,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.318,	0.225000, 0.034000, 0.014000, 81.799942, 7.699998, 179.999954);
	item_TopHat			= DefineItemType("Top Hat",				19352,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			-0.023,	0.225000, 0.034000, 0.014000, 81.799942, 7.699998, 179.999954);
	item_Ammo9mm		= DefineItemType("9mm Rounds",			2037,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.082,	0.221075, 0.067746, 0.037494, 87.375968, 305.182189, 5.691741);
	item_Ammo50			= DefineItemType(".50 Rounds",			2037,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.082,	0.221075, 0.067746, 0.037494, 87.375968, 305.182189, 5.691741);
	item_AmmoBuck		= DefineItemType("Buckshot Shells",		2038,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.082,	0.221075, 0.067746, 0.037494, 87.375968, 305.182189, 5.691741);
	item_Ammo556		= DefineItemType("5.56 Rounds",			2040,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.082,	0.221075, 0.067746, 0.037494, 87.375968, 305.182189, 5.691741);
	item_Ammo357		= DefineItemType(".357 Rounds",			2039,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.082,	0.221075, 0.067746, 0.037494, 87.375968, 305.182189, 5.691741);
	item_AmmoRocket		= DefineItemType("Rockets",				3016,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.0,	0.081998, 0.081005, -0.195033, 247.160079, 336.014343, 347.379638);
	item_MolotovEmpty	= DefineItemType("Empty Molotov",		344,	ITEM_SIZE_SMALL,	-4.0, 0.0, 0.0,			0.1728,	0.000000, -0.004999, 0.000000,  0.000000, 0.000000, 0.000000);
	item_Money			= DefineItemType("Pre-War Money",		1212,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.133999, 0.022000, 0.018000,  -90.700004, -11.199998, -101.600013);
// 150
	item_PowerSupply	= DefineItemType("Power Supply",		3016,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.255000, -0.054000, 0.032000, -87.499984, -7.599999, -7.999998);
	item_StorageUnit	= DefineItemType("Storage Unit",		328,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0);
	item_Fluctuator		= DefineItemType("Fluctuator Unit",		343,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0);
	item_IoUnit			= DefineItemType("I/O Unit",			19273,	ITEM_SIZE_SMALL,	270.0, 0.0, 0.0,		0.0,	0.198234, 0.101531, 0.095477, 0.000000, 343.020019, 0.000000);
	item_FluxCap		= DefineItemType("Flux Capacitor",		343,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0);
	item_DataInterface	= DefineItemType("Data Interface",		19273,	ITEM_SIZE_SMALL,	270.0, 0.0, 0.0,		0.0,	0.198234, 0.101531, 0.095477, 0.000000, 343.020019, 0.000000);
	item_HackDevice		= DefineItemType("Hack Interface",		364,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.134000, 0.080000, -0.037000,  84.299949, 3.399998, 9.400002);
	item_PlantPot		= DefineItemType("Plant Pot",			2203,	ITEM_SIZE_CARRY,	0.0, 0.0, 0.0,			0.138,	-0.027872, 0.145617, -0.246524, 243.789840, 347.397491, 349.931610);
	item_HerpDerp		= DefineItemType("Derpification Unit",	19513,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.103904, -0.003697, -0.015173, 94.655189, 184.031860, 0.000000);
	item_Parrot			= DefineItemType("Sebastian",			19078,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.131000, 0.021000, 0.005999,  -86.000091, 6.700000, -106.300018);
// 160
	item_TripMine		= DefineItemType("Proximity Mine",		1576,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.269091, 0.166367, 0.000000, 90.000000, 0.000000, 0.000000);
	item_IedTimebomb	= DefineItemType("Timed IED",			2033,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.100000, 0.055999, 0.000000,  -86.099967, -112.099975, 100.099891);
	item_IedMotionMine	= DefineItemType("Motion IED",			2033,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.100000, 0.055999, 0.000000,  -86.099967, -112.099975, 100.099891);
	item_IedTripMine	= DefineItemType("Proximity IED",		2033,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.100000, 0.055999, 0.000000,  -86.099967, -112.099975, 100.099891);
	item_IedPhoneBomb	= DefineItemType("Phone Remote IED",	2033,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.100000, 0.055999, 0.000000,  -86.099967, -112.099975, 100.099891);
	item_EmpTimebomb	= DefineItemType("Timed EMP",			343,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0);
	item_EmpMotionMine	= DefineItemType("Motion EMP",			343,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0);
	item_EmpTripMine	= DefineItemType("Proximity EMP",		343,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0);
	item_EmpPhoneBomb	= DefineItemType("Phone Remote EMP",	343,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0);
	item_Gyroscope		= DefineItemType("Gyroscope Unit",		1945,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.180000, 0.085000, 0.009000,  -86.099967, -112.099975, 92.699890);
// 170
	item_Motor			= DefineItemType("Motor",				2006,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.129999, 0.087999, 0.009000,  -86.099967, -112.099975, 92.699890);
	item_StarterMotor	= DefineItemType("Starter Motor",		2006,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.0,	0.129999, 0.087999, 0.009000,  -86.099967, -112.099975, 92.699890);
	item_FlareGun		= DefineItemType("Flare Gun",			2034,	ITEM_SIZE_SMALL,	0.0, 0.0, 0.0,			0.0,	0.160999, 0.035000, 0.058999,  84.400062, 0.000000, 0.000000);
	item_PetrolBomb		= DefineItemType("Petrol Bomb",			1650,	ITEM_SIZE_MEDIUM,	0.0, 0.0, 0.0,			0.27,	0.143402, 0.027548, 0.063652, 0.000000, 253.648208, 0.000000);


// 1656 - CUBOID SHAPE, CARRY ITEM
// 1719 - SMALL COMPUTER TYPE DEVICE
// 1898 - SMALL SPIN CLICKER
// 1899 - VERY SMALL SINGLE CHIP
// 1901 - SMALL BLUE CHIPS STACK
// 1952 - SMALL RECORD NEEDLE
// 1960 - RECORD
// 2060 - SANDBAG
// 2277 - PICTURE OF A CAT
// 2352 - T SHAPED SMALL OBJ
// 2590 - SPIKEY HOOK, SCHYTHE?



	anim_Blunt = DefineAnimSet();
	anim_Stab = DefineAnimSet();

	AddAnimToSet(anim_Blunt, 26, 3.0);
	AddAnimToSet(anim_Blunt, 17, 4.0);
	AddAnimToSet(anim_Blunt, 18, 6.0);
	AddAnimToSet(anim_Blunt, 19, 8.0);
	AddAnimToSet(anim_Stab, 751, 18.8);

	SetItemAnimSet(item_Wrench,			anim_Blunt);
	SetItemAnimSet(item_Crowbar,		anim_Blunt);
	SetItemAnimSet(item_Hammer,			anim_Blunt);
	SetItemAnimSet(item_Rake,			anim_Blunt);
	SetItemAnimSet(item_Cane,			anim_Blunt);
	SetItemAnimSet(item_Taser,			anim_Stab);
	SetItemAnimSet(item_Screwdriver,	anim_Stab);


	DefineFoodItem(item_HotDog,			20.0, 1, 0);
	DefineFoodItem(item_Pizza,			50.0, 0, 0);
	DefineFoodItem(item_Burger,			25.0, 1, 0);
	DefineFoodItem(item_BurgerBox,		25.0, 0, 0);
	DefineFoodItem(item_Taco,			15.0, 0, 0);
	DefineFoodItem(item_BurgerBag,		30.0, 0, 0);
	DefineFoodItem(item_Meat,			65.0, 1, 0);
	DefineFoodItem(item_Bottle,			1.0, 0, 1);
	DefineFoodItem(item_CanDrink,		1.0, 0, 1);


	DefineDefenseItem(item_Door,		180.0000, 90.0000, 0.0000, -0.0331,		1, 1, 0);
	DefineDefenseItem(item_MetPanel,	90.0000, 90.0000, 0.0000, -0.0092,		2, 1, 1);
	DefineDefenseItem(item_SurfBoard,	90.0000, 0.0000, 0.0000, 0.2650,		1, 1, 1);
	DefineDefenseItem(item_CrateDoor,	0.0000, 90.0000, 0.0000, 0.7287,		3, 1, 1);
	DefineDefenseItem(item_CorPanel,	0.0000, 90.0000, 0.0000, 1.1859,		2, 1, 1);
	DefineDefenseItem(item_ShipDoor,	90.0000, 90.0000, 0.0000, 1.3966,		4, 1, 1);
	DefineDefenseItem(item_MetalPlate,	90.0000, 90.0000, 0.0000, 2.1143,		4, 1, 1);
	DefineDefenseItem(item_MetalStand,	90.0000, 0.0000, 0.0000, 0.5998,		3, 1, 1);
	DefineDefenseItem(item_WoodDoor,	90.0000, 90.0000, 0.0000, -0.0160,		1, 1, 0);
	DefineDefenseItem(item_WoodPanel,	90.0000, 0.0000, 20.0000, 1.0284,		3, 1, 1);


	DefineItemCombo(item_Medkit,		item_Bandage,		item_DoctorBag);
	DefineItemCombo(ItemType:4,			item_Parachute,		item_ParaBag,		.returnitem1 = 0, .returnitem2 = 1);
	DefineItemCombo(item_Bottle,		item_Bandage,		item_MolotovEmpty);

	DefineItemCombo(item_FireworkBox,	item_PowerSupply,	item_IedBomb);
	DefineItemCombo(item_GasCan,		item_PowerSupply,	item_PetrolBomb);
	DefineItemCombo(item_Explosive,		item_Timer,			item_TntTimebomb);
	DefineItemCombo(item_Explosive,		item_MotionSense,	item_TripMine);
	DefineItemCombo(item_Explosive,		item_MobilePhone,	item_TntPhoneBomb);
	DefineItemCombo(item_Explosive,		item_Accelerometer,	item_TntMotionMine);
	DefineItemCombo(item_IedBomb,		item_Timer,			item_IedTimebomb);
	DefineItemCombo(item_IedBomb,		item_Accelerometer,	item_IedMotionMine);
	DefineItemCombo(item_IedBomb,		item_MotionSense,	item_IedTripMine);
	DefineItemCombo(item_IedBomb,		item_MobilePhone,	item_IedPhoneBomb);
	DefineItemCombo(item_Fluctuator,	item_Timer,			item_EmpTimebomb);
	DefineItemCombo(item_Fluctuator,	item_Accelerometer,	item_EmpMotionMine);
	DefineItemCombo(item_Fluctuator,	item_MotionSense,	item_EmpTripMine);
	DefineItemCombo(item_Fluctuator,	item_MobilePhone,	item_EmpPhoneBomb);

	DefineItemCombo(item_MediumBox,		item_MediumBox,		item_Campfire);
	DefineItemCombo(item_SmallBox,		item_MediumBox,		item_Campfire);
	DefineItemCombo(item_SmallBox,		item_SmallBox,		item_Campfire);

	DefineItemCombo(item_Battery,		item_Fusebox,		item_PowerSupply);
	DefineItemCombo(item_Timer,			item_HardDrive,		item_StorageUnit);
	DefineItemCombo(item_Taser,			item_RadioPole,		item_Fluctuator);
	DefineItemCombo(item_MobilePhone,	item_Keypad,		item_IoUnit);
	DefineItemCombo(item_PowerSupply,	item_Fluctuator,	item_FluxCap);
	DefineItemCombo(item_StorageUnit,	item_IoUnit,		item_DataInterface);
	DefineItemCombo(item_FluxCap,		item_DataInterface,	item_HackDevice);
	WriteAllCombosToFile();


	DefineLootIndex(loot_Civilian);
	DefineLootIndex(loot_Industrial);
	DefineLootIndex(loot_Police);
	DefineLootIndex(loot_Military);
	DefineLootIndex(loot_Medical);
	DefineLootIndex(loot_CarCivilian);
	DefineLootIndex(loot_CarIndustrial);
	DefineLootIndex(loot_CarPolice);
	DefineLootIndex(loot_CarMilitary);
	DefineLootIndex(loot_Survivor);


	skin_MainM	= DefineSkinItem(60,	"Civilian",			1, 0.0);
	skin_MainF	= DefineSkinItem(192,	"Civilian",			0, 0.0);

	skin_Civ1M	= DefineSkinItem(170,	"Civilian",			1, 1.0);
	skin_Civ2M	= DefineSkinItem(188,	"Civilian",			1, 1.0);
	skin_Civ3M	= DefineSkinItem(44,	"Civilian",			1, 1.0);
	skin_Civ4M	= DefineSkinItem(206,	"Civilian",			1, 1.0);
	skin_MechM	= DefineSkinItem(50,	"Mechanic",			1, 0.6);
	skin_BikeM	= DefineSkinItem(254,	"Biker",			1, 0.3);
	skin_ArmyM	= DefineSkinItem(287,	"Military",			1, 0.2);
	skin_ClawM	= DefineSkinItem(101,	"Southclaw",		1, 0.1);
	skin_FreeM	= DefineSkinItem(156,	"Morgan Freeman",	1, 0.01);

	skin_Civ1F	= DefineSkinItem(65,	"Civilian",			0, 0.8);
	skin_Civ2F	= DefineSkinItem(93,	"Civilian",			0, 0.8);
	skin_Civ3F	= DefineSkinItem(233,	"Civilian",			0, 0.8);
	skin_Civ4F	= DefineSkinItem(193,	"Civilian",			0, 0.8);
	skin_ArmyF	= DefineSkinItem(191,	"Military",			0, 0.2);
	skin_IndiF	= DefineSkinItem(131,	"Indian",			0, 0.1);

	DefineSafeboxType("Medium Box",		item_MediumBox,		6, 6, 3, 2);
	DefineSafeboxType("Small Box", 		item_SmallBox,		4, 2, 1, 0);
	DefineSafeboxType("Large Box", 		item_LargeBox,		10, 8, 6, 6);
	DefineSafeboxType("Capsule", 		item_Capsule,		2, 2, 0, 0);

	for(new i; i < _:item_Parachute; i++)
	{
		switch(i)
		{
			case 2, 3, 5, 6, 7, 8, 15:
				SetItemTypeHolsterable(ItemType:i, 1, 0.123097, -0.129424, -0.139251, 0.000000, 301.455871, 0.000000, 300, "PED", "PHONE_IN"); // Small arms

			case 1, 4, 16..18, 22..24, 10..13, 26, 28, 32, 39..41, 43, 44, 45:
				SetItemTypeHolsterable(ItemType:i, 8, 0.061868, 0.008748, 0.136682, 254.874801, 0.318417, 0.176398, 300, "PED", "PHONE_IN"); // Small arms

			case 25, 27, 29, 30, 31, 33, 34:
				SetItemTypeHolsterable(ItemType:i, 1, 0.214089, -0.126031, 0.114131, 0.000000, 159.522552, 0.000000, 800, "GOGGLES", "GOGGLES_PUT_ON"); // Two handed

			case 35, 36:
				SetItemTypeHolsterable(ItemType:i, 1, 0.181966, -0.238397, -0.094830, 252.791229, 353.893859, 357.529418, 800, "GOGGLES", "GOGGLES_PUT_ON"); // Rocket
		}
	}

	// Initiation Code

	CallLocalFunction("OnLoad", "");

	// Data From Files

	LoadVehicles(true);
	LoadSafeboxes(true);
	LoadTents(true);
	LoadDefenses();


	for(new i; i < MAX_PLAYERS; i++)
	{
		ResetVariables(i);
	}

	defer AutoSave();

	return 1;
}

public OnGameModeExit()
{
	SavePlayerVehicles(true);
	SaveSafeboxes(true);
	SaveTents(true);
	SaveDefenses();

	db_close(gAccounts);

	return 1;
}

public SetRestart(seconds)
{
	printf("Restarting server in: %ds", seconds);
	gServerUptime = MAX_SERVER_UPTIME - seconds;
}

RestartGamemode()
{
	t:bServerGlobalSettings<Restarting>;

	foreach(new i : Player)
	{
		Logout(i);
		ResetVariables(i);
	}

	SendRconCommand("gmx");

	MsgAll(BLUE, " ");
	MsgAll(BLUE, " ");
	MsgAll(BLUE, " ");
	MsgAll(BLUE, " ");
	MsgAll(BLUE, " ");
	MsgAll(BLUE, " ");
	MsgAll(BLUE, " ");
	MsgAll(BLUE, " ");
	MsgAll(BLUE, HORIZONTAL_RULE);
	MsgAll(YELLOW, " >  The Server Is Restarting, Please Wait...");
	MsgAll(BLUE, HORIZONTAL_RULE);
}

task GameUpdate[1000]()
{
	if(gServerUptime >= MAX_SERVER_UPTIME)
	{
		RestartGamemode();
	}

	if(gServerUptime >= MAX_SERVER_UPTIME - 3600)
	{
		new str[36];
		format(str, 36, "Server Restarting In:~n~%02d:%02d", (MAX_SERVER_UPTIME - gServerUptime) / 60, (MAX_SERVER_UPTIME - gServerUptime) % 60);
		TextDrawSetString(RestartCount, str);
		TextDrawShowForAll(RestartCount);
	}

	WeatherUpdate();

	gServerUptime++;
}

task GlobalAnnouncement[600000]()
{
	MsgAll(YELLOW, " >  Confused? Check out the Wiki: "#C_ORANGE"scavenge-survive.wikia.com "#C_YELLOW"or: "#C_ORANGE"empire-bay.com");
}

/*

	new h, m, s;
	gettime(h, m, s);

	if(h == 0 && m == 0 && s < 1)
	{
		ArchiveServerLog();
	}

ArchiveServerLog()
{
	#define SERVER_LOG_PATH		"./server_log.txt"
	#define SERVER_LOG_DIR		"./logs/"

	if(!file_exists(SERVER_LOG_PATH))
	{
		print("ERROR: Server log file not found");
		return;
	}

	if(!dir_exists(SERVER_LOG_DIR))
	{
		print("ERROR: Server log archive directory not found");
		return;
	}

	print("Archiving Server Log");

	printf("Return: %d", file_move(SERVER_LOG_PATH, "./logs/server_log.txt"));

	return;
}
*/
