# INCLUDE "RPTDEF.CH"
# INCLUDE "FWPrintSetup.ch"
# Include "PROTHEUS.CH"
# Include "RWMAKE.CH"
# Include "RPTDEF.CH"
# INCLUDE "TBICONN.CH"

Function Iuspa_PDF()
Local oPrint
		/* Classe FWMsPrinter
			FWMsPrinter(): New ( < cFilePrintert >, [ nDevice], [ lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] ) --> oPrinter
        */

		oPrint:= FWMSPrinter():New(clNomArq, IMP_PDF,.T., "\spool", .T.,,,,,,, .F., )

		/*
		�1 - Letter   216mm x 279mm  637 x 823
		�3 - Tabloid  279mm x 432mm  823 x 1275
		�7 - Executive 184mm x 267mm  543 x 788
		�8 - A3     297mm x 420mm  876 x 1240
		�9 - A4     210mm x 297mm  620 x 876
		*/

		oPrint:SetPaperSize(0,297,210)
		clSetup := oPrint:setDevice(IMP_PDF)

		//oPrint:lInJob   := .T.
		//oPrint:Setup()
		//If oPrint:nModalResult == 1

		//oPrint:Setup()

			ImpBrad(oPrint,cBitMap,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,CB_RN_NN)
			n := n + 1

			oPrint:Print()
//			oPrint:Preview()     // Visualiza antes de imprimir

	        If oPrint:cPathPDF != clBkpPatch
		        clBkpPatch := oPrint:cPathPDF
	        EndIf

			FreeObj(oPrint)

			oPrint:= Nil

	   //	EndIF
	EndIf

	dbSelectArea("SE1")
	dbSkip()
	IncProc()
	i := i + 1
EndDo

//oPrint:EndPage()  	//Finaliza a p�gina
//oPrint:Setup()     	//Seta a Impressora
//oPrint:Preview() 	//Visualiza antes de imprimir

Return nil

/*
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
���������������������������������������������������������������������������Ŀ��
���FUNCAO    � ImpBrad  � Autor � Celio Oliveira        � Data � 19/09/2013 ���
���������������������������������������������������������������������������Ĵ��
���DESCRICAO � Impressao do boleto laser do Bradesco com codigo de barras   ���
���������������������������������������������������������������������������Ĵ��
���SINTAXE   � ImpBrad()                                                    ���
���������������������������������������������������������������������������Ĵ��
���PARAMETROS� Nenhum                                                       ���
���������������������������������������������������������������������������Ĵ��
���RETORNO   � Nenhum                                                       ���
���������������������������������������������������������������������������Ĵ��
��� USO      � Generico                                                     ���
����������������������������������������������������������������������������ٱ�
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
*/
Static Function ImpBrad(oPrint,cBitmap,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,CB_RN_NN)
Local oFont8
Local oFont10
Local oFont14n
Local oFont16
Local oFont16n
Local oFont24
Local i        := 0
Local cImpData := " "

Local aCoords1 := {0150,1900,0550,2300}
Local aCoords2 := {0450,1050,0550,1900}
Local aCoords3 := {0710,1900,0810,2300}
Local aCoords4 := {0980,1900,1050,2300}
Local aCoords5 := {1330,1900,1400,2300}
Local aCoords6 := {2000,1900,2100,2300}
Local aCoords7 := {2270,1900,2340,2300}
Local aCoords8 := {2620,1900,2690,2300}

Local oBrush

Local cStartPath := GetSrvProfString("StartPath","")
Local cBmp		 := ""

cStartPath	:= AllTrim(cStartPath)
If SubStr(cStartPath,Len(cStartPath),1) <> "\"
	cStartPath	+= "\"
EndIf
cBmp := cStartPath+"BRADESCO.bmp"  	//Logotipo

//Parametros de TFont.New()
//1.Nome da Fonte (Windows)
//3.Tamanho em Pixels
//5.Bold (T/F)
oFont8   := TFont():New("Arial",9,8 ,.T.,.F.,5,.T.,5,.T.,.F.)
oFont10  := TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
oFont14n := TFont():New("Arial",9,14,.T.,.F.,5,.T.,5,.T.,.F.)
oFont16  := TFont():New("Arial",9,16,.T.,.T.,5,.T.,5,.T.,.F.)
oFont16n := TFont():New("Arial",9,16,.T.,.F.,5,.T.,5,.T.,.F.)
oFont24  := TFont():New("Arial",9,24,.T.,.T.,5,.T.,5,.T.,.F.)

oBrush   := TBrush():New("",4)
oPrint:StartPage()   // Inicia uma nova pagina


// Inicia aqui
oPrint:Line (0150,550,0050, 550)
oPrint:Line (0150,800,0050, 800)

oPrint:SayBitMap(0084,100,cBitMap,0300,060)		// Logo do banco
//oPrint:Say  (0084,100,aDadosBanco[2],oFont14n)	// [2]Nome do Banco

oPrint:Say  (0130,567,aDadosBanco[1],oFont24 )	//Numero do Banco
oPrint:Say  (0130,1900,"Comprovante de Entrega",oFont10)
oPrint:Line (0150,100,0150,2300)
oPrint:Say  (0170,100 ,"Benefici�rio",oFont8)
oPrint:Say  (0200,100 ,aDadosEmp[1]	,oFont10)	//Nome + CNPJ
oPrint:Say  (0224,100 ,aDadosEmp[2]	,oFont10)	//Nome + CNPJ
oPrint:Say  (0170,1060,"Ag�ncia/C�digo Benefici�rio",oFont8)
oPrint:Say  (0200,1060,aDadosBanco[3]+"-"+aDadosBanco[7]+"/"+aDadosBanco[4]+"-"+aDadosBanco[5],oFont10)
oPrint:Say  (0170,1510,"Nro.Documento",oFont8)
oPrint:Say  (0200,1510,aDadosTit[7]+aDadosTit[1],oFont10)	//Prefixo +Numero+Parcela
oPrint:Say  (0270,100 ,"Pagador",oFont8)
oPrint:Say  (0300,100 ,aDatSacado[1]+" ("+aDatSacado[2]+") - C.N.P.J.: "+aDatSacado[7],oFont8) //Nome + Codigo + CNPJ
oPrint:Say  (0270,1060,"Vencimento",oFont8)
cImpData := Strzero(Day(aDadosTit[4]),2)+"/"+Strzero(Month(aDadosTit[4]),2)+"/"+Strzero(Year(aDadosTit[4]),4)
oPrint:Say  (0320,1060,If(Dtoc(aDadosTit[4])=="11/11/11","C/Apresenta��o",cImpData),oFont10)
//oPrint:Say  (0300,1060,If(Dtoc(aDadosTit[4])=="11/11/11","C/Apresenta��o",DTOC(aDadosTit[4])),oFont10)
oPrint:Say  (0270,1510,"Valor do Documento"	,oFont8)
oPrint:Say  (0320,1550,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10)
oPrint:Say  (0420,0100,"Recebi(emos) o bloqueto/t�tulo",oFont10)
oPrint:Say  (0470,0100,"com as caracter�sticas acima.",oFont10)
oPrint:Say  (0370,1060,"Data",oFont8)
oPrint:Say  (0370,1410,"Assinatura"	,oFont8)
oPrint:Say  (0470,1060,"Data",oFont8)
oPrint:Say  (0470,1410,"Entregador"	,oFont8)

oPrint:Line (0250, 100,0250,1900 )
oPrint:Line (0350, 100,0350,1900 )
oPrint:Line (0450,1050,0450,1900 ) //---
oPrint:Line (0550, 100,0550,2300 )

oPrint:Line (0550,1050,0150,1050 )
oPrint:Line (0550,1400,0350,1400 )
oPrint:Line (0350,1500,0150,1500 ) //--
oPrint:Line (0550,1900,0150,1900 )

oPrint:Say  (0180,1910,"(  ) Mudou-se"                 ,oFont8)
oPrint:Say  (0220,1910,"(  ) Ausente"                  ,oFont8)
oPrint:Say  (0260,1910,"(  ) N�o existe n� indicado"   ,oFont8)
oPrint:Say  (0300,1910,"(  ) Recusado"                 ,oFont8)
oPrint:Say  (0340,1910,"(  ) N�o procurado"            ,oFont8)
oPrint:Say  (0380,1910,"(  ) Endere�o insuficiente"    ,oFont8)
oPrint:Say  (0420,1910,"(  ) Desconhecido"             ,oFont8)
oPrint:Say  (0460,1910,"(  ) Falecido"                 ,oFont8)
oPrint:Say  (0500,1910,"(  ) Outros(anotar no verso)"  ,oFont8)

For i := 100 to 2300 step 50
	oPrint:Line( 0600, i, 0600, i+30)
Next i

oPrint:Line (0710,100,0710,2300)
oPrint:Line (0710,550,0610, 550)
oPrint:Line (0710,800,0610, 800)

//oPrint:Say  (0644,100,aDadosBanco[2],oFont14n)	// [2]Nome do Banco
oPrint:SayBitMap(0644,100,cBmp,0300,060)			// Logo do banco

oPrint:Say  (0690,0567,aDadosBanco[1],oFont24 )		//Numero do Banco
oPrint:Say  (0690,1900,"Recibo do Pagador",oFont10)

oPrint:Line (0810,100,0810,2300 )
oPrint:Line (0910,100,0910,2300 )
oPrint:Line (0980,100,0980,2300 )
oPrint:Line (1050,100,1050,2300 )

oPrint:Line (0910,500,1050,500)
oPrint:Line (0980,750,1050,750)
oPrint:Line (0910,1000,1050,1000)
oPrint:Line (0910,1350,0980,1350)
oPrint:Line (0910,1550,1050,1550)

oPrint:Say  (0730,100 ,"Local de Pagamento",oFont8)
oPrint:Say  (0780,100 ,"Pag�vel preferencialmente na rede Bradesco ou Bradesco Expresso",oFont10)

oPrint:Say  (0730,1910,"Vencimento",oFont8)
cImpData := Strzero(Day(aDadosTit[4]),2)+"/"+Strzero(Month(aDadosTit[4]),2)+"/"+Strzero(Year(aDadosTit[4]),4)
oPrint:Say  (0770,2010,If(Dtoc(aDadosTit[4])=="11/11/11","C/Apresenta��o",cImpData),oFont10)
//oPrint:Say  (0750,2010,If(Dtoc(aDadosTit[4])=="11/11/11","C/Apresenta��o",DTOC(aDadosTit[4])),oFont10)

oPrint:Say  (0830,100 ,"Benefici�rio",oFont8)
oPrint:Say  (0869,100 ,aDadosEmp[1]+"                  - "+aDadosEmp[6],oFont10) //Nome + CNPJ
oPrint:Say  (0893,100 ,aDadosEmp[2],oFont10) //Endereco

oPrint:Say  (0830,1910,"Ag�ncia/C�digo Benefici�rio",oFont8)
oPrint:Say  (0870,2010,aDadosBanco[3]+"-"+aDadosBanco[7]+"/"+aDadosBanco[4]+"-"+aDadosBanco[5],oFont10)

oPrint:Say  (0930,100 ,"Data do Documento",oFont8)
cImpData := Strzero(Day(aDadosTit[2]),2)+"/"+Strzero(Month(aDadosTit[2]),2)+"/"+Strzero(Year(aDadosTit[2]),4)
oPrint:Say  (0960,100 ,cImpData,oFont10) //Emissao do Titulo (E1_EMISSAO)
//oPrint:Say  (0940,100 ,DTOC(aDadosTit[2],"ddmmyyyy"),oFont10) //Emissao do Titulo (E1_EMISSAO)

oPrint:Say  (0930,505 ,"Nro.Documento",oFont8)
oPrint:Say  (0960,605 ,aDadosTit[7]+aDadosTit[1],oFont10) //Prefixo +Numero+Parcela

oPrint:Say  (0930,1005,"Esp�cie Doc.",oFont8)
oPrint:Say  (0960,1050,If(aDadosTit[8]$"NF |NFF","DM",aDadosTit[8]),oFont10) //Tipo do Titulo

oPrint:Say  (0930,1355,"Aceite",oFont8)
oPrint:Say  (0960,1455,"N",oFont10)

oPrint:Say  (0930,1555,"Data do Processamento",oFont8)
cImpData := Strzero(Day(aDadosTit[3]),2)+"/"+Strzero(Month(aDadosTit[3]),2)+"/"+Strzero(Year(aDadosTit[3]),4)
oPrint:Say  (0960,1655,cImpData,oFont10) //Data impressao

oPrint:Say  (0930,1910,"Nosso N�mero",oFont8)
oPrint:Say  (0960,2010,aDadosTit[6],oFont10)

oPrint:Say  (1000,100 ,"Uso do Banco",oFont8)

oPrint:Say  (1000,505 ,"Carteira",oFont8)
oPrint:Say  (1030,555 ,aDadosBanco[6],oFont10)

oPrint:Say  (1000,755 ,"Esp�cie",oFont8)
oPrint:Say  (1030,805 ,"R$",oFont10)

oPrint:Say  (1000,1005,"Quantidade",oFont8)
oPrint:Say  (1000,1555,"Valor",oFont8)

oPrint:Say  (1000,1910,"Valor do Documento",oFont8)
oPrint:Say  (1030,2010,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10)

oPrint:Say  (1070,100 ,"Instru��es (Texto de responsabilidade do Benefici�rio)  *** Valores expressos em R$ ***",oFont8)
oPrint:Say  (1120,100 ,aBolText[1],oFont10)
oPrint:Say  (1170,100 ,aBolText[2],oFont10)
oPrint:Say  (1220,100 ,aBolText[3],oFont10)
oPrint:Say  (1270,100 ,aBolText[4],oFont10)
oPrint:Say  (1320,100 ,aBolText[5],oFont10)

oPrint:Say  (1070,1910,"(-)Desconto/Abatimento",oFont8)

/*
If aDadosTit[15] > 0
	oPrint:Say  (1100,2010,AllTrim(Transform(aDadosTit[15],"@E 999,999,999.99")),oFont10)
EndIf
*/

oPrint:Say  (1140,1910,"(-)Outras Dedu��es",oFont8)
oPrint:Say  (1210,1910,"(+)Mora/Multa",oFont8)
oPrint:Say  (1280,1910,"(+)Outros Acr�scimos",oFont8)
oPrint:Say  (1350,1910,"(=)Valor Cobrado",oFont8)

oPrint:Say  (1420,100 ,"Pagador",oFont8)
oPrint:Say  (1450,400 ,aDatSacado[1]+" ("+aDatSacado[2]+") - C.N.P.J.: "+aDatSacado[7],oFont10)
oPrint:Say  (1503,400 ,aDatSacado[3],oFont10)
oPrint:Say  (1556,400 ,aDatSacado[6]+"    "+aDatSacado[4]+" - "+aDatSacado[5],oFont10) // CEP+Cidade+Estado

oPrint:Say  (1625,100 ,"Pagador/Avalista",oFont8)
oPrint:Say  (1665,1500,"Autentica��o Mec�nica -",oFont8)

oPrint:Line (0710,1900,1400,1900 )
oPrint:Line (1120,1900,1120,2300 )
oPrint:Line (1190,1900,1190,2300 )
oPrint:Line (1260,1900,1260,2300 )
oPrint:Line (1330,1900,1330,2300 )
oPrint:Line (1400,100 ,1400,2300 )
oPrint:Line (1640,100 ,1640,2300 )

For i := 100 to 2300 step 50
	oPrint:Line( 1850, i, 1850, i+30)
Next i

oPrint:Line (2000,100,2000,2300)
oPrint:Line (2000,550,1900, 550)
oPrint:Line (2000,800,1900, 800)

oPrint:SayBitMap(1934,100,cBmp,0300,060)			//Logo do banco

oPrint:Say  (1970,0567,aDadosBanco[1],oFont24 )		//Numero do Banco
oPrint:Say  (1970,0820,CB_RN_NN[2],oFont14n)		//Linha Digitavel do Codigo de Barras

oPrint:Line (2100,100,2100,2300 )
oPrint:Line (2200,100,2200,2300 )
oPrint:Line (2270,100,2270,2300 )
oPrint:Line (2340,100,2340,2300 )

oPrint:Line (2200,500,2340,500)
oPrint:Line (2270,750,2340,750)
oPrint:Line (2200,1000,2340,1000)
oPrint:Line (2200,1350,2270,1350)
oPrint:Line (2200,1550,2340,1550)

oPrint:Say  (2020,100 ,"Local de Pagamento",oFont8)
oPrint:Say  (2060,100 ,"Pag�vel preferencialmente na rede Bradesco ou Bradesco Expresso",oFont10)

oPrint:Say  (2020,1910,"Vencimento",oFont8)
cImpData := Strzero(Day(aDadosTit[4]),2)+"/"+Strzero(Month(aDadosTit[4]),2)+"/"+Strzero(Year(aDadosTit[4]),4)
oPrint:Say  (2060,2010,If(Dtoc(aDadosTit[4])=="11/11/11","C/Apresenta��o",cImpData),oFont10)
//oPrint:Say  (2040,2010,If(Dtoc(aDadosTit[4])=="11/11/11","C/Apresenta��o",DTOC(aDadosTit[4])),oFont10)

oPrint:Say  (2120,100 ,"Benefici�rio",oFont8)
oPrint:Say  (2160,100 ,aDadosEmp[1]+"                  - "+aDadosEmp[6],oFont10) //Nome + CNPJ

oPrint:Say  (2120,1910,"Ag�ncia/C�digo Benefici�rio",oFont8)
oPrint:Say  (2160,2010,aDadosBanco[3]+"-"+aDadosBanco[7]+"/"+aDadosBanco[4]+"-"+aDadosBanco[5],oFont10)

oPrint:Say  (2220,100 ,"Data do Documento",oFont8)
cImpData := Strzero(Day(aDadosTit[2]),2)+"/"+Strzero(Month(aDadosTit[2]),2)+"/"+Strzero(Year(aDadosTit[2]),4)
oPrint:Say  (2250,100 , cImpData ,oFont10) 		//Emissao do Titulo (E1_EMISSAO)
//oPrint:Say  (2230,100 ,DTOC(aDadosTit[2],"ddmmyyyy"),oFont10) //Emissao do Titulo (E1_EMISSAO)

oPrint:Say  (2220,505 ,"Nro.Documento",oFont8)
oPrint:Say  (2250,605 ,aDadosTit[7]+aDadosTit[1],oFont10) //Prefixo +Numero+Parcela

oPrint:Say  (2220,1005,"Esp�cie Doc.",oFont8)
oPrint:Say  (2250,1050,If(aDadosTit[8]$"NF |NFF","DM",aDadosTit[8]),oFont10) //Tipo do Titulo

oPrint:Say  (2220,1355,"Aceite",oFont8)
oPrint:Say  (2250,1455,"N",oFont10)

oPrint:Say  (2220,1555,"Data do Processamento",oFont8)
cImpData := Strzero(Day(aDadosTit[3]),2)+"/"+Strzero(Month(aDadosTit[3]),2)+"/"+Strzero(Year(aDadosTit[3]),4)
oPrint:Say  (2250,1655, cImpData ,oFont10) 	//Data impressao
//oPrint:Say  (2230,1655,DTOC(aDadosTit[3],"ddmmyyyy"),oFont10) 	//Data impressao

oPrint:Say  (2220,1910,"Nosso N�mero",oFont8)
oPrint:Say  (2250,2010,aDadosTit[6],oFont10)

oPrint:Say  (2290,100 ,"Uso do Banco",oFont8)

oPrint:Say  (2290,505 ,"Carteira",oFont8)
oPrint:Say  (2320,555 ,aDadosBanco[6],oFont10)

oPrint:Say  (2290,755 ,"Esp�cie",oFont8)
oPrint:Say  (2320,805 ,"R$",oFont10)

oPrint:Say  (2290,1005,"Quantidade",oFont8)
oPrint:Say  (2290,1555,"Valor",oFont8)

oPrint:Say  (2290,1910,"Valor do Documento",oFont8)
oPrint:Say  (2320,2010,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10)

oPrint:Say  (2360,100 ,"Instru��es (Texto de responsabilidade do Benefici�rio)  *** Valores expressos em R$ ***",oFont8)
oPrint:Say  (2410,100 ,aBolText[1],oFont10)
oPrint:Say  (2460,100 ,aBolText[2],oFont10)
oPrint:Say  (2510,100 ,aBolText[3],oFont10)
oPrint:Say  (2560,100 ,aBolText[4],oFont10)
oPrint:Say  (2610,100 ,aBolText[5],oFont10)

oPrint:Say  (2360,1910,"(-)Desconto/Abatimento",oFont8)

/*
If aDadosTit[15] > 0
	oPrint:Say  (2390,2010,AllTrim(Transform(aDadosTit[15],"@E 999,999,999.99")),oFont10)
EndIf
*/

oPrint:Say  (2430,1910,"(-)Outras Dedu��es",oFont8)
oPrint:Say  (2500,1910,"(+)Mora/Multa",oFont8)
oPrint:Say  (2570,1910,"(+)Outros Acr�scimos",oFont8)
oPrint:Say  (2640,1910,"(=)Valor Cobrado",oFont8)

oPrint:Say  (2710,100 ,"Pagador",oFont8)
oPrint:Say  (2740,400 ,aDatSacado[1]+" ("+aDatSacado[2]+") C.N.P.J.: "+aDatSacado[7],oFont10)
oPrint:Say  (2793,400 ,aDatSacado[3]                                    ,oFont10)
oPrint:Say  (2846,400 ,aDatSacado[6]+"    "+aDatSacado[4]+" - "+aDatSacado[5],oFont10) //CEP+Cidade+Estado

oPrint:Say  (2915,100 ,"Pagador/Avalista",oFont8)
oPrint:Say  (2955,1500,"Autentica��o Mec�nica -",oFont8)
oPrint:Say  (2955,1850,"Ficha de Compensa��o",oFont10)

oPrint:Line (2000,1900,2690,1900 )
oPrint:Line (2410,1900,2410,2300 )
oPrint:Line (2480,1900,2480,2300 )
oPrint:Line (2550,1900,2550,2300 )
oPrint:Line (2620,1900,2620,2300 )
oPrint:Line (2690,100 ,2690,2300 )

oPrint:Line (2930,100,2930,2300  )

oPrint:FWMSBAR("INT25",63.5,2, CB_RN_NN[1],oPrint,.F.,,,,1,.F.,,"A",.f.,,,)

For i := 100 to 2300 step 50
	oPrint:Line( 3220, i, 3220, i+30)
Next i

oPrint:EndPage() // Finaliza a pagina

Return Nil


/*
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
���������������������������������������������������������������������������Ŀ��
���FUNCAO    � Modulo10 � Autor � Celio Oliveira        � Data � 19/09/2013 ���
���������������������������������������������������������������������������Ĵ��
���DESCRICAO � Impressao do boleto laser do Bradesco com codigo de barras   ���
���������������������������������������������������������������������������Ĵ��
���SINTAXE   � Modulo10()                                                   ���
���������������������������������������������������������������������������Ĵ��
���PARAMETROS� Nenhum                                                       ���
���������������������������������������������������������������������������Ĵ��
���RETORNO   � Nenhum                                                       ���
���������������������������������������������������������������������������Ĵ��
��� USO      � Generico                                                     ���
����������������������������������������������������������������������������ٱ�
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
*/
Static Function Modulo10(cData)
Local L,D,P := 0
Local B     := .F.

L := Len(cData)
B := .T.
D := 0

While L > 0
	P := Val(SubStr(cData, L, 1))
	If (B)
		P := P * 2
		If P > 9
			P := P - 9
		EndIf
	EndIf
	D := D + P
	L := L - 1
	B := !B
EndDo

D := 10 - (Mod(D,10))

If D = 10
	D := 0
EndIf

Return(D)


/*
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
���������������������������������������������������������������������������Ŀ��
���FUNCAO    � Modulo11 � Autor � Celio Oliveira        � Data � 19/09/2013 ���
���������������������������������������������������������������������������Ĵ��
���DESCRICAO � Impressao do boleto laser do Bradesco com codigo de barras   ���
���������������������������������������������������������������������������Ĵ��
���SINTAXE   � Modulo11()                                                   ���
���������������������������������������������������������������������������Ĵ��
���PARAMETROS� Nenhum                                                       ���
���������������������������������������������������������������������������Ĵ��
���RETORNO   � Nenhum                                                       ���
���������������������������������������������������������������������������Ĵ��
��� USO      � Generico                                                     ���
����������������������������������������������������������������������������ٱ�
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
*/
Static Function Modulo11(cData) //Modulo 11 com base 7
Local L, D, P := 0

L  := Len(cdata)
D  := 0
P  := 1
DV := " "

While L > 0
	P := P + 1
	D := D + (Val(SubStr(cData, L, 1)) * P)
	If P = 7   //Volta para o inicio, ou seja comeca a multiplicar por 2,3,4...
		P := 1
	EndIf
	L := L - 1
EndDo

_nResto := mod(D,11)  //Resto da Divisao
D  := 11 - _nResto
DV := STR(D)

If _nResto == 0
	DV := "0"
EndIf
If _nResto == 1
	DV := "P"
EndIf

Return(DV)


/*
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
���������������������������������������������������������������������������Ŀ��
���FUNCAO    � Mod11CB  � Autor � Celio Oliveira        � Data � 19/09/2013 ���
���������������������������������������������������������������������������Ĵ��
���DESCRICAO � Impressao do boleto laser do Bradesco com codigo de barras   ���
���������������������������������������������������������������������������Ĵ��
���SINTAXE   � Mod11CB()                                                    ���
���������������������������������������������������������������������������Ĵ��
���PARAMETROS� Nenhum                                                       ���
���������������������������������������������������������������������������Ĵ��
���RETORNO   � Nenhum                                                       ���
���������������������������������������������������������������������������Ĵ��
��� USO      � Generico                                                     ���
����������������������������������������������������������������������������ٱ�
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
*/
Static Function Mod11CB(cData) // Modulo 11 com base 9
Local CBL, CBD, CBP := 0

CBL := Len(cdata)
CBD := 0
CBP := 1

While CBL > 0
	CBP := CBP + 1
	CBD := CBD + (Val(SubStr(cData, CBL, 1)) * CBP)
	If CBP = 9
		CBP := 1
	EndIf
	CBL := CBL - 1
EndDo

_nCBResto := mod(CBD,11)  //Resto da Divisao
CBD := 11 - _nCBResto

If (CBD == 0 .Or. CBD == 1 .Or. CBD > 9)
	CBD := 1
EndIf

Return(CBD)


//Retorna os strings para inpress�o do Boleto
//CB = String para o cod.barras, RN = String com o n�mero digit�vel
//Cobran�a nao identificada, numero do boleto = Titulo + Parcela
/*
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
���������������������������������������������������������������������������Ŀ��
���FUNCAO    �Ret_cBarra� Autor � Celio Oliveira        � Data � 19/09/2013 ���
���������������������������������������������������������������������������Ĵ��
���DESCRICAO � Impressao do boleto laser do Bradesco com codigo de barras   ���
���������������������������������������������������������������������������Ĵ��
���SINTAXE   � Ret_cBarra()                                                 ���
���������������������������������������������������������������������������Ĵ��
���PARAMETROS� Nenhum                                                       ���
���������������������������������������������������������������������������Ĵ��
���RETORNO   � Nenhum                                                       ���
���������������������������������������������������������������������������Ĵ��
��� USO      � Generico                                                     ���
����������������������������������������������������������������������������ٱ�
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
*/
Static Function Ret_cBarra(cBanco,cAgencia,cConta,cDacCC,cCarteira,cNroDoc,nValor)
//Local BlDocNuFinal := cAgencia + Strzero(val(cNroDoc),7) DESABILITADO OSMIL
//Local BlDocNuFinal := "1173" + Strzero(val(cNroDoc),7)
Local BlDocNuFinal := cAgencia + Strzero(val(cNroDoc),7)
Local blvalorfinal := Strzero(nValor*100,10)
Local dvnn         := 0
Local dvcb         := 0
Local dv           := 0
Local NN           := ''
Local RN           := ''
Local CB           := ''
Local s            := ''
Local cMoeda       := "9"
Local cFator       := Strzero(SE1->E1_VENCTO - ctod("07/10/97"),4)

//��������������������������������������������������������������Ŀ
//� Montagem do NOSSO NUMERO                                     �
//����������������������������������������������������������������
// s :=  cAgencia + cConta + cCarteira + bldocnufinal
snn := bldocnufinal     // Agencia + Numero (pref+num+parc)
// RAI
//dvnn := modulo10(s)  //Digito verificador no Nosso Numero
dvnn := modulo11(cCarteira+snn)  //Digito verificador no Nosso Numero

//[RAI] NN := '/' + bldocnufinal + '-' + AllTrim(Str(dvnn))
NN := cCarteira +"/"+ bldocnufinal +'-'+ AllTrim(dvnn)

//��������������������������������������������������������������Ŀ
//� Campo Livre                                                  �
//����������������������������������������������������������������
_cLivre := cAgencia+cCarteira+bldocnufinal+cConta+'0'

scb := cBanco + cMoeda+ cFator + blvalorfinal	+ _cLivre
//��������������������������������������������������������������Ŀ
//� Digito verificador do codigo de barras                       �
//����������������������������������������������������������������
dvcb := mod11CB(scb)	//digito verificador do codigo de barras

CB := SubStr(scb,1,4)+AllTrim(Str(dvcb))+SubStr(scb,5,39)

//������������������������������������������������������������������������������Ŀ
//� Montagem da linha digitavel                                                  �
//� Definicao da LINHA DIGITAVEL (Representacao Numerica)                        �
//�	Campo 1			Campo 2			Campo 3			Campo 4		Campo 5          �
//�	AAABC.CCCCX		DDDDD.DDDDDY	DDDDD.DDDDDZ	K			UUUUVVVVVVVVVV   �
//��������������������������������������������������������������������������������

//������������������������������������������������������������������������������Ŀ
//�	CAMPO 1: AAABC.CCCCX                                                         �
//�	AAA	  = Codigo do banco na Camara de Compensacao                             �
//� B     = Codigo da moeda, sempre 9                                            �
//� CCCCC = 5 primeiros digitos do campo livre                                   �
//� X     = DAC que amarra o campo, calculado pelo Modulo 10 mulltiplo superior  �
//��������������������������������������������������������������������������������
srn := cBanco + cMoeda + Substr(_cLivre,1,5) //Codigo Banco + Codigo Moeda + 5 primeiros digitos do campo livre
dv := modulo10(srn,1,5)
RN := SubStr(srn,1,5) + '.' + SubStr(srn,6,4) + Alltrim(Str(DV)) + '  '

//������������������������������������������������������������������������������Ŀ
//�	CAMPO 2: DDDDD.DDDDDY                                                        �
//� DDDDD.DDDDD = 6 ao 15 do campo livre                                         �
//�	Y = DAC que amarra o campo, calculado pelo Modulo 10 mulltiplo superior      �
//��������������������������������������������������������������������������������
srn := SubStr(_cLivre,6,10)		//posicao 6 a 15 do campo livre
dv := modulo10(srn)
RN := RN + SubStr(srn,1,5)+'.'+SubStr(srn,6,5)+AllTrim(Str(dv))+'  '

//������������������������������������������������������������������������������Ŀ
//�	CAMPO 3: DDDDD.DDDDDZ                                                        �
//� DDDDDDDDDD = 16 ao 25 do campo livre                                         �
//� Z = DAC que amarra o campo, calculado pelo Modulo 10 mulltiplo superior      �
//��������������������������������������������������������������������������������
srn := SubStr(_cLivre,16,10)	// posicao 6 a 15 do campo livre
dv := modulo10(srn)
RN := RN + SubStr(srn,1,5)+'.'+SubStr(srn,6,5)+AllTrim(Str(dv)) + '  '

//������������������������������������������������������������������������������Ŀ
//�	CAMPO 4: K                                                                   �
//� K = Digito de controle do codigo de Barra                                    �
//��������������������������������������������������������������������������������
RN := RN + AllTrim(Str(dvcb))+'  '

//������������������������������������������������������������������������������Ŀ
//�	CAMPO 5: UUUUVVVVVVVVVV                                                      �
//� UUUU       = Fator de Vencimento                                             �
//� VVVVVVVVVV = Valor do Documento                                              �
//��������������������������������������������������������������������������������
RN := RN + cFator
RN := RN + Strzero(nValor * 100,10)

Return({CB,RN,NN})


/*
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
���������������������������������������������������������������������������Ŀ��
���FUNCAO    � BuscaNF  � Autor � Celio Oliveira        � Data � 19/09/2013 ���
���������������������������������������������������������������������������Ĵ��
���DESCRICAO � Busca titulos principais que compoem a Fatura                ���
���������������������������������������������������������������������������Ĵ��
���SINTAXE   � BuscaNF(cPrefFat,cNumFat)                                    ���
���������������������������������������������������������������������������Ĵ��
���PARAMETROS� BuscaNF(cPrefFat,cNumFat)                                    ���
���������������������������������������������������������������������������Ĵ��
���RETORNO   � Nenhum                                                       ���
���������������������������������������������������������������������������Ĵ��
��� USO      � Generico                                                     ���
����������������������������������������������������������������������������ٱ�
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
*/
Static Function BUSCANF(cPrefFat,cNumFat)
Local cRet   := " "
Local cQuery := ""

cQuery	:= " SELECT * FROM " + RetSqlName("SE1") "
cQuery	+= " WHERE E1_FILIAL = '"+ xFilial("SE1") + "' AND "
cQuery	+= " E1_FATURA  = '"+ cNumFat + "' AND "
cQuery	+= " E1_FATPREF = '"+ cPrefFat + "' AND "
cQuery	+= " D_E_L_E_T_ <> '*' "
cQuery  := ChangeQuery(cQuery)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"QUERY",.T.,.T.)

dbSelectArea("QUERY")
dbGotop()

While !Eof()
	cRet += QUERY->E1_NUM + "/"
	dbSelectArea("QUERY")
	dbSkip()
EndDo

dbSelectArea("QUERY")
dbCloseArea("QUERY")

Return(cRet)

/*
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
���������������������������������������������������������������������������Ŀ��
���FUNCAO    � ValidPerg� Autor � Celio Oliveira        � Data � 19/09/2013 ���
���������������������������������������������������������������������������Ĵ��
���DESCRICAO � Cria as perguntas do parametro caso nao exista               ���
���������������������������������������������������������������������������Ĵ��
���SINTAXE   � ValidPerg()                                                  ���
���������������������������������������������������������������������������Ĵ��
���PARAMETROS� Nenhum                                                       ���
���������������������������������������������������������������������������Ĵ��
���RETORNO   � Nenhum                                                       ���
���������������������������������������������������������������������������Ĵ��
��� USO      � Generico                                                     ���
����������������������������������������������������������������������������ٱ�
�������������������������������������������������������������������������������
�������������������������������������������������������������������������������
*/
Static Function ValidPerg()
Local cLAlias := Alias()
Local aRegs   := {}

cPerg := PADR(cPerg,10)

Aadd(aRegs,{cPerg,"01","Do Prefixo?"       ,"","","mv_ch1","C",03,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
Aadd(aRegs,{cPerg,"02","Ate o Prefixo?"    ,"","","mv_ch2","C",03,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
Aadd(aRegs,{cPerg,"03","Do Titulo?"        ,"","","mv_ch3","C",09,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"04","Ate o Titulo?"     ,"","","mv_ch4","C",09,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"05","Da Parcela?"       ,"","","mv_ch5","C",01,0,0,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"06","Ate a Parcela?"    ,"","","mv_ch6","C",01,0,0,"G","","mv_par06","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"07","Do Portador?"      ,"","","mv_ch7","C",03,0,0,"G","","mv_par07","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"08","Ate o Portador?"   ,"","","mv_ch8","C",03,0,0,"G","","mv_par08","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"09","Do Cliente?"       ,"","","mv_ch9","C",06,0,0,"G","","mv_par09","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"10","Ate o Cliente?"    ,"","","mv_chA","C",06,0,0,"G","","mv_par10","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"11","Da Loja?"          ,"","","mv_chB","C",02,0,0,"G","","mv_par11","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"12","Ate a Loja?"       ,"","","mv_chC","C",02,0,0,"G","","mv_par12","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"13","Do Vencimento?"    ,"","","mv_chD","D",08,0,0,"G","","mv_par13","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"14","Ate o Vencimento?" ,"","","mv_chE","D",08,0,0,"G","","mv_par14","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"15","Da Emissao?"       ,"","","mv_chF","D",08,0,0,"G","","mv_par15","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"16","Ate a Emissao?"    ,"","","mv_chG","D",08,0,0,"G","","mv_par16","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

AADD(aRegs,{cPerg,"17","Obs. linha 1"		,"","","mv_chH","C",50,0,0,"C","","mv_par17","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"18","Obs. linha 2" 		,"","","mv_chI","C",50,0,0,"C","","mv_par18","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"19","Obs. linha 3"      	,"","","mv_chJ","C",50,0,0,"G","","mv_par19","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"20","Obs. linha 4"     	,"","","mv_chK","C",50,2,0,"G","","mv_par20","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"21","Obs. linha 5"     	,"","","mv_chL","C",50,2,0,"G","","mv_par21","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

//��������������������������������������������Ŀ
//�Atualizacao do SX1 com os parametros criados�
//����������������������������������������������
dbSelectArea("SX1")
dbSetorder(1)
For nLoop1 := 1 to Len(aRegs)
	If !dbSeek(cPerg+aRegs[nLoop1,2])
		RecLock("SX1",.T.)
		For nLoop2 := 1 to FCount()
			FieldPut(nLoop2,aRegs[nLoop1,nLoop2])
		Next
		MsUnlock()
		dbCommit()
	Endif
Next

//�������������������������Ŀ
//�Retorna ambiente original�
//���������������������������
dbSelectArea(cLAlias)
Return
