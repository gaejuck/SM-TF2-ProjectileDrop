#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf_custom_attributes>
#pragma newdecls required
#pragma semicolon 1

// This is some wonky bollocks so I need to explain this.
// In spite of the measures I've created previously, a Github user by the name of SnowySnowtime has reported that this plugin causes a memory leak, one I did not catch due to the length of time it takes for this memory leak to make itself known.
// As such, rather than having one datapack which gets created and passed onto functions by this plugin, I've decided to take an alternate approach.
// The DataPack list is now an array, accompanied by another array, DataPackEntRefNumber, the int array stores an entity reference corresponding to the entity reference that the DataPack uses, I didn't want to read through DataPacks to find an entity reference because I figured it would be far more costly for performance to do so.
// FreeDataPack is a integer that is intended to document what number in the array can be written, both arrays will cycle through all 256 entries and store data, FreeDataPack is designed to let the plugin know which array should be written over next, theoretically this does mean that a DataPack for one weapon can override another weapon's datapack, but considering 256 projectiles would have to be created before the first projectile is destroyed, for the most part this should be fine.
int FreeDataPack;
int DataPackEntRefNumber[256];
DataPack AttrPackDrop[256];

public void OnPluginStart()
{
	FreeDataPack = 0;
}

public void OnEntityCreated(int CreatedEntity, const char[] ClassName)
{
	if (StrEqual(ClassName,"tf_projectile_rocket"))
	{
		SDKHook(CreatedEntity, SDKHook_Spawn, Hook_OnRocketSpawn);
	}
	// Cow Mangler 5000, AKA the direct upgrade to stock launcher
	else if (StrEqual(ClassName, "tf_projectile_energy_ball"))
	{
		SDKHook(CreatedEntity, SDKHook_Spawn, Hook_OnRocketSpawn);
	}
	// Righteous Bison-type projectile
	else if (StrEqual(ClassName, "tf_projectile_energy_ring"))
	{
		SDKHook(CreatedEntity, SDKHook_Spawn, Hook_OnRocketSpawn);
	}
}

public void Hook_OnRocketSpawn(int CreatedEntity)
{
	int RocketOwner = GetEntPropEnt(CreatedEntity, Prop_Data, "m_hOwnerEntity");
	if(RocketOwner > 0 && RocketOwner <= MaxClients)
	{
		int CreatedEntityRef = EntIndexToEntRef(CreatedEntity);

		// Checks any slot from the launcher, this is on the frame the rocket is created so we should be fine?
		int Weapon = GetEntPropEnt(RocketOwner, Prop_Send, "m_hActiveWeapon");

		int RocketLaunchValue = TF2CustAttr_GetInt(Weapon, "rocket launch");
		int RocketDropValue = TF2CustAttr_GetInt(Weapon, "rocket drop");

		// Create a data pack with the rocket entity as well as the two possible attributes, this saves calling TF2CustAttr_GetInt every frame a rocket exists like previous iterations of the code.
		AttrPackDrop[FreeDataPack] = new DataPack();
		WritePackCell(AttrPackDrop[FreeDataPack], CreatedEntityRef);
		WritePackCell(AttrPackDrop[FreeDataPack], RocketLaunchValue);
		WritePackCell(AttrPackDrop[FreeDataPack], RocketDropValue);
		// Store the created entity reference associated with the data pack
		DataPackEntRefNumber[FreeDataPack] = CreatedEntityRef;

		// The game doesn't like it when we execute the function immediately, presumably the velocity stuff doesn't start until the next frame?
		RequestFrame(RocketLaunch, AttrPackDrop[FreeDataPack]);

		FreeDataPack = FreeDataPack++;
	}
}

public void RocketLaunch(DataPack AttrEntPack)
{
	// You normally don't need to do this when the DataPack has just been created, but it doesn't hurt to have this here and it saves me doing something stupid down the line
	ResetPack(AttrEntPack);
	int RocketEnt = EntRefToEntIndex(ReadPackCell(AttrEntPack));
	int RocketLaunchValue = ReadPackCell(AttrEntPack);
	int RocketDropValue = ReadPackCell(AttrEntPack);
	if (IsValidEntity(RocketEnt))
	{
		float RocketAngle[3];
		float RocketVelocity[3];

		GetEntPropVector(RocketEnt, Prop_Data, "m_angRotation", RocketAngle);
		GetEntPropVector(RocketEnt, Prop_Data, "m_vecAbsVelocity", RocketVelocity);

		RocketVelocity[2] = RocketVelocity[2] + (RocketLaunchValue);
		
		GetVectorAngles(RocketVelocity, RocketAngle);
		TeleportEntity(RocketEnt, NULL_VECTOR, RocketAngle, RocketVelocity);
	}
	else
	{
		// If the rocket somehow has disappeared off the face of the earth before we were even able to calculate drop, kill the data pack, otherwise memory leaks go brrrrrr
		CloseHandle(AttrEntPack);
	}
	if (RocketDropValue != 0)
	{
		// Creates a timer for the next frame, supposedly this is a lot more reliable and consistent compared to RequestFrame, which previous code iterations used.
		float FrameTimeLength = GetGameFrameTime();
		CreateTimer(FrameTimeLength, RocketDrop, AttrEntPack);
	}
}

public Action RocketDrop(Handle timer, DataPack AttrEntPack)
{
	ResetPack(AttrEntPack);
	int RocketEnt = EntRefToEntIndex(ReadPackCell(AttrEntPack));
	ReadPackCell(AttrEntPack);
	int RocketDropValue = ReadPackCell(AttrEntPack);
	if (IsValidEntity(RocketEnt))
	{
		float RocketAngle[3];
		float RocketVelocity[3];

		GetEntPropVector(RocketEnt, Prop_Data, "m_angRotation", RocketAngle);
		GetEntPropVector(RocketEnt, Prop_Data, "m_vecAbsVelocity", RocketVelocity);

		RocketVelocity[2] = RocketVelocity[2] - (RocketDropValue / 10);

		GetVectorAngles(RocketVelocity, RocketAngle);
		TeleportEntity(RocketEnt, NULL_VECTOR, RocketAngle, RocketVelocity);

		float FrameTimeLength = GetGameFrameTime();
		CreateTimer(FrameTimeLength, RocketDrop, AttrEntPack);
	}
	else
	{
		CloseHandle(AttrEntPack);
	}
}

public void OnEntityDestroyed(int DestroyedEntity)
{
	int DestroyedEntityRef = EntIndexToEntRef(DestroyedEntity);

	for (int i = 0 ; DestroyedEntityRef != DataPackEntRefNumber[i] ; i++)
	{
		if (DestroyedEntityRef == DataPackEntRefNumber[i])
		{
			CloseHandle(AttrPackDrop[i]);
		}
	}
}