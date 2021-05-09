//变量
class CEchoScriptVar{
    string Name;
    array<string> aryValue = {};

    CEchoScriptVar(string _szName){
        Name = _szName;
    }

    CEchoScriptVar(string _szName, array<string> _aryName){
        Name = _szName;
        aryValue = _aryName;
    }
}

//函数
class CEchoScriptFunction{
    string Name;
    array<string> aryValue = {};
    uint uiArgCount = 0; 

    CEchoScriptFunction(string _szName){
        Name = _szName;
    }

    CEchoScriptFunction(string _szName, array<string> _aryName){
        Name = _szName;
        aryValue = _aryName;
    }

    void Excute(array<string>@ aryArgs){
        if(aryArgs.length() != uiArgCount){
            return;
        }
    }
}
//运行时栈
class CEchoScriptStack{
    array<CEchoScriptVar@> aryVars = {};
    array<CEchoScriptFunction@> aryFuncs = {};

    void SetVar(string szName, string szValue){
        for(uint i = 0; i < aryVars.length(); i++){
            if(aryVars[i].Name == szName){
                aryVars[i].aryValue = {szValue};
                return;
            }
        }
        aryVars.insertLast(CEchoScriptVar(szName, {szValue}));
    }

    bool ExistsFunc(string szName){
        for(uint i = 0; i < aryFuncs.length(); i++){
            if(aryFuncs[i].Name == szName)
                return true;
        }
        return false;
    }
}

//解释器
class CEchoScriptEngine{
    private CEchoScriptStack pStack;
    private CBasePlayer@ pPlayer;

    int iInBrackets = 0;
    int iInSquareBrackets = 0;
    int iInCurlyBraces = 0;
    string szBuffer = "";

    string Interpret(string szLine){
        string szReturn = "";
        //逐行解释
        //预处理
        szLine.Trim();
        //分割缓冲区
        array<string> aryBuffer = {};
        //手动分割
        for(uint i  = 0; i < szLine.Length(); i++){
            //已经划词结束
            if(i == szLine.Length() - 1){
                if(iInBrackets != 0 || iInSquareBrackets != 0){
                    throw("Missing closed bracket");
                    return;
                }
                szBuffer.Trim();
                aryBuffer.insertLast(szBuffer);
                szBuffer = "";
                break;
            }
            char c = szLine[i];
            if(c == " " && iInBrackets == 0 && iInSquareBrackets == 0){
                szBuffer.Trim();
                aryBuffer.insertLast(szBuffer);
            }
            else if(c == "(")
                iInBrackets++;
            else if(c == ")")
                iInBrackets--;
            else if(c == "[")
                iInSquareBrackets++;
            else if(c == "]")
                iInSquareBrackets--;
            else if(c == "{")
                iInCurlyBraces++;
            else if(c == "}")
                iInCurlyBraces--;

            szBuffer += c;
        }
        //预处理括号
        for(uint i = 0; i < aryBuffer.length(); i++){
            if((aryBuffer[i].StartsWith("(") && aryBuffer[i].EndsWith(")")) || (aryBuffer[i].StartsWith("[") && aryBuffer[i].EndsWith("]")))
                aryBuffer[i] = Interpret(aryBuffer[i].SubString(1, aryBuffer[i].Length()-2));
        }
        //检查第一个
        szBuffer = aryBuffer[0];
        //是定义变量
        if(szBuffer.Find(":") != String::DEFAULT_COMPARE){
            if(szBuffer.EndsWith(":")){
                if(1 < aryBuffer.length())
                    pStack.SetVar(szBuffer, aryBuffer[1]);
                else
                    throw("Define varible " + szBuffer + " need a expression");
            }
            else{
                array<string>@ aryTemp = szBuffer.Split(":");
                pStack.SetVar(aryTemp[0], aryTemp[1]);
            }
        }
        //是函数
        else if(szBuffer.StartsWith("&")){
            //Fuck Too hard to do
        }
        //是调用函数
        else{
            //函数不存在
            if(!pStack.ExistsFunc(szBuffer))
                throw("Function: " + szBuffer + "is not exists!");
            else{
                IEccoMarco@ pMarco = e_ScriptParser.GetMarco(aryBuffer[0]);
                if(pMarco !is null){
                    aryBuffer.removeAt(0);
                    for(uint i = 0; i < aryBuffer.length(); i++){
                        aryBuffer[i] = EccoProcessVar::ProcessVariables(aryBuffer[i], @pPlayer);
                    }
                    szReturn = pMarco.Execute(@pPlayer, aryBuffer);
                }
                else
                    throw("[ERROR - Ecco::Echo] No such macro called " + szName);
            }
        }
        return szReturn;
    }
}