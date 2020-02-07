#include <sourcemod>
#define VERSION "1.0.0"

Handle:db = INVALID_HANDLE;
char cliOS[] = "OS Not set";

public Plugin:myinfo =
{
    name = "[TF2] OS Logger, forked off Paranoia IP tracker",
    author = "DarthNinja, stephanie",
    description = "Tracks client OS info",
    version = VERSION,
    url = "DarthNinja.com"
}

public OnPluginStart()
{
    CreateConVar("sm_os_logger", VERSION, "Plugin Version", FCVAR_NOTIFY);
    Connect();
}

Connect()
{
    if (SQL_CheckConfig("oslogger"))
        SQL_TConnect(OnDatabaseConnect, "oslogger");
    else
        SetFailState("Can't find 'oslogger' entry in sourcemod/configs/databases.cfg!");
}

public OnDatabaseConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
    {
        LogError("Failed to connect! Error: %s", error);
        PrintToServer("Failed to connect: %s", error)
        SetFailState("Failed to connect, SQL Error:  %s", error);
        return;
    }
    LogMessage("[OS Logger v%s] Online and connected to database!", VERSION);
    PrintToServer("[OS Logger v%s] Online and connected to database!", VERSION);
    db = hndl;
    SQL_CreateTables();
}

SQL_CreateTables()
{
    new len = 0;
    new String:query[1256];
    len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `oslogger` (");
    len += Format(query[len], sizeof(query)-len, "  `id` int(32) NOT NULL AUTO_INCREMENT,");
    len += Format(query[len], sizeof(query)-len, "  `SteamID` varchar(32) COLLATE utf8_unicode_ci NOT NULL,");
    len += Format(query[len], sizeof(query)-len, "  `Name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,");
    len += Format(query[len], sizeof(query)-len, "  `ClientOS` varchar(64) COLLATE utf8_unicode_ci NOT NULL,");
    len += Format(query[len], sizeof(query)-len, "  `LastConnected` int(12) NOT NULL,");
    len += Format(query[len], sizeof(query)-len, "  PRIMARY KEY (`id`),");
    len += Format(query[len], sizeof(query)-len, "  KEY `SteamID` (`SteamID`)");
    len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;");

    // LogMessage("%s", query);
    SQL_TQuery(db, SQLErrorCheckCallback, query);

    Format(query, sizeof(query), "SET NAMES utf8;");
    SQL_TQuery(db, SQLErrorCheckCallback, query);
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (!StrEqual("", error))
        LogError("SQL Error: %s", error);
}

public OnClientPutInServer(client)
{
    if (IsFakeClient(client))
        return;

    new serial = GetClientSerial(client);

    QueryClientConVar(client, "windows_speaker_config", OnWinCheck, serial);
}

public OnWinCheck(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:serial)
{
    if (GetClientFromSerial(serial) != client || !IsClientInGame(client))
    {
        return;
    }
    else if (result == ConVarQuery_NotFound)
    {
        QueryClientConVar(client, "sdl_double_click_size", OnMacCheck, serial);
    }
    else if (StrEqual(cvarName, "windows_speaker_config"))
    {
        cliOS = "Windows";
        DoStuff(any:serial);
        return;
    }
}
public OnLinuxCheck(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:serial)
{
    if (GetClientFromSerial(serial) != client || !IsClientInGame(client))
    {
        return;
    }
    else if (result == ConVarQuery_NotFound)
    {
        QueryClientConVar(client, "gl_can_mix_shader_gammas", OnMacCheck, serial);
    }
    else if (StrEqual(cvarName, "sdl_double_click_size"))
    {
        cliOS = "Linux";
        return;
    }
}
public OnMacCheck(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:serial)
{
    if (GetClientFromSerial(serial) != client || !IsClientInGame(client))
    {
        return;
    }
    else if (StrEqual(cvarName, "gl_can_mix_shader_gammas"))
    {
        cliOS = "Macintosh";
        return;
    }
    else if (result == ConVarQuery_NotFound)
    {
        cliOS = "Unknown";
        return;
    }
}

DoStuff(any:serial)
{
    new client = GetClientFromSerial(serial);
    char steamID[256];
    char name[256];
    GetClientName(client, name, sizeof(name));
    GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
    if (db == INVALID_HANDLE)
    {
        //Log to file instead
        decl String:path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, path, sizeof(path), "logs/oslogger.log");
        new Handle:file = OpenFile(path, "a");
        WriteFileLine(file, "%L connected, Likely OS: %s", client, cliOS);
        CloseHandle(file);
        return;
    }

    SQL_EscapeString(db, name, name, sizeof(name));

    decl String:query[1024];
    Format(query, sizeof(query), "INSERT INTO `oslogger` (`SteamID`, `Name`, `ClientOS`, `LastConnected`) VALUES ('%s', '%s', '%s', '%i');", steamID, name, cliOS, GetTime());
    // LogMessage("%s", query);

    SQL_TQuery(db, SQLErrorCheckCallback, query);

}
