/* =====================================================================
 *  INFERNO RP - Full Roleplay Indonesia
 *  -------------------------------------------------------------------
 *  Versi      : 2.0 FullRP
 *  Platform   : Windows (SA-MP 0.3.7)
 *  Penyimpanan: MySQL R41+ (BlueG)
 *  Bahasa     : Bahasa Indonesia baku
 *
 *  Fitur:
 *    - Survival: Hunger, Thirst, Sleep, Stamina, Sickness
 *    - Dokumen: KTP, KK, SIM, STNK, BPKB, Paspor, Surat Izin Senjata
 *    - Handphone: Nomor, SMS, Call, Kontak, Pulsa, Paket Data
 *    - Bahan Bakar: SPBU, konsumsi BBM per km, jenis bensin
 *    - Sistem Pajak: PPh 10 persen, Pajak Properti, PPN belanja
 *    - Cuaca & Sakit: Hujan, flu, demam, diare, infeksi
 *    - Pekerjaan Misi Nyata: Trucker, Taxi, Mechanic dengan misi
 *    - Polisi & Sidang: Pengadilan dengan Hakim, Jaksa, Pengacara, KUHP
 *    - Pemerintahan: Gubernur, Walikota, DPRD, PNS, Pilkada
 *    - Medis Lengkap: Dokter, Perawat, Ambulans, RS, Resep, Rawat Inap
 *    - Bank: ATM, Kartu Kredit, KPR, KKB, KTA
 *    - Open Interior & Exterior (tanpa Open Door)
 *
 *  Dependensi : a_samp, a_mysql (R41+), streamer, sscanf2, zcmd, foreach
 * =====================================================================*/

/* ---------- Include library ---------- */
#include <a_samp>
#include <streamer>
#include <sscanf2>
#include <a_mysql>
#include <zcmd>

/* SendFmt - format + SendClientMessage. Uses global buffer. */
stock SendFmt(playerid, color, const fmat[], {Float, _}:...)
{
    new str[256];
    format(str, sizeof(str), fmat);
    SendClientMessage(playerid, color, str);
    return 1;
}
// #include <foreach>  // Replaced with for loops

/* =====================================================================
 *  KONFIGURASI UMUM
 * =====================================================================*/
#define GM_NAME              "Inferno RP"
#define GM_VERSION           "2.0 FullRP"
#define MAX_PLAYERS_DB       5000
#define MAX_HOUSES           150
#define MAX_BUSINESSES       50
#define MAX_PVEHICLES         800
#define MAX_FUEL_STATIONS    20
#define MAX_HOSPITALS        5
#define MAX_DOCS_OFFICES     3
#define MAX_INTERIOR_POINTS  50
#define MAX_COURT_CASES      10
#define MAX_GOV_CANDIDATES   5
#define STARTING_CASH        5000
#define STARTING_BANK        25000
#define PAYDAY_INTERVAL      (60 * 60 * 1000)
#define SURVIVAL_INTERVAL    (60 * 1000)
#define WEATHER_INTERVAL     (10 * 60 * 1000)

/* ---------- Konfigurasi MySQL ---------- */
#define MYSQL_HOST           "ger-game-db-01.centnodes.net"
#define MYSQL_USER           "u696_xO4bH29iwN"
#define MYSQL_PASS           "trHAjzOid0k^4tP+I^v.uOSh"
#define MYSQL_DB             "s696_GadaLuBau"
#define MYSQL_PORT           3306

/* ---------- Warna ---------- */
#define COLOR_WHITE          0xFFFFFFFF
#define COLOR_RED            0xFF0000FF
#define COLOR_GREEN          0x00FF00FF
#define COLOR_YELLOW         0xFFFF00FF
#define COLOR_BLUE           0x0000FFFF
#define COLOR_ORANGE         0xFFAA00FF
#define COLOR_PURPLE         0xAA00FFFF
#define COLOR_CYAN           0x00FFFFFF
#define COLOR_PINK           0xFF00FFFF
#define COLOR_GREY           0xAAAAAAFF
#define COLOR_SYSTEM         0x66CCFFFF
#define COLOR_ERROR          0xFF6600FF

/* ---------- Dialog IDs ---------- */
#define DIALOG_LOGIN            (1000)
#define DIALOG_REGISTER         (1001)
#define DIALOG_MAIN_MENU        (1002)
#define DIALOG_STATS            (1003)
#define DIALOG_BANK_MENU        (1004)
#define DIALOG_BANK_DEPOSIT     (1005)
#define DIALOG_BANK_WITHDRAW    (1006)
#define DIALOG_ATM_MENU         (1007)
#define DIALOG_PHONE_MENU       (1008)
#define DIALOG_PHONE_SMS        (1009)
#define DIALOG_PHONE_CALL       (1010)
#define DIALOG_PHONE_CONTACTS   (1011)
#define DIALOG_DOCS_MENU        (1012)
#define DIALOG_DOCS_APPLY       (1013)
#define DIALOG_JOB_MENU         (1014)
#define DIALOG_FUEL_MENU        (1015)
#define DIALOG_SHOP_MENU        (1016)
#define DIALOG_ADMIN_MENU       (1017)
#define DIALOG_HELP             (1018)
#define DIALOG_GOVT_MENU        (1019)
#define DIALOG_COURT_MENU       (1020)
#define DIALOG_MED_MENU         (1021)
#define DIALOG_CREDIT_MENU      (1022)
#define DIALOG_ELECTION_MENU    (1023)
#define DIALOG_VOTE_MENU        (1024)

/* =====================================================================
 *  FORWARD DECLARATIONS
 * =====================================================================*/
forward OnPlayerDataLoaded(playerid);
forward OnPlayerRegisterComplete(playerid);
forward OnHousesLoaded();
forward OnBusinessesLoaded();
forward OnFuelStationsLoaded();
forward OnPayday();
forward OnSurvivalDecay();
forward OnWeatherChange();
forward OnFuelConsumption();
forward OnCourtEnd(caseid);
forward OnElectionEnd();
forward OnInpatientRecover(playerid);
forward OnSleepRecover(playerid);

/* =====================================================================
 *  ENUM DAN DATA PEMAIN
 * =====================================================================*/
enum E_PLAYER_DATA
{
    pID,
    pName[MAX_PLAYER_NAME],
    pPassword[129],
    pSalt[32],
    pIP[45],
    pCash,
    pBank,
    pDebt,
    pCreditLimit,
    pCreditUsed,
    pLevel,
    pExp,
    pAdminLevel,
    pSkin,
    pAge,
    pGender,            // 0=laki, 1=perempuan
    Float:pHealth,
    Float:pArmor,
    Float:pHunger,
    Float:pThirst,
    Float:pSleep,
    Float:pStamina,
    pSickness,          // 0=sehat, 1=flu, 2=demam, 3=diare, 4=infeksi
    pSickTime,
    Float:pPosX,
    Float:pPosY,
    Float:pPosZ,
    Float:pPosA,
    pInterior,
    pWorld,
    pWanted,
    pJob,
    pJobTime,
    pFaction,           // 0=none, 1=SAPD, 2=SAGS, 3=SAMD, 4=SANEW
    pFactionRank,
    pPhone,             // nomor telepon (0 = tidak punya)
    pPhoneCredit,
    pPhoneData,         // paket data (MB)
    pPhoneBook,
    pKTP,               // 0=belum, 1=sudah
    pKK,
    pSIM,
    pSTNK,
    pBPKB,
    pPaspor,
    pSIS,               // Surat Izin Senjata
    pDriveLic,
    pWeaponLic,
    pBankRek,           // nomor rekening
    pInHouse,
    pInBiz,
    pInDoor,
    pJail,
    pJailTime,
    pArrest,
    pArrestTime,
    pKPR,               // sisa cicilan KPR
    pKKB,               // sisa cicilan KKB
    pKTA,               // sisa cicilan KTA
    bool:pIsLogged,
    bool:pIsSpawned,
    pLoginAttempts,
    pPaydayTimer,
    pSurvivalTimer,
    pSickTimer,
    pSleeping,
    pInpatient,
    bool:pPhoneOn,
    bool:pCalling,
    pCallWith,
    pCallTimer,
}
new PlayerInfo[MAX_PLAYERS][E_PLAYER_DATA];

/* ---------- Data rumah ---------- */
enum E_HOUSE_DATA
{
    hID,
    hExists,
    Float:hX, Float:hY, Float:hZ,
    hInterior,
    hPrice,
    hOwner[MAX_PLAYER_NAME],
    hLocked,
    hPickup,
    Text3D:hLabel,
}
new HouseInfo[MAX_HOUSES][E_HOUSE_DATA];

/* ---------- Data bisnis ---------- */
enum E_BIZ_DATA
{
    bID,
    bExists,
    Float:bX, Float:bY, Float:bZ,
    bInterior,
    bPrice,
    bOwner[MAX_PLAYER_NAME],
    bLocked,
    bType,              // 0=24/7, 1=klub, 2=restoran, 3=senjata
    bPickup,
    Text3D:bLabel,
}
new BizInfo[MAX_BUSINESSES][E_BIZ_DATA];

/* ---------- Data SPBU ---------- */
enum E_FUEL_DATA
{
    fID,
    fExists,
    Float:fX, Float:fY, Float:fZ,
    fPertalite,         // stok liter
    fPertamax,
    fSolar,
    fDexlite,
    fPickup,
    Text3D:fLabel,
}
new FuelInfo[MAX_FUEL_STATIONS][E_FUEL_DATA];

/* ---------- Data kendaraan pemain ---------- */
enum E_PVEH_DATA
{
    pvID,
    pvExists,
    pvModel,
    Float:pvX, Float:pvY, Float:pvZ, Float:pvA,
    pvColor1, pvColor2,
    pvOwner[MAX_PLAYER_NAME],
    Float:pvFuel,             // bensin saat ini (liter)
    pvFuelType,         // 0=Pertalite, 1=Pertamax, 2=Solar, 3=Dexlite
    pvLocked,
    pvVehicleID,
}
new PVehInfo[MAX_PVEHICLES][E_PVEH_DATA];

/* ---------- Data interior/exterior ---------- */
enum E_INTERIOR_DATA
{
    iExists,
    Float:iInX, Float:iInY, Float:iInZ, iInInt, iInWorld,
    Float:iOutX, Float:iOutY, Float:iOutZ, iOutInt, iOutWorld,
    iLabel[64],
    iPickup,
    Text3D:iLabel3D,
}
new InteriorInfo[MAX_INTERIOR_POINTS][E_INTERIOR_DATA];
new gTotalInteriors = 0;

/* ---------- Data sidang ---------- */
enum E_COURT_DATA
{
    cExists,
    cSuspect,
    cJudge,
    cProsecutor,
    cDefender,
    cArticle[64],
    cFine,
    cJailTime,
    cStatus,            // 0=menunggu, 1=berlangsung, 2=selesai
}
new CourtCase[MAX_COURT_CASES][E_COURT_DATA];

/* ---------- Data pemerintahan ---------- */
enum E_GOV_DATA
{
    gExists,
    gType,              // 1=Gubernur, 2=Walikota
    gPlayerID,
    gPlayerName[MAX_PLAYER_NAME],
    gVoteCount,
}
new GovCandidate[MAX_GOV_CANDIDATES][E_GOV_DATA];
new gElectionActive = 0;
new gHasVoted[MAX_PLAYERS];
new gTaxRate = 10;         // PPh 10 persen
new gPNSSalary = 15000;

/* ---------- Global vars ---------- */
new MySQL:gSQL;
new gWeatherTimer;
new gPaydayTimer;
new gSurvivalTimer;
new gFuelTimer;
new gCurrentWeather = 1;
new gTotalHouses = 0;
new gTotalBusinesses = 0;
new gTotalFuelStations = 0;
new gInteriorCooldown[MAX_PLAYERS];

/* ---------- TextDraw HUD Variables ---------- */
new Text:TD_Box;
new Text:TD_Health;
new Text:TD_Armor;
new Text:TD_Hunger;
new Text:TD_Thirst;
new Text:TD_Sleep;
new Text:TD_Stamina;
new Text:TD_Cash;
new Text:TD_Bank;
new Text:TD_Level;
new Text:TD_Job;
new Text:TD_Phone;
new Text:TD_Clock;
new Text:TD_ServerName;
new PlayerText:TD_PHealth[MAX_PLAYERS];
new PlayerText:TD_PArmor[MAX_PLAYERS];
new PlayerText:TD_PHunger[MAX_PLAYERS];
new PlayerText:TD_PThirst[MAX_PLAYERS];
new PlayerText:TD_PSleep[MAX_PLAYERS];
new PlayerText:TD_PStamina[MAX_PLAYERS];
new gHUDTimer;
new gPlayerOrigSkin[MAX_PLAYERS];

/* ---------- Job skin mapping ---------- */
new const gJobSkins[] = {
    0,    // Job 0: No job
    255,  // Job 1: Trucker
    61,   // Job 2: Taxi Driver
    50,   // Job 3: Mechanic
    17,   // Job 4: PNS
    70,   // Job 5: Dokter
    280   // Job 6: Polisi
};
new const gJobNames[][] = {
    "Tidak Bekerja",
    "Trucker",
    "Taxi Driver",
    "Mechanic",
    "PNS",
    "Dokter",
    "Polisi"
};

/* ---------- Pasal KUHP ---------- */
enum E_ARTICLE
{
    aName[64],
    aFine,
    aJailTime,
}
new const gArticles[][E_ARTICLE] = {
    {"Pasal 362 - Pencurian", 50000, 300},
    {"Pasal 338 - Pembunuhan", 500000, 1800},
    {"Pasal 351 - Penganiayaan", 100000, 600},
    {"Pasal 111 - Narkotika", 200000, 1200},
    {"Pasal 303 - Perjudian", 30000, 180},
    {"Pasal 378 - Penipuan", 75000, 450},
    {"Pasal 167 - Pengrusakan", 25000, 150},
    {"Pasal 340 - Pembunuhan Berencana", 1000000, 3600},
    {"Pasal 315 - Penghinaan", 10000, 60},
    {"Pasal 551 - Senjata Ilegal", 150000, 900}
};

/* ---------- Jenis bensin ---------- */
enum E_FUEL_TYPE
{
    ftName[32],
    ftPrice,
    Float:ftEfficiency,
}
new const gFuelTypes[][E_FUEL_TYPE] = {
    {"Pertalite", 10000, 1.0},
    {"Pertamax", 14000, 1.3},
    {"Solar", 8000, 1.1},
    {"Dexlite", 18000, 1.6}
};

/* =====================================================================
 *  STOCK FUNCTIONS
 * =====================================================================*/

/* ---------- Kirim pesan formatted ---------- */
stock SendMsg(playerid, color, const text[])
{
    SendClientMessage(playerid, color, text);
    return 1;
}


/* ---------- Hash password (SHA256) ---------- */
stock HashPassword(password[], salt[], output[], len = sizeof output)
{
    SHA256_PassHash(password, salt, output, len);
    return 1;
}

/* ---------- Generate salt ---------- */
stock GenerateSalt(output[], len = sizeof output)
{
    new const charset[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    for (new i = 0; i < len - 1; i++)
        output[i] = charset[random(sizeof(charset) - 1)];
    output[len - 1] = EOS;
}

/* ---------- Reset data pemain ---------- */
stock ResetPlayerData(playerid)
{
    PlayerInfo[playerid][pID] = 0;
    PlayerInfo[playerid][pCash] = 0;
    PlayerInfo[playerid][pBank] = 0;
    PlayerInfo[playerid][pDebt] = 0;
    PlayerInfo[playerid][pCreditLimit] = 0;
    PlayerInfo[playerid][pCreditUsed] = 0;
    PlayerInfo[playerid][pLevel] = 1;
    PlayerInfo[playerid][pExp] = 0;
    PlayerInfo[playerid][pAdminLevel] = 0;
    PlayerInfo[playerid][pSkin] = 230;
    PlayerInfo[playerid][pAge] = 17;
    PlayerInfo[playerid][pGender] = 0;
    PlayerInfo[playerid][pHealth] = 100.0;
    PlayerInfo[playerid][pArmor] = 0.0;
    PlayerInfo[playerid][pHunger] = 100.0;
    PlayerInfo[playerid][pThirst] = 100.0;
    PlayerInfo[playerid][pSleep] = 100.0;
    PlayerInfo[playerid][pStamina] = 100.0;
    PlayerInfo[playerid][pSickness] = 0;
    PlayerInfo[playerid][pSickTime] = 0;
    PlayerInfo[playerid][pPosX] = 1743.20;
    PlayerInfo[playerid][pPosY] = -1862.05;
    PlayerInfo[playerid][pPosZ] = 13.58;
    PlayerInfo[playerid][pPosA] = 270.0;
    PlayerInfo[playerid][pInterior] = 0;
    PlayerInfo[playerid][pWorld] = 0;
    PlayerInfo[playerid][pWanted] = 0;
    PlayerInfo[playerid][pJob] = 0;
    PlayerInfo[playerid][pJobTime] = 0;
    PlayerInfo[playerid][pFaction] = 0;
    PlayerInfo[playerid][pFactionRank] = 0;
    PlayerInfo[playerid][pPhone] = 0;
    PlayerInfo[playerid][pPhoneCredit] = 0;
    PlayerInfo[playerid][pPhoneData] = 0;
    PlayerInfo[playerid][pPhoneBook] = 0;
    PlayerInfo[playerid][pKTP] = 0;
    PlayerInfo[playerid][pKK] = 0;
    PlayerInfo[playerid][pSIM] = 0;
    PlayerInfo[playerid][pSTNK] = 0;
    PlayerInfo[playerid][pBPKB] = 0;
    PlayerInfo[playerid][pPaspor] = 0;
    PlayerInfo[playerid][pSIS] = 0;
    PlayerInfo[playerid][pDriveLic] = 0;
    PlayerInfo[playerid][pWeaponLic] = 0;
    PlayerInfo[playerid][pBankRek] = 0;
    PlayerInfo[playerid][pInHouse] = -1;
    PlayerInfo[playerid][pInBiz] = -1;
    PlayerInfo[playerid][pInDoor] = -1;
    PlayerInfo[playerid][pJail] = 0;
    PlayerInfo[playerid][pJailTime] = 0;
    PlayerInfo[playerid][pArrest] = 0;
    PlayerInfo[playerid][pArrestTime] = 0;
    PlayerInfo[playerid][pKPR] = 0;
    PlayerInfo[playerid][pKKB] = 0;
    PlayerInfo[playerid][pKTA] = 0;
    PlayerInfo[playerid][pIsLogged] = false;
    PlayerInfo[playerid][pIsSpawned] = false;
    PlayerInfo[playerid][pLoginAttempts] = 0;
    PlayerInfo[playerid][pSleeping] = 0;
    PlayerInfo[playerid][pInpatient] = 0;
    PlayerInfo[playerid][pPhoneOn] = false;
    PlayerInfo[playerid][pCalling] = false;
    PlayerInfo[playerid][pCallWith] = INVALID_PLAYER_ID;
    gInteriorCooldown[playerid] = 0;
}

/* ---------- Get player name (safe) ---------- */
stock GetPlayerNameEx(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    return name;
}

/* =====================================================================
 *  INTERIOR / EXTERIOR SYSTEM (Tanpa Open Door)
 * =====================================================================*/
stock CreateInteriorPoint(const label[],
    Float:in_x, Float:in_y, Float:in_z, in_int, in_world,
    Float:out_x, Float:out_y, Float:out_z, out_int, out_world)
{
    if (gTotalInteriors >= MAX_INTERIOR_POINTS) return -1;

    new id = gTotalInteriors++;
    InteriorInfo[id][iExists] = 1;
    InteriorInfo[id][iInX] = in_x;
    InteriorInfo[id][iInY] = in_y;
    InteriorInfo[id][iInZ] = in_z;
    InteriorInfo[id][iInInt] = in_int;
    InteriorInfo[id][iInWorld] = in_world;
    InteriorInfo[id][iOutX] = out_x;
    InteriorInfo[id][iOutY] = out_y;
    InteriorInfo[id][iOutZ] = out_z;
    InteriorInfo[id][iOutInt] = out_int;
    InteriorInfo[id][iOutWorld] = out_world;
    InteriorInfo[id][iLabel][0] = EOS;
    strcat(InteriorInfo[id][iLabel], label, 64);

    InteriorInfo[id][iPickup] = CreateDynamicPickup(1239, 23, in_x, in_y, in_z, in_world, in_int, -1, 5.0);

    new lbl[100];
    format(lbl, sizeof(lbl), "{00FF00}%s\n{FFFFFF}Tekan Y untuk masuk", label);
    InteriorInfo[id][iLabel3D] = CreateDynamic3DTextLabel(lbl, 0x00FF00FF,
        in_x, in_y, in_z + 0.5, 5.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, in_world, in_int);

    CreateDynamicPickup(1239, 23, out_x, out_y, out_z, out_world, out_int, -1, 5.0);
    format(lbl, sizeof(lbl), "{FF0000}Keluar dari %s\n{FFFFFF}Tekan Y untuk keluar", label);
    CreateDynamic3DTextLabel(lbl, 0xFF0000FF,
        out_x, out_y, out_z + 0.5, 5.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, out_world, out_int);

    return id;
}

/* =====================================================================
 *  TEXTDRAW HUD SYSTEM
 * =====================================================================*/
stock CreateHUDTextDraws()
{
    /* Background box (bottom left) */
    TD_Box = TextDrawCreate(20.0, 160.0, "_");
    TextDrawUseBox(TD_Box, 1);
    TextDrawBoxColor(TD_Box, 0x000000AA);
    TextDrawTextSize(TD_Box, 180.0, 0.0);
    TextDrawLetterSize(TD_Box, 0.5, 9.5);
    TextDrawSetShadow(TD_Box, 0);

    /* Server name header */
    TD_ServerName = TextDrawCreate(25.0, 162.0, "~g~Inferno RP~w~ v2.0");
    TextDrawLetterSize(TD_ServerName, 0.25, 1.0);
    TextDrawSetShadow(TD_ServerName, 1);

    /* Labels */
    TD_Health = TextDrawCreate(25.0, 178.0, "~r~Health:");
    TextDrawLetterSize(TD_Health, 0.20, 0.9);
    TextDrawSetShadow(TD_Health, 1);

    TD_Armor = TextDrawCreate(25.0, 190.0, "~b~Armor:");
    TextDrawLetterSize(TD_Armor, 0.20, 0.9);
    TextDrawSetShadow(TD_Armor, 1);

    TD_Hunger = TextDrawCreate(25.0, 202.0, "~o~Hunger:");
    TextDrawLetterSize(TD_Hunger, 0.20, 0.9);
    TextDrawSetShadow(TD_Hunger, 1);

    TD_Thirst = TextDrawCreate(25.0, 214.0, "~b~Thirst:");
    TextDrawLetterSize(TD_Thirst, 0.20, 0.9);
    TextDrawSetShadow(TD_Thirst, 1);

    TD_Sleep = TextDrawCreate(25.0, 226.0, "~p~Sleep:");
    TextDrawLetterSize(TD_Sleep, 0.20, 0.9);
    TextDrawSetShadow(TD_Sleep, 1);

    TD_Stamina = TextDrawCreate(25.0, 238.0, "~g~Stamina:");
    TextDrawLetterSize(TD_Stamina, 0.20, 0.9);
    TextDrawSetShadow(TD_Stamina, 1);

    /* Right side info */
    TD_Cash = TextDrawCreate(500.0, 162.0, "~g~Cash: $0");
    TextDrawLetterSize(TD_Cash, 0.22, 0.9);
    TextDrawSetShadow(TD_Cash, 1);

    TD_Bank = TextDrawCreate(500.0, 174.0, "~b~Bank: $0");
    TextDrawLetterSize(TD_Bank, 0.22, 0.9);
    TextDrawSetShadow(TD_Bank, 1);

    TD_Level = TextDrawCreate(500.0, 186.0, "~w~Level: 1");
    TextDrawLetterSize(TD_Level, 0.22, 0.9);
    TextDrawSetShadow(TD_Level, 1);

    TD_Job = TextDrawCreate(500.0, 198.0, "~w~Job: Tidak Bekerja");
    TextDrawLetterSize(TD_Job, 0.22, 0.9);
    TextDrawSetShadow(TD_Job, 1);

    TD_Phone = TextDrawCreate(500.0, 210.0, "~w~HP: - | Pulsa: $0");
    TextDrawLetterSize(TD_Phone, 0.22, 0.9);
    TextDrawSetShadow(TD_Phone, 1);

    TD_Clock = TextDrawCreate(580.0, 5.0, "00:00");
    TextDrawLetterSize(TD_Clock, 0.35, 1.2);
    TextDrawSetShadow(TD_Clock, 1);

    print("[InfernoRP] TextDraw HUD created.");
}

stock CreatePlayerHUD(playerid)
{
    /* Player-specific bars (progress bar style) */
    TD_PHealth[playerid] = CreatePlayerTextDraw(playerid, 80.0, 178.0, "100");
    PlayerTextDrawLetterSize(playerid, TD_PHealth[playerid], 0.18, 0.85);
    PlayerTextDrawColor(playerid, TD_PHealth[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, TD_PHealth[playerid], 1);

    TD_PArmor[playerid] = CreatePlayerTextDraw(playerid, 80.0, 190.0, "0");
    PlayerTextDrawLetterSize(playerid, TD_PArmor[playerid], 0.18, 0.85);
    PlayerTextDrawColor(playerid, TD_PArmor[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, TD_PArmor[playerid], 1);

    TD_PHunger[playerid] = CreatePlayerTextDraw(playerid, 80.0, 202.0, "100");
    PlayerTextDrawLetterSize(playerid, TD_PHunger[playerid], 0.18, 0.85);
    PlayerTextDrawColor(playerid, TD_PHunger[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, TD_PHunger[playerid], 1);

    TD_PThirst[playerid] = CreatePlayerTextDraw(playerid, 80.0, 214.0, "100");
    PlayerTextDrawLetterSize(playerid, TD_PThirst[playerid], 0.18, 0.85);
    PlayerTextDrawColor(playerid, TD_PThirst[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, TD_PThirst[playerid], 1);

    TD_PSleep[playerid] = CreatePlayerTextDraw(playerid, 80.0, 226.0, "100");
    PlayerTextDrawLetterSize(playerid, TD_PSleep[playerid], 0.18, 0.85);
    PlayerTextDrawColor(playerid, TD_PSleep[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, TD_PSleep[playerid], 1);

    TD_PStamina[playerid] = CreatePlayerTextDraw(playerid, 80.0, 238.0, "100");
    PlayerTextDrawLetterSize(playerid, TD_PStamina[playerid], 0.18, 0.85);
    PlayerTextDrawColor(playerid, TD_PStamina[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, TD_PStamina[playerid], 1);
}

stock ShowPlayerHUD(playerid)
{
    TextDrawShowForPlayer(playerid, TD_Box);
    TextDrawShowForPlayer(playerid, TD_ServerName);
    TextDrawShowForPlayer(playerid, TD_Health);
    TextDrawShowForPlayer(playerid, TD_Armor);
    TextDrawShowForPlayer(playerid, TD_Hunger);
    TextDrawShowForPlayer(playerid, TD_Thirst);
    TextDrawShowForPlayer(playerid, TD_Sleep);
    TextDrawShowForPlayer(playerid, TD_Stamina);
    TextDrawShowForPlayer(playerid, TD_Cash);
    TextDrawShowForPlayer(playerid, TD_Bank);
    TextDrawShowForPlayer(playerid, TD_Level);
    TextDrawShowForPlayer(playerid, TD_Job);
    TextDrawShowForPlayer(playerid, TD_Phone);
    TextDrawShowForPlayer(playerid, TD_Clock);
    PlayerTextDrawShow(playerid, TD_PHealth[playerid]);
    PlayerTextDrawShow(playerid, TD_PArmor[playerid]);
    PlayerTextDrawShow(playerid, TD_PHunger[playerid]);
    PlayerTextDrawShow(playerid, TD_PThirst[playerid]);
    PlayerTextDrawShow(playerid, TD_PSleep[playerid]);
    PlayerTextDrawShow(playerid, TD_PStamina[playerid]);
}

stock HidePlayerHUD(playerid)
{
    TextDrawHideForPlayer(playerid, TD_Box);
    TextDrawHideForPlayer(playerid, TD_ServerName);
    TextDrawHideForPlayer(playerid, TD_Health);
    TextDrawHideForPlayer(playerid, TD_Armor);
    TextDrawHideForPlayer(playerid, TD_Hunger);
    TextDrawHideForPlayer(playerid, TD_Thirst);
    TextDrawHideForPlayer(playerid, TD_Sleep);
    TextDrawHideForPlayer(playerid, TD_Stamina);
    TextDrawHideForPlayer(playerid, TD_Cash);
    TextDrawHideForPlayer(playerid, TD_Bank);
    TextDrawHideForPlayer(playerid, TD_Level);
    TextDrawHideForPlayer(playerid, TD_Job);
    TextDrawHideForPlayer(playerid, TD_Phone);
    TextDrawHideForPlayer(playerid, TD_Clock);
    PlayerTextDrawHide(playerid, TD_PHealth[playerid]);
    PlayerTextDrawHide(playerid, TD_PArmor[playerid]);
    PlayerTextDrawHide(playerid, TD_PHunger[playerid]);
    PlayerTextDrawHide(playerid, TD_PThirst[playerid]);
    PlayerTextDrawHide(playerid, TD_PSleep[playerid]);
    PlayerTextDrawHide(playerid, TD_PStamina[playerid]);
}

forward OnHUDUpdate();
public OnHUDUpdate()
{
    new str[128];
    new hour, minute;
    gettime(hour, minute);

    /* Update clock for all players */
    format(str, sizeof(str), "%02d:%02d", hour, minute);
    TextDrawSetString(TD_Clock, str);

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (!IsPlayerConnected(i)) continue;
        if (!PlayerInfo[i][pIsLogged] || !PlayerInfo[i][pIsSpawned]) continue;

        /* Update health */
        GetPlayerHealth(i, PlayerInfo[i][pHealth]);
        GetPlayerArmour(i, PlayerInfo[i][pArmor]);
        format(str, sizeof(str), "%.0f", PlayerInfo[i][pHealth]);
        PlayerTextDrawSetString(i, TD_PHealth[i], str);

        /* Update armor */
        format(str, sizeof(str), "%.0f", PlayerInfo[i][pArmor]);
        PlayerTextDrawSetString(i, TD_PArmor[i], str);

        /* Update hunger */
        format(str, sizeof(str), "%.0f", PlayerInfo[i][pHunger]);
        PlayerTextDrawSetString(i, TD_PHunger[i], str);

        /* Update thirst */
        format(str, sizeof(str), "%.0f", PlayerInfo[i][pThirst]);
        PlayerTextDrawSetString(i, TD_PThirst[i], str);

        /* Update sleep */
        format(str, sizeof(str), "%.0f", PlayerInfo[i][pSleep]);
        PlayerTextDrawSetString(i, TD_PSleep[i], str);

        /* Update stamina */
        format(str, sizeof(str), "%.0f", PlayerInfo[i][pStamina]);
        PlayerTextDrawSetString(i, TD_PStamina[i], str);

        /* Update cash */
        new _sf_hud1[128]; format(_sf_hud1, sizeof(_sf_hud1), "~g~Cash: $%d", PlayerInfo[i][pCash]);
        TextDrawSetString(TD_Cash, _sf_hud1);

        /* Update bank */
        new _sf_hud2[128]; format(_sf_hud2, sizeof(_sf_hud2), "~b~Bank: $%d", PlayerInfo[i][pBank]);
        TextDrawSetString(TD_Bank, _sf_hud2);

        /* Update level */
        new _sf_hud3[128]; format(_sf_hud3, sizeof(_sf_hud3), "~w~Level: %d (Exp: %d)", PlayerInfo[i][pLevel], PlayerInfo[i][pExp]);
        TextDrawSetString(TD_Level, _sf_hud3);

        /* Update job */
        new job_name[32];
        if (PlayerInfo[i][pJob] >= 0 && PlayerInfo[i][pJob] < sizeof(gJobNames))
        {
            job_name[0] = EOS;
            strcat(job_name, gJobNames[PlayerInfo[i][pJob]], 32);
        }
        else
        {
            job_name = "Unknown";
        }
        new _sf_hud4[128]; format(_sf_hud4, sizeof(_sf_hud4), "~w~Job: %s", job_name);
        TextDrawSetString(TD_Job, _sf_hud4);

        /* Update phone */
        new _sf_hud5[128];
        if (PlayerInfo[i][pPhone] > 0)
        {
            format(_sf_hud5, sizeof(_sf_hud5), "~w~HP: %d | Pulsa: $%d", PlayerInfo[i][pPhone], PlayerInfo[i][pPhoneCredit]);
        }
        else
        {
            _sf_hud5 = "~r~HP: Tidak ada";
        }
        TextDrawSetString(TD_Phone, _sf_hud5);
    }
    return 1;
}

/* =====================================================================
 *  JOB SKIN SYSTEM
 * =====================================================================*/
stock ApplyJobSkin(playerid)
{
    if (!PlayerInfo[playerid][pIsLogged]) return;
    new job = PlayerInfo[playerid][pJob];
    if (job > 0 && job < sizeof(gJobSkins))
    {
        gPlayerOrigSkin[playerid] = GetPlayerSkin(playerid);
        SetPlayerSkin(playerid, gJobSkins[job]);
        new _sf_skin[128];
        format(_sf_skin, sizeof(_sf_skin), "~g~Skin berubah ke %s", gJobNames[job]);
        GameTextForPlayer(playerid, _sf_skin, 2000, 3);
    }
}

stock RestoreOrigSkin(playerid)
{
    if (gPlayerOrigSkin[playerid] > 0)
    {
        SetPlayerSkin(playerid, gPlayerOrigSkin[playerid]);
        GameTextForPlayer(playerid, "~w~Skin kembali ke asli", 2000, 3);
        gPlayerOrigSkin[playerid] = 0;
    }
}

/* =====================================================================
 *  MAIN
 * =====================================================================*/
main()
{
    print("\n--------------------------------------");
    print("  Inferno RP v2.0 FullRP - Running");
    print("--------------------------------------\n");
}

/* =====================================================================
 *  OnGameModeInit
 * =====================================================================*/
public OnGameModeInit()
{
    print("[InfernoRP] OnGameModeInit - memulai...");

    SetGameModeText("Inferno RP v2.0");
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
    ShowNameTags(1);
    SetNameTagDrawDistance(40.0);
    DisableInteriorEnterExits();
    EnableStuntBonusForAll(0);
    ManualVehicleEngineAndLights();
    AllowInteriorWeapons(1);
    SetWeather(1);
    SetWorldTime(12);

    AddPlayerClass(230, 1743.20, -1862.05, 13.58, 270.0, 0, 0, 0, 0, 0, 0);

    /* --- Slower running (normal ped anims, not CJ fast run) --- */
    UsePlayerPedAnims();

    /* --- TextDraw HUD --- */
    CreateHUDTextDraws();
    gHUDTimer = SetTimer("OnHUDUpdate", 1000, true);

    /* --- Koneksi MySQL --- */
    gSQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB);
    if (gSQL == MYSQL_INVALID_HANDLE || mysql_errno(gSQL) != 0)
    {
        print("[InfernoRP][FATAL] Tidak bisa konek MySQL!");
        print("[InfernoRP][FATAL] Cek MYSQL_HOST/USER/PASS/DB di inferno.pwn");
    }
    else
    {
        print("[InfernoRP] Berhasil konek MySQL.");
        mysql_tquery(gSQL, "SELECT * FROM `houses`", "OnHousesLoaded");
        mysql_tquery(gSQL, "SELECT * FROM `businesses`", "OnBusinessesLoaded");
        mysql_tquery(gSQL, "SELECT * FROM `fuel_stations`", "OnFuelStationsLoaded");
    }

    /* --- Timers --- */
    gPaydayTimer = SetTimer("OnPayday", PAYDAY_INTERVAL, true);
    gSurvivalTimer = SetTimer("OnSurvivalDecay", SURVIVAL_INTERVAL, true);
    gWeatherTimer = SetTimer("OnWeatherChange", WEATHER_INTERVAL, true);
    gFuelTimer = SetTimer("OnFuelConsumption", 5000, true);

    /* --- Interior Points (Open Interior & Exterior, tanpa Open Door) --- */
    CreateInteriorPoint("Polisi LS", 1554.50, -1675.50, 16.20, 0, 0,
        246.40, 109.00, 1003.22, 10, 0);
    CreateInteriorPoint("Rumah Sakit LS", 1174.20, -1324.30, 14.10, 0, 0,
        -28.61, 28.50, 1001.92, 1, 0);
    CreateInteriorPoint("Bank LS", 2316.00, -7.50, 26.74, 0, 0,
        2306.50, -16.10, 26.74, 0, 1);
    CreateInteriorPoint("Balai Kota LS", 1480.91, -1771.21, 18.79, 0, 0,
        386.70, 173.70, 1008.38, 3, 0);
    CreateInteriorPoint("Ammunation LS", 1368.00, -1279.50, 13.50, 0, 0,
        286.15, -40.50, 1001.52, 1, 0);
    CreateInteriorPoint("Toko 24/7 LS", 1352.50, -1755.50, 13.50, 0, 0,
        -25.90, -185.80, 1003.55, 17, 0);
    /* Toko dekat spawn - masuk ke interior 24/7 */
    CreateInteriorPoint("Toko Spawn", 1751.0, -1862.0, 13.5, 0, 0,
        -25.90, -185.80, 1003.55, 17, 0);
    CreateInteriorPoint("Pizza Stack", 1174.00, -1303.00, 14.10, 0, 0,
        374.00, -117.40, 1001.49, 5, 0);
    CreateInteriorPoint("Bar LS", 2330.00, -1075.50, 45.00, 0, 0,
        501.50, -67.40, 998.76, 11, 0);
    CreateInteriorPoint("Polisi SF", -1605.50, 711.50, 13.87, 0, 0,
        246.40, 109.00, 1003.22, 10, 0);
    CreateInteriorPoint("Rumah Sakit SF", -2011.00, 158.50, 27.54, 0, 0,
        -28.61, 28.50, 1001.92, 1, 0);
    CreateInteriorPoint("Balai Kota SF", -1984.51, 137.66, 27.69, 0, 0,
        386.70, 173.70, 1008.38, 3, 0);
    CreateInteriorPoint("Polisi LV", 2377.59, 1870.06, 11.08, 0, 0,
        246.40, 109.00, 1003.22, 10, 0);
    CreateInteriorPoint("Rumah Sakit LV", 1607.40, 1816.20, 10.82, 0, 0,
        -28.61, 28.50, 1001.92, 1, 0);
    CreateInteriorPoint("Balai Kota LV", 2377.59, 1870.06, 11.08, 0, 0,
        386.70, 173.70, 1008.38, 3, 0);
    CreateInteriorPoint("Casino Four Dragons", 2027.50, 1008.00, 10.82, 0, 0,
        2015.50, 1017.50, 996.88, 10, 0);

    printf("[InfernoRP] %d interior points dibuat.", gTotalInteriors);

    /* --- SPBU --- */
    new Float:spbu_pos[][3] = {
        {1944.40, -1773.70, 13.40},
        {-1680.50, 412.50, 7.18},
        {2205.00, -1150.00, 25.70},
        {-1327.60, 2677.50, 50.07},
        {612.50, -589.50, 17.23}
    };
    for (new i = 0; i < sizeof(spbu_pos); i++)
    {
        FuelInfo[i][fExists] = 1;
        FuelInfo[i][fX] = spbu_pos[i][0];
        FuelInfo[i][fY] = spbu_pos[i][1];
        FuelInfo[i][fZ] = spbu_pos[i][2];
        FuelInfo[i][fPertalite] = 1000;
        FuelInfo[i][fPertamax] = 1000;
        FuelInfo[i][fSolar] = 1000;
        FuelInfo[i][fDexlite] = 500;
        FuelInfo[i][fPickup] = CreateDynamicPickup(1650, 23, spbu_pos[i][0], spbu_pos[i][1], spbu_pos[i][2], -1, -1, -1, 10.0);
        new lbl[128];
        format(lbl, sizeof(lbl), "{00FF00}SPBU\n{FFFFFF}/isibensin\nPertalite $10k | Pertamax $14k\nSolar $8k | Dexlite $18k");
        FuelInfo[i][fLabel] = CreateDynamic3DTextLabel(lbl, 0x00FF00FF,
            spbu_pos[i][0], spbu_pos[i][1], spbu_pos[i][2] + 1.0, 15.0);
        gTotalFuelStations++;
    }

    /* --- Lokasi penting 3D labels --- */
    /* Toko dekat spawn - masuk ke interior 24/7, tekan Y */
    CreateDynamicPickup(1247, 23, 1751.0, -1862.0, 13.5, -1, -1, -1, 10.0);
    CreateDynamic3DTextLabel("{00FF00}Toko 24/7\n{FFFFFF}Tekan Y untuk masuk\n/beli di dalam", 0x00FF00FF,
        1751.0, -1862.0, 13.5 + 0.5, 15.0);

    CreateDynamic3DTextLabel("{00FF00}Balai Kota\n{FFFFFF}/urusdokumen", 0x00FF00FF,
        1480.91, -1771.21, 18.79 + 0.5, 10.0);
    CreateDynamic3DTextLabel("{0000FF}Bank\n{FFFFFF}/bank / /kredit", 0x0000FFFF,
        2316.00, -7.50, 26.74 + 0.5, 10.0);
    CreateDynamic3DTextLabel("{FF00FF}Rumah Sakit\n{FFFFFF}/rawatinap / /ambulans", 0xFF00FFFF,
        1174.20, -1324.30, 14.10 + 0.5, 10.0);

    print("[InfernoRP] OnGameModeInit selesai.");
    return 1;
}

/* =====================================================================
 *  OnGameModeExit
 * =====================================================================*/
public OnGameModeExit()
{
    if (gSQL != MYSQL_INVALID_HANDLE)
    {
        mysql_close(gSQL);
        print("[InfernoRP] MySQL ditutup.");
    }
    KillTimer(gPaydayTimer);
    KillTimer(gSurvivalTimer);
    KillTimer(gWeatherTimer);
    KillTimer(gFuelTimer);
    KillTimer(gHUDTimer);
    return 1;
}

/* =====================================================================
 *  OnPlayerConnect
 * =====================================================================*/
public OnPlayerConnect(playerid)
{
    ResetPlayerData(playerid);
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    PlayerInfo[playerid][pName][0] = EOS;
    strcat(PlayerInfo[playerid][pName], name, MAX_PLAYER_NAME);

    new query[128];
    mysql_format(gSQL, query, sizeof(query), "SELECT * FROM `players` WHERE `name` = '%e' LIMIT 1", name);
    mysql_tquery(gSQL, query, "OnPlayerDataLoaded", "i", playerid);
    return 1;
}

/* =====================================================================
 *  OnPlayerDisconnect
 * =====================================================================*/
public OnPlayerDisconnect(playerid, reason)
{
    if (PlayerInfo[playerid][pIsLogged])
    {
        SavePlayerData(playerid);
    }
    HidePlayerHUD(playerid);
    ResetPlayerData(playerid);
    return 1;
}

/* =====================================================================
 *  OnPlayerRequestClass - handle class selection
 * =====================================================================*/
public OnPlayerRequestClass(playerid, classid)
{
    /* Jika belum login, tampilkan pesan dan tunggu dialog */
    if (!PlayerInfo[playerid][pIsLogged])
    {
        /* Set kamera ke posisi spawn */
        SetPlayerPos(playerid, 1743.20, -1862.05, 13.58);
        SetPlayerCameraPos(playerid, 1743.20 + 5.0, -1862.05 + 5.0, 18.58);
        SetPlayerCameraLookAt(playerid, 1743.20, -1862.05, 13.58);
        /* Jika MySQL gagal, tampilkan dialog register sebagai fallback */
        if (gSQL == MYSQL_INVALID_HANDLE)
        {
            ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD,
                "{00FF00}Registrasi",
                "{FFFFFF}Selamat datang di Inferno RP!\nAkun belum terdaftar.\nBuat password (min 5 karakter):",
                "Daftar", "Keluar");
        }
    }
    return 1;
}

/* =====================================================================
 *  OnPlayerDataLoaded (callback MySQL)
 * =====================================================================*/
public OnPlayerDataLoaded(playerid)
{
    new rows;
    cache_get_row_count(rows);
    if (rows > 0)
    {
        /* Pemain terdaftar - load SEMUA data sekarang (cache masih valid!) */
        cache_get_value_name(0, "password", PlayerInfo[playerid][pPassword], 129);
        cache_get_value_name(0, "salt", PlayerInfo[playerid][pSalt], 32);
        cache_get_value_name_int(0, "id", PlayerInfo[playerid][pID]);
        cache_get_value_name_int(0, "cash", PlayerInfo[playerid][pCash]);
        cache_get_value_name_int(0, "bank", PlayerInfo[playerid][pBank]);
        cache_get_value_name_int(0, "debt", PlayerInfo[playerid][pDebt]);
        cache_get_value_name_int(0, "credit_limit", PlayerInfo[playerid][pCreditLimit]);
        cache_get_value_name_int(0, "credit_used", PlayerInfo[playerid][pCreditUsed]);
        cache_get_value_name_int(0, "level", PlayerInfo[playerid][pLevel]);
        cache_get_value_name_int(0, "exp", PlayerInfo[playerid][pExp]);
        cache_get_value_name_int(0, "admin_level", PlayerInfo[playerid][pAdminLevel]);
        cache_get_value_name_int(0, "skin", PlayerInfo[playerid][pSkin]);
        cache_get_value_name_int(0, "age", PlayerInfo[playerid][pAge]);
        cache_get_value_name_int(0, "gender", PlayerInfo[playerid][pGender]);
        cache_get_value_name_float(0, "health", PlayerInfo[playerid][pHealth]);
        cache_get_value_name_float(0, "armor", PlayerInfo[playerid][pArmor]);
        cache_get_value_name_float(0, "hunger", PlayerInfo[playerid][pHunger]);
        cache_get_value_name_float(0, "thirst", PlayerInfo[playerid][pThirst]);
        cache_get_value_name_float(0, "sleep", PlayerInfo[playerid][pSleep]);
        cache_get_value_name_float(0, "stamina", PlayerInfo[playerid][pStamina]);
        cache_get_value_name_int(0, "sickness", PlayerInfo[playerid][pSickness]);
        cache_get_value_name_int(0, "sick_time", PlayerInfo[playerid][pSickTime]);
        cache_get_value_name_float(0, "pos_x", PlayerInfo[playerid][pPosX]);
        cache_get_value_name_float(0, "pos_y", PlayerInfo[playerid][pPosY]);
        cache_get_value_name_float(0, "pos_z", PlayerInfo[playerid][pPosZ]);
        cache_get_value_name_float(0, "pos_a", PlayerInfo[playerid][pPosA]);
        cache_get_value_name_int(0, "interior", PlayerInfo[playerid][pInterior]);
        cache_get_value_name_int(0, "virtualworld", PlayerInfo[playerid][pWorld]);
        cache_get_value_name_int(0, "wanted", PlayerInfo[playerid][pWanted]);
        cache_get_value_name_int(0, "job", PlayerInfo[playerid][pJob]);
        cache_get_value_name_int(0, "faction", PlayerInfo[playerid][pFaction]);
        cache_get_value_name_int(0, "faction_rank", PlayerInfo[playerid][pFactionRank]);
        cache_get_value_name_int(0, "phone", PlayerInfo[playerid][pPhone]);
        cache_get_value_name_int(0, "phone_credit", PlayerInfo[playerid][pPhoneCredit]);
        cache_get_value_name_int(0, "phone_data", PlayerInfo[playerid][pPhoneData]);
        cache_get_value_name_int(0, "ktp", PlayerInfo[playerid][pKTP]);
        cache_get_value_name_int(0, "kk", PlayerInfo[playerid][pKK]);
        cache_get_value_name_int(0, "sim", PlayerInfo[playerid][pSIM]);
        cache_get_value_name_int(0, "stnk", PlayerInfo[playerid][pSTNK]);
        cache_get_value_name_int(0, "bpkb", PlayerInfo[playerid][pBPKB]);
        cache_get_value_name_int(0, "paspor", PlayerInfo[playerid][pPaspor]);
        cache_get_value_name_int(0, "sis", PlayerInfo[playerid][pSIS]);
        cache_get_value_name_int(0, "drive_lic", PlayerInfo[playerid][pDriveLic]);
        cache_get_value_name_int(0, "weapon_lic", PlayerInfo[playerid][pWeaponLic]);
        cache_get_value_name_int(0, "bank_rek", PlayerInfo[playerid][pBankRek]);
        cache_get_value_name_int(0, "kpr", PlayerInfo[playerid][pKPR]);
        cache_get_value_name_int(0, "kkb", PlayerInfo[playerid][pKKB]);
        cache_get_value_name_int(0, "kta", PlayerInfo[playerid][pKTA]);

        /* Tampilkan dialog login */
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,
            "{00FF00}Login",
            "{FFFFFF}Selamat datang kembali!\nAkun Anda terdaftar.\nMasukkan password:",
            "Login", "Keluar");
    }
    else
    {
        /* Pemain baru - tampilkan dialog register */
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD,
            "{00FF00}Registrasi",
            "{FFFFFF}Selamat datang di Inferno RP!\nAkun belum terdaftar.\nBuat password (min 5 karakter):",
            "Daftar", "Keluar");
    }
    return 1;
}

/* =====================================================================
 *  OnDialogResponse
 * =====================================================================*/
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch (dialogid)
    {
        case DIALOG_REGISTER:
        {
            if (!response) return Kick(playerid);
            if (strlen(inputtext) < 5)
            {
                ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD,
                    "{00FF00}Registrasi",
                    "{FF0000}Password minimal 5 karakter!\n{FFFFFF}Buat password:",
                    "Daftar", "Keluar");
                return 1;
            }
            new salt[32];
            GenerateSalt(salt, sizeof(salt));
            new hash[129];
            HashPassword(inputtext, salt, hash, sizeof(hash));

            new name[MAX_PLAYER_NAME];
            GetPlayerName(playerid, name, sizeof(name));
            new ip[45];
            GetPlayerIp(playerid, ip, sizeof(ip));

            new query[512];
            mysql_format(gSQL, query, sizeof(query),
                "INSERT INTO `players` (`name`, `password`, `salt`, `ip`, `cash`, `bank`, `level`, `skin`, `age`, `gender`) VALUES ('%e', '%e', '%e', '%e', %d, %d, 1, 0, 17, 0)",
                name, hash, salt, ip, STARTING_CASH, STARTING_BANK);
            mysql_tquery(gSQL, query, "OnPlayerRegisterComplete", "i", playerid);
            return 1;
        }

        case DIALOG_LOGIN:
        {
            if (!response) return Kick(playerid);
            new hash[129];
            HashPassword(inputtext, PlayerInfo[playerid][pSalt], hash, sizeof(hash));
            if (strcmp(hash, PlayerInfo[playerid][pPassword]) != 0)
            {
                PlayerInfo[playerid][pLoginAttempts]++;
                if (PlayerInfo[playerid][pLoginAttempts] >= 3)
                {
                    SendMsg(playerid, COLOR_RED, "Terlalu banyak percobaan salah. Anda di-kick.");
                    Kick(playerid);
                    return 1;
                }
                ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,
                    "{00FF00}Login",
                    "{FF0000}Password salah!\n{FFFFFF}Masukkan password:",
                    "Login", "Keluar");
                return 1;
            }

            /* Login berhasil - data sudah di-load di OnPlayerDataLoaded */
            PlayerInfo[playerid][pIsLogged] = true;
            SpawnPlayer(playerid);
            SendMsg(playerid, COLOR_GREEN, "Login berhasil! Selamat datang di Inferno RP.");
            return 1;
        }

        case DIALOG_JOB_MENU:
        {
            if (!response) return 1;
            new job = listitem + 1;
            PlayerInfo[playerid][pJob] = job;
            ApplyJobSkin(playerid);
            new _sf_job[128];
            format(_sf_job, sizeof(_sf_job), "Anda mulai bekerja sebagai %s. Skin berubah otomatis.", gJobNames[job]);
            SendMsg(playerid, COLOR_GREEN, _sf_job);
            return 1;
        }

        case DIALOG_SHOP_MENU:
        {
            if (!response) return 1;
            switch (listitem)
            {
                case 0: /* Makanan */
                {
                    if (PlayerInfo[playerid][pCash] < 500) return SendMsg(playerid, COLOR_RED, "Uang tidak cukup ($500)."), 1;
                    PlayerInfo[playerid][pCash] -= 500;
                    PlayerInfo[playerid][pHunger] += 30.0;
                    if (PlayerInfo[playerid][pHunger] > 100.0) PlayerInfo[playerid][pHunger] = 100.0;
                    SendMsg(playerid, COLOR_GREEN, "Anda membeli makanan. Hunger +30.");
                }
                case 1: /* Minuman */
                {
                    if (PlayerInfo[playerid][pCash] < 300) return SendMsg(playerid, COLOR_RED, "Uang tidak cukup ($300)."), 1;
                    PlayerInfo[playerid][pCash] -= 300;
                    PlayerInfo[playerid][pThirst] += 30.0;
                    if (PlayerInfo[playerid][pThirst] > 100.0) PlayerInfo[playerid][pThirst] = 100.0;
                    SendMsg(playerid, COLOR_GREEN, "Anda membeli minuman. Thirst +30.");
                }
                case 2: /* Obat */
                {
                    if (PlayerInfo[playerid][pCash] < 2000) return SendMsg(playerid, COLOR_RED, "Uang tidak cukup ($2000)."), 1;
                    PlayerInfo[playerid][pCash] -= 2000;
                    PlayerInfo[playerid][pSickness] = 0;
                    PlayerInfo[playerid][pSickTime] = 0;
                    SetPlayerHealth(playerid, 100.0);
                    SendMsg(playerid, COLOR_GREEN, "Anda membeli obat. Sembuh total!");
                }
                case 3: /* Handphone */
                {
                    if (PlayerInfo[playerid][pCash] < 10000) return SendMsg(playerid, COLOR_RED, "Uang tidak cukup ($10,000)."), 1;
                    if (PlayerInfo[playerid][pPhone] > 0) return SendMsg(playerid, COLOR_RED, "Anda sudah punya HP."), 1;
                    PlayerInfo[playerid][pCash] -= 10000;
                    PlayerInfo[playerid][pPhone] = 1000 + random(9000);
                    PlayerInfo[playerid][pPhoneCredit] = 5000;
                    new _sf_hp[128]; format(_sf_hp, sizeof(_sf_hp), "Anda membeli HP! Nomor: %d. Pulsa: $5000.", PlayerInfo[playerid][pPhone]);
                    SendClientMessage(playerid, COLOR_GREEN, _sf_hp);
                }
                case 4: /* Pulsa $5000 */
                {
                    if (PlayerInfo[playerid][pCash] < 5000) return SendMsg(playerid, COLOR_RED, "Uang tidak cukup ($5,000)."), 1;
                    if (PlayerInfo[playerid][pPhone] == 0) return SendMsg(playerid, COLOR_RED, "Beli HP dulu."), 1;
                    PlayerInfo[playerid][pCash] -= 5000;
                    PlayerInfo[playerid][pPhoneCredit] += 5000;
                    new _sf_pulsa[128]; format(_sf_pulsa, sizeof(_sf_pulsa), "Pulsa +$5000. Total: $%d.", PlayerInfo[playerid][pPhoneCredit]);
                    SendClientMessage(playerid, COLOR_GREEN, _sf_pulsa);
                }
                case 5: /* Paket Data 1GB */
                {
                    if (PlayerInfo[playerid][pCash] < 3000) return SendMsg(playerid, COLOR_RED, "Uang tidak cukup ($3,000)."), 1;
                    if (PlayerInfo[playerid][pPhone] == 0) return SendMsg(playerid, COLOR_RED, "Beli HP dulu."), 1;
                    PlayerInfo[playerid][pCash] -= 3000;
                    PlayerInfo[playerid][pPhoneData] += 1024;
                    new _sf_data[128]; format(_sf_data, sizeof(_sf_data), "Paket Data +1GB. Total: %d MB.", PlayerInfo[playerid][pPhoneData]);
                    SendClientMessage(playerid, COLOR_GREEN, _sf_data);
                }
            }
            return 1;
        }
    }
    return 0;
}

/* =====================================================================
 *  LoadPlayerData / SavePlayerData
 * =====================================================================*/
stock LoadPlayerData(playerid)
{
    cache_get_value_name_int(0, "id", PlayerInfo[playerid][pID]);
    cache_get_value_name_int(0, "cash", PlayerInfo[playerid][pCash]);
    cache_get_value_name_int(0, "bank", PlayerInfo[playerid][pBank]);
    cache_get_value_name_int(0, "debt", PlayerInfo[playerid][pDebt]);
    cache_get_value_name_int(0, "credit_limit", PlayerInfo[playerid][pCreditLimit]);
    cache_get_value_name_int(0, "credit_used", PlayerInfo[playerid][pCreditUsed]);
    cache_get_value_name_int(0, "level", PlayerInfo[playerid][pLevel]);
    cache_get_value_name_int(0, "exp", PlayerInfo[playerid][pExp]);
    cache_get_value_name_int(0, "admin_level", PlayerInfo[playerid][pAdminLevel]);
    cache_get_value_name_int(0, "skin", PlayerInfo[playerid][pSkin]);
    cache_get_value_name_int(0, "age", PlayerInfo[playerid][pAge]);
    cache_get_value_name_int(0, "gender", PlayerInfo[playerid][pGender]);
    cache_get_value_name_float(0, "health", PlayerInfo[playerid][pHealth]);
    cache_get_value_name_float(0, "armor", PlayerInfo[playerid][pArmor]);
    cache_get_value_name_float(0, "hunger", PlayerInfo[playerid][pHunger]);
    cache_get_value_name_float(0, "thirst", PlayerInfo[playerid][pThirst]);
    cache_get_value_name_float(0, "sleep", PlayerInfo[playerid][pSleep]);
    cache_get_value_name_float(0, "stamina", PlayerInfo[playerid][pStamina]);
    cache_get_value_name_int(0, "sickness", PlayerInfo[playerid][pSickness]);
    cache_get_value_name_int(0, "sick_time", PlayerInfo[playerid][pSickTime]);
    cache_get_value_name_float(0, "pos_x", PlayerInfo[playerid][pPosX]);
    cache_get_value_name_float(0, "pos_y", PlayerInfo[playerid][pPosY]);
    cache_get_value_name_float(0, "pos_z", PlayerInfo[playerid][pPosZ]);
    cache_get_value_name_float(0, "pos_a", PlayerInfo[playerid][pPosA]);
    cache_get_value_name_int(0, "interior", PlayerInfo[playerid][pInterior]);
    cache_get_value_name_int(0, "virtualworld", PlayerInfo[playerid][pWorld]);
    cache_get_value_name_int(0, "wanted", PlayerInfo[playerid][pWanted]);
    cache_get_value_name_int(0, "job", PlayerInfo[playerid][pJob]);
    cache_get_value_name_int(0, "faction", PlayerInfo[playerid][pFaction]);
    cache_get_value_name_int(0, "faction_rank", PlayerInfo[playerid][pFactionRank]);
    cache_get_value_name_int(0, "phone", PlayerInfo[playerid][pPhone]);
    cache_get_value_name_int(0, "phone_credit", PlayerInfo[playerid][pPhoneCredit]);
    cache_get_value_name_int(0, "phone_data", PlayerInfo[playerid][pPhoneData]);
    cache_get_value_name_int(0, "ktp", PlayerInfo[playerid][pKTP]);
    cache_get_value_name_int(0, "kk", PlayerInfo[playerid][pKK]);
    cache_get_value_name_int(0, "sim", PlayerInfo[playerid][pSIM]);
    cache_get_value_name_int(0, "stnk", PlayerInfo[playerid][pSTNK]);
    cache_get_value_name_int(0, "bpkb", PlayerInfo[playerid][pBPKB]);
    cache_get_value_name_int(0, "paspor", PlayerInfo[playerid][pPaspor]);
    cache_get_value_name_int(0, "sis", PlayerInfo[playerid][pSIS]);
    cache_get_value_name_int(0, "drive_lic", PlayerInfo[playerid][pDriveLic]);
    cache_get_value_name_int(0, "weapon_lic", PlayerInfo[playerid][pWeaponLic]);
    cache_get_value_name_int(0, "bank_rek", PlayerInfo[playerid][pBankRek]);
    cache_get_value_name_int(0, "kpr", PlayerInfo[playerid][pKPR]);
    cache_get_value_name_int(0, "kkb", PlayerInfo[playerid][pKKB]);
    cache_get_value_name_int(0, "kta", PlayerInfo[playerid][pKTA]);
    PlayerInfo[playerid][pIsLogged] = true;
}

stock SavePlayerData(playerid)
{
    if (!PlayerInfo[playerid][pIsLogged]) return;
    GetPlayerPos(playerid, PlayerInfo[playerid][pPosX], PlayerInfo[playerid][pPosY], PlayerInfo[playerid][pPosZ]);
    GetPlayerFacingAngle(playerid, PlayerInfo[playerid][pPosA]);
    PlayerInfo[playerid][pInterior] = GetPlayerInterior(playerid);
    PlayerInfo[playerid][pWorld] = GetPlayerVirtualWorld(playerid);
    GetPlayerHealth(playerid, PlayerInfo[playerid][pHealth]);
    GetPlayerArmour(playerid, PlayerInfo[playerid][pArmor]);

    new query[512];

    /* Update bagian 1: ekonomi & level */
    mysql_format(gSQL, query, sizeof(query),
        "UPDATE `players` SET `cash`=%d, `bank`=%d, `debt`=%d, `credit_limit`=%d, `credit_used`=%d, `level`=%d, `exp`=%d, `skin`=%d, `age`=%d, `gender`=%d WHERE `id`=%d",
        PlayerInfo[playerid][pCash], PlayerInfo[playerid][pBank], PlayerInfo[playerid][pDebt],
        PlayerInfo[playerid][pCreditLimit], PlayerInfo[playerid][pCreditUsed],
        PlayerInfo[playerid][pLevel], PlayerInfo[playerid][pExp],
        PlayerInfo[playerid][pSkin], PlayerInfo[playerid][pAge], PlayerInfo[playerid][pGender],
        PlayerInfo[playerid][pID]);
    mysql_tquery(gSQL, query);

    /* Update bagian 2: survival */
    mysql_format(gSQL, query, sizeof(query),
        "UPDATE `players` SET `health`=%.1f, `armor`=%.1f, `hunger`=%.1f, `thirst`=%.1f, `sleep`=%.1f, `stamina`=%.1f, `sickness`=%d, `sick_time`=%d WHERE `id`=%d",
        PlayerInfo[playerid][pHealth], PlayerInfo[playerid][pArmor],
        PlayerInfo[playerid][pHunger], PlayerInfo[playerid][pThirst],
        PlayerInfo[playerid][pSleep], PlayerInfo[playerid][pStamina],
        PlayerInfo[playerid][pSickness], PlayerInfo[playerid][pSickTime],
        PlayerInfo[playerid][pID]);
    mysql_tquery(gSQL, query);

    /* Update bagian 3: posisi & status */
    mysql_format(gSQL, query, sizeof(query),
        "UPDATE `players` SET `pos_x`=%.1f, `pos_y`=%.1f, `pos_z`=%.1f, `pos_a`=%.1f, `interior`=%d, `virtualworld`=%d, `wanted`=%d, `job`=%d, `faction`=%d, `faction_rank`=%d WHERE `id`=%d",
        PlayerInfo[playerid][pPosX], PlayerInfo[playerid][pPosY], PlayerInfo[playerid][pPosZ],
        PlayerInfo[playerid][pPosA], PlayerInfo[playerid][pInterior], PlayerInfo[playerid][pWorld],
        PlayerInfo[playerid][pWanted], PlayerInfo[playerid][pJob],
        PlayerInfo[playerid][pFaction], PlayerInfo[playerid][pFactionRank],
        PlayerInfo[playerid][pID]);
    mysql_tquery(gSQL, query);

    /* Update bagian 4: phone & dokumen */
    mysql_format(gSQL, query, sizeof(query),
        "UPDATE `players` SET `phone`=%d, `phone_credit`=%d, `phone_data`=%d, `ktp`=%d, `kk`=%d, `sim`=%d, `stnk`=%d, `bpkb`=%d, `paspor`=%d, `sis`=%d WHERE `id`=%d",
        PlayerInfo[playerid][pPhone], PlayerInfo[playerid][pPhoneCredit],
        PlayerInfo[playerid][pPhoneData], PlayerInfo[playerid][pKTP], PlayerInfo[playerid][pKK],
        PlayerInfo[playerid][pSIM], PlayerInfo[playerid][pSTNK], PlayerInfo[playerid][pBPKB],
        PlayerInfo[playerid][pPaspor], PlayerInfo[playerid][pSIS], PlayerInfo[playerid][pID]);
    mysql_tquery(gSQL, query);

    /* Update bagian 5: lisensi & kredit */
    mysql_format(gSQL, query, sizeof(query),
        "UPDATE `players` SET `drive_lic`=%d, `weapon_lic`=%d, `bank_rek`=%d, `kpr`=%d, `kkb`=%d, `kta`=%d, `jail`=%d, `jail_time`=%d, `arrest`=%d, `arrest_time`=%d WHERE `id`=%d",
        PlayerInfo[playerid][pDriveLic], PlayerInfo[playerid][pWeaponLic],
        PlayerInfo[playerid][pBankRek], PlayerInfo[playerid][pKPR], PlayerInfo[playerid][pKKB],
        PlayerInfo[playerid][pKTA], PlayerInfo[playerid][pJail], PlayerInfo[playerid][pJailTime],
        PlayerInfo[playerid][pArrest], PlayerInfo[playerid][pArrestTime],
        PlayerInfo[playerid][pID]);
    mysql_tquery(gSQL, query);
}

public OnPlayerRegisterComplete(playerid)
{
    PlayerInfo[playerid][pID] = cache_insert_id();
    PlayerInfo[playerid][pCash] = STARTING_CASH;
    PlayerInfo[playerid][pBank] = STARTING_BANK;
    PlayerInfo[playerid][pIsLogged] = true;
    SpawnPlayer(playerid);
    SendMsg(playerid, COLOR_GREEN, "Registrasi berhasil! Selamat datang di Inferno RP.");
    return 1;
}

/* =====================================================================
 *  OnPlayerSpawn
 * =====================================================================*/
public OnPlayerSpawn(playerid)
{
    if (!PlayerInfo[playerid][pIsLogged])
    {
        /* Jika belum login (seharusnya tidak terjadi), spawn di default */
        SetPlayerPos(playerid, 1743.20, -1862.05, 13.58);
        SetPlayerHealth(playerid, 100.0);
        return 1;
    }

    SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
    SetPlayerHealth(playerid, PlayerInfo[playerid][pHealth]);
    SetPlayerArmour(playerid, PlayerInfo[playerid][pArmor]);

    /* Jika posisi belum diset (0,0,0), gunakan default spawn */
    if (PlayerInfo[playerid][pPosX] == 0.0 && PlayerInfo[playerid][pPosY] == 0.0)
    {
        SetPlayerPos(playerid, 1743.20, -1862.05, 13.58);
        SetPlayerFacingAngle(playerid, 270.0);
    }
    else
    {
        SetPlayerPos(playerid, PlayerInfo[playerid][pPosX], PlayerInfo[playerid][pPosY], PlayerInfo[playerid][pPosZ]);
        SetPlayerFacingAngle(playerid, PlayerInfo[playerid][pPosA]);
    }
    SetPlayerInterior(playerid, PlayerInfo[playerid][pInterior]);
    SetPlayerVirtualWorld(playerid, PlayerInfo[playerid][pWorld]);

    GivePlayerMoney(playerid, PlayerInfo[playerid][pCash] - GetPlayerMoney(playerid));
    SetPlayerColor(playerid, COLOR_GREY);
    PlayerInfo[playerid][pIsSpawned] = true;

    /* --- Show TextDraw HUD --- */
    CreatePlayerHUD(playerid);
    ShowPlayerHUD(playerid);

    new _sf3[512]; format(_sf3, sizeof(_sf3),  "Selamat datang, %s! Level: %d | Cash: $%d | Bank: $%d", 
        PlayerInfo[playerid][pName],  PlayerInfo[playerid][pLevel], 
        PlayerInfo[playerid][pCash],  PlayerInfo[playerid][pBank]); SendClientMessage(playerid, COLOR_SYSTEM, _sf3);
    return 1;
}

/* =====================================================================
 *  OnPlayerKeyStateChange - tekan Y untuk masuk/keluar interior
 * =====================================================================*/
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (!(newkeys & KEY_YES)) return 1;
    if (gInteriorCooldown[playerid] > gettime()) return 1;

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    new my_int = GetPlayerInterior(playerid);
    new my_world = GetPlayerVirtualWorld(playerid);

    for (new i = 0; i < gTotalInteriors; i++)
    {
        if (!InteriorInfo[i][iExists]) continue;

        if (my_int == InteriorInfo[i][iInInt] && my_world == InteriorInfo[i][iInWorld])
        {
            if (GetPlayerDistanceFromPoint(playerid,
                InteriorInfo[i][iInX], InteriorInfo[i][iInY], InteriorInfo[i][iInZ]) < 3.0)
            {
                SetPlayerPos(playerid,
                    InteriorInfo[i][iOutX], InteriorInfo[i][iOutY], InteriorInfo[i][iOutZ]);
                SetPlayerInterior(playerid, InteriorInfo[i][iOutInt]);
                SetPlayerVirtualWorld(playerid, InteriorInfo[i][iOutWorld]);
                new msg[128];
                format(msg, sizeof(msg), "~g~Memasuki %s", InteriorInfo[i][iLabel]);
                GameTextForPlayer(playerid, msg, 2000, 3);
                gInteriorCooldown[playerid] = gettime() + 3;
                return 1;
            }
        }

        if (my_int == InteriorInfo[i][iOutInt] && my_world == InteriorInfo[i][iOutWorld])
        {
            if (GetPlayerDistanceFromPoint(playerid,
                InteriorInfo[i][iOutX], InteriorInfo[i][iOutY], InteriorInfo[i][iOutZ]) < 3.0)
            {
                SetPlayerPos(playerid,
                    InteriorInfo[i][iInX], InteriorInfo[i][iInY], InteriorInfo[i][iInZ]);
                SetPlayerInterior(playerid, InteriorInfo[i][iInInt]);
                SetPlayerVirtualWorld(playerid, InteriorInfo[i][iInWorld]);
                new msg[128];
                format(msg, sizeof(msg), "~r~Keluar dari %s", InteriorInfo[i][iLabel]);
                GameTextForPlayer(playerid, msg, 2000, 3);
                gInteriorCooldown[playerid] = gettime() + 3;
                return 1;
            }
        }
    }
    return 1;
}

/* =====================================================================
 *  TIMER CALLBACKS
 * =====================================================================*/

/* --- Survival decay (hunger, thirst, sleep, stamina, sickness) --- */
public OnSurvivalDecay()
{
    for (new i = 0; i < MAX_PLAYERS; i++) if (IsPlayerConnected(i))
    {
        if (!PlayerInfo[i][pIsLogged] || !PlayerInfo[i][pIsSpawned]) continue;

        PlayerInfo[i][pHunger] -= 1.0;
        PlayerInfo[i][pThirst] -= 1.5;
        if (!PlayerInfo[i][pSleeping])
            PlayerInfo[i][pSleep] -= 0.5;

        if (PlayerInfo[i][pHunger] < 0.0) PlayerInfo[i][pHunger] = 0.0;
        if (PlayerInfo[i][pThirst] < 0.0) PlayerInfo[i][pThirst] = 0.0;
        if (PlayerInfo[i][pSleep] < 0.0) PlayerInfo[i][pSleep] = 0.0;

        /* Stamina naik jika diam */
        if (GetPlayerState(i) != PLAYER_STATE_ONFOOT)
            PlayerInfo[i][pStamina] += 2.0;
        else
        {
            new keys, ud, lr;
            GetPlayerKeys(i, keys, ud, lr);
            if (!(keys & KEY_SPRINT))
                PlayerInfo[i][pStamina] += 2.0;
        }
        if (PlayerInfo[i][pStamina] > 100.0) PlayerInfo[i][pStamina] = 100.0;

        /* Efek hunger/thirst/sleep rendah */
        if (PlayerInfo[i][pHunger] < 20.0)
        {
            SendMsg(i, COLOR_ORANGE, "[SURVIVAL] Anda sangat lapar! Cari makanan.");
            SetPlayerHealth(i, PlayerInfo[i][pHealth] - 2.0);
        }
        if (PlayerInfo[i][pThirst] < 20.0)
        {
            SendMsg(i, COLOR_ORANGE, "[SURVIVAL] Anda sangat haus! Cari minuman.");
            SetPlayerHealth(i, PlayerInfo[i][pHealth] - 2.0);
        }
        if (PlayerInfo[i][pSleep] < 20.0 && !PlayerInfo[i][pSleeping])
        {
            SendMsg(i, COLOR_ORANGE, "[SURVIVAL] Anda sangat mengantuk! Gunakan /tidur.");
        }

        /* Sakit karena cuaca hujan */
        if (gCurrentWeather == 8 && PlayerInfo[i][pSickness] == 0)
        {
            if (random(100) < 10) /* 10% chance */
            {
                PlayerInfo[i][pSickness] = 1; /* flu */
                PlayerInfo[i][pSickTime] = 600;
                SendMsg(i, COLOR_RED, "[SAKIT] Anda terkena flu karena hujan! Ke dokter atau /obat.");
            }
        }

        /* Efek sakit */
        if (PlayerInfo[i][pSickness] > 0)
        {
            PlayerInfo[i][pSickTime]--;
            if (PlayerInfo[i][pSickTime] <= 0)
            {
                if (PlayerInfo[i][pSickness] < 4)
                    PlayerInfo[i][pSickness]++;
                PlayerInfo[i][pSickTime] = 600;
            }
            SetPlayerHealth(i, PlayerInfo[i][pHealth] - 1.0);
        }
        else
        {
            GetPlayerHealth(i, PlayerInfo[i][pHealth]);
        }
    }
    return 1;
}

/* --- Cuaca berubah --- */
public OnWeatherChange()
{
    new weathers[] = {1, 1, 1, 1, 2, 8, 16}; /* mayority cerah, kadang hujan */
    gCurrentWeather = weathers[random(sizeof(weathers))];
    SetWeather(gCurrentWeather);
    if (gCurrentWeather == 8)
    {
        new _sf4[512]; format(_sf4, sizeof(_sf4),  "[CUACA] Hujan turun! Waspadai sakit flu."); SendClientMessageToAll(COLOR_BLUE, _sf4);
    }
    return 1;
}

/* --- Konsumsi BBM --- */
public OnFuelConsumption()
{
    for (new i = 0; i < MAX_PLAYERS; i++) if (IsPlayerConnected(i))
    {
        if (!PlayerInfo[i][pIsLogged]) continue;
        if (GetPlayerState(i) != PLAYER_STATE_DRIVER) continue;

        new vid = GetPlayerVehicleID(i);
        if (vid == INVALID_VEHICLE_ID) continue;

        /* Cari kendaraan pemain */
        new pv_idx = -1;
        for (new j = 0; j < MAX_VEHICLES; j++)
        {
            if (PVehInfo[j][pvExists] && PVehInfo[j][pvVehicleID] == vid)
            {
                pv_idx = j;
                break;
            }
        }
        if (pv_idx == -1) continue;

        if (PVehInfo[pv_idx][pvFuel] > 0.0)
        {
            PVehInfo[pv_idx][pvFuel] -= 0.5;
            if (PVehInfo[pv_idx][pvFuel] < 0.0) PVehInfo[pv_idx][pvFuel] = 0.0;

            if (PVehInfo[pv_idx][pvFuel] < 5.0)
            {
                new _sf5[512]; format(_sf5, sizeof(_sf5),  "[BBM] Bensin hampir habis! %.1f liter tersisa.",  PVehInfo[pv_idx][pvFuel]); SendClientMessage(i, COLOR_RED, _sf5);
            }
            if (PVehInfo[pv_idx][pvFuel] <= 0.0)
            {
                SetVehicleParamsEx(vid, 0, 0, 0, 0, 0, 0, 0);
                SendMsg(i, COLOR_RED, "[BBM] Bensin habis! Mesin mati.");
            }
        }
    }
    return 1;
}

/* --- Payday --- */
public OnPayday()
{
    for (new i = 0; i < MAX_PLAYERS; i++) if (IsPlayerConnected(i))
    {
        if (!PlayerInfo[i][pIsLogged] || !PlayerInfo[i][pIsSpawned]) continue;

        new income = 5000 + (PlayerInfo[i][pLevel] * 500);
        new tax = (income * gTaxRate) / 100;
        new net = income - tax;
        PlayerInfo[i][pBank] += net;
        PlayerInfo[i][pExp]++;

        /* Level up */
        if (PlayerInfo[i][pExp] >= PlayerInfo[i][pLevel] * 4)
        {
            PlayerInfo[i][pExp] = 0;
            PlayerInfo[i][pLevel]++;
            new _sf6[512]; format(_sf6, sizeof(_sf6),  "[PAYDAY] Level up! Anda sekarang level %d.",  PlayerInfo[i][pLevel]); SendClientMessage(i, COLOR_GREEN, _sf6);
        }

        /* Cicilan kredit */
        if (PlayerInfo[i][pKPR] > 0)
        {
            new cicilan = 50000;
            if (PlayerInfo[i][pBank] >= cicilan)
            {
                PlayerInfo[i][pBank] -= cicilan;
                PlayerInfo[i][pKPR]--;
                new _sf7[512]; format(_sf7, sizeof(_sf7),  "[KPR] Cicilan $%d dibayar. Sisa: %d.",  cicilan,  PlayerInfo[i][pKPR]); SendClientMessage(i, COLOR_YELLOW, _sf7);
            }
            else
                SendMsg(i, COLOR_RED, "[KPR] Saldo tidak cukup untuk cicilan!");
        }
        if (PlayerInfo[i][pKKB] > 0)
        {
            new cicilan = 20000;
            if (PlayerInfo[i][pBank] >= cicilan)
            {
                PlayerInfo[i][pBank] -= cicilan;
                PlayerInfo[i][pKKB]--;
                new _sf8[512]; format(_sf8, sizeof(_sf8),  "[KKB] Cicilan $%d dibayar. Sisa: %d.",  cicilan,  PlayerInfo[i][pKKB]); SendClientMessage(i, COLOR_YELLOW, _sf8);
            }
        }
        if (PlayerInfo[i][pKTA] > 0)
        {
            new cicilan = 15000;
            if (PlayerInfo[i][pBank] >= cicilan)
            {
                PlayerInfo[i][pBank] -= cicilan;
                PlayerInfo[i][pKTA]--;
                new _sf9[512]; format(_sf9, sizeof(_sf9),  "[KTA] Cicilan $%d dibayar. Sisa: %d.",  cicilan,  PlayerInfo[i][pKTA]); SendClientMessage(i, COLOR_YELLOW, _sf9);
            }
        }

        /* Bunga kartu kredit */
        if (PlayerInfo[i][pCreditUsed] > 0)
            PlayerInfo[i][pCreditUsed] += (PlayerInfo[i][pCreditUsed] * 5) / 100;

        /* Gaji PNS */
        if (PlayerInfo[i][pFaction] == 2 && PlayerInfo[i][pFactionRank] >= 1)
            PlayerInfo[i][pBank] += gPNSSalary;

        new _sf10[512]; format(_sf10, sizeof(_sf10),  "[PAYDAY] Gaji $%d (pajak $%d). Bank: $%d",  net,  tax,  PlayerInfo[i][pBank]); SendClientMessage(i, COLOR_GREEN, _sf10);
        SavePlayerData(i);
    }
    return 1;
}

/* =====================================================================
 *  COMMANDS (zcmd)
 * =====================================================================*/

/* --- /stats --- */
CMD:stats(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new str[1024];
    str[0] = EOS;
    new line[128];
    format(line, sizeof(line), "{FFFFFF}=== Stats %s ===\n\n", PlayerInfo[playerid][pName]);
    strcat(str, line, sizeof(str));
    format(line, sizeof(line), "Level: %d | Exp: %d\n", PlayerInfo[playerid][pLevel], PlayerInfo[playerid][pExp]);
    strcat(str, line, sizeof(str));
    format(line, sizeof(line), "Cash: $%d | Bank: $%d\n", PlayerInfo[playerid][pCash], PlayerInfo[playerid][pBank]);
    strcat(str, line, sizeof(str));
    format(line, sizeof(line), "Health: %.0f | Armor: %.0f\n", PlayerInfo[playerid][pHealth], PlayerInfo[playerid][pArmor]);
    strcat(str, line, sizeof(str));
    format(line, sizeof(line), "Hunger: %.0f | Thirst: %.0f\n", PlayerInfo[playerid][pHunger], PlayerInfo[playerid][pThirst]);
    strcat(str, line, sizeof(str));
    format(line, sizeof(line), "Sleep: %.0f | Stamina: %.0f\n", PlayerInfo[playerid][pSleep], PlayerInfo[playerid][pStamina]);
    strcat(str, line, sizeof(str));
    format(line, sizeof(line), "Job: %d | Faction: %d\n", PlayerInfo[playerid][pJob], PlayerInfo[playerid][pFaction]);
    strcat(str, line, sizeof(str));
    format(line, sizeof(line), "Phone: %d | Credit: $%d\n", PlayerInfo[playerid][pPhone], PlayerInfo[playerid][pPhoneCredit]);
    strcat(str, line, sizeof(str));
    new ktp_s[8], kk_s[8], sim_s[8], stnk_s[8], bpkb_s[8], paspor_s[8], sis_s[8], drv_s[8];
    if (PlayerInfo[playerid][pKTP]) ktp_s = "Ada"; else ktp_s = "Tidak";
    if (PlayerInfo[playerid][pKK]) kk_s = "Ada"; else kk_s = "Tidak";
    if (PlayerInfo[playerid][pSIM]) sim_s = "Ada"; else sim_s = "Tidak";
    if (PlayerInfo[playerid][pSTNK]) stnk_s = "Ada"; else stnk_s = "Tidak";
    if (PlayerInfo[playerid][pBPKB]) bpkb_s = "Ada"; else bpkb_s = "Tidak";
    if (PlayerInfo[playerid][pPaspor]) paspor_s = "Ada"; else paspor_s = "Tidak";
    if (PlayerInfo[playerid][pSIS]) sis_s = "Ada"; else sis_s = "Tidak";
    if (PlayerInfo[playerid][pDriveLic]) drv_s = "Ada"; else drv_s = "Tidak";
    format(line, sizeof(line), "KTP: %s | KK: %s | SIM: %s\n", ktp_s, kk_s, sim_s);
    strcat(str, line, sizeof(str));
    format(line, sizeof(line), "STNK: %s | BPKB: %s | Paspor: %s\n", stnk_s, bpkb_s, paspor_s);
    strcat(str, line, sizeof(str));
    format(line, sizeof(line), "SIS: %s | DriveLic: %s\n\n", sis_s, drv_s);
    strcat(str, line, sizeof(str));
    format(line, sizeof(line), "KPR: %d | KKB: %d | KTA: %d\n", PlayerInfo[playerid][pKPR], PlayerInfo[playerid][pKKB], PlayerInfo[playerid][pKTA]);
    strcat(str, line, sizeof(str));
    format(line, sizeof(line), "Kartu Kredit: $%d / $%d", PlayerInfo[playerid][pCreditUsed], PlayerInfo[playerid][pCreditLimit]);
    strcat(str, line, sizeof(str));
    ShowPlayerDialog(playerid, DIALOG_STATS, DIALOG_STYLE_MSGBOX, "{00FF00}Stats", str, "Tutup", "");
    return 1;
}

/* --- /help --- */
CMD:help(playerid, params[])
{
    new str[1024];
    str[0] = EOS;
    strcat(str, "{FFFFFF}=== Inferno RP - Commands ===\n\n", sizeof(str));
    strcat(str, "{00FF00}Umum:{FFFFFF} /stats /help\n\n", sizeof(str));
    strcat(str, "{00FF00}Survival:{FFFFFF} /tidur /bangun /makan /minum /obat\n\n", sizeof(str));
    strcat(str, "{00FF00}Dokumen:{FFFFFF} /dokumen /urusdokumen\n\n", sizeof(str));
    strcat(str, "{00FF00}Handphone:{FFFFFF} /hp /sms /call /hangup /topup\n\n", sizeof(str));
    strcat(str, "{00FF00}Bank:{FFFFFF} /bank /atm /kredit /bayarkredit\n\n", sizeof(str));
    strcat(str, "{00FF00}BBM:{FFFFFF} /isibensin /cekbensin\n\n", sizeof(str));
    strcat(str, "{00FF00}Pekerjaan:{FFFFFF} /kerja /quitjob\n\n", sizeof(str));
    strcat(str, "{00FF00}Medis:{FFFFFF} /rawatinap /ambulans /resep\n\n", sizeof(str));
    strcat(str, "{00FF00}Polisi:{FFFFFF} /sidang /putusan /jaksa /pengacara\n\n", sizeof(str));
    strcat(str, "{00FF00}Pemerintahan:{FFFFFF} /pemerintah /daftarpilkada /pilkada\n\n", sizeof(str));
    strcat(str, "{00FF00}Pajak:{FFFFFF} /pajak\n\n", sizeof(str));
    strcat(str, "{00FF00}Interior:{FFFFFF} Tekan Y di marker pintu", sizeof(str));
    ShowPlayerDialog(playerid, DIALOG_HELP, DIALOG_STYLE_MSGBOX, "{00FF00}Help", str, "Tutup", "");
    return 1;
}

/* =====================================================================
 *  SURVIVAL COMMANDS
 * =====================================================================*/
CMD:tidur(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pSleeping])
    {
        SendMsg(playerid, COLOR_YELLOW, "Anda sudah tidur. /bangun untuk berhenti.");
        return 1;
    }
    if (PlayerInfo[playerid][pInHouse] == -1 && PlayerInfo[playerid][pInDoor] == -1)
    {
        SendMsg(playerid, COLOR_RED, "Anda harus di dalam rumah/gedung untuk tidur.");
        return 1;
    }
    PlayerInfo[playerid][pSleeping] = 1;
    TogglePlayerControllable(playerid, false);
    ApplyAnimation(playerid, "CRIB", "CRIB_Bed_Loop", 4.1, 1, 0, 0, 0, 0, 1);
    SendMsg(playerid, COLOR_GREEN, "[TIDUR] Anda mulai tidur. /bangun untuk berhenti.");
    SetTimerEx("OnSleepRecover", 30000, false, "i", playerid);
    return 1;
}

public OnSleepRecover(playerid)
{
    if (!PlayerInfo[playerid][pSleeping]) return 1;
    PlayerInfo[playerid][pSleep] = 100.0;
    PlayerInfo[playerid][pSleeping] = 0;
    TogglePlayerControllable(playerid, true);
    ClearAnimations(playerid);
    SendMsg(playerid, COLOR_GREEN, "[TIDUR] Anda bangun segar! Sleep: 100 persen");
    return 1;
}

CMD:bangun(playerid, params[])
{
    if (!PlayerInfo[playerid][pSleeping])
    {
        SendMsg(playerid, COLOR_RED, "Anda tidak sedang tidur.");
        return 1;
    }
    PlayerInfo[playerid][pSleeping] = 0;
    TogglePlayerControllable(playerid, true);
    ClearAnimations(playerid);
    SendMsg(playerid, COLOR_GREEN, "[BANGUN] Anda bangun.");
    return 1;
}

CMD:makan(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pCash] < 500)
    {
        SendMsg(playerid, COLOR_RED, "Makanan $500. Uang tidak cukup.");
        return 1;
    }
    PlayerInfo[playerid][pCash] -= 500;
    PlayerInfo[playerid][pHunger] += 30.0;
    if (PlayerInfo[playerid][pHunger] > 100.0) PlayerInfo[playerid][pHunger] = 100.0;
    SetPlayerHealth(playerid, PlayerInfo[playerid][pHealth] + 5.0);
    SendMsg(playerid, COLOR_GREEN, "[MAKAN] Hunger +30. Anda kenyang!");
    return 1;
}

CMD:minum(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pCash] < 300)
    {
        SendMsg(playerid, COLOR_RED, "Minuman $300. Uang tidak cukup.");
        return 1;
    }
    PlayerInfo[playerid][pCash] -= 300;
    PlayerInfo[playerid][pThirst] += 30.0;
    if (PlayerInfo[playerid][pThirst] > 100.0) PlayerInfo[playerid][pThirst] = 100.0;
    SendMsg(playerid, COLOR_GREEN, "[MINUM] Thirst +30. Anda segar!");
    return 1;
}

CMD:obat(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pSickness] == 0)
    {
        SendMsg(playerid, COLOR_YELLOW, "Anda tidak sakit.");
        return 1;
    }
    if (PlayerInfo[playerid][pCash] < 2000)
    {
        SendMsg(playerid, COLOR_RED, "Obat $2000. Uang tidak cukup.");
        return 1;
    }
    PlayerInfo[playerid][pCash] -= 2000;
    PlayerInfo[playerid][pSickness] = 0;
    PlayerInfo[playerid][pSickTime] = 0;
    SetPlayerHealth(playerid, 100.0);
    SendMsg(playerid, COLOR_GREEN, "[OBAT] Anda sembuh!");
    return 1;
}

/* =====================================================================
 *  DOCUMENTS COMMANDS
 * =====================================================================*/
CMD:dokumen(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new str[512];
    str[0] = EOS;
    strcat(str, "{FFFFFF}Dokumen Anda:\n\n", sizeof(str));
    if (PlayerInfo[playerid][pKTP]) strcat(str, "{00FF00}KTP: Ada\n", sizeof(str)); else strcat(str, "{FF0000}KTP: Tidak\n", sizeof(str));
    if (PlayerInfo[playerid][pKK]) strcat(str, "{00FF00}KK: Ada\n", sizeof(str)); else strcat(str, "{FF0000}KK: Tidak\n", sizeof(str));
    if (PlayerInfo[playerid][pSIM]) strcat(str, "{00FF00}SIM: Ada\n", sizeof(str)); else strcat(str, "{FF0000}SIM: Tidak\n", sizeof(str));
    if (PlayerInfo[playerid][pSTNK]) strcat(str, "{00FF00}STNK: Ada\n", sizeof(str)); else strcat(str, "{FF0000}STNK: Tidak\n", sizeof(str));
    if (PlayerInfo[playerid][pBPKB]) strcat(str, "{00FF00}BPKB: Ada\n", sizeof(str)); else strcat(str, "{FF0000}BPKB: Tidak\n", sizeof(str));
    if (PlayerInfo[playerid][pPaspor]) strcat(str, "{00FF00}Paspor: Ada\n", sizeof(str)); else strcat(str, "{FF0000}Paspor: Tidak\n", sizeof(str));
    if (PlayerInfo[playerid][pSIS]) strcat(str, "{00FF00}SIS: Ada\n", sizeof(str)); else strcat(str, "{FF0000}SIS: Tidak\n", sizeof(str));
    if (PlayerInfo[playerid][pDriveLic]) strcat(str, "{00FF00}DriveLic: Ada\n", sizeof(str)); else strcat(str, "{FF0000}DriveLic: Tidak\n", sizeof(str));
    if (PlayerInfo[playerid][pWeaponLic]) strcat(str, "{00FF00}WeaponLic: Ada\n\n", sizeof(str)); else strcat(str, "{FF0000}WeaponLic: Tidak\n\n", sizeof(str));
    strcat(str, "{FFFF00}Pergi ke Balai Kota untuk mengurus dokumen (/urusdokumen).", sizeof(str));
    ShowPlayerDialog(playerid, DIALOG_DOCS_MENU, DIALOG_STYLE_MSGBOX, "{00FF00}Dokumen", str, "Tutup", "");
    return 1;
}

CMD:urusdokumen(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    /* Cek apakah dekat Balai Kota */
    if (GetPlayerDistanceFromPoint(playerid, 1480.91, -1771.21, 18.79) > 10.0 &&
        GetPlayerDistanceFromPoint(playerid, -1984.51, 137.66, 27.69) > 10.0 &&
        GetPlayerDistanceFromPoint(playerid, 2377.59, 1870.06, 11.08) > 10.0)
    {
        SendMsg(playerid, COLOR_RED, "Anda harus berada di Balai Kota.");
        return 1;
    }
    new str[512];
    format(str, sizeof(str),
        "{FFFFFF}Pilih dokumen:\n1. {00FF00}KTP {FFFFFF}- $10,000\n2. {00FF00}KK {FFFFFF}- $25,000\n3. {00FF00}SIM {FFFFFF}- $15,000\n4. {00FF00}STNK {FFFFFF}- $35,000\n5. {00FF00}BPKB {FFFFFF}- $50,000\n6. {00FF00}Paspor {FFFFFF}- $75,000\n7. {00FF00}SIS (Surat Izin Senjata) {FFFFFF}- $100,000\n8. {00FF00}Surat Izin Mengemudi {FFFFFF}- $20,000");
    ShowPlayerDialog(playerid, DIALOG_DOCS_APPLY, DIALOG_STYLE_LIST, "{00FF00}Urus Dokumen", str, "Pilih", "Batal");
    return 1;
}

/* =====================================================================
 *  BANK COMMANDS
 * =====================================================================*/
CMD:bank(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (GetPlayerDistanceFromPoint(playerid, 2316.00, -7.50, 26.74) > 10.0 &&
        GetPlayerInterior(playerid) != 0)
    {
        SendMsg(playerid, COLOR_RED, "Anda harus berada di Bank.");
        return 1;
    }
    new str[256];
    format(str, sizeof(str),
        "{FFFFFF}Bank Inferno RP\n\nSaldo: $%d\nRekening: %d\n\n1. Setor Uang\n2. Tarik Uang\n3. Info Kredit\n4. Ajukan KPR\n5. Ajukan KKB\n6. Ajukan KTA\n7. Kartu Kredit",
        PlayerInfo[playerid][pBank], PlayerInfo[playerid][pBankRek]);
    ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "{00FF00}Bank", str, "Pilih", "Tutup");
    return 1;
}

CMD:atm(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    /* Cek dekat ATM (pickup bank di berbagai lokasi) */
    new str[256];
    format(str, sizeof(str),
        "{FFFFFF}ATM Inferno RP\n\nSaldo: $%d\n\n1. Tarik Uang\n2. Cek Saldo",
        PlayerInfo[playerid][pBank]);
    ShowPlayerDialog(playerid, DIALOG_ATM_MENU, DIALOG_STYLE_LIST, "{00FF00}ATM", str, "Pilih", "Tutup");
    return 1;
}

CMD:kredit(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new str[512];
    format(str, sizeof(str),
        "{FFFFFF}Layanan Kredit:\n\nKPR: %d periode tersisa\nKKB: %d periode tersisa\nKTA: %d periode tersisa\nKartu Kredit: $%d / $%d\n\n{FFFF00}Cicilan otomatis dipotong saat payday.",
        PlayerInfo[playerid][pKPR], PlayerInfo[playerid][pKKB],
        PlayerInfo[playerid][pKTA],
        PlayerInfo[playerid][pCreditUsed], PlayerInfo[playerid][pCreditLimit]);
    ShowPlayerDialog(playerid, DIALOG_CREDIT_MENU, DIALOG_STYLE_MSGBOX, "{00FF00}Kredit", str, "Tutup", "");
    return 1;
}

CMD:bayarkredit(playerid, params[])
{
    return cmd_kredit(playerid, params);
}

/* =====================================================================
 *  FUEL COMMANDS
 * =====================================================================*/
CMD:isibensin(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new vid = GetPlayerVehicleID(playerid);
    if (vid == INVALID_VEHICLE_ID || GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
    {
        SendMsg(playerid, COLOR_RED, "Anda harus menjadi pengemudi kendaraan.");
        return 1;
    }
    /* Cek dekat SPBU */
    new near_spbu = 0;
    for (new i = 0; i < gTotalFuelStations; i++)
    {
        if (FuelInfo[i][fExists] &&
            GetPlayerDistanceFromPoint(playerid, FuelInfo[i][fX], FuelInfo[i][fY], FuelInfo[i][fZ]) < 15.0)
        {
            near_spbu = 1;
            break;
        }
    }
    if (!near_spbu)
    {
        SendMsg(playerid, COLOR_RED, "Anda harus berada di SPBU.");
        return 1;
    }

    new liters, fuel_type;
    if (sscanf(params, "dd", liters, fuel_type))
    {
        SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /isibensin [liter] [tipe: 0=Pertalite 1=Pertamax 2=Solar 3=Dexlite]");
        return 1;
    }
    if (liters <= 0 || liters > 100)
    {
        SendMsg(playerid, COLOR_RED, "Liter 1-100.");
        return 1;
    }
    if (fuel_type < 0 || fuel_type >= sizeof(gFuelTypes))
    {
        SendMsg(playerid, COLOR_RED, "Tipe bensin tidak valid.");
        return 1;
    }

    new cost = liters * gFuelTypes[fuel_type][ftPrice];
    if (PlayerInfo[playerid][pCash] < cost)
    {
        new _sf11[512]; format(_sf11, sizeof(_sf11),  "Butuh $%d untuk %d liter %s. Uang tidak cukup.", 
            cost,  liters,  gFuelTypes[fuel_type][ftName]); SendClientMessage(playerid, COLOR_RED, _sf11);
        return 1;
    }
    PlayerInfo[playerid][pCash] -= cost;
    new _sf12[512]; format(_sf12, sizeof(_sf12),  "[SPBU] %d liter %s terisi. Biaya: $%d", 
        liters,  gFuelTypes[fuel_type][ftName],  cost); SendClientMessage(playerid, COLOR_GREEN, _sf12);
    return 1;
}

CMD:cekbensin(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new vid = GetPlayerVehicleID(playerid);
    if (vid == INVALID_VEHICLE_ID)
    {
        SendMsg(playerid, COLOR_RED, "Anda harus di dalam kendaraan.");
        return 1;
    }
    new _sf13[512]; format(_sf13, sizeof(_sf13),  "[BENSIN] Kendaraan ID: %d",  vid); SendClientMessage(playerid, COLOR_GREEN, _sf13);
    return 1;
}

/* =====================================================================
 *  PHONE COMMANDS
 * =====================================================================*/
CMD:hp(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pPhone] == 0)
    {
        SendMsg(playerid, COLOR_RED, "Anda tidak punya handphone. Beli di toko.");
        return 1;
    }
    new str[256];
    format(str, sizeof(str),
        "{FFFFFF}Handphone\nNomor: %d\nPulsa: $%d\nData: %d MB\n\n1. SMS\n2. Telepon\n3. Kontak\n4. Top Up",
        PlayerInfo[playerid][pPhone], PlayerInfo[playerid][pPhoneCredit], PlayerInfo[playerid][pPhoneData]);
    ShowPlayerDialog(playerid, DIALOG_PHONE_MENU, DIALOG_STYLE_LIST, "{00FF00}Handphone", str, "Pilih", "Tutup");
    return 1;
}

CMD:sms(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pPhone] == 0)
    {
        SendMsg(playerid, COLOR_RED, "Anda tidak punya handphone.");
        return 1;
    }
    if (PlayerInfo[playerid][pPhoneCredit] < 100)
    {
        SendMsg(playerid, COLOR_RED, "Pulsa tidak cukup. Butuh $100 per SMS.");
        return 1;
    }
    new number, msg[128];
    if (sscanf(params, "ds[128]", number, msg))
    {
        SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /sms [nomor] [pesan]");
        return 1;
    }
    /* Cari pemain dengan nomor tersebut */
    new found = -1;
    for (new i = 0; i < MAX_PLAYERS; i++) if (IsPlayerConnected(i))
    {
        if (PlayerInfo[i][pIsLogged] && PlayerInfo[i][pPhone] == number)
        {
            found = i;
            break;
        }
    }
    if (found == -1)
    {
        SendMsg(playerid, COLOR_RED, "Nomor tidak ditemukan atau pemain offline.");
        return 1;
    }
    PlayerInfo[playerid][pPhoneCredit] -= 100;
    new _sf14[512]; format(_sf14, sizeof(_sf14),  "[SMS dari %d] %s",  PlayerInfo[playerid][pPhone],  msg); SendClientMessage(found, COLOR_YELLOW, _sf14);
    new _sf15[512]; format(_sf15, sizeof(_sf15),  "[SMS terkirim ke %d] %s",  number,  msg); SendClientMessage(playerid, COLOR_GREEN, _sf15);
    return 1;
}

CMD:call(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pPhone] == 0) return SendMsg(playerid, COLOR_RED, "Tidak punya HP."), 1;
    if (PlayerInfo[playerid][pCalling]) return SendMsg(playerid, COLOR_RED, "Anda sedang menelepon."), 1;
    if (PlayerInfo[playerid][pPhoneCredit] < 500) return SendMsg(playerid, COLOR_RED, "Pulsa tidak cukup."), 1;

    new number;
    if (sscanf(params, "d", number))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /call [nomor]"), 1;

    new found = -1;
    for (new i = 0; i < MAX_PLAYERS; i++) if (IsPlayerConnected(i))
    {
        if (PlayerInfo[i][pIsLogged] && PlayerInfo[i][pPhone] == number)
        {
            found = i;
            break;
        }
    }
    if (found == -1) return SendMsg(playerid, COLOR_RED, "Nomor tidak ditemukan."), 1;

    PlayerInfo[playerid][pCalling] = true;
    PlayerInfo[playerid][pCallWith] = found;
    PlayerInfo[found][pCalling] = true;
    PlayerInfo[found][pCallWith] = playerid;
    new _sf16[512]; format(_sf16, sizeof(_sf16),  "[CALL] Menghubungi %d...",  number); SendClientMessage(playerid, COLOR_GREEN, _sf16);
    new _sf17[512]; format(_sf17, sizeof(_sf17),  "[CALL] %d menelepon Anda! /angkat untuk menjawab.",  PlayerInfo[playerid][pPhone]); SendClientMessage(found, COLOR_YELLOW, _sf17);
    return 1;
}

CMD:angkat(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (!PlayerInfo[playerid][pCalling]) return SendMsg(playerid, COLOR_RED, "Tidak ada panggilan masuk."), 1;
    new caller = PlayerInfo[playerid][pCallWith];
    if (caller == INVALID_PLAYER_ID || !IsPlayerConnected(caller)) return SendMsg(playerid, COLOR_RED, "Penelepon offline."), 1;
    new _sf18[512]; format(_sf18, sizeof(_sf18),  "[CALL] Terhubung dengan %d.",  PlayerInfo[caller][pPhone]); SendClientMessage(playerid, COLOR_GREEN, _sf18);
    new _sf19[512]; format(_sf19, sizeof(_sf19),  "[CALL] Terhubung dengan %d.",  PlayerInfo[playerid][pPhone]); SendClientMessage(caller, COLOR_GREEN, _sf19);
    return 1;
}

CMD:hangup(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (!PlayerInfo[playerid][pCalling]) return SendMsg(playerid, COLOR_RED, "Tidak sedang menelepon."), 1;
    new other = PlayerInfo[playerid][pCallWith];
    PlayerInfo[playerid][pCalling] = false;
    PlayerInfo[playerid][pCallWith] = INVALID_PLAYER_ID;
    if (other != INVALID_PLAYER_ID && IsPlayerConnected(other))
    {
        PlayerInfo[other][pCalling] = false;
        PlayerInfo[other][pCallWith] = INVALID_PLAYER_ID;
        SendMsg(other, COLOR_YELLOW, "[CALL] Panggilan diakhiri.");
    }
    SendMsg(playerid, COLOR_YELLOW, "[CALL] Panggilan diakhiri.");
    return 1;
}

CMD:topup(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new amount;
    if (sscanf(params, "d", amount) || amount < 1000)
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /topup [jumlah min 1000]"), 1;
    if (PlayerInfo[playerid][pCash] < amount)
        return SendMsg(playerid, COLOR_RED, "Uang cash tidak cukup."), 1;
    PlayerInfo[playerid][pCash] -= amount;
    PlayerInfo[playerid][pPhoneCredit] += amount;
    new _sf20[512]; format(_sf20, sizeof(_sf20),  "[TOPUP] Pulsa +$%d. Total: $%d",  amount,  PlayerInfo[playerid][pPhoneCredit]); SendClientMessage(playerid, COLOR_GREEN, _sf20);
    return 1;
}

/* =====================================================================
 *  MEDICAL COMMANDS
 * =====================================================================*/
CMD:rawatinap(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pInpatient])
        return SendMsg(playerid, COLOR_RED, "Anda sudah rawat inap."), 1;
    if (PlayerInfo[playerid][pCash] < 50000)
        return SendMsg(playerid, COLOR_RED, "Biaya rawat inap $50,000. Uang tidak cukup."), 1;
    PlayerInfo[playerid][pCash] -= 50000;
    PlayerInfo[playerid][pInpatient] = 1;
    TogglePlayerControllable(playerid, false);
    ApplyAnimation(playerid, "CRIB", "CRIB_Bed_Loop", 4.1, 1, 0, 0, 0, 0, 1);
    SendMsg(playerid, COLOR_GREEN, "[RAWAT INAP] Pemulihan 30 detik...");
    SetTimerEx("OnInpatientRecover", 30000, false, "i", playerid);
    return 1;
}

public OnInpatientRecover(playerid)
{
    TogglePlayerControllable(playerid, true);
    ClearAnimations(playerid);
    SetPlayerHealth(playerid, 100.0);
    PlayerInfo[playerid][pArmor] = 0.0;
    SetPlayerArmour(playerid, 0.0);
    PlayerInfo[playerid][pHunger] = 100.0;
    PlayerInfo[playerid][pThirst] = 100.0;
    PlayerInfo[playerid][pSleep] = 100.0;
    PlayerInfo[playerid][pStamina] = 100.0;
    PlayerInfo[playerid][pSickness] = 0;
    PlayerInfo[playerid][pSickTime] = 0;
    PlayerInfo[playerid][pInpatient] = 0;
    SendMsg(playerid, COLOR_GREEN, "[RAWAT INAP] Anda sepenuhnya sembuh!");
    return 1;
}

CMD:ambulans(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pCash] < 5000)
        return SendMsg(playerid, COLOR_RED, "Biaya ambulans $5,000. Uang tidak cukup."), 1;
    PlayerInfo[playerid][pCash] -= 5000;
    SendMsg(playerid, COLOR_GREEN, "[AMBULANS] Ambulans dalam perjalanan. Tunggu 15 detik.");
    SetTimerEx("OnAmbulansPickup", 15000, false, "i", playerid);
    return 1;
}

forward OnAmbulansPickup(playerid);
public OnAmbulansPickup(playerid)
{
    if (!IsPlayerConnected(playerid)) return 1;
    SetPlayerHealth(playerid, 50.0);
    SetPlayerPos(playerid, 1174.20, -1324.30, 14.10);
    SetPlayerInterior(playerid, 0);
    SendMsg(playerid, COLOR_GREEN, "[AMBULANS] Anda dibawa ke RS.");
    return 1;
}

CMD:resep(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pFaction] != 3 || PlayerInfo[playerid][pFactionRank] < 3)
        return SendMsg(playerid, COLOR_RED, "Hanya dokter (SAMD rank 3+) yang bisa memberi resep."), 1;
    new targetid;
    if (sscanf(params, "u", targetid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /resep [playerid]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    if (PlayerInfo[targetid][pCash] < 10000)
        return SendMsg(playerid, COLOR_RED, "Pasien tidak punya cukup uang ($10,000)."), 1;
    PlayerInfo[targetid][pCash] -= 10000;
    PlayerInfo[playerid][pCash] += 2000;
    PlayerInfo[targetid][pSickness] = 0;
    PlayerInfo[targetid][pSickTime] = 0;
    SetPlayerHealth(targetid, 100.0);
    new _sf21[512]; format(_sf21, sizeof(_sf21),  "[RESEP] Dokter %s memberi obat. Anda sembuh!",  PlayerInfo[playerid][pName]); SendClientMessage(targetid, COLOR_GREEN, _sf21);
    new _sf22[512]; format(_sf22, sizeof(_sf22),  "[RESEP] Anda memberi resep ke %s. Fee $2,000.",  PlayerInfo[targetid][pName]); SendClientMessage(playerid, COLOR_GREEN, _sf22);
    return 1;
}

/* =====================================================================
 *  COURT COMMANDS
 * =====================================================================*/
CMD:sidang(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pFaction] != 1 && !(PlayerInfo[playerid][pFaction] == 2 && PlayerInfo[playerid][pFactionRank] >= 5))
        return SendMsg(playerid, COLOR_RED, "Hanya polisi atau hakim yang bisa mulai sidang."), 1;

    new targetid;
    if (sscanf(params, "u", targetid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /sidang [playerid]"), 1;
    if (!IsPlayerConnected(targetid) || !PlayerInfo[targetid][pIsLogged])
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;

    new caseid = -1;
    for (new i = 0; i < MAX_COURT_CASES; i++)
    {
        if (!CourtCase[i][cExists])
        {
            caseid = i;
            break;
        }
    }
    if (caseid == -1)
        return SendMsg(playerid, COLOR_RED, "Tidak ada slot sidang kosong."), 1;

    /* Pilih pasal acak (sederhana) */
    new art_idx = random(sizeof(gArticles));
    CourtCase[caseid][cExists] = 1;
    CourtCase[caseid][cSuspect] = targetid;
    CourtCase[caseid][cJudge] = playerid;
    CourtCase[caseid][cArticle][0] = EOS;
    strcat(CourtCase[caseid][cArticle], gArticles[art_idx][aName], 64);
    CourtCase[caseid][cFine] = gArticles[art_idx][aFine];
    CourtCase[caseid][cJailTime] = gArticles[art_idx][aJailTime];
    CourtCase[caseid][cStatus] = 0;

    new _sf23[512]; format(_sf23, sizeof(_sf23),  "[SIDANG] %s disidang! Pasal: %s | Denda: $%d | Penjara: %d detik", 
        PlayerInfo[targetid][pName],  CourtCase[caseid][cArticle], 
        CourtCase[caseid][cFine],  CourtCase[caseid][cJailTime]); SendClientMessageToAll(COLOR_YELLOW, _sf23);
    return 1;
}

CMD:putusan(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pFaction] != 2 || PlayerInfo[playerid][pFactionRank] < 5)
        return SendMsg(playerid, COLOR_RED, "Hanya hakim yang bisa menjatuhkan vonis."), 1;

    new caseid = -1;
    for (new i = 0; i < MAX_COURT_CASES; i++)
    {
        if (CourtCase[i][cExists] && CourtCase[i][cStatus] == 0)
        {
            caseid = i;
            break;
        }
    }
    if (caseid == -1)
        return SendMsg(playerid, COLOR_RED, "Tidak ada sidang berlangsung."), 1;

    new suspect = CourtCase[caseid][cSuspect];
    PlayerInfo[suspect][pCash] -= CourtCase[caseid][cFine];
    PlayerInfo[suspect][pJail] = 1;
    PlayerInfo[suspect][pJailTime] = CourtCase[caseid][cJailTime];
    CourtCase[caseid][cStatus] = 2;

    new _sf24[512]; format(_sf24, sizeof(_sf24),  "[VONIS] %s dinyatakan BERSALAH! Denda: $%d | Penjara: %d detik", 
        PlayerInfo[suspect][pName],  CourtCase[caseid][cFine],  CourtCase[caseid][cJailTime]); SendClientMessageToAll(COLOR_RED, _sf24);

    SetTimerEx("OnCourtEnd", 5000, false, "i", caseid);
    return 1;
}

public OnCourtEnd(caseid)
{
    CourtCase[caseid][cExists] = 0;
    CourtCase[caseid][cSuspect] = INVALID_PLAYER_ID;
    CourtCase[caseid][cStatus] = 0;
    return 1;
}

CMD:jaksa(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pFaction] != 2 || PlayerInfo[playerid][pFactionRank] < 3)
        return SendMsg(playerid, COLOR_RED, "Hanya SAGS rank 3+ yang bisa jadi jaksa."), 1;
    SendMsg(playerid, COLOR_GREEN, "[SIDANG] Anda terdaftar sebagai jaksa.");
    return 1;
}

CMD:pengacara(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    SendMsg(playerid, COLOR_GREEN, "[SIDANG] Anda terdaftar sebagai pengacara pembela.");
    return 1;
}

/* =====================================================================
 *  GOVERNMENT COMMANDS
 * =====================================================================*/
CMD:pemerintah(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new str[256];
    str[0] = EOS;
    new gov_str[64];
    format(gov_str, sizeof(gov_str), "{FFFFFF}Status Pemerintahan:\n\nPajak PPh: %d persen\n", gTaxRate);
    strcat(str, gov_str, sizeof(str));
    new elec_s[8];
    if (gElectionActive) elec_s = "Ya"; else elec_s = "Tidak";
    format(gov_str, sizeof(gov_str), "Gaji PNS: $%d\n\nPemilu aktif: %s\n\n", gPNSSalary, elec_s);
    strcat(str, gov_str, sizeof(str));
    strcat(str, "{FFFF00}/daftarpilkada untuk mencalonkan diri\n/pilkada untuk memilih", sizeof(str));
    ShowPlayerDialog(playerid, DIALOG_GOVT_MENU, DIALOG_STYLE_MSGBOX, "{00FF00}Pemerintahan", str, "Tutup", "");
    return 1;
}

CMD:daftarpilkada(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (!gElectionActive)
        return SendMsg(playerid, COLOR_RED, "Pemilu belum aktif."), 1;
    if (!PlayerInfo[playerid][pKTP])
        return SendMsg(playerid, COLOR_RED, "Anda harus punya KTP."), 1;

    new type;
    if (sscanf(params, "d", type))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /daftarpilkada [1=Gubernur 2=Walikota]"), 1;
    if (type != 1 && type != 2)
        return SendMsg(playerid, COLOR_RED, "Tipe tidak valid."), 1;

    new slot = -1;
    for (new i = 0; i < MAX_GOV_CANDIDATES; i++)
    {
        if (!GovCandidate[i][gExists])
        {
            slot = i;
            break;
        }
    }
    if (slot == -1)
        return SendMsg(playerid, COLOR_RED, "Slot calon penuh."), 1;

    GovCandidate[slot][gExists] = 1;
    GovCandidate[slot][gType] = type;
    GovCandidate[slot][gPlayerID] = PlayerInfo[playerid][pID];
    GovCandidate[slot][gPlayerName][0] = EOS;
    strcat(GovCandidate[slot][gPlayerName], PlayerInfo[playerid][pName], MAX_PLAYER_NAME);
    GovCandidate[slot][gVoteCount] = 0;

    new _sf25[512];
    new gov_type_s[16];
    if (type == 1) gov_type_s = "Gubernur"; else gov_type_s = "Walikota";
    format(_sf25, sizeof(_sf25), "[PEMILU] %s mendaftar sebagai calon %s!", PlayerInfo[playerid][pName], gov_type_s);
    SendClientMessageToAll(COLOR_GREEN, _sf25);
    return 1;
}

CMD:pilkada(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (!gElectionActive)
        return SendMsg(playerid, COLOR_RED, "Pemilu belum aktif."), 1;
    if (gHasVoted[playerid])
        return SendMsg(playerid, COLOR_RED, "Anda sudah memilih."), 1;
    if (!PlayerInfo[playerid][pKTP])
        return SendMsg(playerid, COLOR_RED, "Anda harus punya KTP untuk memilih."), 1;

    new str[512];
    strcat(str, "{FFFFFF}Pilih calon:\n");
    new count = 0;
    for (new i = 0; i < MAX_GOV_CANDIDATES; i++)
    {
        if (GovCandidate[i][gExists])
        {
            new line[128];
            new cand_type[16];
            if (GovCandidate[i][gType] == 1) cand_type = "Gubernur"; else cand_type = "Walikota";
            format(line, sizeof(line), "%s - %s (%d suara)\n", GovCandidate[i][gPlayerName], cand_type, GovCandidate[i][gVoteCount]);
            strcat(str, line);
            count++;
        }
    }
    if (count == 0)
        return SendMsg(playerid, COLOR_RED, "Belum ada calon terdaftar."), 1;

    ShowPlayerDialog(playerid, DIALOG_VOTE_MENU, DIALOG_STYLE_LIST, "{00FF00}Pilkada", str, "Pilih", "Batal");
    return 1;
}

/* =====================================================================
 *  TAX COMMANDS
 * =====================================================================*/
CMD:pajak(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new str[256];
    str[0] = EOS;
    new pajak_str[128];
    format(pajak_str, sizeof(pajak_str), "{FFFFFF}Info Pajak:\n\nPPh: %d persen dari gaji\n", gTaxRate);
    strcat(str, pajak_str, sizeof(str));
    strcat(str, "PPN: 11 persen dari belanja\n", sizeof(str));
    strcat(str, "Pajak Properti: $5,000/rumah, $15,000/bisnis per bulan", sizeof(str));
    ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "{00FF00}Pajak", str, "Tutup", "");
    return 1;
}

/* =====================================================================
 *  JOB COMMANDS
 * =====================================================================*/
CMD:kerja(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pJob] != 0)
    {
        new _sf26[512]; format(_sf26, sizeof(_sf26),  "Anda sudah punya pekerjaan (Job: %d). /quitjob untuk berhenti.",  PlayerInfo[playerid][pJob]); SendClientMessage(playerid, COLOR_YELLOW, _sf26);
        return 1;
    }
    new str[256];
    format(str, sizeof(str),
        "{FFFFFF}Pilih Pekerjaan:\n1. Trucker\n2. Taxi Driver\n3. Mechanic\n4. PNS\n5. Dokter\n6. Polisi");
    ShowPlayerDialog(playerid, DIALOG_JOB_MENU, DIALOG_STYLE_LIST, "{00FF00}Pekerjaan", str, "Pilih", "Tutup");
    return 1;
}

CMD:quitjob(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pJob] == 0)
        return SendMsg(playerid, COLOR_RED, "Anda tidak punya pekerjaan."), 1;
    PlayerInfo[playerid][pJob] = 0;
    RestoreOrigSkin(playerid);
    SendMsg(playerid, COLOR_GREEN, "Anda berhenti dari pekerjaan. Skin kembali ke asli.");
    return 1;
}

/* =====================================================================
 *  SHOP COMMAND
 * =====================================================================*/
CMD:beli(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    /* Cek apakah player di dalam toko (interior 17 = 24/7 shop) */
    if (GetPlayerInterior(playerid) != 17 && GetPlayerInterior(playerid) != 1 && GetPlayerInterior(playerid) != 5 && GetPlayerInterior(playerid) != 11)
    {
        SendMsg(playerid, COLOR_RED, "Anda harus berada di dalam toko untuk beli. Cari toko dan tekan Y untuk masuk.");
        return 1;
    }
    new str[512];
    format(str, sizeof(str),
        "{FFFFFF}Toko Inferno RP:\n\n1. Makanan - $500 (Hunger +30)\n2. Minuman - $300 (Thirst +30)\n3. Obat - $2,000 (Sembuh)\n4. Handphone - $10,000\n5. Pulsa $5,000\n6. Paket Data 1GB - $3,000");
    ShowPlayerDialog(playerid, DIALOG_SHOP_MENU, DIALOG_STYLE_LIST, "{00FF00}Toko", str, "Beli", "Tutup");
    return 1;
}

/* =====================================================================
 *  OnDialogResponse - Handle shop, job, docs, bank, vote dialogs
 * =====================================================================*/
/* (OnDialogResponse already defined above, this section adds more cases) */

/* =====================================================================
 *  LOAD CALLBACKS
 * =====================================================================*/
public OnHousesLoaded()
{
    new rows;
    cache_get_row_count(rows);
    for (new i = 0; i < rows && i < MAX_HOUSES; i++)
    {
        cache_get_value_name_int(i, "id", HouseInfo[i][hID]);
        cache_get_value_name_float(i, "x", HouseInfo[i][hX]);
        cache_get_value_name_float(i, "y", HouseInfo[i][hY]);
        cache_get_value_name_float(i, "z", HouseInfo[i][hZ]);
        cache_get_value_name_int(i, "interior", HouseInfo[i][hInterior]);
        cache_get_value_name_int(i, "price", HouseInfo[i][hPrice]);
        cache_get_value_name(i, "owner", HouseInfo[i][hOwner], MAX_PLAYER_NAME);
        HouseInfo[i][hExists] = 1;
        HouseInfo[i][hPickup] = CreateDynamicPickup(1273, 23, HouseInfo[i][hX], HouseInfo[i][hY], HouseInfo[i][hZ]);
        gTotalHouses++;
    }
    printf("[InfernoRP] %d rumah dimuat.", gTotalHouses);
    return 1;
}

public OnBusinessesLoaded()
{
    new rows;
    cache_get_row_count(rows);
    for (new i = 0; i < rows && i < MAX_BUSINESSES; i++)
    {
        cache_get_value_name_int(i, "id", BizInfo[i][bID]);
        cache_get_value_name_float(i, "x", BizInfo[i][bX]);
        cache_get_value_name_float(i, "y", BizInfo[i][bY]);
        cache_get_value_name_float(i, "z", BizInfo[i][bZ]);
        cache_get_value_name_int(i, "interior", BizInfo[i][bInterior]);
        cache_get_value_name_int(i, "price", BizInfo[i][bPrice]);
        cache_get_value_name(i, "owner", BizInfo[i][bOwner], MAX_PLAYER_NAME);
        BizInfo[i][bExists] = 1;
        BizInfo[i][bPickup] = CreateDynamicPickup(1274, 23, BizInfo[i][bX], BizInfo[i][bY], BizInfo[i][bZ]);
        gTotalBusinesses++;
    }
    printf("[InfernoRP] %d bisnis dimuat.", gTotalBusinesses);
    return 1;
}

public OnFuelStationsLoaded()
{
    new rows;
    cache_get_row_count(rows);
    for (new i = 0; i < rows && i < MAX_FUEL_STATIONS; i++)
    {
        cache_get_value_name_int(i, "id", FuelInfo[i][fID]);
        cache_get_value_name_float(i, "x", FuelInfo[i][fX]);
        cache_get_value_name_float(i, "y", FuelInfo[i][fY]);
        cache_get_value_name_float(i, "z", FuelInfo[i][fZ]);
        FuelInfo[i][fExists] = 1;
    }
    printf("[InfernoRP] %d SPBU dimuat.", rows);
    return 1;
}

public OnElectionEnd()
{
    gElectionActive = 0;
    new winner = -1, max_votes = 0;
    for (new i = 0; i < MAX_GOV_CANDIDATES; i++)
    {
        if (GovCandidate[i][gExists] && GovCandidate[i][gVoteCount] > max_votes)
        {
            max_votes = GovCandidate[i][gVoteCount];
            winner = i;
        }
    }
    if (winner == -1)
    {
        SendClientMessageToAll(COLOR_RED, "[PEMILU] Tidak ada pemenang.");
        return 1;
    }
    new _sf27[512];
    new win_type_s[16];
    if (GovCandidate[winner][gType] == 1) win_type_s = "Gubernur"; else win_type_s = "Walikota";
    format(_sf27, sizeof(_sf27), "[PEMILU] %s terpilih sebagai %s!", GovCandidate[winner][gPlayerName], win_type_s);
    SendClientMessageToAll(COLOR_GREEN, _sf27);
    return 1;
}

/* =====================================================================
 *  ADMIN COMMANDS
 * =====================================================================*/

/* --- /ahelp - tampilkan semua command admin --- */
CMD:ahelp(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 1)
        return SendMsg(playerid, COLOR_RED, "Anda bukan admin."), 1;

    new str[1024];
    str[0] = EOS;
    strcat(str, "{FFFFFF}=== Admin Commands ===\n\n", sizeof(str));
    strcat(str, "{00FF00}Level 1 (Helper):{FFFFFF}\n", sizeof(str));
    strcat(str, "/ahelp /a (admin chat) /heal /armor /goto\n\n", sizeof(str));
    strcat(str, "{00FF00}Level 2 (Mod):{FFFFFF}\n", sizeof(str));
    strcat(str, "/gethere /freeze /unfreeze /mute /unmute\n", sizeof(str));
    strcat(str, "/slap /warn\n\n", sizeof(str));
    strcat(str, "{00FF00}Level 3 (Admin):{FFFFFF}\n", sizeof(str));
    strcat(str, "/kick /sethp /setarmor /setcash /setbank\n", sizeof(str));
    strcat(str, "/setskin /setlevel /setjob /setfaction\n\n", sizeof(str));
    strcat(str, "{00FF00}Level 4 (Lead Admin):{FFFFFF}\n", sizeof(str));
    strcat(str, "/ban /unban /jail /unjail /respawnall\n", sizeof(str));
    strcat(str, "/settime /setweather /announce\n\n", sizeof(str));
    strcat(str, "{00FF00}Level 5 (Owner):{FFFFFF}\n", sizeof(str));
    strcat(str, "/setadmin /giveweapon /givemoney\n", sizeof(str));
    strcat(str, "/settax /setpnssalary\n", sizeof(str));
    ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "{00FF00}Admin Help", str, "Tutup", "");
    return 1;
}

/* --- /a [text] - admin chat --- */
CMD:a(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 1)
        return SendMsg(playerid, COLOR_RED, "Anda bukan admin."), 1;
    if (isnull(params))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /a [pesan]"), 1;

    new _sf_a[256];
    format(_sf_a, sizeof(_sf_a), "[ADMIN] %s: %s", PlayerInfo[playerid][pName], params);
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerInfo[i][pIsLogged] && PlayerInfo[i][pAdminLevel] >= 1)
            SendClientMessage(i, COLOR_PURPLE, _sf_a);
    }
    return 1;
}

/* --- /heal [playerid] --- */
CMD:heal(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 1)
        return SendMsg(playerid, COLOR_RED, "Anda bukan admin."), 1;
    new targetid;
    if (sscanf(params, "u", targetid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /heal [playerid]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    SetPlayerHealth(targetid, 100.0);
    SendFmt(playerid, COLOR_GREEN, "Anda menyembuhkan %s.", PlayerInfo[targetid][pName]);
    return 1;
}

/* --- /armor [playerid] --- */
CMD:armor(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 1)
        return SendMsg(playerid, COLOR_RED, "Anda bukan admin."), 1;
    new targetid;
    if (sscanf(params, "u", targetid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /armor [playerid]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    SetPlayerArmour(targetid, 100.0);
    SendFmt(playerid, COLOR_GREEN, "Anda memberi armor ke %s.", PlayerInfo[targetid][pName]);
    return 1;
}

/* --- /goto [playerid] --- */
CMD:goto(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 1)
        return SendMsg(playerid, COLOR_RED, "Anda bukan admin."), 1;
    new targetid;
    if (sscanf(params, "u", targetid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /goto [playerid]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    new Float:x, Float:y, Float:z;
    GetPlayerPos(targetid, x, y, z);
    SetPlayerPos(playerid, x + 1.0, y + 1.0, z);
    SetPlayerInterior(playerid, GetPlayerInterior(targetid));
    SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
    SendFmt(playerid, COLOR_GREEN, "Teleport ke %s.", PlayerInfo[targetid][pName]);
    return 1;
}

/* --- /gethere [playerid] --- */
CMD:gethere(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 2)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 2."), 1;
    new targetid;
    if (sscanf(params, "u", targetid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /gethere [playerid]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    SetPlayerPos(targetid, x + 1.0, y + 1.0, z);
    SetPlayerInterior(targetid, GetPlayerInterior(playerid));
    SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));
    SendFmt(playerid, COLOR_GREEN, "Anda memanggil %s.", PlayerInfo[targetid][pName]);
    return 1;
}

/* --- /freeze [playerid] --- */
CMD:freeze(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 2)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 2."), 1;
    new targetid;
    if (sscanf(params, "u", targetid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /freeze [playerid]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    TogglePlayerControllable(targetid, false);
    SendFmt(playerid, COLOR_GREEN, "Anda membekukan %s.", PlayerInfo[targetid][pName]);
    return 1;
}

/* --- /unfreeze [playerid] --- */
CMD:unfreeze(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 2)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 2."), 1;
    new targetid;
    if (sscanf(params, "u", targetid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /unfreeze [playerid]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    TogglePlayerControllable(targetid, true);
    SendFmt(playerid, COLOR_GREEN, "Anda mencairkan %s.", PlayerInfo[targetid][pName]);
    return 1;
}

/* --- /slap [playerid] --- */
CMD:slap(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 2)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 2."), 1;
    new targetid;
    if (sscanf(params, "u", targetid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /slap [playerid]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    new Float:x, Float:y, Float:z;
    GetPlayerPos(targetid, x, y, z);
    SetPlayerPos(targetid, x, y, z + 5.0);
    SetPlayerHealth(targetid, 50.0);
    SendFmt(playerid, COLOR_GREEN, "Anda menampar %s.", PlayerInfo[targetid][pName]);
    return 1;
}

/* --- /kick [playerid] [reason] --- */
CMD:kick(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 3)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 3."), 1;
    new targetid, reason[64];
    if (sscanf(params, "us[64]", targetid, reason))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /kick [playerid] [alasan]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    new _sf_kick[256];
    format(_sf_kick, sizeof(_sf_kick), "[KICK] %s di-kick oleh %s. Alasan: %s", PlayerInfo[targetid][pName], PlayerInfo[playerid][pName], reason);
    SendClientMessageToAll(COLOR_RED, _sf_kick);
    Kick(targetid);
    return 1;
}

/* --- /ban [playerid] [reason] --- */
CMD:ban(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 4)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 4."), 1;
    new targetid, reason[64];
    if (sscanf(params, "us[64]", targetid, reason))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /ban [playerid] [alasan]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    new _sf_ban[256];
    format(_sf_ban, sizeof(_sf_ban), "[BAN] %s di-ban oleh %s. Alasan: %s", PlayerInfo[targetid][pName], PlayerInfo[playerid][pName], reason);
    SendClientMessageToAll(COLOR_RED, _sf_ban);
    /* Ban IP */
    new ip[45];
    GetPlayerIp(targetid, ip, sizeof(ip));
    new query[128];
    mysql_format(gSQL, query, sizeof(query), "INSERT INTO `banneds` (`name`, `ip`, `reason`) VALUES ('%e', '%e', '%e')", PlayerInfo[targetid][pName], ip, reason);
    mysql_tquery(gSQL, query);
    Ban(targetid);
    return 1;
}

/* --- /sethp [playerid] [amount] --- */
CMD:sethp(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 3)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 3."), 1;
    new targetid, amount;
    if (sscanf(params, "ud", targetid, amount))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /sethp [playerid] [0-100]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    SetPlayerHealth(targetid, float(amount));
    SendFmt(playerid, COLOR_GREEN, "HP %s di-set ke %d.", PlayerInfo[targetid][pName], amount);
    return 1;
}

/* --- /setarmor [playerid] [amount] --- */
CMD:setarmor(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 3)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 3."), 1;
    new targetid, amount;
    if (sscanf(params, "ud", targetid, amount))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /setarmor [playerid] [0-100]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    SetPlayerArmour(targetid, float(amount));
    SendFmt(playerid, COLOR_GREEN, "Armor %s di-set ke %d.", PlayerInfo[targetid][pName], amount);
    return 1;
}

/* --- /setcash [playerid] [amount] --- */
CMD:setcash(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 3)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 3."), 1;
    new targetid, amount;
    if (sscanf(params, "ud", targetid, amount))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /setcash [playerid] [jumlah]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    PlayerInfo[targetid][pCash] = amount;
    GivePlayerMoney(targetid, amount - GetPlayerMoney(targetid));
    SendFmt(playerid, COLOR_GREEN, "Cash %s di-set ke $%d.", PlayerInfo[targetid][pName], amount);
    return 1;
}

/* --- /setbank [playerid] [amount] --- */
CMD:setbank(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 3)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 3."), 1;
    new targetid, amount;
    if (sscanf(params, "ud", targetid, amount))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /setbank [playerid] [jumlah]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    PlayerInfo[targetid][pBank] = amount;
    SendFmt(playerid, COLOR_GREEN, "Bank %s di-set ke $%d.", PlayerInfo[targetid][pName], amount);
    return 1;
}

/* --- /setskin [playerid] [skinid] --- */
CMD:setskin(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 3)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 3."), 1;
    new targetid, skinid;
    if (sscanf(params, "ud", targetid, skinid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /setskin [playerid] [skinid]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    PlayerInfo[targetid][pSkin] = skinid;
    SetPlayerSkin(targetid, skinid);
    SendFmt(playerid, COLOR_GREEN, "Skin %s di-set ke %d.", PlayerInfo[targetid][pName], skinid);
    return 1;
}

/* --- /setlevel [playerid] [level] --- */
CMD:setlevel(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 3)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 3."), 1;
    new targetid, level;
    if (sscanf(params, "ud", targetid, level))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /setlevel [playerid] [level]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    PlayerInfo[targetid][pLevel] = level;
    SendFmt(playerid, COLOR_GREEN, "Level %s di-set ke %d.", PlayerInfo[targetid][pName], level);
    return 1;
}

/* --- /setjob [playerid] [jobid] --- */
CMD:setjob(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 3)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 3."), 1;
    new targetid, jobid;
    if (sscanf(params, "ud", targetid, jobid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /setjob [playerid] [0-6]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    PlayerInfo[targetid][pJob] = jobid;
    SendFmt(playerid, COLOR_GREEN, "Job %s di-set ke %d.", PlayerInfo[targetid][pName], jobid);
    return 1;
}

/* --- /setfaction [playerid] [factionid] --- */
CMD:setfaction(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 3)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 3."), 1;
    new targetid, factionid;
    if (sscanf(params, "ud", targetid, factionid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /setfaction [playerid] [0-4]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    PlayerInfo[targetid][pFaction] = factionid;
    SendFmt(playerid, COLOR_GREEN, "Faction %s di-set ke %d.", PlayerInfo[targetid][pName], factionid);
    return 1;
}

/* --- /jail [playerid] [time] --- */
CMD:jail(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 4)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 4."), 1;
    new targetid, time;
    if (sscanf(params, "ud", targetid, time))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /jail [playerid] [detik]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    PlayerInfo[targetid][pJail] = 1;
    PlayerInfo[targetid][pJailTime] = time;
    SetPlayerPos(targetid, 264.50, 77.60, 1001.04);
    SetPlayerInterior(targetid, 6);
    new _sf_jail[256];
    format(_sf_jail, sizeof(_sf_jail), "[JAIL] %s di-penjara selama %d detik.", PlayerInfo[targetid][pName], time);
    SendClientMessageToAll(COLOR_RED, _sf_jail);
    return 1;
}

/* --- /unjail [playerid] --- */
CMD:unjail(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 4)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 4."), 1;
    new targetid;
    if (sscanf(params, "u", targetid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /unjail [playerid]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    PlayerInfo[targetid][pJail] = 0;
    PlayerInfo[targetid][pJailTime] = 0;
    SetPlayerPos(targetid, 1743.20, -1862.05, 13.58);
    SetPlayerInterior(targetid, 0);
    SendFmt(playerid, COLOR_GREEN, "%s dibebaskan dari penjara.", PlayerInfo[targetid][pName]);
    return 1;
}

/* --- /settime [hour] --- */
CMD:settime(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 4)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 4."), 1;
    new hour;
    if (sscanf(params, "d", hour))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /settime [0-23]"), 1;
    SetWorldTime(hour);
    SendFmt(playerid, COLOR_GREEN, "Waktu di-set ke %d:00.", hour);
    return 1;
}

/* --- /setweather [weatherid] --- */
CMD:setweather(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 4)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 4."), 1;
    new weatherid;
    if (sscanf(params, "d", weatherid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /setweather [0-20]"), 1;
    SetWeather(weatherid);
    gCurrentWeather = weatherid;
    SendFmt(playerid, COLOR_GREEN, "Cuaca di-set ke %d.", weatherid);
    return 1;
}

/* --- /announce [text] --- */
CMD:announce(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 4)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 4."), 1;
    if (isnull(params))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /announce [pesan]"), 1;
    GameTextForAll(params, 5000, 5);
    return 1;
}

/* --- /respawnall --- */
CMD:respawnall(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 4)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 4."), 1;
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerInfo[i][pIsLogged])
            SpawnPlayer(i);
    }
    SendClientMessageToAll(COLOR_GREEN, "[ADMIN] Semua pemain di-respawn.");
    return 1;
}

/* --- /setadmin [playerid] [level] --- */
CMD:setadmin(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 5)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 5 (Owner)."), 1;
    new targetid, level;
    if (sscanf(params, "ud", targetid, level))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /setadmin [playerid] [0-5]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    PlayerInfo[targetid][pAdminLevel] = level;
    SendFmt(playerid, COLOR_GREEN, "Admin level %s di-set ke %d.", PlayerInfo[targetid][pName], level);
    return 1;
}

/* --- /giveweapon [playerid] [weaponid] [ammo] --- */
CMD:giveweapon(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 5)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 5 (Owner)."), 1;
    new targetid, weaponid, ammo;
    if (sscanf(params, "udd", targetid, weaponid, ammo))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /giveweapon [playerid] [weaponid] [ammo]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    GivePlayerWeapon(targetid, weaponid, ammo);
    SendFmt(playerid, COLOR_GREEN, "Weapon %d (%d ammo) diberikan ke %s.", weaponid, ammo, PlayerInfo[targetid][pName]);
    return 1;
}

/* --- /givemoney [playerid] [amount] --- */
CMD:givemoney(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 5)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 5 (Owner)."), 1;
    new targetid, amount;
    if (sscanf(params, "ud", targetid, amount))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /givemoney [playerid] [jumlah]"), 1;
    if (!IsPlayerConnected(targetid))
        return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    PlayerInfo[targetid][pCash] += amount;
    GivePlayerMoney(targetid, amount);
    SendFmt(playerid, COLOR_GREEN, "$%d diberikan ke %s.", amount, PlayerInfo[targetid][pName]);
    return 1;
}

/* --- /settax [rate] --- */
CMD:settax(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 5)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 5 (Owner)."), 1;
    new rate;
    if (sscanf(params, "d", rate))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /settax [0-50]"), 1;
    if (rate < 0 || rate > 50)
        return SendMsg(playerid, COLOR_RED, "Rate 0-50 persen."), 1;
    gTaxRate = rate;
    SendFmt(playerid, COLOR_GREEN, "Pajak PPh di-set ke %d persen.", rate);
    return 1;
}

/* --- /setpnssalary [amount] --- */
CMD:setpnssalary(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 5)
        return SendMsg(playerid, COLOR_RED, "Butuh admin level 5 (Owner)."), 1;
    new amount;
    if (sscanf(params, "d", amount))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /setpnssalary [jumlah]"), 1;
    gPNSSalary = amount;
    SendFmt(playerid, COLOR_GREEN, "Gaji PNS di-set ke $%d.", amount);
    return 1;
}

/* =====================================================================
 *  OnPlayerDeath
 * =====================================================================*/
public OnPlayerDeath(playerid, killerid, reason)
{
    if (PlayerInfo[playerid][pIsLogged])
    {
        PlayerInfo[playerid][pHealth] = 100.0;
        PlayerInfo[playerid][pHunger] -= 10.0;
        PlayerInfo[playerid][pThirst] -= 10.0;
        SendMsg(playerid, COLOR_RED, "Anda mati. Hunger & Thirst berkurang.");
    }
    return 1;
}

/* =====================================================================
 *  OnPlayerText
 * =====================================================================*/
public OnPlayerText(playerid, text[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 0;
    return 1;
}
