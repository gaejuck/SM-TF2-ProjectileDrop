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
}

public void Hook_OnRocketSpawn(int CreatedEntity)
{
	int RocketOwner = GetEntPropEnt(CreatedEntity, Prop_Data, "m_hOwnerEntity");
	if(RocketOwner > 0 && RocketOwner <= MaxClients)
	{
		int CreatedEntityRef = EntIndexToEntRef(CreatedEntity);
		// The game doesn't like it when we execute the function immediately, presumably the velocity stuff doesn't start until the next frame?
		RequestFrame(RocketLaunch, CreatedEntityRef);
	}
}

public void RocketLaunch(int RocketEntRef)
{
	int RocketEnt = EntRefToEntIndex(RocketEntRef);
	if(IsValidEntity(RocketEnt))
	{
		int WeaponOwner = GetEntPropEnt(RocketEnt, Prop_Data, "m_hOwnerEntity");
		int Weapon = GetPlayerWeaponSlot(WeaponOwner, 0);
		int RocketLaunchValue = TF2CustAttr_GetInt(Weapon, "rocket launch");

		float RocketAngle[3];
		float RocketVelocity[3];

		GetEntPropVector(RocketEnt, Prop_Data, "m_angRotation", RocketAngle);
		GetEntPropVector(RocketEnt, Prop_Data, "m_vecAbsVelocity", RocketVelocity);

		RocketVelocity[2] = RocketVelocity[2] + (RocketLaunchValue);
		
		GetVectorAngles(RocketVelocity, RocketAngle);
		TeleportEntity(RocketEnt, NULL_VECTOR, RocketAngle, RocketVelocity);
	}
	// I hate how you can't put more than one goddamn bit of data in this thing, WHY?
	RequestFrame(RocketDrop, RocketEntRef);
}

public void RocketDrop(int RocketEntRef)
{
	int RocketEnt = EntRefToEntIndex(RocketEntRef);
	if(IsValidEntity(RocketEnt))
	{
		float RocketAngle[3];
		float RocketVelocity[3];

		int WeaponOwner = GetEntPropEnt(RocketEnt, Prop_Data, "m_hOwnerEntity");
		int Weapon = GetPlayerWeaponSlot(WeaponOwner, 0);
		// Supposedly these calls are expensive to make, but I had significant trouble getting this to work in a more optimal way, but then I've lost a lot of the coding knowledge I had, and that wasn't exactly much knowledge in the first place.
		int RocketDropValue = TF2CustAttr_GetInt(Weapon, "rocket drop");

		GetEntPropVector(RocketEnt, Prop_Data, "m_angRotation", RocketAngle);
		GetEntPropVector(RocketEnt, Prop_Data, "m_vecAbsVelocity", RocketVelocity);

		RocketVelocity[2] = RocketVelocity[2] - (RocketDropValue / 10);

		GetVectorAngles(RocketVelocity, RocketAngle);
		TeleportEntity(RocketEnt, NULL_VECTOR, RocketAngle, RocketVelocity);

		if (RocketDropValue!= 0)
		{
			RequestFrame(RocketDrop, RocketEnt);
		}
	}
}