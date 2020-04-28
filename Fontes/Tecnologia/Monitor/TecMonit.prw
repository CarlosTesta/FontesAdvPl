#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'TOPCONN.CH'
#INCLUDE "FWMVCDEF.CH"

User Function TecMonit()
Local cTitulo   := "TOTVSTEC Monitor"   // Meta de Venda
Local aSizeAut  := MsAdvSize(.F.,.T.)   // Array para redimensionamento da tela
Local aObjects  := {}					// Array para redimensionamento da tela
Local aPosObj   := {}					// Array para redimensionamento da tela
Local oDlg,oButton1,oButton2,oTsay,cGet1
// parametros do JOB de Coleta a serem utilizados no monitoramento.
Local nBINVersion   := Val(GetPvProfString("TECMONITOR","BINVersion","undefined","appserver.ini"))
Local nSetEnv       := Val(GetPvProfString("TECMONITOR","SetEnv"    ,"undefined","appserver.ini"))
Local nERPVersion   := Val(GetPvProfString("TECMONITOR","ERPVersion","undefined","appserver.ini"))
Local nTRBCount     := Val(GetPvProfString("TECMONITOR","TRBCount"  ,"undefined","appserver.ini"))
Local nTOPCount     := Val(GetPvProfString("TECMONITOR","TOPCount"  ,"undefined","appserver.ini"))
Local nUserList     := Val(GetPvProfString("TECMONITOR","USERList"  ,"undefined","appserver.ini"))
Local nRefresh      := Val(GetPvProfString("TECMONITOR","RefreshRate","undefined","appserver.ini"))
Local nRefreshINI   := Val(GetPvProfString("TECMONITOR","RefreshINI","undefined","appserver.ini"))
Local cRPCTest      := Val(GetPvProfString("TECMONITOR","RPCTest","undefined","appserver.ini"))
Local cEmpresa      := GetPvProfString("TECMONITOR","Empresa","undefined","appserver.ini")
Local cCodEmp       := SubStr(cEmpresa,1,AT(",",cEmpresa)-1)
Local cCodFil       := SubStr(cEmpresa,AT(",",cEmpresa)+1)
// variáveis de montagem de tela
Local oFontCabec	:= TFont():New( 'Courier New',, 18,,.t.)
Local oFontItem		:= TFont():New( "Century",, 14,,.t.,,,,.t.)
Local bBtnOk		:= {|| (Iif(DYN010EXEC(),oDlg:End(),.T.)) }
Local bBtnCancel	:= {|| oDlg:End() }
Local bEnchBarOn	:= {|| EnchoiceBar(oDlg,bBtnOk,bBtnCancel,,aButtons) }
Local aButtons		:= {}


Private _lAlter		:= .F.

// recuperação da lista de valores + lista de usuários (ultimo nível do array)
//Static aGlbAll := {}
//VarGetAA(GLBDataSrv,@aGlbAll)


RpcSetType( 3 )
PREPARE ENVIRONMENT EMPRESA cCodEmp FILIAL cCodFil MODULO "FAT"

// para debug sem o Splash
aSizeAut := {0,12,636,422,1272,968,120}

cGet1 := Space(TAMSX3("B1_COD")[1])
// abre a tabela pra garantir uso
If Select("SB1") <= 0
	ChkFile("SB1")
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Calculo automatico de dimensoes dos objetos                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
AAdd( aObjects, { aSizeAut[3]-6              , 030 , .F. , .F. } )	// painel Param
AAdd( aObjects, { aSizeAut[3]-6              , 080 , .F. , .F. } )	// painel Transportadora
AAdd( aObjects, { aSizeAut[3]-6              , 060 , .F. , .F. } )	// painel Imposto
AAdd( aObjects, { aSizeAut[3]-6              , 150 , .F. , .F. } )	// painel MGet
AAdd( aObjects, { Int((aSizeAut[3]*0.50-6)) , 060 , .F. , .F. } )	// painel Info Complementares, ocupa 1/2 do rodape da pagina
AAdd( aObjects, { Int((aSizeAut[3]*0.25)-6) , 060 , .F. , .F. } )	// painel Impostos de DI, ocupa 1/4 do rodape da pagina
AAdd( aObjects, { Int((aSizeAut[3]*0.25)-6) , 060 , .F. , .F. } )	// painel PIS e COFINS, ocupa 1/4 do rodape da pagina

aInfo   := { aSizeAut[ 1 ], aSizeAut[ 2 ], aSizeAut[ 3 ], aSizeAut[ 4 ], 5, 5 }
aPosObj  := MsObjSize( aInfo, aObjects, , .T. )

DEFINE MSDIALOG oDlg TITLE "TOTVS Monitor" FROM aSizeAut[7],00 TO aSizeAut[6],aSizeAut[5] PIXEL //000,000 TO 700,950 PIXEL 
	// painel da Param
	oPnlParam  := TPanel():New(aPosObj[1,1],aPosObj[1,2],"Parametros do MONITOR",oDlg,,,,,CLR_WHITE,aObjects[1,1],aObjects[1,2],.T.,.T.)

	oSayDF1 := TSay():New(aPosObj[1,2]+10,002, {|| "Versão do Binário" },oPnlParam,,oFontCabec,,,,.t.,CLR_RED,,200,21)
 	cGetDF1 := nBINVersion
	oGetDF1 := TGet():New(aPosObj[1,2]+10,100,{|u| if(PCount()>0,cGetDF1:=u,cGetDF1)},oPnlParam,30,10,'99',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,'cGetDF1')

/*
	oSayDF2 := TSay():New(aPosObj[1,2]+0,175, {|| "Environment" },oPnlParam,,oFontCabec,,,,.t.,CLR_RED,,200,21)


	oSayDF3 := TSay():New(aPosObj[1,2]+0,250, {|| "Release Protheus" },oPnlParam,,oFontCabec,,,,.t.,CLR_RED,,200,21)


	oSayDF4 := TSay():New(aPosObj[1,2]+0,355, {|| "ReFresh INI" },oPnlParam,,oFontCabec,,,,.t.,CLR_RED,,200,21)

	cGetDF2 := nSetEnv
	oGetDF2 := TGet():New(aPosObj[1,2]+10,175,{|u| if(PCount()>0,cGetDF2:=u,cGetDF2)},oPnlParam,070,10,'99',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,'cGetDF2')
	cGetDF3 := nTRBCount
	oGetDF3 := TGet():New(aPosObj[1,2]+10,250,{|u| if(PCount()>0,cGetDF3:=u,cGetDF3)},oPnlParam,100,10,'99',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,'cGetDF3')
	cGetDF4 := nRefreshINI
	oGetDF4 := TGet():New(aPosObj[1,2]+10,355,{|u| if(PCount()>0,cGetDF4:=u,cGetDF4)},oPnlParam,170,10,'99',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,'cGetDF4')
*/
    /*
	oPnlParam := TPanel():New(aPosObj[1,1],540,"Situação do Arquivo",oPnlParam,,,,,CLR_WHITE,aObjects[1,1]-10,aObjects[1,2],.T.,.T.)
	TBitMap():New(14,20,10,10,_cImgAlt, , ,oPnlParam,,,,,,,,,.T.,,)
	oSayDF6 := TSay():New(14,35, {|| Iif(_lAlter,"Alterável","Bloqueado") },oPnlParam,,oFontCabec,,,,.t.,Iif(_lAlter,CLR_GREEN,CLR_RED),,200,21)
    */

    /*
	// Painel da transportadora
	oPnlTrans  := TPanel():New(aPosObj[2,1],aPosObj[2,2],"Dados da Transportadora e Transporte",oDlg,,,,,CLR_WHITE,aObjects[2,1],aObjects[2,2],.T.,.T.)
	// segunda linha de dados de transportadora
	oSayTrA1 := TSay():New(aPosObj[2,2]+00,002, {|| "Razão Social" },oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,200,21)
	oSayTrA2 := TSay():New(aPosObj[2,2]+00,200, {|| "Frete Por Conta"},oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,200,21)
	oSayTrA3 := TSay():New(aPosObj[2,2]+00,290, {|| "Código ANTT" },oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,200,21)
	oSayTrA4 := TSay():New(aPosObj[2,2]+00,360, {|| "Placa Veículo" },oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,200,21)
	oSayTrA5 := TSay():New(aPosObj[2,2]+00,450, {|| "UF" },oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,200,21)
	oSayTrA6 := TSay():New(aPosObj[2,2]+00,480, {|| "CNPJ/CPF" },oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,200,21)
	cGetTrA1 := RetTag("TRANS_NOME") 
	oGetTrA1 := TGet():New(aPosObj[2,2]+10,002,{|u| if(PCount()>0,cGetTrA1:=u,cGetTrA1)},oPnlTrans,190,10,'@!',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrA1")
	cGetTrA2 := Iif(RetTag("TRANS_TPFRETE") == "1","F-FOB","C-CIF")
	oGetTrA2 := TGet():New(aPosObj[2,2]+10,200,{|u| if(PCount()>0,cGetTrA2:=u,cGetTrA2)},oPnlTrans,80,10,'@!',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrA2")
	cGetTrA3 := RetTag("TRANS_ANTT")
	oGetTrA3 := TGet():New(aPosObj[2,2]+10,290,{|u| if(PCount()>0,cGetTrA3:=u,cGetTrA3)},oPnlTrans,60,10,'@!',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrA3")
	cGetTrA4 := RetTag("TRANS_PLACA")
	oGetTrA4 := TGet():New(aPosObj[2,2]+10,360,{|u| if(PCount()>0,cGetTrA4:=u,cGetTrA4)},oPnlTrans,80,10,'@!',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrA4")
	cGetTrA5 := RetTag("TRANS_UFCARRO") 
	oGetTrA5 := TGet():New(aPosObj[2,2]+10,450,{|u| if(PCount()>0,cGetTrA5:=u,cGetTrA5)},oPnlTrans,20,10,'@!',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrA5")
	cGetTrA6 := RetTag("TRANS_CNPJ") 
	oGetTrA6 := TGet():New(aPosObj[2,2]+10,480,{|u| if(PCount()>0,cGetTrA6:=u,cGetTrA6)},oPnlTrans,80,10,PesqPict("SA1","A1_CGC"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrA6")
	
	// segunda linha de dados de transportadora
	oSayTrB1 := TSay():New(aPosObj[2,2]+25,002, {|| "Endereço" },oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,200,21)
	oSayTrB2 := TSay():New(aPosObj[2,2]+25,300, {|| "Municipio"},oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,200,21)
	oSayTrB3 := TSay():New(aPosObj[2,2]+25,420, {|| "UF" },oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,200,21)
	oSayTrB4 := TSay():New(aPosObj[2,2]+25,450, {|| "Inscrição Estadual" },oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,200,21)
	cGetTrB1 := RetTag("TRANS_END") 
	oGetTrB1 := TGet():New(aPosObj[2,2]+35,002,{|u| if(PCount()>0,cGetTrB1:=u,cGetTrB1)},oPnlTrans,285,10,"@!",{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrB1")
	cGetTrB2 := RetTag("TRANS_MUN") 
	oGetTrB2 := TGet():New(aPosObj[2,2]+35,300,{|u| if(PCount()>0,cGetTrB2:=u,cGetTrB2)},oPnlTrans,100,10,"@!",{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrB2")
	cGetTrB3 := RetTag("TRANS_UF") 
	oGetTrB3 := TGet():New(aPosObj[2,2]+35,420,{|u| if(PCount()>0,cGetTrB3:=u,cGetTrB3)},oPnlTrans,20,10,"@!",{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrB3")
	cGetTrB4 := RetTag("TRANS_IE") 
	oGetTrB4 := TGet():New(aPosObj[2,2]+35,450,{|u| if(PCount()>0,cGetTrB4:=u,cGetTrB4)},oPnlTrans,80,10,"@!",{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrB4")

	// terceira linha de dados de transportadora
	oSayTrC1 := TSay():New(aPosObj[2,2]+50,002, {|| "Quantidade" },oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,100,21)
	oSayTrC2 := TSay():New(aPosObj[2,2]+50,070, {|| "Especie"},oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,100,21)
	oSayTrC3 := TSay():New(aPosObj[2,2]+50,140, {|| "Marca" },oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,100,21)
	oSayTrC4 := TSay():New(aPosObj[2,2]+50,240, {|| "Numeração" },oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,100,21)
	oSayTrC5 := TSay():New(aPosObj[2,2]+50,340, {|| "Peso Bruto" },oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,100,21)
	oSayTrC6 := TSay():New(aPosObj[2,2]+50,440, {|| "Peso Liquido" },oPnlTrans,,oFontCabec,,,,.t.,CLR_RED,,100,21)
	cGetTrC1 := RetTag("VOLUME_QTDVOL") 
	oGetTrC1 := TGet():New(aPosObj[2,2]+60,002,{|u| if(PCount()>0,cGetTrC1:=u,cGetTrC1)},oPnlTrans,050,10,"@!",{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrC1")
	cGetTrC2 := RetTag("VOLUME_ESP") 
	oGetTrC2 := TGet():New(aPosObj[2,2]+60,070,{|u| if(PCount()>0,cGetTrC2:=u,cGetTrC2)},oPnlTrans,050,10,"@!",{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrC2")
	cGetTrC3 := RetTag("VOLUME_MARCA") 
	oGetTrC3 := TGet():New(aPosObj[2,2]+60,140,{|u| if(PCount()>0,cGetTrC3:=u,cGetTrC3)},oPnlTrans,070,10,"@!",{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrC3")
	cGetTrC4 := RetTag("VOLUME_NUM") 
	oGetTrC4 := TGet():New(aPosObj[2,2]+60,240,{|u| if(PCount()>0,cGetTrC4:=u,cGetTrC4)},oPnlTrans,080,10,"@!",{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrC4")
	cGetTrC5 := Val( RetTag("VOLUME_PESOB") )
	oGetTrC5 := TGet():New(aPosObj[2,2]+60,340,{|u| if(PCount()>0,cGetTrC5:=u,cGetTrC5)},oPnlTrans,090,10,PesqPict("SF1","F1_PESOL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrC5")
	cGetTrC6 := Val( RetTag("VOLUME_PESOL") )
	oGetTrC6 := TGet():New(aPosObj[2,2]+60,440,{|u| if(PCount()>0,cGetTrC6:=u,cGetTrC6)},oPnlTrans,100,10,PesqPict("SF1","F1_PESOL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetTrC6")
	
	// painel dos impostos
	oPnlImp  := TPanel():New(aPosObj[3,1],aPosObj[3,2],"Impostos e Tributos",oDlg,,,,,CLR_WHITE,aObjects[3,1],aObjects[3,2],.T.,.T.)
	// primeira linha de dados de impostos
	oSayImpA1 := TSay():New(aPosObj[3,2]+00,002, {|| "Base de Cálculo ICMS" },oPnlImp,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	oSayImpA2 := TSay():New(aPosObj[3,2]+00,120, {|| "Valor ICMS"},oPnlImp,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	oSayImpA3 := TSay():New(aPosObj[3,2]+00,200, {|| "Base Cálculo ICMS Substituição" },oPnlImp,,oFontCabec,,,,.t.,CLR_RED,,200,21)
	oSayImpA4 := TSay():New(aPosObj[3,2]+00,370, {|| "Valor ICMS Substituição" },oPnlImp,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	oSayImpA5 := TSay():New(aPosObj[3,2]+00,500, {|| "Valor Total Produtos" },oPnlImp,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	cGetImpA1 := Val( RetTag("IMP_BCICMS") )
	oGetImpA1 := TGet():New(aPosObj[3,2]+10,002,{|u| if(PCount()>0,cGetImpA1:=u,cGetImpA1)},oPnlImp,100,10,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetImpA1")
	cGetImpA2 := Val( RetTag("IMP_VALICMS") )
	oGetImpA2 := TGet():New(aPosObj[3,2]+10,120,{|u| if(PCount()>0,cGetImpA2:=u,cGetImpA2)},oPnlImp,070,10,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetImpA2")
	cGetImpA3 := Val( RetTag("IMP_BCST") )
	oGetImpA3 := TGet():New(aPosObj[3,2]+10,200,{|u| if(PCount()>0,cGetImpA3:=u,cGetImpA3)},oPnlImp,160,10,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetImpA3")
	cGetImpA4 := Val( RetTag("IMP_VALSUBTRIB") )
	oGetImpA4 := TGet():New(aPosObj[3,2]+10,370,{|u| if(PCount()>0,cGetImpA4:=u,cGetImpA4)},oPnlImp,110,10,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetImpA4")
	cGetImpA5 := Val( RetTag("IMP_VALTOTPROD") )
	oGetImpA5 := TGet():New(aPosObj[3,2]+10,500,{|u| if(PCount()>0,cGetImpA5:=u,cGetImpA5)},oPnlImp,100,10,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetImpA5")

	// segunda linha de dados de impostos
	oSayImpB1 := TSay():New(aPosObj[3,2]+25,002, {|| "Valor do Frete" },oPnlImp,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	oSayImpB2 := TSay():New(aPosObj[3,2]+25,102, {|| "Valor do Seguro"},oPnlImp,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	oSayImpB3 := TSay():New(aPosObj[3,2]+25,202, {|| "Desconto" },oPnlImp,,oFontCabec,,,,.t.,CLR_RED,,200,21)
	oSayImpB4 := TSay():New(aPosObj[3,2]+25,302, {|| "Outras Despesas" },oPnlImp,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	oSayImpB5 := TSay():New(aPosObj[3,2]+25,402, {|| "Valor IPI" },oPnlImp,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	oSayImpB6 := TSay():New(aPosObj[3,2]+25,502, {|| "Valor Total Nota" },oPnlImp,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	cGetImpB1 := Val( RetTag("IMP_VALFRETE") )
	oGetImpB1 := TGet():New(aPosObj[3,2]+35,002,{|u| if(PCount()>0,cGetImpB1:=u,cGetImpB1)},oPnlImp,080,10,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetImpB1")
	cGetImpB2 := Val( RetTag("IMP_VALSEG") )
	oGetImpB2 := TGet():New(aPosObj[3,2]+35,102,{|u| if(PCount()>0,cGetImpB2:=u,cGetImpB2)},oPnlImp,080,10,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetImpB2")
	cGetImpB3 := Val( RetTag("IMP_VALDESC") )
	oGetImpB3 := TGet():New(aPosObj[3,2]+35,202,{|u| if(PCount()>0,cGetImpB3:=u,cGetImpB3)},oPnlImp,080,10,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetImpB3")
	cGetImpB4 := Val( RetTag("IMP_VALOUTROS") )
	oGetImpB4 := TGet():New(aPosObj[3,2]+35,302,{|u| if(PCount()>0,cGetImpB4:=u,cGetImpB4)},oPnlImp,080,10,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetImpB4")
	cGetImpB5 := Val( RetTag("IMP_VALIPI") )
	oGetImpB5 := TGet():New(aPosObj[3,2]+35,402,{|u| if(PCount()>0,cGetImpB5:=u,cGetImpB5)},oPnlImp,080,10,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetImpB5")
	cGetImpB6 := Val( RetTag("IMP_VALTOTNF") )
	oGetImpB6 := TGet():New(aPosObj[3,2]+35,502,{|u| if(PCount()>0,cGetImpB6:=u,cGetImpB6)},oPnlImp,080,10,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetImpB6")

	// painel da MsNewGetDados
	oPnlMGet  := TPanel():New(aPosObj[4,1],aPosObj[4,2],"",oDlg,,,,,CLR_WHITE,aObjects[4,1],aObjects[4,2],.T.,.T.)
	oGetDados := MsNewGetDados():New(00,00,00,00,GD_INSERT+GD_ALTERA+GD_DELETE,,,,Iif(_lAlter,aHeaderAlt,{}),,999,,,,oPnlMGet,aHeader,aCols)
	oGetDados:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT 	// faz com que o objeto ocupe todo o panel.
	oGetDados:Refresh() 

	// painel Informacoes complementares
	oPnlInfA1 := TPanel():New(aPosObj[5,1],aPosObj[5,2],"Informações Complementares",oDlg,,,,,CLR_WHITE,aObjects[5,1],aObjects[5,2],.T.,.T.)
	cGetInfA1 := RetTag("INF_ADICIONAL") 
	oGetInfA1 := TGet():New(aPosObj[5,2]+05,002,{|u| if(PCount()>0,cGetInfA1:=u,cGetInfA1)},oPnlInfA1,aObjects[5,1]-10,10,"@!",{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetInfA1")
	cGetInfA2 := RetTag("INF_PROTOCOLO") 
	oGetInfA2 := TGet():New(aPosObj[5,2]+20,002,{|u| if(PCount()>0,cGetInfA2:=u,cGetInfA2)},oPnlInfA1,aObjects[5,1]-10,10,"@!",{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetInfA2")

	// painel total dos impostos de DI, mesma linha das Info Complementares
	oPnlDI  := TPanel():New(aPosObj[5,1],aPosObj[5,2]+aObjects[5,1]+5,"Total dos Impostos de DI",oDlg,,,,,CLR_WHITE,aObjects[6,1],aObjects[6,2],.T.,.T.)
	oSayDIA1 := TSay():New(aPosObj[7,2]+05,002, {|| "Base Cálculo:" },oPnlDI,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	oSayDIA2 := TSay():New(aPosObj[7,2]+15,002, {|| "Valor Despacho:" },oPnlDI,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	oSayDIA3 := TSay():New(aPosObj[7,2]+25,002, {|| "Valor do II:" },oPnlDI,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	oSayDIA4 := TSay():New(aPosObj[7,2]+35,002, {|| "Valor do IOF:" },oPnlDI,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	cGetDIA1 := SomaTag(VAL_BSCII)
	oGetDIA1 := TGet():New(aPosObj[7,2]+04,085,{|u| if(PCount()>0,cGetDIA1:=u,cGetDIA1)},oPnlDI,aObjects[7,1]-090,08,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetDIA1")
	cGetDIA2 := SomaTag(VAL_DESPA)
	oGetDIA2 := TGet():New(aPosObj[7,2]+14,085,{|u| if(PCount()>0,cGetDIA2:=u,cGetDIA2)},oPnlDI,aObjects[7,1]-090,08,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetDIA2")
	cGetDIA3 := SomaTag(VAL_II)
	oGetDIA3 := TGet():New(aPosObj[7,2]+24,085,{|u| if(PCount()>0,cGetDIA3:=u,cGetDIA3)},oPnlDI,aObjects[7,1]-090,08,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetDIA3")
	cGetDIA4 := SomaTag(VAL_IOF)
	oGetDIA4 := TGet():New(aPosObj[7,2]+34,085,{|u| if(PCount()>0,cGetDIA4:=u,cGetDIA4)},oPnlDI,aObjects[7,1]-090,08,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetDIA4")

	// painel total dos PIS e COFINS, mesma linha das Info Complementares
	oPnlPIS  := TPanel():New(aPosObj[5,1],aPosObj[5,2]+aObjects[5,1]+aObjects[6,1]+10,"Total de PIS, COFINS e Despesas de Transporte",oDlg,,,,,CLR_WHITE,aObjects[7,1],aObjects[7,2],.T.,.T.)
	oSayPISA1 := TSay():New(aPosObj[7,2]+05,002, {|| "Pis:" },oPnlPIS,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	oSayPISA2 := TSay():New(aPosObj[7,2]+15,002, {|| "COFINS:"},oPnlPIS,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	oSayPISA2 := TSay():New(aPosObj[7,2]+25,002, {|| "Frete/Descontos/Seguro:"},oPnlPIS,,oFontCabec,,,,.t.,CLR_RED,,150,21)
	cGetPISA1 := Val( RetTag("IMP_VALPIS") )
	oGetPISA1 := TGet():New(aPosObj[7,2]+04,100,{|u| if(PCount()>0,cGetPISA1:=u,cGetPISA1)},oPnlPIS,aObjects[7,1]-100,08,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetPISA1")
	cGetPISA2 := Val( RetTag("IMP_VALCOFINS") )
	oGetPISA2 := TGet():New(aPosObj[7,2]+14,100,{|u| if(PCount()>0,cGetPISA2:=u,cGetPISA2)},oPnlPIS,aObjects[7,1]-100,08,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetPISA2")
	cGetPISA3 := cGetImpB1 + cGetImpB2 + cGetImpB3
	oGetPISA3 := TGet():New(aPosObj[7,2]+24,100,{|u| if(PCount()>0,cGetPISA3:=u,cGetPISA3)},oPnlPIS,aObjects[7,1]-100,08,PesqPict("SD1","D1_TOTAL"),{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,"cGetPISA3")
    */

//Linha abaixo exatamente igual ao comando ACTIVATE comum so que permite habilitar a oDlg e a enchoicebar ja na mesma chamada
oDlg:Activate(,,,.T.,,,bEnchBarOn)

RESET ENVIRONMENT

Return(.T.)
