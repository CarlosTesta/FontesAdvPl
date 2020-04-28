#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'TOPCONN.CH'

// Depois criar um CH com todos os DEFINE´s
// DEFINE´s da ordem dos campos que serão montados no Browse
#DEFINE USUARIO     1
#DEFINE ESTACAO     2
#DEFINE ID          3
#DEFINE SERVIDOR    4
#DEFINE PROGRAMA    5   
#DEFINE ENVUSER     6
#DEFINE STARTON     7
#DEFINE TIMECONN    8
#DEFINE INSTRSEC    9
#DEFINE INSTRTOT    10
#DEFINE OBS         11
#DEFINE MEMORIA     12
#DEFINE SID         13
#DEFINE OPCAO       14
#DEFINE ESP         15

// Define de controle das variáveis GLOBAIS de armazenamento
#DEFINE GLBDataSrv  "TECMONITOR"    // dados globais do servidor

User Function TECJOBMON()
Local nRefresh      := Val(GetPvProfString("TECMONITOR","RefreshRate","undefined","appserver.ini")) * 1000
Local nRefreshINI   := Val(GetPvProfString("TECMONITOR","RefreshINI","undefined","appserver.ini")) * 1000
Local cRPCTest      := Val(GetPvProfString("TECMONITOR","RPCTest","undefined","appserver.ini"))
Local cEmpresa      := GetPvProfString("TECMONITOR","Empresa","undefined","appserver.ini")
Local cCodEmp       := SubStr(cEmpresa,1,AT(",",cEmpresa)-1)
Local cCodFil       := SubStr(cEmpresa,AT(",",cEmpresa)+1)
Local aFuncs        := {}
Local nLastRunINI   := MicroSeconds()
Local aGlbAll       := {}   // somente para DEBUG


//  Variáveis Globais de controle de UID
VarSetXD(GLBDataSrv,"lSetUID",VarSetUID(GLBDataSrv,.T.))

RPCSetType(3)
PREPARE ENVIRONMENT EMPRESA cCodEmp FILIAL cCodFil

// Inicialização do Array de controle
U_RefreshINI(@aFuncs,@nRefreshINI)

While .T.
    If !IsInCallStack('U_TECJOBMON')
        ConOut("TECJOBMON ERROR.Queda do JOB, subindo Nova Instância. " + Time()) // Criar CH para tradução
        U_TECJOBMON()
    EndIf
    U_TTGetVals(aFuncs)
    ConOut("Antes do Sleep " + Time())
    Sleep(nRefresh)
    If MicroSeconds() + nRefreshINI >= nLastRunINI
        U_RefreshINI(@aFuncs,@nRefreshINI)
        nLastRunINI := MicroSeconds() + nRefreshINI
    EndIf
    ConOut("Depois do Sleep "+ Time())
    ConOut("")
EndDo

RESET ENVIRONMENT

Return Nil

User Function RefreshINI(aFuncs,nRefreshINI)
Local nCntFor,nValNew
Local nBINVersion   := Val(GetPvProfString("TECMONITOR","BINVersion","undefined","appserver.ini"))
Local nSetEnv       := Val(GetPvProfString("TECMONITOR","SetEnv"    ,"undefined","appserver.ini"))
Local nERPVersion   := Val(GetPvProfString("TECMONITOR","ERPVersion","undefined","appserver.ini"))
Local nTRBCount     := Val(GetPvProfString("TECMONITOR","TRBCount"  ,"undefined","appserver.ini"))
Local nTOPCount     := Val(GetPvProfString("TECMONITOR","TOPCount"  ,"undefined","appserver.ini"))
Local nUserList     := Val(GetPvProfString("TECMONITOR","USERList"  ,"undefined","appserver.ini"))

If Len(aFuncs) == 0
    AADD(aFuncs,{"nBINVersion",nBINVersion,MicroSeconds(),"SRV_IPPROTHEUS" ,"GetServerIP()"})         // IP do Server
    AADD(aFuncs,{"nBINVersion",nBINVersion,MicroSeconds(),"SRV_APPSERVER"  ,"GetBuild()"})            // Binário do AppServer
    AADD(aFuncs,{"nBINVersion",nBINVersion,MicroSeconds(),"SRV_BINVERSION" ,"GetSrvVersion()"})       // Versão do AppServer
    AADD(aFuncs,{"nSetEnv"    ,nSetEnv    ,MicroSeconds(),"SRV_ENVIRONMENT","GetEnvServer()"})        // Environment de trabalha atual
    AADD(aFuncs,{"nERPVersion",nERPVersion,MicroSeconds(),"ERP_RELEASE"    ,"GetRPORelease()"})       // Release do ERP
    AADD(aFuncs,{"nTRBCount"  ,nTRBCount  ,MicroSeconds(),"TRB_COUNT"      ,"U_TCount('TRB_COUNT')"}) // Contagem de Tempo para tabelas temporárias LOCAIS
    AADD(aFuncs,{"nTOPCount"  ,nTOPCount  ,MicroSeconds(),"TOP_COUNT"      ,"U_TCount('TOP_COUNT')"}) // Contagem de Tempo para tabelas temporárias via TOP
    AADD(aFuncs,{"nUserList"  ,nUserList  ,MicroSeconds(),"SRV_USERLIST"   ,"U_TUsers()"})            // Pega a lista de usuários por Slave ou a Partir do Master Balance
Else
    For nCntFor := 1 To Len(aFuncs)
        nValNew := &(aFuncs[nCntFor][1])
        If aFuncs[nCntFor][2] <> nValNew
            ConOut("Parametro alterado:<<" +aFuncs[nCntFor][4] + ">> | Antigo:<<"+AllTrim(Str(aFuncs[nCntFor][2]))+">> | Atual:<<"+AllTrim(Str(nValNew))+">>")
            aFuncs[nCntFor][2] := nValNew
        EndIf
    Next
    // validação da alteração do PARAMETRO RefreshINI
    nValNew := Val(GetPvProfString("TECMONITOR","RefreshINI","undefined","appserver.ini")) * 1000
    If nRefreshINI <> nValNew
        ConOut("Parametro alterado:<<RefreshINI>> | Antigo:<<"+AllTrim(Str(nRefreshINI))+">> | Atual:<<"+AllTrim(Str(nValNew))+">>")
        nRefreshINI := nValNew
    EndIf
EndIf

Return Nil

User Function TTGetVals(aFuncs)
Local nCnt,lSetList,lSetUID
Local aRet      := {}
Local aGlbAll   := {}

VarGetX(GLBDataSrv,"lSetUID",@lSetUID)

For nCnt := 1 To Len(aFuncs)
    If aFuncs[nCnt][3] >= 1 .and. (aFuncs[nCnt][3] <= MicroSeconds())
        If aFuncs[nCnt][2] > 1
            aFuncs[nCnt][3] := MicroSeconds() + aFuncs[nCnt][2]
        Else
            aFuncs[nCnt][3] := 0
        EndIf
        // este está OK para //VarInfo()
        AADD(aRet,{aFuncs[nCnt][4],&(aFuncs[nCnt][5])})

        // agora criando a idéia de armazenar os dados em variáveis Globais
        If lSetUID
            If ValType(aRet[Len(aRet)][2]) <> "A"
                lSetList := VarSetXD(GLBDataSrv,aFuncs[nCnt][4],aRet[Len(aRet)][2]) // atualizando valor
            Else
                lSetList  := VarSetAD(GLBDataSrv,aFuncs[nCnt][4],@aRet)        // Atualizando Array Global
            EndIf
        Else
            ConOut("Erro na atualização da Lista GLOBAL <<" + GLBDataSrv + ">>. Valores podem estar DEFASADOS!!!")
        Endif
    EndIf
Next

If Len(aRet) > 0
    VarGetAA(GLBDataSrv,@aGlbAll)
    //VarInfo("aGlbAll",aGlbAll)
EndIf

Return Nil

// opções a serem contempladas com tempos
//Cria / Deleta / Insere (1 e N) / Modifica (1 e N) / Exclui (1 e N) / Trunca / DELETA ARQUIVO
//User Function TCount()
//Local cOpc      := "TOP_COUNT"
User Function TCount(cOpc)
Local nCntOp,nRegOp
Local aEnlapsed := {}
Local aStruTbl  := {}
Local aDataIns  := {}

AADD(aStruTbl,{"FIELD_CS","C",015,0})   // campo caracter CURTO (SHORT)
AADD(aStruTbl,{"FIELD_CL","C",250,0})	// campo caracter LONGO (LONG)
AADD(aStruTbl,{"FIELD_NI","N",007,0})   // campo numérico INTEIRO
AADD(aStruTbl,{"FIELD_ND","N",010,4})   // campo numérico DECIMAL
AADD(aStruTbl,{"FIELD_D" ,"D",008,0})
AADD(aStruTbl,{"FIELD_L" ,"L",001,0})

AADD(aEnlapsed,{cOpc,"CREATE",MicroSeconds(),})
If cOpc == "TRB_COUNT"
    // criação da tabela
    dbCreate("TECMON"+GetDbExtension(),aStruTbl,__LocalDriver)
    dbUseArea(.T.,__LocalDriver,"TECMON"+GetDbExtension(),"TBL",.F.,.F.)
Else
    // criação da tabela
    dbCreate("TECMON",aStruTbl,"TOPCONN")
    dbUseArea(.T., "TOPCONN","TECMON","TBL", .T., .F.)
    // Ajustando campos para o recebimento padrão de dados no formato do ERP
    TcSetField("TBL","FIELD_NI","N", 07, 0 )
    TcSetField("TBL","FIELD_ND","N", 10, 4 )
    TcSetField("TBL","FIELD_D" ,"D", 08, 0 )
    TcSetField("TBL","FIELD_L" ,"L", 01, 0 )
EndIf
dbSelectArea("TBL")
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// Inserção 1 REGISTRO
aDataIns := U_MontaDt(1)
AADD(aEnlapsed,{cOpc,"INSERTx1",MicroSeconds(),})
For nCntOp := 1 To Len(aDataIns)
    RecLock("TBL",.T.)
    TBL->FIELD_CS   := aDataIns[nCntOp][1]
    TBL->FIELD_CL   := aDataIns[nCntOp][2]
    TBL->FIELD_NI   := aDataIns[nCntOp][3]
    TBL->FIELD_ND   := aDataIns[nCntOp][4]
    TBL->FIELD_D    := aDataIns[nCntOp][5]
    TBL->FIELD_L    := .T.
    TBL->( MsUnLock() )
Next
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// chamada para o Inserção em N
aDataIns := U_MontaDt(Randomize(1,500))
AADD(aEnlapsed,{cOpc,"INSERTxN",MicroSeconds(),})
For nCntOp := 1 To Len(aDataIns)
    RecLock("TBL",.T.)
    TBL->FIELD_CS   := aDataIns[nCntOp][1]
    TBL->FIELD_CL   := aDataIns[nCntOp][2]
    TBL->FIELD_NI   := aDataIns[nCntOp][3]
    TBL->FIELD_ND   := aDataIns[nCntOp][4]
    TBL->FIELD_D    := aDataIns[nCntOp][5]
    TBL->FIELD_L    := .T.
    TBL->( MsUnlock() )
Next
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// chamada para ALTERAÇÃO de 1 Registro ALEATORIO
AADD(aEnlapsed,{cOpc,"ALTERx1",MicroSeconds(),})
nRegOp := Randomize(1,TBL->(RecCount()) )
TBL->( dbGoTo(nRegOp) )    // seleciona um registro aleatório na base
RecLock("TBL")
TBL->FIELD_CL   := "REGISTRO ALTERADO PARA " + MD5(Str(MicroSeconds()),2)+MD5(Str(MicroSeconds()),2)
TBL->( MsUnlock() )
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// chamada para ALTERAÇÃO de 10 Registros ALEATORIOS
AADD(aEnlapsed,{cOpc,"ALTERx10",MicroSeconds(),})
nRegOp := Int(TBL->(RecCount())/10)
For nCntOp := 1 to nRegOp Step 10
    TBL->( dbGoTo(nCntOp) )    // seleciona um registro aleatório na base
    RecLock("TBL")
    TBL->FIELD_CL   := "REGISTRO ALTERACAO " + Str(nCntOp) + " PARA " + MD5(Str(MicroSeconds()),2)
    TBL->( MsUnlock() )
Next
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// chamada para o Exclusão de 1 Registro ALEATORIO
AADD(aEnlapsed,{cOpc,"DELETEx1",MicroSeconds(),})
nRegOp := Randomize(1,TBL->(RecCount()) )
TBL->( dbGoTo(nRegOp) )     // seleciona um registro aleatório na base
RecLock("TBL")
TBL->( dbDelete() )         // deleção formato ERP
TBL->( MsUnlock() )
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// chamada para o Exclusão de N Registro ALEATORIO
AADD(aEnlapsed,{cOpc,"DELETEx10",MicroSeconds(),})
nRegOp := Int(TBL->(RecCount())/10)
For nCntOp := 1 to nRegOp Step 10
    TBL->( dbGoTo(nCntOp) )     // seleciona um registro aleatório na base
    RecLock("TBL")
    TBL->( dbDelete() )         // deleção formato ERP
    TBL->( MsUnlock() )
Next
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// chamada TRUNCATE de tabela 
AADD(aEnlapsed,{cOpc,"TRUNCATE",MicroSeconds(),})
If cOpc == "TRB_COUNT"
    TBL->( __dbZap() )
Else
    TCSQLExec("TRUNCATE TABLE TECMON")
    TCSQLExec("COMMIT")
EndIf
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

TBL->( dbCloseArea() )
//VarInfo("Dados " + cOpc,aEnlapsed)

// eliminando o arquivo de trabalho
AADD(aEnlapsed,{cOpc,"DROP",MicroSeconds(),})
If cOpc == "TRB_COUNT"
    fErase("TECMON"+GetDbExtension())
Else
    TCDelfile("TECMON")
EndIf
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

Return(aEnlapsed)

User Function MontaDt(nOpc)
Local nCnt
Local aDataSci := {}

For nCnt := 1 To nOpc
    cChar15     := StrZero(nCnt,15)
    cChar250    := MD5(Str(MicroSeconds()),2) + Space(10) + MD5(Str(MicroSeconds()),2) + Space(10) + MD5(Str(MicroSeconds()),2)
    nNumInt     := Randomize(1,999999)
    nNumDec     := Randomize(1,999999) + (Randomize(0,9999)/100)
    AADD(aDataSci,{cChar15,cChar250,nNumInt,nNumDec,dDATABASE,.T.})
Next

Return(aDataSci)

User Function TUsers()
Local cCmdSlave,cSrvSlave,nPortSlave,nCntFor    //,lGlbTran,lRunOK,lGlbComm,lGetList,lSetUID
Local aSlaves   := {}
Local aUsersL   := {}
Local aListAll  := {}
Local cSlaves   := GetPvProfString("ServerNetwork","Servers","undefined","appserver.ini") + "," // acrescentada a "," para facilitar coleta de info

//VarGetX(GLBListUSER,"lSetUID",@lSetUID)

// Caso o Serviço seja um Master Balance, irá efetuar a coleta a partir deste, 
// caso contrário, somente pegará a lista de usuários LOCAL
If Upper(cSlaves) <> "UNDEFINED,"   // UPPER para garantir comparação sempre correta
    While !Empty(cSlaves)
        cCmdSlave   := SubStr(cSlaves,1,AT(",",cSlaves)-1)
        cSrvSlave   := GetPvProfString(cCmdSlave,"Server","undefined","appserver.ini")
        nPortSlave  := GetPvProfString(cCmdSlave,"Port","undefined","appserver.ini")
        AADD(aSlaves,{cCmdSlave,cSrvSlave,nPortSlave})
        cSlaves     := SubStr(cSlaves,AT(",",cSlaves)+1)
    EndDo
Else    
    cSrvSlave   := GetComputerName()
    nPortSlave  := GetPvProfString("TCP","Port","undefined","appserver.ini")
    AADD(aSlaves,{GetServerIP(),cSrvSlave,nPortSlave})  // Chave Principal IP DO Servidor LOCAl
EndIf

For nCntFor := 1 to Len(aSlaves)
    AADD(aUsersL,GetUserInfoArray())
Next

Return(aUsersL)

User Function MyGlbTest()
Local xRet
Local xaRet     := {}
Local lOK       := VarSetUID("TSTVarGet",.T.)
Local nValor    := 123
Local aGlbPut   := {}   // trabalhando com área de memória comum
Local aGlbAll   := {}

AADD(aGlbPut,{"VarGlb01","Valor 01"})
AADD(aGlbPut,{"VarGlb02","Valor 02"})
AADD(aGlbPut,{"VarGlb03","Valor 03"})

// trabalhando com áreas de memória NOMEADAS TRANSACIONADAS...
lOkBeginT   := VarBeginT("TSTVarGet","VarGlbX")         // Begin Transaction
lRunOK      := VarSetXD("TSTVarGet","VarGlbX",nValor)   // atualizando valor
lOkCommitT  := VarEndT("TSTVarGet","VarGlbX")           // Commit Transaction

lOkBeginT   := VarBeginT("TSTVarGet","VarGlbA")         // Begin Transaction
lRunOK      := VarSetAD("TSTVarGet","VarGlbA",aGlbPut)  // atualizando valor
lOkCommitT  := VarEndT("TSTVarGet","VarGlbA")           // Commit Transaction

VarGetAA("TSTVarGet",@aGlbAll)          // retorna um HASH MAP com todos as chaves/valores

VarGetX("TSTVarGet","VarGlbX",@xRet)    // recuperando valor
VarGetA("TSTVarGet","VarGlbA",@xaRet)   // recuperando Array

//VarInfo("VarGlbX",xRet)
//VarInfo("VarGlbA",xaRet)
//VarInfo("Lista Geral",aGlbAll)

Return Nil
