//TODO: Brand new yankee scripts
funcdef string FuncEccoCommand(CEccoScriptCommandItem@);

class CEccoScriptCommandItem{
    FuncEccoCommand@ pFunc();
    array<sting> = aryArgs = {};
}

class CEccoScriptItem {
    private string szName;
    private string szPath;
    private array<CEccoScriptCommandItem@> aryExcuteBlock = {};
}

enum SCRIPTS_VAR_TYPE{
    VAR_INVALID = -1,
    VAR_STRING = 0,
    VAR_FUNCTION = 1;
}

class CEccoScriptVar{
    string szName;
    private array<string> aryVal = {};
    SCRIPTS_VAR_TYPE iType = SCRIPTS_VAR_TYPE::VAR_INVALID;
    void Set(string val){
        aryVal.removeAll();
        aryVal[0] = val;
        iType = SCRIPTS_VAR_TYPE::VAR_STRING;
    }

    void Set(array<string>@ aryInput){
        aryVal = aryInput;
        iType = SCRIPTS_VAR_TYPE::VAR_FUNCTION;
    }
}


class CEccoException{
    string Message;
    uint Line;
    uint Pos;
    CEccoException(string _Msg, uint _L, uint _P){
        Message = _Msg;
        Line = _L;
        Pos = _P;
    }
}

class CEccoScriptEngine{
    //紧急拉闸
     private bool bException = false;
     private CEccoException@ pException = null;
     //解释到第几行
     private uint iLine = 0;
     private uint iPosition = 0;
     //延迟控制
     private CScheduledFunction@ pScheduler = null;
     private float flNowDelay = 0.0f;
     //变量
     private dictionary dicVars = {};
     private void SetVar(string szName, string szVar){
         CEccoScriptVar pVar;
         pVar.Set(szVar);
         dicVars.set(szName, @pVar);
     }
     private void SetVar(string szName, array<string> aryVar){
         CEccoScriptVar pVar;
         pVar.Set(aryVar);
         dicVars.set(szName, @pVar);
     }

     //栈
     private array<string> aryStack = {};
     //是否处于压栈状态
     private bool bIsInStack = false;

    //从文件分割得代码块
    array<string>@ Load(string szPath){

    }
    //从字符串分割得代码块
    array<string>@ Parse(string szCode){

    }

    void Interpret(array<string>@ aryLines){
        //紧急拉闸报错
        if(bException && State != TCLEngineState::IN_TRYCATCH){
            Logger::Log("Catch Excetipon in TCL script (%1,%2):\n    Message:%3.\n   script will abort running.", pException.iLine, pException.iPos, pException.Message);
            return;
        }
        //解释好多行
        //递归解释，可以控制整个流延迟
        if(aryLines.length() > 0){
            iLine++;
            InterpretLine(aryLines[0]);
            aryLines.removeAt(0);
            pScheduler.SetTimeout(this, "Interpret", flNowDelay, @aryLines);
        }
    }

    string InterpretLine(string szLine){
        if(bIsInStack){
            if(szLine.FindFirstOf("}") != String::INVALID_INDEX)
                bIsInStack = false;
            else{
                aryStack.insertLast(szLine);
                return "";
            }
        }
        //解释一行
        //预处理小括号，递归进行解释
        string szCommand = szLine;
        uint lParenth = szCommand.FindFirstOf("[");
        uint rParenth = szCommand.FindLastOf("]");
        if(lParenth != String::INVALID_INDEX || rParenth != String::INVALID_INDEX){
            if(lParenth != String::INVALID_INDEX && rParenth != String::INVALID_INDEX){
                string szSubCommand = szCommand.SubString(lParenth + 1, rParenth - lParenth);
                szCommand = szCommand.Replace("[" + szSubCommand + "]", InterpretLine(szSubCommand));
            }
            else
                ThrowException("Missing closed parenthesis");
        }
        //我是返回值
        string szReturn = "";
        szCommand.Trim();
        szCommand = szCommand.Replace("\t", " ");
        array<string> arySplites = szCommand.Split(" ");
        for(uint i = 0; i < arySplites.length(); i++){
            arySplites.Trim();
            //压栈
            if(arySplites[i] == "{")
                bIsInStack = true;
        }
        return szReturn;
    }

}

class CEccoScriptParser{
    array<IEccoMarco@> aryMarco = {};
    void Register(IEccoMarco@ Marco){
        aryMarco.insertLast(@Marco);
    }
    IEccoMarco@ GetMarco(string szName){
        for(uint i = 0; i < aryMarco.length(); i++){
            if(aryMarco[i] == szName)
                return aryMarco[i];
        }
        return null;
    }

    array<CEccoScriptItem@> aryItem = {};
    CEccoScriptItem@ GetItem(string szPath){
        for(uint i = 0; i < aryItem.length(); i++){
            if(aryItem[i] == szPath)
                return aryItem[i];
        }
        return null;
    }
    void BuildItemList(){
        array<string>@ aryScripts = IO::FileLineReader(szRootPath + EccoConfig::GetConfig()["Ecco.BaseConfig", "ScriptsPath"].getString());
        for(uint i = 0; i < aryScripts.length();i++){
            CEccoScriptItem@ pItem = CEccoScriptItem(aryScripts[i]);
            if(!pItem.IsEmpty())
                aryItem.insertLast(@pItem);
        }
    }

    bool ExecuteCommand(string szCommandLine, CBasePlayer@ pPlayer){
        array<string> aryCommandList = szCommandLine.Split("&&");
        bool bSuccess = true;
        for(uint j=0; j < aryCommandList.length(); j++){
            array<string>@ args = Utility::Select(aryCommandList[j].Split(" "), function(string szLine){ return !szLine.IsEmpty(); });
            if(args.length() > 0){
                string szName = args[0];
                if(!szName.IsEmpty() && szName != "\n"){
                    args.removeAt(0);
                    IEccoMarco@ pMarco = GetMarco(szName);
                    if(pMarco !is null){
                        for(uint i = 0; i < args.length(); i++){
                            args[i] = EccoProcessVar::ProcessVariables(args[i], @pPlayer);
                        }
                        bSuccess = bSuccess && pMarco.Execute(@pPlayer, args);
                        if(!bSuccess)
                            break;
                    }else{
                        Logger::Log("[ERROR - Ecco::Echo] No such macro called " + szName);
                        bSuccess = false;
                    }
                }
            }
        }
        return bSuccess;
    }

    void RandomExecute(array<string>@ aryRandom, CBasePlayer@ pPlayer){
        dictionary dicRandomElements = {};
        for(uint i = 0; i< aryRandom.length(); i++){
            array<string>@ aryThisArgs = Utility::Select(aryRandom[i].Split(" "), function(string szLine){return !szLine.IsEmpty();});
            int iPossibility = atoi(aryThisArgs[0]);
            if(iPossibility > 0){
                aryThisArgs.removeAt(0);
                aryRandom[i] = "";
                for(uint j = 0; j < aryThisArgs.length(); j++){
                    aryRandom[i] += aryThisArgs[j];
                    if( j != aryThisArgs.length() - 1 )
                        aryRandom[i] += " ";
                }
                dicRandomElements.set(aryRandom[i], iPossibility);
            }else
                aryRandom.removeAt(i);
        }
        
        array<string>@ dictKeys = dicRandomElements.getKeys();
        int randomSum = 0;
        for(uint i = 0; i < dictKeys.length(); i++){
            randomSum += int(dicRandomElements[dictKeys[i]]);
        }
        int randomNum = int(Math.RandomLong(0, randomSum));
        int thisRandom = 0;
        for(uint i=0; i < dictKeys.length(); i++){
            thisRandom += int(dicRandomElements[dictKeys[i]]);
            if(thisRandom >= randomNum){
                if(dictKeys[i] != "")
                    ExecuteCommand(dictKeys[i], pPlayer);
                break;
            }
        }
    }

    bool ExecuteFile(string MacroPath, CBasePlayer@ pPlayer){
        CEccoScriptItem@ pItem = GetItem(MacroPath);
        if(pItem !is null && !pItem.IsEmpty())
            return pItem.Excute(@pPlayer);
        else
            return false;
    }
}
CEccoScriptParser e_ScriptParser;