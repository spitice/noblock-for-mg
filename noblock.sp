
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#include <dhooks>
#include <sendproxy>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name = "NoBlock for MG/Courses",
    author = "Spitice (10 shots 0 kills)",
    description = "Yet another noblock plugin. Based on Bakr's NoBlock.",
    version = "1.0.0",
    url = "https://github.com/spitice"
};

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------
#define COLLISION_GROUP_NONE            0
#define COLLISION_GROUP_DEBRIS_TRIGGER  2
#define COLLISION_GROUP_PLAYER          5
#define COLLISION_GROUP_PLAYER_MOVEMENT 8
// dropped weapons, throwing melees. unused
#define COLLISION_GROUP_WEAPON          11
// grenade projectiles
#define COLLISION_GROUP_PROJECTILE      13

//------------------------------------------------------------------------------
// States
//------------------------------------------------------------------------------
DynamicHook g_dhookShouldCollide;

ConVar g_cvarNoBlock = null;
ConVar g_cvarIgnoreProjectiles = null;

int g_hShouldCollideHookPre = INVALID_HOOK_ID;

//------------------------------------------------------------------------------
// Setup
//------------------------------------------------------------------------------
public void OnPluginStart() {

    // Set up DHook
    Handle hGameConf = LoadGameConfigFile( "noblock.games" );
    if ( hGameConf == null ) {
        SetFailState( "Failed to load noblock gamedata" );
    }

    int offset = GameConfGetOffset( hGameConf, "CGameRules::ShouldCollide" );
    if ( offset == -1 ) {
        SetFailState( "Failed to get CGameRules::ShouldCollide offset" );
    }

    g_dhookShouldCollide = new DynamicHook( offset, HookType_GameRules, ReturnType_Bool, ThisPointer_Ignore );
    g_dhookShouldCollide.AddParam( HookParamType_Int );
    g_dhookShouldCollide.AddParam( HookParamType_Int );

    delete hGameConf;

    // Set up ConVars
    g_cvarNoBlock = CreateConVar( "sm_noblock", "1", "Enables NoBlock plugin", 0, true, 0.0, true, 1.0 );
    g_cvarIgnoreProjectiles = CreateConVar( "sm_noblock_ignore_projectiles", "0", "Completely ignores grenade projectiles", 0, true, 0.0, true, 1.0 );

    HookConVarChange( g_cvarNoBlock, OnConVarChanged_NoBlock );
    HookConVarChange( g_cvarIgnoreProjectiles, OnConVarChanged_IgnoreProjectiles );

    // Initialization
    if ( g_cvarNoBlock.BoolValue ) {
        HookAllClients();
    }
}

void HookAllClients() {
    int ent = -1;
    while ( ( ent = FindEntityByClassname( ent, "player" ) ) != -1 ) {
        HookClient( ent );
    }
}

void UnhookAllClients() {
    int ent = -1;
    while ( ( ent = FindEntityByClassname( ent, "player" ) ) != -1 ) {
        UnhookClient( ent );
    }
}

void HookClient( int client ) {
    SendProxy_Hook( client, "m_CollisionGroup", Prop_Int, Proxy_CollisionGroup );
}

void UnhookClient( int client ) {
    // Should be safe to call on non-hooked entity
    SendProxy_Unhook( client, "m_CollisionGroup", Proxy_CollisionGroup );
}

void HookShouldCollide() {
    if ( g_hShouldCollideHookPre != INVALID_HOOK_ID ) {
        UnhookShouldCollide();
    }

    if ( g_cvarIgnoreProjectiles.BoolValue ) {
        g_hShouldCollideHookPre = g_dhookShouldCollide.HookGamerules( Hook_Pre, Gamerules_ShouldCollide_IgnoreProjectiles );
    } else {
        g_hShouldCollideHookPre = g_dhookShouldCollide.HookGamerules( Hook_Pre, Gamerules_ShouldCollide );
    }
}

void UnhookShouldCollide() {
    if ( g_hShouldCollideHookPre == INVALID_HOOK_ID ) {
        return;
    }
    DynamicHook.RemoveHook( g_hShouldCollideHookPre );
}

//------------------------------------------------------------------------------
// Hooks
//------------------------------------------------------------------------------
public void OnClientPutInServer( int client ) {
    if ( !g_cvarNoBlock.BoolValue ) {
        return;
    }
    HookClient( client );
}

public void OnClientDisconnect( int client ) {
    UnhookClient( client );
}

public void OnMapStart() {
    if ( !g_cvarNoBlock.BoolValue ) {
        return;
    }
    HookShouldCollide();
}

public void OnConVarChanged_NoBlock( ConVar convar, const char[] oldValue, const char[] newValue ) {
    UnhookShouldCollide();
    UnhookAllClients();

    if ( !g_cvarNoBlock.BoolValue ) {
        return;
    }

    HookAllClients();
    HookShouldCollide();
}

public void OnConVarChanged_IgnoreProjectiles( ConVar convar, const char[] oldValue, const char[] newValue ) {
    if ( !g_cvarNoBlock.BoolValue ) {
        return;
    }
    UnhookShouldCollide();
    HookShouldCollide();
}

// bool CGameRules::ShouldCollide(int, int)
public MRESReturn Gamerules_ShouldCollide( DHookReturn hReturn, DHookParam hParams ) {

    int collisionGroup1 = hParams.Get(2);

    if (collisionGroup1 == COLLISION_GROUP_NONE) {
        // Ignore anything vs. world collisions
        return MRES_Ignored;
    }

    int collisionGroup0 = hParams.Get(1);

    if ( collisionGroup0 == COLLISION_GROUP_PLAYER ||
         collisionGroup0 == COLLISION_GROUP_PLAYER_MOVEMENT ) {
        if ( collisionGroup1 == COLLISION_GROUP_PLAYER ||
             collisionGroup1 == COLLISION_GROUP_PROJECTILE ) {
            // Player vs. Player
            // Player vs. Projectile
            // Player Movement vs. Player
            // Player Movement vs. Projectile
            hReturn.Value = false;
            return MRES_Override;
        }
    }

    return MRES_Ignored;
}

public MRESReturn Gamerules_ShouldCollide_IgnoreProjectiles( DHookReturn hReturn, DHookParam hParams ) {

    int collisionGroup1 = hParams.Get(2);

    if (collisionGroup1 == COLLISION_GROUP_NONE) {
        return MRES_Ignored;
    }

    int collisionGroup0 = hParams.Get(1);

    if ( collisionGroup0 == COLLISION_GROUP_PLAYER ||
         collisionGroup0 == COLLISION_GROUP_PLAYER_MOVEMENT ||
         collisionGroup0 == COLLISION_GROUP_PROJECTILE ) {
        if ( collisionGroup1 == COLLISION_GROUP_PLAYER ||
             collisionGroup1 == COLLISION_GROUP_PROJECTILE ) {
            hReturn.Value = false;
            return MRES_Override;
        }
    }

    return MRES_Ignored;
}

public Action Proxy_CollisionGroup( int entity, const char[] PropName, int& iValue, int element ) {
    iValue = COLLISION_GROUP_DEBRIS_TRIGGER;
    return Plugin_Changed;
}
