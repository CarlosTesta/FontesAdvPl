User Function RunTCPSrv()
Local cErrMsg		:= ''
Local oSockSrv	:= tSocketSrv():New()
Local nBuffer		:= 1000
Local nRet			:= 0
Local nSend		:= 0
Local nPort		:= 9001

// como ja tenho dados nas tabelas, nao preciso me preocupar neste momento com a comunicacao
// verificar depois se o comportamento vai ser o esperado
conout("Entrou Requisição"+Time())
If !oSockSrv:StartTcp(nPort)
	nErrCode := oSockSrv:GetError(@cErrMsg)
	conout("STARTTCP FAILED ("+cErrMsg+")")
	return
Else
	conout("TCP Server no AR....")
EndIf
                                   
cOutBuffer := "HTTP/1.1 200 OK" + Chr(13) + Chr(10)
cOutBuffer += "Connection: keep-alive" + Chr(13) + Chr(10) 
cOutBuffer += "Access-Control-Allow-Origin: 172.16.70.70:9001" + Chr(13) + Chr(10) + Chr(13) + Chr(10)

While (!killapp())
	cInBuffer := space(nBuffer)
	oObjConn := oSockSrv:Accept( 0 )
	If oObjConn == NIL
		conout("ACCEPT FAILED ("+cErrMsg+")")
		Return
	Endif
	nRet		:= oObjConn:Receive(cInBuffer, nBuffer)
	cInBuffer	:= AllTrim(cInBuffer)
	
	nSend := oObjConn:Send(cOutBuffer,Len(cOutBuffer))
	
	oObjConn:Close()
	oObjConn := nil
	
EndDo

Return Nil