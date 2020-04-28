#include 'protheus.ch'
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "COLORS.CH"

User Function TSTUI()
	Local oContDesktop
	Local oPanelMain
	Local oWSFV12
	// variáveis para construção de tela
	Local _lAlter		:= .F.
	Local oFontTitulo	:= TFont():New('Arial',,20,,.T.)
	Local oFontCabec	:= TFont():New('Courier New',,18,,.t.)
	Local oFontItem		:= TFont():New("Century",,14,,.t.,,,,.t.)
	// variáveis dos processos envolvidos
	Local nRefresINI	:= Val(GetPvProfString("TECMONITOR","RefreshINI","undefined","appserver.ini"))
	Local cEmpresa      := GetPvProfString("TECMONITOR","Empresa","undefined","appserver.ini")
	Local cCodEmp       := SubStr(cEmpresa,1,AT(",",cEmpresa)-1)
	Local cCodFil       := SubStr(cEmpresa,AT(",",cEmpresa)+1)
	Local nBINVersion   := Val(GetPvProfString("TECMONITOR","BINVersion","undefined","appserver.ini"))
	Local nSetEnv       := Val(GetPvProfString("TECMONITOR","SetEnv"    ,"undefined","appserver.ini"))
	Local nERPVersion   := Val(GetPvProfString("TECMONITOR","ERPVersion","undefined","appserver.ini"))
	Local nTRBCount     := Val(GetPvProfString("TECMONITOR","TRBCount"  ,"undefined","appserver.ini"))
	Local nTOPCount     := Val(GetPvProfString("TECMONITOR","TOPCount"  ,"undefined","appserver.ini"))
	Local nUserList     := Val(GetPvProfString("TECMONITOR","USERList"  ,"undefined","appserver.ini"))
	// Coleta dos valores que está em Variável Global no Server
	//Local aGlbAll		:= {}
	//VarGetAA(GLBDataSrv,@aGlbAll)

    DEFINE WINDOW oMainWnd FROM 000,000 TO 600,800 PIXEL TITLE I18N("TOTVS | VPTEC Tools")

	//--------------------------------------------------------------
	// Cria Painel de fundo para a criação dos componentes
	//--------------------------------------------------------------
	oContDeskTop := tPanelCss():New(000,000,,oMainWnd,,,,,,000,000,.F.,.F.)
	oContDeskTop:Align := CONTROL_ALIGN_ALLCLIENT
	oContDeskTop:ReadClientCoors(.T., .T.)

	//--------------------------------------------------------------
	// Cria barra superior com as opções padrão
	//--------------------------------------------------------------
	oWSFV12 := FWWSF12():New( oContDesktop )
	oWSFV12:aButtons := {}
	oWSFV12:AddButton("LSINFO","info.png"  ,"",{|| alert("INFO")}, CONTROL_ALIGN_RIGHT )
	oWSFV12:AddButton("LSHELP","help.png"  ,"",{|| alert("HELP")}, CONTROL_ALIGN_RIGHT )
	oWSFV12:AddButton("LSCOMM","sinc.png"  ,"",{|| alert("SINC")}, CONTROL_ALIGN_RIGHT )
	oWSFV12:AddButton("LSMAIL","mailto.png","",{|| alert("MAIL")}, CONTROL_ALIGN_RIGHT )
	oWSFV12:AddButton("LSUSER","user.png"  ,"",{|| alert("USER")}, CONTROL_ALIGN_RIGHT ) 
    oWSFV12:Activate()

	oPanelMain := oWSFV12:GetPMenu()
    oPanelMain:Align := CONTROL_ALIGN_ALLCLIENT
    oFolder := LSUIFolder():New(oPanelMain)
    oFolder:Activate()

	oPnlParam  := TPanel():New(025,005,"Parametros da Rotina",oPanelMain,oFontTitulo,,,CLR_BLACK,CLR_WHITE,200,490,.F.,.T.)
	oSayPT := TSay():New(015+00,010, {|| "Refresh de Dados:" },oPnlParam,,oFontCabec,,,,.t.,CLR_BLACK,,100,20)
	oSayPP := TSay():New(015+00,095, {|| '"RefreshINI"' },oPnlParam,,oFontCabec,,,,.t.,CLR_RED,,100,20)
	oGetPC := TGet():New(013+00,150,{|u| if(PCount()>0,nRefresINI:=u,nRefresINI)},oPnlParam,40,10,'999',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,'nRefresINI')

	oSayPT := TSay():New(015+15,010, {|| "Environment HOST:" },oPnlParam,,oFontCabec,,,,.t.,CLR_BLACK,,100,20)
	oSayPP := TSay():New(015+15,095, {|| '"SetEnv"' },oPnlParam,,oFontCabec,,,,.t.,CLR_RED,,100,20)
	oGetPC := TGet():New(013+15,150,{|u| if(PCount()>0,nSetEnv:=u,nSetEnv)},oPnlParam,40,10,'999',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,'nSetEnv')

	oSayPT := TSay():New(015+30,010, {|| "Binário do AppServer:"},oPnlParam,,oFontCabec,,,,.t.,CLR_BLACK,,100,20)
	oSayPP := TSay():New(015+30,095, {|| '"BINVersion"' },oPnlParam,,oFontCabec,,,,.t.,CLR_RED,,100,20)
	oGetPC := TGet():New(013+30,150,{|u| if(PCount()>0,nBINVersion:=u,nBINVersion)},oPnlParam,40,10,'999',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,'nBINVersion')

	oSayPT := TSay():New(015+45,010, {|| "Versão do AppServer:"},oPnlParam,,oFontCabec,,,,.t.,CLR_BLACK,,100,20)
	oSayPP := TSay():New(015+45,095, {|| '"BINVersion"' },oPnlParam,,oFontCabec,,,,.t.,CLR_RED,,100,20)
	oGetPC := TGet():New(013+45,150,{|u| if(PCount()>0,nBINVersion:=u,nBINVersion)},oPnlParam,40,10,'999',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,'nBINVersion')

	oSayPT := TSay():New(015+60,010, {|| "Release Protheus:" },oPnlParam,,oFontCabec,,,,.t.,CLR_BLACK,,100,20)
	oSayPP := TSay():New(015+60,095, {|| '"ERPVersion"' },oPnlParam,,oFontCabec,,,,.t.,CLR_RED,,100,20)
	oGetPC := TGet():New(013+60,150,{|u| if(PCount()>0,nERPVersion:=u,nERPVersion)},oPnlParam,40,10,'999',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,'nERPVersion')

	oSayPT := TSay():New(015+75,010, {|| "Teste RDD Local:"  },oPnlParam,,oFontCabec,,,,.t.,CLR_BLACK,,100,20)
	oSayPP := TSay():New(015+75,095, {|| '"TRBCount"' },oPnlParam,,oFontCabec,,,,.t.,CLR_RED,,100,20)
	oGetPC := TGet():New(013+75,150,{|u| if(PCount()>0,nTRBCount:=u,nTRBCount)},oPnlParam,40,10,'999',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,'nTRBCount')

	oSayPT := TSay():New(015+90,010, {|| "Teste DBAccess:"   },oPnlParam,,oFontCabec,,,,.t.,CLR_BLACK,,100,20)
	oSayPP := TSay():New(015+90,095, {|| '"TOPCount"' },oPnlParam,,oFontCabec,,,,.t.,CLR_RED,,100,20)
	oGetPC := TGet():New(013+90,150,{|u| if(PCount()>0,nTOPCount:=u,nTOPCount)},oPnlParam,40,10,'999',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,'nTOPCount')

	oSayPT := TSay():New(015+105,010, {|| "Lista de usuários:"},oPnlParam,,oFontCabec,,,,.t.,CLR_BLACK,,100,20)
	oSayPP := TSay():New(015+105,095, {|| '"UserList"' },oPnlParam,,oFontCabec,,,,.t.,CLR_RED,,100,20)
	oGetPC := TGet():New(013+105,150,{|u| if(PCount()>0,nUserList:=u,nUserList)},oPnlParam,40,10,'999',{|o| .t. },,,oFontItem,,,.T.,,,,,,,!(_lAlter),,,'nUserList')

	oPnlDetail  := TPanel():New(025,250,"Dados Coletados",oPanelMain,oFontTitulo,,,CLR_BLACK,CLR_WHITE,400,490,.F.,.T.)


    ACTIVATE WINDOW oMainWnd MAXIMIZED
	
Return
