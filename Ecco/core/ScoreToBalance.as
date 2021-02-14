namespace EccoScoreBuffer{
    CScheduledFunction@ RefreshScore;
    dictionary PlayerScoreBuffer;

    void ResetPlayerBuffer(CBasePlayer@ pPlayer){
        PlayerScoreBuffer.set(e_PlayerInventory.GetUniquePlayerId(pPlayer), 0);
    }

    void ResetPlayerBuffer(){
        PlayerScoreBuffer.deleteAll();
    }

    void RegisterTimer(){
        if(@RefreshScore !is null)
            g_Scheduler.RemoveTimer(@RefreshScore);
        @RefreshScore = g_Scheduler.SetInterval("RefreshBuffer", EccoConfig::GetConfig()["Ecco.BaseConfig", "RefreshTimer"].getFloat(), g_Scheduler.REPEAT_INFINITE_TIMES);
    }

    void RefreshBuffer(){
        for(int i = 0; i < g_Engine.maxClients; i++){
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i+1);
            if(pPlayer !is null){
                string PlayerUniqueId = e_PlayerInventory.GetUniquePlayerId(pPlayer);
                int ScoreChange = int(pPlayer.pev.frags) - int(PlayerScoreBuffer[PlayerUniqueId]);
                if(ScoreChange != 0){
                    float ConfigMultiplier = EccoConfig::GetConfig()["Ecco.BaseConfig", "ScoreToMoneyMultiplier"].getFloat();
                    e_PlayerInventory.ChangeBalance(pPlayer, int(ScoreChange * ConfigMultiplier));
                }
                PlayerScoreBuffer[PlayerUniqueId] = int(pPlayer.pev.frags);
            }
        }
    }
}