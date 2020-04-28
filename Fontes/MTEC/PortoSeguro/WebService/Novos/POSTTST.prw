#include "protheus.ch"
#include "TBICONN.ch"
#include "TOPCONN.ch"
#include "aarray.ch"
#include "totvs.ch"

#DEFINE CRLF CHR(13) + CHR(10)

user function POSTTST()
	Local aArea := {}
	Local aParam := {}
	Local aPergs := {}
	Local aExcel := nil

	RpcSetType( 3 )
	PREPARE ENVIRONMENT EMPRESA "T1" FILIAL "D MG 01 " MODULO "FAT"

	aArea := GetArea()

	AAdd(aPergs, {1,'Máximo de registros',60,"","","","",50,.T.})
	AAdd(aPergs, {2,"Tipo Post","1",{"1=Sale MundiPagg","2=Post Apiary"},80,"",.T.})

	if !Parambox(aPergs, "Tentativas de Post", @aParam)
		Msgalert("Rotina cancelada pelo usuário.", "Tentativas de Post")
		RestArea(aArea)
		Return
	endIf

	if aParam[2] == "1"
		Processa({|| aExcel := POSTMUNDI(aParam[1])}, "Teste stress REST Post - MundiPagg", "Executando posts de teste. Aguarde...", .t.)
	else
		Processa({|| aExcel := POSTAPIARY(aParam[1])}, "Teste stress REST Post - Apiary", "Executando posts de teste. Aguarde...", .t.)
	endIf

	if ValType(aExcel) != "A"
		MsgAlert("Nenhum resultado foi processado para os parâmetros informados.", "Execução do QueryOrder")
		RestArea(aArea)
		Return
	endIf

	if MsgYesNo("Deseja exportar o resultado do processamento para uma planilha em excel?","Confirmação")
		FWMsgRun(, {|| u_GridExcel({"Tentativa","Resultado","Descritivo"}, aExcel, "Teste stress REST Post", "RESULTADO", "TesteStressRestPost",)}, "Resultado para Excel", "Aguarde a extração do resultado do teste para planilha...")
	endIf

	RestArea(aArea)
	RESET ENVIRONMENT

	Return

return

Static Function POSTMUNDI(nQtd)
	Local aExcel := {}
	Local aHeader := {}
	Local aRet := {}
	Local cJson := ""
	Local cOrderRef := ""
	Local cRet := ""
	Local nCont := 0
	Local nx := 0
	Local aJson := nil
	Local oRet := nil
	Local oMundi := MundiPaggOne():New()

	Default nQtd := 60

	ProcRegua(nQtd)

	for nx := 1 to nQtd
		IncProc()

		cRet := ""
		oRet := nil
		aJson := nil

		aJson := Array(#)

		aJson[#'CreditCardTransactionCollection'] := Array(1)
		aJson[#'CreditCardTransactionCollection'][1] := Array(#)
		aJson[#'CreditCardTransactionCollection'][1][#'AmountInCents'] := Randomize(100,199999)
		aJson[#'CreditCardTransactionCollection'][1][#'CreditCard'] := Array(#)
		aJson[#'CreditCardTransactionCollection'][1][#'CreditCard'][#'CreditCardBrand'] := iif(Mod(10,nx) == 0, "Mastercard","Visa")
		aJson[#'CreditCardTransactionCollection'][1][#'CreditCard'][#'CreditCardNumber'] := "4716846827800023"
		aJson[#'CreditCardTransactionCollection'][1][#'CreditCard'][#'ExpMonth'] := Randomize(1,12)
		aJson[#'CreditCardTransactionCollection'][1][#'CreditCard'][#'ExpYear'] := Randomize(19,30)
		aJson[#'CreditCardTransactionCollection'][1][#'CreditCard'][#'HolderName'] := "CLIENTE PADRAO"
		aJson[#'CreditCardTransactionCollection'][1][#'CreditCard'][#'SecurityCode'] := cValToChar(Randomize(111,300))
		aJson[#'CreditCardTransactionCollection'][1][#'CreditCardOperation'] := "AuthOnly"
		aJson[#'CreditCardTransactionCollection'][1][#'InstallmentCount'] := Randomize(1,4)
		aJson[#'Order'] := Array(#)

		cOrderRef := "TST" + cValToChar(Randomize(1,300))

		aJson[#'Order'][#'OrderReference'] := cOrderRef

		cJson := ToJson(aJson)

		AAdd(aHeader, 'Accept: application/json')
		AAdd(aHeader, 'Accept-Charset: UTF8')
		AAdd(aHeader, 'Content-type: application/json')
		AAdd(aHeader, 'MerchantKey: ' + oMundi:MerchantKey)

		oPost := FWRest():New(oMundi:Url)
		oPost:SetPath(oMundi:SalePath)
		oPost:SetPostParams(cJson)

		if oPost:Post(aHeader)
			aRet := u_mpggrvhis(oPost:cResult,cOrderRef)
		else
			if Empty(oPost:cResult)
				aRet := u_mpggrvhis(oPost:GetLastError(),cOrderRef)
			else
				aRet := u_mpggrvhis(oPost:cResult,cOrderRef)
			endif
		endif

		if Len(aRet) != 3
			AAdd(aExcel, {nx, "Negativo", "Retorno incorreto da gravação de histórico MundiPagg."})
			Loop
		endIf

		if !FWJsonDeserialize(aRet[2],@oRet)
			AAdd(aExcel, {nx, "Negativo", "Erro ao compatibilizar o retorno da gravação de histórico MundiPagg."})
			Loop
		endIf

		if ValType(oRet) != "O"
			AAdd(aExcel, {nx, "Negativo", "Retorno incorreto da Mundipagg."})
			Loop
		endIf

		if !AttIsMemberOf(oRet, "RETMP")
			AAdd(aExcel, {nx, "Negativo", "Retorno incorreto da Mundipagg."})
			Loop
		endIf

		oRet := oRet:RETMP

		for nCont := 1 to len(oRet)
			do case
				case AttIsMemberOf(oRet[nCont],"_CCSTAT")
					cRet += oRet[nCont]:_ACQRET:TagName + ": " + oRet[nCont]:_ACQRET:Value + CRLF
					cRet += oRet[nCont]:_ACQMSG:TagName + ": " + oRet[nCont]:_ACQMSG:Value + CRLF
					cRet += oRet[nCont]:_AUTHCD:TagName + ": " + oRet[nCont]:_AUTHCD:Value + CRLF
					cRet += oRet[nCont]:_CCSTAT:TagName + ": " + oRet[nCont]:_CCSTAT:Value + CRLF
					cRet += oRet[nCont]:_MCC:TagName + ": " + oRet[nCont]:_MCC:Value + CRLF
					AAdd(aExcel, {nx,"Positivo", cRet})

				case AttIsMemberOf(oRet[nCont], "_ERROR")
					cRet += "Erro na autorização: " + oRet[nCont]:_ERRORCODE + " - " + oRet[nCont]:_ERROR + CRLF
					AAdd(aExcel, {nx,"Negativo", cRet})

				otherwise
					AAdd(aExcel, {nx, "Negativo", "Retorno com propriedade não esperada pela rotina."})
					Loop
			endcase
		next
	next

Return aExcel


Static Function POSTAPIARY(nQtd)
	Local aExcel := {}
	Local aHeader := {}
	Local cJson := ""
	Local cRet := ""
	Local nx := 0
	Local aJson := nil
	Local oPost := nil

	Default nQtd := 60

	ProcRegua(nQtd)

	for nx := 1 to nQtd
		IncProc()

		aJson := Array(#)

		aJson[#'question'] := "Favourite programming language?"
		aJson[#'choices'] := Array(4)
		aJson[#'choices'][1] := "Swift"
		aJson[#'choices'][2] := "Python"
		aJson[#'choices'][3] := "Objective-C"
		aJson[#'choices'][4] := "Ruby"

		cJson := ToJson(aJson)

		if Empty(cJson)
			MsgStop("Não foi possível gerar o request.","Teste de Post")
			Return
		endif

		AAdd(aHeader, 'Content-type: application/json')
		AAdd(aHeader, 'Location: /questions/2')

		oPost := FWRest():New("http://polls.apiblueprint.org")
		oPost:SetPath("/questions")

		if oPost:Post(aHeader)
			cRet := oPost:cResult
			AAdd(aExcel, {nx, "Positivo", cRet})
		else
			cRet := oPost:cResult
			if Empty(cRet)
				cRet := oPost:GetLastError()
			endif
			AAdd(aExcel, {nx, "Negativo", cRet})
		endif
	next

Return aExcel