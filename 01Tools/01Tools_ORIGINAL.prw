#include "protheus.ch"
#include "TBICONN.CH"
#include "TOPCONN.CH"

#define STERNA1 23
#define STERNA_VER 777
// Severity
#define SEV_EMG_ 0
#define SEV_ALERT_ 1
#define SEV_CRITICAL_ 2
#define SEV_ERROR_ 3
#define SEV_WARN_ 4
#define SEV_NOTICE_ 5
#define SEV_INFORM_ 6
#define SEV_DEBUG_ 7

User Function 01TcpSrv()
Local nErrCode,cErrMsg,cInBuffer,cCmd2Run,bCmd2Run
Local oSockSrv	:= tSocketSrv():New()
Local nBuffer	:= 2000
Local nRet		:= 0
Local nSend		:= 0
// Local nPort		:= Val(GetPvProfString("QM_TCPServer", "Port", "undefined", "appserver.ini"))
Local nPort		:= 10100

Public xOutBuffer

// como ja tenho dados nas tabelas, nao preciso me preocupar neste momento com a comunicacao
// verificar depois se o comportamento vai ser o esperado
conout("-- Subiu Serviço porta " + AllTrim(Str(nPort)) + " | "+Time())
If !oSockSrv:StartTcp(nPort)
	nErrCode := oSockSrv:GetError(@cErrMsg)
	conout("STARTTCP FAILED ("+nErrCode+")")
	return
Else
	Do While (!killapp())
		oObjConn := oSockSrv:Accept( 0 )
		If oObjConn == NIL
			conout("ACCEPT FAILED ("+cErrMsg+")")
			Return
		else
			// ConOut(time())
			// varinfo("oObjConn",oObjConn)
			cInBuffer := space(nBuffer)	// zera BUFFER para proxima requisicao

			// recebe a requisicao
			nRet		:= oObjConn:Receive(cInBuffer, nBuffer)
			cInBuffer	:= AllTrim(cInBuffer)
            // conout("== cInBuffer ==============")
            // conout(cInBuffer)
            // conout("== cInBuffer ==============")
            // conout()
			
            cCmd2Run := '{||' + cInBuffer + '}'
            bCmd2Run := &(cCmd2Run)
            xOutBuffer := Eval(bCmd2Run)

            conout()
			conout("== xOutBuffer =======" + time())
			conout(Type(xOutBuffer))
			conout(Len(xOutBuffer))
			conout(xOutBuffer)
			conout("== xOutBuffer =======" + time())
			nSend := oObjConn:Send(xOutBuffer,Len(xOutBuffer))

            conout("nSend <<" + Alltrim(Str(nSend)) + ">>")
		Endif
	EndDo
EndIf

Return nil

User Function JsonTool(aCab,aDet)
local nLin,nCol,cAjuste     // variaveis do FOR para tirar warning de compilação
local cJSONRet              // JSON de Retorno
Local _cPortaSrv := GetPvProfString("TCP", "Port", "undefined", "appserver.ini")	   	// pega a porta do servico do Protheus
local cOrigem    := '{"SOURCE":[{"IPSERVER" : "' + GetServerIP() + '"},{"PORT" : "' + _cPortaSrv + '"},{"TIME":"' + Time() + '"}]}'
local cJSON      := '{"USERLIST": ['

For nLin := 1 To Len( aDet )
    cJSON += "{"
    For nCol := 1 To Len( aCab )
        If ValType(aDet[nLin][nCol]) = "C"
            cAjuste := aDet[nLin][nCol]
            If At(CHR(10),cAjuste) > 0
                cAjuste := StrTran(cAjuste,chr(10),'')
            Endif
            cAjuste := StrTran(cAjuste,"\","\\")
            cConteudo := '"' + cAjuste + '"'
        ElseIf ValType(aDet[nLin][nCol]) = "N"
            cConteudo := AllTrim(Str(aDet[nLin][nCol]))
        ElseIf ValType(aDet[nLin][nCol]) = "D"
            cConteudo := '"' + DTOC(aDet[nLin][nCol]) + '"'
        ElseIf ValType(aDet[nLin][nCol]) = "L"
            cConteudo := IF(aDet[nLin][nCol], '"true"' , '"false"')
        Else
            cConteudo := '"' + aDet[nLin][nCol] + '"'
        EndIf               
        cJSON += '"' + aCab[nCol] + '":' + cConteudo
        If nCol < Len(aCab)
            cJSON += ","
        EndIf
    Next
    cJSON += "}"
    If nLin < Len(aDet)
        cJSON += ","
    EndIf
Next
cJSON += "]}"
cJSONRet := '{"USERS":[' + cOrigem + ',' + cJSON + ']}'

Return(cJSONRet)


User Function RetUsers()
local cCmd,cMsgRet,cMsgSrc 
public cRetJson

cCmd := 'aUsers :=  GetUserInfoArray(),'
cCmd += 'aCab := {"USR_SO","ESTACAO","ID","SERVIDOR","PROGRAMA","ENVIRONMENT","START","TEMPO_CONEXAO","N_INSTR_SEC","N_INSTR","OBS","MEMORIA","SID"},'
cCmd += 'cRetJson := U_JsonTool(aCab,aUsers)'

cCmd2Run := '{||' + cCmd + '}'
bCmd2Run := &(cCmd2Run)
cRetJson := Eval(bCmd2Run)

cMsgRet := "<USERS>" + cRetJson + "</USERS>"            // Msg formato JSON padrão
cMsgSrc := '[' + GetServerIP() +'="' + Time() +'"]'   // IP e Tempo do envio

// LogMsg('LISTUSERS', STERNA1, SEV_NOTICE_, STERNA_VER, 'USER_MONITOR','[timestamp=1234]',cRetJson)
//LogMsg('LISTUSERS', STERNA1, SEV_NOTICE_, STERNA_VER, 'USER_MONITOR','',cRetJson)

// ConOut(cRetJson)

Return cRetJson

User Function NewList()
Local cTopBuild,cThreadUser,cThreadLst,cUserInfo,cMsgUser,_nCnt,cUsersPrt
Local aListUser := {}
Local aUsers :=  GetUserInfoArray()
Local aCabUser := {"USR_SO","ESTACAO","ID","SERVIDOR","PROGRAMA","ENVIRONMENT","START","TEMPO_CONEXAO","N_INSTR_SEC","N_INSTR","OBS","MEMORIA","SID"},'


RPCSetType(3)
PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "CFG"

// recupera lista usuários Protheus
JsonTool(aCabUser,aUsers)

cUsersPrt := U_RetUsers()
ConOut("== Protheus ============================")
ConOut(cUsersPrt)
ConOut("========================================")

// Recupera Build do TOPConnect
cTopBuild := TCInternal(80)

// Recupera lista de Threads Ativas ( Usuarios ) 
cThreadLst  := TCInternal(82)

While !Empty(cThreadLst)
    nPosVirg    := at(",",cThreadLst)
    if nPosVirg > 0
        cThreadUser := SubStr(cThreadLst,1,nPosVirg-1)
        cThreadLst  := SubStr(cThreadLst,at(",",cThreadLst)+1)
    Else
        cThreadUser := cThreadLst
        cThreadLst := ''
    EndIf
    AADD(aListUser,{cThreadUser,""})
EndDo
VarInfo("Lista Threads -- ANTES",aListUser)

For _nCnt := 1 to Len(aListUser)
    cUserInfo := TCInternal(91,aListUser[_nCnt,1])
    cMsgUser := '{'
    cMsgUser += '"ID":"'            + ExtraiTAG(cUserInfo,'id') + '",'
    cMsgUser += '"USR_PRT":"'       + ExtraiTAG(cUserInfo,'username') + '",'
    cMsgUser += '"IOS":"'           + ExtraiTAG(cUserInfo,'iocount') + '",'
    cMsgUser += '"TABELAS":"'       + ExtraiTAG(cUserInfo,'currentopentables') + '",'
    // cMsgUser += '"COMENTARIO":"'    + ExtraiTAG(cUserInfo,'comment') + '",'
    cMsgUser += '"PROCEDURE":"'     + ExtraiTAG(cUserInfo,'inprocedure') + '",'
    cMsgUser += '"AMBIENTE":"'      + ExtraiTAG(cUserInfo,'dbenv') + '",'
    cMsgUser += '"DBTHREAD":"'      + ExtraiTAG(cUserInfo,'dbthreadid') + '",'
    // cMsgUser += '"START":"'         + ExtraiTAG(cUserInfo,'start') + '",'
    cMsgUser += '"IPORIGEM":"'      + ExtraiTAG(cUserInfo,'sourceip') + '",'
    cMsgUser += '"EMTRANSACAO":"'   + ExtraiTAG(cUserInfo,'intransaction') + '"'
    cMsgUser += '}'
   
    // Release 20120705 recebe uma thread como parametro, retorna TODAS as informações sobre ela
    aListUser[_nCnt,2] := cMsgUser

Next

VarInfo("Lista Threads -- DEPOIS",aListUser)

cMsgJson := '{"TOP": {"BUILD":"' + cTopBuild +'",'
cMsgJson += '"THREADS":['
For _nCnt :=1 to Len(aListUser)
    cMsgJson += aListUser[_nCnt][2]
    If _nCnt < Len(aListUser)
        cMsgJson += ","
    EndIf
Next
cMsgJson += ']}}'

ConOut("== JSON ============================")
ConOut(cMsgJson)
ConOut("====================================")

Return Nil

Static Function JsonTool(aCabUser,aDet)
local nLin,nCol,cAjuste     // variaveis do FOR para tirar warning de compilação
local cJSONRet              // JSON de Retorno
Local _cPortaSrv := GetPvProfString("TCP", "Port", "undefined", "appserver.ini")	   	// pega a porta do servico do Protheus
local cOrigem    := '{"SOURCE":[{"IPSERVER" : "' + GetServerIP() + '"},{"PORT" : "' + _cPortaSrv + '"},{"TIME":"' + Time() + '"}]}'
local cJSON      := '{"USERLIST": ['

For nLin := 1 To Len( aDet )
    cJSON += "{"
    For nCol := 1 To Len( aCab )
        If ValType(aDet[nLin][nCol]) = "C"
            cAjuste := aDet[nLin][nCol]
            If At(CHR(10),cAjuste) > 0
                cAjuste := StrTran(cAjuste,chr(10),'')
            Endif
            cAjuste := StrTran(cAjuste,"\","\\")
            cConteudo := '"' + cAjuste + '"'
        ElseIf ValType(aDet[nLin][nCol]) = "N"
            cConteudo := AllTrim(Str(aDet[nLin][nCol]))
        ElseIf ValType(aDet[nLin][nCol]) = "D"
            cConteudo := '"' + DTOC(aDet[nLin][nCol]) + '"'
        ElseIf ValType(aDet[nLin][nCol]) = "L"
            cConteudo := IF(aDet[nLin][nCol], '"true"' , '"false"')
        Else
            cConteudo := '"' + aDet[nLin][nCol] + '"'
        EndIf               
        cJSON += '"' + aCab[nCol] + '":' + cConteudo
        If nCol < Len(aCab)
            cJSON += ","
        EndIf
    Next
    cJSON += "}"
    If nLin < Len(aDet)
        cJSON += ","
    EndIf
Next
cJSON += "]}"
cJSONRet := '{"USERS":[' + cOrigem + ',' + cJSON + ']}'

Return(cJSONRet)

Static Function ExtraiTAG(cMsgTag,cTag)
Local cRetMsg,cMsgTmp,nPosIni,nPosFim
Local nLenTag := Len(cTag)

nPosIni := at(cTag,cMsgTag) + nLenTag + 1   // soma 1 para sair do caracter ">"
cMsgTmp := SubStr(cMsgTag,nPosIni)
nPosFim := at("<",cMsgTmp) - 1              // retira 1 para sair do caracter "<"
cRetMsg := SubStr(cMsgTag,nPosIni,nPosFim)

Return cRetMsg