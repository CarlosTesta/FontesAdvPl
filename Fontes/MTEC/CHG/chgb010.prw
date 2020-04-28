#INCLUDE "TOTVS.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

#DEFINE nTamEtiq TamSX3('ZY_ID')[1]+1        //- Tamanho da etiqueta a ser lida lembrando que tem um byte do leitor
#DEFINE DIRCTRL "\CHG\IMPRCONF\"
#DEFINE cFileImp 'chgb010'
#DEFINE nMaxFolha 28       //- Total de itens por folha 35 itens eh o total maximo de itens na folha
//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Constantes do relatorio Papel   ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
// dimensoes e fontes principais
#DEFINE cFontName "Courier New"  // Nome da Fonte Principal
#DEFINE cFntCabec "Courier New"  // Nome da fonte usada no cabecalho

// posicionamento da pagina e do cabecalho
#DEFINE nMargEsq  0010  // Margem esquerda do relatorio
#DEFINE nMargTop  0000  // Margem Superior do relatorio
#DEFINE nNewLine  10    // Valor do tamanho de uma linha

// posicao do logo do cabecalho
#DEFINE nLogoEsq  nMargEsq+2 // Esquerda
#DEFINE nLogoTop  nMargTop+nNewLine+2 // Topo
#DEFINE cPrior    "'01','02'" //- Prioridades de pedidos urgentes
#DEFINE cUrgente  '0,00,01,02,03,04'

Static cNomePrint := 'Printer'
Static cImpEtiq   := Space(6)
Static nCalcMeta  := 0    //- Controla o Calculo da meta para 10 Minutos

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณCHGB010   บAutor  ณNilton A. Rodrigues บ Data ณ  29/10/2014 บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณRotina de impressao de prenotas                             บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Function U_CHGB010
	Local cCracha := Space(nTamEtiq)
	Local lOk      as logical 
	Local oTimer   as logical 
	Local bInit := {|| U_CheckRPO(),StatusPed()}

	Local oBmpNoPed     as object 
	Local oBmpNormal    as object
	Local oBtn_Baixa    as object
	Local oBtn_Fechar   as object
	Local oBtn_Monitor  as object
	Local oGroup1       as object
	Local oGroup2       as object
	Local oGroup3
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4
	Local oSay5
	Local oSay6
	Local oSay7
	Local oSay8
	Local bKeyF4  := {|| TeclasFunc(.T.),oTimer:lActive := .F.,U_CHGB164(),oTimer:lActive := .T.,eVal(bInit),TeclasFunc(.F.),oCracha:SetFocus(), oCracha:SelectAll(),oDlg_B010:Refresh()}
	Local bKeyF5  := {|| TeclasFunc(.T.),oTimer:lActive := .F.,Monitor(),oTimer:lActive := .T.,eVal(bInit),TeclasFunc(.F.),oCracha:SetFocus(), oCracha:SelectAll(),oDlg_B010:Refresh()}
	Local bKeyF9  := {|| TeclasFunc(.T.),oTimer:lActive := .F.,U_CHGW011(.T.),oTimer:lActive := .T.,eVal(bInit),TeclasFunc(.F.),oCracha:SetFocus(), oCracha:SelectAll(),oDlg_B010:Refresh()}
	Local bKeyF12 := {|| oTimer:lActive := .F.,TeclasFunc(.T.),oDlg_B010:End()}
	Local oBmp_Urgente
	Local oBitmap1

	Private oCracha
	Private oBmp_Bar_A
	Private oBmp_Bar_C
	Private oBmp_Bar_E
	Private oBmp_Bar_F
	Private oBmp_Bar_G
	Private oBmp_Bar_K
	Private oDlg_B010
	Private oSetup
	Private aKeyFunc  := {}
	Private nTimeSleep := 5000
	dbSelectArea("SA4")
	SA4->(dbSetOrder(1))
	dbSelectArea("CB5")
	CB5->(dbSetOrder(1))
	dbSelectArea("SC5") //- Cadastro de Pedidos de Vendas (cabecalho)
	SC5->(dbSetOrder(1))
	dbSelectArea("SDC") //- Cadastro de Itens de Pedidos de Vendas (Localizacao)
	SDC->(dbSetOrder(1))
	dbSelectArea("SZJ") //- Cadastro de Avaliacao da Atividade
	SZJ->(dbSetOrder(1))       //- Funcionario + Data Final

	AADD(aKeyFunc,{VK_F4  ,bKeyF4})
	AADD(aKeyFunc,{VK_F5  ,bKeyF5})
	If !SuperGetMv('CHGWMSRF')
		AADD(aKeyFunc,{VK_F9  ,bKeyF9})
	EndIf
	AADD(aKeyFunc,{VK_F12 ,bKeyF12})

	//ConOut(APXTo64( Upper( AllTrim( '226704' ) ) ))
	//ConOut(APXTo64( Embaralha( Upper( AllTrim( '226704' ) ) , 1 ) ))

	//- Busca a impressora configurada
	PrinterVld()

	//- processa os pedidos do dia anterior
	ProcDayLast()

	dbSelectArea("SZY") //- Cadastro de Recursos Humano
	SZY->(dbSetOrder(1))

	//- habilita as teclas de fun็ใo
	TeclasFunc(.F.)

	DEFINE MSDIALOG oDlg_B010 TITLE "Monitor de Atividades - WMS-CHG" FROM 000, 000  TO 220, 500 COLORS 0, 16777215 PIXEL Style DS_MODALFRAME

	oDlg_B010:lEscClose := .F.

	@ 005, 006 GROUP oGroup1 TO 038, 082 PROMPT "Leitura do Crachแ" OF oDlg_B010 COLOR 0, 16777215 PIXEL
	@ 017, 013 MSGET oCracha VAR cCracha SIZE 060, 010 OF oDlg_B010  COLORS 0, 16777215 PASSWORD PIXEL
	oCracha:bValid := {||.F.,oTimer:lActive := .F., VldCracha(@cCracha,@lOk),oDlg_B010:cCaption:= "Atividade: "+cNomePrint,;
	oTimer:lActive := .T.,IIF(lOk,lOk,(StatusPed(),oCracha:SetFocus(), oCracha:SelectAll(),oDlg_B010:Refresh()))}

	@ 005, 087 GROUP oGroup2 TO 038, 241 PROMPT "Legenda" OF oDlg_B010 COLOR 16711680, 16777215 PIXEL

	@ 013, 091 BITMAP oBmpNormal SIZE 010, 010 OF oDlg_B010 RESOURCE "ENABLE" NOBORDER PIXEL
	@ 013, 104 SAY oSay1 PROMPT "Com Atividade" SIZE 041, 007 OF oDlg_B010 COLORS 0, 16777215 PIXEL

	@ 013, 174 BITMAP oBitmap1   SIZE 010, 010 OF oDlg_B010 RESOURCE "BR_LARANJA" NOBORDER PIXEL
	@ 013, 187 SAY oSay3 PROMPT "Atrasado" SIZE 031, 007 OF oDlg_B010 COLORS 0, 16777215 PIXEL

	@ 026, 091 BITMAP oBmpNoPed  SIZE 010, 010 OF oDlg_B010 RESOURCE "DISABLE" NOBORDER PIXEL
	@ 026, 104 SAY oSay2 PROMPT "Sem Atividade" SIZE 041, 007 OF oDlg_B010 COLORS 0, 16777215 PIXEL

	@ 026, 174 BITMAP oBmp_Urgente SIZE 010, 010 OF oDlg_B010 RESOURCE "BR_AZUL" NOBORDER PIXEL
	@ 026, 187 SAY oSay9 PROMPT "URGENTE" SIZE 031, 007 OF oDlg_B010 COLORS 0, 16777215 PIXEL

	@ 043, 007 GROUP oGroup3 TO 083, 240 PROMPT "Status Armaz้m" OF oDlg_B010 COLOR 0, 16777215 PIXEL

	@ 053, 011 BITMAP oBmp_Bar_A SIZE 010, 010 OF oDlg_B010 RESOURCE "ENABLE" NOBORDER PIXEL
	@ 053, 024 SAY oSay4 PROMPT "Armaz้m A" SIZE 031, 007 OF oDlg_B010 COLORS 0, 16777215 PIXEL

	@ 053, 082 BITMAP oBmp_Bar_C SIZE 010, 010 OF oDlg_B010 RESOURCE "ENABLE" NOBORDER PIXEL
	@ 053, 095 SAY oSay6 PROMPT "Armaz้m C" SIZE 031, 007 OF oDlg_B010 COLORS 0, 16777215 PIXEL

	@ 053, 151 BITMAP oBmp_Bar_G SIZE 010, 010 OF oDlg_B010 RESOURCE "ENABLE" NOBORDER PIXEL
	@ 053, 164 SAY oSay8 PROMPT "Barracใo G" SIZE 031, 007 OF oDlg_B010 COLORS 0, 16777215 PIXEL

	@ 068, 011 BITMAP oBmp_Bar_E SIZE 010, 010 OF oDlg_B010 RESOURCE "ENABLE" NOBORDER PIXEL
	@ 068, 024 SAY oSay5 PROMPT "Barracใo E" SIZE 031, 007 OF oDlg_B010 COLORS 0, 16777215 PIXEL

	@ 068, 082 BITMAP oBmp_Bar_F SIZE 010, 010 OF oDlg_B010 RESOURCE "ENABLE" NOBORDER PIXEL
	@ 068, 095 SAY oSay7 PROMPT "Barracใo F" SIZE 031, 007 OF oDlg_B010 COLORS 0, 16777215 PIXEL

	@ 068, 151 BITMAP oBmp_Bar_K SIZE 010, 010 OF oDlg_B010 RESOURCE "ENABLE" NOBORDER PIXEL
	@ 068, 164 SAY oSay8 PROMPT "Barracใo K" SIZE 031, 007 OF oDlg_B010 COLORS 0, 16777215 PIXEL

	@ 090, 070 BUTTON oBtn_Monitor PROMPT "F4 - P.Monitor" SIZE 050, 012  ACTION eVal(bKeyF4) PIXEL
	@ 090, 130 BUTTON oBtn_Monitor PROMPT "F5 - Monitor" SIZE 050, 012  ACTION eVal(bKeyF5) PIXEL
	@ 090, 190 BUTTON oBtn_Fechar  PROMPT "F12 - Fechar"  SIZE 050, 012  ACTION eVal(bKeyF12) PIXEL
	If !SuperGetMv('CHGWMSRF')
		@ 090, 006 BUTTON oBtn_Baixa  PROMPT "F9 - Baixar"  SIZE 050, 012  ACTION eVal(bKeyF9) PIXEL
	EndIf
	oDlg_B010:bInit := bInit

	oTimer:=TTimer():New(20000,oDlg_B010:bInit,oDlg_B010)
	oTimer:lActive := .T.

	ACTIVATE MSDIALOG oDlg_B010 CENTERED

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณVldCracha บAutor  ณNilton A. Rodrigues บ Data ณ 29/10/2014  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณFuncao de validacao e processamento da prenota              บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function VldCracha(cCracha,lOk)
	Local cLockKey   as character 
	Local lContinua  as logical 
	Local nContBlq   as numeric 
	Local _aArea     as array 
	Local aAtividade as array 
	Local cQuery     as character
	Local cServidor  as character 
	Local cUserLogin as character
	Private cLockLog   as character 
	Private cTimeBloq  as character

	cLockLog := 'B010BLOQ'+AllTrim(cNumEmp)+'.blq'  

	cLockKey      := 'B010LCK'+AllTrim(cNumEmp)
	lContinua     := .T.
	nContBlq      := 0
	_aArea        := GetArea()
	aAtividade    := {}
	cServidor     := ComputerName()
	cUserLogin    := LogUserName()

	//- Verifica se houve alteracao na data do sistema
	If MsDate() <> dDataBase
		Final('Data Invแlida')
		RestArea(_aArea)
		aSize(_aArea,0)
		aSize(aAtividade,0)
		aAtividade := nil
		_aArea := nil
		lOk := .T.
		Return .F.
	EndIf

	//- VALIDACOES DO CRACHA
	If cCracha == NIL .or. Empty(cCracha)
		cCracha := Space(nTamEtiq)
		RestArea(_aArea)
		aSize(_aArea,0)
		aSize(aAtividade,0)
		aAtividade := nil
		_aArea := nil
		lOk := .T.
		Return .T.
	EndIf

	If AllTrim(Lower(cCracha)) == '7edr4nag'
		If !ValidPrint()
			Help(" ",1,"NOPRINTGRA")
			Final("Impressora")
		EndIf
		cCracha := Space(nTamEtiq)
		RestArea(_aArea)
		aSize(_aArea,0)
		aSize(aAtividade,0)
		aAtividade := nil
		_aArea := nil
		lOk    := .F.
		Return .F.
	EndIf

	//- VERIFICA SE EXISTE O CRACHA
	If !U_SeekCracha(cCracha,'129')
		cCracha := Space(nTamEtiq)
		RestArea(_aArea)
		aSize(_aArea,0)
		aSize(aAtividade,0)
		aAtividade := nil
		_aArea := nil
		lOk    := .F.
		Return .F.
	EndIf
	//-------------------------------------------------
	//- verifica e carrega as atividade configurada
	//-------------------------------------------------
	If !SeekExp(@aAtividade)
		U_AvisoExp("Atividade","Aten็ใo voc๊ nใo possui nenhuma atividade configurada!",.T.)
		cCracha := Space(nTamEtiq)
		RestArea(_aArea)
		aSize(_aArea,0)
		aSize(aAtividade,0)
		aAtividade := nil
		_aArea := nil
		lOk    := .F.
		Return .F.
	EndIf

	If Empty(SZY->ZY_ARMAZEM)
		U_AvisoExp('Sem Armaz้m',"Aten็ใo nใo existem armaz้m configurado, procure pelo supervisor para que o mesmo cadastre",.T.)
		cCracha := Space(nTamEtiq)
		RestArea(_aArea)
		aSize(_aArea,0)
		aSize(aAtividade,0)
		aAtividade := nil
		_aArea := nil
		lOk    := .F.
		Return .F.
	EndIf

	//-------------------------------------
	//- checa se ha pendencia no carrinho
	//-------------------------------------
	If !U_ChkPenAtv('D')
		cCracha := Space(nTamEtiq)
		RestArea(_aArea)
		aSize(_aArea,0)
		aSize(aAtividade,0)
		aAtividade := nil
		_aArea := nil
		lOk    := .F.
		Return .F.
	EndIf


	If Empty(cImpEtiq)
		U_AvisoExp('Impressora Etiqueta','Aten็ใo nใo existe impressora de etiqueta configurada',.T.)
		cCracha := Space(nTamEtiq)
		RestArea(_aArea)
		aSize(_aArea,0)
		aSize(aAtividade,0)
		aAtividade := nil
		_aArea := nil
		lOk    := .F.
		Return .F.
	EndIf

	cCracha := Space(nTamEtiq)

	nContBlq  := 0
	lContinua := .T.

	//- Verifica se nao existe ninguem usando a impressao
	cTimeBloq := Time()

	While lContinua
		Sleep(850)//- segura
		If LockByName(cLockKey,.T.,.T.,.F.)
			MemoWrite(cLockLog,;
			'Tipo...: ENTRANDO NO SISTEMA'+CRLF+;
			'Pedido.: '+CRLF+;
			'Data...: '+dToc(dDataBase)+' - '+cTimeBloq+CRLF+;
			'Maquina: '+ UPPER(ComputerName())+CRLF+;
			'Usuario: '+ LogUserName()+CRLF+;
			'Cracha.: '+SZY->ZY_CODIGO+CRLF+;
			'Nome...: '+AllTrim(SZY->ZY_NOME))

			Exit
		EndIf

		U_AvisoExp('Em uso por outra Esta็ใo - '+cTimeBloq,MemoRead(cLockLog),.F.,0,nTimeSleep)

		nContBlq ++

		If nContBlq > 10
			lContinua := .F.
			U_AvisoExp('Serial',"Processo abortado limite de tentativas excedidas, tente novamente",.T.)
			RestArea(_aArea)
			aSize(_aArea,0)
			_aArea := nil
			lOk    := .F.
			Return .F.
		EndIf
	EndDo

	If lContinua
		dbSelectArea("SC5")

		FwMsgRun(,{|oSay| Prenota(aAtividade)},'Impressใo Atividade',cNomePrint+' - Imprimindo...')

		MsUnLockAll()


		MemoWrite(cLockLog,;
		'Tipo...: liberando Sistema'+CRLF+;
		'Pedido.: '+CRLF+;
		'Data...: '+dToc(dDataBase)+' - '+Time()+CRLF+;
		'Maquina: '+ UPPER(ComputerName())+CRLF+;
		'Usuario: '+ LogUserName()+CRLF+;
		'Nome...: ')

		//- Libera a chave para uso
		UnLockByName(cLockKey,.T.,.T.,.F.)

	EndIf
	//----------------------------------------------------
	//- Libera todos os nomes reservados pela MayIUseCode
	//----------------------------------------------------
	FreeUsedCode()
	RestArea(_aArea)
	aSize(_aArea,0)
	aSize(aAtividade,0)
	aAtividade := nil
	_aArea := nil
	lOk    := .F.
Return .F.


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณPrenota   บAutor  ณNilton A. Rodrigues บ Data ณ 29/10/2014  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao responsavel por montar os dados a serem impresso na บฑฑ
ฑฑบ          ณ prenota                                                    บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function PreNota(aAtividade)
	Local oPrint
	Local cFile
	Local nX
	Local nTotFor := Len(aAtividade)
	Local lImp    := .F.

	Private nLarReport
	Private nAltReport
	Private aLocais   := {}


	//- Seleciona o drive para impressora
	If Impressora(@oPrint,@cFile)
		Begin TransAction
			For nX := 1 To nTotFor
				//- busca o pedido a ser impresso
				If aAtividade[nX] == 'F' //- Prenota de separacao
					If (lImp:= SearchPed(@oPrint))
						Exit
					EndIf
				ElseIf aAtividade[nX] == 'B'
					//----------------------------------------------
					//- checa o uso da rotina esta habilitada em RF
					//----------------------------------------------
					If !SuperGetMv('CHGWMSRF')
						If (lImp:=SearchEst(@oPrint))//- Pick List de entrada
							Exit
						EndIf
					EndIf
				EndIf
			Next nX
		End TransAction
		//----------------------------------
		//- indica que nao houve atividade
		//----------------------------------
		If !lImp
			U_AvisoExp('Sem Atividade','Aten็ใo nใo existe atividade na Fila')
		EndIf
		fErase(cFile+'.rel')

	EndIf

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณValidPrintบAutor  ณNilton A. Rodrigues บ Data ณ 29/10/2014  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao responsavel por montar os dados a serem impresso na บฑฑ
ฑฑบ          ณ prenota                                                    บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function ValidPrint
	Local cSession     := GetPrinterSession()
	Local nFlags
	Local aDevice := {}
	Local nLocal
	Local nOrientation
	Local cDevice
	Local nPrintType


	//- seta o flag do que sera permitido alterar
	nFlags := PD_ISTOTVSPRINTER + PD_DISABLEPAPERSIZE + PD_DISABLEPREVIEW + PD_DISABLEMARGIN

	AADD(aDevice,"DISCO") // 1
	AADD(aDevice,"SPOOL") // 2
	AADD(aDevice,"EMAIL") // 3
	AADD(aDevice,"EXCEL") // 4
	AADD(aDevice,"HTML" ) // 5
	AADD(aDevice,"PDF"  ) // 6

	//- forca os valores de setup
	nLocal       	:= 2 //- If(fwGetProfString(cSession,"LOCAL","SERVER",.T.)=="SERVER",1,2 )
	nOrientation 	:= 1 //-If(fwGetProfString(cSession,"ORIENTATION","PORTRAIT",.T.)=="PORTRAIT",1,2)
	cDevice     	:= 'SPOOL' //-If(Empty(fwGetProfString(cSession,"PRINTTYPE","SPOOL",.T.)),"PDF",fwGetProfString(cSession,"PRINTTYPE","SPOOL",.T.))
	nPrintType     := aScan(aDevice,{|x| x == cDevice })


	oSetup := FWPrintSetup():New(nFlags, "PRENOTA")
	// ----------------------------------------------
	// Define saida
	// ----------------------------------------------
	oSetup:SetPropert(PD_PRINTTYPE   , nPrintType)
	oSetup:SetPropert(PD_ORIENTATION , nOrientation)
	oSetup:SetPropert(PD_DESTINATION , nLocal)
	oSetup:SetPropert(PD_MARGIN      , {10,10,10,10})
	oSetup:SetPropert(PD_PAPERSIZE   , 2)


	// ----------------------------------------------
	// Pressionado botใo OK na tela de Setup
	// ----------------------------------------------
	If oSetup:Activate() == PD_OK // PD_OK =1
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณSalva os Parametros no Profile             ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		fwWriteProfString( cSession, "LOCAL"      , If(oSetup:GetProperty(PD_DESTINATION)==1 ,"SERVER"    ,"CLIENT"    ), .T. )
		fwWriteProfString( cSession, "PRINTTYPE"  , If(oSetup:GetProperty(PD_PRINTTYPE)==2   ,"SPOOL"     ,"PDF"       ), .T. )
		fwWriteProfString( cSession, "ORIENTATION", If(oSetup:GetProperty(PD_ORIENTATION)==1 ,"PORTRAIT"  ,"LANDSCAPE" ), .T. )
		cNomePrint := oSetup:aOptions[6]
		If Empty(cNomePrint)
			U_AvisoExp('Impressora',"Nenhuma impressora foi selecionada",.t.)
			Return .F.
		EndIf
		If 'ZEBRA' $ Upper(cNomePrint) .or. 'WRITER' $ Upper(cNomePrint) .OR. 'PDF' $ Upper(cNomePrint)
			U_AvisoExp('Impressora',"voc๊ selecionou uma impressora nใo permitida, verifique!",.t.)
			Return .F.
		EndIf
	Else
		U_AvisoExp('Setup',"Setup abortado")
		Return .F.
	EndIf


Return .T.
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณPrinterVldบAutor  ณNilton A. Rodrigues บ Data ณ  17/02/14   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณFuncao responsavel por alimentar a impressora de etiqueta   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function PrinterVld()
	Local cArqVars  := DIRCTRL+'CHGB010A.DTC'
	Local cChave    := ''
	Local cIndice   := RetArq(__LocalDrive,FileNoExt(cArqVars),.F.)

	U_criaTmp(cArqVars,'MAQ',.F.)
	If ! File(cIndice)
		INDEX ON MAQUINA+SSID TAG &(RetFileName(cIndice)) TO &(FileNoExt(cArqVars))
	EndIf

	dbSetIndex(FileNoExt(cIndice))

	cChave    := Padr(Upper(ComputerName()),Len(MAQ->MAQUINA))+PADR(GetCredential(),Len(MAQ->SSID))

	If MAQ->(!dbSeek(cChave))
		U_AvisoExp('Configura็๕es',"Aten็ใo nใo hแ nenhuma impressora de ETIQUETA configurada, digite o c๓digo da impressora"+;
		" de etiqueta para esta maquina, caso tenha alguma duvida ligue para o setor de informแtica")

		cImpEtiq := Padr(AllTrim(U_CHGInput('Impressora Etiqueta','Digite o c๓digo da impressora Etiqueta',Space(U_LenVar("CB5_CODIGO")),,U_LenVar("CB5_CODIGO"),'CB5')),U_LenVar("CB5_CODIGO"))

		If !Empty(cImpEtiq)
			If CB5->(!dbSeek(xFilial('CB5')+cImpEtiq))
				U_AvisoExp('Impressora',"Impressora de etiqueta nใo localizada, saia e entre novamente no programa."+CRLF+"Havendo alguma duvida entre em contato com a Informแtica",.t.)
				cImpEtiq := "ERROR"
			EndIf
		EndIf

		If cImpEtiq <> 'ERROR'
			If MsgYesNo("Voc๊ selecionou a impressora: "+Iif(Empty(cImpEtiq),"EM BRANCO",cImpEtiq+" - "+CB5->CB5_DESCRI)+CRLF+"Confirma a inclusใo da impressora para este terminal?")
				Reclock("MAQ",.T.)
				MAQ->MAQUINA  := UPPER(ComputerName())
				MAQ->SSID     := GetCredential()
				MAQ->ETIQUETA := cImpEtiq
				MAQ->(MsUnlock())
			Else
				U_AvisoExp('Config Impressora',"Opera็ใo abortada, entre novamente para cadastrar!",.t.)
				cImpEtiq := Space(6)
			EndIf
		Else
			cImpEtiq := Space(6)
		EndIf
	Else
		cImpEtiq := MAQ->ETIQUETA
	EndIf

	U_CHGClose("MAQ")
Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณProcDayLastบAutor  ณNilton A. Rodrigues บ Data ณ  18/09/2014 บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณFuncao para processar os pedidos do dia Anterior             บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function ProcDayLast
	Local cQuery
	Local cLockKey  := 'B10DAY'+AllTrim(cNumEmp)

	If LockByName(cLockKey,.T.,.T.,.F.)
		cQuery := "UPDATE "+RetSqlName("SC5")
		cQuery += " SET C5_CHGPRIO = '05' "
		cQuery += " WHERE C5_FILIAL = '"+xFilial("SC5")+"'"
		cQuery += " AND C5_NUM IN (SELECT ZJ_PEDIDO FROM "
		cQuery += RetSqlName("SZJ")
		cQuery += " WHERE ZJ_FILIAL = '"+xFilial("SZJ")+"'"
		cQuery += " AND ZJ_FILIAL = '"+xFilial("SZJ")+"'"
		cQuery += " AND ZJ_TIPO = 'L' "
		cQuery += " AND ZJ_PEDIDO IN (SELECT C5_NUM FROM "
		cQuery += RetSqlName("SC5")
		cQuery += " WHERE C5_FILIAL = '"+xFilial("SC5")+"'"
		cQuery += " AND C5_CHGLOG = 'S' "
		cQuery += " AND C5_CHGPRIO NOT IN ('0','00','01','02','03','04','05','06','07','08')"
		cQuery += " AND D_E_L_E_T_ = ' ' )"
		cQuery += " AND D_E_L_E_T_ = ' ' "
		cQuery += " AND ZJ_DTINI <= '"+dTos(dDatabase-1)+"') "

		TcSqlExec(cQuery)
		TCRefresh(RetSqlName("SC5"))
		//- Libera a chave para uso
		UnLockByName(cLockKey,.T.,.T.,.F.)
	EndIf

Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณMonitor   บAutor  ณNilton A. Rodrigues บ Data ณ 29/10/2014  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Demonstra o monitor de atividades                          บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function Monitor
	Local oAtrasado
	Local oCracha
	Local oExpItem
	Local oFontNeg := TFont():New("Arial",,018,,.T.,,,,,.F.,.F.)
	Local oDiasAtras
	Local oGroup1
	Local oGroup2
	Local oItHoje
	Local oItOntem
	Local oRetira
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4
	Local oSay5
	Local oSay6
	Local oSay7
	Local oSay8
	Local oSay9
	Local oSButton1
	Local oSeparar
	Local oSepConf
	Local oBrwPedido
	Local oBrwLocais
	Local bExecInit
	Local bExecCon
	Local aSize     := MsAdvSize()
	Local aObjects  := {}
	Local aInfo     := {}
	Local aPosObj   := {}
	Local oDlg_Monitor
	Local oBtn_Fechar
	Local oTimerFecha

	Private aBrwPedido := {{' ',' ',' ',' ',' ',' ',' ' ,' ' ,' '}}
	Private aBrwLocais := {{' ',' ',' ',' ',' ',' '}}
	Private oTimer     := Nil
	Private nAtrasado  := 0
	Private nExpItem   := 0
	Private nDiasAtras := 0
	Private nItHoje    := 0
	Private nItOntem   := 0
	Private nRetira    := 0
	Private nSeparar   := 0
	Private nSepConf   := 0
	Private cCadastro  := "M o n i t o r   d e   P e d i d o s"

	/*
	If !ReadCracha('9','Crachแ Supervisor','Monitor de atividade!')
		FreeObj(oFontNeg )
		oFontNeg := nil
		Return .F.
	EndIf
	*/

	aObjects := {}
	AAdd( aObjects, { 100, 035 , .T., .F., .T. } )
	AAdd( aObjects, { 100, 100 , .T., .T., .T. } )
	AAdd( aObjects, { 100, 050 , .T., .F., .T. } )

	aInfo    := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 }
	aPosObj := MsObjSize( aInfo, aObjects)

	bExecCon:= {|| FwMsgRun(,{||B010Rfr()},'Atualizando','Aguarde atualizando...'), oSeparar:Refresh(), oSepConf:Refresh(), oRetira:Refresh(), oDiasAtras:Refresh(), oExpItem:Refresh(),;
	oAtrasado:Refresh(), oItOntem:Refresh(), oItHoje:Refresh(), oBrwPedido:SetArray(aBrwPedido), oBrwPedido:Refresh(),oBrwLocais:SetArray(aBrwLocais), oBrwLocais:Refresh(),;
	oBtn_Fechar:SetFocus(),oDlg_Monitor:CtrlRefresh()}
	
	bExecIni:= {|| FwMsgRun(,{||B010Rfr()},'Atualizando','Aguarde atualizando...'), oSeparar:Refresh(), oSepConf:Refresh(), oRetira:Refresh(), oDiasAtras:Refresh(), oExpItem:Refresh(),;
	oAtrasado:Refresh(), oItOntem:Refresh(), oItHoje:Refresh(), oBrwPedido:SetArray(aBrwPedido), oBrwPedido:Refresh(),oBrwLocais:SetArray(aBrwLocais), oBrwLocais:Refresh(),;
	oBtn_Fechar:SetFocus(),oDlg_Monitor:CtrlRefresh(),EnchoiceBar(oDlg_Monitor, {||oDlg_Monitor:End()},{||oDlg_Monitor:End()},,)}

	DEFINE MSDIALOG oDlg_Monitor TITLE cCadastro FROM aSize[7],0 to aSize[6],aSize[5] COLORS 0, 16777215  of oMainWnd PIXEL STYLE nOr(WS_VISIBLE,WS_POPUP)

	oDlg_Monitor:lEscClose := .F.

	@ 051, 007 GROUP oGroup2 TO 180, 218 PROMPT "I n f o r m a t i v o   d a   E x p e d i ็ ใ o" OF oDlg_Monitor COLOR 16711680, 16777215 PIXEL

	@ 065, 011 SAY oSay3 PROMPT "A  S e p a r a r" SIZE 085, 011 OF oGroup2 FONT oFontNeg COLORS 0, 16777215 PIXEL
	@ 075, 011 MSGET oSeparar VAR nSeparar SIZE 085, 012 OF oGroup2 PICTURE "@E 99,999" COLORS 0, 16777215 FONT oFontNeg READONLY PIXEL

	@ 065, 108 SAY oSay2 PROMPT "E m   P r o d u ็ ใ o" SIZE 085, 011 OF oGroup2 FONT oFontNeg COLORS 0, 16777215 PIXEL
	@ 075, 108 MSGET oSepConf VAR nSepConf SIZE 085, 012 OF oGroup2 PICTURE "@E 99,999" COLORS 0, 16777215 FONT oFontNeg READONLY PIXEL

	@ 095, 011 SAY oSay5 PROMPT "U r g e n t e s" SIZE 085, 010 OF oGroup2 FONT oFontNeg COLORS 255, 16777215 PIXEL
	@ 105, 011 MSGET oRetira VAR nRetira SIZE 085, 012 OF oGroup2 PICTURE "@E 99,999" COLORS 0, 16777215 FONT oFontNeg READONLY PIXEL

	@ 095, 108 SAY oSay8 PROMPT "Dias Atras / Pedidos" SIZE 095, 011 OF oGroup2 FONT oFontNeg COLORS 0, 16777215 PIXEL
	@ 105, 108 MSGET oDiasAtras VAR nDiasAtras SIZE 085, 012 OF oGroup2 COLORS 0, 16777215 FONT oFontNeg READONLY PIXEL

	@ 125, 011 SAY oSay6 PROMPT "Sep.Itens/M้dia Pedido " SIZE 095, 007 OF oGroup2 FONT oFontNeg COLORS 0, 16777215 PIXEL
	@ 135, 011 MSGET oExpItem VAR nExpItem SIZE 085, 012 OF oGroup2 COLORS 0, 16777215 FONT oFontNeg READONLY PIXEL

	@ 150, 011 SAY oSay1 PROMPT "ATRASADOS / Itens" SIZE 085, 007 OF oGroup2 FONT oFontNeg COLORS 0, 16777215 PIXEL
	@ 160, 011 MSGET oAtrasado VAR nAtrasado SIZE 085, 012 OF oGroup2 COLORS 0, 11448063 FONT oFontNeg READONLY PIXEL

	@ 125, 108 SAY oSay7 PROMPT "Itens/Pedido - D.Anterior" SIZE 095, 007 OF oGroup2 FONT oFontNeg COLORS 0, 16777215 PIXEL
	@ 135, 108 MSGET oItOntem VAR nItOntem SIZE 085, 012 OF oGroup2 COLORS 0, 1677721 FONT oFontNeg READONLY PIXEL

	@ 150, 108 SAY oSay4 PROMPT "Itens/Pedido - Hoje" SIZE 085, 007 OF oGroup2 FONT oFontNeg COLORS 0, 16777215 PIXEL
	@ 160, 108 MSGET oItHoje VAR nItHoje SIZE 085, 012 OF oGroup2 COLORS 0, 1677721  FONT oFontNeg READONLY PIXEL


	@ 050,aPosObj[2,2]+220 SAY oSay9 PROMPT "Atrasados - (*E)=E-Commerce    (*)=Urgentes" SIZE 285, 011 OF oGroup2 FONT oFontNeg COLORS 16711680, 16777215 PIXEL



	//-- bowser de pedidos atrasados
	//oBrw     := TcBrowse():New(aPosObj[2,1],aPosObj[2,2],aPosObj[1,3],aPosObj[2,3]-40,,,,oDlg_CPR,,,,,,,,,,,,.F.,'TRB',.T.,,.F.,,)
	oBrwPedido := TCBrowse():New( 060,aPosObj[2,2]+220  , 250, aPosObj[2,4]+aPosObj[3,4],,,,oDlg_Monitor,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )

	// Seta array para o browse
	oBrwPedido:SetArray(aBrwPedido)

	// Adciona colunas
	oBrwPedido:AddColumn( TCColumn():New('Pedido'        ,{ || aBrwPedido[oBrwPedido:nAt,9] },,,,"LEFT"  ,30,.F.,.T.,,,,.F.,) )
	oBrwPedido:AddColumn( TCColumn():New('Arm'           ,{ || aBrwPedido[oBrwPedido:nAt,2] },,,,"CENTER",20,.F.,.T.,,,,.F.,) )
	oBrwPedido:AddColumn( TCColumn():New('Funcionแrio'   ,{ || aBrwPedido[oBrwPedido:nAt,3] },,,,"LEFT"  ,100,.F.,.T.,,,,.F.,) )
	oBrwPedido:AddColumn( TCColumn():New('Data'          ,{ || aBrwPedido[oBrwPedido:nAt,4] },,,,"LEFT"  ,35,.F.,.T.,,,,.F.,) )
	oBrwPedido:AddColumn( TCColumn():New('Hora'          ,{ || aBrwPedido[oBrwPedido:nAt,5] },,,,"LEFT"  ,25,.F.,.T.,,,,.F.,) )
	oBrwPedido:AddColumn( TCColumn():New('Tot.It'        ,{ || aBrwPedido[oBrwPedido:nAt,6] },'@E 999',,,"RIGHT"  ,25,.F.,.T.,,,,.F.,) )
	//oBrw:AddColumn(TCColumn():New('Hr.Final'     ,{|| TRB->HRFINAL}        ,'@!'           ,,,'CENTER',36 ,.F.,.F.,,,,.F.,))


	//- browser de barrac๕es
	oBrwLocais := TCBrowse():New( 190,aPosObj[2,2]+10,200,95,,,,oDlg_Monitor,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )

	// Seta array para o browse
	oBrwPedido:SetArray(aBrwLocais)


	// Adciona colunas
	oBrwLocais:AddColumn( TCColumn():New('Bar'      ,{ || aBrwLocais[oBrwLocais:nAt,1] },,,,"CENTER"  ,,.F.,.T.,,,,.F.,) )
	oBrwLocais:AddColumn( TCColumn():New('Sep'      ,{ || aBrwLocais[oBrwLocais:nAt,2] },'@E 99,999',,,"RIGHT",,.F.,.T.,,,,.F.,) )
	oBrwLocais:AddColumn( TCColumn():New('Urg'      ,{ || aBrwLocais[oBrwLocais:nAt,3] },'@E 99,999',,,"RIGHT"  ,,.F.,.T.,,,,.F.,) )
	oBrwLocais:AddColumn( TCColumn():New('Atraso'   ,{ || aBrwLocais[oBrwLocais:nAt,4] },'@E 99,999',,,"RIGHT"  ,,.F.,.T.,,,,.F.,) )
	oBrwLocais:AddColumn( TCColumn():New('T.Itens'  ,{ || aBrwLocais[oBrwLocais:nAt,5] },'@E 99,999',,,"RIGHT"  ,,.F.,.T.,,,,.F.,) )
	oBrwLocais:AddColumn( TCColumn():New('T.Pe็as'  ,{ || aBrwLocais[oBrwLocais:nAt,6] },'@E 999,999',,,"RIGHT"  ,,.F.,.T.,,,,.F.,) )

	@ 011, 020 BUTTON oBtn_Fechar PROMPT "&Fechar" Action oDlg_Monitor:End() SIZE 037, 012 OF oDlg_Monitor PIXEL




	oDlg_Monitor:bInit:= bExecIni
	//oDlg_Monitor:bStart = bExecCon 

	//-- Temporizador/Refresh da tela
	oTimer:=TTimer():New(20000,bExecCon,oDlg_Monitor)
	oTimer:lActive := .T.

	//oTimerFecha:=TTimer():New(70000,{||oDlg_Monitor:End()},oDlg_Monitor)
	//oTimerFecha:lActive := .T.


	ACTIVATE MSDIALOG oDlg_Monitor CENTERED //on init EnchoiceBar(oDlg_Monitor, {||oDlg_Monitor:End()},{||oDlg_Monitor:End()},,)

	FreeObj(oFontNeg )
	oFontNeg := nil

	oDlg_Monitor := nil
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณImpressoraบAutor  ณNilton A. Rodrigues บ Data ณ 29/10/2014  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao responsavel por montar a chamada da FMSPrinter      บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function Impressora(oPrint,cFile)
	Local lAdjustToLegacy := .F.
	Local lDisableSetup   := .T.
	Local lTReport  := .F.
	Local cLocal    := SuperGetMv("MV_RELT")
	Local lViewPDF  := .T.
	Local nCopias   := 1
	Local lRaw      := .F.
	Local _cFileImp := cFileImp+AllTrim(cNumEmp)+Dtos(MSDate())+StrTran(Time(),":","")

	oPrint := FWMSPrinter():New(_cFileImp, IMP_SPOOL, lAdjustToLegacy,cLocal, lDisableSetup,lTReport,/*oPrintSetup*/,/*cPrinter*/,/*lServer*/,.T./*lPDFAsPNG*/, lRaw,lViewPDF,nCopias)

	//If !oPrint:isPrinterActive()  //- Habilita a configuracao da impressora
	//	DisarmTransAction()
	//	Help(" ",1,"NOPRINTGRA")
	//	Return .F.
	//EndIf

	If oSetup <> nil //- houve troca de setup
		// ----------------------------------------------
		// Define saida de impressใo
		// ----------------------------------------------
		If oSetup:GetProperty(PD_PRINTTYPE) == IMP_SPOOL
			oPrint:nDevice := IMP_SPOOL
			// ----------------------------------------------
			// Salva impressora selecionada
			// ----------------------------------------------
			fwWriteProfString(GetPrinterSession(),"DEFAULT", oSetup:aOptions[PD_VALUETYPE], .T.)
			oPrint:cPrinter := oSetup:aOptions[PD_VALUETYPE]
		ElseIf oSetup:GetProperty(PD_PRINTTYPE) == IMP_PDF
			oPrint:nDevice := IMP_PDF
			// ----------------------------------------------
			// Define para salvar o PDF
			// ----------------------------------------------
			oPrint:cPathPDF := oSetup:aOptions[PD_VALUETYPE]
		Endif
	EndIf

	oPrint:SetResolution(72)
	oPrint:SetPortrait()
	oPrint:SetPaperSize(DMPAPER_A4)
	oPrint:SetMargin(10,10,10,10)
	oPrint:cPathPDF := 'c:\' //- drive da maquina nใo pode ser do protheus o path

	//- alimenta o arquivo de impressao
	cFile := cLocal+_cFileImp

	//- guarda o nome da impressora
	cNomePrint := oPrint:cPrinter

	If Empty(cNomePrint) //- checa se ha impressora configurada
		U_AvisoExp('Impressora',"Aten็ใo nenhuma impressora foi selicionada, queira informar corretamente a impressora a ser usada.",.t.)
		If !ValidPrint()
			Help(" ",1,"NOPRINTGRA")
			Return .F.
		EndIf
		//- limpa o objeto
		FreeObj(oPrint)
		oPrint := nil
		//- faz a chamada da funcao impressora() para revalidar o ajuste do setup
		If Impressora(@oPrint,@cFile)
			Return .T.
		EndIf
		Return .F.
	EndIf

	//- apaga o arquivo PDF
	fErase(oPrint:cPathPDF+_cFileImp+'.pdf')

	//- Alimenta a largura do Relatorio
	nLarReport := Int(oPrint:NPAGEWIDTH/oPrint:NFACTORHOR)

	//- Alimenta a Altura do Relatorio
	nAltReport  := Int(oPrint:NPAGEHEIGHT/oPrint:NFACTORVERT)

Return .T.


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณSearchPed บAutor  ณNilton A. Rodrigues บ Data ณ  30/10/14   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao responsavel por busca do pedido a ser impresso      บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function SearchPed(oPrint)
	Local nLin      := 0
	Local nTotRec   := 0
	Local nPag      := 0
	Local nPagImp   := 0
	Local nTotFolha := 0
	Local cCodBar   := ''
	Local cQuery    := ''
	Local lRetira   := .F.
	Local lExecute  := .T.
	Local nItemPag  := 0
	Local nItemSep  := 0 //- total de itens real na pagina
	Local nTotPec   := 0
	Local nTotVal   := 0
	Local cLocais   := ""
	Local lArm_G    := .F.
	Local cArm      := "" //- Armazem de trabalho
	Local nPosArm   := 0  //- Posicao do Armazem
	Local aPaginas  := {} //- Indica como sera agrupadas as paginas
	Local cArmAux   := ''
	Local cArmTrab  := ''
	Local nMinPre   := 0
	Local lExecRet  := SuperGetMv("CHGRETIRA") //- identifica se saira a folha completa para o retira
	Local cEtiqPg   := ''
	// variaveis locais
	Local cLocAnt  := ' '
	Local oFont10  := TFont():New(cFntCabec,,-12,,.T.,,,,.F.,.F.)
	Local oFont20  := TFont():New(cFntCabec,,-18,,.T.,,,,.F.,.F.)
	Local oBrush	:= TBrush():New(,13158600)
	Local cLocArmG := " "
	Local nPosPag  := 0
	Local cAliasAtiv:= ''
	Local _lEof
	Local lImpOk    := .T.//- indica se houve impressao
	Private cHora      := Time()

	Private lAllPre    := SuperGetMv('CHGPREBAR') //- Identifica se a pre-nota saira de todos os barracoes ou se sera dividida

	Do Case 
		//---------------------------------------------------------
		//- Goiania
		//---------------------------------------------------------
		Case AllTrim(cNumEmp) == '0200'
		AADD(aLocais,{"A","'A','B'"})
		AADD(aLocais,{"B","'A','B'"})
		AADD(aLocais,{"C","'C','D'"})
		AADD(aLocais,{"K","'K'"})

		//---------------------------------------------------------
		//- Combinacoes de paginas
		//---------------------------------------------------------
		AADD(aPaginas,{"A","A"})
		AADD(aPaginas,{"B","A"})
		AADD(aPaginas,{"C","C"})
		AADD(aPaginas,{"D","C"})
		AADD(aPaginas,{"K","K"})
		AADD(aPaginas,{"E","E"})
		AADD(aPaginas,{"I","E"})
		AADD(aPaginas,{"F","F"})
		AADD(aPaginas,{"J","F"})
		AADD(aPaginas,{"G","G"})
		AADD(aPaginas,{"H","G"})


		//---------------------------------------------------------
		//- Contagem
		//---------------------------------------------------------
		Case AllTrim(cNumEmp) == '0103'
		AADD(aLocais,{"A","'A'"})

		AADD(aLocais,{"B","'B','C'"})
		AADD(aLocais,{"C","'B','C'"})

		AADD(aLocais,{"K","'K'"})


		//---------------------------------------------------------
		//- Combinacoes de paginas
		//---------------------------------------------------------
		AADD(aPaginas,{"A","A"})

		AADD(aPaginas,{"B","B"})
		AADD(aPaginas,{"C","B"})

		AADD(aPaginas,{"K","K"})

		OtherWise 
		AADD(aLocais,{"A","'A','B'"})
		AADD(aLocais,{"B","'A','B'"})

		AADD(aLocais,{"C","'C','D'"})
		AADD(aLocais,{"D","'C','D'"})

		AADD(aLocais,{"K","'K'"})

		AADD(aLocais,{"E","'E','I'"})
		AADD(aLocais,{"I","'E','I'"})

		AADD(aLocais,{"F","'F','J'"})
		AADD(aLocais,{"J","'F','J'"})

		AADD(aLocais,{"G","'G','H'"})
		AADD(aLocais,{"H","'G','H'"})


		//---------------------------------------------------------
		//- Combinacoes de paginas
		//---------------------------------------------------------
		AADD(aPaginas,{"A","A"})
		AADD(aPaginas,{"B","A"})
		AADD(aPaginas,{"C","C"})
		AADD(aPaginas,{"D","C"})
		AADD(aPaginas,{"K","K"})
		AADD(aPaginas,{"E","E"})
		AADD(aPaginas,{"I","E"})
		AADD(aPaginas,{"F","F"})
		AADD(aPaginas,{"J","F"})
		AADD(aPaginas,{"G","G"})
		AADD(aPaginas,{"H","G"})

	EndCase

	cLocArmG := "'G','H','F','J','K'"


	//---------------------------------------------------------
	//- Fecha a atividade anterior do funcionario
	//---------------------------------------------------------
	U_AtuAtivFun(SZY->ZY_CODIGO,/*__cDoc*/,/*__nTotMov*/,/*__cTipoMov*/,/*__cArmazem*/,/*__lRetTmp*/,.T.)


	cHora    := Time()
	nMinPre  := SuperGetMv("CHGMINPRE")
	cArm     := AllTrim(SZY->ZY_ARMAZEM)
	nPosArm  := aScan(aLocais,{|x|x[1] == cArm})
	lRetira  := SZY->ZY_RETIRA == '1'
	lExecute := .T.
	lArm_G   := cArm== 'G' .or. cArm== 'F' .or. cArm== 'K'

	//- nao existe barracao configurado
	If (nPosArm  := aScan(aLocais,{|x| AllTrim(x[1])==SZY->ZY_ARMAZEM})) == 0
		U_AvisoExp("Armaz้m","Aten็ใo nใo existe nenhum armaz้m configurado, verifique",.T.)
		Return .F.
	Endif

	nTotItAll:= 0 //- totalizador de itens geral
	cEtiqPg  := ''

	//- Consulta principal para determinar se existe ou nใo pedido para ser separado
	While .T.
		cQuery := "SELECT FIRST 1 C5_CHGLOG, C5_CHGPRIO, C5_NUM, SC5.R_E_C_N_O_ RECSC5, SUBSTR(DC_LOCALIZ,1,1) ARMAZEM FROM "
		cQuery += RetSqlName("SC5")+" SC5, "
		cQuery += RetSqlName("SDC")+" SDC "
		cQuery += " WHERE C5_FILIAL = '"+xFilial("SC5")+"'"
		cQuery += " AND C5_CHGLOG IN ('H','S','C')"
		cQuery += " AND SC5.D_E_L_E_T_ = ' '"
		cQuery += " AND SC5.C5_CHGPRIO <> '"+Space(Len(SC5->C5_CHGPRIO))+"'"
		cQuery += " AND DC_FILIAL = '"+xFilial("SDC")+"'"
		cQuery += " AND DC_PEDIDO = C5_NUM "
		cQuery += " AND DC_CHGSTAT = '"+Space(Len(SDC->DC_CHGSTAT))+"'"

		//- indica se havara a divisao pelo barracao de acordo com o cadastro do usuario
		If !lAllPre
			//- primeira pasagem pega de acordo com o galpao cadastrado
			If lExecute .or. lArm_G
				cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) IN ("+aLocais[nPosArm,2]+")"
			Else
				//- segunda passagem caso nao exista atividade de trabalho, pega o armazem disponivel
				//- retirando os galpoes proibidos
				cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) NOT IN ("+cLocArmG+")"//- Retira o barracao G
			EndIf
		Else
			//- verifica se o usuแrio esta cadastrado com os armazens especiais 
			If lArm_G
				cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) IN ("+aLocais[nPosArm,2]+")"
			Else
				cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) NOT IN ("+cLocArmG+")"//- Retira o barracao G
			EndIf
		EndIF

		cQuery += " AND SDC.D_E_L_E_T_ = ' ' "
		cQuery += " ORDER BY  C5_CHGPRIO, C5_CHGLOG, C5_NUM, 5 "
		U_CriaTmp(cQuery,'QSearchPed')
		If lExecute .and. !lArm_G .and. QSearchPed->(Eof())
			U_CHGClose('QSearchPed')
			lExecute := .F.
			Loop
		EndIf
		Exit
	EndDo


	If QSearchPed->(!Eof())
		//- Verifica se esta habilitado o uso de retira/entrega pegar todas as folhas
		//- forcando a analisar a quantidade de itens
		If !lExecRet
			lRetira := .F.
		EndIf

		nPosArm  := aScan(aLocais,{|x|x[1] == AllTrim(QSearchPed->ARMAZEM)})//- valida o barracao alocado para memoria

		SC5->(dbSetOrder(1))
		If !SC5->(dbSeek(xFilial('SC5')+QSearchPed->C5_NUM))
			U_AvisoExp("Error","Aten็ใo!! houve um erro de processamento, passe seu crachแ novamente!")
			lImpOk := .T.//- tem que ser True para nao chamar a rotina de estoque, e deixar passar o cracha novamente
			Return lImpOK
		EndIf
		//- VELIDA O STATUS DO PEDIDO PARA GARANTIR QUE O MESMO NรO TENHA RETONADO PARA VENDAS
		If SC5->C5_CHGLOG $'A/D/E/F/G/I/L/T/U/V/W' 
			U_AvisoExp("Error","Aten็ใo!! houve um erro de processamento, passe seu crachแ novamente!")
			lImpOk := .T.//- tem que ser True para nao chamar a rotina de estoque, e deixar passar o cracha novamente
			Return lImpOK
		EndIf 

		MemoWrite(cLockLog,;
		'Tipo...: PEDIDO DE VENDAS'+CRLF+;
		'Pedido.: '+SC5->C5_NUM+CRLF+;
		'Data...: '+dToc(dDataBase)+' - '+cTimeBloq+CRLF+;
		'Maquina: '+ UPPER(ComputerName())+CRLF+;
		'Usuario: '+ LogUserName()+CRLF+;
		'Cracha.: '+SZY->ZY_CODIGO+CRLF+;
		'Nome...: '+AllTrim(SZY->ZY_NOME))

		//- Garante que o pedido seja travado somente pelo usuario em execu็ใo
		While .T.
			If !SoftLock('SC5')
				FwMsgRun(,{||Sleep(nTimeSleep)},'Pedido Bloqueado - SC5','Pedido esta sendo usado por outro usuแrio.....')
				Loop
			EndIf
			Exit
		EndDo

		SA4->(dbSeek(xFilial("SA4")+SC5->C5_TRANSP))//- POSICIONA TRANSPORTE

		RecLock("SC5",.F.)

		//- Guarda a Posicao do array qdo nao for pra dividir o armazem
		nItemPag := 0
		nItemSep := 0
		nTotVal  := 0
		nTotPec  := 0
		nPag     := 1  //- Inicializa a numeracao da pagina
		nPagImp  := PagPedido(SC5->C5_NUM)


		//- Verifica se a pre-nota sera ou nao dividida por Armazem
		//---------Altera็ใo para liberar uso de prenota
		If !lArm_G
			cQuery := "SELECT COUNT(*) TOTREC FROM "
			cQuery += RetSqlName("SDC")
			cQuery += " WHERE DC_FILIAL = '"+xFilial("SDC")+"'"
			cQuery += " AND DC_PEDIDO = '"+SC5->C5_NUM+"'"
			//- retira os barracoes que devem ser isolados
			cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) NOT IN ("+cLocArmG+")"//- Retira o barracao G

			cQuery += " AND DC_ORIGEM = 'SC6'"
			cQuery += " AND DC_CHGSTAT = '"+Space(Len(SDC->DC_CHGSTAT))+"'"
			cQuery += " AND D_E_L_E_T_ = ' ' "
			U_CriaTmp(cQuery,'QB10SDC')

			lRetira := QB10SDC->TOTREC <= nMinPre

			If lRetira 
				aPaginas := {}
				AADD(aPaginas,{"A","A"})
				AADD(aPaginas,{"B","A"})
				AADD(aPaginas,{"C","A"})
				AADD(aPaginas,{"D","A"})
				AADD(aPaginas,{"E","A"})
				AADD(aPaginas,{"I","A"})

				AADD(aPaginas,{"K","K"})


				AADD(aPaginas,{"F","F"})
				AADD(aPaginas,{"J","F"})

				AADD(aPaginas,{"G","G"})
				AADD(aPaginas,{"H","G"})
			EndIf

			U_CHGClose('QB10SDC')
		EndIf
		//- Calcula o Total de Paginas
		If lRetira
			nTotFolha := CalcPagina(aPaginas,@nTotRec,lArm_G,cLocArmG)//efetua o calculo de paginas por barracao
		Else
			cQuery := "SELECT COUNT(*) TOTREC FROM "
			cQuery += RetSqlName("SDC")
			cQuery += " WHERE DC_FILIAL = '"+xFilial("SDC")+"'"
			cQuery += " AND DC_PEDIDO = '"+SC5->C5_NUM+"'"
			cQuery += " AND DC_ORIGEM = 'SC6'"
			cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) IN ("+aLocais[nPosArm,2]+")"
			cQuery += " AND DC_CHGSTAT = '"+Space(Len(SDC->DC_CHGSTAT))+"'"
			cQuery += " AND D_E_L_E_T_ = ' ' "
			U_CriaTmp(cQuery,'QB10SDC')

			nTotRec := QB10SDC->TOTREC

			//- Faz o total de folha a serem impressa
			nTotFolha := nTotRec%nMaxFolha
			nTotFolha := Iif(nTotFolha <> 0,nTotRec - nTotFolha + nMaxFolha,nTotRec)
			nTotFolha := nTotFolha / nMaxFolha

			U_CHGClose('QB10SDC')
		EndIf

		//- QUERY QUE Busca os barracoes a serem impressos
		cQuery := "SELECT DISTINCT SUBSTR(DC_LOCALIZ,1,1) LOCAL FROM "
		cQuery += RetSqlName("SDC")
		cQuery += " WHERE DC_FILIAL = '"+xFilial("SDC")+"'"
		cQuery += " AND DC_PEDIDO = '"+SC5->C5_NUM+"'"
		cQuery += " AND DC_ORIGEM = 'SC6'"
		If !lRetira
			cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) IN ("+aLocais[nPosArm,2]+")"
		Else
			If lArm_G
				cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) IN ("+aLocais[nPosArm,2]+")"
			Else
				cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) NOT IN ("+cLocArmG+")"//- Retira o barracao G
			EndIf
		EndIF
		cQuery += " AND DC_CHGSTAT = '"+Space(Len(SDC->DC_CHGSTAT))+"'"
		cQuery += " AND D_E_L_E_T_ = ' ' "
		U_CriaTmp(cQuery,'QB10SDC')

		//- Monta a Estrutura para o IN da query
		If QB10SDC->(!Eof())
			cLocais   := "'"
			While QB10SDC->(!Eof())
				cLocais += QB10SDC->LOCAL

				QB10SDC->(dbSkip())

				If QB10SDC->(!Eof())
					cLocais += "','"
				Else
					cLocais += "'"
				EndIf

			EndDo
		Else
			//- RETORNA DEVIDO A UM ERRO NAS BUSCAS 
			U_AvisoExp("Error de Busca","Aten็ใo!! houve um erro de processamento, passe seu crachแ novamente!")
			lImpOk := .T.//- tem que ser True para nao chamar a rotina de estoque, e deixar passar o cracha novamente
			SC5->(MsUnLock())
			Return lImpOK
		EndIF

		U_CHGClose('QB10SDC')

		cQuery := "SELECT DC_FILIAL, DC_PEDIDO, DC_LOCAL, DC_LOCALIZ, SDC.R_E_C_N_O_ RECSDC, NVL(BE_CHGEST,' ') BE_CHGEST,"
		cQuery += " B1_DESC, B1_CHGSECU, B1_UM, B2_QATU-B2_QACLASS SLDEST, B1_QE, B1_CODBAR,SUBSTR(DC_LOCALIZ,1,1) ARMAZEM  FROM "
		cQuery += RetSqlName("SDC")+" SDC, "
		cQuery += RetSqlName("SB1")+" SB1, "
		cQuery += RetSqlName("SB2")+" SB2, OUTER("
		cQuery += RetSqlName("SBE")+" SBE) "
		cQuery += " WHERE DC_FILIAL = '"+xFilial("SDC")+"'"
		cQuery += " AND DC_PEDIDO = '"+SC5->C5_NUM+"'"
		cQuery += " AND DC_ORIGEM = 'SC6'"
		If !lRetira
			cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) IN ("+aLocais[nPosArm,2]+")"
		Else
			If lArm_G
				cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) IN ("+aLocais[nPosArm,2]+")"
			Else
				cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) NOT IN ("+cLocArmG+")"//- Retira o barracao G
			EndIf
		EndIF
		cQuery += " AND DC_CHGSTAT = '"+Space(Len(SDC->DC_CHGSTAT))+"'"
		cQuery += " AND SDC.D_E_L_E_T_ = ' ' "

		cQuery += " AND B1_FILIAL = '"+xFilial("SB1")+"'"
		cQuery += " AND B1_COD = DC_PRODUTO "
		cQuery += " AND SB1.D_E_L_E_T_ = ' ' "

		cQuery += " AND B2_FILIAL = '"+xFilial("SB2")+"'"
		cQuery += " AND B2_COD = DC_PRODUTO "
		cQuery += " AND B2_LOCAL = DC_LOCAL "
		cQuery += " AND SB2.D_E_L_E_T_ = ' ' "

		cQuery += " AND BE_FILIAL = '"+xFilial("SBE")+"'"
		cQuery += " AND BE_LOCAL = DC_LOCAL "
		cQuery += " AND BE_LOCALIZ = DC_LOCALIZ "
		cQuery += " AND SBE.D_E_L_E_T_ = ' '"

		cQuery += " ORDER BY 6 DESC, DC_LOCALIZ DESC "

		U_CriaTmp(cQuery,'QB10SDC')
		dbSelectArea('QB10SDC')


		nPosPag  := aScan(aPaginas,{|x| Alltrim(x[1]) == QB10SDC->ARMAZEM})

		cArmAux := aPaginas[nPosPag][2] //- Grava o Armazem para controle das paginas
		cArmTrab:= cArmAux

		CabecPed(@nLin,nPag,nTotFolha,@cCodBar,nPagImp,cLocais,@oPrint) //- Impressao do cabecalho

		cEtiqPg := cCodBar //- grava o serial para impressao e busca das etiquetas

		nPag ++
		//- esse tratamento eh feito para evitar falso positivo do alias
		_lEof := QB10SDC->(!Eof())

		While _lEof

			_lEof := QB10SDC->(Eof())
			//----------------------------------------------
			//- Garante para que nao haja falha na execucao
			//----------------------------------------------
			If !_lEof

				cAliasAtiv:= Alias()

				//- Grava o Armazem para controle das paginas
				nPosPag  := aScan(aPaginas,{|x| Alltrim(x[1]) == QB10SDC->ARMAZEM})

				cArmTrab := aPaginas[nPosPag][2]

				If nItemPag == nMaxFolha .or. (lRetira .and. cArmAux <> cArmTrab)
					RodaPed(nLin,SZY->ZY_CODIGO,/*lTime*/,/*nTotItens*/,cCodBar,nItemSep,cArmAux,nTotVal,nTotPec,@oPrint)  //- Impressao do Rodape
					nItemPag := 0
					nItemSep := 0
					nTotVal  := 0
					nTotPec  := 0
					CabecPed(@nLin,nPag,nTotFolha,@cCodBar,nPagImp,cLocais,@oPrint)//- Impressao do cabecalho
					cEtiqPg += "/"+cCodBar
					nPag ++
					cArmAux  := cArmTrab
					cLocAnt := 'ZZZ' //- faz entrada para impressao do local
				EndIf

				//- checa para impressao da rua
				If cLocAnt <> QB10SDC->ARMAZEM
					nItemPag++
					If nItemPag == nMaxFolha//- checa a pagina
						Loop
					EndIf
					//nLin-=nNewLine//- Retira a soma para ser impresso na posicao correta
					cLocAnt := QB10SDC->ARMAZEM
					oPrint := U_DrawBox(oPrint,1,nLin-nNewLine,nLin,010,nLarReport,0,0)
					oPrint:Say(nLin-2,nMargEsq,'Armaz้m: '+QB10SDC->ARMAZEM,oFont10,,16777215,,0)
					nLin+=nNewLine
				EndIf
				ItemPed(@nLin,'QB10SDC',cCodBar,@oPrint) //- Impressao dos Itens do Pedido
				nItemPag ++
				nItemSep ++
				nTotItAll ++

				nTotPec += SDC->DC_QUANT
				nTotVal += U_ValPedVds(1)
				dbSelectArea("QB10SDC")
				dbSkip()

				_lEof := !Eof()
			Else
				oPrint:Say(nLin-2,nMargEsq,'F O L H A   C O M   E R R O ',oFont20,,16777215,,0)
				oPrint:Print()

				FreeObj(oPrint)

				oPrint:= Nil
				U_AvisoExp("ERROR","Impressใo abortada, por favor, jogar fora a(s) folha(s) impressa(s) e passar o crachแ novamamente",.T.)
				DisarmTransaction()
				Break
			EndIf
		EndDo
		dbSelectArea("SC5")

		//- Atualiza o Status do Pedido
		If SC5->C5_CHGLOG == 'S'

			If !Alltrim(SC5->C5_CHGPRIO) $ '0,00,01,02,03,04,05,06,07,08'
				SC5->C5_CHGPRIO:= '08'
			EndIf

			SC5->C5_CHGLOG := 'H' //- Status como separando

			//-------------------------------------------------------------------
			//- ajusta o status do pedido do mercado livre
			//-------------------------------------------------------------------
			U_UPDSTZ32(SC5->C5_NUM,'G')


		EndIf
		SC5->(MsUnLock())

		U_CHGClose('QB10SDC')

		dbSelectArea("SC5")

		RodaPed(nLin,SZY->ZY_CODIGO,.T.,nTotRec,cCodBar,nItemSep,cArmAux,nTotVal,nTotPec,@oPrint)

		oPrint:Print()

		FreeObj(oPrint)

		oPrint:= Nil

		//- Impressao de etiqueta
		ImpEtiq(SC5->C5_NUM,SZY->ZY_CODIGO,cEtiqPg,aPaginas)

		If lRetira
			U_AvisoExp("Separa็ใo Completa","Aten็ใo!! Separar Completo o Pedido")
		EndIf
	Else
		//- U_AvisoExp(cTitle,cMensagem,_lCaptcha)
		lImpOk := .F.
	EndIf
	U_CHGClose('QSearchPed')

	FreeObj(oFont10)
	FreeObj(oFont20)
	FreeObj(oBrush)

	oFont10  := nil
	oBrush	:= nil
	dbSelectArea("SC5")

Return lImpOk
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณCabecPed  บAutor  ณNilton A. Rodriguersบ Data ณ  30/04/07   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao de impressao do Cabecalho                           บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function CabecPed(nLin,nPag,nTotFolha,cCodBar,nPagImp,cLocais,oPrint)
	Local _aArea  := GetArea()
	Local oFont16 := TFont():New(cFntCabec,,-16,,.T.,,,,.T.,.F.)
	Local oFont14 := TFont():New(cFntCabec,,-14,,.T.,,,,.T.,.F.)
	Local oFont08 := TFont():New(cFntCabec,,-08,,.F.,,,,.T.,.F.)
	Local oFont08n:= TFont():New(cFntCabec,,-08,,.T.,,,,.T.,.F.)
	Local oFont09 := TFont():New(cFntCabec,,-09,,.T.,,,,.F.,.F.)

	//- Efetua o tratamento da busca do serial
	cCodBar := Soma1(GetMv("MV_CHGFATP"),8)

	PutMv("MV_CHGFATP",cCodBar)

	oPrint:StartPage()

	oPrint:Line( 008, 10, 008, nLarReport,CLR_BLACK,"-1")

	oPrint:Say(024,010,'. : :ORDEM DE SEPARAวรO: : .',oFont14,,,,0)

	oPrint:Say(040,010,AllTrim(SM0->M0_NOME)+" - "+AllTrim(SM0->M0_FILIAL),oFont14,,,,0)

	oPrint:FWMSBAR("CODE128" /*cTypeBar*/,0.9/*nRow*/ ,40/*nCol*/ ,cCodBar /*cCode*/,oPrint/*oPrint*/,/*lCheck*/,/*Color*/,/*lHorz*/,;
	/*nWidth*/,1/*nHeigth*/,/*lBanner*/,/*cFont*/,/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,/*lCmtr2Pix*/)

	oPrint:= U_DrawBox(oPrint,0.33,010,35,360,430,0,13158600)//- borda da prenota
	oPrint:Say(17,362,OemToAnsi('Pr้-Nota'),oFont08)
	oPrint:Say(31,367,SC5->C5_NUM,oFont16)

	oPrint:Say(045,355,"Fol: "+StrZero(nPagImp,2)+' -> '+StrZero(nPag,2)+' / '+StrZero(nTotFolha,2),oFont08n,,,,0)

	LineDown(@oPrint,50)

	If SC5->C5_TRANSP $ SuperGetMv("MV_CHGTRAN")
		If SC5->C5_TRANSP $ SuperGetMv("CHGTRANENT") //- CODIGO DAS TRANSPORTADORAS DE ENTREGA
			oPrint := U_DrawBox(oPrint,1,050,060,010,nLarReport,0,0)
			oPrint:Say(059,010,'***E N T R E G A CHG / M O T O - PLACA VERDE - '+Iif(Time() <= '12:30','13:00',Iif(Time() <= '16:30','16:30','17:00')),oFont09,,16777215,,0)
		Else
			oPrint := U_DrawBox(oPrint,1,050,060,010,nLarReport,0,0)
			oPrint:Say(059,010,'***R E T I R A - PLACA VERMELHA',oFont09,,16777215,,0)
		EndIf
	ElseIf AllTrim(SC5->C5_CHGPRIO) == '0'
		oPrint := U_DrawBox(oPrint,1,050,060,010,nLarReport,0,0)
		oPrint:Say(059,010,'TRANSP: '+SC5->C5_TRANSP+'-'+SA4->A4_NREDUZ+' ***FATURAMENTO C O R R E I O S - '+dToc(dDataBase),oFont09,,16777215,,0)
	ElseIf AllTrim(SC5->C5_CHGPRIO) $ '00/01/02/03/04'
		oPrint := U_DrawBox(oPrint,1,050,060,010,nLarReport,0,0)
		oPrint:Say(059,010,'TRANSP: '+SC5->C5_TRANSP+'-'+SA4->A4_NREDUZ+' ***FATURAMENTO URGENTE HOJE - '+dToc(dDataBase),oFont09,,16777215,,0)
	Else
		oPrint:Say(059,010,'TRANSP: '+SC5->C5_TRANSP+'-'+SA4->A4_NREDUZ,oFont09,,0,,0)
	EndIf

	LineDown(@oPrint,60)

	nLin:=68

	oPrint:Say(nLin,nMargEsq,'SEP',oFont08n,,,,0) //- Item do Pedido
	oPrint:Say(nLin,038,'|IT',oFont08n,,,,0) //- Item do Pedido
	oPrint:Say(nLin,060,OemToAnsi('| LOCALIZAวรO'),oFont08n,,,,0)
	oPrint:Say(nLin,157,OemToAnsi('| PRODUTO'),oFont08n,,,,0)
	oPrint:Say(nLin,232,OemToAnsi('| QTD'),oFont08n,,,,0)
	oPrint:Say(nLin,279,OemToAnsi('| UND'),oFont08n,,,,0)
	oPrint:Say(nLin,310,OemToAnsi('| APANHE'),oFont08n,,,,0)
	oPrint:Say(nLin,361,OemToAnsi('| COD.FORNEC'),oFont08n,,,,0)
	oPrint:Say(nLin,452,OemToAnsi('| ESTOQUE'),oFont08n,,,,0)
	oPrint:Say(nLin,498,OemToAnsi('| COD.BARRAS'),oFont08n,,,,0)

	LineDown(@oPrint,nLin)

	nLin+=nNewLine+2

	FreeObj(oFont16 )
	FreeObj(oFont14 )
	FreeObj(oFont08 )
	FreeObj(oFont08n)
	FreeObj(oFont09 )

	oFont16 := nil
	oFont08 := nil
	oFont08n:= nil
	oFont09 := nil

	RestArea(_aArea)
	aSize(_aArea,0)
	_aArea := nil
Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณItemPed   บAutor  ณNilton A. Rodrigues บ Data ณ  07/04/05   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao de impressao dos itens do pedido                    บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function ItemPed(nLin,cAliasSDC,cCodBar,oPrint)
	Local _aArea  := GetArea()

	Local oFont09 := TFont():New(cFntCabec,,-09,,.F.,,,,.F.,.F.)
	Local oFont10 := TFont():New(cFntCabec,,-12,,.T.,,,,.F.,.F.)
	Local oFont08n:= TFont():New(cFntCabec,,-08,,.T.,,,,.T.,.F.)

	SDC->(dbGoto(QB10SDC->RecSDC))
	oPrint:Say(nLin,nMargEsq,'(  )',oFont10,,,,0) //- Item do Pedido

	oPrint:Say(nLin,038,'|',oFont08n,,,,0) //- Item do Pedido
	oPrint:Say(nLin,060,'|',oFont08n,,,,0)
	oPrint:Say(nLin,157,'|',oFont08n,,,,0)
	oPrint:Say(nLin,232,'|',oFont08n,,,,0)
	oPrint:Say(nLin,279,'|',oFont08n,,,,0)
	oPrint:Say(nLin,310,'|',oFont08n,,,,0)
	oPrint:Say(nLin,361,'|',oFont08n,,,,0)
	oPrint:Say(nLin,452,'|',oFont08n,,,,0)
	oPrint:Say(nLin,498,'|',oFont08n,,,,0)

	oPrint:Say(nLin,041,AllTrim(SDC->DC_ITEM),oFont09,,,,0) //- Item do Pedido
	oPrint:Say(nLin,063,Transform(AllTrim(SDC->DC_LOCALIZ),"@R X-99-999-99-X"),oFont10,,,,0)

	oPrint := U_DrawBox(oPrint,1,nLin-8,nLin+2,159,235,0,0)
	oPrint:Say(nLin,166	,U_MascProd(SDC->DC_PRODUTO),oFont10,,16777215,,0)

	oPrint:Say(nLin,225,TransForm(SDC->DC_QUANT,"@E 99,999"),oFont10,,,,1)
	oPrint:Say(nLin,285,QB10SDC->B1_UM,oFont09,,,,0)
	oPrint:Say(nLin,285,TransForm(SDC->DC_QUANT/QB10SDC->B1_QE,'@E 999,999.99'),oFont10,,,,1)
	oPrint:Say(nLin,368,SubStr(QB10SDC->B1_CHGSECU,2),oFont09,,,,0)//- tira o "F" inicial
	oPrint:Say(nLin,452,TransForm(QB10SDC->SLDEST,'@E 999,999'),oFont09,,,,1)//- tira o "F" inicial
	oPrint:Say(nLin,505,QB10SDC->B1_CODBAR,oFont09,,,,0)

	LineDown(@oPrint,nLin)

	nLin+=nNewLine

	oPrint:Say(nLin,064,QB10SDC->B1_DESC,oFont09,,,,0) //- Item do Pedido

	nLin+=5

	LineDown(@oPrint,nLin)

	nLin+=nNewLine
	//- Grava o conteudo da pagina em que estara item na prenota
	RecLock('SDC',.F.)
	SDC->DC_CHGSTAT := cCodBar
	SDC->(MsUnLock())

	FreeObj(oFont09 )
	FreeObj(oFont10 )
	FreeObj(oFont08n)

	oFont09 := nil
	oFont10 := nil
	oFont08n:= nil

	RestArea(_aArea)
	aSize(_aArea,0)
	_aArea := nil


Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณRodaPed   บAutor  ณNilton A. Rodrigues บ Data ณ  07/04/05   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao de impressao do Rodape do pedido                    บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function RodaPed(nLin,cCracha,lTime,nTotItens,cCodBar,nItemPag,cArmazem,nTotVal,nTotPec,oPrint)
	Local _aArea    := GetArea()
	Local oFont09   := TFont():New(cFntCabec,09,09,,.T.,,,,.F.,.F.)

	DEFAULT lTime    := .F.
	DEFAULT nTotItens:= 0

	//- Atualiza as informacoes da ultima atividade executada

	U_AtuAtivFun(cCracha,SC5->C5_NUM,nItemPag,'S',cArmazem,.F.,.F.,cCodBar,nTotVal,nTotPec,cHora)



	oPrint:Say(nLin,0010,'Separador: '+SZY->ZY_NOME,oFont09,,,,0)
	oPrint:Say(nLin,0300,'Emissใo: '+dToc(dDataBase)+' = '+cHora+' - Tot.It.Pg: '+AllTrim(Str(nItemPag)),oFont09,,,,0)

	oPrint:EndPage()

	FreeObj(oFont09)
	oFont09    := nil

	RestArea(_aArea)
	aSize(_aArea,0)
	_aArea := nil

Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณImpEtiq   บAutor  ณNilton A. Rodrigues บ Data ณ  24/10/05   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณFuncao para efetuar a impresao de etiqueta de produtos      บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ CHGO007                                                    บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function ImpEtiq(cPedido,cCracha,cEtiqPg,aPaginas)
	Local cQuery
	Local lEtiq := .F.
	Local cArmAux := ' '
	Local cArmTrab:= ' '
	Local aArea   := GetArea()
	Local nSerie

	dbSelectArea("SB1")
	SB1->(dbSetOrder(1))

	cQuery := "SELECT DC_PRODUTO, DC_QUANT, DC_LOCALIZ, B5_IMPETI, B5_TIPUNIT, NVL(BE_CHGEST,' ')  FROM "
	cQuery += RetSqlName("SDC")+" SDC, "
	cQuery += RetSqlName("SB5")+" SB5, OUTER("
	cQuery += RetSqlName("SBE")+" SBE) "
	cQuery += " WHERE DC_FILIAL = '"+xFilial("SDC")+"'"
	cQuery += " AND DC_PEDIDO = '"+cPedido+"'"
	cQuery += " AND DC_CHGSTAT IN "+U_FormatIn(cEtiqPg,'/')
	cQuery += " AND SDC.D_E_L_E_T_ = ' ' "

	cQuery += " AND B5_FILIAL = '"+xFilial("SB5")+"'"
	cQuery += " AND B5_COD = DC_PRODUTO "
	cQuery += " AND B5_IMPETI = '2' "
	cQuery += " AND B5_TIPUNIT = '0'"
	cQuery += " AND SB5.D_E_L_E_T_ = ' ' "

	cQuery += " AND BE_FILIAL = '"+xFilial("SBE")+"'"
	cQuery += " AND BE_LOCAL = DC_LOCAL "
	cQuery += " AND BE_LOCALIZ = DC_LOCALIZ "
	cQuery += " AND SBE.D_E_L_E_T_ = ' '"

	cQuery += " ORDER BY 6 DESC, DC_LOCALIZ DESC, DC_PRODUTO "

	U_CriaTmp(cQuery,'QSDC')

	dbSelectArea("QSDC")
	If QSDC->(!Eof())
		If CB5->(CB5SetImp(cImpEtiq))
			cArmTrab := SUBSTR(QSDC->DC_LOCALIZ,1,1)
			cArmAux  := cArmTrab

			While QSDC->(!Eof())
				cArmTrab := SUBSTR(QSDC->DC_LOCALIZ,1,1)

				If cArmAux <> cArmTrab
					MSCBBOX(00,01,76,09,50)
					MSCBBEGIN(1,6) //Inicio da Imagem da Etiqueta
					MSCBSAY(05,02,"INFORMATIVO DE SEPARACAO","N","0","030,030",.T.)
					MSCBSAY(05,10,"Pedido...: "+cPedido,"N","0","035,025",.F.)
					MSCBSAY(05,17,'Armazem..: '+cArmAux,'N','0','035,025',.F.)
					MSCBSAY(05,25,'Separador: '+SZY->ZY_NOME,'N','0','035,025',.F.)
					MSCBEND()
					cArmAux := SUBSTR(QSDC->DC_LOCALIZ,1,1)
				EndIf
				SB1->(dbSeek(xFilial("SB1")+QSDC->DC_PRODUTO,.F.))
				//- Atualiza a serie do produto
				RecLock("SB1")
				If SB1->B1_CHGSERI+1 >= 10000
					SB1->B1_CHGSERI := 0
				EndIf
				nSerie:= SB1->B1_CHGSERI
				SB1->B1_CHGSERI := nSerie + 1
				SB1->(MSUnLock())

				cBarPro := Padr(SB1->B1_COD,7)+StrZero(QSDC->DC_QUANT,5)+SubStr(dTos(dDataBase),5,4)+StrZero(nSerie,4)

				U_CHGN006(1,SB1->B1_COD,QSDC->DC_QUANT,U_AplicProd(SB1->B1_COD),cBarPro,.T.)

				lEtiq := .T.
				QSDC->(DbSkip())
			EndDo
			MSCBBEGIN(1,6) //Inicio da Imagem da Etiqueta
			MSCBBOX(00,01,76,09,50)
			MSCBSAY(05,02,"INFORMATIVO DE SEPARACAO","N","0","030,030",.T.)
			MSCBSAY(05,10,"Pedido...: "+cPedido,"N","0","035,025",.f.)
			MSCBSAY(05,17,'Armazem..: '+cArmAux,'N','0','035,025',.f.)
			MSCBSAY(05,25,'Separador: '+SZY->ZY_NOME,'N','0','035,025',.f.)
			MSCBEND()
			MSCBCLOSEPRINTER()
		EndIf
	Else
		U_AvisoExp("Pedido sem Etiqueta","Aten็ใo nใo hแ etiqueta a ser impressa para este pedido")
	EndIf

	U_CHGClose("QSDC")

	RestArea(aArea)
	aSize(aArea,0)
	aArea := nil

Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณPagPedido บAutor  ณNilton A. Rodrigues บ Data ณ  11/03/08   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณBusca a quantidade de paginas impressas                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function PagPedido(cPedido)
	Local nPag := 0
	Local cQuery

	cQuery := "SELECT DISTINCT DC_CHGSTAT FROM "
	cQuery += RetSqlName("SDC")
	cQuery += " WHERE DC_FILIAL = '"+xFilial("SDC")+"'"
	cQuery += " AND DC_PEDIDO = '"+cPedido+"'"
	cQuery += " AND DC_CHGSTAT <> '"+Space(Len(SDC->DC_CHGSTAT))+"'"
	cQuery += " AND D_E_L_E_T_ = ' ' "
	U_CriaTmp(cQuery,'QSDCPAG')
	While QSDCPAG->(!EOF())
		nPag++
		QSDCPAG->(dbSkip())
	EndDo
Return nPag

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณCalcPaginasบAutor  ณNilton A. Rodrigues บ Data ณ  15/09/09   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณEfetua o calculo de paginas para divisao de pre-notas        บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function CalcPagina(aPaginas,nTotalIT,lArm_G,cArmG)
	Local _aArea := GetArea()
	Local cQuery
	Local nTotRec   := 0
	Local nTotFolha := 0
	Local cAliasSDC := 'QSDCPAG'
	Local cArmAux
	Local cArmTrab
	Local nCalcAux
	Local nPosPag

	nTotalIT := 0

	//- QUERY QUE TRAZ OS ITENS A SEREM SEPARADOS
	cQuery := "SELECT BE_CHGEST, SUBSTR(DC_LOCALIZ,1,1) LOCAIS, COUNT(*) TOTREC FROM "
	cQuery += RetSqlName("SDC")+' SDC, '
	cQuery += RetSqlName("SBE")+" SBE "
	cQuery += " WHERE DC_FILIAL = '"+xFilial("SDC")+"'"
	cQuery += " AND DC_PEDIDO = '"+SC5->C5_NUM+"'"
	cQuery += " AND DC_ORIGEM = 'SC6'"
	cQuery += " AND DC_CHGSTAT = '"+Space(Len(SDC->DC_CHGSTAT))+"'"
	If lArm_G
		cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) IN ("+cArmG+")"
	Else
		cQuery += " AND SUBSTR(DC_LOCALIZ,1,1) NOT IN ("+cArmG+")"
	EndIf
	cQuery += " AND SDC.D_E_L_E_T_ = ' ' "
	cQuery += " AND BE_FILIAL = '"+xFilial("SDC")+"'"
	cQuery += " AND BE_LOCAL = DC_LOCAL "
	cQuery += " AND BE_LOCALIZ = DC_LOCALIZ "
	cQuery += " AND SBE.D_E_L_E_T_ = ' ' "
	cQuery += " GROUP BY 1,2 "
	cQuery += " ORDER BY 1 "
	U_CriaTmp(cQuery,cAliasSDC)


	nPosPag  := aScan(aPaginas,{|x| Alltrim(x[1]) == (cAliasSDC)->LOCAIS})

	cArmAux := aPaginas[nPosPag][2] //- Grava o Armazem para controle das paginas
	While (cAliasSDC)->(!Eof())
		//- Faz o total de folha a serem impressa
		nPosPag  := aScan(aPaginas,{|x| Alltrim(x[1]) == (cAliasSDC)->LOCAIS})

		cArmTrab := aPaginas[nPosPag][2] //- Grava o Armazem para controle das paginas

		If cArmTrab <> cArmAux
			nCalcAux  := nTotRec%nMaxFolha
			nCalcAux  := iIf(nCalcAux <> 0,nTotRec - nCalcAux + nMaxFolha,nTotRec)
			nTotFolha += nCalcAux / nMaxFolha
			nTotRec   := 0
			cArmAux := cArmTrab
		EndIf
		nTotRec += (cAliasSDC)->TOTREC
		nTotalIT+= (cAliasSDC)->TOTREC
		(cAliasSDC)->(dbSkip())
	EndDo
	If nTotRec >0
		nCalcAux  := nTotRec%nMaxFolha
		nCalcAux  := Iif(nCalcAux <> 0,nTotRec - nCalcAux + nMaxFolha,nTotRec)
		nTotFolha += nCalcAux / nMaxFolha
	EndIf

	U_CHGClose(cAliasSDC)

	RestArea(_aArea)
	aSize(_aArea,0)
	_aArea := nil

Return nTotFolha

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณLineDown  บAutor  ณNilton A. Rodrigues บ Data ณ  20/03/2014 บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณDesenha a linha de fechamento                               บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function LineDown(oPrint,nLin)
	Local oFont08n:= TFont():New(cFntCabec,,-08,,.T.,,,,.T.,.F.)
	Local nX
	For nX := nMargEsq To nLarReport
		oPrint:Say(nLin,nX,OemToAnsi('_'),oFont08n,,,,0)
	Next nX
	FreeObj(oFont08n)
	oFont08n:= nil

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณB010Rfr   บAutor  ณNilton A. Rodrigues บ Data ณ  01/06/07   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณEfetua o refresh da fila de pedidos                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function B010RFR
	Local cQuery
	Local dDataAnt:= dDataBase
	Local nPosPed := 0

	U_CheckRPO() //- Verifica se houve atualizacao no RPO

	nAtrasado  := 0
	nDiasAtras := 0

	//Analisa se hแ o fechamento do sistema para manutencao
	If File("FECHAB010.CHG")
		U_AvisoExp('Fechado para Manuten็ใo',"Aten็ใo o sistema se econtra em manuten็ใo. "+;
		"Aguarde libera็ใo do sistema."+CRLF+;
		"Sua janela fecharแ automaticamente!",,,8000)
		Ms_Quit()
	EndIf

	If nCalcMeta == 0 //- Faz com que nao seja contantemente requisitado
		//- Efetua a busca de Itens separados no dia
		cQuery := "SELECT COUNT(*) TOTDIA FROM "
		cQuery += RetSqlName("SD2")
		cQuery += " WHERE D2_FILIAL = '"+xFilial("SD2")+"'"
		cQuery += " AND D2_EMISSAO = '"+dTos(dDataBase)+"'"
		cQuery += " AND D2_TIPO = 'N' "
		cQuery += " AND D2_CLASFIS <> 'ZZZ'"
		cQuery += " AND D_E_L_E_T_ = ' ' "
		U_CriaTmp(cQuery,'B010QSD2')

		nItHoje := TransForm(B010QSD2->TOTDIA,'@E 999,999')

		cQuery := "SELECT COUNT(DISTINCT D2_PEDIDO) TOTDIA FROM "
		cQuery += RetSqlName("SD2")
		cQuery += " WHERE D2_FILIAL = '"+xFilial("SD2")+"'"
		cQuery += " AND D2_EMISSAO = '"+dTos(dDataBase)+"'"
		cQuery += " AND D2_TIPO = 'N' "
		cQuery += " AND D2_CLASFIS <> 'ZZZ'"
		cQuery += " AND D_E_L_E_T_ = ' ' "
		U_CriaTmp(cQuery,'B010QSD2')

		nItHoje += ' / '+TransForm(B010QSD2->TOTDIA,'@E 999,999')

		//- Busca os itens faturados do dian anterior
		cQuery := "SELECT FIRST 1 F2_EMISSAO FROM "
		cQuery += RetSqlName("SF2")
		cQuery += " WHERE F2_FILIAL = '"+xFilial("SF2")+"'"
		cQuery += " AND F2_EMISSAO < '"+dTos(dDataBase)+"'"
		cQuery += " AND F2_TIPO = 'N' "
		cQuery += " AND D_E_L_E_T_ = ' ' "
		cQuery += " ORDER BY F2_EMISSAO DESC"
		U_CriaTmp(cQuery,'B010QSD2')

		TcSetField('B010QSD2',"F2_EMISSAO","D",8,0)

		dDataAnt := B010QSD2->F2_EMISSAO

		cQuery := "SELECT COUNT(*) TOTDIA FROM "
		cQuery += RetSqlName("SD2")
		cQuery += " WHERE D2_FILIAL = '"+xFilial("SD2")+"'"
		cQuery += " AND D2_EMISSAO = '"+dTos(dDataAnt)+"'"
		cQuery += " AND D2_TIPO = 'N' "
		cQuery += " AND D2_CLASFIS <> 'ZZZ'"
		cQuery += " AND D_E_L_E_T_ = ' ' "
		U_CriaTmp(cQuery,'B010QSD2')

		nItOntem := TransForm(B010QSD2->TOTDIA,"@E 999,999")

		cQuery := "SELECT COUNT(DISTINCT D2_PEDIDO) TOTDIA FROM "
		cQuery += RetSqlName("SD2")
		cQuery += " WHERE D2_FILIAL = '"+xFilial("SD2")+"'"
		cQuery += " AND D2_EMISSAO = '"+dTos(dDataAnt)+"'"
		cQuery += " AND D2_TIPO = 'N' "
		cQuery += " AND D2_CLASFIS <> 'ZZZ'"
		cQuery += " AND D_E_L_E_T_ = ' ' "
		U_CriaTmp(cQuery,'B010QSD2')

		nItOntem += ' / '+TransForm(B010QSD2->TOTDIA,"@E 999,999")

		U_CHGClose("B010QSD2")
	Else
		If nCalcMeta == 12
			nCalcMeta := 0
		Else
			nCalcMeta ++
		EndIF
	EndIf

	//- inibe a qtd para usuario
	If AllTrim(UPPER(cUserName)) == 'ESTOQUE'
		nItOntem := 0
		nItHoje  := 0
	EndIf
	//- Efetua a busca do total de Pedidos que estao sendo conferidos e separados
	cQuery := " SELECT COUNT(*) TOTPED FROM "
	cQuery += RetSqlName("SC5")+" SC5"
	cQuery += " WHERE C5_FILIAL = '"+xFilial("SC5")+"'"
	cQuery += " AND C5_CHGLOG IN ('C','H') "
	cQuery += " AND C5_TIPO = 'N' "
	cQuery += " AND SC5.D_E_L_E_T_ = ' ' "
	cQuery += " GROUP BY C5_CHGLOG "
	U_CriaTmp(cQuery,'B010QSC5')

	nSepConf := B010QSC5->TOTPED

	//- TOTAL DE PEDIDOS NA EXPEDICAO A SEREM SEPARADOS
	cQuery := " SELECT COUNT(DISTINCT DC_PEDIDO) TOTPED FROM "
	cQuery += RetSqlName("SC5")+" SC5, "
	cQuery += RetSqlName("SDC")+" SDC "
	cQuery += " WHERE C5_FILIAL = '"+xFilial("SC5")+"'"
	cQuery += " AND C5_CHGLOG IN('S','C','H') "
	cQuery += " AND C5_TIPO = 'N' "
	cQuery += " AND SC5.D_E_L_E_T_ = ' ' "
	cQuery += " AND DC_FILIAL = '"+xFilial("SDC")+"'"
	cQuery += " AND DC_PEDIDO = C5_NUM "
	cQuery += " AND DC_CHGSTAT = '"+Space(U_LenVar("DC_CHGSTAT"))+"'"
	cQuery += " AND SDC.D_E_L_E_T_ = ' ' "

	U_CriaTmp(cQuery,'B010QSC5')

	nSeparar := B010QSC5->TOTPED

	//- Efetua a busca do total de itens a serem separados
	cQuery := " SELECT COUNT(*) TOTITEM FROM "
	cQuery += RetSqlName("SC5")+" SC5,"
	cQuery += RetSQlName("SDC")+" SDC "
	cQuery += " WHERE C5_FILIAL = '"+xFilial("SC5")+"'"
	cQuery += " AND C5_CHGLOG IN ('S','C','H') "
	cQuery += " AND C5_TIPO = 'N' "
	cQuery += " AND SC5.D_E_L_E_T_ = ' ' "
	cQuery += " AND DC_FILIAL = '"+xFilial("SDC")+"'"
	cQuery += " AND DC_PEDIDO = C5_NUM "
	cQuery += " AND DC_CHGSTAT = '"+Space(U_LenVar("DC_CHGSTAT"))+"' "
	cQuery += " AND SDC.D_E_L_E_T_ = ' ' "
	U_CriaTmp(cQuery,'B010QSC5')

	nExpItem   := TransForm(B010QSC5->TOTITEM,'@E 999,999')+' / '+TransForm(Round(B010QSC5->TOTITEM/nSeparar,0),'@E 999,999')


	//- Efetua a busca de pedidos urgentes
	cQuery := "SELECT COUNT(DISTINCT SC5.C5_NUM) TOTITEM FROM "
	cQuery += RetSqlName("SC5")+" SC5,"
	cQuery += RetSQlName("SDC")+" SDC "
	cQuery += " WHERE C5_FILIAL = '"+xFilial("SC5")+"'"
	cQuery += " AND C5_CHGLOG IN ('S','C','H') "
	cQuery += " AND C5_CHGPRIO IN ('"+StrTran(cUrgente,",","','")+"')"
	cQuery += " AND C5_TIPO = 'N' "
	cQuery += " AND SC5.D_E_L_E_T_ = ' ' "
	cQuery += " AND DC_FILIAL = '"+xFilial("SDC")+"'"
	cQuery += " AND DC_PEDIDO = C5_NUM "
	cQuery += " AND DC_CHGSTAT = '"+Space(U_LenVar("DC_CHGSTAT"))+"' "
	cQuery += " AND SDC.D_E_L_E_T_ = ' ' "
	U_CriaTmp(cQuery,'B010QSC5')

	nRetira   := B010QSC5->TOTITEM

	//- Efetua a Busca do numero de dias em atraso que esta a expedicao
	cQuery := "SELECT COUNT(DISTINCT ZJ_DTINI) ATRASO,  "
	cQuery += " COUNT(DISTINCT ZJ_PEDIDO) PEDIDO FROM "
	cQuery += RetSqlName("SZJ")
	cQuery += " WHERE ZJ_FILIAL = '"+xFilial("SZJ")+"'"
	cQuery += " AND ZJ_TIPO = 'L' "
	cQuery += " AND ZJ_DTINI < '"+dTos(dDataBase)+"'"
	cQuery += " AND ZJ_PEDIDO IN (SELECT C5_NUM FROM "
	cQuery += RetSqlName("SC5")
	cQuery += " WHERE C5_FILIAL = '"+xFilial("SC5")+"'"
	cQuery += " AND C5_CHGLOG = 'S' "
	cQuery += " AND D_E_L_E_T_ = ' ' )"
	cQuery += " AND D_E_L_E_T_ = ' ' "
	U_CriaTmp(cQuery,'B010QSC5')

	nDiasAtras := TransForm(B010QSC5->ATRASO,'@E 99')+' / '+TransForm(B010QSC5->PEDIDO,'@E 9,999')

	//- Efetua a Busca de quatidade de pedidos atrasados, ou seja,
	//- verifica os pedidos que jแ estao no faturamento alguma parte
	cQuery := "SELECT COUNT(DISTINCT C5_NUM) ATRASADO, COUNT(C6_ITEM) ITENS FROM "
	cQuery += RetSqlName("SC5")+" SC5, "
	cQuery += REtSqlName("SC6")+" SC6 "
	cQuery += " WHERE C5_FILIAL = '"+xFilial("SC5")+"'"
	cQuery += " AND C5_TIPO = 'N' "
	cQuery += " AND C5_NUM IN (SELECT DISTINCT DC_PEDIDO FROM "
	cQuery += RetSqlName("SDC")
	cQuery += " WHERE DC_FILIAL = '"+xFilial("SDC")+"'"
	cQuery += " AND DC_CHGOK <> '  ' " //- esta incluido o cf e ok
	cQuery += " AND D_E_L_E_T_ = ' ' "
	cQuery += " AND EXISTS(SELECT DC_PEDIDO FROM "
	cQuery += RetSqlName("SDC")+" SDC "
	cQuery += " WHERE SDC.DC_FILIAL = '"+xFilial("SDC")+"'"
	cQuery += " AND SDC.DC_PEDIDO = DC_PEDIDO "
	cQuery += " AND SDC.DC_ITEM = DC_ITEM "
	cQuery += " AND SDC.DC_PRODUTO = DC_PRODUTO "
	cQuery += " AND SDC.D_E_L_E_T_ =' ' "
	cQuery += " AND SDC.DC_CHGOK = '  ' )) "
	cQuery += " AND C5_CHGLOG IN ('S','H','C') "
	cQuery += " AND SC5.D_E_L_E_T_ =  ' '  "
	cQuery += " AND C6_FILIAL = '"+xFilial("SC6")+"'"
	cQuery += " AND C6_NUM = C5_NUM "
	cQuery += " AND SC6.D_E_L_E_T_ = ' ' "
	U_CriaTmp(cQuery,'B010QSC5')

	nAtrasado := TransForm(B010QSC5->ATRASADO,'@E 99,999')+' / '+TransForm(B010QSC5->ITENS,'@E 99,999')


	//- busca os Registros a serem processados
	aBrwPedido := aClone(U_QPedSlow()) //- funcao dentro do chgn016

	aBrwLocais := {}

	cQuery := "SELECT CASE C5_CHGLOG "
	cQuery += " WHEN 'S' THEN 'S'"
	cQuery += " ELSE 'C'"
	cQuery += " END STATUS,"
	cQuery += " CASE C5_CHGPRIO"
	cQuery += " WHEN '00' THEN 'U'"
	cQuery += " WHEN '01' THEN 'U'"
	cQuery += " WHEN '02' THEN 'U'"
	cQuery += " WHEN '03' THEN 'U'"
	cQuery += " WHEN '04' THEN 'U'"
	cQuery += " ELSE 'N'"
	cQuery += " END PRIORIDADE,"
	cQuery += " CASE SUBSTR(DC_LOCALIZ,1,1)"
	cQuery += " WHEN 'A' THEN 'A'"
	cQuery += " WHEN 'B' THEN 'A'"
	cQuery += " WHEN 'C' THEN 'C'"
	cQuery += " WHEN 'D' THEN 'C'"
	cQuery += " WHEN 'E' THEN 'E' "
	cQuery += " WHEN 'I' THEN 'E' "
	cQuery += " WHEN 'F' THEN 'F' "
	cQuery += " WHEN 'J' THEN 'F'"
	cQuery += " WHEN 'G' THEN 'G'"
	cQuery += " WHEN 'H' THEN 'G'"
	cQuery += " ELSE 'K'"
	cQuery += " END LOCAIS,COUNT(DISTINCT C5_NUM) PEDIDOS, COUNT(*) ITENS,"
	cQuery += " SUM(DC_QUANT) TOTPCS FROM "
	cQuery += RetSqlName("SC5")+" SC5,"
	cQuery += RetSqlName("SDC")+" SDC "
	cQuery += " WHERE C5_FILIAL = '"+xFilial("SC5")+"'"
	cQuery += " AND C5_CHGLOG IN ('S','H','C')"
	cQuery += " AND SC5.D_E_L_E_T_ = ' ' "
	cQuery += " AND DC_FILIAL = '"+xFilial("SDC")+"'"
	cQuery += " AND DC_PEDIDO = C5_NUM "
	cQuery += " AND DC_CHGSTAT = '"+Space(U_LenVar("DC_CHGSTAT"))+"'"
	cQuery += " AND SDC.D_E_L_E_T_ = ' '"
	cQuery += " GROUP BY 1,2,3"
	cQuery += " ORDER BY 3"
	U_CriaTmp(cQuery,'B010QSC5')


	If  B010QSC5->(!Eof())
		While B010QSC5->(!Eof())
			If (nPosPed := aScan(aBrwLocais,{|x| x[1] == B010QSC5->LOCAIS})) == 0
				AADD(aBrwLocais,{B010QSC5->LOCAIS,B010QSC5->PEDIDOS,0,0,B010QSC5->ITENS,B010QSC5->TOTPCS})
				nPosPed := Len(aBrwLocais) //- guarda a posicao
			Else
				aBrwLocais[nPosPed,2] += B010QSC5->PEDIDOS
				aBrwLocais[nPosPed,5] += B010QSC5->ITENS
				aBrwLocais[nPosPed,6] += B010QSC5->TOTPCS
			EndIf
			If B010QSC5->STATUS <> 'S'
				aBrwLocais[nPosPed,4] += B010QSC5->PEDIDOS
			EndIF
			If B010QSC5->PRIORIDADE == 'U'
				aBrwLocais[nPosPed,3] += B010QSC5->PEDIDOS
			EndIf
			B010QSC5->(dbSkip())
		EndDo
	Else
		aBrwLocais := {{' ',0,0,0,0,0}}
	EndIf
	U_CHGClose('B010QSC5')

Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณStatusPed บAutor  ณNilton A. Rodrigues บ Data ณ  20/03/2014 บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณAtualiza o semaforo do monitor de pedidos                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function StatusPed()
	Local cQuery

	//Analisa se hแ o fechamento do sistema para manutencao
	If File("FECHAB010.CHG")
		U_AvisoExp('Fechado para Manuten็ใo',"Aten็ใo o sistema se econtra em manuten็ใo. "+;
		"Aguarde libera็ใo do sistema."+CRLF+;
		"Sua janela fecharแ automaticamente!",,,8000)
		Ms_Quit()
	EndIf
	//--------------------------------------------------------
	//- forca a saida do sistema caso seja
	//- o horario maior, para funcionar o InactiveTimeOut
	//--------------------------------------------------------
	If Time() > '22:00'
		oDlg_B010:End()
		Ms_Quit()
		Return
	EndIf

	cQuery := "SELECT CASE C5_CHGLOG "
	cQuery += " WHEN 'S' THEN 'S'"
	cQuery += " ELSE 'C'"
	cQuery += " END STATUS,"
	cQuery += " CASE C5_CHGPRIO"
	cQuery += " WHEN '00' THEN 'U'"
	cQuery += " WHEN '01' THEN 'U'"
	cQuery += " WHEN '02' THEN 'U'"
	cQuery += " WHEN '03' THEN 'U'"
	cQuery += " WHEN '04' THEN 'U'"
	cQuery += " ELSE 'N'"
	cQuery += " END PRIORIDADE,"
	cQuery += " CASE SUBSTR(DC_LOCALIZ,1,1)"
	cQuery += " WHEN 'A' THEN 'A'"
	cQuery += " WHEN 'B' THEN 'A'"
	cQuery += " WHEN 'C' THEN 'C'"
	cQuery += " WHEN 'D' THEN 'C'"
	cQuery += " WHEN 'E' THEN 'E' "
	cQuery += " WHEN 'I' THEN 'E' "
	cQuery += " WHEN 'F' THEN 'F' "
	cQuery += " WHEN 'J' THEN 'F'"
	cQuery += " WHEN 'G' THEN 'G'"
	cQuery += " WHEN 'H' THEN 'G'"
	cQuery += " ELSE 'K'"
	cQuery += " END LOCAIS,COUNT(DISTINCT C5_NUM) PEDIDOS, COUNT(*) ITENS,"
	cQuery += " SUM(DC_QUANT) TOTPCS FROM "
	cQuery += RetSqlName("SC5")+" SC5,"
	cQuery += RetSqlName("SDC")+" SDC "
	cQuery += " WHERE C5_FILIAL = '"+xFilial("SC5")+"'"
	cQuery += " AND C5_CHGLOG IN ('S','H','C')"
	cQuery += " AND SC5.D_E_L_E_T_ = ' ' "
	cQuery += " AND DC_FILIAL = '"+xFilial("SDC")+"'"
	cQuery += " AND DC_PEDIDO = C5_NUM "
	cQuery += " AND DC_CHGSTAT = '"+Space(U_LenVar("DC_CHGSTAT"))+"'"
	cQuery += " AND SDC.D_E_L_E_T_ = ' '"
	cQuery += " GROUP BY 1,2,3"
	cQuery += " ORDER BY 3,2,1 DESC"
	U_CriaTmp(cQuery,'B010QSC5')


	oBmp_Bar_A:SetBmp( "DISABLE" )
	oBmp_Bar_C:SetBmp( "DISABLE" )
	oBmp_Bar_E:SetBmp( "DISABLE" )
	oBmp_Bar_F:SetBmp( "DISABLE" )
	oBmp_Bar_G:SetBmp( "DISABLE" )
	oBmp_Bar_K:SetBmp( "DISABLE" )
	If  B010QSC5->(!Eof())
		While B010QSC5->(!Eof())
			If B010QSC5->LOCAIS == 'A
				If B010QSC5->PRIORIDADE == 'U'
					oBmp_Bar_A:SetBmp( "BR_AZUL" )
				ElseIf B010QSC5->STATUS <> 'S'
					oBmp_Bar_A:SetBmp( "BR_LARANJA" )
				Else
					oBmp_Bar_A:SetBmp( "ENABLE" )
				EndIF
			ElseIf B010QSC5->LOCAIS == 'C'
				If B010QSC5->PRIORIDADE == 'U'
					oBmp_Bar_C:SetBmp( "BR_AZUL" )
				ElseIf B010QSC5->STATUS <> 'S'
					oBmp_Bar_C:SetBmp( "BR_LARANJA" )
				Else
					oBmp_Bar_C:SetBmp( "ENABLE" )
				EndIF
			ElseIf B010QSC5->LOCAIS == 'E'
				If B010QSC5->PRIORIDADE == 'U'
					oBmp_Bar_E:SetBmp( "BR_AZUL" )
				ElseIf B010QSC5->STATUS <> 'S'
					oBmp_Bar_E:SetBmp( "BR_LARANJA" )
				Else
					oBmp_Bar_E:SetBmp( "ENABLE" )
				EndIF
			ElseIf B010QSC5->LOCAIS == 'F'
				If B010QSC5->PRIORIDADE == 'U'
					oBmp_Bar_F:SetBmp( "BR_AZUL" )
				ElseIf B010QSC5->STATUS <> 'S'
					oBmp_Bar_F:SetBmp( "BR_LARANJA" )
				Else
					oBmp_Bar_F:SetBmp( "ENABLE" )
				EndIF
			ElseIf B010QSC5->LOCAIS == 'G'
				If B010QSC5->PRIORIDADE == 'U'
					oBmp_Bar_G:SetBmp( "BR_AZUL" )
				ElseIf B010QSC5->STATUS <> 'S'
					oBmp_Bar_G:SetBmp( "BR_LARANJA" )
				Else
					oBmp_Bar_G:SetBmp( "ENABLE" )
				EndIF
			Else
				If B010QSC5->PRIORIDADE == 'U'
					oBmp_Bar_K:SetBmp( "BR_AZUL" )
				ElseIf B010QSC5->STATUS <> 'S'
					oBmp_Bar_K:SetBmp( "BR_LARANJA" )
				Else
					oBmp_Bar_K:SetBmp( "ENABLE" )
				EndIF
			EndIf
			B010QSC5->(dbSkip())
		EndDo
	EndIf

	//------------------------------------------------------------
	//- VERIFICA A EXISTENCIA DA ATIVIDADE DE ESTOQUE
	//------------------------------------------------------------
	cQuery := "SELECT CASE SUBSTR(ZA7_ENDDES,1,1) "
	cQuery += " WHEN 'A' THEN 'A'"
	cQuery += " WHEN 'B' THEN 'A'"
	cQuery += " WHEN 'C' THEN 'A'"
	cQuery += " WHEN 'D' THEN 'A'"
	cQuery += " WHEN 'E' THEN 'A'"
	cQuery += " WHEN 'I' THEN 'A'"
	cQuery += " WHEN 'F' THEN 'F'"
	cQuery += " WHEN 'J' THEN 'F'"
	cQuery += " WHEN 'G' THEN 'G'"
	cQuery += " WHEN 'H' THEN 'G'"
	cQuery += " ELSE 'K'"
	cQuery += " END LOCAIS, COUNT(*) ITENS FROM "
	cQuery += RetSqlName("ZA7")
	cQuery += " WHERE ZA7_FILIAL = '"+xFilial("ZA7")+"'"
	cQuery += " AND ZA7_ATIVID = '"+U_SeekAtiv('B')+"'"
	cQuery += " AND ZA7_STATUS = 'A'"
	cQuery += " AND ZA7_RH = '"+Space(U_LenVar('ZA7_RH'))+"'"
	cQuery += " AND D_E_L_E_T_ = ' ' "
	cQuery += " GROUP BY 1"
	cQuery += " ORDER BY 1"
	U_CriaTmp(cQuery,'B010QSC5')
	If  B010QSC5->(!Eof())
		While B010QSC5->(!Eof())
			If B010QSC5->LOCAIS == 'A' .and. AllTrim(Upper(oBmp_Bar_A:CResName)) == 'DISABLE'
				oBmp_Bar_A:SetBmp( "ENABLE" )
			ElseIf B010QSC5->LOCAIS == 'C' .and. AllTrim(Upper(oBmp_Bar_C:CResName)) == 'DISABLE'
				oBmp_Bar_C:SetBmp( "ENABLE" )
			ElseIf B010QSC5->LOCAIS == 'E' .and. AllTrim(Upper(oBmp_Bar_E:CResName)) == 'DISABLE'
				oBmp_Bar_E:SetBmp( "ENABLE" )
			ElseIf B010QSC5->LOCAIS == 'F' .and. AllTrim(Upper(oBmp_Bar_F:CResName)) == 'DISABLE'
				oBmp_Bar_F:SetBmp( "ENABLE" )
			ElseIf B010QSC5->LOCAIS == 'G' .and. AllTrim(Upper(oBmp_Bar_G:CResName)) == 'DISABLE'
				oBmp_Bar_G:SetBmp( "ENABLE" )
			ElseIF AllTrim(Upper(oBmp_Bar_K:CResName)) == 'DISABLE'
				oBmp_Bar_K:SetBmp( "ENABLE" )
			EndIf
			B010QSC5->(dbSkip())
		EndDo
	EndIf

	U_CHGClose('B010QSC5')


	oBmp_Bar_A:Refresh()
	oBmp_Bar_C:Refresh()
	oBmp_Bar_E:Refresh()
	oBmp_Bar_F:Refresh()
	oBmp_Bar_G:Refresh()
	oBmp_Bar_K:Refresh()

	oCracha:SetFocus()
	oCracha:SelectAll()
	oDlg_B010:Refresh()

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณSeekExp   บAutor  ณNilton A. Rodrigues บ Data ณ  26/05/2015 บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao responsavel por montar o array com as atividades    บฑฑ
ฑฑบ          ณ configuradas para o usuario                                บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function SeekExp(aAtividade)
	Local cQuery
	Local lAchou := .F.
	cQuery := "SELECT ZY_CODIGO, ZY_NOME, ZA3_ORDEM, ZA5_ATIVID, ZA4_DESC, ZA4_TIPO FROM "
	cQuery += RetSqlName("SZY")+" SZY,"
	cQuery += RetSqlName("ZA3")+" ZA3,"
	cQuery += RetSqlName("ZA5")+" ZA5,"
	cQuery += RetSqlName("ZA4")+" ZA4 "
	cQuery += " WHERE ZY_FILIAL = '"+xFilial("SZY")+"'"
	cQuery += " AND ZY_CODIGO = '"+SZY->ZY_CODIGO+"'"
	cQuery += " AND SZY.D_E_L_E_T_ = ' ' "
	cQuery += " AND ZA3_FILIAL = '"+xFilial("ZA3")+"'"
	cQuery += " AND ZA3_CODRH = ZY_CODIGO"
	cQuery += " AND ZA3.D_E_L_E_T_ = ' ' "
	cQuery += " AND ZA5_FILIAL = '"+xFilial("ZA5")+"'"
	cQuery += " AND ZA5_FUNCAO = ZA3_FUNCAO "
	cQuery += " AND ZA5.D_E_L_E_T_ = ' ' "
	cQuery += " AND ZA4_FILIAL = '"+xFilial("ZA4")+"'"
	cQuery += " AND ZA4_CODIGO = ZA5_ATIVID "
	cQuery += " AND ZA4_TIPO IN ('B','F')"  //- atividades de separacao e enderecamento
	cQuery += " AND ZA4.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY ZA3_ORDEM"
	U_CriaTmp(cQuery,'QSEEKEXP')
	aAtividade := {}
	If QSEEKEXP->(!Eof())
		lAchou := .T.
		While QSEEKEXP->(!Eof())
			//- ALIMENTA AS ATIVIDADES CONFIGURADAS
			AADD(aAtividade,QSEEKEXP->ZA4_TIPO)
			QSEEKEXP->(dbSkip())
		EndDo
	EndIf
Return lAchou

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณSearchEst บAutor  ณNilton A. Rodrigues บ Data ณ  28/05/2015 บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณFuncao responsavel por buscar e imprimir a listagem de      บฑฑ
ฑฑบ          ณprodutos a serem endere็ados                                บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function SearchEst(oPrint)
	Local oFont10  := TFont():New(cFntCabec,,-12,,.T.,,,,.F.,.F.)
	Local oFont20  := TFont():New(cFntCabec,,-18,,.T.,,,,.F.,.F.)
	Local lImpOk   := .F.//- indica se houve impressao
	Local cQuery
	Local nLin      := 0
	Local nTotRec   := 0
	Local nPag      := 0
	Local nPagImp   := 0
	Local nTotFolha := 0
	Local cLockKey
	Local nTotPec   := 0

	Local cAtividade := U_SeekAtiv('B')//- codigo de enderecamento estoquista
	//--------------------------------------------------------------------------------------------------------
	//- codigo da atividade de dispositivo a enderecar, indica que o produto esta aguardando o endereco final
	//--------------------------------------------------------------------------------------------------------
	Local cAtivPend  := U_SeekAtiv('D')

	//----------------------------------------
	//- guarda a posicao do local de trabalho
	//----------------------------------------
	Local cCodSZY  := SZY->ZY_CODIGO
	Local cArmOld  := SZY->ZY_ARMAZEM
	Local cArm     := SZY->ZY_ARMAZEM
	Local nPosArm  := ''
	Local nLimite  := Val(SuperGetMv("CHGWMSFIRS"))
	Local nX
	Local cCodBar  := ''
	Local nTotFor
	Local cHora    := Time()
	Local lArm_G   := cArm== 'G' .or. cArm== 'F' .or. cArm== 'K'
	Local lExecute := .F.
	Local cLocArmG := "'G','H','F','J','K'"

	Local nTotProd := 0

	dbSelectArea("SB1")
	dbSetOrder(1)
	//-------------------------------------------------------------------------------------------------------
	//- montagem das buscas
	//- deve ser realizado desta maneira para evistar erros de amarracao
	//-------------------------------------------------------------------------------------------------------
	AADD(aLocais,{"A","'A','B'"})
	AADD(aLocais,{"B","'A','B'"})
	AADD(aLocais,{"C","'C','D'"})
	AADD(aLocais,{"D","'C','D'"})
	AADD(aLocais,{"E","'E'"})
	AADD(aLocais,{"G","'G','H'"})
	AADD(aLocais,{"H","'G','H'"})
	AADD(aLocais,{"K","'K'"})
	AADD(aLocais,{"F","'J','F'"})
	AADD(aLocais,{"J","'J','F'"})


	//-------------------------------------------------------------------------------------------------------
	//- nao existe barracao configurado
	//-------------------------------------------------------------------------------------------------------
	If (nPosArm  := aScan(aLocais,{|x| AllTrim(x[1])==SZY->ZY_ARMAZEM})) == 0
		U_AvisoExp("Armaz้m","Aten็ใo nใo existe nenhum armaz้m configurado, verifique",.T.)
		Return lImpOk
	Endif


	//-------------------------------------------------------------------------------------------------------
	//- Fecha a atividade anterior do funcionario
	//-------------------------------------------------------------------------------------------------------
	U_AtuAtivFun(SZY->ZY_CODIGO,/*__cDoc*/,/*__nTotMov*/,/*__cTipoMov*/,/*__cArmazem*/,/*__lRetTmp*/,.T.)

	//-------------------------------------------------------------------------------------------------------
	//- efetua a trava do semaforo
	//-------------------------------------------------------------------------------------------------------
	cLockKey  := 'W008'+AllTrim(cNumEmp)+aLocais[nPosArm,1]

	While .T.
		If LockByName(cLockKey,.T.,.T.,.F.)
			Exit
		EndIf
		FwMsgRun(,{||Sleep(nTimeSleep)},'Lock Estoque','Processo sendo usado por outra pessoa.')
	EndDo

	//- loga o usuแrio que esta em uso 
	MemoWrite(cLockLog,;
	'Tipo...: PROCESSO ESTOQUE'+CRLF+;
	'Pedido.: '+CRLF+;
	'Data...: '+dToc(dDataBase)+' - '+cTimeBloq+CRLF+;
	'Maquina: '+ UPPER(ComputerName())+CRLF+;
	'Usuario: '+ LogUserName()+CRLF+;
	'Cracha.: '+SZY->ZY_CODIGO+CRLF+;
	'Nome...: '+AllTrim(SZY->ZY_NOME))

	MemoWrite('W008'+AllTrim(cNumEmp)+aLocais[nPosArm,1]+'.lck',;
	'Tipo...: PROCESSO ESTOQUE'+CRLF+;
	'Data...: '+dToc(dDataBase)+' - '+Time()+CRLF+;
	'Maquina: '+ UPPER(ComputerName())+CRLF+;
	'Usuario: '+ LogUserName()+CRLF+;
	'Cracha.: '+SZY->ZY_CODIGO+CRLF+;
	'Nome...: '+AllTrim(SZY->ZY_NOME))

	While .T.
		cQuery := " SELECT DISTINCT SUBSTR(ZA7_ENDDES,1,1) ARMAZEM, COUNT(*) TOTARM FROM "
		cQuery += RetSqlName("ZA7")
		cQuery += " WHERE ZA7_FILIAL = '"+xFilial("ZA7")+"'"
		cQuery += " AND ZA7_ATIVID = '"+cAtividade+"'"
		cQuery += " AND (ZA7_RH = '"+cCodSZY+"' OR ZA7_RH = '"+Space(U_LenVar('ZA7_RH'))+"')"
		cQuery += " AND ZA7_STATUS IN ('A','B') "

		//-------------------------------------------------------------------------------------------------------
		//- QDO FOR A PRIMEIRA PASSADA O SISTEMA PEGA  DE ACORDO COM O ENDERECO DO USUARIO
		//- DEPOIS ELE CHECA SE EXISTE OUTROS ARMAZENS
		//-------------------------------------------------------------------------------------------------------
		If !lExecute
			cQuery += " AND SUBSTR(ZA7_ENDDES,1,1) IN ("+aLocais[nPosArm,2]+")"
		ElseIf !lArm_G
			cQuery += " AND SUBSTR(ZA7_ENDDES,1,1) NOT IN ("+cLocArmG+")"//- Retira o barracao G
		EndIf
		cQuery += " AND D_E_L_E_T_ = ' ' "
		cQuery += " GROUP BY 1 "
		cQuery += " ORDER BY 2 DESC, 1"
		U_CriaTmp(cQuery,'QZA7')

		//-------------------------------------------------------------------------------------------------------
		//- caso nao localize nenhum registro e nao seja do grupo ArmG
		//- faz uma nova busca, desta vez buscando o galpao dispovel para
		//- serem realizados os trabalhos de enderecamento
		//-------------------------------------------------------------------------------------------------------
		If QZA7->(Eof()) .and. !lArm_G .and. !lExecute
			lExecute := .T.
			Loop
		ElseIf QZA7->(!Eof())
			//-------------------------------------------------------------------------------------------------------
			//- caso tenha encontrado registros para serem guardados
			//- faz uma nova checagem para buscar a sequencia de locais
			//-------------------------------------------------------------------------------------------------------
			If (nPosArm  := aScan(aLocais,{|x| AllTrim(x[1])==QZA7->ARMAZEM})) == 0
				U_AvisoExp("Armaz้m Automแtico","Erro de estrutura armaz้m: "+QZA7->ARMAZEM,.T.)
				Return lImpOk
			Endif
		EndIf
		Exit
	EndDo
	//-------------------------------------------------------------------------------------------------------
	//- inicia os processo de buscas dos registros
	//-------------------------------------------------------------------------------------------------------
	cQuery := " SELECT FIRST "+cValToChar(nLimite)+" MIN(ZA7_PRIORI) ZA7_PRIORI,ZA7_CODPRO, ZA7_NUMSEQ, ZA7_RH FROM "
	cQuery += RetSqlName("ZA7")
	cQuery += " WHERE ZA7_FILIAL = '"+xFilial("ZA7")+"'"
	cQuery += " AND ZA7_ATIVID = '"+cAtividade+"'"
	cQuery += " AND (ZA7_RH = '"+cCodSZY+"' OR ZA7_RH = '"+Space(U_LenVar('ZA7_RH'))+"')"
	cQuery += " AND ZA7_STATUS IN ('A','B') "
	cQuery += " AND SUBSTR(ZA7_ENDDES,1,1) IN ("+aLocais[nPosArm,2]+")"
	cQuery += " AND D_E_L_E_T_ = ' ' "
	cQuery += " GROUP BY ZA7_CODPRO, ZA7_NUMSEQ, ZA7_RH"
	cQuery += " ORDER BY ZA7_RH DESC, 1"
	U_CriaTmp(cQuery,'QZA7')
	//-------------------------------------------------------------------------------------------------------
	//- compoe a chave para garantir o uso das atualizacoes
	//-------------------------------------------------------------------------------------------------------
	While QZA7->(!Eof())
		cQuery := " SELECT R_E_C_N_O_ RECZA7 FROM "
		cQuery += RetSqlName("ZA7")
		cQuery += " WHERE ZA7_FILIAL = '"+xFilial("ZA7")+"'"
		cQuery += " AND ZA7_ATIVID   = '"+cAtividade+"'"
		cQuery += " AND (ZA7_RH = '"+cCodSZY+"' OR ZA7_RH = '"+Space(U_LenVar('ZA7_RH'))+"')"
		cQuery += " AND ZA7_CODPRO   = '"+QZA7->ZA7_CODPRO+"'"
		cQuery += " AND ZA7_NUMSEQ   = '"+QZA7->ZA7_NUMSEQ+"'"
		cQuery += " AND ZA7_STATUS IN ('A','B') "
		cQuery += " AND ZA7_QTD > 0 "
		cQuery += " AND D_E_L_E_T_ = ' '"
		U_CriaTmp(cQuery,'_QZA7')

		While _QZA7->(!Eof())
			cQuery := "UPDATE "+RetSqlName("ZA7")
			cQuery += " SET ZA7_RH = '"+cCodSZY+"',"
			cQuery += " ZA7_STATUS = 'B'"
			cQuery += " WHERE R_E_C_N_O_ = "+cValToChar(_QZA7->RECZA7)
			While .T.
				If TcSqlExec(cQuery) == 0
					Exit
				EndIf
				MsAguarde({||Sleep(nTimeSleep)},'Registro Travado - ZA7','Registro sendo usado por outro usuแrio, aguarde...')
			EndDo
			_QZA7->(dbSkip())
		EndDo
		QZA7->(dbSkip())
	EndDo

	TCRefresh(RetSqlName("ZA7"))

	//-------------------------------------------------------------------------------------------------------
	//- Destrava o semaforo
	//-------------------------------------------------------------------------------------------------------
	MemoWrite('W008'+AllTrim(cNumEmp)+aLocais[nPosArm,1]+'.lck',;
	'Tipo...: PROCESSO ESTOQUE'+CRLF+;
	'Data...: '+dToc(dDataBase)+' - '+Time()+CRLF+;
	'Maquina: '+ UPPER(ComputerName())+CRLF+;
	'Usuario: '+ LogUserName()+CRLF+;
	'Cracha.: '+CRLF+;
	'Nome...: LIBERADO')
	UnLockByName(cLockKey,.T.,.T.,.F.)

	cQuery := " SELECT ZA7_CODPRO, ZA7_NUMSEQ,ZA7_LORI,ZA7_ENDORI,ZA7_DOC,ZA7_SERIE,ZA7_ORIGEM,ZA7_FORNEC,ZA7_LOJA,"
	cQuery += " ZA7_LDEST, ZA7_ENDDES, ZA7_TIPDOC, SUM(ZA7_QTD) TOTAL FROM "
	cQuery += RetSqlName("ZA7")
	cQuery += " WHERE ZA7_FILIAL = '"+xFilial("ZA7")+"'"
	cQuery += " AND ZA7_ATIVID = '"+cAtividade+"'"
	cQuery += " AND ZA7_RH = '"+cCodSZY+"'"
	cQuery += " AND ZA7_STATUS = 'B' "
	cQuery += " AND D_E_L_E_T_ = ' ' "
	cQuery += " GROUP BY ZA7_CODPRO, ZA7_NUMSEQ,ZA7_LORI,ZA7_ENDORI,ZA7_DOC,ZA7_SERIE,ZA7_ORIGEM,ZA7_FORNEC,ZA7_LOJA,"
	cQuery += " ZA7_LDEST, ZA7_ENDDES, ZA7_TIPDOC"
	U_CriaTmp(cQuery,'QZA7')
	//-------------------------------------------------------------------------------------------------------
	//- o processo abaixo faz com que seja aglutinado os registros iguais de movimento
	//- ou seja, se o endere็o de origem mais destino e numseq forem iguais fara uma juncao de ambos
	//-------------------------------------------------------------------------------------------------------
	//- ARMAZENA O SERIAL
	//-------------------------------------------------------------------------------------------------------
	If QZA7->(!Eof())
		cCodBar := Soma1(GetMv("MV_CHGFATP"),8)

		PutMv("MV_CHGFATP",cCodBar)


		While QZA7->(!Eof())
			//-----------------------------------------------------------
			//- CRIA O REGISTRO JA COM A AMARRACAO DO DISPOSITIVO
			//-----------------------------------------------------------
			U_CriaZA7(QZA7->ZA7_CODPRO,QZA7->ZA7_LORI,QZA7->ZA7_ENDORI,QZA7->ZA7_LDEST,QZA7->ZA7_ENDDES,QZA7->TOTAL,cAtivPend,;
			QZA7->ZA7_DOC,QZA7->ZA7_SERIE,QZA7->ZA7_ORIGEM,QZA7->ZA7_FORNEC,QZA7->ZA7_LOJA,QZA7->ZA7_NUMSEQ,QZA7->ZA7_TIPDOC,SZY->ZY_CODIGO,'A',cCodBar)

			//-----------------------------------------------
			//- AJUSTA O STATUS DA ATIVIDADE COMO ENCERRADA
			//-----------------------------------------------
			cQuery := "UPDATE "+RetSqlName("ZA7")
			cQuery += " SET ZA7_STATUS = 'D', "
			cQuery += " ZA7_TIMEOF = '"+dTos(dDataBase)+"-"+Time()+"'"
			cQuery += " WHERE ZA7_FILIAL = '"+xFilial("ZA7")+"'"
			cQuery += " AND ZA7_CODPRO = '"+QZA7->ZA7_CODPRO+"'"
			cQuery += " AND ZA7_LORI   = '"+QZA7->ZA7_LORI+"'"
			cQuery += " AND ZA7_LDEST  = '"+QZA7->ZA7_LDEST+"'"
			cQuery += " AND ZA7_ENDDES = '"+QZA7->ZA7_ENDDES+"'"
			cQuery += " AND ZA7_DOC    = '"+QZA7->ZA7_DOC+"'"
			cQuery += " AND ZA7_SERIE  = '"+QZA7->ZA7_SERIE+"'"
			cQuery += " AND ZA7_ORIGEM = '"+QZA7->ZA7_ORIGEM+"'"
			cQuery += " AND ZA7_FORNEC = '"+QZA7->ZA7_FORNEC+"'"
			cQuery += " AND ZA7_LOJA   = '"+QZA7->ZA7_LOJA+"'"
			cQuery += " AND ZA7_NUMSEQ = '"+QZA7->ZA7_NUMSEQ+"'"
			cQuery += " AND ZA7_TIPDOC = '"+QZA7->ZA7_TIPDOC+"'"
			cQuery += " AND ZA7_RH     = '"+cCodSZY+"'"
			cQuery += " AND ZA7_STATUS = 'B' "
			cQuery += " AND ZA7_ATIVID = '"+cAtividade+"'"
			cQuery += " AND D_E_L_E_T_ = ' ' "
			TcSqlExec(cQuery)
			TCRefresh(RetSqlName("ZA7"))

			QZA7->(dbSkip())
		EndDo

		//-------------------------------------------------------------------------------------------------------
		//- I N I C I O   D A   I M P R E S S A O
		//- BUSCA ENDERECOS DE DOCAS
		//-------------------------------------------------------------------------------------------------------

		cQuery := " SELECT ZA7_CODPRO, ZA7_LORI ARM, ZA7_ENDORI LOCALIZ, "
		cQuery += " B1_UM, B1_QE, B1_CODBAR, SUM(ZA7_QTD) QTD FROM "
		cQuery += RetSqlName("ZA7")+" ZA7, "
		cQuery += RetSqlName("SB1")+" SB1 "
		cQuery += " WHERE ZA7_FILIAL = '"+xFilial("ZA7")+"'"
		cQuery += " AND ZA7_RH     = '"+cCodSZY+"'"
		cQuery += " AND ZA7_STATUS = 'A' "
		cQuery += " AND ZA7_ATIVID = '"+cAtivPend+"'"//- atividade pendente
		cQuery += " AND ZA7.D_E_L_E_T_ = ' ' "
		cQuery += " AND B1_FILIAL = '"+xFilial("SB1")+"'"
		cQuery += " AND B1_COD = ZA7_CODPRO "
		cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
		cQuery += " GROUP BY ZA7_CODPRO, ZA7_LORI, ZA7_ENDORI, B1_QE, B1_UM, B1_CODBAR"
		cQuery += " ORDER BY ZA7_ENDORI, ZA7_CODPRO"
		U_CriaTmp(cQuery,'QZA7')

		CabecEst(@nLin,nPag,cCodBar,@oPrint,.T.)
		nTotProd := 0

		While QZA7->(!Eof())
			If nTotProd > 41
				nTotProd := 0
				nPag ++
				CabecEst(@nLin,nPag,cCodBar,@oPrint,.T.)
			EndIf
			ItemEst(@nLin,cCodBar,oPrint)
			nTotProd ++
			QZA7->(dbSkip())
		EndDo


		//-------------------------------------------------------------------------------------------------------
		//- S E G U N D A   P A R T E  -  D A   I M P R E S S A O
		//- ORDENA POR ENDERECOS DE ESTOQUE
		//-------------------------------------------------------------------------------------------------------
		//- monta a query
		//-------------------------------------------------------------------------------------------------------
		U_QEstZA7('QZA7',cCodSZY,cAtivPend)

		CabecEst(@nLin,nPag,cCodBar,@oPrint,.F.)
		nX := 0
		While QZA7->(!Eof())
			//- checa se havera divisao de paginas
			If nTotProd > 39//- 39 ja descontando o cabecalho alternativo
				nTotProd := 0
				nPag ++
				//- impressao do cabecalho padrao
				CabecEst(@nLin,nPag,cCodBar,@oPrint,.T.)
				//- impressao do cabecalho alternativo
				CabecEst(@nLin,nPag,cCodBar,@oPrint,.F.)
			EndIf

			ItemEst(@nLin,cCodBar,oPrint)
			nTotPec += QZA7->QTD
			nX ++ //- totaliza o total de itens a serem guardados
			nTotProd++
			QZA7->(dbSkip())
		EndDo


		//-------------------------------------------------------------------------------------------------------
		//- ATUALIZA AS INFORMACOES DE ATIVIDADES
		//-------------------------------------------------------------------------------------------------------
		U_AtuAtivFun(cCodSZY,'FOLEST',nX,'A',cArmOld,.F.,.F.,cCodBar,0,nTotPec,cHora)

		oPrint:Print()
		lImpOk := .T.
		FreeObj(oPrint)

		oPrint:= Nil
	EndIf

Return lImpOk



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณCabecEst  บAutor  ณNilton A. Rodrigues บ Data ณ  02/06/15   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณCabecalho da listagem do Estoque                            บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function CabecEst(nLin,nPag,cCodBar,oPrint,lImp)
	Local _aArea  := GetArea()
	Local oFont16 := TFont():New(cFntCabec,,-14,,.T.,,,,.T.,.F.)
	Local oFont08 := TFont():New(cFntCabec,,-08,,.F.,,,,.T.,.F.)
	Local oFont08n:= TFont():New(cFntCabec,,-08,,.T.,,,,.T.,.F.)
	Local oFont09 := TFont():New(cFntCabec,,-09,,.T.,,,,.F.,.F.)


	If lImp
		//- Efetua o tratamento da busca do serial
		oPrint:StartPage()

		oPrint:Line( 008, 10, 008, nLarReport,CLR_BLACK,"-1")

		oPrint:FWMSBAR("CODE128" /*cTypeBar*/,0.9/*nRow*/ ,40/*nCol*/ ,cCodBar /*cCode*/,oPrint/*oPrint*/,;
		/*lCheck*/,/*Color*/,/*lHorz*/, /*nWidth*/,1/*nHeigth*/,/*lBanner*/,/*cFont*/,/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,/*lCmtr2Pix*/)

		oPrint:Say(024,010,'* * * Guardar Mercadoria',oFont16,,0,,0)

		oPrint:Say(040,010,AllTrim(SM0->M0_NOME)+" - "+AllTrim(SM0->M0_FILIAL),oFont16,,,,0)

		LineDown(@oPrint,50)

		oPrint := U_DrawBox(oPrint,1,050,060,010,nLarReport,0,0)
		oPrint:Say(059,010,SZY->(ZY_CODIGO+" - "+ZY_NOME)+' || '+cCodBar,oFont09,,16777215,,0)
		oPrint:Say(059,395,"Emissใo: "+dToc(dDataBase)+' -> '+Time(),oFont08n,,16777215,,0)
		LineDown(@oPrint,60)

		nLin:=68
		If nPag >= 2
			oPrint := U_DrawBox(oPrint,1,050,060,010,nLarReport,0,0)
			oPrint:Say(059,010,'Imprimindo a parte '+StrZero(nPag,2)+'  || '+cCodBar,oFont09,,16777215,,0)
			LineDown(@oPrint,60)

			nLin:=68
		EndIf
		oPrint:Say(nLin,nMargEsq+10,'OK',oFont08n,,,,0) //- Item do Pedido
		oPrint:Say(nLin,050,OemToAnsi('| D O C A '),oFont08n,,,,0)
	Else
		oPrint := U_DrawBox(oPrint,1,nLin,nLin+12,010,nLarReport,0,0)
		oPrint:Say(nLin+9,010,'. : :S E Q U E N C I A   E N D E R E ว A M E N T O: : .',oFont09,,16777215,,0)
		LineDown(@oPrint,nLin+10)

		nLin+=nNewLine+10

		oPrint:Say(nLin,nMargEsq+10,'OK',oFont08n,,,,0) //- Item do Pedido
		oPrint:Say(nLin,050,OemToAnsi('| E N D E R E ว O'),oFont08n,,,,0)
	EndIf

	oPrint:Say(nLin,157,OemToAnsi('| P R O D U T O'),oFont08n,,,,0)
	oPrint:Say(nLin,232,OemToAnsi('| QTD'),oFont08n,,,,0)
	oPrint:Say(nLin,279,OemToAnsi('| OBSERVAวรO = Unid. + EMB.+ Apanhe + Cod.Barras'),oFont08n,,,,0)

	LineDown(@oPrint,nLin)

	nLin+=nNewLine+2

	FreeObj(oFont16 )
	FreeObj(oFont08 )
	FreeObj(oFont08n)
	FreeObj(oFont09 )

	oFont16 := nil
	oFont08 := nil
	oFont08n:= nil
	oFont09 := nil

	RestArea(_aArea)
	aSize(_aArea,0)
	_aArea := nil
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณItemEst   บAutor  ณNilton A. Rodrigues บ Data ณ  07/04/05   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao de impressao dos itens a ser guardado               บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function ItemEst(nLin,cCodBar,oPrint)

	Local oFont09 := TFont():New(cFntCabec,,-09,,.F.,,,,.F.,.F.)
	Local oFont10 := TFont():New(cFntCabec,,-12,,.T.,,,,.F.,.F.)
	Local oFont08n:= TFont():New(cFntCabec,,-08,,.T.,,,,.T.,.F.)


	oPrint:Say(nLin,nMargEsq,'(  )',oFont10,,,,0) //- Item do Pedido

	oPrint:Say(nLin,050,OemToAnsi('|'),oFont08n,,,,0)
	oPrint:Say(nLin,157,OemToAnsi('|'),oFont08n,,,,0)
	oPrint:Say(nLin,232,OemToAnsi('|'),oFont08n,,,,0)
	oPrint:Say(nLin,279,OemToAnsi('|'),oFont08n,,,,0)

	oPrint:Say(nLin,058,U_MascEnd(QZA7->LOCALIZ),oFont10,,,,0)

	oPrint := U_DrawBox(oPrint,1,nLin-10,nLin+7,158.6,234.4,0,0)
	oPrint:Say(nLin,166,U_MascProd(QZA7->ZA7_CODPRO),oFont10,,16777215,,0)

	oPrint:Say(nLin,228,TransForm(QZA7->QTD,'@E 999,999'),oFont10,,,,0)
	oPrint:Say(nLin,289,QZA7->B1_UM+' - '+TransForm(QZA7->B1_QE,'@E 999')+' - '+TransForm(QZA7->QTD/QZA7->B1_QE,'@E 9,999.99')+' - '+QZA7->B1_CODBAR,oFont09,,,,0)

	nLin+=5

	LineDown(@oPrint,nLin)

	nLin+=nNewLine+3
	//- Grava o conteudo da pagina em que estara item na prenota

	FreeObj(oFont09 )
	FreeObj(oFont10 )
	FreeObj(oFont08n)

	oFont09 := nil
	oFont10 := nil
	oFont08n:= nil

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณQEstZA7   บAutor  ณNilton A. Rodrigues บ Data ณ  19/06/15   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณFuncao responsavel por elabora a query principal das        บฑฑ
ฑฑบ          ณbuscas de produtos com o endereco final                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Function U_QEstZA7(_cAlias,cCodSZY,cAtivPend)
	cQuery := " SELECT ZA7_CODPRO, ZA7_NUMSEQ, ZA7_LDEST ARM , ZA7_ENDDES LOCALIZ, "
	cQuery += " B1_UM, B1_QE, B1_CODBAR, SUM(ZA7_QTD) QTD, ZA7_DOC, ZA7_SERIE, "
	cQuery += " ZA7_ORIGEM, ZA7_FORNEC, ZA7_LOJA, ZA7_NUMSEQ, ZA7_TIPDOC, ZA7_SERIAL FROM "
	cQuery += RetSqlName("ZA7")+" ZA7, "
	cQuery += RetSqlName("SB1")+" SB1 "
	cQuery += " WHERE ZA7_FILIAL = '"+xFilial("ZA7")+"'"
	cQuery += " AND ZA7_RH     = '"+cCodSZY+"'"
	cQuery += " AND ZA7_STATUS = 'A' "
	cQuery += " AND ZA7_ATIVID = '"+cAtivPend+"'"
	cQuery += " AND ZA7.D_E_L_E_T_ = ' ' "
	cQuery += " AND B1_FILIAL = '"+xFilial("SB1")+"'"
	cQuery += " AND B1_COD = ZA7_CODPRO "
	cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
	cQuery += " GROUP BY ZA7_CODPRO, ZA7_LDEST, ZA7_ENDDES, ZA7_NUMSEQ, B1_QE, B1_UM, B1_CODBAR, ZA7_DOC, ZA7_SERIE, "
	cQuery += " ZA7_ORIGEM, ZA7_FORNEC, ZA7_LOJA, ZA7_NUMSEQ, ZA7_TIPDOC, ZA7_SERIAL "
	cQuery += " ORDER BY ZA7_ENDDES DESC, ZA7_CODPRO"
	U_CriaTmp(cQuery,_cAlias)
Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณTeclasFuncบAutor  ณNilton A. Rodrigues บ Data ณ  15/01/15   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณFuncao resposavel por resetar ou habilitar as teclas de     บฑฑ
ฑฑบ          ณfuncoes padrao do sistema                                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function TeclasFunc(lReset)
	Local nX
	Local nTotFunc := Len(aKeyFunc)

	If lReset
		FreeUsedCode()
		For nX := 1 To nTotFunc
			SetKey(aKeyFunc[nX,1] ,{ || Nil})
		Next nX
	Else
		//- restaura as teclas de fun็๕es usadas
		For nX := 1 To nTotFunc
			SetKey(aKeyFunc[nX,1] ,aKeyFunc[nX,2])
		Next nX
	EndIf
Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณReadCrachaบAutor  ณNilton A. Rodrigues บ Data ณ 14/11/2014  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao responsavel pela leitura e validacao do cracha      บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function ReadCracha(cTpFun,cMsg,cTitle,lRet)
	Local oCracha
	Local cCracha := Space(nTamEtiq)
	Local oSay1
	Local oGroup1
	Local oTCracha
	Local lOk := .F.
	Local oSButton1
	Local nSup  := Iif(cTpFun=='9',255,0)
	Local bSair
	Local oFontTitulo := TFont():New("Courier New",,032,,.T.,,,,,.F.,.F.)
	Local oButton1

	If lRet <> NIL //- INDICA A CHAMADA NO INICIO DO PROGRAMA
		bSair := {|| lRet:= .F.,lOk:= .F.,oTCracha:End()}
	EndIf

	DEFINE MSDIALOG oTCracha TITLE cTitle FROM 000, 000  TO 250, 600 COLORS 0, 16777215 PIXEL Style DS_MODALFRAME
	oTCracha:lEscClose := .F.

	@ 011, 010 SAY oSay1 PROMPT cMsg SIZE 282, 024 OF oTCracha FONT oFontTitulo COLORS nSup, 16777215 PIXEL
	@ 035, 010 MSGET oCracha VAR cCracha SIZE 177, 022 OF oTCracha COLORS 0, 16777215 FONT oFontTitulo PASSWORD PIXEL

	If lRet <> NIL
		@ 070, 010 SAY oSay1 PROMPT "Digite [SAIR] para sair da confer๊ncia" SIZE 278, 035 OF oTCracha FONT oFontTitulo COLORS 255, 16777215 PIXEL
	Else
		@ 070, 010 SAY oSay1 PROMPT cTitle SIZE 278, 035 OF oTCracha FONT oFontTitulo COLORS 16711680, 16777215 PIXEL
	EndIf
	//- botao de apoio para mudanca do get para funcionar a validacao
	@ 220, 120 BUTTON oButton1 PROMPT "oButton1" SIZE 037, 012 OF oTCracha PIXEL

	oCracha:bValid := {|| IIf(lRet <> NIL .and. AllTrim(upper(cCracha)) == 'SAIR',eVal(bSair),((lOk:=U_SeekCracha(cCracha,cTpFun)),oTCracha:End()))}

	ACTIVATE MSDIALOG oTCracha CENTERED


	FreeObj(oFontTitulo)
	oFontTitulo:= Nil

Return lOk
