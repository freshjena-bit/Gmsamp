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
    pOnDuty,
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

/* ---------- TextDraw HUD Variables (Modern Box-Style) ---------- */
new Text:TD_BgLeft;         /* Left panel background */
new Text:TD_BgRight;        /* Right panel background */
new Text:TD_BgClock;        /* Clock background */
new Text:TD_ServerName;
new Text:TD_HealthLabel;
new Text:TD_ArmorLabel;
new Text:TD_HungerLabel;
new Text:TD_ThirstLabel;
new Text:TD_SleepLabel;
new Text:TD_StaminaLabel;
new Text:TD_Cash;
new Text:TD_Bank;
new Text:TD_Level;
new Text:TD_Job;
new Text:TD_Phone;
new Text:TD_Clock;

/* Bar backgrounds (dark) - global */
new Text:TD_HpBarBg;
new Text:TD_ArBarBg;
new Text:TD_HgBarBg;
new Text:TD_ThBarBg;
new Text:TD_SlBarBg;
new Text:TD_StBarBg;

/* Bar fills (colored, per-player for dynamic width) */
new PlayerText:TD_HpBar[MAX_PLAYERS];
new PlayerText:TD_ArBar[MAX_PLAYERS];
new PlayerText:TD_HgBar[MAX_PLAYERS];
new PlayerText:TD_ThBar[MAX_PLAYERS];
new PlayerText:TD_SlBar[MAX_PLAYERS];
new PlayerText:TD_StBar[MAX_PLAYERS];

new PlayerText:TD_Speedo[MAX_PLAYERS];
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
 *  TEXTDRAW HUD SYSTEM - Modern Box-Style (ESX/FiveM inspired)
 * =====================================================================*/

#define BAR_X         48.0    /* Bar start X */
#define BAR_WIDTH     90.0    /* Max bar width */
#define BAR_HEIGHT    6.0     /* Bar height (in Y letter size units) */
#define BAR_GAP       12.0    /* Gap between bars (Y) */
#define BAR_START_Y   358.0   /* First bar Y position */
#define PANEL_X       12.0    /* Panel left X */
#define PANEL_W       140.0   /* Panel width */

/* Helper: get color by value */
stock Float:GetBarWidth(Float:value, Float:maxval)
{
    new Float:w = (value / maxval) * BAR_WIDTH;
    if (w < 1.0) w = 1.0;
    if (w > BAR_WIDTH) w = BAR_WIDTH;
    return w;
}

stock GetBarColor(Float:value)
{
    if (value >= 60.0) return 0x4CAF50FF; /* Green */
    if (value >= 30.0) return 0xFFC107FF; /* Amber */
    return 0xF44336FF; /* Red */
}

stock CreateHUDTextDraws()
{
    /* === LEFT PANEL BACKGROUND === */
    TD_BgLeft = TextDrawCreate(PANEL_X, 340.0, "_");
    TextDrawUseBox(TD_BgLeft, 1);
    TextDrawBoxColor(TD_BgLeft, 0x00000066);
    TextDrawTextSize(TD_BgLeft, PANEL_X + PANEL_W, 0.0);
    TextDrawLetterSize(TD_BgLeft, 0.5, 7.5);
    TextDrawSetShadow(TD_BgLeft, 0);

    /* === RIGHT PANEL BACKGROUND === */
    TD_BgRight = TextDrawCreate(500.0, 2.0, "_");
    TextDrawUseBox(TD_BgRight, 1);
    TextDrawBoxColor(TD_BgRight, 0x00000066);
    TextDrawTextSize(TD_BgRight, 635.0, 0.0);
    TextDrawLetterSize(TD_BgRight, 0.5, 5.5);
    TextDrawSetShadow(TD_BgRight, 0);

    /* === CLOCK BACKGROUND === */
    TD_BgClock = TextDrawCreate(285.0, 2.0, "_");
    TextDrawUseBox(TD_BgClock, 1);
    TextDrawBoxColor(TD_BgClock, 0x00000066);
    TextDrawTextSize(TD_BgClock, 360.0, 0.0);
    TextDrawLetterSize(TD_BgClock, 0.5, 1.5);
    TextDrawSetShadow(TD_BgClock, 0);

    /* === SERVER NAME === */
    TD_ServerName = TextDrawCreate(PANEL_X + 3.0, 342.0, "~b~~h~INFERNO~w~ RP");
    TextDrawLetterSize(TD_ServerName, 0.17, 0.75);
    TextDrawSetShadow(TD_ServerName, 0);
    TextDrawSetOutline(TD_ServerName, 1);

    /* === STAT LABELS (compact, left-aligned) === */
    TD_HealthLabel = TextDrawCreate(PANEL_X + 3.0, BAR_START_Y, "~w~HP");
    TextDrawLetterSize(TD_HealthLabel, 0.14, 0.65);
    TextDrawSetShadow(TD_HealthLabel, 0);

    TD_ArmorLabel = TextDrawCreate(PANEL_X + 3.0, BAR_START_Y + BAR_GAP, "~w~AR");
    TextDrawLetterSize(TD_ArmorLabel, 0.14, 0.65);
    TextDrawSetShadow(TD_ArmorLabel, 0);

    TD_HungerLabel = TextDrawCreate(PANEL_X + 3.0, BAR_START_Y + BAR_GAP * 2, "~w~FD");
    TextDrawLetterSize(TD_HungerLabel, 0.14, 0.65);
    TextDrawSetShadow(TD_HungerLabel, 0);

    TD_ThirstLabel = TextDrawCreate(PANEL_X + 3.0, BAR_START_Y + BAR_GAP * 3, "~w~WT");
    TextDrawLetterSize(TD_ThirstLabel, 0.14, 0.65);
    TextDrawSetShadow(TD_ThirstLabel, 0);

    TD_SleepLabel = TextDrawCreate(PANEL_X + 3.0, BAR_START_Y + BAR_GAP * 4, "~w~SL");
    TextDrawLetterSize(TD_SleepLabel, 0.14, 0.65);
    TextDrawSetShadow(TD_SleepLabel, 0);

    TD_StaminaLabel = TextDrawCreate(PANEL_X + 3.0, BAR_START_Y + BAR_GAP * 5, "~w~ST");
    TextDrawLetterSize(TD_StaminaLabel, 0.14, 0.65);
    TextDrawSetShadow(TD_StaminaLabel, 0);

    /* === BAR BACKGROUNDS (dark gray boxes) === */
    TD_HpBarBg = TextDrawCreate(BAR_X, BAR_START_Y + 2.0, "_");
    TextDrawUseBox(TD_HpBarBg, 1);
    TextDrawBoxColor(TD_HpBarBg, 0x333333FF);
    TextDrawTextSize(TD_HpBarBg, BAR_X + BAR_WIDTH, 0.0);
    TextDrawLetterSize(TD_HpBarBg, 0.5, 0.3);
    TextDrawSetShadow(TD_HpBarBg, 0);

    TD_ArBarBg = TextDrawCreate(BAR_X, BAR_START_Y + BAR_GAP + 2.0, "_");
    TextDrawUseBox(TD_ArBarBg, 1);
    TextDrawBoxColor(TD_ArBarBg, 0x333333FF);
    TextDrawTextSize(TD_ArBarBg, BAR_X + BAR_WIDTH, 0.0);
    TextDrawLetterSize(TD_ArBarBg, 0.5, 0.3);
    TextDrawSetShadow(TD_ArBarBg, 0);

    TD_HgBarBg = TextDrawCreate(BAR_X, BAR_START_Y + BAR_GAP * 2 + 2.0, "_");
    TextDrawUseBox(TD_HgBarBg, 1);
    TextDrawBoxColor(TD_HgBarBg, 0x333333FF);
    TextDrawTextSize(TD_HgBarBg, BAR_X + BAR_WIDTH, 0.0);
    TextDrawLetterSize(TD_HgBarBg, 0.5, 0.3);
    TextDrawSetShadow(TD_HgBarBg, 0);

    TD_ThBarBg = TextDrawCreate(BAR_X, BAR_START_Y + BAR_GAP * 3 + 2.0, "_");
    TextDrawUseBox(TD_ThBarBg, 1);
    TextDrawBoxColor(TD_ThBarBg, 0x333333FF);
    TextDrawTextSize(TD_ThBarBg, BAR_X + BAR_WIDTH, 0.0);
    TextDrawLetterSize(TD_ThBarBg, 0.5, 0.3);
    TextDrawSetShadow(TD_ThBarBg, 0);

    TD_SlBarBg = TextDrawCreate(BAR_X, BAR_START_Y + BAR_GAP * 4 + 2.0, "_");
    TextDrawUseBox(TD_SlBarBg, 1);
    TextDrawBoxColor(TD_SlBarBg, 0x333333FF);
    TextDrawTextSize(TD_SlBarBg, BAR_X + BAR_WIDTH, 0.0);
    TextDrawLetterSize(TD_SlBarBg, 0.5, 0.3);
    TextDrawSetShadow(TD_SlBarBg, 0);

    TD_StBarBg = TextDrawCreate(BAR_X, BAR_START_Y + BAR_GAP * 5 + 2.0, "_");
    TextDrawUseBox(TD_StBarBg, 1);
    TextDrawBoxColor(TD_StBarBg, 0x333333FF);
    TextDrawTextSize(TD_StBarBg, BAR_X + BAR_WIDTH, 0.0);
    TextDrawLetterSize(TD_StBarBg, 0.5, 0.3);
    TextDrawSetShadow(TD_StBarBg, 0);

    /* === RIGHT PANEL: Player Info === */
    TD_Cash = TextDrawCreate(630.0, 4.0, "~g~~h~$0");
    TextDrawLetterSize(TD_Cash, 0.25, 1.0);
    TextDrawSetShadow(TD_Cash, 0);
    TextDrawSetOutline(TD_Cash, 1);
    TextDrawAlignment(TD_Cash, 3);

    TD_Bank = TextDrawCreate(630.0, 18.0, "~b~Bank: $0");
    TextDrawLetterSize(TD_Bank, 0.15, 0.7);
    TextDrawSetShadow(TD_Bank, 0);
    TextDrawSetOutline(TD_Bank, 1);
    TextDrawAlignment(TD_Bank, 3);

    TD_Level = TextDrawCreate(630.0, 30.0, "~w~Lvl 1");
    TextDrawLetterSize(TD_Level, 0.15, 0.7);
    TextDrawSetShadow(TD_Level, 0);
    TextDrawSetOutline(TD_Level, 1);
    TextDrawAlignment(TD_Level, 3);

    TD_Job = TextDrawCreate(630.0, 42.0, "~w~Job: -");
    TextDrawLetterSize(TD_Job, 0.15, 0.7);
    TextDrawSetShadow(TD_Job, 0);
    TextDrawSetOutline(TD_Job, 1);
    TextDrawAlignment(TD_Job, 3);

    TD_Phone = TextDrawCreate(630.0, 54.0, "~w~HP: -");
    TextDrawLetterSize(TD_Phone, 0.15, 0.7);
    TextDrawSetShadow(TD_Phone, 0);
    TextDrawSetOutline(TD_Phone, 1);
    TextDrawAlignment(TD_Phone, 3);

    /* === CLOCK === */
    TD_Clock = TextDrawCreate(320.0, 4.0, "00:00");
    TextDrawLetterSize(TD_Clock, 0.28, 1.1);
    TextDrawSetShadow(TD_Clock, 0);
    TextDrawSetOutline(TD_Clock, 1);
    TextDrawAlignment(TD_Clock, 2);

    print("[InfernoRP] Modern Box-Style HUD created.");
}

stock CreatePlayerHUD(playerid)
{
    /* Per-player colored bar fills - dynamic width via TextSize */
    TD_HpBar[playerid] = CreatePlayerTextDraw(playerid, BAR_X, BAR_START_Y + 2.0, "_");
    PlayerTextDrawUseBox(playerid, TD_HpBar[playerid], 1);
    PlayerTextDrawBoxColor(playerid, TD_HpBar[playerid], 0x4CAF50FF);
    PlayerTextDrawTextSize(playerid, TD_HpBar[playerid], BAR_X + BAR_WIDTH, 0.0);
    PlayerTextDrawLetterSize(playerid, TD_HpBar[playerid], 0.5, 0.3);
    PlayerTextDrawSetShadow(playerid, TD_HpBar[playerid], 0);

    TD_ArBar[playerid] = CreatePlayerTextDraw(playerid, BAR_X, BAR_START_Y + BAR_GAP + 2.0, "_");
    PlayerTextDrawUseBox(playerid, TD_ArBar[playerid], 1);
    PlayerTextDrawBoxColor(playerid, TD_ArBar[playerid], 0x2196F3FF);
    PlayerTextDrawTextSize(playerid, TD_ArBar[playerid], BAR_X + 1.0, 0.0);
    PlayerTextDrawLetterSize(playerid, TD_ArBar[playerid], 0.5, 0.3);
    PlayerTextDrawSetShadow(playerid, TD_ArBar[playerid], 0);

    TD_HgBar[playerid] = CreatePlayerTextDraw(playerid, BAR_X, BAR_START_Y + BAR_GAP * 2 + 2.0, "_");
    PlayerTextDrawUseBox(playerid, TD_HgBar[playerid], 1);
    PlayerTextDrawBoxColor(playerid, TD_HgBar[playerid], 0xFF9800FF);
    PlayerTextDrawTextSize(playerid, TD_HgBar[playerid], BAR_X + BAR_WIDTH, 0.0);
    PlayerTextDrawLetterSize(playerid, TD_HgBar[playerid], 0.5, 0.3);
    PlayerTextDrawSetShadow(playerid, TD_HgBar[playerid], 0);

    TD_ThBar[playerid] = CreatePlayerTextDraw(playerid, BAR_X, BAR_START_Y + BAR_GAP * 3 + 2.0, "_");
    PlayerTextDrawUseBox(playerid, TD_ThBar[playerid], 1);
    PlayerTextDrawBoxColor(playerid, TD_ThBar[playerid], 0x00BCD4FF);
    PlayerTextDrawTextSize(playerid, TD_ThBar[playerid], BAR_X + BAR_WIDTH, 0.0);
    PlayerTextDrawLetterSize(playerid, TD_ThBar[playerid], 0.5, 0.3);
    PlayerTextDrawSetShadow(playerid, TD_ThBar[playerid], 0);

    TD_SlBar[playerid] = CreatePlayerTextDraw(playerid, BAR_X, BAR_START_Y + BAR_GAP * 4 + 2.0, "_");
    PlayerTextDrawUseBox(playerid, TD_SlBar[playerid], 1);
    PlayerTextDrawBoxColor(playerid, TD_SlBar[playerid], 0x9C27B0FF);
    PlayerTextDrawTextSize(playerid, TD_SlBar[playerid], BAR_X + BAR_WIDTH, 0.0);
    PlayerTextDrawLetterSize(playerid, TD_SlBar[playerid], 0.5, 0.3);
    PlayerTextDrawSetShadow(playerid, TD_SlBar[playerid], 0);

    TD_StBar[playerid] = CreatePlayerTextDraw(playerid, BAR_X, BAR_START_Y + BAR_GAP * 5 + 2.0, "_");
    PlayerTextDrawUseBox(playerid, TD_StBar[playerid], 1);
    PlayerTextDrawBoxColor(playerid, TD_StBar[playerid], 0x4CAF50FF);
    PlayerTextDrawTextSize(playerid, TD_StBar[playerid], BAR_X + BAR_WIDTH, 0.0);
    PlayerTextDrawLetterSize(playerid, TD_StBar[playerid], 0.5, 0.3);
    PlayerTextDrawSetShadow(playerid, TD_StBar[playerid], 0);
}

stock ShowPlayerHUD(playerid)
{
    TextDrawShowForPlayer(playerid, TD_BgLeft);
    TextDrawShowForPlayer(playerid, TD_BgRight);
    TextDrawShowForPlayer(playerid, TD_BgClock);
    TextDrawShowForPlayer(playerid, TD_ServerName);
    TextDrawShowForPlayer(playerid, TD_HealthLabel);
    TextDrawShowForPlayer(playerid, TD_ArmorLabel);
    TextDrawShowForPlayer(playerid, TD_HungerLabel);
    TextDrawShowForPlayer(playerid, TD_ThirstLabel);
    TextDrawShowForPlayer(playerid, TD_SleepLabel);
    TextDrawShowForPlayer(playerid, TD_StaminaLabel);
    TextDrawShowForPlayer(playerid, TD_HpBarBg);
    TextDrawShowForPlayer(playerid, TD_ArBarBg);
    TextDrawShowForPlayer(playerid, TD_HgBarBg);
    TextDrawShowForPlayer(playerid, TD_ThBarBg);
    TextDrawShowForPlayer(playerid, TD_SlBarBg);
    TextDrawShowForPlayer(playerid, TD_StBarBg);
    TextDrawShowForPlayer(playerid, TD_Cash);
    TextDrawShowForPlayer(playerid, TD_Bank);
    TextDrawShowForPlayer(playerid, TD_Level);
    TextDrawShowForPlayer(playerid, TD_Job);
    TextDrawShowForPlayer(playerid, TD_Phone);
    TextDrawShowForPlayer(playerid, TD_Clock);
    PlayerTextDrawShow(playerid, TD_HpBar[playerid]);
    PlayerTextDrawShow(playerid, TD_ArBar[playerid]);
    PlayerTextDrawShow(playerid, TD_HgBar[playerid]);
    PlayerTextDrawShow(playerid, TD_ThBar[playerid]);
    PlayerTextDrawShow(playerid, TD_SlBar[playerid]);
    PlayerTextDrawShow(playerid, TD_StBar[playerid]);
}

stock HidePlayerHUD(playerid)
{
    TextDrawHideForPlayer(playerid, TD_BgLeft);
    TextDrawHideForPlayer(playerid, TD_BgRight);
    TextDrawHideForPlayer(playerid, TD_BgClock);
    TextDrawHideForPlayer(playerid, TD_ServerName);
    TextDrawHideForPlayer(playerid, TD_HealthLabel);
    TextDrawHideForPlayer(playerid, TD_ArmorLabel);
    TextDrawHideForPlayer(playerid, TD_HungerLabel);
    TextDrawHideForPlayer(playerid, TD_ThirstLabel);
    TextDrawHideForPlayer(playerid, TD_SleepLabel);
    TextDrawHideForPlayer(playerid, TD_StaminaLabel);
    TextDrawHideForPlayer(playerid, TD_HpBarBg);
    TextDrawHideForPlayer(playerid, TD_ArBarBg);
    TextDrawHideForPlayer(playerid, TD_HgBarBg);
    TextDrawHideForPlayer(playerid, TD_ThBarBg);
    TextDrawHideForPlayer(playerid, TD_SlBarBg);
    TextDrawHideForPlayer(playerid, TD_StBarBg);
    TextDrawHideForPlayer(playerid, TD_Cash);
    TextDrawHideForPlayer(playerid, TD_Bank);
    TextDrawHideForPlayer(playerid, TD_Level);
    TextDrawHideForPlayer(playerid, TD_Job);
    TextDrawHideForPlayer(playerid, TD_Phone);
    TextDrawHideForPlayer(playerid, TD_Clock);
    PlayerTextDrawHide(playerid, TD_HpBar[playerid]);
    PlayerTextDrawHide(playerid, TD_ArBar[playerid]);
    PlayerTextDrawHide(playerid, TD_HgBar[playerid]);
    PlayerTextDrawHide(playerid, TD_ThBar[playerid]);
    PlayerTextDrawHide(playerid, TD_SlBar[playerid]);
    PlayerTextDrawHide(playerid, TD_StBar[playerid]);
}

forward OnHUDUpdate();
public OnHUDUpdate()
{
    new str[128];
    new hour, minute;
    gettime(hour, minute);
    format(str, sizeof(str), "%02d:%02d", hour, minute);
    TextDrawSetString(TD_Clock, str);

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (!IsPlayerConnected(i)) continue;
        if (!PlayerInfo[i][pIsLogged] || !PlayerInfo[i][pIsSpawned]) continue;

        /* Update HP bar - change width and color */
        GetPlayerHealth(i, PlayerInfo[i][pHealth]);
        new Float:hpw = GetBarWidth(PlayerInfo[i][pHealth], 100.0);
        PlayerTextDrawTextSize(i, TD_HpBar[i], BAR_X + hpw, 0.0);
        PlayerTextDrawBoxColor(i, TD_HpBar[i], GetBarColor(PlayerInfo[i][pHealth]));
        PlayerTextDrawShow(i, TD_HpBar[i]);

        /* Update Armor bar */
        GetPlayerArmour(i, PlayerInfo[i][pArmor]);
        new Float:arw = GetBarWidth(PlayerInfo[i][pArmor], 100.0);
        PlayerTextDrawTextSize(i, TD_ArBar[i], BAR_X + arw, 0.0);
        PlayerTextDrawShow(i, TD_ArBar[i]);

        /* Update Hunger bar */
        new Float:hgw = GetBarWidth(PlayerInfo[i][pHunger], 100.0);
        PlayerTextDrawTextSize(i, TD_HgBar[i], BAR_X + hgw, 0.0);
        PlayerTextDrawBoxColor(i, TD_HgBar[i], GetBarColor(PlayerInfo[i][pHunger]));
        PlayerTextDrawShow(i, TD_HgBar[i]);

        /* Update Thirst bar */
        new Float:thw = GetBarWidth(PlayerInfo[i][pThirst], 100.0);
        PlayerTextDrawTextSize(i, TD_ThBar[i], BAR_X + thw, 0.0);
        PlayerTextDrawBoxColor(i, TD_ThBar[i], GetBarColor(PlayerInfo[i][pThirst]));
        PlayerTextDrawShow(i, TD_ThBar[i]);

        /* Update Sleep bar */
        new Float:slw = GetBarWidth(PlayerInfo[i][pSleep], 100.0);
        PlayerTextDrawTextSize(i, TD_SlBar[i], BAR_X + slw, 0.0);
        PlayerTextDrawBoxColor(i, TD_SlBar[i], GetBarColor(PlayerInfo[i][pSleep]));
        PlayerTextDrawShow(i, TD_SlBar[i]);

        /* Update Stamina bar */
        new Float:stw = GetBarWidth(PlayerInfo[i][pStamina], 100.0);
        PlayerTextDrawTextSize(i, TD_StBar[i], BAR_X + stw, 0.0);
        PlayerTextDrawBoxColor(i, TD_StBar[i], GetBarColor(PlayerInfo[i][pStamina]));
        PlayerTextDrawShow(i, TD_StBar[i]);

        /* Update cash */
        new _sf_h1[64]; format(_sf_h1, sizeof(_sf_h1), "~g~~h~$%d", PlayerInfo[i][pCash]);
        TextDrawSetString(TD_Cash, _sf_h1);

        /* Update bank */
        new _sf_h2[64]; format(_sf_h2, sizeof(_sf_h2), "~b~Bank: $%d", PlayerInfo[i][pBank]);
        TextDrawSetString(TD_Bank, _sf_h2);

        /* Update level */
        new _sf_h3[64]; format(_sf_h3, sizeof(_sf_h3), "~w~Lvl %d (Exp:%d)", PlayerInfo[i][pLevel], PlayerInfo[i][pExp]);
        TextDrawSetString(TD_Level, _sf_h3);

        /* Update job */
        new _sf_h4[64];
        new jn[32];
        jn[0] = EOS;
        if (PlayerInfo[i][pJob] >= 0 && PlayerInfo[i][pJob] < sizeof(gJobNames))
            strcat(jn, gJobNames[PlayerInfo[i][pJob]], 32);
        else
            strcat(jn, "Unknown", 32);
        format(_sf_h4, sizeof(_sf_h4), "~w~Job: %s", jn);
        TextDrawSetString(TD_Job, _sf_h4);

        /* Update phone */
        new _sf_h5[64];
        if (PlayerInfo[i][pPhone] > 0)
            format(_sf_h5, sizeof(_sf_h5), "~w~HP: %d ~g~$%d", PlayerInfo[i][pPhone], PlayerInfo[i][pPhoneCredit]);
        else
            _sf_h5 = "~r~HP: -";
        TextDrawSetString(TD_Phone, _sf_h5);

        UpdateSpeedo(i);
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
    CreatePhoneTextDraws();
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

        case 1100: /* GPS Navigation */
        {
            if (!response) return 1;
            new Float:gx, Float:gy, Float:gz;
            switch (listitem)
            {
                case 0: { gx = 1480.91; gy = -1771.21; gz = 18.79; }
                case 1: { gx = 2316.00; gy = -7.50; gz = 26.74; }
                case 2: { gx = 1174.20; gy = -1324.30; gz = 14.10; }
                case 3: { gx = 1554.50; gy = -1675.50; gz = 16.20; }
                case 4: { gx = 1944.40; gy = -1773.70; gz = 13.40; }
                case 5: { gx = 1751.0; gy = -1862.0; gz = 13.5; }
                case 6: { gx = 1368.00; gy = -1279.50; gz = 13.50; }
            }
            SetPlayerCheckpoint(playerid, gx, gy, gz, 5.0);
            SendMsg(playerid, COLOR_GREEN, "GPS aktif! Ikuti checkpoint merah.");
            return 1;
        }

        case 1101: /* Menu */
        {
            if (!response) return 1;
            switch (listitem)
            {
                case 0: cmd_stats(playerid, "");
                case 1: cmd_help(playerid, "");
                case 2: cmd_kerja(playerid, "");
                case 3: cmd_dokumen(playerid, "");
                case 4: cmd_hp(playerid, "");
                case 5: cmd_bank(playerid, "");
                case 6: cmd_gps(playerid, "");
                case 7: cmd_ahelp(playerid, "");
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
    CreateSpeedo(playerid);
    CreatePlayerPhoneIcons(playerid);
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
    ShowStatsCard(playerid);
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
CMD:ktp(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (!PlayerInfo[playerid][pKTP]) return SendMsg(playerid, COLOR_RED, "Anda belum punya KTP. /urusdokumen di Balai Kota."), 1;
    ShowKTPCard(playerid);
    return 1;
}

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
    /* Show modern smartphone UI */
    ShowPhoneUI(playerid);
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
 *  HOUSE SYSTEM
 * =====================================================================*/
CMD:buyhouse(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    for (new i = 0; i < MAX_HOUSES; i++)
    {
        if (!HouseInfo[i][hExists]) continue;
        if (GetPlayerDistanceFromPoint(playerid, HouseInfo[i][hX], HouseInfo[i][hY], HouseInfo[i][hZ]) > 3.0) continue;
        if (HouseInfo[i][hOwner][0] != EOS) return SendMsg(playerid, COLOR_RED, "Rumah ini sudah dimiliki."), 1;
        if (PlayerInfo[playerid][pCash] < HouseInfo[i][hPrice]) return SendMsg(playerid, COLOR_RED, "Uang tidak cukup."), 1;
        PlayerInfo[playerid][pCash] -= HouseInfo[i][hPrice];
        HouseInfo[i][hOwner][0] = EOS;
        strcat(HouseInfo[i][hOwner], PlayerInfo[playerid][pName], MAX_PLAYER_NAME);
        new query[256];
        mysql_format(gSQL, query, sizeof(query), "UPDATE `houses` SET `owner`='%e' WHERE `id`=%d", HouseInfo[i][hOwner], HouseInfo[i][hID]);
        mysql_tquery(gSQL, query);
        SendFmt(playerid, COLOR_GREEN, "Anda membeli rumah ID %d seharga $%d!", i, HouseInfo[i][hPrice]);
        return 1;
    }
    SendMsg(playerid, COLOR_YELLOW, "Anda tidak dekat rumah manapun.");
    return 1;
}

CMD:sellhouse(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    for (new i = 0; i < MAX_HOUSES; i++)
    {
        if (!HouseInfo[i][hExists]) continue;
        if (strcmp(HouseInfo[i][hOwner], PlayerInfo[playerid][pName]) != 0) continue;
        new refund = HouseInfo[i][hPrice] / 2;
        PlayerInfo[playerid][pCash] += refund;
        HouseInfo[i][hOwner][0] = EOS;
        new query[128];
        mysql_format(gSQL, query, sizeof(query), "UPDATE `houses` SET `owner`='' WHERE `id`=%d", HouseInfo[i][hID]);
        mysql_tquery(gSQL, query);
        SendFmt(playerid, COLOR_GREEN, "Anda menjual rumah ID %d seharga $%d.", i, refund);
        return 1;
    }
    SendMsg(playerid, COLOR_RED, "Anda tidak punya rumah.");
    return 1;
}

CMD:enterhouse(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    for (new i = 0; i < MAX_HOUSES; i++)
    {
        if (!HouseInfo[i][hExists]) continue;
        if (GetPlayerDistanceFromPoint(playerid, HouseInfo[i][hX], HouseInfo[i][hY], HouseInfo[i][hZ]) > 3.0) continue;
        if (HouseInfo[i][hLocked] && strcmp(HouseInfo[i][hOwner], PlayerInfo[playerid][pName]) != 0)
            return SendMsg(playerid, COLOR_RED, "Rumah terkunci."), 1;
        SetPlayerPos(playerid, 2324.50, -1144.60, 1050.70);
        SetPlayerInterior(playerid, 12);
        PlayerInfo[playerid][pInHouse] = i;
        SendMsg(playerid, COLOR_GREEN, "Anda masuk ke rumah.");
        return 1;
    }
    SendMsg(playerid, COLOR_YELLOW, "Anda tidak dekat rumah.");
    return 1;
}

CMD:exithouse(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pInHouse] == -1) return SendMsg(playerid, COLOR_RED, "Anda tidak di dalam rumah."), 1;
    new i = PlayerInfo[playerid][pInHouse];
    SetPlayerPos(playerid, HouseInfo[i][hX], HouseInfo[i][hY], HouseInfo[i][hZ]);
    SetPlayerInterior(playerid, 0);
    PlayerInfo[playerid][pInHouse] = -1;
    SendMsg(playerid, COLOR_GREEN, "Anda keluar dari rumah.");
    return 1;
}

CMD:lockhouse(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    for (new i = 0; i < MAX_HOUSES; i++)
    {
        if (!HouseInfo[i][hExists]) continue;
        if (strcmp(HouseInfo[i][hOwner], PlayerInfo[playerid][pName]) != 0) continue;
        HouseInfo[i][hLocked] = !HouseInfo[i][hLocked];
        if (HouseInfo[i][hLocked]) SendMsg(playerid, COLOR_GREEN, "Rumah dikunci.");
        else SendMsg(playerid, COLOR_GREEN, "Rumah dibuka.");
        return 1;
    }
    SendMsg(playerid, COLOR_RED, "Anda tidak punya rumah.");
    return 1;
}

/* =====================================================================
 *  BUSINESS SYSTEM
 * =====================================================================*/
CMD:buybiz(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    for (new i = 0; i < MAX_BUSINESSES; i++)
    {
        if (!BizInfo[i][bExists]) continue;
        if (GetPlayerDistanceFromPoint(playerid, BizInfo[i][bX], BizInfo[i][bY], BizInfo[i][bZ]) > 3.0) continue;
        if (BizInfo[i][bOwner][0] != EOS) return SendMsg(playerid, COLOR_RED, "Bisnis sudah dimiliki."), 1;
        if (PlayerInfo[playerid][pCash] < BizInfo[i][bPrice]) return SendMsg(playerid, COLOR_RED, "Uang tidak cukup."), 1;
        PlayerInfo[playerid][pCash] -= BizInfo[i][bPrice];
        BizInfo[i][bOwner][0] = EOS;
        strcat(BizInfo[i][bOwner], PlayerInfo[playerid][pName], MAX_PLAYER_NAME);
        new query[256];
        mysql_format(gSQL, query, sizeof(query), "UPDATE `businesses` SET `owner`='%e' WHERE `id`=%d", BizInfo[i][bOwner], BizInfo[i][bID]);
        mysql_tquery(gSQL, query);
        SendFmt(playerid, COLOR_GREEN, "Anda membeli bisnis ID %d seharga $%d!", i, BizInfo[i][bPrice]);
        return 1;
    }
    SendMsg(playerid, COLOR_YELLOW, "Anda tidak dekat bisnis.");
    return 1;
}

CMD:sellbiz(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    for (new i = 0; i < MAX_BUSINESSES; i++)
    {
        if (!BizInfo[i][bExists]) continue;
        if (strcmp(BizInfo[i][bOwner], PlayerInfo[playerid][pName]) != 0) continue;
        new refund = BizInfo[i][bPrice] / 2;
        PlayerInfo[playerid][pCash] += refund;
        BizInfo[i][bOwner][0] = EOS;
        new query[128];
        mysql_format(gSQL, query, sizeof(query), "UPDATE `businesses` SET `owner`='' WHERE `id`=%d", BizInfo[i][bID]);
        mysql_tquery(gSQL, query);
        SendFmt(playerid, COLOR_GREEN, "Anda menjual bisnis seharga $%d.", refund);
        return 1;
    }
    SendMsg(playerid, COLOR_RED, "Anda tidak punya bisnis.");
    return 1;
}

CMD:bizmenu(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    for (new i = 0; i < MAX_BUSINESSES; i++)
    {
        if (!BizInfo[i][bExists]) continue;
        if (strcmp(BizInfo[i][bOwner], PlayerInfo[playerid][pName]) != 0) continue;
        new str[256];
        new _sf_bm[256];
        format(_sf_bm, sizeof(_sf_bm), "{FFFFFF}Bisnis ID: %d\nHarga: $%d\nPemilik: %s\n\n1. Kunci/Buka\n2. Jual Bisnis", i, BizInfo[i][bPrice], BizInfo[i][bOwner]);
        strcat(str, _sf_bm, sizeof(str));
        ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "{00FF00}Bisnis Menu", str, "Tutup", "");
        return 1;
    }
    SendMsg(playerid, COLOR_RED, "Anda tidak punya bisnis.");
    return 1;
}

/* =====================================================================
 *  VEHICLE OWNERSHIP SYSTEM
 * =====================================================================*/
CMD:buycar(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new model, color1, color2;
    if (sscanf(params, "ddd", model, color1, color2))
    {
        SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /buycar [model] [warna1] [warna2]");
        SendMsg(playerid, COLOR_YELLOW, "Harga: model x 1000. Contoh: /buycar 411 0 0 (Infernus)");
        return 1;
    }
    if (model < 400 || model > 611) return SendMsg(playerid, COLOR_RED, "Model 400-611."), 1;
    new price = model * 1000;
    if (PlayerInfo[playerid][pCash] < price) return SendMsg(playerid, COLOR_RED, "Uang tidak cukup."), 1;
    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);
    x += 3.0 * floatsin(-a, degrees);
    y += 3.0 * floatcos(-a, degrees);
    new vid = CreateVehicle(model, x, y, z, a, color1, color2, 600);
    new slot = -1;
    for (new i = 0; i < MAX_PVEHICLES; i++)
    {
        if (!PVehInfo[i][pvExists]) { slot = i; break; }
    }
    if (slot == -1) return DestroyVehicle(vid), SendMsg(playerid, COLOR_RED, "Slot kendaraan penuh."), 1;
    PlayerInfo[playerid][pCash] -= price;
    PVehInfo[slot][pvExists] = 1;
    PVehInfo[slot][pvModel] = model;
    PVehInfo[slot][pvX] = x; PVehInfo[slot][pvY] = y; PVehInfo[slot][pvZ] = z; PVehInfo[slot][pvA] = a;
    PVehInfo[slot][pvColor1] = color1; PVehInfo[slot][pvColor2] = color2;
    PVehInfo[slot][pvOwner][0] = EOS;
    strcat(PVehInfo[slot][pvOwner], PlayerInfo[playerid][pName], MAX_PLAYER_NAME);
    PVehInfo[slot][pvFuel] = 50.0;
    PVehInfo[slot][pvFuelType] = 0;
    PVehInfo[slot][pvLocked] = 0;
    PVehInfo[slot][pvVehicleID] = vid;
    SendFmt(playerid, COLOR_GREEN, "Anda membeli kendaraan model %d seharga $%d! ID: %d", model, price, slot);
    return 1;
}

CMD:lockcar(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new vid = GetPlayerVehicleID(playerid);
    if (vid == INVALID_VEHICLE_ID)
    {
        new Float:vx, Float:vy, Float:vz;
        for (new i = 0; i < MAX_PVEHICLES; i++)
        {
            if (!PVehInfo[i][pvExists]) continue;
            if (strcmp(PVehInfo[i][pvOwner], PlayerInfo[playerid][pName]) != 0) continue;
            GetVehiclePos(PVehInfo[i][pvVehicleID], vx, vy, vz);
            if (GetPlayerDistanceFromPoint(playerid, vx, vy, vz) < 5.0)
            {
                PVehInfo[i][pvLocked] = !PVehInfo[i][pvLocked];
                if (PVehInfo[i][pvLocked])
                {
                    SetVehicleParamsEx(PVehInfo[i][pvVehicleID], 0, 0, 0, 1, 0, 0, 0);
                    SendMsg(playerid, COLOR_GREEN, "Mobil dikunci.");
                }
                else
                {
                    SetVehicleParamsEx(PVehInfo[i][pvVehicleID], 0, 0, 0, 0, 0, 0, 0);
                    SendMsg(playerid, COLOR_GREEN, "Mobil dibuka.");
                }
                return 1;
            }
        }
        SendMsg(playerid, COLOR_RED, "Anda tidak dekat kendaraan Anda.");
        return 1;
    }
    for (new i = 0; i < MAX_PVEHICLES; i++)
    {
        if (!PVehInfo[i][pvExists]) continue;
        if (PVehInfo[i][pvVehicleID] != vid) continue;
        if (strcmp(PVehInfo[i][pvOwner], PlayerInfo[playerid][pName]) != 0) return SendMsg(playerid, COLOR_RED, "Ini bukan mobil Anda."), 1;
        PVehInfo[i][pvLocked] = !PVehInfo[i][pvLocked];
        if (PVehInfo[i][pvLocked]) SendMsg(playerid, COLOR_GREEN, "Mobil dikunci.");
        else SendMsg(playerid, COLOR_GREEN, "Mobil dibuka.");
        return 1;
    }
    SendMsg(playerid, COLOR_RED, "Kendaraan tidak ditemukan.");
    return 1;
}

CMD:park(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new vid = GetPlayerVehicleID(playerid);
    if (vid == INVALID_VEHICLE_ID) return SendMsg(playerid, COLOR_RED, "Anda tidak di kendaraan."), 1;
    for (new i = 0; i < MAX_PVEHICLES; i++)
    {
        if (!PVehInfo[i][pvExists]) continue;
        if (PVehInfo[i][pvVehicleID] != vid) continue;
        if (strcmp(PVehInfo[i][pvOwner], PlayerInfo[playerid][pName]) != 0) return SendMsg(playerid, COLOR_RED, "Ini bukan mobil Anda."), 1;
        new Float:x, Float:y, Float:z, Float:a;
        GetVehiclePos(vid, x, y, z);
        GetVehicleZAngle(vid, a);
        PVehInfo[i][pvX] = x; PVehInfo[i][pvY] = y; PVehInfo[i][pvZ] = z; PVehInfo[i][pvA] = a;
        SendMsg(playerid, COLOR_GREEN, "Kendaraan diparkir di sini.");
        return 1;
    }
    SendMsg(playerid, COLOR_RED, "Kendaraan tidak ditemukan.");
    return 1;
}

CMD:engine(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new vid = GetPlayerVehicleID(playerid);
    if (vid == INVALID_VEHICLE_ID) return SendMsg(playerid, COLOR_RED, "Anda tidak di kendaraan."), 1;
    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendMsg(playerid, COLOR_RED, "Anda bukan pengemudi."), 1;
    new engine, lights, alarm, doors, bonnet, boot, objective;
    GetVehicleParamsEx(vid, engine, lights, alarm, doors, bonnet, boot, objective);
    SetVehicleParamsEx(vid, !engine, lights, alarm, doors, bonnet, boot, objective);
    if (!engine) SendMsg(playerid, COLOR_GREEN, "Mesin dinyalakan.");
    else SendMsg(playerid, COLOR_GREEN, "Mesin dimatikan.");
    return 1;
}

CMD:mycars(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new str[512];
    str[0] = EOS;
    new count = 0;
    for (new i = 0; i < MAX_PVEHICLES; i++)
    {
        if (!PVehInfo[i][pvExists]) continue;
        if (strcmp(PVehInfo[i][pvOwner], PlayerInfo[playerid][pName]) != 0) continue;
        new line[128];
        new _sf_mc[128];
        format(_sf_mc, sizeof(_sf_mc), "ID: %d | Model: %d | Bensin: %.1fL\n", i, PVehInfo[i][pvModel], PVehInfo[i][pvFuel]);
        strcat(line, _sf_mc, sizeof(line));
        strcat(str, line, sizeof(str));
        count++;
    }
    if (count == 0) return SendMsg(playerid, COLOR_RED, "Anda tidak punya kendaraan."), 1;
    ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "{00FF00}Kendaraan Saya", str, "Tutup", "");
    return 1;
}

/* =====================================================================
 *  JOB MISSIONS (Trucker, Taxi, Mechanic)
 * =====================================================================*/
new gJobMission[MAX_PLAYERS];
new gJobTarget[MAX_PLAYERS];
new Float:gTruckerPoints[][3] = {
    {2776.0, -2435.5, 13.6},
    {2225.0, -1150.0, 25.7},
    {2500.0, -1700.0, 13.5},
    {1800.0, -1900.0, 13.5},
    {1400.0, -1700.0, 13.5}
};

CMD:mulaikerja(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pJob] == 0) return SendMsg(playerid, COLOR_RED, "Anda tidak punya pekerjaan. /kerja untuk memilih."), 1;
    if (gJobMission[playerid] > 0) return SendMsg(playerid, COLOR_YELLOW, "Anda sedang dalam misi."), 1;

    if (PlayerInfo[playerid][pJob] == 1) /* Trucker */
    {
        new dest = random(sizeof(gTruckerPoints));
        gJobMission[playerid] = 1;
        gJobTarget[playerid] = dest;
        SetPlayerCheckpoint(playerid, gTruckerPoints[dest][0], gTruckerPoints[dest][1], gTruckerPoints[dest][2], 5.0);
        SendMsg(playerid, COLOR_GREEN, "[TRUCKER] Antar barang ke checkpoint merah! Hadiah $3000.");
    }
    else if (PlayerInfo[playerid][pJob] == 2) /* Taxi */
    {
        gJobMission[playerid] = 2;
        new dest = random(sizeof(gTruckerPoints));
        gJobTarget[playerid] = dest;
        SetPlayerCheckpoint(playerid, gTruckerPoints[dest][0], gTruckerPoints[dest][1], gTruckerPoints[dest][2], 5.0);
        SendMsg(playerid, COLOR_GREEN, "[TAXI] Antar penumpang ke checkpoint! Hadiah $2000.");
    }
    else if (PlayerInfo[playerid][pJob] == 3) /* Mechanic */
    {
        gJobMission[playerid] = 3;
        SendMsg(playerid, COLOR_GREEN, "[MECHANIC] Cari kendaraan rusak dan /repair dekat kendaraan.");
    }
    ApplyJobSkin(playerid);
    return 1;
}

CMD:selesaikerja(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (gJobMission[playerid] == 0) return SendMsg(playerid, COLOR_RED, "Anda tidak dalam misi."), 1;
    DisablePlayerCheckpoint(playerid);
    new reward = 0;
    if (gJobMission[playerid] == 1) reward = 3000;
    else if (gJobMission[playerid] == 2) reward = 2000;
    else if (gJobMission[playerid] == 3) reward = 2500;
    PlayerInfo[playerid][pCash] += reward;
    PlayerInfo[playerid][pExp] += 2;
    gJobMission[playerid] = 0;
    RestoreOrigSkin(playerid);
    SendFmt(playerid, COLOR_GREEN, "Misi selesai! Anda dapat $%d dan +2 EXP.", reward);
    return 1;
}

CMD:repair(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pJob] != 3) return SendMsg(playerid, COLOR_RED, "Hanya mechanic."), 1;
    new vid = GetPlayerVehicleID(playerid);
    if (vid == INVALID_VEHICLE_ID)
    {
        new Float:vx, Float:vy, Float:vz;
        for (new v = 1; v < MAX_VEHICLES; v++)
        {
            if (GetVehicleModel(v) == 0) continue;
            GetVehiclePos(v, vx, vy, vz);
            if (GetPlayerDistanceFromPoint(playerid, vx, vy, vz) < 5.0)
            {
                SetVehicleHealth(v, 1000.0);
                PlayerInfo[playerid][pCash] += 500;
                SendMsg(playerid, COLOR_GREEN, "Kendaraan diperbaiki! +$500.");
                return 1;
            }
        }
        SendMsg(playerid, COLOR_RED, "Tidak ada kendaraan dekat Anda.");
        return 1;
    }
    SetVehicleHealth(vid, 1000.0);
    PlayerInfo[playerid][pCash] += 500;
    SendMsg(playerid, COLOR_GREEN, "Kendaraan diperbaiki! +$500.");
    return 1;
}

/* =====================================================================
 *  PHONE CONTACTS
 * =====================================================================*/
CMD:addcontact(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pPhone] == 0) return SendMsg(playerid, COLOR_RED, "Anda tidak punya HP."), 1;
    new name[MAX_PLAYER_NAME], number;
    if (sscanf(params, "sd", name, number))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /addcontact [nama] [nomor]"), 1;
    new query[256];
    mysql_format(gSQL, query, sizeof(query), "INSERT INTO `phone_contacts` (`owner`, `name`, `number`) VALUES ('%e', '%e', %d)", PlayerInfo[playerid][pName], name, number);
    mysql_tquery(gSQL, query);
    SendFmt(playerid, COLOR_GREEN, "Kontak %s (%d) ditambahkan.", name, number);
    return 1;
}

CMD:contacts(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pPhone] == 0) return SendMsg(playerid, COLOR_RED, "Anda tidak punya HP."), 1;
    SendMsg(playerid, COLOR_YELLOW, "Kontak tersimpan di database. Gunakan /sms [nomor] untuk SMS.");
    return 1;
}

/* =====================================================================
 *  GPS SYSTEM
 * =====================================================================*/
CMD:gps(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new str[512];
    str[0] = EOS;
    strcat(str, "{FFFFFF}Pilih tujuan GPS:\n", sizeof(str));
    strcat(str, "1. Balai Kota LS\n", sizeof(str));
    strcat(str, "2. Bank LS\n", sizeof(str));
    strcat(str, "3. Rumah Sakit LS\n", sizeof(str));
    strcat(str, "4. Polisi LS\n", sizeof(str));
    strcat(str, "5. SPBU terdekat\n", sizeof(str));
    strcat(str, "6. Toko 24/7\n", sizeof(str));
    strcat(str, "7. Ammunation\n", sizeof(str));
    ShowPlayerDialog(playerid, 1100, DIALOG_STYLE_LIST, "{00FF00}GPS Navigation", str, "Navigasi", "Batal");
    return 1;
}

/* =====================================================================
 *  SPEEDOMETER (TextDraw)
 * =====================================================================*/

stock CreateSpeedo(playerid)
{
    /* Modern speedometer - bottom right, FiveM style */
    TD_Speedo[playerid] = CreatePlayerTextDraw(playerid, 530.0, 400.0, "_");
    PlayerTextDrawLetterSize(playerid, TD_Speedo[playerid], 0.25, 1.0);
    PlayerTextDrawColor(playerid, TD_Speedo[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, TD_Speedo[playerid], 0);
    PlayerTextDrawSetOutline(playerid, TD_Speedo[playerid], 1);
    PlayerTextDrawAlignment(playerid, TD_Speedo[playerid], 3);
}

stock UpdateSpeedo(playerid)
{
    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
    {
        PlayerTextDrawHide(playerid, TD_Speedo[playerid]);
        return;
    }
    new vid = GetPlayerVehicleID(playerid);
    new Float:vx, Float:vy, Float:vz;
    GetVehicleVelocity(vid, vx, vy, vz);
    new speed = floatround(floatsqroot(vx*vx + vy*vy + vz*vz) * 200.0);

    /* Color based on speed: green=normal, yellow=fast, red=very fast */
    new speed_color[8];
    speed_color[0] = EOS;
    if (speed < 60) strcat(speed_color, "~g~", sizeof(speed_color));
    else if (speed < 120) strcat(speed_color, "~y~", sizeof(speed_color));
    else strcat(speed_color, "~r~", sizeof(speed_color));

    new _sf_sp[128];
    format(_sf_sp, sizeof(_sf_sp), "%s%d ~w~km/h", speed_color, speed);
    PlayerTextDrawSetString(playerid, TD_Speedo[playerid], _sf_sp);
    PlayerTextDrawShow(playerid, TD_Speedo[playerid]);
}

/* =====================================================================
 *  ATM SYSTEM (Transfer)
 * =====================================================================*/
CMD:transfer(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new targetid, amount;
    if (sscanf(params, "ud", targetid, amount))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /transfer [playerid] [jumlah]"), 1;
    if (!IsPlayerConnected(targetid)) return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    if (PlayerInfo[playerid][pBank] < amount) return SendMsg(playerid, COLOR_RED, "Saldo bank tidak cukup."), 1;
    PlayerInfo[playerid][pBank] -= amount;
    PlayerInfo[targetid][pBank] += amount;
    SendFmt(playerid, COLOR_GREEN, "Anda transfer $%d ke %s.", amount, PlayerInfo[targetid][pName]);
    SendFmt(targetid, COLOR_GREEN, "Anda menerima $%d dari %s.", amount, PlayerInfo[playerid][pName]);
    return 1;
}

/* =====================================================================
 *  POLICE DUTY SYSTEM
 * =====================================================================*/
CMD:duty(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pFaction] != 1) return SendMsg(playerid, COLOR_RED, "Hanya polisi (SAPD)."), 1;
    PlayerInfo[playerid][pOnDuty] = !PlayerInfo[playerid][pOnDuty];
    if (PlayerInfo[playerid][pOnDuty])
    {
        SetPlayerSkin(playerid, 280);
        SetPlayerHealth(playerid, 100.0);
        SetPlayerArmour(playerid, 100.0);
        GivePlayerWeapon(playerid, 3, 1);
        GivePlayerWeapon(playerid, 24, 100);
        GivePlayerWeapon(playerid, 25, 50);
        SendMsg(playerid, COLOR_GREEN, "[DUTY] Anda masuk dinas. Skin, armor, dan senjata diberikan.");
    }
    else
    {
        SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
        SetPlayerArmour(playerid, 0.0);
        ResetPlayerWeapons(playerid);
        SendMsg(playerid, COLOR_YELLOW, "[DUTY] Anda keluar dinas.");
    }
    return 1;
}

CMD:ticket(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pFaction] != 1 || !PlayerInfo[playerid][pOnDuty])
        return SendMsg(playerid, COLOR_RED, "Hanya polisi on-duty."), 1;
    new targetid, amount, reason[64];
    if (sscanf(params, "uds[64]", targetid, amount, reason))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /ticket [playerid] [jumlah] [alasan]"), 1;
    if (!IsPlayerConnected(targetid)) return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    if (PlayerInfo[targetid][pCash] < amount) return SendMsg(playerid, COLOR_RED, "Pemain tidak punya uang."), 1;
    PlayerInfo[targetid][pCash] -= amount;
    SendFmt(targetid, COLOR_RED, "Anda didenda $%d oleh polisi. Alasan: %s", amount, reason);
    SendFmt(playerid, COLOR_GREEN, "Denda $%d diberikan ke %s.", amount, PlayerInfo[targetid][pName]);
    return 1;
}

CMD:cuff(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pFaction] != 1 || !PlayerInfo[playerid][pOnDuty])
        return SendMsg(playerid, COLOR_RED, "Hanya polisi on-duty."), 1;
    new targetid;
    if (sscanf(params, "u", targetid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /cuff [playerid]"), 1;
    if (!IsPlayerConnected(targetid)) return SendMsg(playerid, COLOR_RED, "Pemain tidak ditemukan."), 1;
    if (GetPlayerDistanceFromPoint(playerid, PlayerInfo[targetid][pPosX], PlayerInfo[targetid][pPosY], PlayerInfo[targetid][pPosZ]) > 5.0)
        return SendMsg(playerid, COLOR_RED, "Pemain terlalu jauh."), 1;
    TogglePlayerControllable(targetid, false);
    SendFmt(targetid, COLOR_RED, "Anda diborgol oleh %s!", PlayerInfo[playerid][pName]);
    SendFmt(playerid, COLOR_GREEN, "Anda memborgol %s.", PlayerInfo[targetid][pName]);
    return 1;
}

CMD:uncuff(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pFaction] != 1 || !PlayerInfo[playerid][pOnDuty])
        return SendMsg(playerid, COLOR_RED, "Hanya polisi on-duty."), 1;
    new targetid;
    if (sscanf(params, "u", targetid))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /uncuff [playerid]"), 1;
    TogglePlayerControllable(targetid, true);
    SendFmt(targetid, COLOR_GREEN, "Borgol Anda dilepas oleh %s.", PlayerInfo[playerid][pName]);
    return 1;
}

/* =====================================================================
 *  GANG SYSTEM
 * =====================================================================*/
CMD:creategang(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pLevel] < 3) return SendMsg(playerid, COLOR_RED, "Butuh level 3+."), 1;
    new gangname[48];
    if (sscanf(params, "s[48]", gangname))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /creategang [nama]"), 1;
    new query[256];
    mysql_format(gSQL, query, sizeof(query), "INSERT INTO `gangs` (`name`, `leader`) VALUES ('%e', '%e')", gangname, PlayerInfo[playerid][pName]);
    mysql_tquery(gSQL, query);
    SendFmt(playerid, COLOR_GREEN, "Gang '%s' dibuat! Anda adalah leadernya.", gangname);
    return 1;
}

/* =====================================================================
 *  MONEY WASH (Pencucian Uang)
 * =====================================================================*/
CMD:washmoney(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (GetPlayerDistanceFromPoint(playerid, -427.38, -392.38, 16.58) > 10.0)
        return SendMsg(playerid, COLOR_RED, "Anda harus di tempat pencucian uang."), 1;
    new amount;
    if (sscanf(params, "d", amount))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /washmoney [jumlah]"), 1;
    if (amount < 1000) return SendMsg(playerid, COLOR_RED, "Minimal $1000."), 1;
    /* 80% return (20% fee) */
    new washed = amount * 80 / 100;
    PlayerInfo[playerid][pCash] += washed;
    SendFmt(playerid, COLOR_GREEN, "Uang dicuci: $%d (fee 20 persen). Anda dapat $%d.", amount, washed);
    return 1;
}

/* =====================================================================
 *  FISHING SYSTEM
 * =====================================================================*/
CMD:fish(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (GetPlayerState(playerid) == PLAYER_STATE_DRIVER) return SendMsg(playerid, COLOR_RED, "Turun dari kendaraan dulu."), 1;
    /* Must be near water - simplified check */
    new Float:z;
    GetPlayerPos(playerid, PlayerInfo[playerid][pPosX], PlayerInfo[playerid][pPosY], z);
    if (z > 20.0) return SendMsg(playerid, COLOR_RED, "Anda harus dekat air."), 1;
    ApplyAnimation(playerid, "SAMP", "fishing", 4.1, 0, 1, 1, 1, 0, 1);
    SetTimerEx("OnFishComplete", 10000, false, "i", playerid);
    SendMsg(playerid, COLOR_GREEN, "Memancing... tunggu 10 detik.");
    return 1;
}

forward OnFishComplete(playerid);
public OnFishComplete(playerid)
{
    if (!IsPlayerConnected(playerid)) return 1;
    ClearAnimations(playerid);
    new fish_type = random(5);
    new fish_names[][] = {"Lele", "Nila", "Gurame", "Mas", "Tuna"};
    new price = 500 + random(2000);
    PlayerInfo[playerid][pCash] += price;
    SendFmt(playerid, COLOR_GREEN, "Anda mendapat ikan %s! Dijual $%d.", fish_names[fish_type], price);
    return 1;
}

/* =====================================================================
 *  RENT VEHICLE
 * =====================================================================*/
CMD:rentcar(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (GetPlayerDistanceFromPoint(playerid, 545.75, -1293.42, 17.24) > 10.0)
        return SendMsg(playerid, COLOR_RED, "Anda harus di rental kendaraan."), 1;
    if (PlayerInfo[playerid][pCash] < 5000) return SendMsg(playerid, COLOR_RED, "Sewa $5000. Uang tidak cukup."), 1;
    PlayerInfo[playerid][pCash] -= 5000;
    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);
    new vid = CreateVehicle(462, x + 2.0, y, z, a, 1, 1, 3600);
    PutPlayerInVehicle(playerid, vid, 0);
    SendMsg(playerid, COLOR_GREEN, "Anda menyewa kendaraan selama 1 jam ($5000).");
    return 1;
}

/* =====================================================================
 *  CLOTHING SHOP
 * =====================================================================*/
CMD:buyclothes(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (GetPlayerInterior(playerid) != 5 && GetPlayerInterior(playerid) != 17)
        return SendMsg(playerid, COLOR_RED, "Anda harus di toko baju."), 1;
    if (PlayerInfo[playerid][pCash] < 1000) return SendMsg(playerid, COLOR_RED, "Baju $1000. Uang tidak cukup."), 1;
    PlayerInfo[playerid][pCash] -= 1000;
    new skin = 1 + random(299);
    if (skin == 0) skin = 230;
    PlayerInfo[playerid][pSkin] = skin;
    SetPlayerSkin(playerid, skin);
    SendFmt(playerid, COLOR_GREEN, "Anda membeli baju baru! Skin: %d", skin);
    return 1;
}

/* =====================================================================
 *  EAT AT RESTAURANT
 * =====================================================================*/
CMD:makanresto(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (GetPlayerInterior(playerid) != 5 && GetPlayerInterior(playerid) != 10 && GetPlayerInterior(playerid) != 11)
        return SendMsg(playerid, COLOR_RED, "Anda harus di restoran."), 1;
    if (PlayerInfo[playerid][pCash] < 2000) return SendMsg(playerid, COLOR_RED, "Makan $2000. Uang tidak cukup."), 1;
    PlayerInfo[playerid][pCash] -= 2000;
    PlayerInfo[playerid][pHunger] = 100.0;
    PlayerInfo[playerid][pThirst] = 100.0;
    PlayerInfo[playerid][pHealth] = 100.0;
    SetPlayerHealth(playerid, 100.0);
    SendMsg(playerid, COLOR_GREEN, "Anda makan di restoran. Hunger, Thirst, Health penuh!");
    return 1;
}

/* =====================================================================
 *  DRUG SYSTEM
 * =====================================================================*/
CMD:usedrug(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pCash] < 500) return SendMsg(playerid, COLOR_RED, "Butuh $500."), 1;
    PlayerInfo[playerid][pCash] -= 500;
    SetPlayerHealth(playerid, 100.0);
    SetPlayerArmour(playerid, 50.0);
    SetPlayerDrunkLevel(playerid, 3000);
    SetTimerEx("OnDrugWearOff", 30000, false, "i", playerid);
    SendMsg(playerid, COLOR_GREEN, "Anda menggunakan obat. Health + Armor + Drunk.");
    return 1;
}

forward OnDrugWearOff(playerid);
public OnDrugWearOff(playerid)
{
    if (!IsPlayerConnected(playerid)) return 1;
    SetPlayerDrunkLevel(playerid, 0);
    SendMsg(playerid, COLOR_YELLOW, "Efek obat hilang.");
    return 1;
}

/* =====================================================================
 *  ADMIN TELEPORT
 * =====================================================================*/
CMD:tp(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 2) return SendMsg(playerid, COLOR_RED, "Butuh admin level 2."), 1;
    new Float:x, Float:y, Float:z;
    if (sscanf(params, "fff", x, y, z))
        return SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /tp [x] [y] [z]"), 1;
    SetPlayerPos(playerid, x, y, z);
    SendMsg(playerid, COLOR_GREEN, "Teleport.");
    return 1;
}

CMD:tppos(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    if (PlayerInfo[playerid][pAdminLevel] < 2) return 1;
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    SendFmt(playerid, COLOR_YELLOW, "Posisi Anda: X=%.2f Y=%.2f Z=%.2f", x, y, z);
    return 1;
}

/* =====================================================================
 *  MODERN SMARTPHONE TEXTDRAW SYSTEM (with 3D Model Icons)
 * =====================================================================*/

new Text:PhoneBg;
new Text:PhoneScreen;
new Text:PhoneNotch;
new Text:PhoneStatusBar;
new Text:PhoneTime;
new Text:PhoneBattery;
new Text:PhoneSignal;
new Text:PhoneHeader;
new Text:PhoneDockBg;
new Text:PhoneHomeBtn;
new Text:PhoneAppBg[6];
new Text:PhoneAppLabel[6];
new PlayerText:PhoneAppIcon[MAX_PLAYERS][6];
new bool:gPhoneOpen[MAX_PLAYERS];

new PlayerText:KTP_Card[MAX_PLAYERS];
new PlayerText:KTP_Title[MAX_PLAYERS];
new PlayerText:KTP_Photo[MAX_PLAYERS];
new PlayerText:KTP_Name[MAX_PLAYERS];
new PlayerText:KTP_NIK[MAX_PLAYERS];
new PlayerText:KTP_Detail[MAX_PLAYERS];
new bool:gKTPOpen[MAX_PLAYERS];

new PlayerText:STAT_Card[MAX_PLAYERS];
new PlayerText:STAT_Title[MAX_PLAYERS];
new PlayerText:STAT_Line1[MAX_PLAYERS];
new PlayerText:STAT_Line2[MAX_PLAYERS];
new PlayerText:STAT_Line3[MAX_PLAYERS];
new PlayerText:STAT_Line4[MAX_PLAYERS];
new PlayerText:STAT_Line5[MAX_PLAYERS];
new bool:gStatOpen[MAX_PLAYERS];

#define ICON_BANK     1274
#define ICON_SMS      330
#define ICON_CALL     330
#define ICON_GPS      411
#define ICON_SHOP     2653
#define ICON_DOCS     1582

new Float:gAppPosX[6] = {265.0, 305.0, 345.0, 265.0, 305.0, 345.0};
new Float:gAppPosY[6] = {180.0, 180.0, 180.0, 235.0, 235.0, 235.0};
new gAppModels[6] = {ICON_BANK, ICON_SMS, ICON_CALL, ICON_GPS, ICON_SHOP, ICON_DOCS};

stock CreatePhoneTextDraws()
{
    PhoneBg = TextDrawCreate(255.0, 130.0, "_");
    TextDrawUseBox(PhoneBg, 1);
    TextDrawBoxColor(PhoneBg, 0x000000FF);
    TextDrawTextSize(PhoneBg, 385.0, 0.0);
    TextDrawLetterSize(PhoneBg, 0.5, 25.0);
    TextDrawSetShadow(PhoneBg, 0);

    PhoneScreen = TextDrawCreate(260.0, 135.0, "_");
    TextDrawUseBox(PhoneScreen, 1);
    TextDrawBoxColor(PhoneScreen, 0x004D40DD);
    TextDrawTextSize(PhoneScreen, 380.0, 0.0);
    TextDrawLetterSize(PhoneScreen, 0.5, 24.0);
    TextDrawSetShadow(PhoneScreen, 0);

    PhoneNotch = TextDrawCreate(305.0, 135.0, "_");
    TextDrawUseBox(PhoneNotch, 1);
    TextDrawBoxColor(PhoneNotch, 0x000000FF);
    TextDrawTextSize(PhoneNotch, 335.0, 0.0);
    TextDrawLetterSize(PhoneNotch, 0.5, 0.6);
    TextDrawSetShadow(PhoneNotch, 0);

    PhoneStatusBar = TextDrawCreate(260.0, 142.0, "_");
    TextDrawUseBox(PhoneStatusBar, 1);
    TextDrawBoxColor(PhoneStatusBar, 0x00695CFF);
    TextDrawTextSize(PhoneStatusBar, 380.0, 0.0);
    TextDrawLetterSize(PhoneStatusBar, 0.5, 0.8);
    TextDrawSetShadow(PhoneStatusBar, 0);

    PhoneTime = TextDrawCreate(265.0, 143.0, "00:00");
    TextDrawLetterSize(PhoneTime, 0.16, 0.65);
    TextDrawColor(PhoneTime, 0xFFFFFFFF);
    TextDrawSetShadow(PhoneTime, 0);

    PhoneBattery = TextDrawCreate(365.0, 144.0, "_");
    TextDrawUseBox(PhoneBattery, 1);
    TextDrawBoxColor(PhoneBattery, 0x4CAF50FF);
    TextDrawTextSize(PhoneBattery, 375.0, 0.0);
    TextDrawLetterSize(PhoneBattery, 0.3, 0.35);
    TextDrawSetShadow(PhoneBattery, 0);

    PhoneSignal = TextDrawCreate(350.0, 143.0, "~w~...");
    TextDrawLetterSize(PhoneSignal, 0.12, 0.6);
    TextDrawSetShadow(PhoneSignal, 0);

    PhoneHeader = TextDrawCreate(320.0, 155.0, "~w~~h~INFERNO Phone");
    TextDrawLetterSize(PhoneHeader, 0.18, 0.85);
    TextDrawSetShadow(PhoneHeader, 0);
    TextDrawAlignment(PhoneHeader, 2);

    new appNames[6][12] = {"Bank", "SMS", "Telepon", "GPS", "Toko", "Dokumen"};
    for (new i = 0; i < 6; i++)
    {
        PhoneAppBg[i] = TextDrawCreate(gAppPosX[i], gAppPosY[i], "_");
        TextDrawUseBox(PhoneAppBg[i], 1);
        TextDrawBoxColor(PhoneAppBg[i], 0x37474FFF);
        TextDrawTextSize(PhoneAppBg[i], gAppPosX[i] + 30.0, 0.0);
        TextDrawLetterSize(PhoneAppBg[i], 0.5, 2.2);
        TextDrawSetShadow(PhoneAppBg[i], 0);
        TextDrawSetSelectable(PhoneAppBg[i], 1);

        new Float:lblY = gAppPosY[i] + 18.0;
        PhoneAppLabel[i] = TextDrawCreate(gAppPosX[i] + 15.0, lblY, appNames[i]);
        TextDrawLetterSize(PhoneAppLabel[i], 0.11, 0.5);
        TextDrawColor(PhoneAppLabel[i], 0xB0BEC5FF);
        TextDrawSetShadow(PhoneAppLabel[i], 0);
        TextDrawAlignment(PhoneAppLabel[i], 2);
    }

    PhoneDockBg = TextDrawCreate(260.0, 295.0, "_");
    TextDrawUseBox(PhoneDockBg, 1);
    TextDrawBoxColor(PhoneDockBg, 0x003328FF);
    TextDrawTextSize(PhoneDockBg, 380.0, 0.0);
    TextDrawLetterSize(PhoneDockBg, 0.5, 2.5);
    TextDrawSetShadow(PhoneDockBg, 0);

    PhoneHomeBtn = TextDrawCreate(310.0, 305.0, "_");
    TextDrawUseBox(PhoneHomeBtn, 1);
    TextDrawBoxColor(PhoneHomeBtn, 0xB0BEC5FF);
    TextDrawTextSize(PhoneHomeBtn, 330.0, 0.0);
    TextDrawLetterSize(PhoneHomeBtn, 0.5, 1.2);
    TextDrawSetShadow(PhoneHomeBtn, 0);

    print("[InfernoRP] Phone with 3D model icons created.");
}

stock CreatePlayerPhoneIcons(playerid)
{
    for (new i = 0; i < 6; i++)
    {
        PhoneAppIcon[playerid][i] = CreatePlayerTextDraw(playerid, gAppPosX[i] + 2.0, gAppPosY[i] + 1.0, "_");
        PlayerTextDrawFont(playerid, PhoneAppIcon[playerid][i], 5);
        PlayerTextDrawColor(playerid, PhoneAppIcon[playerid][i], 0xFFFFFFFF);
        PlayerTextDrawBackgroundColor(playerid, PhoneAppIcon[playerid][i], 0x00000000);
        PlayerTextDrawTextSize(playerid, PhoneAppIcon[playerid][i], gAppPosX[i] + 28.0, gAppPosY[i] + 17.0);
        PlayerTextDrawSetPreviewModel(playerid, PhoneAppIcon[playerid][i], gAppModels[i]);
        if (i == 2)
            PlayerTextDrawSetPreviewRot(playerid, PhoneAppIcon[playerid][i], 0.0, 0.0, 90.0, 1.0);
        else if (i == 3)
            PlayerTextDrawSetPreviewRot(playerid, PhoneAppIcon[playerid][i], -15.0, 0.0, -45.0, 0.8);
        else
            PlayerTextDrawSetPreviewRot(playerid, PhoneAppIcon[playerid][i], -10.0, 0.0, 0.0, 1.0);
    }
}

stock ShowPhoneUI(playerid)
{
    if (gPhoneOpen[playerid]) return;
    if (PlayerInfo[playerid][pPhone] == 0) return;
    gPhoneOpen[playerid] = true;
    new hour, minute;
    new tstr[16];
    gettime(hour, minute);
    format(tstr, sizeof(tstr), "%02d:%02d", hour, minute);
    TextDrawSetString(PhoneTime, tstr);
    TextDrawShowForPlayer(playerid, PhoneBg);
    TextDrawShowForPlayer(playerid, PhoneScreen);
    TextDrawShowForPlayer(playerid, PhoneNotch);
    TextDrawShowForPlayer(playerid, PhoneStatusBar);
    TextDrawShowForPlayer(playerid, PhoneTime);
    TextDrawShowForPlayer(playerid, PhoneBattery);
    TextDrawShowForPlayer(playerid, PhoneSignal);
    TextDrawShowForPlayer(playerid, PhoneHeader);
    for (new i = 0; i < 6; i++)
    {
        TextDrawShowForPlayer(playerid, PhoneAppBg[i]);
        TextDrawShowForPlayer(playerid, PhoneAppLabel[i]);
        PlayerTextDrawShow(playerid, PhoneAppIcon[playerid][i]);
    }
    TextDrawShowForPlayer(playerid, PhoneDockBg);
    TextDrawShowForPlayer(playerid, PhoneHomeBtn);
    SelectTextDraw(playerid, 0x00897BAA);
    SendMsg(playerid, COLOR_YELLOW, "Klik icon app untuk menggunakan. Tekan ESC untuk tutup.");
}

stock HidePhoneUI(playerid)
{
    if (!gPhoneOpen[playerid]) return;
    gPhoneOpen[playerid] = false;
    CancelSelectTextDraw(playerid);
    TextDrawHideForPlayer(playerid, PhoneBg);
    TextDrawHideForPlayer(playerid, PhoneScreen);
    TextDrawHideForPlayer(playerid, PhoneNotch);
    TextDrawHideForPlayer(playerid, PhoneStatusBar);
    TextDrawHideForPlayer(playerid, PhoneTime);
    TextDrawHideForPlayer(playerid, PhoneBattery);
    TextDrawHideForPlayer(playerid, PhoneSignal);
    TextDrawHideForPlayer(playerid, PhoneHeader);
    for (new i = 0; i < 6; i++)
    {
        TextDrawHideForPlayer(playerid, PhoneAppBg[i]);
        TextDrawHideForPlayer(playerid, PhoneAppLabel[i]);
        PlayerTextDrawHide(playerid, PhoneAppIcon[playerid][i]);
    }
    TextDrawHideForPlayer(playerid, PhoneDockBg);
    TextDrawHideForPlayer(playerid, PhoneHomeBtn);
}

stock ShowKTPCard(playerid)
{
    if (gKTPOpen[playerid]) return;
    gKTPOpen[playerid] = true;
    KTP_Card[playerid] = CreatePlayerTextDraw(playerid, 200.0, 160.0, "_");
    PlayerTextDrawUseBox(playerid, KTP_Card[playerid], 1);
    PlayerTextDrawBoxColor(playerid, KTP_Card[playerid], 0xF5F5F5FF);
    PlayerTextDrawTextSize(playerid, KTP_Card[playerid], 440.0, 0.0);
    PlayerTextDrawLetterSize(playerid, KTP_Card[playerid], 0.5, 15.0);
    PlayerTextDrawSetShadow(playerid, KTP_Card[playerid], 0);
    KTP_Title[playerid] = CreatePlayerTextDraw(playerid, 200.0, 160.0, "~w~KARTU TANDA PENDUDUK");
    PlayerTextDrawUseBox(playerid, KTP_Title[playerid], 1);
    PlayerTextDrawBoxColor(playerid, KTP_Title[playerid], 0xD32F2FFF);
    PlayerTextDrawTextSize(playerid, KTP_Title[playerid], 440.0, 0.0);
    PlayerTextDrawLetterSize(playerid, KTP_Title[playerid], 0.18, 1.3);
    PlayerTextDrawSetShadow(playerid, KTP_Title[playerid], 0);
    PlayerTextDrawAlignment(playerid, KTP_Title[playerid], 2);
    KTP_Photo[playerid] = CreatePlayerTextDraw(playerid, 210.0, 185.0, "_");
    PlayerTextDrawFont(playerid, KTP_Photo[playerid], 5);
    PlayerTextDrawBackgroundColor(playerid, KTP_Photo[playerid], 0x424242FF);
    PlayerTextDrawTextSize(playerid, KTP_Photo[playerid], 260.0, 230.0);
    PlayerTextDrawSetPreviewModel(playerid, KTP_Photo[playerid], PlayerInfo[playerid][pSkin]);
    PlayerTextDrawSetPreviewRot(playerid, KTP_Photo[playerid], 0.0, 0.0, 0.0, 1.0);
    new _sf_ktp1[128];
    format(_sf_ktp1, sizeof(_sf_ktp1), "~b~Nama: ~w~%s", PlayerInfo[playerid][pName]);
    KTP_Name[playerid] = CreatePlayerTextDraw(playerid, 270.0, 185.0, _sf_ktp1);
    PlayerTextDrawLetterSize(playerid, KTP_Name[playerid], 0.15, 0.7);
    PlayerTextDrawSetShadow(playerid, KTP_Name[playerid], 0);
    new _sf_ktp2[128];
    format(_sf_ktp2, sizeof(_sf_ktp2), "~b~NIK: ~w~%d%d%d%d", playerid + 1000, PlayerInfo[playerid][pID], PlayerInfo[playerid][pAge], PlayerInfo[playerid][pGender]);
    KTP_NIK[playerid] = CreatePlayerTextDraw(playerid, 270.0, 198.0, _sf_ktp2);
    PlayerTextDrawLetterSize(playerid, KTP_NIK[playerid], 0.14, 0.65);
    PlayerTextDrawSetShadow(playerid, KTP_NIK[playerid], 0);
    new _sf_ktp3[256];
    new gender_s[16];
    if (PlayerInfo[playerid][pGender] == 0) gender_s = "Laki-laki";
    else gender_s = "Perempuan";
    format(_sf_ktp3, sizeof(_sf_ktp3), "~b~Umur: ~w~%d  ~b~JK: ~w~%s  ~b~Job: ~w~%s", PlayerInfo[playerid][pAge], gender_s, gJobNames[PlayerInfo[playerid][pJob]]);
    KTP_Detail[playerid] = CreatePlayerTextDraw(playerid, 270.0, 211.0, _sf_ktp3);
    PlayerTextDrawLetterSize(playerid, KTP_Detail[playerid], 0.14, 0.65);
    PlayerTextDrawSetShadow(playerid, KTP_Detail[playerid], 0);
    PlayerTextDrawShow(playerid, KTP_Card[playerid]);
    PlayerTextDrawShow(playerid, KTP_Title[playerid]);
    PlayerTextDrawShow(playerid, KTP_Photo[playerid]);
    PlayerTextDrawShow(playerid, KTP_Name[playerid]);
    PlayerTextDrawShow(playerid, KTP_NIK[playerid]);
    PlayerTextDrawShow(playerid, KTP_Detail[playerid]);
    SetTimerEx("HideKTPCard", 8000, false, "i", playerid);
}

forward HideKTPCard(playerid);
public HideKTPCard(playerid)
{
    if (!gKTPOpen[playerid]) return 1;
    gKTPOpen[playerid] = false;
    PlayerTextDrawDestroy(playerid, KTP_Card[playerid]);
    PlayerTextDrawDestroy(playerid, KTP_Title[playerid]);
    PlayerTextDrawDestroy(playerid, KTP_Photo[playerid]);
    PlayerTextDrawDestroy(playerid, KTP_Name[playerid]);
    PlayerTextDrawDestroy(playerid, KTP_NIK[playerid]);
    PlayerTextDrawDestroy(playerid, KTP_Detail[playerid]);
    return 1;
}

stock ShowStatsCard(playerid)
{
    if (gStatOpen[playerid]) return;
    gStatOpen[playerid] = true;
    STAT_Card[playerid] = CreatePlayerTextDraw(playerid, 180.0, 140.0, "_");
    PlayerTextDrawUseBox(playerid, STAT_Card[playerid], 1);
    PlayerTextDrawBoxColor(playerid, STAT_Card[playerid], 0x1E1E1EEE);
    PlayerTextDrawTextSize(playerid, STAT_Card[playerid], 460.0, 0.0);
    PlayerTextDrawLetterSize(playerid, STAT_Card[playerid], 0.5, 18.0);
    PlayerTextDrawSetShadow(playerid, STAT_Card[playerid], 0);
    new _sf_st[128];
    format(_sf_st, sizeof(_sf_st), "~w~STATS: %s", PlayerInfo[playerid][pName]);
    STAT_Title[playerid] = CreatePlayerTextDraw(playerid, 180.0, 140.0, _sf_st);
    PlayerTextDrawUseBox(playerid, STAT_Title[playerid], 1);
    PlayerTextDrawBoxColor(playerid, STAT_Title[playerid], 0x00897BFF);
    PlayerTextDrawTextSize(playerid, STAT_Title[playerid], 460.0, 0.0);
    PlayerTextDrawLetterSize(playerid, STAT_Title[playerid], 0.16, 1.3);
    PlayerTextDrawSetShadow(playerid, STAT_Title[playerid], 0);
    PlayerTextDrawAlignment(playerid, STAT_Title[playerid], 2);
    new _sf_s1[256];
    format(_sf_s1, sizeof(_sf_s1), "~g~Lvl %d  ~w~Exp: %d  ~b~Job: %s", PlayerInfo[playerid][pLevel], PlayerInfo[playerid][pExp], gJobNames[PlayerInfo[playerid][pJob]]);
    STAT_Line1[playerid] = CreatePlayerTextDraw(playerid, 190.0, 170.0, _sf_s1);
    PlayerTextDrawLetterSize(playerid, STAT_Line1[playerid], 0.15, 0.7);
    PlayerTextDrawSetShadow(playerid, STAT_Line1[playerid], 0);
    new _sf_s2[256];
    format(_sf_s2, sizeof(_sf_s2), "~g~Cash: $%d  ~b~Bank: $%d", PlayerInfo[playerid][pCash], PlayerInfo[playerid][pBank]);
    STAT_Line2[playerid] = CreatePlayerTextDraw(playerid, 190.0, 185.0, _sf_s2);
    PlayerTextDrawLetterSize(playerid, STAT_Line2[playerid], 0.15, 0.7);
    PlayerTextDrawSetShadow(playerid, STAT_Line2[playerid], 0);
    new _sf_s3[256];
    format(_sf_s3, sizeof(_sf_s3), "~r~HP: %.0f  ~b~AR: %.0f  ~o~Hunger: %.0f  ~c~Thirst: %.0f", PlayerInfo[playerid][pHealth], PlayerInfo[playerid][pArmor], PlayerInfo[playerid][pHunger], PlayerInfo[playerid][pThirst]);
    STAT_Line3[playerid] = CreatePlayerTextDraw(playerid, 190.0, 200.0, _sf_s3);
    PlayerTextDrawLetterSize(playerid, STAT_Line3[playerid], 0.13, 0.6);
    PlayerTextDrawSetShadow(playerid, STAT_Line3[playerid], 0);
    new _sf_s4[256];
    new sick_s[16];
    if (PlayerInfo[playerid][pSickness] == 0) sick_s = "Sehat";
    else if (PlayerInfo[playerid][pSickness] == 1) sick_s = "Flu";
    else if (PlayerInfo[playerid][pSickness] == 2) sick_s = "Demam";
    else sick_s = "Infeksi";
    format(_sf_s4, sizeof(_sf_s4), "~p~Sleep: %.0f  ~g~Stamina: %.0f  ~r~Sakit: %s", PlayerInfo[playerid][pSleep], PlayerInfo[playerid][pStamina], sick_s);
    STAT_Line4[playerid] = CreatePlayerTextDraw(playerid, 190.0, 213.0, _sf_s4);
    PlayerTextDrawLetterSize(playerid, STAT_Line4[playerid], 0.13, 0.6);
    PlayerTextDrawSetShadow(playerid, STAT_Line4[playerid], 0);
    new _sf_s5[256];
    new ktp_s[8];
    if (PlayerInfo[playerid][pKTP]) ktp_s = "Ada";
    else ktp_s = "Tdk";
    format(_sf_s5, sizeof(_sf_s5), "~w~HP: %d ($%d)  KTP: %s  Skin: %d  Wanted: %d", PlayerInfo[playerid][pPhone], PlayerInfo[playerid][pPhoneCredit], ktp_s, PlayerInfo[playerid][pSkin], PlayerInfo[playerid][pWanted]);
    STAT_Line5[playerid] = CreatePlayerTextDraw(playerid, 190.0, 226.0, _sf_s5);
    PlayerTextDrawLetterSize(playerid, STAT_Line5[playerid], 0.13, 0.6);
    PlayerTextDrawSetShadow(playerid, STAT_Line5[playerid], 0);
    PlayerTextDrawShow(playerid, STAT_Card[playerid]);
    PlayerTextDrawShow(playerid, STAT_Title[playerid]);
    PlayerTextDrawShow(playerid, STAT_Line1[playerid]);
    PlayerTextDrawShow(playerid, STAT_Line2[playerid]);
    PlayerTextDrawShow(playerid, STAT_Line3[playerid]);
    PlayerTextDrawShow(playerid, STAT_Line4[playerid]);
    PlayerTextDrawShow(playerid, STAT_Line5[playerid]);
    SetTimerEx("HideStatsCard", 8000, false, "i", playerid);
}

forward HideStatsCard(playerid);
public HideStatsCard(playerid)
{
    if (!gStatOpen[playerid]) return 1;
    gStatOpen[playerid] = false;
    PlayerTextDrawDestroy(playerid, STAT_Card[playerid]);
    PlayerTextDrawDestroy(playerid, STAT_Title[playerid]);
    PlayerTextDrawDestroy(playerid, STAT_Line1[playerid]);
    PlayerTextDrawDestroy(playerid, STAT_Line2[playerid]);
    PlayerTextDrawDestroy(playerid, STAT_Line3[playerid]);
    PlayerTextDrawDestroy(playerid, STAT_Line4[playerid]);
    PlayerTextDrawDestroy(playerid, STAT_Line5[playerid]);
    return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if (gPhoneOpen[playerid])
    {
        if (clickedid == PhoneHomeBtn || clickedid == Text:INVALID_TEXT_DRAW)
        {
            HidePhoneUI(playerid);
            return 1;
        }
        for (new i = 0; i < 6; i++)
        {
            if (clickedid == PhoneAppBg[i])
            {
                HidePhoneUI(playerid);
                switch (i)
                {
                    case 0: cmd_bank(playerid, "");
                    case 1: SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /sms [nomor] [pesan]");
                    case 2: SendMsg(playerid, COLOR_YELLOW, "Penggunaan: /call [nomor]");
                    case 3: cmd_gps(playerid, "");
                    case 4: SendMsg(playerid, COLOR_YELLOW, "Masuk ke toko dan gunakan /beli");
                    case 5: cmd_dokumen(playerid, "");
                }
                return 1;
            }
        }
    }
    return 0;
}


/* =====================================================================
 *  MAIN MENU & FULL COMMAND LIST
 * =====================================================================*/
CMD:menu(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new str[512];
    str[0] = EOS;
    strcat(str, "{FFFFFF}=== Menu Inferno RP ===\n\n", sizeof(str));
    strcat(str, "1. {00FF00}Stats Saya{FFFFFF}\n", sizeof(str));
    strcat(str, "2. {00FF00}Help / Commands{FFFFFF}\n", sizeof(str));
    strcat(str, "3. {00FF00}Pekerjaan{FFFFFF}\n", sizeof(str));
    strcat(str, "4. {00FF00}Dokumen{FFFFFF}\n", sizeof(str));
    strcat(str, "5. {00FF00}Handphone{FFFFFF}\n", sizeof(str));
    strcat(str, "6. {00FF00}Bank / ATM{FFFFFF}\n", sizeof(str));
    strcat(str, "7. {00FF00}GPS Navigation{FFFFFF}\n", sizeof(str));
    strcat(str, "8. {00FF00}Admin Help{FFFFFF}\n", sizeof(str));
    ShowPlayerDialog(playerid, 1101, DIALOG_STYLE_LIST, "{00FF00}Menu Utama", str, "Pilih", "Tutup");
    return 1;
}

CMD:commands(playerid, params[])
{
    if (!PlayerInfo[playerid][pIsLogged]) return 1;
    new str[1024];
    str[0] = EOS;
    strcat(str, "{FFFFFF}=== SEMUA COMMAND ===\n\n", sizeof(str));
    strcat(str, "{00FF00}Umum:{FFFFFF} /stats /help /menu /commands\n\n", sizeof(str));
    strcat(str, "{00FF00}Survival:{FFFFFF} /tidur /bangun /makan /minum /obat\n", sizeof(str));
    strcat(str, " /makanresto /usedrug /fish\n\n", sizeof(str));
    strcat(str, "{00FF00}Rumah:{FFFFFF} /buyhouse /sellhouse /enterhouse\n", sizeof(str));
    strcat(str, " /exithouse /lockhouse\n\n", sizeof(str));
    strcat(str, "{00FF00}Bisnis:{FFFFFF} /buybiz /sellbiz /bizmenu\n\n", sizeof(str));
    strcat(str, "{00FF00}Kendaraan:{FFFFFF} /buycar /lockcar /park /engine\n", sizeof(str));
    strcat(str, " /mycars /rentcar /isibensin /cekbensin\n\n", sizeof(str));
    strcat(str, "{00FF00}Pekerjaan:{FFFFFF} /kerja /quitjob /mulaikerja\n", sizeof(str));
    strcat(str, " /selesaikerja /repair\n\n", sizeof(str));
    strcat(str, "{00FF00}HP:{FFFFFF} /hp /sms /call /angkat /hangup /topup\n", sizeof(str));
    strcat(str, " /addcontact /contacts\n\n", sizeof(str));
    strcat(str, "{00FF00}Bank:{FFFFFF} /bank /atm /transfer /kredit /bayarkredit\n\n", sizeof(str));
    strcat(str, "{00FF00}Dokumen:{FFFFFF} /dokumen /urusdokumen\n\n", sizeof(str));
    strcat(str, "{00FF00}Medis:{FFFFFF} /rawatinap /ambulans /resep\n\n", sizeof(str));
    strcat(str, "{00FF00}Polisi:{FFFFFF} /duty /ticket /cuff /uncuff\n", sizeof(str));
    strcat(str, " /sidang /putusan /jaksa /pengacara\n\n", sizeof(str));
    strcat(str, "{00FF00}Gov:{FFFFFF} /pemerintah /daftarpilkada /pilkada\n\n", sizeof(str));
    strcat(str, "{00FF00}Lainnya:{FFFFFF} /gps /beli /buyclothes\n", sizeof(str));
    strcat(str, " /washmoney /pajak /creategang\n\n", sizeof(str));
    strcat(str, "{00FF00}Admin:{FFFFFF} /ahelp /a /heal /armor /goto\n", sizeof(str));
    strcat(str, " /gethere /freeze /slap /kick /ban\n", sizeof(str));
    strcat(str, " /sethp /setcash /setskin /setlevel\n", sizeof(str));
    strcat(str, " /setadmin /givemoney /tp /tppos\n", sizeof(str));
    ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "{00FF00}Semua Command", str, "Tutup", "");
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
 *  OnPlayerEnterCheckpoint - Job Missions
 * =====================================================================*/
public OnPlayerEnterCheckpoint(playerid)
{
    if (gJobMission[playerid] == 1 || gJobMission[playerid] == 2)
    {
        DisablePlayerCheckpoint(playerid);
        new reward = 0;
        if (gJobMission[playerid] == 1) reward = 3000;
        else reward = 2000;
        PlayerInfo[playerid][pCash] += reward;
        PlayerInfo[playerid][pExp] += 2;
        gJobMission[playerid] = 0;
        RestoreOrigSkin(playerid);
        SendFmt(playerid, COLOR_GREEN, "Misi selesai! +$%d dan +2 EXP.", reward);
    }
    return 1;
}

/* =====================================================================
 *  GPS & Menu Dialog Handlers
 * =====================================================================*/
/* Dialog 1100 = GPS, 1101 = Menu */
forward OnGPSDialog(playerid, response, listitem);
forward OnMenuDialog(playerid, response, listitem);

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
