#include 'protheus.ch'
#include 'parmtype.ch'

#define MYIPCJOB_ "MYIPC"
#define CONN_ "MYCONN"
#define CRLF chr(13) + chr(10)

user function RestCons()
local cOutBuffer,oJsonResponse,nBuffer
local cMsgSend		:= ''
local oObjConn		:= ''
local nResponse		:= '2'		// "1-txt/2-Json"
Local cJson			:= ''
Local oJson			:= tJsonParser():New()
Local aJsonfields	:= {}
Local xGet			:= Nil
Local cGet			:= Nil
Local oJHM			:= .F.

If nResponse == '1'
	cMsgSend := "TESTAO"
Else
	cJson := '{"Cliente":{'
    cJson += '            "CGC":"09534545848",'
    cJson += '            "Nome":"Leandro Heilig",'
    cJson += '            "Endereco":"rua santa izabel, 451",'
    cJson += '            "Cep":"07184120",'
    cJson += '            "estado":"SP",'
    cJson += '            "Municipio":"Guarulhos",'
    cJson += '            "Telefone":"24111293"'
    cJson += '            } }'
	cMsgSend := oJsonResponse
EndIf

oObjConn := GetTcpObj(cTCPIdx)

cInBuffer := space(nBuffer)
nRet		:= oObjConn:Receive(cInBuffer, nBuffer)
cInBuffer	:= AllTrim(cInBuffer)

cGet := ""
lRet := HMGet(oJHM, cGet, xGet)


cOutBuffer := "HTTP/1.1 200 OK"+CRLF
cOutBuffer += "Content-Type: text/html"+CRLF
cOutBuffer += "Hora " + TIME() + CRLF
cOutBuffer += "Content-Length: 6"+CRLF+CRLF
cOutBuffer += cMsgSend

nRetAll := len(cOutBuffer)

//conout(time() + " " + "["+cTCPId+"] " + "[SRV] TAM ENVIO: " + AllTrim(Str(nRetAll)) + " Byte(s) enviado(s)." + " [Thread " + AllTrim(Str(ThreadId())) + "]")
nRet := oObjConn:Send(cOutBuffer, nRetAll)
if nRet <= 0
	//conout(time() + " " + "["+cTCPId+"] " + "[SRV***][ERR] Erro ao enviar: " + AllTrim(Str(nRetAll)) + " [Thread " + AllTrim(Str(ThreadId())) + "]")
	//exit
Endif

oObjConn:close()
oObjConn := NIL

Return .T.

User Function MyUpSrv()
Local lSobeSrv	:= .T.
Local nSeq 		:= 0
Local nBuffer	:= 200
Local nRet		:= 0
Local cErrMsg	:= ''
Local nPort		:= 9001
Local oSockSrv	:= tSocketSrv():New()

// como ja tenho dados nas tabelas, nao preciso me preocupar neste momento com a comunicacao
// verificar depois se o comportamento vai ser o esperado

If !oSockSrv:StartTcp(nPort) .and. lSobeSrv
	nErrCode := oSockSrv:GetError(@cErrMsg)
	conout("STARTTCP FAILED ("+cErrMsg+")")
	return
Else
	conout("TCP Server no AR....")
	lSobeSrv := .F.
EndIf

While (!killapp())
	oObjConn := oSockSrv:Accept( 0 )
	If oObjConn == NIL
		conout("ACCEPT FAILED ("+cErrMsg+")")
		Return
	else
		cTCPIdx := "TCP_" + strzero(++nSeq,6)
		SetTcpObj(cTCPIdx, oObjConn)
		nRet = IpcGo(MYIPCJOB_,cTCPIdx)
	Endif
EndDo
Return .T.
