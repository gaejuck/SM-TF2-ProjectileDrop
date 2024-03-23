#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf_custom_attributes>
#pragma newdecls required
#pragma semicolon 1

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

		int RocketLaunchValue = TF2CustAttr_GetInt(Weapon, "rocket launch", 0);
		int RocketDropValue = TF2CustAttr_GetInt(Weapon, "rocket drop", 0);
		
		if(!RocketLaunchValue || !RocketDropValue) return;
		
		// Create a data pack with the rocket entity as well as the two possible attributes, this saves calling TF2CustAttr_GetInt every frame a rocket exists like previous iterations of the code.
		DataPack AttrEntPack = new DataPack();
		WritePackCell(AttrEntPack, CreatedEntityRef);
		WritePackCell(AttrEntPack, RocketLaunchValue);
		WritePackCell(AttrEntPack, RocketDropValue);
		
		// The game doesn't like it when we execute the function immediately, presumably the velocity stuff doesn't start until the next frame?
		RequestFrame(RocketLaunch, AttrEntPack);
	}
}

public void RocketLaunch(DataPack AttrEntPack)
{
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
		CloseHandle(AttrEntPack);
	}
	
	if (RocketDropValue != 0)
	{
		// Creates a timer for the next frame, supposedly this is a lot more reliable and consistent compared to RequestFrame, which previous code iterations used.
		float FrameTimeLength = GetGameFrameTime();
		
		CloseHandle(AttrEntPack);
		
		DataPack NewAttrEntPack = new DataPack();
		WritePackCell(NewAttrEntPack, RocketEnt);
		WritePackCell(NewAttrEntPack, RocketDropValue);
		
		CreateTimer(FrameTimeLength, RocketDrop, NewAttrEntPack);
	}
	else
	{
		if(AttrEntPack != INVALID_HANDLE)
		{
			CloseHandle(AttrEntPack);
		}
	}
}

public Action RocketDrop(Handle timer, DataPack AttrEntPack)
{
	ResetPack(AttrEntPack);
	int RocketEnt = EntRefToEntIndex(ReadPackCell(AttrEntPack));
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
		
		CloseHandle(AttrEntPack);
		
		DataPack NewAttrEntPack = new DataPack();
		WritePackCell(NewAttrEntPack, RocketEnt);
		WritePackCell(NewAttrEntPack, RocketDropValue);
		
		CreateTimer(FrameTimeLength, RocketDrop, NewAttrEntPack);
	}
	else
	{
		CloseHandle(AttrEntPack);
	}
	
	return Plugin_Continue;
}
