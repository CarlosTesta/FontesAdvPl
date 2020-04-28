#include "protheus.ch"
#include "TBICONN.CH"
#include "TOPCONN.CH"
// #INCLUDE "TOTVS.CH"
// #INCLUDE "XMLCSVCS.CH"

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

User Function NewList()
Local cJSONRet,nLin,nCol,cInfoSrv,nPosEsp
Local cJSON := ''
Local aUsersLst :=  GetUserInfoArray()
Local aCabUser  := {"USER_SO","ESTACAO","ID","SERVIDOR","PROGRAMA","ENVIRONMENT","START","TEMPO_CONEXAO","N_INSTR_SEC","N_INSTR","OBS","MEMORIA","SID"}
Local cEmpConn  := GetPvProfString("STERNA","EMPRESA","undefined","appserver.ini")
Local cFilConn  := GetPvProfString("STERNA","FILIAL","undefined","appserver.ini")

RPCSetType(3)
// PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "CFG"    // Empresa TESTE
PREPARE ENVIRONMENT EMPRESA cEmpConn FILIAL cFilConn MODULO "CFG"

For nLin := 1 To Len( aUsersLst )
    cJSON += "{"
    For nCol := 1 To Len( aCabUser )
        If ValType(aUsersLst[nLin][nCol]) = "C"
            cAjuste := aUsersLst[nLin][nCol]
            If At('  ',cAjuste) > 0     // retirar espaços duplicados 
                nPosEsp := At('  ',cAjuste)
                While nPosEsp > 0
                    cAjuste := StrTran(cAjuste,'  ',' ')
                    nPosEsp := At('  ',cAjuste)
                EndDo
            Endif
            cAjuste := StrTran(cAjuste,"\","\\")
            cAjuste := StrTran(cAjuste,CHR(10),"")
            cConteudo := '"' + cAjuste + '"'
        ElseIf ValType(aUsersLst[nLin][nCol]) = "N"
            cConteudo := AllTrim(Str(aUsersLst[nLin][nCol]))
        ElseIf ValType(aUsersLst[nLin][nCol]) = "D"
            cConteudo := '"' + DTOC(aUsersLst[nLin][nCol]) + '"' 
        ElseIf ValType(aUsersLst[nLin][nCol]) = "L"
            cConteudo := IF(aUsersLst[nLin][nCol], '"true"' , '"false"')
        Else
            cConteudo := '"' + aUsersLst[nLin][nCol] + '"'
        EndIf               
        cJSON += '"' + aCabUser[nCol] + '":' + cConteudo + ","
        If nCol == Len(aCabUser)    // após ultimo campo do monitor protheus, acrescenta dados do TopMonitor
            cConteudo := StrTran(cConteudo,'"','')
            // cJSON  += ","       // acrescenta virgula antes de inserir novo bloco de dados
            If !Empty(cConteudo)
                cUserInfo := TCInternal(91,cConteudo)
                cJSON  += '"USER_PRT":"'      + ExtraiTAG(cUserInfo,'username') + '",'
                cJSON  += '"IOS":"'           + ExtraiTAG(cUserInfo,'iocount') + '",'
                cJSON  += '"TABELAS":"'       + ExtraiTAG(cUserInfo,'currentopentables') + '",'
                cJSON  += '"PROCEDURE":"'     + ExtraiTAG(cUserInfo,'inprocedure') + '",'
                cJSON  += '"AMBIENTE":"'      + ExtraiTAG(cUserInfo,'dbenv') + '",'
                cJSON  += '"DBTHREAD":"'      + ExtraiTAG(cUserInfo,'dbthreadid') + '",'
                cJSON  += '"IPORIGEM":"'      + ExtraiTAG(cUserInfo,'sourceip') + '",'
                cJSON  += '"EMTRANSACAO":"'   + ExtraiTAG(cUserInfo,'intransaction') + '"'
            Else
                cJSON  += '"USER_PRT":"",'
                cJSON  += '"IOS":"",'
                cJSON  += '"TABELAS":"",'
                cJSON  += '"PROCEDURE":"",'
                cJSON  += '"AMBIENTE":"",'
                cJSON  += '"DBTHREAD":"",'
                cJSON  += '"IPORIGEM":"",'
                cJSON  += '"EMTRANSACAO":""'
            EndIf
        EndIf
    Next
    cJSON += "}"
    If nLin < Len(aUsersLst)
        cJSON += ","
    EndIf
Next

cInfoSrv := '{"IPSERVER":"' + GetServerIP() + '"},{"TIME":"' + Time() + '"},{"TOPBUILD":"' + TCInternal(80) + '"}'
cJSONRet := '{"USERSLIST":{"CONNECTION":[' + cInfoSrv + '],"USERS":[' + cJSON + ']}}'

// ConOut("== cJSONRet ============================")
// ConOut(cJSONRet)
// ConOut("== cJSONRet ============================")

SendJson(cJSONRet)

RESET ENVIRONMENT

Return Nil

Static Function ExtraiTAG(cMsgTag,cTag)
Local cRetMsg,cMsgTmp,nPosIni,nPosFim
Local nLenTag := Len(cTag)

nPosIni := at(cTag,cMsgTag) + nLenTag + 1   // soma 1 para sair do caracter ">"
cMsgTmp := SubStr(cMsgTag,nPosIni)
nPosFim := at("<",cMsgTmp) - 1              // retira 1 para sair do caracter "<"
cRetMsg := SubStr(cMsgTag,nPosIni,nPosFim)

Return cRetMsg

Static Function SendJson(cJSONRet)
Local oObj      := tSocketClient():New()
Local cIp       := GetPvProfString("STERNA","01ECIPSRV","undefined","appserver.ini")
Local nPorta    := Val(GetPvProfString("STERNA","01ECPORT","undefined","appserver.ini"))
Local nResp     := oObj:Connect( nPorta,cIp,50 )
Local cHttpPost := ""// Monta pacote de requisição HTTP básico

// --------------------------------------
// Verifica se a conexão foi bem sucedida
// --------------------------------------
if( !oObj:IsConnected() )
    conout("ADVPL ==> Falha na conexão")
    return
else
    ConOut("ADVPL ==> Conexão OK")

    cHttpPost += "POST /?OPC=USERSLIST HTTP/1.1" + CRLF
    cHttpPost += "Content-Type: html/text" + CRLF
    cHttpPost += "Connection: localhost" + CRLF
    cHttpPost += "Content-Length: " + cValToChar(Len(cJSONRet)) + CRLF
    cHttpPost += 'User-Agent: Mozilla/4.0 (compatible)' +CRLF+CRLF
    cHttpPost += cJSONRet

    nResp := oObj:Send( cHttpPost )

    If ( nResp != len( cHttpPost ) )              
        conout( "ADVPL ==> Erro! Dado não transmitido" )
    Else
        conout( "ADVPL ==> Dado Enviado - Retorno: " +StrZero(nResp,5) )
    EndIf
    
    oObj:CloseConnection()

endif


Return

