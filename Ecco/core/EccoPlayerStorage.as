namespace EccoPlayerStorage{
    class CPlayerStorageData{
        array<CPlayerStorageDataItem@> aryPlayerList = {};

        CPlayerStorageDataItem@ Get(string szSteamID){
            for(uint i = 0; i < aryPlayerList.length(); i++){
                if(aryPlayerList[i].szSteamID == szSteamID)
                    return aryPlayerList[i];
            }
            return null;
        }

        CPlayerStorageDataItem@ Get(CBasePlayer@ pPlayer){
            return Get(e_PlayerInventory.GetUniquePlayerId(@pPlayer));
        }

        CPlayerStorageDataItem@ opIndex(string szSteamID){
            return Get(szSteamID);
        }

        CPlayerStorageDataItem@ opIndex(CBasePlayer@ pPlayer){
            return Get(pPlayer);
        }

        bool Exists(CBasePlayer@ pPlayer){
            return Get(@pPlayer) !is null;
        }

        void SetScore(CBasePlayer@ pPlayer, float flNew){
            Get(@pPlayer).flScore = flNew;
        }

        void Clear(){
            aryPlayerList = {};
        }

        void Add(CBasePlayer@ pPlayer){
            CPlayerStorageDataItem pItem;
                pItem.szSteamID = e_PlayerInventory.GetUniquePlayerId(@pPlayer);
                pItem.flScore = 0;
                pItem.szLastPlayMap = g_Engine.mapname;
                pItem.pLastUpdateTime = DateTime();
            aryPlayerList.insertLast(pItem);
        }
    }
    class CPlayerStorageDataItem{
        string szSteamID;
        EHandle pPlayer;
        float flScore;
        
        string szLastPlayMap;
        DateTime pLastUpdateTime;
    }
    CScheduledFunction@ RefreshScore;
    CPlayerStorageData pData;

    void ResetPlayerBuffer(CBasePlayer@ pPlayer){
        pData.SetScore(pPlayer, 0.0f);
    }

    void AddPlayerBuffer(CBasePlayer@ pPlayer){
        pData.Add(@pPlayer);
    }

    void ResetPlayerBuffer(){
        pData.Clear();
    }

    bool Exists(CBasePlayer@ pPlayer){
        return pData.Exists(pPlayer);
    }

    void RemoveTimer(){
        if(@RefreshScore !is null)
            g_Scheduler.RemoveTimer(@RefreshScore);
    }

    void RegisterTimer(){
        @RefreshScore = g_Scheduler.SetInterval("RefreshBuffer", EccoConfig::GetConfig()["Ecco.BaseConfig", "RefreshTimer"].getFloat(), g_Scheduler.REPEAT_INFINITE_TIMES);
    }

    void RefreshBuffer(){
        float flConfigMultiplier = EccoConfig::GetConfig()["Ecco.BaseConfig", "ScoreToMoneyMultiplier"].getFloat();
        for(int i = 0; i < g_Engine.maxClients; i++){
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i+1);
            if(pPlayer !is null){
                string szPlayerUniqueId = e_PlayerInventory.GetUniquePlayerId(pPlayer);
                int iScoreChanged = int(pPlayer.pev.frags - pData[szPlayerUniqueId].flScore * flConfigMultiplier);
                if(iScoreChanged != 0)
                    e_PlayerInventory.ChangeBalance(pPlayer, iScoreChanged);
                pData.SetScore(pPlayer, pPlayer.pev.frags);
            }
        }
    }
}