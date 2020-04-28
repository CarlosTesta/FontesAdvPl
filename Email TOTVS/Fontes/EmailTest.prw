#Include "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#Include "PROTHEUS.CH"
#INCLUDE 'TBICONN.CH'


User Function EmailTest()
Local nCnt

//RPCSetType(3)
//PREPARE ENVIRONMENT EMPRESA 'T1' FILIAL 'D MG 01 ' MODULO 'FAT'

conout("")
conout("===============================================")
conout("INICIO StartJOB" + Time())
For nCnt:=1 to 2
	//StartJOB("U_MyImpress",getenvserver(),.F.,AlLTrim(StrZero(nCnt,2)),50,Date())
	StartJOB("U_OneTurn",getenvserver(),.F.,"Job"+AllTrim(Str(nCnt)),10)
Next
conout("FINAL StartJOB" + Time())
conout("===============================================")
conout("")

//RESET ENVIRONMENT

Return


// chamada unica fora do JOB de Volume de Testes
User Function OneTurn(cRef,nQtd)
Default cRef := "500"
Default nQtd := 50

RPCSetType(3)
PREPARE ENVIRONMENT EMPRESA 'T1' FILIAL 'D MG 01 ' MODULO 'FAT'

conout("cRef >>>>>>" + cRef)
U_MyImpress(cRef,nQtd,CTOD("2017/06/14"))

RESET ENVIRONMENT

Return

User Function MyImpress(cRef,nQtd,ddatabase)
Local nCntRel
Local oMail
Local oMessage
Local nX
Local i 			:= 0
Local aCoords5 		:= {2190,1900,2290,2300} 	// FICHA DE COMPENSACAO
Local aCoords6 		:= {2460,1900,2530,2300} 	// FICHA DE COMPENSACAO
Local nStatus 		:= -1
Local cBody			:= ""
Local nSequencia	:= 0
Local cAnexos 		:= ""
Local lOk 			:= .T.
Local cTo			:= ""
Local cCC			:= ""
Local cLocalSpool	:= "\spool\boletos2\"
Local nErro			:= 0
Local nVlrMulta1 	:= 0
Local nVlrTotal1 	:= 0
Local aFonts		:= {} 
Local oFont7n		:= TFont():New("Arial",9,7 ,.T.,.T.,5,.T.,5,.T.,.F.)
Local oFont8  		:= TFont():New("Arial",9,8 ,.T.,.F.,5,.T.,5,.T.,.F.)
Local oFont8n 		:= TFont():New("Arial",9,8 ,.T.,.T.,5,.T.,5,.T.,.F.)
Local oFont10 		:= TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
Local oFont12 		:= TFont():New("Arial",9,12,.T.,.F.,5,.T.,5,.T.,.F.)
Local oFont12n		:= TFont():New("Arial",9,12,.T.,.T.,5,.T.,5,.T.,.F.)
Local oFont14		:= TFont():New("Arial",9,14,.T.,.T.,5,.T.,5,.T.,.F.)
Local oFont14n		:= TFont():New("Arial",9,13,.T.,.F.,5,.T.,5,.T.,.F.)
Local oFont16 		:= TFont():New("Arial",9,16,.T.,.T.,5,.T.,5,.T.,.F.)
Local oFont16n		:= TFont():New("Arial",9,16,.T.,.F.,5,.T.,5,.T.,.F.)
Local oFont20 		:= TFont():New("Arial",9,20,.T.,.T.,5,.T.,5,.T.,.F.)
Local oFont24 		:= TFont():New("Arial",9,24,.T.,.T.,5,.T.,5,.T.,.F.)
Local oBrush 		:= TBrush():New(,CLR_HGRAY,,)		//fundo no valor do titulo

Private oPrint
Private oPrintSetup

FERASE(cLocalSpool+"Bol"+cRef+".pdf")

//(cFilePrint, nDevice, lAdjustToLegacy, cPathInServer, lDisableSetup, lTReport, oPrintSetup, cPrinter, lServer, lPDFAsPNG, lRaw, lViewPDF, nQtdCopy, lConvertFont) Class FWMSPrinter
oPrint:= FWMSPrinter():New("Bol"+cRef+".pdf",IMP_PDF,.T.,cLocalSpool, .T., .F., Nil, Nil, .F., .F., .F., .F., , .F., )
oPrint:SetPortrait() // ou SetLandscape()
oPrint:SetPaperSize(0,297,210)
clSetup := oPrint:setDevice(IMP_PDF)

AADD(aFonts,{oFont7n,oFont8,oFont8n,oFont10,oFont12n,oFont14,oFont14n,oFont16,oFont16n,oFont20,oFont24,oFont12})

conout("")
conout("")
conout("---------------------------------")
conout("INICIO >>" + time())
For nCntRel := 1 to nQtd
	CriaPage(aFonts,oPrint,clSetup,nCntRel,oBrush,aCoords5,aCoords6,cRef)
Next
conout("FINAL >>" + time())
conout("---------------------------------")
conout("")
conout("")

///*
cFilePrint := cLocalSpool+"boleto.PD_"
File2Printer( cFilePrint, "PDF" )
oPrint:cPathPDF:= cLocalSpool
//*/

oPrint:Preview()
oPrint:ResetPrinter()

//oPrint:End()		// termina a geração
//oPrint:Print()

Return

Static Function CriaPage(aFonts,oPrint,clSetup,nCntRel,oBrush,aCoords5,aCoords6,cRef) 
Local aEventos := {}
Local nVlrSeg  := 0

oPrint:StartPage()   // Inicia uma nova página
oPrint:Say(050,100,"Página " + AllTrim(Str(nCntRel)) + " | INÍCIO >> " + Time(),aFonts[1][12])

AADD(aEventos,{"JOB <<" + cRef + ">> | BOLETO " +AllTrim(STRZero(nCntRel,4)) ,1000})
AADD(aEventos,{"BOLSA DE ENSINO",-120})
AADD(aEventos,{"AUX. FIN. DE ENSINO",-50})
AADD(aEventos,{"DESCONTO DE ENSINO",-15})
AADD(aEventos,{"VALOR LIQUIDO DE ENSINO",1000})
AADD(aEventos,{"Seguro : ",30})

//Ficha do Caixa
oPrint:FillRect({150,1900,260,2300},oBrush)
oPrint:FillRect({260,1900,370,2300},oBrush)

oPrint:Line (260, 1150,1700,1150)
oPrint:Line (150, 2300,2000,2300)

//Linhas Horizontais
oPrint:Line ( 150, 100, 150,2300)
oPrint:Line ( 260, 100, 260,2300)
oPrint:Line ( 370, 100, 370,2300)
oPrint:Line ( 480, 100, 480,2300)

oPrint:Line (1700, 100,1700,2300)
oPrint:Line (1850, 100,1850,2300)
oPrint:Line (2000, 100,2000,2300)
oPrint:Line (2000, 100,2000,2300)

oPrint:SayBitmap( 060,150,"santander.jpg",300,070 )

For nX := 1 to 3
	oPrint:Line (080,660+nX, 150,660+nX )
Next

oPrint:Say  (085,920,"00190.00009 02597.731054 88909.730181 4 64540000034900",aFonts[1][6]) //linha digitavel

For nX := 1 to 3
	oPrint:Line (080,890+nX, 150,890+nX )
Next

oPrint:Say  ( 160, 110 ,"EU SOU A LENDA"    ,aFonts[1][2])
oPrint:Say  ( 200,110 ,"Banco SANTANDER | JOB <<" + cRef + ">> | Boleto <<" + AllTrim(Str(nCntRel)) + ">>",aFonts[1][5])

oPrint:Say  ( 160,1910 ,"VENCIMENTO" ,aFonts[1][2])
oPrint:Say  ( 200,2005,PadL(AllTrim(DTOC(date()+15)),16," "),aFonts[1][4])

oPrint:Say  ( 270, 120 ,"SACADO"    ,aFonts[1][2])
oPrint:Say  ( 310 ,120 ,"Fulano de Tal da Silva",aFonts[1][4])
oPrint:Say  ( 270, 1160 ,"N.DO DOCUMENTO"    ,aFonts[1][2])
oPrint:Say  ( 310 ,1220 ,"134654231654",aFonts[1][4])
oPrint:Say  ( 270, 1910 ,"VALOR DO DOCUMENTO"    ,aFonts[1][2])

AaDD(aEventos,{"SEILÁ",1000})
AaDD(aEventos,{"BOLSA DE ENSINO",-120})
AaDD(aEventos,{"AUX. FIN. DE ENSINO",-50})
AaDD(aEventos,{"DESCONTO DE ENSINO",-15})
AaDD(aEventos,{"VALOR LIQUIDO DE ENSINO",1000})
AADD(aEventos,{"Seguro : ",30})

nVlrTotal1 := 1000-(120+50+15)	// calculo simples
oPrint:Say  ( 310, 2010,PadL(AllTrim(Transform(nVlrTotal1,"@E 999,999,999.99")),16," "),aFonts[1][4])
oPrint:Say  ( 380, 120 ,"NOME DO ALUNO",aFonts[1][2])
oPrint:Say  ( 430 ,120 ,"Tospericagerja de Souza",aFonts[1][4])
oPrint:Say  ( 380, 1160 ,"COD. ALUNO",aFonts[1][2])
oPrint:Say  ( 430 ,1200 ,"197006",aFonts[1][5])

oPrint:Say  (  490, 250 ,"COMPOSIÇÃO DO TÍTULO",aFonts[1][12])
oPrint:Say  (  490, 1650 ,"PREÇO em R$",aFonts[1][12])
oPrint:Say  ( 1710, 110 ,"MENSAGEM",aFonts[1][1])
oPrint:Say  (1860,1850,"- Autentica o Mecânica -",aFonts[1][1])

If Len(aEventos) > 0
	nLin := 550
	For nX := 1 to Len(aEventos)
		oPrint:Say  (nLin, 120,aEventos[nX,1],aFonts[1][2] )
		oPrint:Say  (nLin, 950,PadL(Alltrim(Transform(aEventos[nX,2],"@e 999,999,999.99")),14),aFonts[1][2])
		nLin += 40
	Next
EndIf

cMens := "Esta mensagem é somente para poder completar ainda mais a idéia de um boleto real" 
oPrint:Say  (nLin, 1160,"Mensagem Padrão",aFonts[1][2] )
oPrint:Say  (nLin, 2050,PadL(Alltrim(Transform(185,"@e 999,999,999.99")),14),aFonts[1][2])

///////////////
//Gambiarra, descobrir como mudar tipo da linha.  PONTILHAMENTO
For i := 100 to 2300 step 30
	oPrint:Line( 2050, i, 2050, i+20)
	oPrint:Line( 2051, i, 2051, i+20)
	oPrint:Line( 2051, i, 2051, i+20)
Next i

//Ficha de Compensacao
oPrint:FillRect(aCoords5,oBrush)
oPrint:FillRect(aCoords6,oBrush)

oPrint:Line (2190,100,2190,2300)
oPrint:Line (2190,650,2190,650 )
oPrint:Line (2190,900,2190,900 )

oPrint:SayBitmap( 2090,100,"santander.jpg",500,90 )

For nX := 1 to 3
	oPrint:Line (2100,660+nX,2190,660+nX )
Next

For nX := 1 to 3
	oPrint:Line (2100,890+nX,2190,890+nX )
Next

oPrint:Say  (2124,920,"00190.00009 02597.731054 88909.730181 4 64540000034900",aFonts[1][6]) //linha digitavel

oPrint:Line (2290,100,2290,2300 )
oPrint:Line (2390,100,2390,2300 )
oPrint:Line (2460,100,2460,2300 )
oPrint:Line (2530,100,2530,2300 )

oPrint:Line (2390,500,2530,500)
oPrint:Line (2460,750,2530,750)
oPrint:Line (2390,1000,2530,1000)
oPrint:Line (2390,1350,2460,1350)
oPrint:Line (2390,1550,2530,1550)

oPrint:Say  (2190,100 ,"Local de Pagamento",aFonts[1][2])
oPrint:Say  (2230,100 ,"Pagável em qualquer agência bancácia até o vencimento",aFonts[1][4])
oPrint:Say  (2190,1910,"Vencimento",aFonts[1][2])
oPrint:Say  (2230,2005,PadL(AllTrim(DTOC(date())),16," "),aFonts[1][4])
oPrint:Say  (2290,100 ,"Cedente",aFonts[1][2])
oPrint:Say  (2330,100 ,"Banco SANTANDER / Boleto" + AllTrim(Str(nCntRel)),aFonts[1][4])
oPrint:Say  (2290,1910,"Agência/Código Cedente",aFonts[1][2])

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
oPrint:Say  (2330,2010,PadL("8536"+"/"+"123456",16),aFonts[1][4])
oPrint:Say  (2390,100 ,"Data do Documento",aFonts[1][2])
oPrint:Say  (2420,100 ,DTOC(Date()),aFonts[1][4])

oPrint:Say  (2390,505 ,"Nro.Documento",aFonts[1][2])
oPrint:Say  (2420,605 ,"123456789",aFonts[1][4])

oPrint:Say  (2390,1005,"Espécie Doc.",aFonts[1][2])
oPrint:Say  (2420,1105,"DS"                                             ,aFonts[1][4])

oPrint:Say  (2390,1355,"Aceite"                                         ,aFonts[1][2])
oPrint:Say  (2420,1455,"N"                                             ,aFonts[1][4])

oPrint:Say  (2390,1555,"Data do Processamento"                          ,aFonts[1][2])
oPrint:Say  (2420,1655,DTOC(Date()-15)                            	,aFonts[1][4])

oPrint:Say  (2390,1910,"Nosso Número"                                   ,aFonts[1][2])
oPrint:Say  (2420,2000,"123456789"                            	,aFonts[1][4])

oPrint:Say  (2460,100 ,"Uso do Banco"                                   ,aFonts[1][2])

oPrint:Say  (2460,505 ,"Carteira"                                       ,aFonts[1][2])
oPrint:Say  (2490,555 ,"Não tenho idéia"           										,aFonts[1][4])

oPrint:Say  (2460,755 ,"Espécie"                                        			,aFonts[1][2])
oPrint:Say  (2490,805 ,"R$"                                             			,aFonts[1][4])

oPrint:Say  (2460,1005,"Quantidade"                                     		,aFonts[1][2])
oPrint:Say  (2460,1555,"Valor"                                          			,aFonts[1][2])

oPrint:Say  (2460,1910,"(=)Valor do Documento"                         	,aFonts[1][2])
oPrint:Say  (2490,2010,PadL(AllTrim(Transform(1000,"@E 999,999,999.99")),16," "),aFonts[1][4])

oPrint:Say  (2530,100 ,"Instruções/Texto de responsabilidade do cedente",aFonts[1][2])

oPrint:Say  (2580,100 ,"Instrução 1"                                      ,aFonts[1][4])
oPrint:Say  (2630,100 ,"APOS O VENCIMENTO COBRAR JUROS DE 1% A.M.",aFonts[1][4])
oPrint:Say  (2680,100 ,"Instrução 3"                                      ,aFonts[1][4])
oPrint:Say  (2730,100 ,"Atualiza o de boleto vencido acesse:  ",aFonts[1][4],,CLR_HRED)
oPrint:Say  (2780,100 ,"www.santander.com.br/boletos   ",aFonts[1][4],,CLR_HRED)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

oPrint:Say  (2530,1910,"(-)Desconto/Abatimento"                         ,aFonts[1][2])
oPrint:Say  (2600,1910,"(-)Outras Deduções"                             ,aFonts[1][2])
oPrint:Say  (2630,2010,PadL(AllTrim(Transform(0,"@E 999,999,999.99")),16," "),aFonts[1][4])
oPrint:Say  (2670,1910,"(+)Mora/Multa"                                  ,aFonts[1][2])

//acrescentar as multas aqui
oPrint:Say  (2700,2020,PadL(AllTrim(Transform(0,"@E 999,999,999.99")),16," ")                                  ,aFonts[1][4])
oPrint:Say  (2740,1910,"(+)Outros Acréscimos"                           ,aFonts[1][2])
oPrint:Say  (2810,1910,"(=)Valor Cobrado"                               ,aFonts[1][2])
oPrint:Say  (2840,2010,PadL(AllTrim(Transform(0,"@E 999,999,999.99")),16," ")                                  ,aFonts[1][4])

oPrint:Say  (2880,100 ,"Sacado"                                         ,aFonts[1][2])
oPrint:Say  (2908,210 ,"Fulano de Tal da Silva"             ,aFonts[1][2])
oPrint:Say  (2948,210 ,"Rua Taco Taco, 1234"                                    ,aFonts[1][2])
oPrint:Say  (2988,210 ,"CGC/CPF: "+AllTrim(Transform("12345645878","@R 999.999.999-99")) ,aFonts[1][2])

oPrint:Say  (2845,100 ,"Sacador/Avalista"                               ,aFonts[1][2])
oPrint:Say  (3030,1500,"Autentica o Mecânica"                        ,aFonts[1][2])
oPrint:Say  (3030,1850,"Ficha de Compensação"                           ,aFonts[1][4])

oPrint:Line (2190,1900,2880,1900 )
oPrint:Line (2600,1900,2600,2300 )
oPrint:Line (2670,1900,2670,2300 )
oPrint:Line (2740,1900,2740,2300 )
oPrint:Line (2810,1900,2810,2300 )
oPrint:Line (2880,100 ,2880,2300 )

oPrint:Line (3025,100,3025,2300  )

//MSBAR("INT25",26.28,1.2,"00190000090259773105488909730181464540000034900",oPrint,.F.,Nil,Nil,0.023,1.2,Nil,Nil,"A",.F.)
//oPrint:FWMSBAR("INT25",26.28,1.2,"00190000090259773105488909730181464540000034900",oPrint,.F.,Nil,Nil,0.023,1.2,Nil,Nil,"A",.F.)

oPrint:FWMSBAR("INT25",064,3,"00190000090259773105488909730181464540000034900",oPrint,.F.,Nil,Nil,0.023,1.2,Nil,Nil,"A",.F.)
oPrint:Say(3300,100,"Página " + AllTrim(Str(nCntRel)) + " | INÍCIO >> " + Time(),aFonts[1][12])

oPrint:EndPage()	// Finaliza a página

Return Nil


Static Function CheckPdf( cLocalSpool )
Local nTent		:= 0
Local nArq		:= 0

While .T. .and. nTent <= 15
	If !file( cLocalSpool + "boleto.pdf" )
		Sleep(500)
		nTent ++
	Else
		nArq := fOpen( cLocalSpool + "boleto.pdf", 2 )
		if nArq < 0
			Sleep( 500 )
			nTent ++
			Loop
		Else
			fClose( nArq )
			nArq := -1
			Exit
		Endif
	Endif
End
If nArq > 0
	fClose( nArq )
Endif
Return Nil


Static Function SendMail(cFilename)
Local oMail // objeto eMail 
Local nStatus		:= -1
Local cAnexos		:= ""
Local aFiles		:= {}
Local x			:= 0
Local nErro		:= 0
Local cFrom		:= ""
Local cSubject	:= "Boleto Cobrança Graded School"
Local cTexto		:= ""
Local cDiretorio	:= "\Spool\boletos\"
Local cLocalSpool	:= "\Spool\boletos\"
Local cMail		:= "cristiano.lino@totvs.com.br" 
Local cFilename 	:= "boleto.pdf"
Local cMesRef		:=	Str(Month(DAte())) 
Local cAnoRef		:= Str(Year(DAte()))
Local cUserMail	:= "testa@totvs.com.br" 
Local cemailSent	:= "testa@totvs.com.br"
Local cSenhaMail	:= "S@giTTarius005"

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
If Right( cLocalSpool, 1 ) <> "\"
	cLocalSpool += "\"
Endif
cDiretorio := cLocalSpool

cTexto := "<html>"
cTexto += "<head>"
cTexto += " <title></title>"
cTexto += "</head>"
cTexto += "<body>"
cTexto += " <br>"
cTexto += '<font color="#000000" face="Arial">'
cTexto += " <br>"
cTexto += " <br>"
cTexto += "Dear Parents/Prezados Pais,<br><br>"
cTexto += "Enclosed please find the Graded School tuition bill for " + cAnoRef + "/" + cMesRef + ", which you may also have received through the regular mail.<br>"
cTexto += "Por favor, anexo boleto da mensalidade escolar de " + cMesRef + "/" + cAnoRef + ". Obs: Este mesmo boleto anexo ser?enviado tamb? por correio.<br><br>"

cTexto += '<font color="#0000FF" face="Arial">'
cTexto += "All payments should be made directly at the bank. Payments will not be allowed at Graded.<br>"
cTexto += "Este boleto dever?ser pago diretamente nas ag?cias banc?ias ou internet banking. N? recebemos pagamentos na Escola.<br><br>"

cTexto += '<font color="#000000" face="Arial">'
cTexto += "Lembramos que nos meses de Junho e Dezembro as mensalidades tem como vencimento o dia 15 e no m? de Julho o vencimento ?dia 01.<br>"
cTexto += "Please remind that every year in the months of June and December the due date is on the 15th and July is on the 1st.<br><br>"
cTexto += "Sincerely/Atenciosamente,<br><br>"
cTexto += "" + Alltrim(cUserMail) + "<br>"
cTexto += "Assoc.Escola Graduada de S.P.<br>"
cTexto += "" + Alltrim(cemailSent) + "<br>"
cTexto += "Fone : (11) 3747-4800 - Fax : (11) 3742-9358"
cTexto += "</body>"
cTexto += "</html>"

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
nStatus := -1
aFiles := Directory( cDiretorio + cFilename )

For X:= 1 to Len(aFiles)
	cAnexos += cDiretorio+aFiles[X,1]
Next X

oMail := TMailManager():New()
oMail:SetUseSSL(.T.)
oMail:Init( '','smtp.gmail.com',Alltrim(cemailSent),Alltrim(cSenhaMail),0,465 )
oMail:SetSmtpTimeOut( 120 )
nErro := oMail:SmtpConnect()
If nErro <> 0
	conout( "ERROR: Conectando - " + oMail:GetErrorString( nErro ) )
	oMail:SMTPDisconnect()
	return .F.
Endif
nErro := oMail:SmtpAuth(Alltrim(cemailSent) ,Alltrim(cSenhaMail))
If nErro <> 0
	conout( "ERROR:2 autenticando - " + oMail:GetErrorString( nErro ) )
	oMail:SMTPDisconnect()
	return .F.
Endif

oMessage 					:= TMailMessage():New()
oMessage:Clear()
oMessage:cFrom 			:= Alltrim(cemailSent)
oMessage:cTo	 			:= cMail
oMessage:cCc 				:= ""
oMessage:cSubject    	:= cSubject
oMessage:cBody 	    	:= cTexto
oMessage:MsgBodyType( "text/html" )

If oMessage:AttachFile(cAnexos ) < 0
	Conout( "Erro ao atachar o arquivo" )
Else
	oMessage:AddAtthTag( 'Content-Disposition: attachment; filename=' + cFileName)
End If

nErro := oMessage:Send( oMail )
oMail:SMTPDisconnect()

oMail 	:= Nil
oMessage := Nil

Return (nErro == 0)