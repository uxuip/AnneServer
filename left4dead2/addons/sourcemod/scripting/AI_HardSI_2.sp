#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define MAXMOVESPEED 1000
// 特感类型
#define ZC_SMOKER       1
#define ZC_BOOMER       2
#define ZC_HUNTER       3
#define ZC_SPITTER      4
#define ZC_JOCKEY       5
#define ZC_CHARGER      6
#define ZC_WITCH        7
#define ZC_TANK         8
// 数据
#define VEM_MAX 450.0
#define MAXSURVIVORS 8
#define SURVIVORHEIGHT 72.0
#define PLAYER_HEIGHT 72.0
// SMOKER
#define SMOKERMELEERANGE 300.0
// JOCKEY
#define JOCKEYJUMPDELAY 2.0
#define JOCKEYJUMPNEARDELAY 0.1
#define JOCKEYJUMPRANGE 400.0
#define JOCKEYMINSPEED 130.0
// HUNTER
#define HUNTERATTACKTIME 5.0
#define HUNTERREPEATSPEED 4
#define HUNTERONGTOUNDSTATE 1
#define HUNTERFLYSTATE 2
#define HUNTERCOOLDOWNTIME 0.5
// TANK
#define TANKMELEESCANDELAY 0.0
#define TANKROCKAIMTIME 3.0
#define TANKAFTERTHROW 2.0
#define TANKROCKAIMDELAY 0.25
#define TANKATTACKRANGEFACTOR 0.90
#define TANKTHROWHEIGHT 110.0
#define THROW_OVERHEAD 50
// SPITTER
#define SPITTERRUNSPEED 200.0
#define SPITDELAY 2.0
#define SPITTERJUMPDELAY 0.1

enum AimType
{
	AimEye,
	AimBody,
	AimChest
};

// ConVars
ConVar g_hPlayBackRate;
// Ints
int g_iState[MAXPLAYERS + 1][8];
// Floats
float g_fPlayBackRate, g_fDelay[MAXPLAYERS + 1][8], g_fMoveGrad[MAXPLAYERS + 1][3], g_fMoveSpeed[MAXPLAYERS + 1], g_fPos[MAXPLAYERS + 1][3];
// Bools
bool g_bAiEnable[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name 			= "Advance Special Infected AI",
	author 			= "def075, Caibiii, 夜羽真白，东",
	description 	= "Advanced Special Infected AI",
	version 		= "2022.05.02",
	url 			= "https://github.com/Caibiii/AnneServer"
}

public void OnPluginStart()
{
	g_hPlayBackRate = CreateConVar("ai_TankSequencePlayBackRate", "3.0", "坦克攀爬动画加速速率", FCVAR_NOTIFY, true, 0.0);
	g_hPlayBackRate.AddChangeHook(ConVarChanged_Cvars);
	g_fPlayBackRate = g_hPlayBackRate.FloatValue;
	HookEvent("round_start", evt_RoundStart, EventHookMode_Post);
	HookEvent("player_spawn", evt_PlayerSpawn, EventHookMode_Post);
	HookEvent("tank_spawn", evt_TankSpawn, EventHookMode_Post);
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fPlayBackRate = g_hPlayBackRate.FloatValue;
}

// 向量绘制
// #include "vector/vector_show.sp"

// *********************
//		   事件
// *********************
//特感激进进攻
public Action L4D_OnFirstSurvivorLeftSafeArea(int firstSurvivor) 
{
	CreateTimer( 0.3, Timer_ForceInfectedAssault, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
}

public Action Timer_ForceInfectedAssault( Handle timer) 
{
	BypassAndExecuteCommand("nb_assault");
}
public int BypassAndExecuteCommand(char []strCommand)
{
	int flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~ FCVAR_CHEAT);
	FakeClientCommand(GetRandomSurvivor(), "%s", strCommand);
	SetCommandFlags(strCommand, flags);
}
public void OnMapStart()
{
	CreateTimer(1.0, Timer_MapStartMoveSpeed, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action evt_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		g_bAiEnable[client] = false;
	}
	InitStatus();
	return Plugin_Continue;
}

public Action evt_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsInfectedBot(client))
	{
		g_bAiEnable[client] = true;
	}
	return Plugin_Continue;
}

public void evt_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsInfectedBot(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK)
	{
		SDKHook(client, SDKHook_PostThinkPost, UpdateThink);
	}
}

public void L4D_TankClaw_DoSwing_Pre(int tank, int claw)
{
	if (IsInfectedBot(tank) && IsPlayerAlive(tank) && GetEntProp(tank, Prop_Send, "m_zombieClass") == ZC_TANK)
	{
		SetConVarString(FindConVar("z_tank_throw_force"), "500");
	}
}

// 修正玩家速度
public Action Timer_MapStartMoveSpeed(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			int team = GetClientTeam(client);
			{
				if (team == TEAM_SURVIVOR || team == TEAM_INFECTED)
				{
					float pos[3];
					GetClientAbsOrigin(client, pos);
					g_fMoveGrad[client][0] = pos[0] - g_fPos[client][0];
					g_fMoveGrad[client][1] = pos[1] - g_fPos[client][1];
					g_fMoveGrad[client][2] = pos[2] - g_fPos[client][2];
					// 获取玩家速度
					g_fMoveSpeed[client] = SquareRoot(g_fMoveGrad[client][0] * g_fMoveGrad[client][0] + g_fMoveGrad[client][1] * g_fMoveGrad[client][1]);
					if (g_fMoveSpeed[client] > MAXMOVESPEED)
					{
						g_fMoveSpeed[client] = 0.0;
						g_fMoveGrad[client][0] = 0.0;
						g_fMoveGrad[client][1] = 0.0;
						g_fMoveGrad[client][2] = 0.0;
					}
					g_fPos[client] = pos;
				}
			}
		}
	}
	return Plugin_Continue;
}

// 动画序列：9=正常走路，49=单手举过头顶投掷，50=低抛，51=双手举过头顶投掷
// 25=爬梯子，16=上低矮障碍物，19/20/21=爬墙/空调机/正常围栏，15=落地或上低矮障碍物，17=爬灌木/低矮围栏，22=爬房车，23=爬大货车，梯子由于有ladderboost不用加了
public void UpdateThink(int client)
{
	switch (GetEntProp(client, Prop_Send, "m_nSequence"))
	{
		case 15,16,17:
		{
			SetEntPropFloat(client, Prop_Send, "m_flPlaybackRate", 1.6);
		}
		case 18, 19, 20, 21, 22, 23:
		{
			SetEntPropFloat(client, Prop_Send, "m_flPlaybackRate", g_fPlayBackRate);
		}
		case 54, 55, 56, 57, 58, 59, 60:
		{
			SetEntPropFloat(client, Prop_Send, "m_flPlaybackRate", 999.0);
		}
	}
}
/*public void UpdateThink(int client)
{
	switch (GetEntProp(client, Prop_Send, "m_nSequence"))
	{
		case 15, 16, 17, 18, 19, 20, 21, 22, 23:
		{
			SetEntPropFloat(client, Prop_Send, "m_flPlaybackRate", g_fPlayBackRate);
		}
		case 54, 55, 56, 57, 58, 59, 60:
		{
			SetEntPropFloat(client, Prop_Send, "m_flPlaybackRate", 999.0);
		}
	}
}*/

// *********************
//		   主要
// *********************
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsInfectedBot(client) && !IsGhost(client))
	{
		int zombieclass = GetZombieClass(client);
		Action react = Plugin_Continue;
		if (zombieclass == ZC_TANK)
		{
			react = OnTankRunCmd(client, buttons, vel, angles);
		}
		else if (g_bAiEnable[client])
		{
			switch (zombieclass)
			{
				case ZC_HUNTER:
				{
					react = OnHunterRunCmd(client, buttons, vel, angles);
				}
			}
		}
		return react;
	}
	return Plugin_Continue;
}

#define DOOR_ATTACK_SPEED 50

public Action OnHunterRunCmd(int client, int &buttons, float vel[3], float angles[3])
{
	Action react = Plugin_Continue;
	if (GetCurrentSpeed(client) <= DOOR_ATTACK_SPEED)
	{
		DoorAttack(client, buttons, ZC_HUNTER);
	}
	return react;
}

public Action OnTankRunCmd(int client, int &buttons, float vel[3], float angles[3])
{
	if (GetCurrentSpeed(client) <= DOOR_ATTACK_SPEED)
	{
		DoorAttack(client, buttons, ZC_TANK);
	}
	if (GetEntityMoveType(client) != MOVETYPE_LADDER)
	{
		float tankattackrange = -1.0, tankspeed = -1.0;
		if (tankattackrange < 0.0)
		{
			tankattackrange = GetConVarFloat(FindConVar("tank_attack_range"));
		}
		if (tankspeed < 0.0)
		{
			tankspeed = GetConVarFloat(FindConVar("z_tank_speed"));
		}
		int flags = GetEntityFlags(client);
		if (flags == 65922)
		{
			buttons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
		if (buttons & IN_ATTACK2)
		{
			DelayStart(client, 3);
			DelayStart(client, 4);
			SetConVarString(FindConVar("z_tank_throw_force"), "1000");
		}
		// 按了右键之后 0.25s 并在 0.25 + 2.5s内，锁定视野
		if (DelayExpired(client, 4, TANKROCKAIMDELAY) && !DelayExpired(client, 3, TANKROCKAIMTIME))
		{
			Handle hTrace = INVALID_HANDLE;
			int targetclient = 0, hittimes = 0, survivorcount = 0;
			float selfpos[3] = {0.0}, targetpos[3] = {0.0}, aimangles[3] = {0.0};
			GetClientAbsOrigin(client, selfpos);
			// 射线，坦克 z 高度 +100，作为石头出手高度
			selfpos[2] += TANKTHROWHEIGHT;
			// 2022-4-8更新：判断目标有效，判断目标是否可见
			for (int survivor = 1; survivor <= MaxClients; survivor++)
			{
				if (IsClientConnected(survivor) && IsClientInGame(survivor) && IsPlayerAlive(survivor) && GetClientTeam(survivor) == TEAM_SURVIVOR && !IsIncapped(survivor) && !IsPinned(survivor))
				{
					survivorcount += 1;
				}
			}
			int firsttarget = GetNearestSurvivorTank(client);
			if (IsValidSurvivor(firsttarget))
			{
				GetClientAbsOrigin(firsttarget, targetpos);
				targetpos[2] += SURVIVORHEIGHT;
				hTrace = TR_TraceRayFilterEx(selfpos, targetpos, MASK_VISIBLE, RayType_EndPoint, traceFilter, client);
				if (!TR_DidHit(hTrace) || TR_GetEntityIndex(hTrace) == firsttarget)
				{
					targetclient = firsttarget;
					GetClientAbsOrigin(targetclient, targetpos);
					delete hTrace;
					hTrace = INVALID_HANDLE;
				}
				else
				{
					int entity = -1;
					char classname[64] = {'\0'};
					entity = TR_GetEntityIndex(hTrace);
					GetEntityClassname(entity, classname, sizeof(classname));
					if (strcmp(classname, "player") != 0 && strcmp(classname, "env_physics_blocker") != 0 && strcmp(classname, "tank_rock") != 0)
					{
						hittimes += 1;
						for (int newtarget = 1; newtarget <= MaxClients; newtarget++)
						{
							// 生还者有效，未死亡，且未倒地与被控状态下
							if (newtarget != targetclient && IsClientConnected(newtarget) && IsClientInGame(newtarget) && IsPlayerAlive(newtarget) && GetClientTeam(newtarget) == TEAM_SURVIVOR && IsPlayerAlive(newtarget) && !IsIncapped(newtarget) && !IsPinned(newtarget))
							{
								GetClientAbsOrigin(newtarget, targetpos);
								targetpos[2] += SURVIVORHEIGHT;
								hTrace = TR_TraceRayFilterEx(selfpos, targetpos, MASK_VISIBLE, RayType_EndPoint, traceFilter, client);
								if (!TR_DidHit(hTrace))
								{
									// 射线未撞击到物体，则跳出，找到可以被攻击的生还者，上面已经判断是生还者，不需要进行二次判断，设置 hittimes = 0，避免判断为所有生还均被遮挡
									hittimes = 0;
									targetclient = newtarget;
									GetClientAbsOrigin(newtarget, targetpos);
									delete hTrace;
									hTrace = INVALID_HANDLE;
									break;
								}
								else
								{
									entity = TR_GetEntityIndex(hTrace);
									GetEntityClassname(entity, classname, sizeof(classname));
									if (strcmp(classname, "player") != 0 && strcmp(classname, "env_physics_blocker") != 0 && strcmp(classname, "tank_rock") != 0)
									{
										hittimes += 1;
										delete hTrace;
										hTrace = INVALID_HANDLE;
									}
								}
							}
						}
					}
				}
				delete hTrace;
				hTrace = INVALID_HANDLE;
			}
			// 撞击次数和生还者数相等，所有生还者皆在障碍后，取最近目标
			if (hittimes == survivorcount)
			{
				// PrintToConsoleAll("[Ai-Tank]：所有生还者均被遮挡，锁定目标于最近生还者身上");
				int nearesttarget = GetNearestSurvivorTank(client);
				if (IsValidSurvivor(nearesttarget))
				{
					ComputeAimAngles(client, nearesttarget, aimangles, AimChest);
					TeleportEntity(client, NULL_VECTOR, aimangles, NULL_VECTOR);
				}
				return Plugin_Changed;
			}
			else
			{
				// 撞击次数与生还者数不相等，能直视某个生还，则计算角度
				float absdist[3] = {0.0};
				GetClientAbsOrigin(client, selfpos);
				if (IsValidSurvivor(targetclient))
				{
					ComputeAimAngles(client, targetclient, aimangles, AimEye);
					GetEntPropVector(targetclient, Prop_Send, "m_vecOrigin", absdist);
					int dist = RoundToNearest(GetVectorDistance(selfpos, absdist)), sequence = GetEntProp(client, Prop_Send, "m_nSequence");
					float height = selfpos[2] - targetpos[2];
					// 距离小于 300，则说明离生还较近，直接瞄准生还下部即可
					if (dist <= 250)
					{
						// PrintToConsoleAll("[Ai-Tank]：克与最近生还距离小于 300");
						ComputeAimAngles(client, targetclient, aimangles, AimBody);
						aimangles[0] += 20.0;
					}
					else if ((dist / 1000) == 0)
					{
						// PrintToConsoleAll("[Ai-Tank]：克与最近生还者距离小于 1000，距离：%d，除以 1000：%d", dist, dist / 1000);
						// 高度相减小于 0，说明自身处于生还下方，高度相减大于 0，则在生还上方
						if (flags & FL_ONGROUND)
						{
							if (height < 0.0 && height < -100.0)
							{
								// PrintToChatAll("[Ai-Tank]：克的位置位于生还下方，且距离小于1000");
								ComputeAimAngles(client, targetclient, aimangles, AimEye);
								(sequence == THROW_OVERHEAD) ? (aimangles[0] -= dist / (PLAYER_HEIGHT * 1.2)) : (aimangles[0] -= dist / (PLAYER_HEIGHT * 1.5));
							}
							else if (height < 0.0 && height > -100.0)
							{
								// PrintToChatAll("[Ai-Tank]：克的位置位于生还下方，height：%.2f，且距离小于1000", height);
								ComputeAimAngles(client, targetclient, aimangles, AimEye);
								(sequence == THROW_OVERHEAD) ? (aimangles[0] -= dist / (PLAYER_HEIGHT * 1.5)) : (aimangles[0] -= dist / (PLAYER_HEIGHT * 2));
							}
							else if (height > 0.0 && height > 100.0)
							{
								// PrintToChatAll("[Ai-Tank]：克的位置位于生还上方，距离小于1000，距离：%d", dist);
								ComputeAimAngles(client, targetclient, aimangles, AimEye);
								(sequence == THROW_OVERHEAD) ? (aimangles[0] -= dist / PLAYER_HEIGHT * 0.8) : (aimangles[0] -= dist / (PLAYER_HEIGHT * 2));
							}
							else if (height > 0.0 && height < 100.0)
							{
								// PrintToChatAll("[Ai-Tank]：克的位置位于生还上方，height：%.2f，且距离小于1000", height);
								ComputeAimAngles(client, targetclient, aimangles, AimBody);
								aimangles[0] -= dist / PLAYER_HEIGHT * 0.8;
							}
							else if (height == 0.0)
							{
								// PrintToChatAll("[Ai-Tank]：克的位置与生还位置相等，height：%.2f，且距离小于1000", height);
								ComputeAimAngles(client, targetclient, aimangles, AimBody);
								(sequence == THROW_OVERHEAD) ? (aimangles[0] -= dist / (PLAYER_HEIGHT * 0.8)) : (aimangles[0] -= dist / PLAYER_HEIGHT);
							}
						}
					}
					else
					{
						// PrintToConsoleAll("[Ai-Tank]：克与最近生还者距离大于 1000，距离：%d，除以 1000：%d", dist, dist / 1000);
						if (flags & FL_ONGROUND)
						{
							if (height < 0.0 && height < -100.0)
							{
								// PrintToChatAll("[Ai-Tank]：克的位置位于生还下方，且距离大于1000");
								ComputeAimAngles(client, targetclient, aimangles, AimEye);
								(sequence == THROW_OVERHEAD) ? (aimangles[0] -= dist / (PLAYER_HEIGHT * 1.2)) : (aimangles[0] -= dist / (PLAYER_HEIGHT * 1.5));
							}
							else if ((height < 0.0 && height > -100.0))
							{
								// PrintToChatAll("[Ai-Tank]：克的位置位于生还下方，height：%.2f，且距离大于1000", height);
								ComputeAimAngles(client, targetclient, aimangles, AimEye);
								(sequence == THROW_OVERHEAD) ? (aimangles[0] -= dist / (PLAYER_HEIGHT * 1.5)) : (aimangles[0] -= dist / (PLAYER_HEIGHT * 1.8));
							}
							else if (height > 0.0 && height > 100.0)
							{
								// PrintToChatAll("[Ai-Tank]：克的位置位于生还上方，且距离大于1000，高度大于100：%.2f， 距离：%d", height, dist);
								ComputeAimAngles(client, targetclient, aimangles, AimEye);
								(sequence == THROW_OVERHEAD) ? (aimangles[0] -= dist / (PLAYER_HEIGHT * 1.6)) : (aimangles[0] -= dist / (PLAYER_HEIGHT * 2));
							}
							else if (height > 0.0 && height < 100.0)
							{
								// PrintToChatAll("[Ai-Tank]：克的位置位于生还上方，且距离大于1000"，高度小于100：%.2f，距离：%d, dist, height);
								ComputeAimAngles(client, targetclient, aimangles, AimEye);
								(sequence == THROW_OVERHEAD) ? (aimangles[0] -= dist / (PLAYER_HEIGHT * 2.1)) : (aimangles[0] -= dist / (PLAYER_HEIGHT * 2.3));
							}
							else if (height == 0.0)
							{
								// PrintToChatAll("[Ai-Tank]：克的位置与生还位置相等，height：%.2f，且距离大于1000", height);
								ComputeAimAngles(client, targetclient, aimangles, AimBody);
								(sequence == THROW_OVERHEAD) ? (aimangles[0] -= dist / (PLAYER_HEIGHT * 1.2)) : (aimangles[0] -= dist / (PLAYER_HEIGHT * 1.5));
							}
						}
					}
					// PrintToConsoleAll("[Ai-Tank]：计算得出的角度：%.2f %.2f %.2f", aimangles[0], aimangles[1], aimangles[2]);
					TeleportEntity(client, NULL_VECTOR, aimangles, NULL_VECTOR);
					return Plugin_Changed;
				}
			}
		}
		/*
		if (DelayExpired(client, 0, TANKMELEESCANDELAY))
		{
			DelayStart(client, 0);
			float nearestdist = NearestSurvivorDistanceTank(client);
			if (nearestdist > -1.0 && nearestdist < tankattackrange * TANKATTACKRANGEFACTOR)
			{
				buttons |= IN_ATTACK;
				return Plugin_Changed;
			}
		}
		*/
	}
	return Plugin_Continue;
}



// *********************
//		   方法
// *********************
bool IsValidSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR)
	{
		return true;
	}
	else
	{
		return false;
	}
}

bool IsInfectedBot(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_INFECTED)
	{
		return true;
	}
	else
	{
		return false;
	}
}

bool IsGhost(int client)
{
	if (IsInfectedBot(client))
	{
		if (GetEntProp(client, Prop_Send, "m_isGhost") == 1)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
}

int GetZombieClass(int client)
{
	return view_as<int>(GetEntProp(client, Prop_Send, "m_zombieClass"));
}

void InitStatus()
{
	float time = GetGameTime();
	for (int client = 1; client <= MaxClients; client++)
	{
		for (int index = 0; index < 8; index++)
		{
			g_fDelay[client][index] = time;
			g_iState[client][index] = 0;
		}
	}
}

void DelayStart(int client, int number)
{
	g_fDelay[client][number] = GetGameTime();
}

bool DelayExpired(int client, int number, float delay)
{
	return view_as<bool>(GetGameTime() - g_fDelay[client][number] > delay);
}

stock void SetState(int client, int number, int value)
{
	g_iState[client][number] = value;
}

stock int GetState(int client, int number)
{
	return view_as<int>(g_iState[client][number]);
}

stock float GetMoveSpeed(int client)
{
	return view_as<float>(g_fMoveSpeed[client]);
}

bool IsIncapped(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

// 计算角度
void ComputeAimAngles(int client, int target, float angles[3], AimType type = AimEye)
{
	if(client<0||client>MaxClients||target<0||target>MaxClients)
		return;
	float selfpos[3], targetpos[3], lookat[3];
	GetClientEyePosition(client, selfpos);
	switch (type)
	{
		case AimEye:
		{
			GetClientEyePosition(target, targetpos);
		}
		case AimBody:
		{
			GetClientAbsOrigin(target, targetpos);
		}
		case AimChest:
		{
			GetClientAbsOrigin(target, targetpos);
			targetpos[2] += 45.0;
		}
	}
	MakeVectorFromPoints(selfpos, targetpos, lookat);
	GetVectorAngles(lookat, angles);
}


stock float NearestSurvivorDistance(int client, int SpecificSur = -1)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		int TargetSur = -1;
		float selfpos[3] = {0.0}, TargetSurPos[3] = {0.0};
		GetClientAbsOrigin(client, selfpos);
		if (IsValidSurvivor(SpecificSur))
		{
			TargetSur = SpecificSur;
		}
		else
		{
			int newtarget = GetNearestSurvivor(client);
			if (IsValidSurvivor(newtarget))
			{
				TargetSur = newtarget;
			}
		}
		if (IsValidSurvivor(TargetSur) && HasEntProp(TargetSur, Prop_Send, "m_vecOrigin"))
		{
			GetEntPropVector(TargetSur, Prop_Send, "m_vecOrigin", TargetSurPos);
			return GetVectorDistance(selfpos, TargetSurPos);
		}
	}
	return -1.0;
}

stock int GetRandomMobileSurvivorTank()
{
	int survivors[16] = {0}, index = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client) && !IsIncapped(client))
		{
			survivors[index] = client;
			index += 1;
		}
	}
	if (index > 0)
	{
		return survivors[GetRandomInt(0, index - 1)];
	}
	return 0;
}

stock int GetRandomMobileSurvivor()
{
	int survivors[16] = {0}, index = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client) && !IsIncapped(client) && !IsPinned(client))
		{
			survivors[index] = client;
			index += 1;
		}
	}
	if (index > 0)
	{
		return survivors[GetRandomInt(0, index - 1)];
	}
	return 0;
}

stock int GetNearestSurvivorTank(int self, int excludeSur = -1)
{
	if (self > 0 && self <= MaxClients && IsClientConnected(self) && IsClientInGame(self) && IsPlayerAlive(self))
	{
		float selfpos[3] = {0.0}, surPos[3] = {0.0};
		GetClientAbsOrigin(self, selfpos);
		int closetSur = GetRandomMobileSurvivorTank();
		if (IsValidSurvivor(closetSur))
		{
			GetClientAbsOrigin(closetSur, surPos);
			int iClosetAbsDisplacement = RoundToNearest(GetVectorDistance(selfpos, surPos));
			for (int client = 1; client < MaxClients; client++)
			{
				if (IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client) && !IsIncapped(client) && client != excludeSur)
				{
					GetClientAbsOrigin(client, surPos);
					int iAbsDisplacement = RoundToNearest(GetVectorDistance(selfpos, surPos));
					if (iClosetAbsDisplacement < 0)
					{
						iClosetAbsDisplacement = iAbsDisplacement;
						closetSur = client;
					}
					else if (iAbsDisplacement < iClosetAbsDisplacement)
					{
						iClosetAbsDisplacement = iAbsDisplacement;
						closetSur = client;
					}
				}
			}
		}
		return closetSur;
	}
	return 0;
}

stock int GetNearestSurvivor(int self, int excludeSur = -1)
{
	if (self > 0 && self <= MaxClients && IsClientConnected(self) && IsClientInGame(self) && IsPlayerAlive(self))
	{
		float selfpos[3] = {0.0}, surPos[3] = {0.0};
		GetClientAbsOrigin(self, selfpos);
		int closetSur = GetRandomMobileSurvivor();
		if (IsValidSurvivor(closetSur))
		{
			GetClientAbsOrigin(closetSur, surPos);
			int iClosetAbsDisplacement = RoundToNearest(GetVectorDistance(selfpos, surPos));
			for (int client = 1; client < MaxClients; client++)
			{
				if (IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client) && !IsIncapped(client) && !IsPinned(client) && client != excludeSur)
				{
					GetClientAbsOrigin(client, surPos);
					int iAbsDisplacement = RoundToNearest(GetVectorDistance(selfpos, surPos));
					if (iClosetAbsDisplacement < 0)
					{
						iClosetAbsDisplacement = iAbsDisplacement;
						closetSur = client;
					}
					else if (iAbsDisplacement < iClosetAbsDisplacement)
					{
						iClosetAbsDisplacement = iAbsDisplacement;
						closetSur = client;
					}
				}
			}
		}
		return closetSur;
	}
	return 0;
}

bool IsPinned(int client)
{
	bool bIsPinned = false;
	if (IsValidSurvivor(client) && IsPlayerAlive(client))
	{
		if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0) bIsPinned = true;
	}		
	return bIsPinned;
}

bool traceFilter(int entity, int mask, int self)
{
	return entity != self;
}



// 特感挠门
float GetCurrentSpeed(int client)
{
	float vecspeed[3] = {0.0}, curspeed = 0.0;
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecspeed);
	curspeed = SquareRoot(Pow(vecspeed[0], 2.0) + Pow(vecspeed[1], 2.0));
	return curspeed;
}

public Action DoorAttack(int client, int &buttons, int infectedClass)
{
	int target = GetNearestSurvivor(client);
	if (IsValidSurvivor(target))
	{
		char className[32] = {'\0'};
		float eyePos[3] = {0.0}, targetPos[3] = {0.0}, mins[3] = {0.0}, maxs[3] = {0.0};
		GetClientAbsOrigin(client, eyePos);
		GetClientAbsOrigin(target, targetPos);
		GetClientMins(client, mins);
		GetClientMaxs(client, maxs);
		mins[2] += 15.0;
		Handle hTrace = TR_TraceHullFilterEx(eyePos, targetPos, mins, maxs, MASK_VISIBLE, TR_RayFilter, client);
		if (TR_DidHit(hTrace))
		{
			// 射线撞击，获取实体名称
			int entIndex = TR_GetEntityIndex(hTrace);
			if (IsValidEntity(entIndex) && IsValidEdict(entIndex))
			{
				GetEdictClassname(entIndex, className, sizeof(className));
			}
			if (className[0] != '\0' && strcmp(className, "prop_door_rotating") == 0 || strcmp(className, "infected") == 0 || strcmp(className, "witch") == 0)
			{
				delete hTrace;
				switch (infectedClass)
				{
					case view_as<int>(ZC_TANK):
					{
						buttons &= IN_ATTACK;
						return Plugin_Changed;
					}
					case view_as<int>(ZC_HUNTER):
					{
						buttons &= IN_ATTACK2;
						return Plugin_Changed;
					}
				}
			}
		}
		delete hTrace;
	}
	return Plugin_Continue;
}
stock bool TR_RayFilter(int entity, int mask, int self)
{
	return entity != self;
}
