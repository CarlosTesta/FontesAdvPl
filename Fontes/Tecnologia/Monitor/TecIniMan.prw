#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'TOPCONN.CH'
/*/
Fase 1  - sem depend�ncia de API em C (j� pode ser executada)
Gerenciamento de INI
    o   Leitura de item
    o   Grava��o de item/sess�o
    o   Modifica��o de item
    o   exclus�o de item/sess�o
SetEnv
    o   Montagem de um ambiente consumindo licen�a
    o   Montagem de um ambiente sem consumir licen�a (light)
Tabela TRB (com ciclos distintos para 1 e N)
    o   Cria
    o   Deleta
    o   Insere (1 e N)
    o   Modifica (1 e N)
    o   Exclui (1 e N)
Tabela TOP (com ciclos distintos para 1 e N)
    o   Cria
    o   Deleta
    o   Insere (1 e N)
    o   Modifica (1 e N)
    o   Exclui (1 e N)
    o   Trunca
RPC
    o   Chamada para a m�quina local
    o   Chamada para uma m�quina remota
Obter a vers�o do Bin�rio
Obter a vers�o do RPO
Obter a vers�o do RELEASE do Protheus
Obter a lista de usu�rios (verificar se a API existente atende, sen�o dever� ser implementada na pr�xima fase)
/*/
User Function TecIni()
Local nCnt,xRet
Local cLib := NIL      // Para uso GetRemoteType()
Local cRet := ""       // Para uso GetRmtVersion()
Local _aFuncs := {}

RPCSetType(3)
PREPARE ENVIRONMENT EMPRESA "T1" FILIAL "D MG 01 " MODULO "FAT"

// Poder�o ser utilizadas no futuro
//AADD(_aFuncs,"GetClientIP()")
//AADD(_aFuncs,"GetComputerName()")
//AADD(_aFuncs,"GetEnvHost()")
//AADD(_aFuncs,"GetHardwareId()")
//AADD(_aFuncs,"GetProcInfoArray()")
//AADD(_aFuncs,"GetRemoteIniName()")
//AADD(_aFuncs,"GetRemoteType(@cLib)")
//AADD(_aFuncs,"GetRmtDate()")
//AADD(_aFuncs,"GetRmtInfo()")
//AADD(_aFuncs,"GetRmtTime()")
//AADD(_aFuncs,"cRet := GetRmtVersion()")
//AADD(_aFuncs,"GetSrvGlbInfo()")
//AADD(_aFuncs,"GetSrvInfo()")
//AADD(_aFuncs,"GetSrvIniName()")
//AADD(_aFuncs,"GetSrvMemInfo()")
//AADD(_aFuncs,"GetSrvOSInfo()")
//AADD(_aFuncs,"GetTempPath()")
//AADD(_aFuncs,"GetUserInfoArray()")
//AADD(_aFuncs,"GetVarSize()")
//AADD(_aFuncs,"GetWebJob()")
//AADD(_aFuncs,"GetServerType()")         // Tipo de Execu��o do AppServer, retorno pode ser 0=None, 1=Console (texto), 2=ISAPI (Web) e 3=FAT (Gr�fico)

// Fun��es necess�rias para a Fase 1
AADD(_aFuncs,"GetBuild()")              // Bin�rio do AppServer
AADD(_aFuncs,"GetRPORelease()")         // Release do ERP
AADD(_aFuncs,"GetEnvServer()")          // Environment de trabalha atual
AADD(_aFuncs,"GetServerIP()")           // IP do Server
AADD(_aFuncs,"GetSrvVersion()")         // Vers�o do AppServer

ConOut("========================================")
For nCnt :=1 To Len(_aFuncs)
    xRet := &(_aFuncs[nCnt])
    If ValType(xRet) == "D"
        xRet := DTOC(xRet)
    ElseIf ValType(xRet) == "N"
        xRet := AllTrim(Str(xRet))
    EndIf
    ConOut("--------------------------")
    ConOut("Feature <<" + AlLTrim(Str(nCnt)) + ">> " + _aFuncs[nCnt])
    If ValType(xRet) == "A"
        Varinfo("",xRet)
    Else
        If ValType(cLib) == "U"
            ConOut("<<"+ xRet +">>")
        Else
            ConOut(cLib)
            cLib := NIL
        EndIf
    EndIf
    //ConOut("--------------------------")
    xRet := NIL
Next
ConOut("========================================")

RESET ENVIRONMENT

Return Nil