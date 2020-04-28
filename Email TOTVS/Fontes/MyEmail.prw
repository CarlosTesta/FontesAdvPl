#Include 'Protheus.ch'

Function MyEmail()
Local aCores := { 	{ "ZTB->ZTB_STATUS == '1'"										, "BR_AMARELO"		},;  //a Processar
{ "ZTB->ZTB_STATUS == '2'.and.ZTB->ZTB_STATU1 == '1'"	, "BR_AZUL"			},;  //Aguardando envio
{ "ZTB->ZTB_STATUS == '2'.and.ZTB->ZTB_STATU1 == '2'"	, "BR_VERDE"    	},;  //Enviado
{ "ZTB->ZTB_STATUS == '2'.and.ZTB->ZTB_STATU1 == '4'"	, "BR_PRETO"    	},;  //Veracross
{ "ZTB->ZTB_STATUS <> '1'.and.ZTB->ZTB_STATUS <> '2'"	, "BR_VERMELHO" 	} }  //Com Erro

Private cCadastro := "Controle de boletos Graded"

Private aRotina   := MenuDef() //Implementa menu funcional


//Endereca a funcao de BROWSE                                           ?
dbSelectArea("ZTB")
mBrowse( 6,1,22,75,"ZTB",,,,,,aCores)

//Devolve os indices padroes do SIGA.                                   ?
RetIndex("ZTB")

Return Nil


Static Function MenuDef()
Local aRotina	:= {	{ "Pesquisar" 						, "AxPesqui"   ,0,1		},;		//"Pesquisar"
{ "Visualizar"						, "AxVisual"	,0,2		},;		//"Visualizar"
{ "Gerar Boletos"					, "U_GRDA012"	,0,3		},;		//"Gerar boletos"
{ "Enviar boletos pendentes"	, "U_GRDA013"	,0,4		},;		//"Enviar Pendentes"
{ "Marcar como enviado"			, "U_GRDA017"	,0,4		},;		//"Relatorio"
{ "Marcar como pendente"		, "U_GRDA018"	,0,4		},;		//"Relatorio"
{ "Limpeza de base"				, "U_GRDA016"	,0,4		},;		//"Limpeza"
{ "Legenda"							, "U_GRDA011"	,0,4		}}			//"Legenda"


Return aRotina





User Function GRDA011(cAlias, nReg, nOpc)
Local aLegenda := {	{"BR_AMARELO"    	,"Nao Gerado"  },;
{"BR_AZUL"    		,"Gerado"  		},;
{"BR_VERDE"   		,"Enviado"		},;
{"BR_PRETO"   		,"VeraCross"	},;
{"BR_VERMELHO"		,"Pendente"    }}

BrwLegenda( cCadastro, "Legenda", aLegenda)

Return Nil



User Function GRDA012(cAlias, nReg, nOpc)
Local cPerg			:= 'GRD010'
Local cUserMail	:= ""
Local cemailSent	:= ""
Local cSenhaMail	:= ""
Local aUsuario		:= {}
Local cMsg			:= ""
Local lOk			:= .F.

/*
lVeracros	:= MV_PAR10 == 1
lAutomatico := MV_PAR13 == 1
*/

mBrchgLoop(.F.)

lOk := ChecaPend()

If lOk
	
	If !ApmsgYesNo( "Existem e-mails pendentes de envio, se continuar com a gera o, estes e-mails ser? perdidos, confirma a nova gera o?", "E-mails n? enviados" )
		Return Nil
	Endif
	
Endif

Ajustaperg( cPerg )
If Pergunte( cPerg, .T. )
	
	MsgRun( "Limpeza da base de dados", "Aguarde...", { || LimpaBas( {.T., .T., .T., .T., .T.} ) } )
	
	If MV_PAR10 <> 1 .and. MV_PAR13 == 1
		aUsuario := GetUsermail()
		If len(aUsuario) == 3
			cUserMail 	:= aUsuario[1]
			cemailSent 	:= aUsuario[2]
			cSenhaMail	:= aUsuario[3]
			
			MsgRun( "Gerando emails....", "Aguarde...", { || ProcGera( cAlias, nReg, nOpc, cPerg, cUserMail, cEmailSent, cSenhaMail ) } )
		Else
			ApMsgAlert( "Operacao de envio de e-mail abortada", "Envio" )
		Endif
	ElseIf MV_PAR10 == 1 .or. ( MV_PAR10 <> 1 .and. MV_PAR13 <> 1 )
		IF MV_PAR10 == 1
			cMsg := "Gerando PDFs..."
		Else
			cMsg := "Gerando emails..."
		Endif
		MsgRun( cMsg, "Aguarde...", { || ProcGera( cAlias, nReg, nOpc, cPerg, cUserMail, cEmailSent, cSenhaMail ) } )
	Endif
	
Endif

Return Nil




Static Function ProcGera(cAlias, nReg, nOpc, cPerg, cUserMail, cEmailSent, cSenhaMail )
Local cBanco
Local cAgencia
Local cConta
Local cLText1
Local cLText2
Local cLText3
Local lBaixados
Local cAnoRef
Local cMesRef
Local cTitIni
Local cTitFim
Local cEtiqueta
Local cEmailUni
Local cCliIni
Local cLojaIni
Local cCliFim
Local cLojafim
Local lAglutina
Local lVeraCros
Local cEmailIni
Local cEmailFim
Local aFilesDel		:= {}
Local cLocalSpool		:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )
Local cMsg				:= ""

Default cPerg			:= 'GRD010'

mBrchgLoop(.F.)
Pergunte( cPerg, .F. )
If Right( cLocalSpool, 1 ) <> "\"
	cLocalSpool += "\"
Endif

AtuMailE1( MV_PAR11 )

If MV_PAR13 == 1   // Envia e-mail automatico
	aFilesDel := Directory(cLocalSpool+"*.*", "D")
	For i := 1 to len(aFilesDel)
		if len(aFilesDel[i][1]) > 3
			Ferase(cLocalSpool + aFilesDel[i][1])
		endif
	Next i
End If

cBanco		:= MV_PAR01
cAgencia		:= MV_PAR02
cConta		:= MV_PAR03
cLText1		:= MV_PAR18
cLText2		:= MV_PAR19
cLText3		:= MV_PAR20
lBaixados	:= MV_PAR17 == 1
cAnoRef		:= Right( MV_PAR11, 4 )
cMesRef		:= Left( MV_PAR11, 2 )
cTitIni		:= MV_PAR04
cTitFim		:= MV_PAR05
cEtiqueta	:= "  "
cEmailUni	:= MV_PAR14
cCliIni		:= MV_PAR06		//MV_PAR06
cLojaIni		:= MV_PAR08		//MV_PAR07
cCliFim		:= MV_PAR07		//MV_PAR08
cLojafim		:= MV_PAR09		//MV_PAR09
lAglutina	:= MV_PAR10 == 2
lVeracros	:= MV_PAR10 == 1
cEmailIni	:= Alltrim( MV_PAR15 )
cEmailFim	:= Alltrim( MV_PAR16 )
lAutomatico := MV_PAR13 == 1

If lVeracros
	cMsg := "Foi selecionada a op o VERACROSS igual a 'SIM'." + CRLF
	cMsg += "Nesse caso os arquivos PDF ser? criados, porem" + CRLF
	cMsg += "nenhum email ser?enviado." + CRLF
	ApMsgInfo( cMsg, "Aviso VERACROSS" )
Endif

If !lVeracros .and. lAutomatico
	If ApMsgYesNo( "Foi selecionado o envio automatico dos emails ap? a gera o, confirma?", "Envio Automatico" )
		GeraBol( cBanco, cAgencia, cConta, cLText1, cLText2, cLText3, lBaixados, cAnoRef, cMesRef, cTitIni, ;
		cTitFim, cEtiqueta, cEmailUni, cCliIni, cLojaIni, cCliFim, cLojafim, lAglutina, cEmailIni, ;
		cEmailFim, lAutomatico, lVeraCros, cUserMail, cEmailSent, cSenhaMail )
	Endif
ElseIf lVeracros .or. !lAutomatico
	GeraBol( cBanco, cAgencia, cConta, cLText1, cLText2, cLText3, lBaixados, cAnoRef, cMesRef, cTitIni, ;
	cTitFim, cEtiqueta, cEmailUni, cCliIni, cLojaIni, cCliFim, cLojafim, lAglutina, cEmailIni, ;
	cEmailFim, lAutomatico, lVeraCros, cUserMail, cEmailSent, cSenhaMail )
Endif

MsgRun( "Limpeza da base de dados", "Aguarde...", { || LimpaBas( {.F., .F., .T., .F., .F.} ) } )

Return Nil



Static Function AjustaPerg( cPerg )
Local aHelpSpa	:= {}
Local aHelpPor	:= {}
Local aHelpEng	:= {}
Local aArea	  	:= GetArea()
Local cKey	  	:= ""

Aadd(aHelpPor,'Codigo do Banco')
PutSx1( cPerg, "01","Banco            ? ","","","mv_ch1","C",003,0,0,"G","","SA6","","","mv_par01","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Agencia')
PutSx1( cPerg, "02","Agencia          ? ","","","mv_ch2","C",005,0,0,"G","","","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Conta corrente')
PutSx1( cPerg, "03","Conta            ? ","","","mv_ch3","C",012,0,0,"G","","","","","mv_par03","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Titulo Inicial')
PutSx1( cPerg, "04","Do Titulo        ? ","","","mv_ch4","C",009,0,0,"G","","SE1","","","mv_par04","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Titulo Final')
PutSx1( cPerg, "05","At?Titulo       ? ","","","mv_ch5","C",009,0,0,"G","","SE1","","","mv_par05","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Aluno inicial')
PutSx1( cPerg, "06","Do Aluno         ? ","","","mv_ch6","C",006,0,0,"G","","SA1","","","mv_par06","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Aluno Final')
PutSx1( cPerg, "07","At?aluno        ? ","","","mv_ch7","C",006,0,0,"G","","SA1","","","mv_par07","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Loja inicial')
PutSx1( cPerg, "08","Loja De          ? ","","","mv_ch8","C",002,0,0,"G","","","","","mv_par08","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Loja final')
PutSx1( cPerg, "09","Loja Ate         ? ","","","mv_ch9","C",002,0,0,"G","","","","","mv_par09","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'PDF VeraCross')
PutSx1( cPerg, "10","PDF Veracross    ? ","","","mv_cha","N",001,0,0,"C","","","","","MV_PAR10","Sim","Sim","Sim","","N?","N?","N?","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Mes e ano no formato MMAAAA')
PutSx1( cPerg, "11","Mes e Ano        ? ","","","mv_chb","C",006,0,0,"G","","","","","MV_PAR11","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Seleciona aluno')
PutSx1( cPerg, "12","Seleciona Aluno  ? ","","","mv_chc","N",001,0,0,"C","","","","","MV_PAR12","Sim","Sim","Sim","","N?","N?","N?","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Envia Automaticamente')
PutSx1( cPerg, "13","envia automatico ? ","","","mv_chd","N",001,0,0,"C","","","","","MV_PAR13","Sim","Sim","Sim","","N?","N?","N?","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Filtra e-mail')
PutSx1( cPerg, "14","Filtra e-mail    ? ","","","mv_che","C",090,0,0,"G","","","","","MV_PAR14","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'e-mail inicial')
PutSx1( cPerg, "15","Do e-mail        ? ","","","mv_chf","C",090,0,0,"G","","","","","MV_PAR15","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'e-mail final')
PutSx1( cPerg, "16","At?e-mail       ? ","","","mv_chg","C",090,0,0,"G","","","","","MV_PAR16","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Gerar Boletos para titulos ja baixados')
PutSx1( cPerg, "17","Emite j?baixados? ","","","mv_chh","N",001,0,0,"C","","","","","MV_PAR17","Sim","Sim","Sim","","N?","N?","N?","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Linha 1 de texto para boleto')
PutSx1( cPerg, "18","Linha 1          ? ","","","mv_chi","C",045,0,0,"G","","","","","MV_PAR18","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Linha 2 de texto para boleto')
PutSx1( cPerg, "19","Linha 2          ? ","","","mv_chj","C",045,0,0,"G","","","","","MV_PAR19","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Linha 3 de texto para boleto')
PutSx1( cPerg, "20","Linha 3          ? ","","","mv_chk","C",045,0,0,"G","","","","","MV_PAR20","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )


RestArea(aArea)

Return Nil



Static Function makescr(cAliasNew, dDataIni, dDataFim)
Local oDlg
Local cCadastro		:= "Sele o de alunos"
Local aSize 			:= MsAdvSize()
Local aInfo 			:= {aSize[1],aSize[2],aSize[3],aSize[4],3,3}
Local oPanelUp
Local oPanelDown
Local oPanel1
Local oPanel2
Local aResult			:= {}
Local oListBox1
Local aListBox1		:= {}
Local nOpca 			:= 0
Local aAreaSav			:= GetArea()
Local oCheck
Local lCheck

Default dDataini		:= dDataBase - 5
Default dDataFim		:= dDataBase

DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],aSize[1] To aSize[6],aSize[5] OF oMainWnd PIXEL
oFWLayer := FWLayer():New()
oFWLayer:Init( oDlg, .F., .T. )
oFWLayer:AddLine( 'PRIMEIRO' , 14, .T. )                     // Cria uma "linha" com 25% da tela
oFWLayer:AddLine( 'SEGUNDO', 85, .F. )                       // Cria uma "linha" com 25% da tela
oPanelUp   		:= oFWLayer:GetlinePanel( 'PRIMEIRO'  )
oPanelDown 		:= oFWLayer:GetlinePanel( 'SEGUNDO' )

@ 000, 000 MSPANEL oPanel1 SIZE 000, 015 OF oPanelUp //COLORS 0, 16777215 RAISED
oPanel1:align:=CONTROL_ALIGN_ALLCLIENT

@ 000, 000 MSPANEL oPanel2 SIZE  000, 015 OF oPanelDown //COLORS 0, 16777215 RAISED
oPanel2:align:=CONTROL_ALIGN_ALLCLIENT

@ 005, 005 Say "Selecionando alunos para gera o de boletos "  	SIZE 210,08 	PIXEL OF oPanel1
@ 020, 005 CHECKBOX oCheck VAR lCheck PROMPT "Marca / Desmarca todos ?" SIZE 100,010 ON CLICK( Verchk(oListBox1,aListBox1,lCheck) , oCheck:Refresh() ) OF oPanel1 PIXEL

fListBox1( oPanel2, aResult, @oListBox1, aListBox1, cAliasNew )

ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{||nOpcA:=1,oDlg:End()},{||oDlg:End()})

If nOpca == 1
	aResult := aClone( aListBox1 )
Endif

aListBox1 := {}

RestArea( aAreaSav )
mBrchgLoop(.F.)

Return aResult



Static Function fListBox1( oScreen, aResult, oListBox1, aListBox1, cAliasNew )
Local aHead			:= {}

// carrega o array da listbox
aListBox1 := LoadLst1( @aHead, aResult, cAliasNew )

@ 016, 005 ListBox oListBox1 Fields ;
HEADER "" Size 381, 173 Of oScreen Pixel ColSizes 0

oListBox1:align:=CONTROL_ALIGN_ALLCLIENT

SetLst1(oListBox1, aListBox1, aHead) // atualiza o vetor da listbox

oListBox1:BlDblClick := { || aListBox1[oListBox1:nAt, 1] := !aListBox1[oListBox1:nAt, 1], oListBox1:Refresh() }

Return Nil



//carga da listbox1
Static Function LoadLst1( aHead, aResult, cAliasNew )
Local aRet 			:= {}
Local nXa			:= 0
Local nJ			:= 0
Local aTmp			:= {}
Local xTmp

dbSelectArea( cAliasNew )
(cAliasNew)->( dbGotop() )

While (cAliasNew)->( !eof() )
	SA1->( DbSetOrder(1) )
	SA1->( DbSeek( xFilial("SA1") + (cAliasNew)->(E1_CLIENTE + E1_LOJA ) ) )
	
	aTmp := {}
	aadd( aTmp, .F. )
	aadd( aTmp, (cAliasNew)->E1_CLIENTE )
	aadd( aTmp, (cAliasNew)->E1_LOJA )
	aadd( aTmp, SA1->A1_NOME )
	aadd( aTmp, (cAliasNew)->E1_PREFIXO )
	aadd( aTmp, (cAliasNew)->E1_NUM )
	aadd( aTmp, (cAliasNew)->E1_TIPO )
	aadd( aTmp, (cAliasNew)->E1_EMAIL2)
	aadd( aTmp, (cAliasNew)->E1_EMAIL3 )
	aadd( aTmp, (cAliasNew)->E1_EMAIL4 )
	
	aadd( aResult, aClone( aTmp ) )
	
	(cAliasNew)->( dbSkip() )
End

aHead := {}

aadd(ahead, {" ", 				"020", "L"})
aadd(ahead, {"Cod.Aluno", 		"055", "C"})
aadd(ahead, {"Loja", 			"045", "C"})
aadd(aHead, {"Nome Aluno", 		"080", "C"})

aadd(aHead, {"Pref.",			"045", "C"})
aadd(aHead, {"Numero", 			"070", "C"})
aadd(aHead, {"Tipo",			"045", "C"})

aadd(aHead, {"e-mail 2",		"080", "C"})
aadd(aHead, {"e-mail 3", 		"080", "C"})
aadd(aHead, {"e-mail 4",		"080", "C"})

For nXa := 1 to len( aResult )
	aTmp := {}
	For nJ := 1 to len( aResult[nXa] )
		Aadd( aTmp, aResult[nXa][nJ] )
	Next nJ
	aadd( aRet, aClone( aTmp ) )
	aTmp := {}
Next nXa

aResult := Nil

dbSelectArea( cAliasNew )
(cAliasNew)->( dbGotop() )

// verifica se o array de retorno esta vazio e providencia um retorno
If Len(aRet) < 1
	aTmp := {}
	For nXa := 1 to len(aHead)
		IF aHead[nXa][3] == "N"
			xTmp := 0.00
		Elseif aHead[nXa][3] == "D"
			xTmp := cTod(" ")
		Elseif aHead[nXa][3] == "L"
			xTmp := .F.
		Else
			xTmp := " "
		Endif
		aadd( aTmp, xTmp)
	next nXa
	aadd( aTmp, ' ')
	aadd(aRet, aTmp)
Endif

Return aRet



//Refresh da listbox 1
Static Function SetLst1(oLbx, aLbx, aHead)
Local aHead1		:= {}
Local aCols1		:= {}
Local nXa			:= 0
Local cPrefix 		:= '"'
Local cPrefix1 		:= ''
Local oOk	 		:= LoadBitmap(GetResources(),'LBOK')
Local oNo			:= LoadBitmap(GetResources(),'LBNO')
Local nSav			:= 0

Default aHead		:= {}

Private cVar		:= ""
Private cVar1		:= ""

If Len( aHead ) > 0
	//Monta o header da listbox e o tamanho das colunas
	cVar 		:= ""
	cVar1 	:= ""
	For nXa := 1 to len(aHead)
		cVar 		+= cPrefix + aHead[nXa][1]  + '"'
		cVar1 	+= cPrefix1 + aHead[nXa][2]
		cPrefix 	:= ',"'
		cPrefix1 := ','
		
		aadd(aHead1, aHead[nXa][1])
		aadd(aCols1, Val(aHead[nXa][2]))
	next nXa
	
	oLbx:aHeaders 	:= aHead1
	oLbx:aColSizes := aCols1
	
Endif

oLbx:SetArray(aLbx)
oLbx:nAt := 1

// Cria ExecBlocks das ListBoxes
oLbx:bLine 		:= {|| {;
Iif( aLbx[oLbx:nAT,01], oOk, oNo ),;
aLbx[oLbx:nAT,02],;
aLbx[oLbx:nAT,03],;
aLbx[oLbx:nAT,04],;
aLbx[oLbx:nAT,05],;
aLbx[oLbx:nAT,06],;
aLbx[oLbx:nAT,07],;
aLbx[oLbx:nAT,08],;
aLbx[oLbx:nAT,09] }}


oLbx:refresh()

Return Nil



/*============================================================================================================================================================
Função     : AtuMailE1
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade : Busca o e-mail do cadastro do cliente e atualiza no contas a receber.
============================================================================================================================================================*/
Static Function AtuMailE1( cMesAno )
Local cQuery 		:= ""
Local cAliasQry		:= getNextAlias()
Local aAreaSav		:= GetArea()
Local cMesEmi		:= ""
Local cAnoEmi		:= ""

Default cMesAno		:= StrZero(Month(dDataBase), 2) + StrZero(Year(dDataBase), 4)
cMesEmi := left( cMesAno, 2 )
cAnoEmi	:= Right( cMesAno,4 )



//Atenção os e-mails parecem estar errados porem foi mantido
//esta forma devido aos indices customizados no SE1.       
//o cadastro de alunos o EMAIL 2 que aparece no cadastro,  
//a verdade ?o campo A1_EMAIL1 por isso esta sendo        


cQuery := "SELECT E1_EMISSAO, E1_CLIENTE, E1_LOJA, E1_EMAIL2, E1_EMAIL3, E1_EMAIL4, R_E_C_N_O_ AS SE1RECNO "
cQuery += "  FROM "+	RetSqlName("SE1")
cQuery += " WHERE substring(E1_PREFIXO,1,1) = 'F' "
cQuery += " AND E1_FILIAL = '" + xFilial("SE1") + "' "
cQuery += " AND E1_CLIENTE >= '"+  MV_PAR06 + "' AND E1_CLIENTE <= '" + MV_PAR07 + "' "
cQuery += " AND E1_LOJA >= '" + MV_PAR08 + "' AND E1_LOJA <= '" + MV_PAR09 + "' "
If MV_PAR17 <> 1 // nao
	cQuery += " AND E1_SALDO > 0 "
Endif
cQuery += " AND E1_EMISSAO LIKE '" + cAnoEmi + cMesEmi + "%' "
cQuery += " AND (E1_PREFIXO + E1_NUM >= '" + MV_PAR04 + "' AND E1_PREFIXO + E1_NUM <= '" +MV_PAR05 + "' ) "
cQuery += " AND D_E_L_E_T_ = ' ' "

If Select( cAliasQry ) > 0
	(cAliasQry)->(dbCloseArea())
Endif

cQuery := ChangeQuery(cQuery)

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasQry, .F., .T.)
tcSetField(cAliasQry, "SE1RECNO", "N", 10, 00 )

DbSelectArea(cAliasQry)
(cAliasQry)->( DBGoTop() )

While (cAliasQry)->(!EOF())
	
	If !Empty(cMesAno)
		If substr((cAliasQry)->E1_EMISSAO,5,2) <> cMesEmi .Or. substr((cAliasQry)->E1_EMISSAO,1,4) <> cAnoEmi
			(cAliasQry)->( DbSkip() )
			Loop
		End If
	Else
		Exit
	End If
	
	SA1->( DbSetOrder(1) )
	SA1->( DbSeek( xFilial("SA1") + (cAliasQry)->( E1_CLIENTE + E1_LOJA ) ) )
	
	If Alltrim( (cAliasQry)->E1_EMAIL2 ) <> alltrim( SA1->A1_EMAIL1 )
		SE1->( DbGoTo( (cAliasQry)->SE1RECNO ) )
		Reclock("SE1",.F.)
		SE1->E1_EMAIL2 := SA1->A1_EMAIL1
		SE1->(MsUnlock())
	End If
	
	If Alltrim( (cAliasQry)->E1_EMAIL3 ) <> Alltrim( SA1->A1_EMAIL2 )
		SE1->( DbGoTo( (cAliasQry)->SE1RECNO ) )
		Reclock("SE1",.F.)
		SE1->E1_EMAIL3 := SA1->A1_EMAIL2
		SE1->( MsUnlock() )
	End If
	
	If Alltrim( (cAliasQry)->E1_EMAIL4 ) <> alltrim( SA1->A1_EMAIL3 )
		SE1->( DbGoTo( (cAliasQry)->SE1RECNO ) )
		Reclock("SE1",.F.)
		SE1->E1_EMAIL4 := SA1->A1_EMAIL3
		SE1->(MsUnlock())
	End If
	
	(cAliasQry)->(DbSkip())
End

If Select( cAliasQry ) > 0
	(cAliasQry)->(dbCloseArea())
Endif

RestArea( aAreasav )

Return Nil




Static  Function GeraBol( cBanco, cAgencia, cConta, cLText1, cLText2, cLText3, lBaixados, cAnoRef, cMesRef, cTitIni, ;
cTitFim, cEtiqueta, cEmailUni, cCliIni, cLojaIni, cCliFim, cLojafim, lAglutina, cEmailIni, cEmailFim, lAutomatico, ;
lVeraCros, cUserMail, cEmailSent, cSenhaMail )

Local n 					:= 0
Local aBitmap			:= {		"" ,; 								//Banner publicit?io
"\Bitmaps\Logo_Siga.bmp"      }  	//Logo da empresa
Local cAnoMes	   	:= ""
Local aDadosEmp		:= {	SM0->M0_NOMECOM                                    								,; 		//Nome da Empresa
SM0->M0_ENDCOB                                                            	,; 		//Endere?
AllTrim(SM0->M0_BAIRCOB)+", "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB 	,; 		//Complemento
"CEP: "+Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)             	,; 		//CEP
"PABX/FAX: "+SM0->M0_TEL                                                  	,; 		//Telefones
"C.G.C.: "+Subs(SM0->M0_CGC,1,2)+"."+Subs(SM0->M0_CGC,3,3)+"."+             ;
Subs(SM0->M0_CGC,6,3)+"/"+Subs(SM0->M0_CGC,9,4)+"-"+Subs(SM0->M0_CGC,13,2) ,; 		//CGC                                                   ,; //CGC
"I.E.: "+Subs(SM0->M0_INSC,1,3)+"."+Subs(SM0->M0_INSC,4,3)+"."+          	 ;
Subs(SM0->M0_INSC,7,3)+"."+Subs(SM0->M0_INSC,10,3)                        	 }  		//I.E
Local aDadosTit		:= {}
Local cQuery 			:= ""
Local aDadosBanco 	:= {}
Local aDatSacado		:= {}
Local aBolText     	:= {}
Local _nVlrDesc 		:= 0
Local _nVlrJuro 		:= 0
Local aBMP      		:= aBitMap
Local i         		:= 1
Local CB_RN_NN  		:= {}
Local nRec      		:= 0
Local _nVlrAbat 		:= 0
Local dDtIni 			:= dDatabase-60
Local dDtFim 			:= dDatabase
Local lPrev 			:= .T.
Local cZgDoc 			:= ""
Local lFound 			:= .F.
Local cMail				:= ""
Local cSacNom 			:= ""
Local cRefere			:= ""
Local cAliasQry		:= GetNextAlias()
Local cName				:= ""
Local cNomFile1		:= ""
Local cNomFile2		:= ""
Local aRegGer			:= {}
Local nX					:= 0
Local nRegSav			:= 0
Local cBusca			:= ""
Local LPREVIEW			:= .F.
Local cLocalSpool		:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )
Local aSelect			:= {}
Local cReferAnt		:= ""
Local cEnviado			:= "1"
Local cEmailFix		:= Alltrim(GetMv("MV_SZPREC1"))

Default cBanco			:= ""
Default cAgencia		:= ""
Default cConta			:= ""
Default cLText1		:= ""
Default cLText2		:= ""
Default cLText3		:= ""
Default lBaixados		:= .F.
Default cAnoRef		:= ""
Default	cMesRef		:= ""
Default cTitIni		:= ""
Default cTitFim		:= ""
Default cEmailUni		:= ""
Default cCliIni		:= ""
Default cLojaIni		:= ""
Default cCliFim		:= ""
Default cLojaFim		:= ""
Default lAutomatico	:= .F.
Default lVeraCros		:= .F.

Private cDoc
Private aTam1 			:= {}
Private oPrint
Private lMudaNome 	:= .F.
Private aArrayMails 	:= {}
Private aMens 			:= {}

Private aNossoNum		:= {}
Private cNossoNum 	:= ''
Private cnNumero  	:= ''

Private cCCedente		:= "6524915"
Private cCarteira		:= '101'

Private cSacNom := ""
Private cSacEnd := ""
Private cSacCep := ""
Private cSacMun := ""
Private cSacEst := ""
Private cDesNom := ""
Private cDesEnd := ""
Private cDesCep := ""
Private cDesMun := ""
Private cDesEst := ""
Private cDesCon := ""
Private cSacCGC := ""

If Right( cLocalSpool, 1 ) <> "\"
	cLocalSpool += "\"
Endif

cAnoRef 				:= Padl( cAnoRef, 4, '0' )
cMesRef				:= padl( cMesRef, 2, "0" )
aBolText     		:= { cLText1, cLText2, cLText3 }
cRefere 				:= cAnoRef+cMesRef
cAnoMes				:= cAnoRef + cMesRef

dbSelectArea( "SZD" )
SZD->(DbSetOrder(1))

SZD->(DbSeek(xFIlial("SZD")+"000001"))
nValor1 := SZD->ZD_VALOR

SZD->(DbSeek(xFIlial("SZD")+"000004"))
nValor2 := SZD->ZD_VALOR

SZD->(DbSeek(xFIlial("SZD")+"000006"))
nValor3 := SZD->ZD_VALOR

SZD->(DbSeek(xFIlial("SZD")+"000013"))
nValor4 := SZD->ZD_VALOR

SZD->(DbSeek(xFIlial("SZD")+"000014"))
nValor5 := SZD->ZD_VALOR

SZD->(DbSeek(xFIlial("SZD")+"000017"))
nValor6 := SZD->ZD_VALOR

aMens := {	{ "Preprimary half day program (K2AM / K2PM /K3PM)",	nValor1}	,;
{ "Preprimary half day program (K3AM / K4AM )",			nValor2}	,;
{ "Preprimary full day program ",							nValor3}	,;
{ "Elementary School",											nValor4}	,;
{ "Middle School",												nValor5}	,;
{ "High School",													nValor6}	,;
{ "Transportation",												"Vari?el"	}}

cEnviado := "1"
If lVeraCros
	cEnviado := "2"
Endif

oPrint:= TMSPrinter():New( "Boleto Laser" )  //INSTANCIA O OBJETO

oPrint:Setup()
oPrint:SetPortrait() // ou SetLandscape()
oPrint:StartPage()   // Inicia uma nova p?ina



DbSelectArea("SA6")        //Posiciona o SA6 (Bancos)
DbSetOrder(1)
DbSeek(xFilial("SA6")+cBanco+cAgencia+cConta)

//Posiciona o SEE (Parametros banco)
DbSelectArea("SEE")
DbSetOrder(1)
DbSeek(xFilial("SEE")+cBanco+cAgencia+cConta)

cQuery := "SELECT E1_PREFIXO, E1_NUM, E1_TIPO, E1_PARCELA, E1_CLIENTE, E1_LOJA, E1_EMAIL2, E1_EMAIL3, E1_EMAIL4 "
cQuery += "FROM "+	RetSqlName("SE1") + " "
cQuery += "WHERE E1_FILIAL = '" + xFilial("SE1") + "' "
cQuery += " AND substring(E1_PREFIXO,1,1) = 'F' "
cQuery += " AND E1_CLIENTE >= '"+  cCliIni + "' AND E1_CLIENTE <= '" + cCliFim + "' "
cQuery += " AND E1_LOJA >= '" + cLojaIni + "' AND E1_LOJA <= '" + cLojaFim + "' "
If !lBaixados // nao
	cQuery += " AND E1_SALDO > 0 "
Endif
cQuery += " AND E1_EMISSAO LIKE '" + cRefere + "%' "
cQuery += " AND (E1_PREFIXO + E1_NUM >= '" + cTitIni + "' AND E1_PREFIXO + E1_NUM <= '" + cTitFim + "' ) "
cQuery += " AND D_E_L_E_T_ = ' ' "
cQuery += "ORDER BY E1_EMAIL2, E1_EMAIL3, E1_EMAIL4 "

If Select( cAliasQry ) > 0
	dbSelectArea( cAliasQry )
	( cAliasQry )->( dbCloseArea() )
Endif

cQuery := ChangeQuery(cQuery)
dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasQry, .F., .T.)

DbSelectArea( cAliasQry )
( cAliasQry )->( DBGoTop() )

aRegGer	:= {}


If ( cAliasQry )->( Eof() )
	ApMsgAlert( "Nada foi Selecionado!", "Busca Titulos" )
	If Select( cAliasQry ) > 0
		dbSelectArea( cAliasQry )
		( cAliasQry )->( dbCloseArea() )
	Endif
	Return Nil
Endif

If Len( aArrayMails ) == 0
	
	If MV_PAR12 == 1
		SaveInter()
		aSelect := makescr(cAliasQry, dDtIni, dDtFim )
		RestInter()
	Else
		aSelect := {}
	End If
	
	While ( cAliasQry )->(!EOF())
		
		If ((cAliasQry)->(E1_PREFIXO+Alltrim(E1_NUM))) < cTitIni .Or. ((cAliasQry)->(E1_PREFIXO+Alltrim(E1_NUM))) > cTitFim
			(cAliasQry)->( DbSkip() )
			Loop
		End If
		
		If !Empty( cEmailUni )
			If Empty(cAliasQry->E1_EMAIL2) .and. Empty( cAliasQry->E1_EMAIL3 ) .and. empty( cAliasQry->E1_EMAIL4 )
				cAliasQry->(DbSkip())
				Loop
			End If
		End If
		
		SA1->( DbSetOrder(1) )
		SA1->( DbSeek( xFilial("SA1") + (cAliasQry)->(E1_CLIENTE + E1_LOJA ) ) )
		
		SZC->( DbSetOrder(1) )
		SZC->( DbSeek( xFilial("SZC") + SA1->A1_CODFAM ) )
		
		If cEtiqueta <> " "
			If Alltrim( Upper( SZC->ZC_ETIQ ) ) <> alltrim( Upper( cEtiqueta ) )
				cAliasQry->( DbSkip() )
				Loop
			End If
		End If
		
		If !Empty(cEmailUni)
			If !( alltrim(cEmailUni) == alltrim((cAliasQry)->E1_EMAIL2) .Or. alltrim(cEmailUni) == alltrim((cAliasQry)->E1_EMAIL3) .or.  alltrim(cEmailUni) == alltrim((cAliasQry)->E1_EMAIL4) )
				cAliasQry->(DbSkip())
				Loop
			End If
		EndIf
		
		If MV_PAR12 == 1 .AND. LEN( aSelect ) > 0
			nPos := ascan( aSelect, { |x| x[2] == (cAliasQry)->E1_CLIENTE .and. x[3] ==(cAliasQry)->E1_LOJA  .and. x[5] == (cAliasQry)->E1_PREFIXO .and. x[6] == (cAliasQry)->E1_NUM } )
			If nPos > 0
				if !aSelect[nPos][1]
					(cAliasQry)->( DbSkip() )
					Loop
				Endif
			Endif
		End If
		
		cZgDoc := (cAliasQry)->( E1_PREFIXO + Alltrim(E1_NUM) )  + " RM"
		lFound := .F.
		SZG->( DbSetOrder(2) )
		SZG->( DBSeek( xFilial("SZG") + cZgDoc + ( cAliasQry )->E1_CLIENTE ) )
		while SZG->(!EOF()) .And. SZG->ZG_CODALU == (cAliasQry)->E1_CLIENTE .And. SZG->ZG_DOC == cZgDoc .And. SZG->ZG_MESANO == cMesRef + cAnoRef
			lFound := .T.
			Exit
			SZG->( DbSkip() )
		End
		
		If !lFound
			( cAliasQry )->( DbSkip() )
			Loop
		End If
		
		lFound := .F.
		
		If lAglutina
			
			cCliente		:= Alltrim( ( cAliasQry )->E1_CLIENTE )
			cEmail		:= ( cAliasQry )->E1_EMAIL2
			IF !Empty( cEmail )
				nPos := ascan( aArrayMails, { |x|  Alltrim( x[1] ) == cEmail .and. Alltrim( x[4] ) == cCliente  } )
				If nPos == 0
					AADD( aArrayMails,{ cEmail, ( cAliasQry )->E1_PREFIXO, ( cAliasQry )->E1_NUM, cCliente, ( cAliasQry )->E1_LOJA, ( cAliasQry )->E1_TIPO, ( cAliasQry )->E1_PARCELA, "1", cEnviado, "1" } )
				Endif
			Endif
			
			cCliente		:= Alltrim( ( cAliasQry )->E1_CLIENTE )
			cEmail		:= ( cAliasQry )->E1_EMAIL3
			IF !Empty( cEmail )
				nPos := ascan( aArrayMails, { |x|  Alltrim( x[1] ) == cEmail .and. Alltrim( x[4] ) == cCliente  } )
				If nPos == 0
					AADD( aArrayMails,{ cEmail, ( cAliasQry )->E1_PREFIXO, ( cAliasQry )->E1_NUM, cCliente, ( cAliasQry )->E1_LOJA, ( cAliasQry )->E1_TIPO, ( cAliasQry )->E1_PARCELA, "1", cEnviado, "2" } )
				Endif
			Endif
			
			cCliente		:= Alltrim( ( cAliasQry )->E1_CLIENTE )
			cEmail		:= ( cAliasQry )->E1_EMAIL4
			IF !Empty( cEmail )
				nPos := ascan( aArrayMails, { |x|  Alltrim( x[1] ) == cEmail .and. Alltrim( x[4] ) == cCliente  } )
				If nPos == 0
					AADD( aArrayMails,{ cEmail, ( cAliasQry )->E1_PREFIXO, ( cAliasQry )->E1_NUM, cCliente, ( cAliasQry )->E1_LOJA, ( cAliasQry )->E1_TIPO, ( cAliasQry )->E1_PARCELA, "1", cEnviado, "3" } )
				Endif
			Endif
			
		Else
			
			cCliente		:= Alltrim( ( cAliasQry )->E1_CLIENTE )
			cEmail		:= ( cAliasQry )->E1_EMAIL2
			IF !Empty( cEmail )
				nPos := ascan( aArrayMails, { |x|  Alltrim( x[4] ) == cCliente  } )
				If nPos == 0
					AADD( aArrayMails,{ cEmail, ( cAliasQry )->E1_PREFIXO, ( cAliasQry )->E1_NUM, cCliente, ( cAliasQry )->E1_LOJA, ( cAliasQry )->E1_TIPO, ( cAliasQry )->E1_PARCELA, "1", cEnviado, "1" } )
				Endif
			Endif
			
			cCliente		:= Alltrim( ( cAliasQry )->E1_CLIENTE )
			cEmail		:= ( cAliasQry )->E1_EMAIL3
			IF !Empty( cEmail )
				nPos := ascan( aArrayMails, { |x|  Alltrim( x[4] ) == cCliente  } )
				If nPos == 0
					AADD( aArrayMails,{ cEmail, ( cAliasQry )->E1_PREFIXO, ( cAliasQry )->E1_NUM, cCliente, ( cAliasQry )->E1_LOJA, ( cAliasQry )->E1_TIPO, ( cAliasQry )->E1_PARCELA, "1", cEnviado, "2" } )
				Endif
			Endif
			
			cCliente		:= Alltrim( ( cAliasQry )->E1_CLIENTE )
			cEmail		:= ( cAliasQry )->E1_EMAIL4
			IF !Empty( cEmail )
				nPos := ascan( aArrayMails, { |x|  Alltrim( x[4] ) == cCliente } )
				If nPos == 0
					AADD( aArrayMails,{ cEmail, ( cAliasQry )->E1_PREFIXO, ( cAliasQry )->E1_NUM, cCliente, ( cAliasQry )->E1_LOJA, ( cAliasQry )->E1_TIPO, ( cAliasQry )->E1_PARCELA, "1", cEnviado, "3" } )
				Endif
			Endif
			
		Endif
		
		( cAliasQry )->( DbSkip() )
	End
	
End If

If Select( cAliasQry ) > 0
	dbSelectArea( cAliasQry )
	( cAliasQry )->( dbCloseArea() )
Endif

//Organiza os emails para envio e gera o
aSort(aArrayMails,,,{|x,y| y[1] > x[1]})

IF len(aArrayMails) > 0
	dbSelectArea( "ZTB" )
	dbSetOrder( 2 )
	For i := 1 to Len(aArrayMails)
		cBusca := padr(cMesRef + cAnoRef, TAMSX3("ZTB_REFERE")[1]) + padr(aArrayMails[i][1], TamSX3("ZTB_EMAIL")[1]) + padr(aArrayMails[i][4], TamSX3("ZTB_COD_AL")[1]) + padr(aArrayMails[i][5], TamSX3("ZTB_LOJALU")[1])
		If ZTB->( !dbSeek( xFilial("ZTB") + cBusca ) )
			
			Reclock("ZTB",.T.)
			
			ZTB->ZTB_FILIAL		:= xFilial( "ZTB" )
			ZTB->ZTB_STATUS		:= aArrayMails[i][8]
			ZTB->ZTB_STATU1		:= aArrayMails[i][9]
			ZTB->ZTB_PREFIX 		:= aArrayMails[i][2]
			ZTB->ZTB_NUM 			:= aArrayMails[i][3]
			ZTB->ZTB_COD_AL		:= aArrayMails[i][4]
			ZTB->ZTB_LOJALU 		:= aArrayMails[i][5]
			ZTB->ZTB_EMAIL 		:= aArrayMails[i][1]
			ZTB->ZTB_TIPO 			:= aArrayMails[i][10]
			ZTB->ZTB_TIPTIT		:= aArrayMails[i][6]
			ZTB->ZTB_PARCEL		:= aArrayMails[i][7]
			ZTB->ZTB_CODRES     	:= " "//aArrayMails[i][11]
			ZTB->ZTB_IDUNIQ     	:= GetSx8Num( "ZTB", "ZTB_IDUNIQ" )
			ZTB->ZTB_ARQUI	    	:= " "
			ZTB->ZTB_DTGER      	:= cTod( " " )
			ZTB->ZTB_DTENVI     	:= Iif( cEnviado=="1", ctod( " " ), dDataBase )
			ZTB->ZTB_REFERE		:= cMesRef + cAnoRef
			
			ZTB->( MsUnlock() )
			ConfirmSX8()
			
		Endif
	Next i
	
	DbSelectArea("ZTB")
	ZTB->( dbSetOrder( 2 ) )
	ZTB->( dbSeek( xFilial( "ZTB" ) + cMesRef + cAnoRef ) )
	ZTB->( DbGoTop() )
	
	While ZTB->(!EOF()) .and. ( ZTB->ZTB_FILIAL == xFilial( "ZTB" ) .and. ZTB->ZTB_REFERE == cMesRef + cAnoRef )
		
		IF ZTB->ZTB_STATUS <> "1"
			ZTB->( dbSkip() )
			Loop
		Endif
		
		DbSelectArea("SE1")
		If ZTB->ZTB_TIPO == "1"
			//DbSetOrder(21)
			SE1->(DBOrderNickName("SE1ALEM2"))
			cMail := "1"
		ElseIf ZTB->ZTB_TIPO == "2"
			//DbSetOrder(22)
			SE1->(DBOrderNickName("SE1ALEM3"))
			cMail := "2"
		Else
			//DbSetOrder(23)
			SE1->(DBOrderNickName("SE1ALEM4"))
			cMail := "3"
		End If
		
		DbSeek( xFilial("SE1") + ZTB->ZTB_COD_AL + ZTB->ZTB_LOJALU + ZTB->ZTB_PREFIX + ZTB->ZTB_NUM + ZTB->ZTB_EMAIL )
		
		cDoc 		:= Substr(SE1->E1_PREFIXO,2,2)+alltrim(SE1->E1_NUM)
		cnNumero := SE1->E1_NUMBCO   // Nosso numero que foi calculo quando foi gerado o CNAB
		
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek( xFilial("SA1")+ SE1->E1_CLIENTE + SE1->E1_LOJA )
		
		SZC->( DbSeek( xFilial("SZC") + SA1->A1_CODFAM ) )
		
		SZB->( DbSeek( xFilial("SZB") + SZC->ZC_CODEMP ) )
		
		//Define o Sacado e Destinatario
		If Empty( SZC->ZC_ETIQ )
			ApMsgStop("O Cadastro da fam?ia "+SA1->A1_CODFAM+" est?sem o n?ero da etiqueta. Esta gera o de boleto dar?erro.", "Aviso")
		EndIf
		
		If SZC->ZC_ETIQ == "1"
			cSacNom := SZC->ZC_NOME
			cSacEnd := SZC->ZC_ENDFAM
			cSacCep := Transform(SZC->ZC_CEP,"@r 99999-999")
			cSacMun := SZC->ZC_CIDADE
			cSacEst := SZC->ZC_ESTADO
			cDesNom := SZB->ZB_NOME
			cDesEnd := SZB->ZB_ENDEMP
			cDesCep := Transform(SZB->ZB_CEP,"@R 99999-999")
			cDesMun := SZB->ZB_CIDADE
			cDesEst := SZB->ZB_ESTADO
			cDesCon := SZB->ZB_CONTATO
			cSacCGC := SZC->ZC_CGC
		ElseIf SZC->ZC_ETIQ == "2"
			If len(alltrim(SZC->ZC_ENDFAM)) < 5 .Or. SZC->ZC_CEP == "00000000" .Or. Empty(SZC->ZC_CEP)
				cSacEnd := SZB->ZB_ENDEMP
				cSacCep := Transform(SZB->ZB_CEP,"@r 99999-999")
				cSacMun := Substr(SZB->ZB_CIDADE,1,15)
				cSacEst := SZB->ZB_ESTADO
			Else
				cSacEnd := SZC->ZC_ENDFAM
				cSacCep := Transform(SZC->ZC_CEP,"@r 99999-999")
				cSacMun := Substr(SZC->ZC_CIDADE,1,15)
				cSacEst := SZC->ZC_ESTADO
			End If
			cSacNom := SZC->ZC_NOME
			cDesNom := SZB->ZB_NOME
			cDesEnd := SZB->ZB_ENDEMP
			cDesCep := Transform(SZB->ZB_CEP,"@R 99999-999")
			cDesMun := Substr(SZB->ZB_CIDADE,1,15)
			cDesEst := SZB->ZB_ESTADO
			cDesCon := SZB->ZB_CONTATO+Space(5)
			cSacCGC := SZC->ZC_CGC
			
		ElseIf SZC->ZC_ETIQ == "3"
			
			If len(alltrim(SZC->ZC_ENDFAM)) < 5 .Or. SZC->ZC_CEP == "00000000" .Or. Empty(SZC->ZC_CEP)
				cSacEnd := SZB->ZB_ENDEMP
				cSacCep := Transform(SZB->ZB_CEP,"@r 99999-999")
				cSacMun := Substr(SZB->ZB_CIDADE,1,15)
				cSacEst := SZB->ZB_ESTADO
			Else
				cSacEnd := SZC->ZC_ENDFAM
				cSacCep := Transform(SZC->ZC_CEP,"@r 99999-999")
				cSacMun := Substr(SZC->ZC_CIDADE,1,15)
				cSacEst := SZC->ZC_ESTADO
			End If
			cSacNom := SZC->ZC_NOME
			cDesNom := SZB->ZB_NOME
			cDesEnd := SZB->ZB_ENDEMP
			cDesCep := Transform(SZB->ZB_CEP,"@R 99999-999")
			cDesMun := Substr(SZB->ZB_CIDADE,1,15)
			cDesEst := SZB->ZB_ESTADO
			cDesCon := SZC->ZC_NOME
			cSacCGC := SZC->ZC_CGC
			
		ElseIf SZC->ZC_ETIQ == "4"
			cSacNom := SZC->ZC_NOME
			cSacEnd := SZC->ZC_ENDFAM
			cSacCep := Transform(SZC->ZC_CEP,"@r 99999-999")
			cSacMun := Substr(SZC->ZC_CIDADE,1,15)
			cSacEst := SZC->ZC_ESTADO
			cDesNom := SPACE(40)
			cDesEnd := SZC->ZC_ENDFAM
			cDesCep := Transform(SZC->ZC_CEP,"@R 99999-999")
			cDesMun := Substr(SZC->ZC_CIDADE,1,15)
			cDesEst := SZC->ZC_ESTADO
			cDesCon := SZC->ZC_NOME
			cSacCGC := SZC->ZC_CGC
			
		ElseIf SZC->ZC_ETIQ == "5"
			cSacNom := SZC->ZC_NOME
			cSacEnd := SZC->ZC_ENDFAM
			cSacCep := Transform(SZC->ZC_CEP,"@r 99999-999")
			cSacMun := SZC->ZC_CIDADE
			cSacEst := SZC->ZC_ESTADO
			
			cDesNom := SZB->ZB_CONTATO
			cDesEnd := SZB->ZB_ENDEMP
			cDesCep := Transform(SZB->ZB_CEP,"@R 99999-999")
			cDesMun := SZB->ZB_CIDADE
			cDesEst := SZB->ZB_ESTADO
			cDesCon := SPACE(40)
			cSacCGC := SZC->ZC_CGC
			
		ElseIf SZC->ZC_ETIQ == "6"
			cSacNom := SZC->ZC_NOME
			cSacEnd := SZC->ZC_ENDFAM
			cSacCep := Transform(SZC->ZC_CEP,"@r 99999-999")
			cSacMun := SZC->ZC_CIDADE
			cSacEst := SZC->ZC_ESTADO
			cDesNom := SZB->ZB_CONTATO
			cDesEnd := SZB->ZB_ENDEMP
			cDesCep := Transform(SZB->ZB_CEP,"@R 99999-999")
			cDesMun := SZB->ZB_CIDADE
			cDesEst := SZB->ZB_ESTADO
			cDesCon := SPACE(40)
			cSacCGC := SZC->ZC_CGC
		Else
			ApMsgAlert("Problema no c?igo da etiqueta do cadastro da fam?ia "+SZC->ZC_CODFAM+"-"+SZC->ZC_NOME,"Montarel - Boleto_Real")
		EndIf
		
		//Posiciona o SE1 (Contas a Receber)
		DbSelectArea("SE1")
		
		_lBcoCorrespondente := .f.
		aDadosBanco  := {	SA6->A6_COD                                     	 																,;	//1-Numero do Banco
		Iif(SA6->A6_COD=="389","MERCANTIL DO BRASIL",SA6->A6_NREDUZ )    	 											,;	//2-Nome do Banco
		Agencia(SA6->A6_COD, SA6->A6_AGENCIA)																					,; //3-Ag?cia
		Conta(SA6->A6_COD, SA6->A6_NUMCON)																						,; //4-Conta Corrente
		Iif(SA6->A6_COD $ "479/389","",SubStr(AllTrim(SA6->A6_NUMCON),Len(AllTrim(SA6->A6_NUMCON)),1))  	,;	//5-D?ito da conta corrente
		"00"  																															,; //6-Carteira
		" "  																																,;	//7-Variacao da Carteira
		""  																																}	//8-Reservado para o banco correspondente
		
		aDatSacado   := {	AllTrim(cSacNom)           		,;      	//1-Raz? Social
		AllTrim(SA1->A1_COD ) 				,;      	//2-C?igo
		AllTrim(cSacEnd)  					,;      	//3-Endere?
		AllTrim(cSacMUN)						,;      	//4-Cidade
		cSacEst									,;      	//5-Estado
		cSacCep									,;      	//6-CEP
		AllTrim(SA1->A1_CGC )				}       	//7-CGC/CPF
		
		nValor := SE1->E1_SALDO   // Valor do Saldo, pois alguns pais pagam adiantado e a Karina baixa por compensa o
		
		
		//VALOR DOS TITULOS TIPO "AB-"
		_nVlrAbat   :=  SomaAbat(SE1->E1_PREFIXO,alltrim(SE1->E1_NUM),SE1->E1_PARCELA,"R",1,,SE1->E1_CLIENTE,SE1->E1_LOJA)
		
		CB_RN_NN    := Ret_cBarra(	Subs(aDadosBanco[1],1,3)+"9"					,;
		Subs(aDadosBanco[3],1,4)						,;
		aDadosBanco[4]										,;
		aDadosBanco[5]										,;
		aDadosBanco[6]										,;
		AllTrim(E1_NUM)+AllTrim(E1_PARCELA)			,;
		nValor 												,;
		SE1->E1_VENCREA									,;
		SEE->EE_CODEMP										,;
		SEE->EE_FAXATU										,;
		Iif(SE1->E1_DECRESC > 0,.t.,.f.)				,;
		SE1->E1_PARCELA									,;
		aDadosBanco[3]										)
		
		aDadosTit    :=  {	SUBSTR(SE1->E1_PREFIXO,2,2)+Alltrim(SE1->E1_NUM)		,;	// 1-N?ero do t?ulo
		SE1->E1_EMISSAO													,;	// 2-Data da emiss? do t?ulo
		dDataBase															,;	// 3-Data da emiss? do boleto
		SE1->E1_VENCREA													,;	// 4-Data do vencimento
		SE1->E1_VALOR 														,;	// 5-Valor do t?ulo
		AllTrim(CB_RN_NN[3])												,;	// 6-Nosso n?ero (Ver f?mula para calculo)
		SE1->E1_DESCONT													,;	// 7-Valor do Desconto do titulo
		SE1->E1_VALJUR 													,;	// 8-Valor dos juros do titulo
		(SE1->E1_VALOR - SE1->E1_SALDO)								,;	// 9-Valor do Abatimento // Recebimento  antecipado  Tiago Filho conversado com a Karina
		SE1->E1_SALDO														}	// 10-Valor Cobrado
		
		aadd( aRegGer, { ZTB->(Recno()), "" } )
		
		Impress( aBMP, aDadosEmp, aDadosTit, aDadosBanco, aDatSacado, aBolText, CB_RN_NN, cMail, cAnoMes, cMesRef, cAnoRef )
		
		If (lower(alltrim(ZTB->ZTB_EMAIL)) <= lower(alltrim(cEmailIni)) .or. lower(alltrim(ZTB->ZTB_EMAIL)) > lower(alltrim(cEmailFim))) .And. !Empty(ZTB->ZTB_EMAIL)
			DbSelectArea("ZTB")
			Reclock("ZTB",.F.)
			ZTB->ZTB_STATUS := "3"
			ZTB->ZTB_DTGER	:= dDataBase
			ZTB->( MsUnlock() )
			
			ZTB->( DbSkip() )
			Loop
		End If
		
		nRecno := ZTB->( Recno() )
		lMudaNome := .F.
		
		If lAglutina
			
			cEmailAnt := ZTB->ZTB_EMAIL
			cAlunoAnt := ZTB->ZTB_COD_AL
			cReferAnt := Alltrim(ZTB->ZTB_REFERE)
			ZTB->( DbSkip() )
			
			If ( !Empty(ZTB->ZTB_EMAIL) .And. cEmailAnt <> ZTB->ZTB_EMAIL ) .Or. ZTB->( EOF() )
				
				If (cEmailAnt <> ZTB->ZTB_EMAIL)
					lMudaNome := .T.
					cNomFile1  := trname(cEmailAnt) + "_" + cReferAnt + ".pdf"
				End If
			Endif
			ZTB->( DbGoTo(nRecno) )
			
		Else
			
			lMudaNome := .T.
			cNomFile1  := ZTB->ZTB_COD_AL + "_" + substr(ZTB->ZTB_PREFIX,2,2) + alltrim(ZTB->ZTB_NUM) + ".pdf"
			
		Endif
		
		IF lMudaNome
			ZTB->( DbGoTo(nRecno) )
			
			oPrint:Print()
			
			CheckPdf( cLocalSpool )
			
			nStatus := -1
			nTent 	:= 0
			
			If File( cLocalSpool + cNomFile1 )
				
				while nStatus < 0 .and. nTent <= 5
					nStatus	:= Ferase( cLocalSpool + cNomFile1 )
					nTent ++
				End
				nStatus := -1
				
			End If
			
			nTent := 0
			nStatus := -1
			
			while nStatus < 0 .and. nTent <= 5
				
				nStatus := frename( cLocalSpool + "boleto.pdf" , cLocalSpool + cNomFile1 )
				cName := cNomFile1
				If nStatus == 0
					Exit
				Else
					Sleep( 500 )
				Endif
				nTent ++
				
			End
			
			If nStatus == 0
				For nX := 1 to len(aRegGer)
					aRegGer[nX][2] := cName
				Next nX
			Endif
			
			nStatus := -1
			nTent := 0
			
			oPrint:ResetPrinter()
			oPrint:= TMSPrinter():New( "Boleto Laser" )
			
			nRegSav := ZTB->( Recno() )
			
			If !Empty( aRegGer[1][2] )
				
				For nx := 1 to len( aRegGer )
					If !Empty( aRegGer[nX][2] )
						ZTB->( dbGoto( aRegGer[nX][1] ) )
						Reclock("ZTB",.F.)
						ZTB->ZTB_ARQUI := aRegGer[nX][2]
						ZTB->ZTB_STATUS := "2"
						If lVeraCros
							ZTB->ZTB_STATU1 := "4"
						Endif
						ZTB->ZTB_DTGER	:= dDataBase
						ZTB->( MsUnlock() )
					Endif
				Next nX
				ZTB->( dbGoto( aRegGer[1][1] ) )
				
				cEmailEnv	:= ZTB->ZTB_EMAIL
				cAnexo		:= ZTB->ZTB_ARQUI
				nRegZTB		:= ZTB->( Recno() )
				aRegGer := {}
				
				If !lVeraCros .and. lAutomatico
					envAuto( nRegZTB, cEmailEnv, cAnexo, cUserMail, cemailSent, cSenhaMail )
				Endif
				
			Endif
			
			ZTB->( dbGoto( nRegSav ) )
			
		Endif
		
		DbSelectArea("ZTB")
		ZTB->( DbSkip() )
	End
EndIf

If lPreview
	oPrint:Preview()     // Visualiza antes de imprimir
End If

Return nil




/*
==============================================================================================================================================================
Fun o     : Impress
Autor      : Tiago Filho
Data       :27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function Impress( aBitmap, aDadosEmp, aDadosTit, aDadosBanco, aDatSacado, aBolText, CB_RN_NN, cMail, cAnoMes, cMesRef, cAnoRef )
Local cBmpSant 		:= "SantanderColor.bmp"
Local oFont8
Local oFont10
Local oFont16
Local oFont16n
Local oFont20
Local oFont24
Local i := 0
Local aCoords1 		:= {150,1900,250,2300}  	// FICHA DO SACADO
Local aCoords2 		:= {420,1900,490,2300}  	// FICHA DO SACADO
Local aCoords3 		:= {1270,1900,1370,2300} 	// FICHA DO CAIXA
Local aCoords4 		:= {1540,1900,1610,2300} 	// FICHA DO CAIXA
Local aCoords5 		:= {2190,1900,2290,2300} 	// FICHA DE COMPENSACAO
Local aCoords6 		:= {2460,1900,2530,2300} 	// FICHA DE COMPENSACAO
Local oBrush  												//fundo no valor do titulo
Local nStatus 			:= -1
Local cBody				:=""
Local nSequencia		:=0
Local cAnexos 			:= ""
Local lOk 				:= .T.
Local cTo				:= ""
Local cCC				:= ""
Local cDiretorio 		:= "\spool\boletos\"
Local cLocalSpool		:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )
Local nErro				:= 0
Local nRecno
Local oMail
Local oMessage
Local nVlrMulta1 		:= 0
Local nVlrTotal1 		:= 0


If Right( cLocalSpool, 1 ) <> "\"
	cLocalSpool += "\"
Endif
cDiretorio := cLocalSpool


oFont6n 	:= TFont():New("Arial",9,6 ,.T.,.T.,5,.T.,5,.T.,.F.)
oFont7n 	:= TFont():New("Arial",9,7 ,.T.,.T.,5,.T.,5,.T.,.F.)
oFont8  	:= TFont():New("Arial",9,8 ,.T.,.F.,5,.T.,5,.T.,.F.)
oFont8n 	:= TFont():New("Arial",9,8 ,.T.,.T.,5,.T.,5,.T.,.F.)
oFont10 	:= TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
oFont12 	:= TFont():New("Arial",9,12,.T.,.F.,5,.T.,5,.T.,.F.)
oFont12n	:= TFont():New("Arial",9,12,.T.,.T.,5,.T.,5,.T.,.F.)
oFont14	:= TFont():New("Arial",9,14,.T.,.T.,5,.T.,5,.T.,.F.)
oFont14n	:= TFont():New("Arial",9,13,.T.,.F.,5,.T.,5,.T.,.F.)
oFont16 	:= TFont():New("Arial",9,16,.T.,.T.,5,.T.,5,.T.,.F.)
oFont16n	:= TFont():New("Arial",9,16,.T.,.F.,5,.T.,5,.T.,.F.)
oFont20 	:= TFont():New("Arial",9,20,.T.,.T.,5,.T.,5,.T.,.F.)
oFont24 	:= TFont():New("Arial",9,24,.T.,.T.,5,.T.,5,.T.,.F.)

oBrush 	:= TBrush():New(,CLR_HGRAY,,)
oPrint:StartPage()   // Inicia uma nova p?ina

aEventos := {}
nVlrSeg  := 0

DbSelectArea("SZG")
DbSetOrder(2)
DbSeek(xFilial("SZG")+SE1->E1_PREFIXO+Alltrim(SE1->E1_NUM) )

While SZG->(!Eof()) .And.  SE1->E1_PREFIXO+alltrim(alltrim(SE1->E1_NUM)) == Substr(SZG->ZG_DOC,1,9)
	
	SZD->(DbSeek(xFilial("SZD")+SZG->ZG_CODEVEN ))
	
	SX5->(DbSeek(xFilial("SX5")+"Z9"+SZD->ZD_TIPEVEN ))
	
	nValor := SZG->ZG_VALOR - SZG->ZG_VLRBOL - SZG->ZG_VLASSFI - SZG->ZG_VLRDESC
	
	If SZG->ZG_VALOR == (SZG->ZG_VALOR - SZG->ZG_VLRBOL - SZG->ZG_VLASSFI - SZG->ZG_VLRDESC)
		AaDD(aEventos,{SZG->ZG_DESEVEN,nValor})
	Else
		AaDD(aEventos,{SZG->ZG_DESEVEN,SZG->ZG_VALOR})
		If substr(SZG->ZG_DESEVEN,1,6) == "ENSINO"
			If SZG->ZG_VLRBOL > 0
				AaDD(aEventos,{"BOLSA DE ENSINO",-SZG->ZG_VLRBOL})
			End If
			If SZG->ZG_VLASSFI > 0
				AaDD(aEventos,{"AUX. FIN. DE ENSINO",-SZG->ZG_VLASSFI})
			End If
			If SZG->ZG_VLRDESC > 0
				AaDD(aEventos,{"DESCONTO DE ENSINO",-SZG->ZG_VLRDESC})
			End If
			
		ElseIf substr(SZG->ZG_DESEVEN,1,3) == "BUS"
			If SZG->ZG_VLRBOL > 0
				AaDD(aEventos,{"BOLSA DE BUS",-SZG->ZG_VLRBOL})
			End If
			If SZG->ZG_VLASSFI > 0
				AaDD(aEventos,{"AUS. FIN. DE BUS ",-SZG->ZG_VLASSFI})
			End If
			If SZG->ZG_VLRDESC > 0
				AaDD(aEventos,{"DESCONTO DE BUS",-SZG->ZG_VLRDESC})
			End If
		End If
		
		If substr(SZG->ZG_DESEVEN,1,6) == "ENSINO"
			AaDD(aEventos,{"VALOR LIQUIDO DE ENSINO",nValor})
		ElseIf substr(SZG->ZG_DESEVEN,1,3) == "BUS"
			AaDD(aEventos,{"VALOR LIQUIDO DE BUS",nValor})
		End If
	End If
	If SZG->ZG_VLRSEG <> 0
		nVlrSeg += SZG->ZG_VLRSEG
	EndIf
	
	DbSelectArea("SZG")
	DbSkip()
	
End

If nVlrSeg <> 0
	AADD(aEventos,{"Seguro : ",nVlrSeg})
EndIf

//Ficha do Caixa                                                     ?
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

oPrint:SayBitmap( 050,100,cBmpSant,500,90 )

For nX := 1 to 3
	oPrint:Line (080,660+nX, 150,660+nX )
Next

oPrint:Say  (070,690,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20 )

For nX := 1 to 3
	oPrint:Line (080,890+nX, 150,890+nX )
Next

oPrint:Say  ( 160, 110 ,"CEDENTE"    ,oFont8n)
oPrint:Say  ( 200,110 ,Iif(_lBcoCorrespondente,aDadosBanco[8],aDadosEmp[1]) ,oFont12n)

oPrint:Say  ( 160,1910 ,"VENCIMENTO" ,oFont8n)
If (dDatabase > aDadosTit[4])
	oPrint:Say  ( 200,2005,PadL(AllTrim(DTOC(dDatabase)),16," ")             ,oFont10)
Else
	oPrint:Say  ( 200,2005,PadL(AllTrim(DTOC(aDadosTit[4])),16," ")             ,oFont10)
End If

oPrint:Say  ( 270, 120 ,"SACADO"    ,oFont8n)
oPrint:Say  ( 310 ,120 ,aDatSacado[1]      ,oFont10)
oPrint:Say  ( 270, 1160 ,"N.DO DOCUMENTO"    ,oFont8n)
oPrint:Say  ( 310 ,1220 ,aDadosTit[1] ,oFont10)
oPrint:Say  ( 270, 1910 ,"VALOR DO DOCUMENTO"    ,oFont8n)

If (dDatabase > aDadosTit[4])
	nVlrMulta1 := (aDadosTit[10]*2/100)+(1/30/100*(aDadosTit[4]-dDatabase)*aDadosTit[10]*-1)
End If

nVlrTotal1 := aDadosTit[10]+nVlrMulta1

//oPrint:Say  ( 310, 2010,PadL(AllTrim(Transform(aDadosTit[10],"@E 999,999,999.99")),16," "),oFont10)
oPrint:Say  ( 310, 2010,PadL(AllTrim(Transform(nVlrTotal1,"@E 999,999,999.99")),16," "),oFont10)
oPrint:Say  ( 380, 120 ,"NOME DO ALUNO"    ,oFont8n)
oPrint:Say  ( 430 ,120 ,SA1->A1_NOME      ,oFont10)
oPrint:Say  ( 380, 1160 ,"COD. ALUNO"    ,oFont8n)
oPrint:Say  ( 430 ,1200 ,aDatSacado[2]    ,oFont12n)

oPrint:Say  (  490, 250 ,"COMPOSIÇÃO DO T?ULO"    ,oFont12)

oPrint:Say  (  490, 1650 ,"PRE?S em R$"    ,oFont12)

oPrint:Say  ( 1710, 110 ,"MENSAGEM"    ,oFont7n)

oPrint:Say  (1860,1850,"- Autentica o Mec?ica -"  ,oFont7n)

If Len(aEventos) > 0
	nLin := 550
	For nX := 1 to Len(aEventos)
		oPrint:Say  (nLin, 120,aEventos[nX,1],oFont8n )
		oPrint:Say  (nLin, 950,PadL(Alltrim(Transform(aEventos[nX,2],"@e 999,999,999.99")),14),oFont8n)
		nLin += 40
	Next
EndIf

If Len(aMens) > 0
	nLin := 550
	For nX := 2 to Len(aMens)
		oPrint:Say  (nLin, 1160,aMens[nX,1],oFont8n )
		If nX <> 7
			oPrint:Say  (nLin, 2050,PadL(Alltrim(Transform(aMens[nX,2],"@e 999,999,999.99")),14),oFont8n)
		Else
			oPrint:Say  (nLin, 2087,aMens[nX,2],oFont8n)
		EndIf
		nLin += 40
	Next
EndIf

///////////////

//Gambiarra, descobrir como mudar tipo da linha.  PONTILHAMENTO
For i := 100 to 2300 step 30
	oPrint:Line( 2050, i, 2050, i+20)
	oPrint:Line( 2051, i, 2051, i+20)
	oPrint:Line( 2051, i, 2051, i+20)
Next i

//Ficha de Compensacao
If aDadosBanco[1] <> "356" .and. aDadosBanco[1] <> "033"
	oPrint:FillRect(aCoords5,oBrush)
	oPrint:FillRect(aCoords6,oBrush)
Endif

oPrint:Line (2190,100,2190,2300)
oPrint:Line (2190,650,2190,650 )
oPrint:Line (2190,900,2190,900 )

oPrint:SayBitmap( 2090,100,cBmpSant,500,90 )

For nX := 1 to 3
	oPrint:Line (2100,660+nX,2190,660+nX )
Next

oPrint:Say  (2102,680,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20 )

For nX := 1 to 3
	oPrint:Line (2100,890+nX,2190,890+nX )
Next

oPrint:Say  (2124,920,CB_RN_NN[2],oFont14n) //linha digitavel

oPrint:Line (2290,100,2290,2300 )
oPrint:Line (2390,100,2390,2300 )
oPrint:Line (2460,100,2460,2300 )
oPrint:Line (2530,100,2530,2300 )

oPrint:Line (2390,500,2530,500)
oPrint:Line (2460,750,2530,750)
oPrint:Line (2390,1000,2530,1000)
oPrint:Line (2390,1350,2460,1350)
oPrint:Line (2390,1550,2530,1550)

oPrint:Say  (2190,100 ,"Local de Pagamento"                             ,oFont8)
oPrint:Say  (2230,100 ,"Pag?el em qualquer ag?cia banc?ia at?o vencimento"       ,oFont10)
oPrint:Say  (2190,1910,"Vencimento"                                     ,oFont8)

If (dDatabase > aDadosTit[4])
	oPrint:Say  (2230,2005,PadL(AllTrim(DTOC(dDataBase)),16," ")                               ,oFont10)
Else
	oPrint:Say  (2230,2005,PadL(AllTrim(DTOC(aDadosTit[4])),16," ")                               ,oFont10)
End If

oPrint:Say  (2290,100 ,"Cedente"                                        ,oFont8)
oPrint:Say  (2330,100 ,Iif(_lBcoCorrespondente,aDadosBanco[8],aDadosEmp[1])                                     ,oFont10)

oPrint:Say  (2290,1910,"Ag?cia/C?igo Cedente"                ,oFont8)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

If aDadosBanco[1]$"356-033"
	oPrint:Say  (2330,2010,PadL(AllTrim(SA6->A6_AGENCIA)+"/"+cCCedente,16),oFont10)// +SA6->A6_NUMCON),16 ) //+" / "+cDigitao,oFont10)
End If

oPrint:Say  (2390,100 ,"Data do Documento"                              ,oFont8)

oPrint:Say  (2420,100 ,DTOC(aDadosTit[3])                               ,oFont10)

oPrint:Say  (2390,505 ,"Nro.Documento"                                  ,oFont8)
oPrint:Say  (2420,605 ,aDadosTit[1]                                     ,oFont10)

oPrint:Say  (2390,1005,"Esp?ie Doc."                                   ,oFont8)
oPrint:Say  (2420,1105,"DS"                                             ,oFont10)

oPrint:Say  (2390,1355,"Aceite"                                         ,oFont8)
oPrint:Say  (2420,1455,"N"                                             ,oFont10)

oPrint:Say  (2390,1555,"Data do Processamento"                          ,oFont8)

oPrint:Say  (2420,1655,DTOC(aDadosTit[2])                            	,oFont10)

oPrint:Say  (2390,1910,"Nosso N?ero"                                   ,oFont8)
//oPrint:Say  (2420,2000,LEFT(CB_RN_NN[3],12)            	,oFont10) //cDoc
oPrint:Say  (2420,2000, cnNumero                            	,oFont10)
//oPrint:Say  (2420,2000,"0000"+cnNumero                            	,oFont10)   // *Verificar se ?ou n? para acrescentar os 4 zeros a esquerda, pois ni cod de barras ?n ecessario.

oPrint:Say  (2460,100 ,"Uso do Banco"                                   ,oFont8)

oPrint:Say  (2460,505 ,"Carteira"                                       ,oFont8)
//oPrint:Say  (2490,555 ,"ECR 										 "          ,oFont10)
oPrint:Say  (2490,555 ,cCarteira           										,oFont10)

oPrint:Say  (2460,755 ,"Esp?ie"                                        			,oFont8)
oPrint:Say  (2490,805 ,"R$"                                             			,oFont10)

oPrint:Say  (2460,1005,"Quantidade"                                     		,oFont8)
oPrint:Say  (2460,1555,"Valor"                                          			,oFont8)

oPrint:Say  (2460,1910,"(=)Valor do Documento"                         	,oFont8)
oPrint:Say  (2490,2010,PadL(AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),16," "),oFont10)

oPrint:Say  (2530,100 ,"Instruções/Texto de responsabilidade do cedente",oFont8)

oPrint:Say  (2580,100 ,aBolText[1]                                      ,oFont10)
oPrint:Say  (2630,100 ,"APOS O VENCIMENTO COBRAR JUROS DE 1% A.M.",oFont10)
oPrint:Say  (2680,100 ,aBolText[2]                                      ,oFont10)
If Empty( aBolText[3] )
	oPrint:Say  (2730,100 ,"Atualiza o de boleto vencido acesse:  ",oFont10,,CLR_HRED)
	oPrint:Say  (2780,100 ,"www.santander.com.br/boletos   ",oFont10,,CLR_HRED)
Else
	oPrint:Say  (2730,100 ,aBolText[3]    												,oFont10)
	oPrint:Say  (2780,100 ,"Atualiza o de boleto vencido acesse:  www.santander.com.br/boletos   ",oFont10,,CLR_HRED)
Endif
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

oPrint:Say  (2530,1910,"(-)Desconto/Abatimento"                         ,oFont8)
oPrint:Say  (2600,1910,"(-)Outras Deduções"                             ,oFont8)
oPrint:Say  (2630,2010,PadL(AllTrim(Transform(aDadosTit[9],"@E 999,999,999.99")),16," "),oFont10)
oPrint:Say  (2670,1910,"(+)Mora/Multa"                                  ,oFont8)
//acrescentar as multas aqui
If (dDatabase > aDadosTit[4])
	oPrint:Say  (2700,2020,PadL(AllTrim(Transform(Round((aDadosTit[10]*2/100)+(1/30/100*(aDadosTit[4]-dDatabase)*aDadosTit[10]*-1),2),"@E 999,999,999.99")),16," ")                                  ,oFont10)
End If
oPrint:Say  (2740,1910,"(+)Outros Acr?cimos"                           ,oFont8)
oPrint:Say  (2810,1910,"(=)Valor Cobrado"                               ,oFont8)
If (dDatabase > aDadosTit[4])
	oPrint:Say  (2840,2010,PadL(AllTrim(Transform( Round((((aDadosTit[10]*2/100)+(1/30/100*(aDadosTit[4]-dDatabase)*aDadosTit[10]*-1)) + aDadosTit[10]),2),"@E 999,999,999.99")),16," ")                                  ,oFont10)
Else
	oPrint:Say  (2840,2010,PadL(AllTrim(Transform(aDadosTit[10],"@E 999,999,999.99")),16," ")                                  ,oFont10)
End If

oPrint:Say  (2880,100 ,"Sacado"                                         ,oFont8)
oPrint:Say  (2908,210 ,aDatSacado[1]+" ("+aDatSacado[2]+")"             ,oFont8)
oPrint:Say  (2948,210 ,aDatSacado[3]                                    ,oFont8)
oPrint:Say  (2988,210 ,aDatSacado[6]+"  "+aDatSacado[4]+" - "+aDatSacado[5]+"         CGC/CPF: "+Iif(Len(AllTrim(aDatSacado[7]))==14,Transform(aDatSacado[7],"@R 99.999.999/9999-99"),Transform(aDatSacado[7],"@R 999.999.999-99")) ,oFont8)

oPrint:Say  (2845,100 ,"Sacador/Avalista"+Iif(_lBcoCorrespondente,aDadosEmp[1],"")                               ,oFont8)
oPrint:Say  (3030,1500,"Autentica o Mec?ica -"                        ,oFont8)

oPrint:Say  (3030,1850,"Ficha de Compensa o"                           ,oFont10)

oPrint:Line (2190,1900,2880,1900 )
oPrint:Line (2600,1900,2600,2300 )
oPrint:Line (2670,1900,2670,2300 )
oPrint:Line (2740,1900,2740,2300 )
oPrint:Line (2810,1900,2810,2300 )
oPrint:Line (2880,100 ,2880,2300 )

oPrint:Line (3025,100,3025,2300  )

MSBAR("INT25",26.28,1.2,CB_RN_NN[1],oPrint,.F.,Nil,Nil,0.023,1.2,Nil,Nil,"A",.F.)

oPrint:EndPage() // Finaliza a p?ina


Return Nil





/*
==============================================================================================================================================================
Fun o     : Modulo10
Autor      :Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/

Static Function Modulo10(cData)
Local L,D,P 	:= 0
Local B     	:= .F.

Default cData 	:= ""

L := Len(cData)  	//TAMANHO DE BYTES DO CARACTER
B := .T.
D := 0     			//DIGITO VERIFICADOR

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
	
End

D := 10 - (Mod(D,10))

If D = 10
	D := 0
End

Return(D)



/*
==============================================================================================================================================================
Fun o     : Modulo11
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function Modulo11(cData,cBanc)
Local L, D, P := 0

If cBanc$"001"  // Banco do brasil
	L := Len(cdata)
	D := 0
	P := 10
	While L > 0
		P := P - 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 2
			P := 10
		EndIf
		L := L - 1
	End
	D := mod(D,11)
	If D == 10
		D := "X"
	Else
		D := AllTrim(Str(D))
	EndIf
ElseIf cBanc$"237-033-356-453-399-422" // Bradesco/Santander/Itau/Mercantil/Rural/HSBC/Safra
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		EndIf
		L := L - 1
	End
	D := 11 - (mod(D,11))
	
	If (D == 10 .Or. D == 11) .and. (cBanc$"237-033-356-422")
		D := 1
	EndIf
	If (D == 1 .Or. D == 0 .Or. D == 10 .Or. D == 11) .and. (cBanc$"289-453-399")
		D := 0
	EndIf
	D := AllTrim(Str(D))
ElseIf cBanc$"389" //Mercantil
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		EndIf
		L := L - 1
	End
	D := mod(D,11)
	If D == 1 .Or. D == 0
		D := 0
	Else
		D := 11 - D
	EndIf
	D := AllTrim(Str(D))
ElseIf cBanc$"479"  //BOSTON
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		EndIf
		L := L - 1
	End
	D := Mod(D*10,11)
	If D == 10
		D := 0
	EndIf
	D := AllTrim(Str(D))
ElseIf cBanc$"409"  //UNIBANCO
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		EndIf
		L := L - 1
	End
	D := Mod(D*10,11)
	If D == 10 .or. D == 0
		D := 0
	EndIf
	D := AllTrim(Str(D))
ElseIf cBanc$"999"  //Real
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		EndIf
		L := L - 1
	End
	D := Mod(D*10,11)
	If D == 10 .or. D == 0
		D := 0
	EndIf
	D := AllTrim(Str(D))
Else
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		EndIf
		L := L - 1
	End
	D := 11 - (mod(D,11))
	If (D == 10 .Or. D == 11)
		D := 1
	EndIf
	D := AllTrim(Str(D))
Endif

Return(D)





/*
==============================================================================================================================================================
Fun o     : Ret_cBarra
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function Ret_cBarra(cBanco,cAgencia,cConta,cDacCC,cCarteir,cNroDoc,nValor,dvencimento,cConvenio,cSequencial,_lTemDesc,_cParcela,_cAgCompleta)

Local blvalorfinal 		:= 0
Local cNNumSDig 			:= ''
Local cCpoLivre 			:= ''
Local cCBSemDig 			:= ''
Local cCodBarra 			:= ''
Local cNNum 				:= ''
Local cFatVenc 			:= ''
Local cLinDigit 			:= ''

Private nVlrDesc 			:= 0
Private nVlrJuro 			:= 0

nVlrMulta 	:= 0
cBanco	 	:= Substr(cBanco,1,3)

If (dDatabase > dvencimento)
	nVlrMulta 	:= (nValor*2/100)+(1/30/100*(dVencimento-dDatabase)*nValor*-1)
	dvencimento := dDatabase
End If

nValorfinal := nValor+nVlrMulta

cSeqNNum  	:= StrZero(Val(Substr(ZTB->ZTB_PREFIX,3,1)+AllTrim(ZTB->ZTB_NUM)),12)

cNossoNum := "00000"+alltrim(cnNumero) // para boleto o nosso numero s? 13 digitos // ele esta vindo com 8 , entao acrescento 5 zeros a esquerda

//		cCarteira	:= '101'
aCart 		:= {U_EGFINNMSTN(cCarteira)}
cCart 		:= aCart[1][1] + aCart[1][2]
nFatorVenc  := STRZERO(dvencimento - CtoD("07/10/1997"),4)

cCdBarSeq1  := cBanco + '9' + nFatorVenc + STRZERO((ROUND(nValorfinal,2)*100),10)+ '9'+ cCCedente + alltrim(cNossoNum) + '0' + '101'  // cCarteira
aDvCodBar	:= {U_CALCDVBARR(cCdBarSeq1)}

cCodBarra   := cBanco + "9" + aDvCodBar[1][2]+ nFatorVenc +  STRZERO((ROUND(nValorfinal,2)*100),10)+ '9'+ cCCedente + cNossoNum + '0' + '101' //cCarteira

cLinha1 		:= cBanco + "9" + "9" + Substr(cCCedente,1,4)
aDVLinDig1  := Mod10Boleto(cLinha1)
cLinha1 		+= aDVLinDig1

// Linha 1 OK
cLinha2 		:= Substr(cCCedente,5,3) + Substr(cNossoNum,1,7) //3 ultimos digitos do cedente + 7 primeiros digitos do nosso numero )
aDVLinDig2  := Mod10Boleto(cLinha2)
cLinha2 		+= aDVLinDig2

// Linha 2 OK
cLinha3 		:= Substr(cNossoNum,8,6) + '0' + '101' // cCarteira 101 - cobranca com registro // 102 cobranca simples sem registro
aDVLinDig3  := Mod10Boleto(cLinha3)
cLinha3 		+= aDVLinDig3

// Linha 3 OK
cLinha4 		:= aDvCodBar[1][2]

// Linha 4 n?

//		cLinha5 	:= nFatorVenc + STRZERO((ROUND(nValor,2)*100),10)
cLinha5 		:= nFatorVenc + STRZERO((ROUND(nValorfinal,2)*100),10)

cLindig 		:= Substr(cLinha1,1,5) +'.'+ Substr(cLinha1,6,5) +' '
cLindig 		+= Substr(cLinha2,1,5) +'.'+ Substr(cLinha2,6,6) +' '
cLindig 		+= Substr(cLinha3,1,5) +'.'+ Substr(cLinha3,6,6) +' '
cLindig 		+= cLinha4 +' '+ cLinha5

Return({cCodBarra,cLinDig,cNossoNum})

/*
==============================================================================================================================================================
Fun o     : Agencia
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function Agencia(_cBanco,_nAgencia)
Local _cRet 		:= ""

If _cBanco$"479-389"
	_cRet := AllTrim(SEE->EE_AGBOSTO)
ElseIF _cBanco$"033-356-422"
	_cRet := StrZero(Val(AllTrim(_nAgencia)),4)
Else
	_cRet := SubStr(StrZero(Val(AllTrim(_nAgencia)),5),1,4)+"-"+SubStr(StrZero(Val(AllTrim(_nAgencia)),5),5,1)
Endif

Return(_cRet)

/*
==============================================================================================================================================================
Fun o     : Conta
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function Conta(_cBanco,_cConta)
Local _cRet 		:= ""

If _cBanco$"479/389"
	_cRet := AllTrim(SEE->EE_CODEMP)
ElseIf _cBanco$"033-356"
	_cRet := StrZero(Val(SubStr(AllTrim(_cConta),1,Len(AllTrim(_cConta)))),7)
Else
	_cRet := SubStr(AllTrim(_cConta),1,Len(AllTrim(_cConta)))
Endif

Return(_cRet)



/*
==============================================================================================================================================================
Fun o     : NumParcela
Autor      : Tiago Filho
Data       :27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function NumParcela(_cParcela)
Local _cRet 		:= ""

If ASC(_cParcela) >= 65 .or. ASC(_cParcela) <= 90
	_cRet := StrZero(Val(Chr(ASC(_cParcela)-16)),2)
Else
	_cRet := StrZero(Val(_cParcela),2)
Endif

Return(_cRet)



/*
==============================================================================================================================================================
Fun o     : Fic_Sacado
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function Fic_Sacado()

If aDadosBanco[1]<>"033".And.aDadosBanco[1]<>"356"
	oPrint:FillRect(aCoords3,oBrush)
	oPrint:FillRect(aCoords4,oBrush)
Endif

oPrint:Line (1270,100,1270,2300)
oPrint:Line (1270,650,1170,650 )
oPrint:Line (1270,900,1170,900 )

oPrint:SayBitmap( 1975,100,cBmpSant,500,90 )

oPrint:Say  (1182,680,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20 )

oPrint:Line (1370,100,1370,2300 )
oPrint:Line (1470,100,1470,2300 )
oPrint:Line (1540,100,1540,2300 )
oPrint:Line (1610,100,1610,2300 )

oPrint:Line (1470,500,1610,500)
oPrint:Line (1540,750,1610,750)
oPrint:Line (1470,1000,1610,1000)
oPrint:Line (1470,1350,1540,1350)
oPrint:Line (1470,1550,1610,1550)

oPrint:Say  (1270,100 ,"Local de Pagamento"                             ,oFont8)
oPrint:Say  (1310,100 ,"Qualquer banco at?a data do vencimento"        ,oFont10) //ALT. VALDEIR

oPrint:Say  (1270,1910,"Vencimento"                                     ,oFont8)
oPrint:Say  (1310,2010,DTOC(aDadosTit[4])                               ,oFont10)

oPrint:Say  (1370,100 ,"Cedente"                                        ,oFont8)
oPrint:Say  (1410,100 ,Iif(_lBcoCorrespondente,aDadosBanco[8],aDadosEmp[1])          ,oFont10)

oPrint:Say  (1370,1910,"Ag?cia/C?igo Cedente"                         ,oFont8)
oPrint:Say  (1410,2005,PadL(AllTrim(aDadosBanco[3]+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],"")),16," "),oFont10)

oPrint:Say  (1470,100 ,"Data do Documento"                              ,oFont8)
oPrint:Say  (1500,100 ,DTOC(aDadosTit[3])     ,oFont10) //ALT. VALDEIR

If aDadosBanco[1] == "237"  //SE BRADESCO
	oPrint:Say  (1500,100 ,Substring(DTOS(aDadosTit[3]),7,2)+"/"+Substring(DTOS(aDadosTit[3]),5,2)+"/"+Substring(DTOS(aDadosTit[3]),1,4)  ,oFont10)
Else
	oPrint:Say  (1500,100 ,DTOC(aDadosTit[3])                               ,oFont10)
Endif

oPrint:Say  (1470,505 ,"Nro.Documento"                                  ,oFont8)
oPrint:Say  (1500,595 ,aDadosTit[1]                                     ,oFont10)

oPrint:Say  (1470,1005,"Esp?ie Doc."                                   ,oFont8)
oPrint:Say  (1500,1105,"DM"                                             ,oFont10)

oPrint:Say  (1470,1355,"Aceite"                                         ,oFont8)
oPrint:Say  (1500,1455,"N"                                             ,oFont10)

oPrint:Say  (1470,1555,"Data do Processamento"                          ,oFont8)
oPrint:Say  (1500,1655,DTOC(aDadosTit[2])     ,oFont10)  //ALT. VALDEIR

If aDadosBanco[1]$"237"   //SE BRADESCO
	oPrint:Say  (1500,1655,Substring(DTOS(aDadosTit[2]),7,2)+"/"+Substring(DTOS(aDadosTit[2]),5,2)+"/"+Substring(DTOS(aDadosTit[2]),1,4)  ,oFont10)
Else
	oPrint:Say  (1500,1655,DTOC(aDadosTit[2])                               ,oFont10)
Endif

oPrint:Say  (1470,1910,"Nosso N?ero"                                   ,oFont8)
oPrint:Say  (1500,2005,PadL(AllTrim(aDadosTit[6]),17," ")                  ,oFont10)
oPrint:Say  (1540,100 ,"Uso do Banco"                                   ,oFont8)

If aDadosBanco[1]$"409"
	oPrint:Say  (1570,100,"cvt 5539-5",oFont10)
Endif

oPrint:Say  (1540,505 ,"Carteira"                                       ,oFont8)
oPrint:Say  (1570,555 ,aDadosBanco[6]+aDadosBanco[7]                    ,oFont10)

oPrint:Say  (1540,755 ,"Esp?ie"                                        ,oFont8)
oPrint:Say  (1570,805 ,"R$"                                             ,oFont10)

oPrint:Say  (1540,1005,"Quantidade"                                     ,oFont8)
oPrint:Say  (1540,1555,"Valor"                                          ,oFont8)

oPrint:Say  (1540,1910,"(=)Valor do Documento"                          ,oFont8)
oPrint:Say  (1570,2005,PadL(AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),16," "),oFont10)

If aDadosBanco[1]$"033-356"
	oPrint:Say  (1610,100 ,"Instruções/Todos as informações deste bloqueto s? de exclusiva responsabilidade do cedente",oFont8)
Else
	oPrint:Say  (1610,100 ,"Instruções/Texto de responsabilidade do cedente",oFont8)
Endif

oPrint:Say  (1660,100 ,Iif(aDadosTit[7]>0,"Conceder desconto de R$ "+AllTrim(Transform(aDadosTit[7],"@E 999,999.99"))+" ate o vencimento","") ,oFont10)
oPrint:Say  (1710,100 ,Iif(aDadosTit[8]>0,"Cobrar juros/mora dia de R$ "+AllTrim(Transform(aDadosTit[8],"@E 999,999.99")),"") ,oFont10)
oPrint:Say  (1760,100 ,aBolText[1]                                      ,oFont10)
oPrint:Say  (1810,100 ,aBolText[2]                                      ,oFont10)
oPrint:Say  (1860,100 ,aBolText[3]                                      ,oFont10)

oPrint:Say  (1610,1910,"(-)Desconto/Abatimento"                         ,oFont8)
oPrint:Say  (1680,1910,"(-)Outras Deduções"                             ,oFont8)
oPrint:Say  (1750,1910,"(+)Mora/Multa"                                  ,oFont8)
oPrint:Say  (1820,1910,"(+)Outros Acr?cimos"                           ,oFont8)
oPrint:Say  (1890,1910,"(=)Valor Cobrado"                               ,oFont8)

oPrint:Say  (1960 ,100 ,"Sacado:"                                         ,oFont8)
oPrint:Say  (1988 ,210 ,aDatSacado[1]+" ("+aDatSacado[2]+")"             ,oFont8)
oPrint:Say  (2030 ,210 ,aDatSacado[3]                                    ,oFont8)
oPrint:Say  (2070 ,210 ,aDatSacado[6]+"  "+aDatSacado[4]+" - "+aDatSacado[5]+"         CGC/CPF: "+Iif(Len(AllTrim(aDatSacado[7]))==14,Transform(aDatSacado[7],"@R 99.999.999/9999-99"),Transform(aDatSacado[7],"@R 999.999.999-99")) ,oFont8)
oPrint:Say  (2070 ,200 ,aDatSacado[6]                                    ,oFont10)

oPrint:Say  (1925,100 ,"Sacador/Avalista"+Iif(_lBcoCorrespondente,aDadosEmp[1],"")                               ,oFont8)
oPrint:Say  (2110,1500,"Autentica o Mec?ica "                        ,oFont8)
oPrint:Say  (1204,1850,"Recibo do Sacado"                              ,oFont10)

oPrint:Line (1270,1900,1960,1900 )
oPrint:Line (1680,1900,1680,2300 )
oPrint:Line (1750,1900,1750,2300 )
oPrint:Line (1820,1900,1820,2300 )
oPrint:Line (1890,1900,1890,2300 )
oPrint:Line (1960,100 ,1960,2300 )

oPrint:Line (2105,100,2105,2300  )

Return Nil




/*
==============================================================================================================================================================
Fun o     : RetDac
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function RetDac(cCodBarra)
Local i 			:= 44
Local nDac
Local nResto
Local nSoma 	:= 0
Local nMult 	:= 2

for i := 44 to 1 step -1
	if i # 5
		If nMult > 9
			nMult := 2
		End If
		nSoma := nSoma + val(substr(alltrim(cCodBarra),i,1)) * nMult
		nMult++
	Endif
next i

nResto 	:= nSoma % 11
nDac 		:= 11 - nResto

If (nDac == 0 .Or. nDac == 1 .Or. nDac == 10 .Or. nDac == 11)
	nDac := 1
EndIf

Return nDac




/*
==============================================================================================================================================================
Fun o     : CalcDigitao
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function CalcDigitao(cData)
Local nMult 			:= 1
Local i 					:= 1
Local nSoma1 			:= 0
Local nSoma2 			:= 0
Local nResto			:= 0
Local nRet				:= 0

For i := 1 to 24
	nSoma1 := val(Substr(cData,i,1))*nMult
	If nSoma1 >= 10
		nSoma2 := nSoma2 + (val(substr(alltrim(str(nSoma1)),1,1)) + val(substr(alltrim(str(nSoma1)),2,1)) )
	Else
		nSoma2 := nSoma2 + nSoma1
	EndIf
	
	If nMult == 1
		nMult := 2
	ElseIf nMult == 2
		nMult := 1
	EndIf
Next i

nResto 	:= nSoma2 % 10
nRet 		:= 10-nResto

If nRet == 10
	nRet := 0
End If

cDigitao := alltrim(str(nRet))

Return alltrim(str(nRet))




Static Function Mod10Boleto(cSeq)

cDoc 		:= Alltrim(cSeq)
nSoma		:= 0

nMult	:= 2

For i := len(cDoc) to 1 Step -1                  // 8 x 2 = 16
	// 7 x 1 = 07
	nDigDoc 	:= val(substr(cDoc,i,1))         // 7 x 2 = 14
	// 4 x 1 = 04
	nCalc 	:= nDigDoc*nMult                     // 1 x 2 = 02
	
	if nCalc > 9
		cCalc := Str(nCalc,2)
		nCalc := Val(Substr(cCalc,1,1)) + Val(Substr(cCalc,2,1))
	endif
	
	nSoma	+= nCalc                             // 2 x 1 = 02
	// 1 x 2 =  2
	nMult := if(nMult == 1, 2, 1) 				 // 1 x 1 =  1
	// 1 x 2 =  2
Next                                             //--->     46 / 10 = 4,6 rest 6
//D?. = 10 - 6 = --> 4 <--
nResto 	:= (nSoma % 10)
if nResto == 0
	nDigNN	:= '0'
else
	nDigNN	:= Str(10 - nResto,1)
endif

Return(nDigNN)



User Function GRDA013(cAlias, nReg, nOpc)
Local cQuery		:= ""
Local cAliasQry	:= GetNextAlias()
Local cMail			:= ""
Local cFilename	:= ""
Local cMesRef		:= ""
Local cAnoRef		:= ""
Local cPerg			:= 'GRD010'
Local lOk			:= .F.

If Select( cAliasQry ) > 0
	dbSelectArea( cAliasQry )
	dbCloseArea()
Endif

Pergunte( cPerg, .F. )

cQuery := "SELECT DISTINCT ZTB_EMAIL, ZTB_ARQUI, ZTB_REFERE "
cQuery += "FROM " + RetSqlName( "ZTB" ) + " ZTB "
cQuery += "WHERE ZTB_FILIAL = '" + xFilial( "ZTB" ) + "' "
cQuery += "AND ZTB_REFERE = '" + MV_PAR11 + "' "
cQuery += "AND ( ZTB_STATU1 = '1' "
cQuery += " OR  ZTB_STATU1 = '3' ) "
cQuery += "AND ZTB_STATUS = '2' "
cQuery += "AND D_E_L_E_T_ = ' ' "

cQuery := ChangeQuery(cQuery)

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasQry, .F., .T.)

cMesRef := Left( MV_PAR11, 2 )
cAnoRef := Right( MV_PAR11, 4 )

If (cAliasQry)->(Eof())
	ApmsgAlert( "N? existem e-mails pendentes a serem enviados!", "Aviso" )
Endif

If ApMsgYesNo( "Confirma o envio dos boletos pendentes?", "Confirmar Envio" )
	If (cAliasQry)->( !eof() )
		msgRun( "Enviando emails pendentes","Aguarde...",{ || envPend( cAliasQry, cMesRef, cAnoRef ) } )
		LoK		:= .T.
	Endif
Endif

If Select( cAliasQry ) > 0
	dbSelectArea( cAliasQry )
	dbCloseArea()
Endif
If lOk
	MsgRun( "Limpeza da base de dados", "Aguarde...", { || LimpaBas( {.F., .F., .T., .F., .F.} ) } )
Endif
Return Nil




Static Function SendMail(cMail, cFilename, cMesRef, cAnoRef, cUserMail, cemailSent, cSenhaMail)
Local nStatus		:= -1
Local cAnexos		:= ""
Local aFiles		:= {}
Local x				:= 0
Local oMail
Local nErro			:= 0
Local cFrom			:= ""
Local cSubject		:= "Boleto Cobran? Graded School"
Local cTexto		:= ""
Local cDiretorio	:= "\Spool\boletos\"
Local cLocalSpool	:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

If Right( cLocalSpool, 1 ) <> "\"
	cLocalSpool += "\"
Endif
cDiretorio := cLocalSpool

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
Dear Parents/Prezados Pais,

Enclosed please find the Graded School tuition bill for 2016/05, which you may also have received through the regular mail.
Por favor, anexo boleto da mensalidade escolar de 05/2016. Obs: Este mesmo boleto anexo ser?enviado tamb? por correio.

All payments should be made directly at the bank. Payments will not be allowed at Graded.
Este boleto dever?ser pago diretamente nas ag?cias banc?ias ou internet banking. N? recebemos pagamentos na Escola. (alterar p/ azul)

Lembramos que nos meses de Junho e Dezembro as mensalidades tem como vencimento o dia 15 e no m? de Julho o vencimento ?dia 01.

Please remind that every year in the months of June and December the due date is on the 15th and July is on the 1st.

Regards, Atenciosamente
*/

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
oMail:Init( '', Alltrim(GetMV("MV_SZPREC4",,'smtp.gmail.com')) , Alltrim(cemailSent),Alltrim(cSenhaMail), 0, GetMv( "MV_SZPREC5",,465) )
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

oMessage := TMailMessage():New()
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



User Function GRDA014(cAlias, nReg, nOpc)
Local cMesAno	:= ""
Local nTipoRel	:= 3
Local cPerg		:= 'GRD010'

Ajustaperg( cPerg )
Pergunte( cPerg, .F. )
If !Empty( MV_PAR11 )
	cMesAno := MV_PAR11
	
	SaveInter()
	
	U_GRDA020( cMesAno, nTipoRel )
	
	RestInter()
	
Endif

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




User Function GRDA016()
Local aPergs		:= {}
Local aRet			:= {}
Local cSql			:= ""
Local cWhere		:= ""
Local cPref			:= " ( "
Local cAliasQry	:= GetNextAlias()
Local cLocalSpool	:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )
Local nStatus		:= 0
Local nSelect		:= 0
Local oDlg
Local cCadastro	:= "Limpeza de base"
Local aResult		:= {}
Local nOpca 		:= 0
Local aAreaSav		:= GetArea()
Local oCheck1
Local lCheck1		:= .F.
Local oCheck2
Local lCheck2		:= .F.
Local oCheck3
Local lCheck3		:= .F.
Local oCheck4
Local lCheck4		:= .F.
Local oAmarelo
Local oCheck5
Local lCheck5		:= .F.
Local oVermelho
Local oAzul
Local oVerde
Local oPreto
//DEFINE MSDIALOG oDlgSenha TITLE cTitle FROM 20, 20 TO 225,310 Of oMainWnd Pixel

DEFINE MSDIALOG oDlg TITLE cCadastro From 20, 20 TO 245,330 OF oMainWnd PIXEL

@ 005, 005 Say "Efetuar limpeza de base "  	SIZE 210,08 	PIXEL OF oDlg

@ 020, 025 CHECKBOX oCheck1 VAR lCheck1 PROMPT "N? Gerados ?" SIZE 080,010  OF oDlg PIXEL
@ 020, 005 BITMAP oAmarelo RESOURCE "BR_AMARELO" 	oF  oDlg PIXEL SIZE 08,08 ADJUST WHEN .F. NOBORDER

@ 035, 025 CHECKBOX oCheck2 VAR lCheck2 PROMPT "Gerados     ?" SIZE 080,010  OF oDlg PIXEL
@ 035, 005 BITMAP oAzul RESOURCE "BR_AZUL" 			oF  oDlg PIXEL SIZE 08,08 ADJUST WHEN .F. NOBORDER

@ 050, 025 CHECKBOX oCheck3 VAR lCheck3 PROMPT "Enviados    ?" SIZE 080,010  OF oDlg PIXEL
@ 050, 005 BITMAP oVerde RESOURCE "BR_VERDE" 		oF  oDlg PIXEL SIZE 08,08 ADJUST WHEN .F. NOBORDER

@ 065, 025 CHECKBOX oCheck4 VAR lCheck4 PROMPT "Pendentes   ?" SIZE 080,010  OF oDlg PIXEL
@ 065, 005 BITMAP oVermelho RESOURCE "BR_VERMELHO" oF  oDlg PIXEL SIZE 08,08 ADJUST WHEN .F. NOBORDER

@ 080, 025 CHECKBOX oCheck5 VAR lCheck5 PROMPT "Veracross   ?" SIZE 080,010  OF oDlg PIXEL
@ 080, 005 BITMAP oPreto RESOURCE "BR_Preto" oF  oDlg PIXEL SIZE 08,08 ADJUST WHEN .F. NOBORDER

ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{||nOpcA:=1,oDlg:End()},{||oDlg:End()})

If nOpca == 1
	
	IF ApMsgYesNo( "Confirma a limpeza da base de dados? ", "Confirma o" )
		aRet := {}
		aadd( aRet, lCheck1 )
		aadd( aRet, lCheck2 )
		aadd( aRet, lCheck3 )
		aadd( aRet, lCheck4 )
		aadd( aRet, lCheck5 )
		
		MsgRun( "Limpeza da base de dados", "Aguarde...", { || LimpaBas( aRet ) } )
	Endif
	
Endif

Return Nil




Static Function LimpaBas( aRet )
Local cSql			:= ""
Local cWhere		:= ""
Local cPref			:= " ( "
Local cAliasQry	:= GetNextAlias()
Local cLocalSpool	:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )
Local nStatus		:= 0
Local nSelect		:= 0
Local cNovoLocal	:= ""

If right( cLocalSpool, 1 ) <> "\"
	cLocalSpool += "\"
Endif

cNovoLocal := cLocalSpool + "Enviados\"

cNovoLocal := U_FSMakeDir( cNovoLocal )

cSql := "SELECT R_E_C_N_O_ AS NUMREGZTB "
cSql += "FROM " + RetSqlName( "ZTB" ) + " ZTB "
cSql += "WHERE "

If aRet[1]
	cWhere += cPref + " (ZTB_STATUS = '1') "
	cPref := " OR "
	nSelect := 1
Endif
If aRet[2]
	cWhere += cPref + " ( ZTB_STATUS = '2' AND ZTB_STATU1 = '1' ) "
	cPref := " OR "
	nSelect := 1
Endif
If aRet[3]
	cWhere += cPref + " ( ZTB_STATUS = '2' AND ZTB_STATU1 = '2' ) "
	cPref := " OR "
	nSelect := 1
Endif
If aRet[4]
	cWhere += cPref + " ( ZTB_STATUS <> '1' AND ZTB_STATUS <> '2' ) "
	cPref := " OR "
	nSelect := 1
Endif
If aRet[5]
	cWhere += cPref + " ( ZTB_STATUS = '2' AND ZTB_STATU1 = '4' ) "
	cPref := " OR "
	nSelect := 1
Endif

If nSelect == 1
	cWhere += " ) AND " + " D_E_L_E_T_ = ' ' "
	
	cSql += cWhere
	
	If Select( cAliasQry ) > 0
		dbSelectArea( cAliasQry )
		(cAliasQry)->( dbCloseArea() )
	Endif
	
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cSql), cAliasQry, .F., .T.)
	tcSetField(cAliasQry, "NUMREGZTB", "N", 10, 00 )
	
	While (cAliasQry)->( !eof() )
		
		ZTB->(dbGoto( (cAliasQry)->NUMREGZTB ))
		If file( cLocalSpool + Alltrim(ZTB->( ZTB_ARQUI )))
			nStatus := __CopyFile( cLocalSpool + Alltrim(ZTB->( ZTB_ARQUI )), cNovoLocal + Alltrim(ZTB->( ZTB_ARQUI )) )
			nStatus := fErase( cLocalSpool + Alltrim(ZTB->( ZTB_ARQUI )) )
		Endif
		
		(cAliasQry)->( dbSkip() )
		
	End
	
	If Select( cAliasQry ) > 0
		dbSelectArea( cAliasQry )
		(cAliasQry)->( dbCloseArea() )
	Endif
	
	cSql := "DELETE FROM " + RetSqlName( "ZTB" ) + " WHERE "
	cSql += cWhere
	
	nStatus := tcSqlExec( cSql )
	tcRefresh( Alltrim( RetSqlName( "ZTB" ) ) )
	
Else
	ApMsgAlert( "Nada foi selecionado para limpeza", "Aviso" )
Endif

Return Nil





Static Function envPend( cAliasQry, cMesRef, cAnoRef )
LOcal cMail			:= ""
Local cFilename	:= ""
Local lOk			:= .F.
Local aUsuario		:= {}

aUsuario := GetUsermail()
If len(aUsuario) == 3
	cUserMail 	:= aUsuario[1]
	cemailSent 	:= aUsuario[2]
	cSenhaMail	:= aUsuario[3]
	
	
Else
	ApMsgAlert( "Operacao de envio de e-mail abortada", "Envio" )
	Return Nil
Endif


While (cAliasQry)->(!eof())
	
	cMail := (cAliasQry)->ZTB_EMAIL
	cFileName := Alltrim( (cAliasQry)->ZTB_ARQUI )
	
	lOk := SendMail(cMail, cFilename, cMesRef, cAnoRef, cUserMail, cemailSent, cSenhaMail)
	
	If lOk
		dbSelectArea( "ZTB" )
		dbSetOrder( 2 )
		dbSeek( xFilial( "ZTB" ) + (cAliasQry)->ZTB_REFERE + (cAliasQry)->ZTB_EMAIL )
		While ZTB->( !Eof() ) .and. (cAliasQry)->( ZTB_REFERE + ZTB_EMAIL ) == ZTB->( ZTB_REFERE + ZTB_EMAIL )
			RecLock("ZTB", .F.)
			ZTB->ZTB_DTENVI := dDataBase
			ZTB->ZTB_STATU1 := "2"
			ZTB->( msUnlock() )
			ZTB->( dbSkip() )
		End
	Endif
	(cAliasQry)->( dbSkip() )
	
End

Return Nil



Static Function envAuto( nRegZTB, cEmail, cAnexo, cUserMail, cemailSent, cSenhaMail )
LOcal cMail			:= ""
Local cFilename	:= ""
Local lOk			:= .F.
Local aAreaSav		:= GetArea()
Local aAreaZTB		:= ZTB->( GetArea() )
Local cMesRef		:= ""
Local cAnoRef		:= ""
Local cRefereAnt	:= ""
Local eEmailAnt	:= ""


ZTB->( dbGoto( nRegZTB ) )
If ZTB->( !Eof() )
	cMesRef 		:= left( ZTB->ZTB_REFERE, 2 )
	cAnoRef		:= right( ZTB->ZTB_REFERE, 4 )
	
	cMail 		:= ZTB->ZTB_EMAIL
	cFileName 	:= Alltrim( ZTB->ZTB_ARQUI )
	cRefereAnt	:= ZTB->ZTB_REFERE
	cEmailAnt	:= ZTB->ZTB_EMAIL
	
	If Alltrim(Upper( cMail )) == Alltrim(Upper( cEmail )) .and. ZTB->ZTB_STATU1 <> "2"
		
		lOk := SendMail(cMail, cFilename, cMesRef, cAnoRef, cUserMail, cemailSent, cSenhaMail)
		
		If lOk
			
			dbSelectArea( "ZTB" )
			dbSetOrder( 2 ) //ZTB_FILIAL+ZTB_REFERE+ZTB_EMAIL+ZTB_TIPO
			dbSeek( xFilial( "ZTB" ) + cRefereAnt + cEmailAnt )
			
			While ZTB->( !Eof() ) .and. cRefereAnt + cEmailAnt == ZTB->( ZTB_REFERE + ZTB_EMAIL )
				RecLock("ZTB", .F.)
				ZTB->ZTB_DTENVI := dDataBase
				ZTB->ZTB_STATU1 := "2"
				ZTB->( msUnlock() )
				ZTB->( dbSkip() )
			End
			
		Endif
	Endif
Endif

RestArea( aAreaZTB )
RestArea( aAreaSav )

Return Nil


Static Function Verchk(oListBox1,aListBox1,lCheck)
Local nX		:= 0

For nX := 1 to len( aListBox1 )
	aListBox1[nX][1] := lCheck
Next nX

SetLst1(oListBox1, aListBox1 ) // atualiza o vetor da listbox
Return Nil




Static Function trname( xemail )
Local cRet		:= ""

cRet := alltrim( xEmail )

cRet := strTran( cRet, ".", "_" )

cRet := strTran( cRet, "@", "_" )

Return cRet



Static Function GetUsermail()
Local aUsuario		:= {}
Local aRet			:= {}
Local aParambox	:= {}
Local aResp			:= {}

PswOrder(1)
PswSeek(__cUserId)
aUsuario :=	PswRet()

aadd( aRet, aUsuario[1][04] )
aadd( aRet, aUsuario[1][14] )
aadd( aRet, "" )

While .T.
	aParambox 	:= {}
	aResp			:= {}
	
	aAdd(aParamBox,{1,"Assinatura" 		,padr(aRet[1], 40),"","","","",0, .F.  })
	aAdd(aParamBox,{1,"Email"          	,Padr(aRet[2], 50),"","","","",0, .F.  })
	aAdd(aParamBox,{1,"Senha Email"     ,Space(15)			,"","","","",0, .T.  })
	
	If ParamBox(aParamBox,"Usuario Envio Email",@aResp)
		If Conecta( aResp[2], aResp[3] )
			aRet[1] := Alltrim( aResp[1] )
			aRet[2] := Alltrim( aResp[2] )
			aRet[3] := Alltrim( aResp[3] )
			Exit
		Else
			ApMsgAlert( "Falha de conex? ao tentar enviar email! Verifique a senha!", "Senha" )
		Endif
	Else
		aRet		:= {}
		Exit
	Endif
End

Return aRet



Static Function Conecta( cEmail, cSenha )
Local lRet		:= .T.
Local oMail
Local nErro		:= 0
Local lConect	:= .F.

lConect := GetMV( "MV_SZPREC1",, .F.)
If lConect
	oMail := TMailManager():New()
	oMail:SetUseSSL(.T.)
	oMail:Init( '', Alltrim(GetMv("MV_SZPREC4",,'smtp.gmail.com')) , Alltrim(cEmail),Alltrim(cSenha), 0, GetMv("MV_SZPREC5",,465) )
	oMail:SetSmtpTimeOut( GetMv("MV_SZPREC6",,60) )
	nErro := oMail:SmtpConnect()
	If nErro <> 0
		conout( "ERROR: Conectando - " + oMail:GetErrorString( nErro ) )
		oMail:SMTPDisconnect()
		lRet := .F.
	Endif
	If lRet
		nErro := oMail:SmtpAuth( Alltrim(cEmail), Alltrim(cSenha) )
		If nErro <> 0
			conout( "ERROR:2 autenticando - " + oMail:GetErrorString( nErro ) )
			oMail:SMTPDisconnect()
			lRet := .F.
		Endif
	Endif
	
	oMail:SMTPDisconnect()
Else
	lRet := .T.
Endif

Return lRet




Static Function ChecaPend()
Local cQuery		:= ""
Local cAliasQry	:= GetNextAlias()
Local lRet			:= .F.

cQuery := ""
cQuery += "SELECT TOP 10 ZTB_EMAIL, ZTB_REFERE, ZTB.R_E_C_N_O_ AS ZTB_NUMREG "
cQuery += "FROM " + RetSqlName( "ZTB" ) + " ZTB "
cQuery += "WHERE ZTB_FILIAL = '" + xFilial( "ZTB" ) + "' "
cQuery += "AND ZTB_STATUS = '2' "
cQuery += "AND ZTB_STATU1 IN ( '1', '3' ) "
cQuery += "AND ZTB.D_E_L_E_T_ = ' ' "
cQuery += "ORDER BY ZTB_EMAIL, ZTB_COD_AL "

cQuery := ChangeQuery(cQuery)

If Select( cAliasQry ) > 0
	dbSelectArea( cAliasQry )
	( cAliasQry )->( dbCloseArea() )
Endif

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasQry, .F., .T.)
TcSetField( cAliasQry, 	"ZTB_NUMREG", 	"N", 	10,	00 )

If ( cAliasQry )->( !Eof() )
	lRet := .T.
Endif

If Select( cAliasQry ) > 0
	dbSelectArea( cAliasQry )
	( cAliasQry )->( dbCloseArea() )
Endif

Return lRet




User Function FSMakeDir(cOrigem)
Local cRet 		:= Alltrim(cOrigem)
Local nPOs		:= 0
Local cDir		:= ""
Local cTrab		:= ""
Local cDrive	:= ""
Local lDisco	:= .F.
Local aPath		:= {}

If Right(cRet,1) <> "\"
	cRet += "\"
Endif

cTrab := cRet

//drive
nPos := at(":\",cRet)
If nPos > 0
	cDrive := left(cRet, nPos+1)
	cRet := Substr(cRet, nPos+2)
	lDisco := .T.
Endif

If !lDisco
	//drive
	nPos := at("\\",cRet)
	If nPos > 0
		cDrive := left(cRet, nPos+1)
		cRet := Substr(cRet, nPos+2)
		lDisco := .T.
		nPos := at("\",cRet)
		If nPos > 0
			cDrive += left(cRet, nPos-1)
			cRet := Substr(cRet, nPos+1)
		Endif
		If right(cDrive,1) <> "\"
			cDrive += "\"
		Endif
	Endif
Endif

While len(cRet) > 0  .and. lDisco
	
	cDir := ""
	nPos := at("\",cRet)
	If nPos <> 0
		If nPos <> 1
			If substr(cRet, nPos-1,1) <> ":"
				cDir := left(cRet, nPos -1 )
				cRet := Substr(cRet, nPos+1)
			Else
				cRet := Substr(cRet, nPos+1)
			Endif
		Else
			cRet := Substr(cRet,2)
		Endif
	Else
		cDir := cRet
		cRet := ""
	Endif
	If !Empty(cDir)
		aadd(aPath, cDir)
	Endif
End
cRet := cDrive
For nPos := 1 to len(aPath)
	cRet += aPath[nPos]
	MakeDir( cRet)
	cRet += "\"
Next
cRet := cTrab
Return(cRet)



User Function GRDA017(cAlias, nReg, nOpc)
local aAreaSAv			:= GetArea()

dbSelectArea( cAlias )
dbGoto( nReg )

If Alltrim(Upper( cAlias )) == "ZTB"
	
	If (ZTB->ZTB_STATUS == "2" .and. ZTB->ZTB_STATU1 == "1" ) .or. (ZTB->ZTB_STATUS == "2" .and. ZTB->ZTB_STATU1 == "3" )
		RecLock( "ZTB", .F. )
		ZTB->ZTB_STATU1	:= "2"
		ZTB->ZTB_DTENVI	:= dDataBase
		ZTB->( MsUnlock() )
		ApMsgInfo( "email de " + Alltrim( ZTB->ZTB_EMAIL ) + " marcado como enviado!", "Marcar como enviado" )
	Else
		ApMsgAlert( "Este registro n? pode ter seu status modificado, somente emails aguardando envio podem ter seu status trocado!", "Marcar como enviado" )
	Endif
	
Endif

RestArea( aAreaSav )
Return Nil



User Function GRDA018(cAlias, nReg, nOpc)
local aAreaSAv			:= GetArea()
Local cLocalSpool		:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )
Local cNomFile1		:= ""

dbSelectArea( cAlias )
dbGoto( nReg )

If Right( cLocalSpool, 1 ) <> "\"
	cLocalSpool += "\"
Endif

If Alltrim(Upper( cAlias )) == "ZTB"
	
	If (ZTB->ZTB_STATUS == "2" .and. ZTB->ZTB_STATU1 == "2" )
		cNomFile1 := Alltrim( ZTB->ZTB_ARQUI )
		If File( cLocalSpool + cNomFile1 )
			
			RecLock( "ZTB", .F. )
			ZTB->ZTB_STATU1	:= "1"
			ZTB->ZTB_DTENVI	:= cTod( " " )
			ZTB->( MsUnlock() )
			ApMsgInfo( "email de " + Alltrim( ZTB->ZTB_EMAIL ) + " marcado como pendente de envio!", "Marcar como pendente" )
		Else
			ApMsgAlert( "Este registro n? pode ter seu status modificado, o arquivo PDF com o boleto n? foi localizado!", "Marcar como pendente" )
		Endif
	Else
		ApMsgAlert( "Este registro n? pode ter seu status modificado, somente emails enviados podem ser marcados como n? enviados!", "Marcar como pendente" )
	Endif
	
Endif

RestArea( aAreaSav )
Return Nil
#Include "PROTHEUS.CH"


User Function GRDA010()
Local aCores := { 	{ "ZTB->ZTB_STATUS == '1'"										, "BR_AMARELO"		},;  //a Processar
{ "ZTB->ZTB_STATUS == '2'.and.ZTB->ZTB_STATU1 == '1'"	, "BR_AZUL"			},;  //Aguardando envio
{ "ZTB->ZTB_STATUS == '2'.and.ZTB->ZTB_STATU1 == '2'"	, "BR_VERDE"    	},;  //Enviado
{ "ZTB->ZTB_STATUS == '2'.and.ZTB->ZTB_STATU1 == '4'"	, "BR_PRETO"    	},;  //Veracross
{ "ZTB->ZTB_STATUS <> '1'.and.ZTB->ZTB_STATUS <> '2'"	, "BR_VERMELHO" 	} }  //Com Erro

Private cCadastro := "Controle de boletos Graded"

Private aRotina   := MenuDef() //Implementa menu funcional


//?Endereca a funcao de BROWSE                                           ?
dbSelectArea("ZTB")
mBrowse( 6,1,22,75,"ZTB",,,,,,aCores)

//?Devolve os indices padroes do SIGA.                                   ?
RetIndex("ZTB")

Return Nil


Static Function MenuDef()
Local aRotina	:= {	{ "Pesquisar" 						, "AxPesqui"   ,0,1		},;		//"Pesquisar"
{ "Visualizar"						, "AxVisual"	,0,2		},;		//"Visualizar"
{ "Gerar Boletos"					, "U_GRDA012"	,0,3		},;		//"Gerar boletos"
{ "Enviar boletos pendentes"	, "U_GRDA013"	,0,4		},;		//"Enviar Pendentes"
{ "Marcar como enviado"			, "U_GRDA017"	,0,4		},;		//"Relatorio"
{ "Marcar como pendente"		, "U_GRDA018"	,0,4		},;		//"Relatorio"
{ "Limpeza de base"				, "U_GRDA016"	,0,4		},;		//"Limpeza"
{ "Legenda"							, "U_GRDA011"	,0,4		}}			//"Legenda"


Return aRotina





User Function GRDA011(cAlias, nReg, nOpc)
Local aLegenda := {	{"BR_AMARELO"    	,"Nao Gerado"  },;
{"BR_AZUL"    		,"Gerado"  		},;
{"BR_VERDE"   		,"Enviado"		},;
{"BR_PRETO"   		,"VeraCross"	},;
{"BR_VERMELHO"		,"Pendente"    }}

BrwLegenda( cCadastro, "Legenda", aLegenda)

Return Nil



User Function GRDA012(cAlias, nReg, nOpc)
Local cPerg			:= 'GRD010'
Local cUserMail	:= ""
Local cemailSent	:= ""
Local cSenhaMail	:= ""
Local aUsuario		:= {}
Local cMsg			:= ""
Local lOk			:= .F.

/*
lVeracros	:= MV_PAR10 == 1
lAutomatico := MV_PAR13 == 1
*/

mBrchgLoop(.F.)

lOk := ChecaPend()

If lOk
	
	If !ApmsgYesNo( "Existem e-mails pendentes de envio, se continuar com a gera o, estes e-mails ser? perdidos, confirma a nova gera o?", "E-mails n? enviados" )
		Return Nil
	Endif
	
Endif

Ajustaperg( cPerg )
If Pergunte( cPerg, .T. )
	
	MsgRun( "Limpeza da base de dados", "Aguarde...", { || LimpaBas( {.T., .T., .T., .T., .T.} ) } )
	
	If MV_PAR10 <> 1 .and. MV_PAR13 == 1
		aUsuario := GetUsermail()
		If len(aUsuario) == 3
			cUserMail 	:= aUsuario[1]
			cemailSent 	:= aUsuario[2]
			cSenhaMail	:= aUsuario[3]
			
			MsgRun( "Gerando emails....", "Aguarde...", { || ProcGera( cAlias, nReg, nOpc, cPerg, cUserMail, cEmailSent, cSenhaMail ) } )
		Else
			ApMsgAlert( "Operacao de envio de e-mail abortada", "Envio" )
		Endif
	ElseIf MV_PAR10 == 1 .or. ( MV_PAR10 <> 1 .and. MV_PAR13 <> 1 )
		IF MV_PAR10 == 1
			cMsg := "Gerando PDFs..."
		Else
			cMsg := "Gerando emails..."
		Endif
		MsgRun( cMsg, "Aguarde...", { || ProcGera( cAlias, nReg, nOpc, cPerg, cUserMail, cEmailSent, cSenhaMail ) } )
	Endif
	
Endif

Return Nil




Static Function ProcGera(cAlias, nReg, nOpc, cPerg, cUserMail, cEmailSent, cSenhaMail )
Local cBanco
Local cAgencia
Local cConta
Local cLText1
Local cLText2
Local cLText3
Local lBaixados
Local cAnoRef
Local cMesRef
Local cTitIni
Local cTitFim
Local cEtiqueta
Local cEmailUni
Local cCliIni
Local cLojaIni
Local cCliFim
Local cLojafim
Local lAglutina
Local lVeraCros
Local cEmailIni
Local cEmailFim
Local aFilesDel		:= {}
Local cLocalSpool		:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )
Local cMsg				:= ""

Default cPerg			:= 'GRD010'

mBrchgLoop(.F.)
Pergunte( cPerg, .F. )
If Right( cLocalSpool, 1 ) <> "\"
	cLocalSpool += "\"
Endif

AtuMailE1( MV_PAR11 )

If MV_PAR13 == 1   // Envia e-mail automatico
	aFilesDel := Directory(cLocalSpool+"*.*", "D")
	For i := 1 to len(aFilesDel)
		if len(aFilesDel[i][1]) > 3
			Ferase(cLocalSpool + aFilesDel[i][1])
		endif
	Next i
End If

cBanco		:= MV_PAR01
cAgencia		:= MV_PAR02
cConta		:= MV_PAR03
cLText1		:= MV_PAR18
cLText2		:= MV_PAR19
cLText3		:= MV_PAR20
lBaixados	:= MV_PAR17 == 1
cAnoRef		:= Right( MV_PAR11, 4 )
cMesRef		:= Left( MV_PAR11, 2 )
cTitIni		:= MV_PAR04
cTitFim		:= MV_PAR05
cEtiqueta	:= "  "
cEmailUni	:= MV_PAR14
cCliIni		:= MV_PAR06		//MV_PAR06
cLojaIni		:= MV_PAR08		//MV_PAR07
cCliFim		:= MV_PAR07		//MV_PAR08
cLojafim		:= MV_PAR09		//MV_PAR09
lAglutina	:= MV_PAR10 == 2
lVeracros	:= MV_PAR10 == 1
cEmailIni	:= Alltrim( MV_PAR15 )
cEmailFim	:= Alltrim( MV_PAR16 )
lAutomatico := MV_PAR13 == 1

If lVeracros
	cMsg := "Foi selecionada a op o VERACROSS igual a 'SIM'." + CRLF
	cMsg += "Nesse caso os arquivos PDF ser? criados, porem" + CRLF
	cMsg += "nenhum email ser?enviado." + CRLF
	ApMsgInfo( cMsg, "Aviso VERACROSS" )
Endif

If !lVeracros .and. lAutomatico
	If ApMsgYesNo( "Foi selecionado o envio automatico dos emails ap? a gera o, confirma?", "Envio Automatico" )
		GeraBol( cBanco, cAgencia, cConta, cLText1, cLText2, cLText3, lBaixados, cAnoRef, cMesRef, cTitIni, ;
		cTitFim, cEtiqueta, cEmailUni, cCliIni, cLojaIni, cCliFim, cLojafim, lAglutina, cEmailIni, ;
		cEmailFim, lAutomatico, lVeraCros, cUserMail, cEmailSent, cSenhaMail )
	Endif
ElseIf lVeracros .or. !lAutomatico
	GeraBol( cBanco, cAgencia, cConta, cLText1, cLText2, cLText3, lBaixados, cAnoRef, cMesRef, cTitIni, ;
	cTitFim, cEtiqueta, cEmailUni, cCliIni, cLojaIni, cCliFim, cLojafim, lAglutina, cEmailIni, ;
	cEmailFim, lAutomatico, lVeraCros, cUserMail, cEmailSent, cSenhaMail )
Endif

MsgRun( "Limpeza da base de dados", "Aguarde...", { || LimpaBas( {.F., .F., .T., .F., .F.} ) } )

Return Nil



Static Function AjustaPerg( cPerg )
Local aHelpSpa	:= {}
Local aHelpPor	:= {}
Local aHelpEng	:= {}
Local aArea	  	:= GetArea()
Local cKey	  	:= ""

Aadd(aHelpPor,'Codigo do Banco')
PutSx1( cPerg, "01","Banco            ? ","","","mv_ch1","C",003,0,0,"G","","SA6","","","mv_par01","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Agencia')
PutSx1( cPerg, "02","Agencia          ? ","","","mv_ch2","C",005,0,0,"G","","","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Conta corrente')
PutSx1( cPerg, "03","Conta            ? ","","","mv_ch3","C",012,0,0,"G","","","","","mv_par03","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Titulo Inicial')
PutSx1( cPerg, "04","Do Titulo        ? ","","","mv_ch4","C",009,0,0,"G","","SE1","","","mv_par04","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Titulo Final')
PutSx1( cPerg, "05","At?Titulo       ? ","","","mv_ch5","C",009,0,0,"G","","SE1","","","mv_par05","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Aluno inicial')
PutSx1( cPerg, "06","Do Aluno         ? ","","","mv_ch6","C",006,0,0,"G","","SA1","","","mv_par06","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Aluno Final')
PutSx1( cPerg, "07","At?aluno        ? ","","","mv_ch7","C",006,0,0,"G","","SA1","","","mv_par07","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Loja inicial')
PutSx1( cPerg, "08","Loja De          ? ","","","mv_ch8","C",002,0,0,"G","","","","","mv_par08","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Loja final')
PutSx1( cPerg, "09","Loja Ate         ? ","","","mv_ch9","C",002,0,0,"G","","","","","mv_par09","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'PDF VeraCross')
PutSx1( cPerg, "10","PDF Veracross    ? ","","","mv_cha","N",001,0,0,"C","","","","","MV_PAR10","Sim","Sim","Sim","","N?","N?","N?","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Mes e ano no formato MMAAAA')
PutSx1( cPerg, "11","Mes e Ano        ? ","","","mv_chb","C",006,0,0,"G","","","","","MV_PAR11","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Seleciona aluno')
PutSx1( cPerg, "12","Seleciona Aluno  ? ","","","mv_chc","N",001,0,0,"C","","","","","MV_PAR12","Sim","Sim","Sim","","N?","N?","N?","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Envia Automaticamente')
PutSx1( cPerg, "13","envia automatico ? ","","","mv_chd","N",001,0,0,"C","","","","","MV_PAR13","Sim","Sim","Sim","","N?","N?","N?","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Filtra e-mail')
PutSx1( cPerg, "14","Filtra e-mail    ? ","","","mv_che","C",090,0,0,"G","","","","","MV_PAR14","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'e-mail inicial')
PutSx1( cPerg, "15","Do e-mail        ? ","","","mv_chf","C",090,0,0,"G","","","","","MV_PAR15","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'e-mail final')
PutSx1( cPerg, "16","At?e-mail       ? ","","","mv_chg","C",090,0,0,"G","","","","","MV_PAR16","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Gerar Boletos para titulos ja baixados')
PutSx1( cPerg, "17","Emite j?baixados? ","","","mv_chh","N",001,0,0,"C","","","","","MV_PAR17","Sim","Sim","Sim","","N?","N?","N?","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Linha 1 de texto para boleto')
PutSx1( cPerg, "18","Linha 1          ? ","","","mv_chi","C",045,0,0,"G","","","","","MV_PAR18","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Linha 2 de texto para boleto')
PutSx1( cPerg, "19","Linha 2          ? ","","","mv_chj","C",045,0,0,"G","","","","","MV_PAR19","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )

Aadd(aHelpPor,'Linha 3 de texto para boleto')
PutSx1( cPerg, "20","Linha 3          ? ","","","mv_chk","C",045,0,0,"G","","","","","MV_PAR20","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa )


RestArea(aArea)

Return Nil



Static Function makescr(cAliasNew, dDataIni, dDataFim)
Local oDlg
Local cCadastro		:= "Sele o de alunos"
Local aSize 			:= MsAdvSize()
Local aInfo 			:= {aSize[1],aSize[2],aSize[3],aSize[4],3,3}
Local oPanelUp
Local oPanelDown
Local oPanel1
Local oPanel2
Local aResult			:= {}
Local oListBox1
Local aListBox1		:= {}
Local nOpca 			:= 0
Local aAreaSav			:= GetArea()
Local oCheck
Local lCheck

Default dDataini		:= dDataBase - 5
Default dDataFim		:= dDataBase

DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],aSize[1] To aSize[6],aSize[5] OF oMainWnd PIXEL
oFWLayer := FWLayer():New()
oFWLayer:Init( oDlg, .F., .T. )
oFWLayer:AddLine( 'PRIMEIRO' , 14, .T. )                     // Cria uma "linha" com 25% da tela
oFWLayer:AddLine( 'SEGUNDO', 85, .F. )                       // Cria uma "linha" com 25% da tela
oPanelUp   		:= oFWLayer:GetlinePanel( 'PRIMEIRO'  )
oPanelDown 		:= oFWLayer:GetlinePanel( 'SEGUNDO' )

@ 000, 000 MSPANEL oPanel1 SIZE 000, 015 OF oPanelUp //COLORS 0, 16777215 RAISED
oPanel1:align:=CONTROL_ALIGN_ALLCLIENT

@ 000, 000 MSPANEL oPanel2 SIZE  000, 015 OF oPanelDown //COLORS 0, 16777215 RAISED
oPanel2:align:=CONTROL_ALIGN_ALLCLIENT

@ 005, 005 Say "Selecionando alunos para gera o de boletos "  	SIZE 210,08 	PIXEL OF oPanel1
@ 020, 005 CHECKBOX oCheck VAR lCheck PROMPT "Marca / Desmarca todos ?" SIZE 100,010 ON CLICK( Verchk(oListBox1,aListBox1,lCheck) , oCheck:Refresh() ) OF oPanel1 PIXEL

fListBox1( oPanel2, aResult, @oListBox1, aListBox1, cAliasNew )

ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{||nOpcA:=1,oDlg:End()},{||oDlg:End()})

If nOpca == 1
	aResult := aClone( aListBox1 )
Endif

aListBox1 := {}

RestArea( aAreaSav )
mBrchgLoop(.F.)

Return aResult



Static Function fListBox1( oScreen, aResult, oListBox1, aListBox1, cAliasNew )
Local aHead			:= {}

// carrega o array da listbox
aListBox1 := LoadLst1( @aHead, aResult, cAliasNew )

@ 016, 005 ListBox oListBox1 Fields ;
HEADER "" Size 381, 173 Of oScreen Pixel ColSizes 0

oListBox1:align:=CONTROL_ALIGN_ALLCLIENT

SetLst1(oListBox1, aListBox1, aHead) // atualiza o vetor da listbox

oListBox1:BlDblClick := { || aListBox1[oListBox1:nAt, 1] := !aListBox1[oListBox1:nAt, 1], oListBox1:Refresh() }

Return Nil



// ?escricao  ?carga da listbox1                                            
Static Function LoadLst1( aHead, aResult, cAliasNew )
Local aRet 			:= {}
Local nXa			:= 0
Local nJ			:= 0
Local aTmp			:= {}
Local xTmp

dbSelectArea( cAliasNew )
(cAliasNew)->( dbGotop() )

While (cAliasNew)->( !eof() )
	SA1->( DbSetOrder(1) )
	SA1->( DbSeek( xFilial("SA1") + (cAliasNew)->(E1_CLIENTE + E1_LOJA ) ) )
	
	aTmp := {}
	aadd( aTmp, .F. )
	aadd( aTmp, (cAliasNew)->E1_CLIENTE )
	aadd( aTmp, (cAliasNew)->E1_LOJA )
	aadd( aTmp, SA1->A1_NOME )
	aadd( aTmp, (cAliasNew)->E1_PREFIXO )
	aadd( aTmp, (cAliasNew)->E1_NUM )
	aadd( aTmp, (cAliasNew)->E1_TIPO )
	aadd( aTmp, (cAliasNew)->E1_EMAIL2)
	aadd( aTmp, (cAliasNew)->E1_EMAIL3 )
	aadd( aTmp, (cAliasNew)->E1_EMAIL4 )
	
	aadd( aResult, aClone( aTmp ) )
	
	(cAliasNew)->( dbSkip() )
End

aHead := {}

aadd(ahead, {" ", 				"020", "L"})
aadd(ahead, {"Cod.Aluno", 		"055", "C"})
aadd(ahead, {"Loja", 			"045", "C"})
aadd(aHead, {"Nome Aluno", 		"080", "C"})

aadd(aHead, {"Pref.",			"045", "C"})
aadd(aHead, {"Numero", 			"070", "C"})
aadd(aHead, {"Tipo",			"045", "C"})

aadd(aHead, {"e-mail 2",		"080", "C"})
aadd(aHead, {"e-mail 3", 		"080", "C"})
aadd(aHead, {"e-mail 4",		"080", "C"})

For nXa := 1 to len( aResult )
	aTmp := {}
	For nJ := 1 to len( aResult[nXa] )
		Aadd( aTmp, aResult[nXa][nJ] )
	Next nJ
	aadd( aRet, aClone( aTmp ) )
	aTmp := {}
Next nXa

aResult := Nil

dbSelectArea( cAliasNew )
(cAliasNew)->( dbGotop() )

// verifica se o array de retorno esta vazio e providencia um retorno
If Len(aRet) < 1
	aTmp := {}
	For nXa := 1 to len(aHead)
		IF aHead[nXa][3] == "N"
			xTmp := 0.00
		Elseif aHead[nXa][3] == "D"
			xTmp := cTod(" ")
		Elseif aHead[nXa][3] == "L"
			xTmp := .F.
		Else
			xTmp := " "
		Endif
		aadd( aTmp, xTmp)
	next nXa
	aadd( aTmp, ' ')
	aadd(aRet, aTmp)
Endif

Return aRet



//Descricao  Refresh da listbox 1                                         
Static Function SetLst1(oLbx, aLbx, aHead)
Local aHead1		:= {}
Local aCols1		:= {}
Local nXa			:= 0
Local cPrefix 		:= '"'
Local cPrefix1 		:= ''
Local oOk	 		:= LoadBitmap(GetResources(),'LBOK')
Local oNo			:= LoadBitmap(GetResources(),'LBNO')
Local nSav			:= 0

Default aHead		:= {}

Private cVar		:= ""
Private cVar1		:= ""

If Len( aHead ) > 0
	//Monta o header da listbox e o tamanho das colunas
	cVar 		:= ""
	cVar1 	:= ""
	For nXa := 1 to len(aHead)
		cVar 		+= cPrefix + aHead[nXa][1]  + '"'
		cVar1 	+= cPrefix1 + aHead[nXa][2]
		cPrefix 	:= ',"'
		cPrefix1 := ','
		
		aadd(aHead1, aHead[nXa][1])
		aadd(aCols1, Val(aHead[nXa][2]))
	next nXa
	
	oLbx:aHeaders 	:= aHead1
	oLbx:aColSizes := aCols1
	
Endif

oLbx:SetArray(aLbx)
oLbx:nAt := 1

// Cria ExecBlocks das ListBoxes
oLbx:bLine 		:= {|| {;
Iif( aLbx[oLbx:nAT,01], oOk, oNo ),;
aLbx[oLbx:nAT,02],;
aLbx[oLbx:nAT,03],;
aLbx[oLbx:nAT,04],;
aLbx[oLbx:nAT,05],;
aLbx[oLbx:nAT,06],;
aLbx[oLbx:nAT,07],;
aLbx[oLbx:nAT,08],;
aLbx[oLbx:nAT,09] }}


oLbx:refresh()

Return Nil



/*============================================================================================================================================================
Fun o     : AtuMailE1
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade : Busca o e-mail do cadastro do cliente e atualiza no contas a receber.
============================================================================================================================================================*/

Static Function AtuMailE1( cMesAno )
Local cQuery 		:= ""
Local cAliasQry		:= getNextAlias()
Local aAreaSav		:= GetArea()
Local cMesEmi		:= ""
Local cAnoEmi		:= ""

Default cMesAno		:= StrZero(Month(dDataBase), 2) + StrZero(Year(dDataBase), 4)
cMesEmi := left( cMesAno, 2 )
cAnoEmi	:= Right( cMesAno,4 )


///*BEGINDOC
//?ten o os e-mails parecem estar errados porem foi mantido?
//?esta forma devido aos indices customizados no SE1.       ?
//?o cadastro de alunos o EMAIL 2 que aparece no cadastro,  ?
//?a verdade ?o campo A1_EMAIL1 por isso esta sendo        ?
//?opiado no E1_EMAIL2 e assim por diante para os demais    ?
//?ampos de emails.                                         ?
//ENDDOC*/

cQuery := "SELECT E1_EMISSAO, E1_CLIENTE, E1_LOJA, E1_EMAIL2, E1_EMAIL3, E1_EMAIL4, R_E_C_N_O_ AS SE1RECNO "
cQuery += "  FROM "+	RetSqlName("SE1")
cQuery += " WHERE substring(E1_PREFIXO,1,1) = 'F' "
cQuery += " AND E1_FILIAL = '" + xFilial("SE1") + "' "
cQuery += " AND E1_CLIENTE >= '"+  MV_PAR06 + "' AND E1_CLIENTE <= '" + MV_PAR07 + "' "
cQuery += " AND E1_LOJA >= '" + MV_PAR08 + "' AND E1_LOJA <= '" + MV_PAR09 + "' "
If MV_PAR17 <> 1 // nao
	cQuery += " AND E1_SALDO > 0 "
Endif
cQuery += " AND E1_EMISSAO LIKE '" + cAnoEmi + cMesEmi + "%' "
cQuery += " AND (E1_PREFIXO + E1_NUM >= '" + MV_PAR04 + "' AND E1_PREFIXO + E1_NUM <= '" +MV_PAR05 + "' ) "
cQuery += " AND D_E_L_E_T_ = ' ' "

If Select( cAliasQry ) > 0
	(cAliasQry)->(dbCloseArea())
Endif

cQuery := ChangeQuery(cQuery)

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasQry, .F., .T.)
tcSetField(cAliasQry, "SE1RECNO", "N", 10, 00 )

DbSelectArea(cAliasQry)
(cAliasQry)->( DBGoTop() )

While (cAliasQry)->(!EOF())
	
	If !Empty(cMesAno)
		If substr((cAliasQry)->E1_EMISSAO,5,2) <> cMesEmi .Or. substr((cAliasQry)->E1_EMISSAO,1,4) <> cAnoEmi
			(cAliasQry)->( DbSkip() )
			Loop
		End If
	Else
		Exit
	End If
	
	SA1->( DbSetOrder(1) )
	SA1->( DbSeek( xFilial("SA1") + (cAliasQry)->( E1_CLIENTE + E1_LOJA ) ) )
	
	If Alltrim( (cAliasQry)->E1_EMAIL2 ) <> alltrim( SA1->A1_EMAIL1 )
		SE1->( DbGoTo( (cAliasQry)->SE1RECNO ) )
		Reclock("SE1",.F.)
		SE1->E1_EMAIL2 := SA1->A1_EMAIL1
		SE1->(MsUnlock())
	End If
	
	If Alltrim( (cAliasQry)->E1_EMAIL3 ) <> Alltrim( SA1->A1_EMAIL2 )
		SE1->( DbGoTo( (cAliasQry)->SE1RECNO ) )
		Reclock("SE1",.F.)
		SE1->E1_EMAIL3 := SA1->A1_EMAIL2
		SE1->( MsUnlock() )
	End If
	
	If Alltrim( (cAliasQry)->E1_EMAIL4 ) <> alltrim( SA1->A1_EMAIL3 )
		SE1->( DbGoTo( (cAliasQry)->SE1RECNO ) )
		Reclock("SE1",.F.)
		SE1->E1_EMAIL4 := SA1->A1_EMAIL3
		SE1->(MsUnlock())
	End If
	
	(cAliasQry)->(DbSkip())
End

If Select( cAliasQry ) > 0
	(cAliasQry)->(dbCloseArea())
Endif

RestArea( aAreasav )

Return Nil




Static  Function GeraBol( cBanco, cAgencia, cConta, cLText1, cLText2, cLText3, lBaixados, cAnoRef, cMesRef, cTitIni, ;
cTitFim, cEtiqueta, cEmailUni, cCliIni, cLojaIni, cCliFim, cLojafim, lAglutina, cEmailIni, cEmailFim, lAutomatico, ;
lVeraCros, cUserMail, cEmailSent, cSenhaMail )

Local n 					:= 0
Local aBitmap			:= {		"" ,; 								//Banner publicit?io
"\Bitmaps\Logo_Siga.bmp"      }  	//Logo da empresa
Local cAnoMes	   	:= ""
Local aDadosEmp		:= {	SM0->M0_NOMECOM                                    								,; 		//Nome da Empresa
SM0->M0_ENDCOB                                                            	,; 		//Endere?
AllTrim(SM0->M0_BAIRCOB)+", "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB 	,; 		//Complemento
"CEP: "+Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)             	,; 		//CEP
"PABX/FAX: "+SM0->M0_TEL                                                  	,; 		//Telefones
"C.G.C.: "+Subs(SM0->M0_CGC,1,2)+"."+Subs(SM0->M0_CGC,3,3)+"."+             ;
Subs(SM0->M0_CGC,6,3)+"/"+Subs(SM0->M0_CGC,9,4)+"-"+Subs(SM0->M0_CGC,13,2) ,; 		//CGC                                                   ,; //CGC
"I.E.: "+Subs(SM0->M0_INSC,1,3)+"."+Subs(SM0->M0_INSC,4,3)+"."+          	 ;
Subs(SM0->M0_INSC,7,3)+"."+Subs(SM0->M0_INSC,10,3)                        	 }  		//I.E
Local aDadosTit		:= {}
Local cQuery 			:= ""
Local aDadosBanco 	:= {}
Local aDatSacado		:= {}
Local aBolText     	:= {}
Local _nVlrDesc 		:= 0
Local _nVlrJuro 		:= 0
Local aBMP      		:= aBitMap
Local i         		:= 1
Local CB_RN_NN  		:= {}
Local nRec      		:= 0
Local _nVlrAbat 		:= 0
Local dDtIni 			:= dDatabase-60
Local dDtFim 			:= dDatabase
Local lPrev 			:= .T.
Local cZgDoc 			:= ""
Local lFound 			:= .F.
Local cMail				:= ""
Local cSacNom 			:= ""
Local cRefere			:= ""
Local cAliasQry		:= GetNextAlias()
Local cName				:= ""
Local cNomFile1		:= ""
Local cNomFile2		:= ""
Local aRegGer			:= {}
Local nX					:= 0
Local nRegSav			:= 0
Local cBusca			:= ""
Local LPREVIEW			:= .F.
Local cLocalSpool		:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )
Local aSelect			:= {}
Local cReferAnt		:= ""
Local cEnviado			:= "1"
Local cEmailFix		:= Alltrim(GetMv("MV_SZPREC1"))

Default cBanco			:= ""
Default cAgencia		:= ""
Default cConta			:= ""
Default cLText1		:= ""
Default cLText2		:= ""
Default cLText3		:= ""
Default lBaixados		:= .F.
Default cAnoRef		:= ""
Default	cMesRef		:= ""
Default cTitIni		:= ""
Default cTitFim		:= ""
Default cEmailUni		:= ""
Default cCliIni		:= ""
Default cLojaIni		:= ""
Default cCliFim		:= ""
Default cLojaFim		:= ""
Default lAutomatico	:= .F.
Default lVeraCros		:= .F.

Private cDoc
Private aTam1 			:= {}
Private oPrint
Private lMudaNome 	:= .F.
Private aArrayMails 	:= {}
Private aMens 			:= {}

Private aNossoNum		:= {}
Private cNossoNum 	:= ''
Private cnNumero  	:= ''

Private cCCedente		:= "6524915"
Private cCarteira		:= '101'

Private cSacNom := ""
Private cSacEnd := ""
Private cSacCep := ""
Private cSacMun := ""
Private cSacEst := ""
Private cDesNom := ""
Private cDesEnd := ""
Private cDesCep := ""
Private cDesMun := ""
Private cDesEst := ""
Private cDesCon := ""
Private cSacCGC := ""

If Right( cLocalSpool, 1 ) <> "\"
	cLocalSpool += "\"
Endif

cAnoRef 				:= Padl( cAnoRef, 4, '0' )
cMesRef				:= padl( cMesRef, 2, "0" )
aBolText     		:= { cLText1, cLText2, cLText3 }
cRefere 				:= cAnoRef+cMesRef
cAnoMes				:= cAnoRef + cMesRef

dbSelectArea( "SZD" )
SZD->(DbSetOrder(1))

SZD->(DbSeek(xFIlial("SZD")+"000001"))
nValor1 := SZD->ZD_VALOR

SZD->(DbSeek(xFIlial("SZD")+"000004"))
nValor2 := SZD->ZD_VALOR

SZD->(DbSeek(xFIlial("SZD")+"000006"))
nValor3 := SZD->ZD_VALOR

SZD->(DbSeek(xFIlial("SZD")+"000013"))
nValor4 := SZD->ZD_VALOR

SZD->(DbSeek(xFIlial("SZD")+"000014"))
nValor5 := SZD->ZD_VALOR

SZD->(DbSeek(xFIlial("SZD")+"000017"))
nValor6 := SZD->ZD_VALOR

aMens := {	{ "Preprimary half day program (K2AM / K2PM /K3PM)",	nValor1}	,;
{ "Preprimary half day program (K3AM / K4AM )",			nValor2}	,;
{ "Preprimary full day program ",							nValor3}	,;
{ "Elementary School",											nValor4}	,;
{ "Middle School",												nValor5}	,;
{ "High School",													nValor6}	,;
{ "Transportation",												"Vari?el"	}}

cEnviado := "1"
If lVeraCros
	cEnviado := "2"
Endif

oPrint:= TMSPrinter():New( "Boleto Laser" )  //INSTANCIA O OBJETO

oPrint:Setup()
oPrint:SetPortrait() // ou SetLandscape()
oPrint:StartPage()   // Inicia uma nova p?ina



DbSelectArea("SA6")        //Posiciona o SA6 (Bancos)
DbSetOrder(1)
DbSeek(xFilial("SA6")+cBanco+cAgencia+cConta)

//Posiciona o SEE (Parametros banco)
DbSelectArea("SEE")
DbSetOrder(1)
DbSeek(xFilial("SEE")+cBanco+cAgencia+cConta)

cQuery := "SELECT E1_PREFIXO, E1_NUM, E1_TIPO, E1_PARCELA, E1_CLIENTE, E1_LOJA, E1_EMAIL2, E1_EMAIL3, E1_EMAIL4 "
cQuery += "FROM "+	RetSqlName("SE1") + " "
cQuery += "WHERE E1_FILIAL = '" + xFilial("SE1") + "' "
cQuery += " AND substring(E1_PREFIXO,1,1) = 'F' "
cQuery += " AND E1_CLIENTE >= '"+  cCliIni + "' AND E1_CLIENTE <= '" + cCliFim + "' "
cQuery += " AND E1_LOJA >= '" + cLojaIni + "' AND E1_LOJA <= '" + cLojaFim + "' "
If !lBaixados // nao
	cQuery += " AND E1_SALDO > 0 "
Endif
cQuery += " AND E1_EMISSAO LIKE '" + cRefere + "%' "
cQuery += " AND (E1_PREFIXO + E1_NUM >= '" + cTitIni + "' AND E1_PREFIXO + E1_NUM <= '" + cTitFim + "' ) "
cQuery += " AND D_E_L_E_T_ = ' ' "
cQuery += "ORDER BY E1_EMAIL2, E1_EMAIL3, E1_EMAIL4 "

If Select( cAliasQry ) > 0
	dbSelectArea( cAliasQry )
	( cAliasQry )->( dbCloseArea() )
Endif

cQuery := ChangeQuery(cQuery)
dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasQry, .F., .T.)

DbSelectArea( cAliasQry )
( cAliasQry )->( DBGoTop() )

aRegGer	:= {}


If ( cAliasQry )->( Eof() )
	ApMsgAlert( "Nada foi Selecionado!", "Busca Titulos" )
	If Select( cAliasQry ) > 0
		dbSelectArea( cAliasQry )
		( cAliasQry )->( dbCloseArea() )
	Endif
	Return Nil
Endif

If Len( aArrayMails ) == 0
	
	If MV_PAR12 == 1
		SaveInter()
		aSelect := makescr(cAliasQry, dDtIni, dDtFim )
		RestInter()
	Else
		aSelect := {}
	End If
	
	While ( cAliasQry )->(!EOF())
		
		If ((cAliasQry)->(E1_PREFIXO+Alltrim(E1_NUM))) < cTitIni .Or. ((cAliasQry)->(E1_PREFIXO+Alltrim(E1_NUM))) > cTitFim
			(cAliasQry)->( DbSkip() )
			Loop
		End If
		
		If !Empty( cEmailUni )
			If Empty(cAliasQry->E1_EMAIL2) .and. Empty( cAliasQry->E1_EMAIL3 ) .and. empty( cAliasQry->E1_EMAIL4 )
				cAliasQry->(DbSkip())
				Loop
			End If
		End If
		
		SA1->( DbSetOrder(1) )
		SA1->( DbSeek( xFilial("SA1") + (cAliasQry)->(E1_CLIENTE + E1_LOJA ) ) )
		
		SZC->( DbSetOrder(1) )
		SZC->( DbSeek( xFilial("SZC") + SA1->A1_CODFAM ) )
		
		If cEtiqueta <> " "
			If Alltrim( Upper( SZC->ZC_ETIQ ) ) <> alltrim( Upper( cEtiqueta ) )
				cAliasQry->( DbSkip() )
				Loop
			End If
		End If
		
		If !Empty(cEmailUni)
			If !( alltrim(cEmailUni) == alltrim((cAliasQry)->E1_EMAIL2) .Or. alltrim(cEmailUni) == alltrim((cAliasQry)->E1_EMAIL3) .or.  alltrim(cEmailUni) == alltrim((cAliasQry)->E1_EMAIL4) )
				cAliasQry->(DbSkip())
				Loop
			End If
		EndIf
		
		If MV_PAR12 == 1 .AND. LEN( aSelect ) > 0
			nPos := ascan( aSelect, { |x| x[2] == (cAliasQry)->E1_CLIENTE .and. x[3] ==(cAliasQry)->E1_LOJA  .and. x[5] == (cAliasQry)->E1_PREFIXO .and. x[6] == (cAliasQry)->E1_NUM } )
			If nPos > 0
				if !aSelect[nPos][1]
					(cAliasQry)->( DbSkip() )
					Loop
				Endif
			Endif
		End If
		
		cZgDoc := (cAliasQry)->( E1_PREFIXO + Alltrim(E1_NUM) )  + " RM"
		lFound := .F.
		SZG->( DbSetOrder(2) )
		SZG->( DBSeek( xFilial("SZG") + cZgDoc + ( cAliasQry )->E1_CLIENTE ) )
		while SZG->(!EOF()) .And. SZG->ZG_CODALU == (cAliasQry)->E1_CLIENTE .And. SZG->ZG_DOC == cZgDoc .And. SZG->ZG_MESANO == cMesRef + cAnoRef
			lFound := .T.
			Exit
			SZG->( DbSkip() )
		End
		
		If !lFound
			( cAliasQry )->( DbSkip() )
			Loop
		End If
		
		lFound := .F.
		
		If lAglutina
			
			cCliente		:= Alltrim( ( cAliasQry )->E1_CLIENTE )
			cEmail		:= ( cAliasQry )->E1_EMAIL2
			IF !Empty( cEmail )
				nPos := ascan( aArrayMails, { |x|  Alltrim( x[1] ) == cEmail .and. Alltrim( x[4] ) == cCliente  } )
				If nPos == 0
					AADD( aArrayMails,{ cEmail, ( cAliasQry )->E1_PREFIXO, ( cAliasQry )->E1_NUM, cCliente, ( cAliasQry )->E1_LOJA, ( cAliasQry )->E1_TIPO, ( cAliasQry )->E1_PARCELA, "1", cEnviado, "1" } )
				Endif
			Endif
			
			cCliente		:= Alltrim( ( cAliasQry )->E1_CLIENTE )
			cEmail		:= ( cAliasQry )->E1_EMAIL3
			IF !Empty( cEmail )
				nPos := ascan( aArrayMails, { |x|  Alltrim( x[1] ) == cEmail .and. Alltrim( x[4] ) == cCliente  } )
				If nPos == 0
					AADD( aArrayMails,{ cEmail, ( cAliasQry )->E1_PREFIXO, ( cAliasQry )->E1_NUM, cCliente, ( cAliasQry )->E1_LOJA, ( cAliasQry )->E1_TIPO, ( cAliasQry )->E1_PARCELA, "1", cEnviado, "2" } )
				Endif
			Endif
			
			cCliente		:= Alltrim( ( cAliasQry )->E1_CLIENTE )
			cEmail		:= ( cAliasQry )->E1_EMAIL4
			IF !Empty( cEmail )
				nPos := ascan( aArrayMails, { |x|  Alltrim( x[1] ) == cEmail .and. Alltrim( x[4] ) == cCliente  } )
				If nPos == 0
					AADD( aArrayMails,{ cEmail, ( cAliasQry )->E1_PREFIXO, ( cAliasQry )->E1_NUM, cCliente, ( cAliasQry )->E1_LOJA, ( cAliasQry )->E1_TIPO, ( cAliasQry )->E1_PARCELA, "1", cEnviado, "3" } )
				Endif
			Endif
			
		Else
			
			cCliente		:= Alltrim( ( cAliasQry )->E1_CLIENTE )
			cEmail		:= ( cAliasQry )->E1_EMAIL2
			IF !Empty( cEmail )
				nPos := ascan( aArrayMails, { |x|  Alltrim( x[4] ) == cCliente  } )
				If nPos == 0
					AADD( aArrayMails,{ cEmail, ( cAliasQry )->E1_PREFIXO, ( cAliasQry )->E1_NUM, cCliente, ( cAliasQry )->E1_LOJA, ( cAliasQry )->E1_TIPO, ( cAliasQry )->E1_PARCELA, "1", cEnviado, "1" } )
				Endif
			Endif
			
			cCliente		:= Alltrim( ( cAliasQry )->E1_CLIENTE )
			cEmail		:= ( cAliasQry )->E1_EMAIL3
			IF !Empty( cEmail )
				nPos := ascan( aArrayMails, { |x|  Alltrim( x[4] ) == cCliente  } )
				If nPos == 0
					AADD( aArrayMails,{ cEmail, ( cAliasQry )->E1_PREFIXO, ( cAliasQry )->E1_NUM, cCliente, ( cAliasQry )->E1_LOJA, ( cAliasQry )->E1_TIPO, ( cAliasQry )->E1_PARCELA, "1", cEnviado, "2" } )
				Endif
			Endif
			
			cCliente		:= Alltrim( ( cAliasQry )->E1_CLIENTE )
			cEmail		:= ( cAliasQry )->E1_EMAIL4
			IF !Empty( cEmail )
				nPos := ascan( aArrayMails, { |x|  Alltrim( x[4] ) == cCliente } )
				If nPos == 0
					AADD( aArrayMails,{ cEmail, ( cAliasQry )->E1_PREFIXO, ( cAliasQry )->E1_NUM, cCliente, ( cAliasQry )->E1_LOJA, ( cAliasQry )->E1_TIPO, ( cAliasQry )->E1_PARCELA, "1", cEnviado, "3" } )
				Endif
			Endif
			
		Endif
		
		( cAliasQry )->( DbSkip() )
	End
	
End If

If Select( cAliasQry ) > 0
	dbSelectArea( cAliasQry )
	( cAliasQry )->( dbCloseArea() )
Endif

//Organiza os emails para envio e gera o
aSort(aArrayMails,,,{|x,y| y[1] > x[1]})

IF len(aArrayMails) > 0
	dbSelectArea( "ZTB" )
	dbSetOrder( 2 )
	For i := 1 to Len(aArrayMails)
		cBusca := padr(cMesRef + cAnoRef, TAMSX3("ZTB_REFERE")[1]) + padr(aArrayMails[i][1], TamSX3("ZTB_EMAIL")[1]) + padr(aArrayMails[i][4], TamSX3("ZTB_COD_AL")[1]) + padr(aArrayMails[i][5], TamSX3("ZTB_LOJALU")[1])
		If ZTB->( !dbSeek( xFilial("ZTB") + cBusca ) )
			
			Reclock("ZTB",.T.)
			
			ZTB->ZTB_FILIAL		:= xFilial( "ZTB" )
			ZTB->ZTB_STATUS		:= aArrayMails[i][8]
			ZTB->ZTB_STATU1		:= aArrayMails[i][9]
			ZTB->ZTB_PREFIX 		:= aArrayMails[i][2]
			ZTB->ZTB_NUM 			:= aArrayMails[i][3]
			ZTB->ZTB_COD_AL		:= aArrayMails[i][4]
			ZTB->ZTB_LOJALU 		:= aArrayMails[i][5]
			ZTB->ZTB_EMAIL 		:= aArrayMails[i][1]
			ZTB->ZTB_TIPO 			:= aArrayMails[i][10]
			ZTB->ZTB_TIPTIT		:= aArrayMails[i][6]
			ZTB->ZTB_PARCEL		:= aArrayMails[i][7]
			ZTB->ZTB_CODRES     	:= " "//aArrayMails[i][11]
			ZTB->ZTB_IDUNIQ     	:= GetSx8Num( "ZTB", "ZTB_IDUNIQ" )
			ZTB->ZTB_ARQUI	    	:= " "
			ZTB->ZTB_DTGER      	:= cTod( " " )
			ZTB->ZTB_DTENVI     	:= Iif( cEnviado=="1", ctod( " " ), dDataBase )
			ZTB->ZTB_REFERE		:= cMesRef + cAnoRef
			
			ZTB->( MsUnlock() )
			ConfirmSX8()
			
		Endif
	Next i
	
	DbSelectArea("ZTB")
	ZTB->( dbSetOrder( 2 ) )
	ZTB->( dbSeek( xFilial( "ZTB" ) + cMesRef + cAnoRef ) )
	ZTB->( DbGoTop() )
	
	While ZTB->(!EOF()) .and. ( ZTB->ZTB_FILIAL == xFilial( "ZTB" ) .and. ZTB->ZTB_REFERE == cMesRef + cAnoRef )
		
		IF ZTB->ZTB_STATUS <> "1"
			ZTB->( dbSkip() )
			Loop
		Endif
		
		DbSelectArea("SE1")
		If ZTB->ZTB_TIPO == "1"
			//DbSetOrder(21)
			SE1->(DBOrderNickName("SE1ALEM2"))
			cMail := "1"
		ElseIf ZTB->ZTB_TIPO == "2"
			//DbSetOrder(22)
			SE1->(DBOrderNickName("SE1ALEM3"))
			cMail := "2"
		Else
			//DbSetOrder(23)
			SE1->(DBOrderNickName("SE1ALEM4"))
			cMail := "3"
		End If
		
		DbSeek( xFilial("SE1") + ZTB->ZTB_COD_AL + ZTB->ZTB_LOJALU + ZTB->ZTB_PREFIX + ZTB->ZTB_NUM + ZTB->ZTB_EMAIL )
		
		cDoc 		:= Substr(SE1->E1_PREFIXO,2,2)+alltrim(SE1->E1_NUM)
		cnNumero := SE1->E1_NUMBCO   // Nosso numero que foi calculo quando foi gerado o CNAB
		
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek( xFilial("SA1")+ SE1->E1_CLIENTE + SE1->E1_LOJA )
		
		SZC->( DbSeek( xFilial("SZC") + SA1->A1_CODFAM ) )
		
		SZB->( DbSeek( xFilial("SZB") + SZC->ZC_CODEMP ) )
		
		//?efine o Sacado e Destinatario?
		
		If Empty( SZC->ZC_ETIQ )
			ApMsgStop("O Cadastro da fam?ia "+SA1->A1_CODFAM+" est?sem o n?ero da etiqueta. Esta gera o de boleto dar?erro.", "Aviso")
		EndIf
		
		If SZC->ZC_ETIQ == "1"
			cSacNom := SZC->ZC_NOME
			cSacEnd := SZC->ZC_ENDFAM
			cSacCep := Transform(SZC->ZC_CEP,"@r 99999-999")
			cSacMun := SZC->ZC_CIDADE
			cSacEst := SZC->ZC_ESTADO
			cDesNom := SZB->ZB_NOME
			cDesEnd := SZB->ZB_ENDEMP
			cDesCep := Transform(SZB->ZB_CEP,"@R 99999-999")
			cDesMun := SZB->ZB_CIDADE
			cDesEst := SZB->ZB_ESTADO
			cDesCon := SZB->ZB_CONTATO
			cSacCGC := SZC->ZC_CGC
		ElseIf SZC->ZC_ETIQ == "2"
			If len(alltrim(SZC->ZC_ENDFAM)) < 5 .Or. SZC->ZC_CEP == "00000000" .Or. Empty(SZC->ZC_CEP)
				cSacEnd := SZB->ZB_ENDEMP
				cSacCep := Transform(SZB->ZB_CEP,"@r 99999-999")
				cSacMun := Substr(SZB->ZB_CIDADE,1,15)
				cSacEst := SZB->ZB_ESTADO
			Else
				cSacEnd := SZC->ZC_ENDFAM
				cSacCep := Transform(SZC->ZC_CEP,"@r 99999-999")
				cSacMun := Substr(SZC->ZC_CIDADE,1,15)
				cSacEst := SZC->ZC_ESTADO
			End If
			cSacNom := SZC->ZC_NOME
			cDesNom := SZB->ZB_NOME
			cDesEnd := SZB->ZB_ENDEMP
			cDesCep := Transform(SZB->ZB_CEP,"@R 99999-999")
			cDesMun := Substr(SZB->ZB_CIDADE,1,15)
			cDesEst := SZB->ZB_ESTADO
			cDesCon := SZB->ZB_CONTATO+Space(5)
			cSacCGC := SZC->ZC_CGC
			
		ElseIf SZC->ZC_ETIQ == "3"
			
			If len(alltrim(SZC->ZC_ENDFAM)) < 5 .Or. SZC->ZC_CEP == "00000000" .Or. Empty(SZC->ZC_CEP)
				cSacEnd := SZB->ZB_ENDEMP
				cSacCep := Transform(SZB->ZB_CEP,"@r 99999-999")
				cSacMun := Substr(SZB->ZB_CIDADE,1,15)
				cSacEst := SZB->ZB_ESTADO
			Else
				cSacEnd := SZC->ZC_ENDFAM
				cSacCep := Transform(SZC->ZC_CEP,"@r 99999-999")
				cSacMun := Substr(SZC->ZC_CIDADE,1,15)
				cSacEst := SZC->ZC_ESTADO
			End If
			cSacNom := SZC->ZC_NOME
			cDesNom := SZB->ZB_NOME
			cDesEnd := SZB->ZB_ENDEMP
			cDesCep := Transform(SZB->ZB_CEP,"@R 99999-999")
			cDesMun := Substr(SZB->ZB_CIDADE,1,15)
			cDesEst := SZB->ZB_ESTADO
			cDesCon := SZC->ZC_NOME
			cSacCGC := SZC->ZC_CGC
			
		ElseIf SZC->ZC_ETIQ == "4"
			cSacNom := SZC->ZC_NOME
			cSacEnd := SZC->ZC_ENDFAM
			cSacCep := Transform(SZC->ZC_CEP,"@r 99999-999")
			cSacMun := Substr(SZC->ZC_CIDADE,1,15)
			cSacEst := SZC->ZC_ESTADO
			cDesNom := SPACE(40)
			cDesEnd := SZC->ZC_ENDFAM
			cDesCep := Transform(SZC->ZC_CEP,"@R 99999-999")
			cDesMun := Substr(SZC->ZC_CIDADE,1,15)
			cDesEst := SZC->ZC_ESTADO
			cDesCon := SZC->ZC_NOME
			cSacCGC := SZC->ZC_CGC
			
		ElseIf SZC->ZC_ETIQ == "5"
			cSacNom := SZC->ZC_NOME
			cSacEnd := SZC->ZC_ENDFAM
			cSacCep := Transform(SZC->ZC_CEP,"@r 99999-999")
			cSacMun := SZC->ZC_CIDADE
			cSacEst := SZC->ZC_ESTADO
			
			cDesNom := SZB->ZB_CONTATO
			cDesEnd := SZB->ZB_ENDEMP
			cDesCep := Transform(SZB->ZB_CEP,"@R 99999-999")
			cDesMun := SZB->ZB_CIDADE
			cDesEst := SZB->ZB_ESTADO
			cDesCon := SPACE(40)
			cSacCGC := SZC->ZC_CGC
			
		ElseIf SZC->ZC_ETIQ == "6"
			cSacNom := SZC->ZC_NOME
			cSacEnd := SZC->ZC_ENDFAM
			cSacCep := Transform(SZC->ZC_CEP,"@r 99999-999")
			cSacMun := SZC->ZC_CIDADE
			cSacEst := SZC->ZC_ESTADO
			cDesNom := SZB->ZB_CONTATO
			cDesEnd := SZB->ZB_ENDEMP
			cDesCep := Transform(SZB->ZB_CEP,"@R 99999-999")
			cDesMun := SZB->ZB_CIDADE
			cDesEst := SZB->ZB_ESTADO
			cDesCon := SPACE(40)
			cSacCGC := SZC->ZC_CGC
		Else
			ApMsgAlert("Problema no c?igo da etiqueta do cadastro da fam?ia "+SZC->ZC_CODFAM+"-"+SZC->ZC_NOME,"Montarel - Boleto_Real")
		EndIf
		
		//Posiciona o SE1 (Contas a Receber)
		DbSelectArea("SE1")
		
		_lBcoCorrespondente := .f.
		aDadosBanco  := {	SA6->A6_COD                                     	 																,;	//1-Numero do Banco
		Iif(SA6->A6_COD=="389","MERCANTIL DO BRASIL",SA6->A6_NREDUZ )    	 											,;	//2-Nome do Banco
		Agencia(SA6->A6_COD, SA6->A6_AGENCIA)																					,; //3-Ag?cia
		Conta(SA6->A6_COD, SA6->A6_NUMCON)																						,; //4-Conta Corrente
		Iif(SA6->A6_COD $ "479/389","",SubStr(AllTrim(SA6->A6_NUMCON),Len(AllTrim(SA6->A6_NUMCON)),1))  	,;	//5-D?ito da conta corrente
		"00"  																															,; //6-Carteira
		" "  																																,;	//7-Variacao da Carteira
		""  																																}	//8-Reservado para o banco correspondente
		
		aDatSacado   := {	AllTrim(cSacNom)           		,;      	//1-Raz? Social
		AllTrim(SA1->A1_COD ) 				,;      	//2-C?igo
		AllTrim(cSacEnd)  					,;      	//3-Endere?
		AllTrim(cSacMUN)						,;      	//4-Cidade
		cSacEst									,;      	//5-Estado
		cSacCep									,;      	//6-CEP
		AllTrim(SA1->A1_CGC )				}       	//7-CGC/CPF
		
		nValor := SE1->E1_SALDO   // Valor do Saldo, pois alguns pais pagam adiantado e a Karina baixa por compensa o
		
		
		//VALOR DOS TITULOS TIPO "AB-"
		_nVlrAbat   :=  SomaAbat(SE1->E1_PREFIXO,alltrim(SE1->E1_NUM),SE1->E1_PARCELA,"R",1,,SE1->E1_CLIENTE,SE1->E1_LOJA)
		
		CB_RN_NN    := Ret_cBarra(	Subs(aDadosBanco[1],1,3)+"9"					,;
		Subs(aDadosBanco[3],1,4)						,;
		aDadosBanco[4]										,;
		aDadosBanco[5]										,;
		aDadosBanco[6]										,;
		AllTrim(E1_NUM)+AllTrim(E1_PARCELA)			,;
		nValor 												,;
		SE1->E1_VENCREA									,;
		SEE->EE_CODEMP										,;
		SEE->EE_FAXATU										,;
		Iif(SE1->E1_DECRESC > 0,.t.,.f.)				,;
		SE1->E1_PARCELA									,;
		aDadosBanco[3]										)
		
		aDadosTit    :=  {	SUBSTR(SE1->E1_PREFIXO,2,2)+Alltrim(SE1->E1_NUM)		,;	// 1-N?ero do t?ulo
		SE1->E1_EMISSAO													,;	// 2-Data da emiss? do t?ulo
		dDataBase															,;	// 3-Data da emiss? do boleto
		SE1->E1_VENCREA													,;	// 4-Data do vencimento
		SE1->E1_VALOR 														,;	// 5-Valor do t?ulo
		AllTrim(CB_RN_NN[3])												,;	// 6-Nosso n?ero (Ver f?mula para calculo)
		SE1->E1_DESCONT													,;	// 7-Valor do Desconto do titulo
		SE1->E1_VALJUR 													,;	// 8-Valor dos juros do titulo
		(SE1->E1_VALOR - SE1->E1_SALDO)								,;	// 9-Valor do Abatimento // Recebimento  antecipado  Tiago Filho conversado com a Karina
		SE1->E1_SALDO														}	// 10-Valor Cobrado
		
		aadd( aRegGer, { ZTB->(Recno()), "" } )
		
		Impress( aBMP, aDadosEmp, aDadosTit, aDadosBanco, aDatSacado, aBolText, CB_RN_NN, cMail, cAnoMes, cMesRef, cAnoRef )
		If (lower(alltrim(ZTB->ZTB_EMAIL)) <= lower(alltrim(cEmailIni)) .or. lower(alltrim(ZTB->ZTB_EMAIL)) > lower(alltrim(cEmailFim))) .And. !Empty(ZTB->ZTB_EMAIL)
			DbSelectArea("ZTB")
			Reclock("ZTB",.F.)
			ZTB->ZTB_STATUS := "3"
			ZTB->ZTB_DTGER	:= dDataBase
			ZTB->( MsUnlock() )
			
			ZTB->( DbSkip() )
			Loop
		End If
		
		nRecno := ZTB->( Recno() )
		lMudaNome := .F.
		
		If lAglutina
			
			cEmailAnt := ZTB->ZTB_EMAIL
			cAlunoAnt := ZTB->ZTB_COD_AL
			cReferAnt := Alltrim(ZTB->ZTB_REFERE)
			ZTB->( DbSkip() )
			
			If ( !Empty(ZTB->ZTB_EMAIL) .And. cEmailAnt <> ZTB->ZTB_EMAIL ) .Or. ZTB->( EOF() )
				
				If (cEmailAnt <> ZTB->ZTB_EMAIL)
					lMudaNome := .T.
					cNomFile1  := trname(cEmailAnt) + "_" + cReferAnt + ".pdf"
				End If
			Endif
			ZTB->( DbGoTo(nRecno) )
			
		Else
			
			lMudaNome := .T.
			cNomFile1  := ZTB->ZTB_COD_AL + "_" + substr(ZTB->ZTB_PREFIX,2,2) + alltrim(ZTB->ZTB_NUM) + ".pdf"
			
		Endif
		
		IF lMudaNome
			ZTB->( DbGoTo(nRecno) )
			
			oPrint:Print()
			
			CheckPdf( cLocalSpool )
			
			nStatus := -1
			nTent 	:= 0
			
			If File( cLocalSpool + cNomFile1 )
				
				while nStatus < 0 .and. nTent <= 5
					nStatus	:= Ferase( cLocalSpool + cNomFile1 )
					nTent ++
				End
				nStatus := -1
				
			End If
			
			nTent := 0
			nStatus := -1
			
			while nStatus < 0 .and. nTent <= 5
				
				nStatus := frename( cLocalSpool + "boleto.pdf" , cLocalSpool + cNomFile1 )
				cName := cNomFile1
				If nStatus == 0
					Exit
				Else
					Sleep( 500 )
				Endif
				nTent ++
				
			End
			
			If nStatus == 0
				For nX := 1 to len(aRegGer)
					aRegGer[nX][2] := cName
				Next nX
			Endif
			
			nStatus := -1
			nTent := 0
			
			oPrint:ResetPrinter()
			oPrint:= TMSPrinter():New( "Boleto Laser" )
			
			nRegSav := ZTB->( Recno() )
			
			If !Empty( aRegGer[1][2] )
				
				For nx := 1 to len( aRegGer )
					If !Empty( aRegGer[nX][2] )
						ZTB->( dbGoto( aRegGer[nX][1] ) )
						Reclock("ZTB",.F.)
						ZTB->ZTB_ARQUI := aRegGer[nX][2]
						ZTB->ZTB_STATUS := "2"
						If lVeraCros
							ZTB->ZTB_STATU1 := "4"
						Endif
						ZTB->ZTB_DTGER	:= dDataBase
						ZTB->( MsUnlock() )
					Endif
				Next nX
				ZTB->( dbGoto( aRegGer[1][1] ) )
				
				cEmailEnv	:= ZTB->ZTB_EMAIL
				cAnexo		:= ZTB->ZTB_ARQUI
				nRegZTB		:= ZTB->( Recno() )
				aRegGer := {}
				
				If !lVeraCros .and. lAutomatico
					envAuto( nRegZTB, cEmailEnv, cAnexo, cUserMail, cemailSent, cSenhaMail )
				Endif
				
			Endif
			
			ZTB->( dbGoto( nRegSav ) )
			
		Endif
		
		DbSelectArea("ZTB")
		ZTB->( DbSkip() )
	End
EndIf

If lPreview
	oPrint:Preview()     // Visualiza antes de imprimir
End If

Return nil




/*
==============================================================================================================================================================
Fun o     : Impress
Autor      : Tiago Filho
Data       :27/06/2014
Finalidade :
==============================================================================================================================================================
*/

Static Function Impress( aBitmap, aDadosEmp, aDadosTit, aDadosBanco, aDatSacado, aBolText, CB_RN_NN, cMail, cAnoMes, cMesRef, cAnoRef )

Local cBmpSant 		:= "SantanderColor.bmp"
Local oFont8
Local oFont10
Local oFont16
Local oFont16n
Local oFont20
Local oFont24
Local i := 0
Local aCoords1 		:= {150,1900,250,2300}  	// FICHA DO SACADO
Local aCoords2 		:= {420,1900,490,2300}  	// FICHA DO SACADO
Local aCoords3 		:= {1270,1900,1370,2300} 	// FICHA DO CAIXA
Local aCoords4 		:= {1540,1900,1610,2300} 	// FICHA DO CAIXA
Local aCoords5 		:= {2190,1900,2290,2300} 	// FICHA DE COMPENSACAO
Local aCoords6 		:= {2460,1900,2530,2300} 	// FICHA DE COMPENSACAO
Local oBrush  												//fundo no valor do titulo
Local nStatus 			:= -1
Local cBody				:=""
Local nSequencia		:=0
Local cAnexos 			:= ""
Local lOk 				:= .T.
Local cTo				:= ""
Local cCC				:= ""
Local cDiretorio 		:= "\spool\boletos\"
Local cLocalSpool		:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )
Local nErro				:= 0
Local nRecno
Local oMail
Local oMessage
Local nVlrMulta1 		:= 0
Local nVlrTotal1 		:= 0


If Right( cLocalSpool, 1 ) <> "\"
	cLocalSpool += "\"
Endif
cDiretorio := cLocalSpool


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

oFont6n 	:= TFont():New("Arial",9,6 ,.T.,.T.,5,.T.,5,.T.,.F.)
oFont7n 	:= TFont():New("Arial",9,7 ,.T.,.T.,5,.T.,5,.T.,.F.)
oFont8  	:= TFont():New("Arial",9,8 ,.T.,.F.,5,.T.,5,.T.,.F.)
oFont8n 	:= TFont():New("Arial",9,8 ,.T.,.T.,5,.T.,5,.T.,.F.)
oFont10 	:= TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
oFont12 	:= TFont():New("Arial",9,12,.T.,.F.,5,.T.,5,.T.,.F.)
oFont12n	:= TFont():New("Arial",9,12,.T.,.T.,5,.T.,5,.T.,.F.)
oFont14	:= TFont():New("Arial",9,14,.T.,.T.,5,.T.,5,.T.,.F.)
oFont14n	:= TFont():New("Arial",9,13,.T.,.F.,5,.T.,5,.T.,.F.)
oFont16 	:= TFont():New("Arial",9,16,.T.,.T.,5,.T.,5,.T.,.F.)
oFont16n	:= TFont():New("Arial",9,16,.T.,.F.,5,.T.,5,.T.,.F.)
oFont20 	:= TFont():New("Arial",9,20,.T.,.T.,5,.T.,5,.T.,.F.)
oFont24 	:= TFont():New("Arial",9,24,.T.,.T.,5,.T.,5,.T.,.F.)

oBrush 	:= TBrush():New(,CLR_HGRAY,,)
oPrint:StartPage()   // Inicia uma nova p?ina

aEventos := {}
nVlrSeg  := 0

DbSelectArea("SZG")
DbSetOrder(2)
DbSeek(xFilial("SZG")+SE1->E1_PREFIXO+Alltrim(SE1->E1_NUM) )

While SZG->(!Eof()) .And.  SE1->E1_PREFIXO+alltrim(alltrim(SE1->E1_NUM)) == Substr(SZG->ZG_DOC,1,9)
	
	SZD->(DbSeek(xFilial("SZD")+SZG->ZG_CODEVEN ))
	
	SX5->(DbSeek(xFilial("SX5")+"Z9"+SZD->ZD_TIPEVEN ))
	
	nValor := SZG->ZG_VALOR - SZG->ZG_VLRBOL - SZG->ZG_VLASSFI - SZG->ZG_VLRDESC
	
	If SZG->ZG_VALOR == (SZG->ZG_VALOR - SZG->ZG_VLRBOL - SZG->ZG_VLASSFI - SZG->ZG_VLRDESC)
		AaDD(aEventos,{SZG->ZG_DESEVEN,nValor})
	Else
		AaDD(aEventos,{SZG->ZG_DESEVEN,SZG->ZG_VALOR})
		If substr(SZG->ZG_DESEVEN,1,6) == "ENSINO"
			If SZG->ZG_VLRBOL > 0
				AaDD(aEventos,{"BOLSA DE ENSINO",-SZG->ZG_VLRBOL})
			End If
			If SZG->ZG_VLASSFI > 0
				AaDD(aEventos,{"AUX. FIN. DE ENSINO",-SZG->ZG_VLASSFI})
			End If
			If SZG->ZG_VLRDESC > 0
				AaDD(aEventos,{"DESCONTO DE ENSINO",-SZG->ZG_VLRDESC})
			End If
			
		ElseIf substr(SZG->ZG_DESEVEN,1,3) == "BUS"
			If SZG->ZG_VLRBOL > 0
				AaDD(aEventos,{"BOLSA DE BUS",-SZG->ZG_VLRBOL})
			End If
			If SZG->ZG_VLASSFI > 0
				AaDD(aEventos,{"AUS. FIN. DE BUS ",-SZG->ZG_VLASSFI})
			End If
			If SZG->ZG_VLRDESC > 0
				AaDD(aEventos,{"DESCONTO DE BUS",-SZG->ZG_VLRDESC})
			End If
		End If
		
		If substr(SZG->ZG_DESEVEN,1,6) == "ENSINO"
			AaDD(aEventos,{"VALOR LIQUIDO DE ENSINO",nValor})
		ElseIf substr(SZG->ZG_DESEVEN,1,3) == "BUS"
			AaDD(aEventos,{"VALOR LIQUIDO DE BUS",nValor})
		End If
	End If
	If SZG->ZG_VLRSEG <> 0
		nVlrSeg += SZG->ZG_VLRSEG
	EndIf
	
	DbSelectArea("SZG")
	DbSkip()
	
End

If nVlrSeg <> 0
	AADD(aEventos,{"Seguro : ",nVlrSeg})
EndIf

//?Ficha do Caixa                                                     ?

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

oPrint:SayBitmap( 050,100,cBmpSant,500,90 )

For nX := 1 to 3
	oPrint:Line (080,660+nX, 150,660+nX )
Next

oPrint:Say  (070,690,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20 )

For nX := 1 to 3
	oPrint:Line (080,890+nX, 150,890+nX )
Next

oPrint:Say  ( 160, 110 ,"CEDENTE"    ,oFont8n)
oPrint:Say  ( 200,110 ,Iif(_lBcoCorrespondente,aDadosBanco[8],aDadosEmp[1]) ,oFont12n)

oPrint:Say  ( 160,1910 ,"VENCIMENTO" ,oFont8n)
If (dDatabase > aDadosTit[4])
	oPrint:Say  ( 200,2005,PadL(AllTrim(DTOC(dDatabase)),16," ")             ,oFont10)
Else
	oPrint:Say  ( 200,2005,PadL(AllTrim(DTOC(aDadosTit[4])),16," ")             ,oFont10)
End If

oPrint:Say  ( 270, 120 ,"SACADO"    ,oFont8n)
oPrint:Say  ( 310 ,120 ,aDatSacado[1]      ,oFont10)
oPrint:Say  ( 270, 1160 ,"N.DO DOCUMENTO"    ,oFont8n)
oPrint:Say  ( 310 ,1220 ,aDadosTit[1] ,oFont10)
oPrint:Say  ( 270, 1910 ,"VALOR DO DOCUMENTO"    ,oFont8n)

If (dDatabase > aDadosTit[4])
	nVlrMulta1 := (aDadosTit[10]*2/100)+(1/30/100*(aDadosTit[4]-dDatabase)*aDadosTit[10]*-1)
End If

nVlrTotal1 := aDadosTit[10]+nVlrMulta1

//oPrint:Say  ( 310, 2010,PadL(AllTrim(Transform(aDadosTit[10],"@E 999,999,999.99")),16," "),oFont10)
oPrint:Say  ( 310, 2010,PadL(AllTrim(Transform(nVlrTotal1,"@E 999,999,999.99")),16," "),oFont10)
oPrint:Say  ( 380, 120 ,"NOME DO ALUNO"    ,oFont8n)
oPrint:Say  ( 430 ,120 ,SA1->A1_NOME      ,oFont10)
oPrint:Say  ( 380, 1160 ,"COD. ALUNO"    ,oFont8n)
oPrint:Say  ( 430 ,1200 ,aDatSacado[2]    ,oFont12n)

oPrint:Say  (  490, 250 ,"COMPOSIÇÃO DO T?ULO"    ,oFont12)

oPrint:Say  (  490, 1650 ,"PRE?S em R$"    ,oFont12)

oPrint:Say  ( 1710, 110 ,"MENSAGEM"    ,oFont7n)

oPrint:Say  (1860,1850,"- Autentica o Mec?ica -"  ,oFont7n)

If Len(aEventos) > 0
	nLin := 550
	For nX := 1 to Len(aEventos)
		oPrint:Say  (nLin, 120,aEventos[nX,1],oFont8n )
		oPrint:Say  (nLin, 950,PadL(Alltrim(Transform(aEventos[nX,2],"@e 999,999,999.99")),14),oFont8n)
		nLin += 40
	Next
EndIf

///////////////////

If Len(aMens) > 0
	nLin := 550
	For nX := 2 to Len(aMens)
		oPrint:Say  (nLin, 1160,aMens[nX,1],oFont8n )
		If nX <> 7
			oPrint:Say  (nLin, 2050,PadL(Alltrim(Transform(aMens[nX,2],"@e 999,999,999.99")),14),oFont8n)
		Else
			oPrint:Say  (nLin, 2087,aMens[nX,2],oFont8n)
		EndIf
		nLin += 40
	Next
EndIf

///////////////

//Gambiarra, descobrir como mudar tipo da linha.  PONTILHAMENTO
For i := 100 to 2300 step 30
	oPrint:Line( 2050, i, 2050, i+20)
	oPrint:Line( 2051, i, 2051, i+20)
	oPrint:Line( 2051, i, 2051, i+20)
Next i

//?Ficha de Compensacao                                                ?
If aDadosBanco[1] <> "356" .and. aDadosBanco[1] <> "033"
	oPrint:FillRect(aCoords5,oBrush)
	oPrint:FillRect(aCoords6,oBrush)
Endif

oPrint:Line (2190,100,2190,2300)
oPrint:Line (2190,650,2190,650 )
oPrint:Line (2190,900,2190,900 )

oPrint:SayBitmap( 2090,100,cBmpSant,500,90 )

For nX := 1 to 3
	oPrint:Line (2100,660+nX,2190,660+nX )
Next

oPrint:Say  (2102,680,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20 )

For nX := 1 to 3
	oPrint:Line (2100,890+nX,2190,890+nX )
Next

oPrint:Say  (2124,920,CB_RN_NN[2],oFont14n) //linha digitavel

oPrint:Line (2290,100,2290,2300 )
oPrint:Line (2390,100,2390,2300 )
oPrint:Line (2460,100,2460,2300 )
oPrint:Line (2530,100,2530,2300 )

oPrint:Line (2390,500,2530,500)
oPrint:Line (2460,750,2530,750)
oPrint:Line (2390,1000,2530,1000)
oPrint:Line (2390,1350,2460,1350)
oPrint:Line (2390,1550,2530,1550)

oPrint:Say  (2190,100 ,"Local de Pagamento"                             ,oFont8)
oPrint:Say  (2230,100 ,"Pag?el em qualquer ag?cia banc?ia at?o vencimento"       ,oFont10)
oPrint:Say  (2190,1910,"Vencimento"                                     ,oFont8)

If (dDatabase > aDadosTit[4])
	oPrint:Say  (2230,2005,PadL(AllTrim(DTOC(dDataBase)),16," ")                               ,oFont10)
Else
	oPrint:Say  (2230,2005,PadL(AllTrim(DTOC(aDadosTit[4])),16," ")                               ,oFont10)
End If

oPrint:Say  (2290,100 ,"Cedente"                                        ,oFont8)
oPrint:Say  (2330,100 ,Iif(_lBcoCorrespondente,aDadosBanco[8],aDadosEmp[1])                                     ,oFont10)

oPrint:Say  (2290,1910,"Ag?cia/C?igo Cedente"                ,oFont8)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

If aDadosBanco[1]$"356-033"
	oPrint:Say  (2330,2010,PadL(AllTrim(SA6->A6_AGENCIA)+"/"+cCCedente,16),oFont10)// +SA6->A6_NUMCON),16 ) //+" / "+cDigitao,oFont10)
End If

oPrint:Say  (2390,100 ,"Data do Documento"                              ,oFont8)

oPrint:Say  (2420,100 ,DTOC(aDadosTit[3])                               ,oFont10)

oPrint:Say  (2390,505 ,"Nro.Documento"                                  ,oFont8)
oPrint:Say  (2420,605 ,aDadosTit[1]                                     ,oFont10)

oPrint:Say  (2390,1005,"Esp?ie Doc."                                   ,oFont8)
oPrint:Say  (2420,1105,"DS"                                             ,oFont10)

oPrint:Say  (2390,1355,"Aceite"                                         ,oFont8)
oPrint:Say  (2420,1455,"N"                                             ,oFont10)

oPrint:Say  (2390,1555,"Data do Processamento"                          ,oFont8)

oPrint:Say  (2420,1655,DTOC(aDadosTit[2])                            	,oFont10)

oPrint:Say  (2390,1910,"Nosso N?ero"                                   ,oFont8)
//oPrint:Say  (2420,2000,LEFT(CB_RN_NN[3],12)            	,oFont10) //cDoc
oPrint:Say  (2420,2000, cnNumero                            	,oFont10)
//oPrint:Say  (2420,2000,"0000"+cnNumero                            	,oFont10)   // *Verificar se ?ou n? para acrescentar os 4 zeros a esquerda, pois ni cod de barras ?n ecessario.

oPrint:Say  (2460,100 ,"Uso do Banco"                                   ,oFont8)

oPrint:Say  (2460,505 ,"Carteira"                                       ,oFont8)
//oPrint:Say  (2490,555 ,"ECR 										 "          ,oFont10)
oPrint:Say  (2490,555 ,cCarteira           										,oFont10)

oPrint:Say  (2460,755 ,"Esp?ie"                                        			,oFont8)
oPrint:Say  (2490,805 ,"R$"                                             			,oFont10)

oPrint:Say  (2460,1005,"Quantidade"                                     		,oFont8)
oPrint:Say  (2460,1555,"Valor"                                          			,oFont8)

oPrint:Say  (2460,1910,"(=)Valor do Documento"                         	,oFont8)
oPrint:Say  (2490,2010,PadL(AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),16," "),oFont10)

oPrint:Say  (2530,100 ,"Instruções/Texto de responsabilidade do cedente",oFont8)

oPrint:Say  (2580,100 ,aBolText[1]                                      ,oFont10)
oPrint:Say  (2630,100 ,"APOS O VENCIMENTO COBRAR JUROS DE 1% A.M.",oFont10)
oPrint:Say  (2680,100 ,aBolText[2]                                      ,oFont10)
If Empty( aBolText[3] )
	oPrint:Say  (2730,100 ,"Atualiza o de boleto vencido acesse:  ",oFont10,,CLR_HRED)
	oPrint:Say  (2780,100 ,"www.santander.com.br/boletos   ",oFont10,,CLR_HRED)
Else
	oPrint:Say  (2730,100 ,aBolText[3]    												,oFont10)
	oPrint:Say  (2780,100 ,"Atualiza o de boleto vencido acesse:  www.santander.com.br/boletos   ",oFont10,,CLR_HRED)
Endif
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

oPrint:Say  (2530,1910,"(-)Desconto/Abatimento"                         ,oFont8)
oPrint:Say  (2600,1910,"(-)Outras Deduções"                             ,oFont8)
oPrint:Say  (2630,2010,PadL(AllTrim(Transform(aDadosTit[9],"@E 999,999,999.99")),16," "),oFont10)
oPrint:Say  (2670,1910,"(+)Mora/Multa"                                  ,oFont8)
//acrescentar as multas aqui
If (dDatabase > aDadosTit[4])
	oPrint:Say  (2700,2020,PadL(AllTrim(Transform(Round((aDadosTit[10]*2/100)+(1/30/100*(aDadosTit[4]-dDatabase)*aDadosTit[10]*-1),2),"@E 999,999,999.99")),16," ")                                  ,oFont10)
End If
oPrint:Say  (2740,1910,"(+)Outros Acr?cimos"                           ,oFont8)
oPrint:Say  (2810,1910,"(=)Valor Cobrado"                               ,oFont8)
If (dDatabase > aDadosTit[4])
	oPrint:Say  (2840,2010,PadL(AllTrim(Transform( Round((((aDadosTit[10]*2/100)+(1/30/100*(aDadosTit[4]-dDatabase)*aDadosTit[10]*-1)) + aDadosTit[10]),2),"@E 999,999,999.99")),16," ")                                  ,oFont10)
Else
	oPrint:Say  (2840,2010,PadL(AllTrim(Transform(aDadosTit[10],"@E 999,999,999.99")),16," ")                                  ,oFont10)
End If

oPrint:Say  (2880,100 ,"Sacado"                                         ,oFont8)
oPrint:Say  (2908,210 ,aDatSacado[1]+" ("+aDatSacado[2]+")"             ,oFont8)
oPrint:Say  (2948,210 ,aDatSacado[3]                                    ,oFont8)
oPrint:Say  (2988,210 ,aDatSacado[6]+"  "+aDatSacado[4]+" - "+aDatSacado[5]+"         CGC/CPF: "+Iif(Len(AllTrim(aDatSacado[7]))==14,Transform(aDatSacado[7],"@R 99.999.999/9999-99"),Transform(aDatSacado[7],"@R 999.999.999-99")) ,oFont8)

oPrint:Say  (2845,100 ,"Sacador/Avalista"+Iif(_lBcoCorrespondente,aDadosEmp[1],"")                               ,oFont8)
oPrint:Say  (3030,1500,"Autentica o Mec?ica -"                        ,oFont8)

oPrint:Say  (3030,1850,"Ficha de Compensa o"                           ,oFont10)

oPrint:Line (2190,1900,2880,1900 )
oPrint:Line (2600,1900,2600,2300 )
oPrint:Line (2670,1900,2670,2300 )
oPrint:Line (2740,1900,2740,2300 )
oPrint:Line (2810,1900,2810,2300 )
oPrint:Line (2880,100 ,2880,2300 )

oPrint:Line (3025,100,3025,2300  )

MSBAR("INT25",26.28,1.2,CB_RN_NN[1],oPrint,.F.,Nil,Nil,0.023,1.2,Nil,Nil,"A",.F.)

oPrint:EndPage() // Finaliza a p?ina


Return Nil





/*
==============================================================================================================================================================
Fun o     : Modulo10
Autor      :Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/

Static Function Modulo10(cData)
Local L,D,P 	:= 0
Local B     	:= .F.

Default cData 	:= ""

L := Len(cData)  	//TAMANHO DE BYTES DO CARACTER
B := .T.
D := 0     			//DIGITO VERIFICADOR

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
	
End

D := 10 - (Mod(D,10))

If D = 10
	D := 0
End

Return(D)



/*
==============================================================================================================================================================
Fun o     : Modulo11
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function Modulo11(cData,cBanc)
Local L, D, P := 0

If cBanc$"001"  // Banco do brasil
	L := Len(cdata)
	D := 0
	P := 10
	While L > 0
		P := P - 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 2
			P := 10
		EndIf
		L := L - 1
	End
	D := mod(D,11)
	If D == 10
		D := "X"
	Else
		D := AllTrim(Str(D))
	EndIf
ElseIf cBanc$"237-033-356-453-399-422" // Bradesco/Santander/Itau/Mercantil/Rural/HSBC/Safra
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		EndIf
		L := L - 1
	End
	D := 11 - (mod(D,11))
	
	If (D == 10 .Or. D == 11) .and. (cBanc$"237-033-356-422")
		D := 1
	EndIf
	If (D == 1 .Or. D == 0 .Or. D == 10 .Or. D == 11) .and. (cBanc$"289-453-399")
		D := 0
	EndIf
	D := AllTrim(Str(D))
ElseIf cBanc$"389" //Mercantil
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		EndIf
		L := L - 1
	End
	D := mod(D,11)
	If D == 1 .Or. D == 0
		D := 0
	Else
		D := 11 - D
	EndIf
	D := AllTrim(Str(D))
ElseIf cBanc$"479"  //BOSTON
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		EndIf
		L := L - 1
	End
	D := Mod(D*10,11)
	If D == 10
		D := 0
	EndIf
	D := AllTrim(Str(D))
ElseIf cBanc$"409"  //UNIBANCO
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		EndIf
		L := L - 1
	End
	D := Mod(D*10,11)
	If D == 10 .or. D == 0
		D := 0
	EndIf
	D := AllTrim(Str(D))
ElseIf cBanc$"999"  //Real
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		EndIf
		L := L - 1
	End
	D := Mod(D*10,11)
	If D == 10 .or. D == 0
		D := 0
	EndIf
	D := AllTrim(Str(D))
Else
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		EndIf
		L := L - 1
	End
	D := 11 - (mod(D,11))
	If (D == 10 .Or. D == 11)
		D := 1
	EndIf
	D := AllTrim(Str(D))
Endif

Return(D)





/*
==============================================================================================================================================================
Fun o     : Ret_cBarra
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function Ret_cBarra(cBanco,cAgencia,cConta,cDacCC,cCarteir,cNroDoc,nValor,dvencimento,cConvenio,cSequencial,_lTemDesc,_cParcela,_cAgCompleta)

Local blvalorfinal 		:= 0
Local cNNumSDig 			:= ''
Local cCpoLivre 			:= ''
Local cCBSemDig 			:= ''
Local cCodBarra 			:= ''
Local cNNum 				:= ''
Local cFatVenc 			:= ''
Local cLinDigit 			:= ''

Private nVlrDesc 			:= 0
Private nVlrJuro 			:= 0

nVlrMulta 	:= 0
cBanco	 	:= Substr(cBanco,1,3)

If (dDatabase > dvencimento)
	nVlrMulta 	:= (nValor*2/100)+(1/30/100*(dVencimento-dDatabase)*nValor*-1)
	dvencimento := dDatabase
End If

nValorfinal := nValor+nVlrMulta

cSeqNNum  	:= StrZero(Val(Substr(ZTB->ZTB_PREFIX,3,1)+AllTrim(ZTB->ZTB_NUM)),12)

cNossoNum := "00000"+alltrim(cnNumero) // para boleto o nosso numero s? 13 digitos // ele esta vindo com 8 , entao acrescento 5 zeros a esquerda

//		cCarteira	:= '101'
aCart 		:= {U_EGFINNMSTN(cCarteira)}
cCart 		:= aCart[1][1] + aCart[1][2]
nFatorVenc  := STRZERO(dvencimento - CtoD("07/10/1997"),4)

cCdBarSeq1  := cBanco + '9' + nFatorVenc + STRZERO((ROUND(nValorfinal,2)*100),10)+ '9'+ cCCedente + alltrim(cNossoNum) + '0' + '101'  // cCarteira
aDvCodBar	:= {U_CALCDVBARR(cCdBarSeq1)}

cCodBarra   := cBanco + "9" + aDvCodBar[1][2]+ nFatorVenc +  STRZERO((ROUND(nValorfinal,2)*100),10)+ '9'+ cCCedente + cNossoNum + '0' + '101' //cCarteira

cLinha1 		:= cBanco + "9" + "9" + Substr(cCCedente,1,4)
aDVLinDig1  := Mod10Boleto(cLinha1)
cLinha1 		+= aDVLinDig1

// Linha 1 OK
cLinha2 		:= Substr(cCCedente,5,3) + Substr(cNossoNum,1,7) //3 ultimos digitos do cedente + 7 primeiros digitos do nosso numero )
aDVLinDig2  := Mod10Boleto(cLinha2)
cLinha2 		+= aDVLinDig2

// Linha 2 OK
cLinha3 		:= Substr(cNossoNum,8,6) + '0' + '101' // cCarteira 101 - cobranca com registro // 102 cobranca simples sem registro
aDVLinDig3  := Mod10Boleto(cLinha3)
cLinha3 		+= aDVLinDig3

// Linha 3 OK
cLinha4 		:= aDvCodBar[1][2]

// Linha 4 n?

//		cLinha5 	:= nFatorVenc + STRZERO((ROUND(nValor,2)*100),10)
cLinha5 		:= nFatorVenc + STRZERO((ROUND(nValorfinal,2)*100),10)

cLindig 		:= Substr(cLinha1,1,5) +'.'+ Substr(cLinha1,6,5) +' '
cLindig 		+= Substr(cLinha2,1,5) +'.'+ Substr(cLinha2,6,6) +' '
cLindig 		+= Substr(cLinha3,1,5) +'.'+ Substr(cLinha3,6,6) +' '
cLindig 		+= cLinha4 +' '+ cLinha5

Return({cCodBarra,cLinDig,cNossoNum})



/*
==============================================================================================================================================================
Fun o     : Agencia
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function Agencia(_cBanco,_nAgencia)
Local _cRet 		:= ""

If _cBanco$"479-389"
	_cRet := AllTrim(SEE->EE_AGBOSTO)
ElseIF _cBanco$"033-356-422"
	_cRet := StrZero(Val(AllTrim(_nAgencia)),4)
Else
	_cRet := SubStr(StrZero(Val(AllTrim(_nAgencia)),5),1,4)+"-"+SubStr(StrZero(Val(AllTrim(_nAgencia)),5),5,1)
Endif

Return(_cRet)




/*
==============================================================================================================================================================
Fun o     : Conta
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function Conta(_cBanco,_cConta)
Local _cRet 		:= ""

If _cBanco$"479/389"
	_cRet := AllTrim(SEE->EE_CODEMP)
ElseIf _cBanco$"033-356"
	_cRet := StrZero(Val(SubStr(AllTrim(_cConta),1,Len(AllTrim(_cConta)))),7)
Else
	_cRet := SubStr(AllTrim(_cConta),1,Len(AllTrim(_cConta)))
Endif

Return(_cRet)



/*
==============================================================================================================================================================
Fun o     : NumParcela
Autor      : Tiago Filho
Data       :27/06/2014
Finalidade :
==============================================================================================================================================================
*/

Static Function NumParcela(_cParcela)
Local _cRet 		:= ""

If ASC(_cParcela) >= 65 .or. ASC(_cParcela) <= 90
	_cRet := StrZero(Val(Chr(ASC(_cParcela)-16)),2)
Else
	_cRet := StrZero(Val(_cParcela),2)
Endif

Return(_cRet)



/*
==============================================================================================================================================================
Fun o     : Fic_Sacado
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/
Static Function Fic_Sacado()

If aDadosBanco[1]<>"033".And.aDadosBanco[1]<>"356"
	oPrint:FillRect(aCoords3,oBrush)
	oPrint:FillRect(aCoords4,oBrush)
Endif

oPrint:Line (1270,100,1270,2300)
oPrint:Line (1270,650,1170,650 )
oPrint:Line (1270,900,1170,900 )

oPrint:SayBitmap( 1975,100,cBmpSant,500,90 )

oPrint:Say  (1182,680,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20 )

oPrint:Line (1370,100,1370,2300 )
oPrint:Line (1470,100,1470,2300 )
oPrint:Line (1540,100,1540,2300 )
oPrint:Line (1610,100,1610,2300 )

oPrint:Line (1470,500,1610,500)
oPrint:Line (1540,750,1610,750)
oPrint:Line (1470,1000,1610,1000)
oPrint:Line (1470,1350,1540,1350)
oPrint:Line (1470,1550,1610,1550)

oPrint:Say  (1270,100 ,"Local de Pagamento"                             ,oFont8)
oPrint:Say  (1310,100 ,"Qualquer banco at?a data do vencimento"        ,oFont10) //ALT. VALDEIR

oPrint:Say  (1270,1910,"Vencimento"                                     ,oFont8)
oPrint:Say  (1310,2010,DTOC(aDadosTit[4])                               ,oFont10)

oPrint:Say  (1370,100 ,"Cedente"                                        ,oFont8)
oPrint:Say  (1410,100 ,Iif(_lBcoCorrespondente,aDadosBanco[8],aDadosEmp[1])          ,oFont10)

oPrint:Say  (1370,1910,"Ag?cia/C?igo Cedente"                         ,oFont8)
oPrint:Say  (1410,2005,PadL(AllTrim(aDadosBanco[3]+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],"")),16," "),oFont10)

oPrint:Say  (1470,100 ,"Data do Documento"                              ,oFont8)
oPrint:Say  (1500,100 ,DTOC(aDadosTit[3])     ,oFont10) //ALT. VALDEIR

If aDadosBanco[1] == "237"  //SE BRADESCO
	oPrint:Say  (1500,100 ,Substring(DTOS(aDadosTit[3]),7,2)+"/"+Substring(DTOS(aDadosTit[3]),5,2)+"/"+Substring(DTOS(aDadosTit[3]),1,4)  ,oFont10)
Else
	oPrint:Say  (1500,100 ,DTOC(aDadosTit[3])                               ,oFont10)
Endif

oPrint:Say  (1470,505 ,"Nro.Documento"                                  ,oFont8)
oPrint:Say  (1500,595 ,aDadosTit[1]                                     ,oFont10)

oPrint:Say  (1470,1005,"Esp?ie Doc."                                   ,oFont8)
oPrint:Say  (1500,1105,"DM"                                             ,oFont10)

oPrint:Say  (1470,1355,"Aceite"                                         ,oFont8)
oPrint:Say  (1500,1455,"N"                                             ,oFont10)

oPrint:Say  (1470,1555,"Data do Processamento"                          ,oFont8)
oPrint:Say  (1500,1655,DTOC(aDadosTit[2])     ,oFont10)  //ALT. VALDEIR

If aDadosBanco[1]$"237"   //SE BRADESCO
	oPrint:Say  (1500,1655,Substring(DTOS(aDadosTit[2]),7,2)+"/"+Substring(DTOS(aDadosTit[2]),5,2)+"/"+Substring(DTOS(aDadosTit[2]),1,4)  ,oFont10)
Else
	oPrint:Say  (1500,1655,DTOC(aDadosTit[2])                               ,oFont10)
Endif

oPrint:Say  (1470,1910,"Nosso N?ero"                                   ,oFont8)
oPrint:Say  (1500,2005,PadL(AllTrim(aDadosTit[6]),17," ")                  ,oFont10)
oPrint:Say  (1540,100 ,"Uso do Banco"                                   ,oFont8)

If aDadosBanco[1]$"409"
	oPrint:Say  (1570,100,"cvt 5539-5",oFont10)
Endif

oPrint:Say  (1540,505 ,"Carteira"                                       ,oFont8)
oPrint:Say  (1570,555 ,aDadosBanco[6]+aDadosBanco[7]                    ,oFont10)

oPrint:Say  (1540,755 ,"Esp?ie"                                        ,oFont8)
oPrint:Say  (1570,805 ,"R$"                                             ,oFont10)

oPrint:Say  (1540,1005,"Quantidade"                                     ,oFont8)
oPrint:Say  (1540,1555,"Valor"                                          ,oFont8)

oPrint:Say  (1540,1910,"(=)Valor do Documento"                          ,oFont8)
oPrint:Say  (1570,2005,PadL(AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),16," "),oFont10)

If aDadosBanco[1]$"033-356"
	oPrint:Say  (1610,100 ,"Instruções/Todos as informações deste bloqueto s? de exclusiva responsabilidade do cedente",oFont8)
Else
	oPrint:Say  (1610,100 ,"Instruções/Texto de responsabilidade do cedente",oFont8)
Endif

oPrint:Say  (1660,100 ,Iif(aDadosTit[7]>0,"Conceder desconto de R$ "+AllTrim(Transform(aDadosTit[7],"@E 999,999.99"))+" ate o vencimento","") ,oFont10)
oPrint:Say  (1710,100 ,Iif(aDadosTit[8]>0,"Cobrar juros/mora dia de R$ "+AllTrim(Transform(aDadosTit[8],"@E 999,999.99")),"") ,oFont10)
oPrint:Say  (1760,100 ,aBolText[1]                                      ,oFont10)
oPrint:Say  (1810,100 ,aBolText[2]                                      ,oFont10)
oPrint:Say  (1860,100 ,aBolText[3]                                      ,oFont10)

oPrint:Say  (1610,1910,"(-)Desconto/Abatimento"                         ,oFont8)
oPrint:Say  (1680,1910,"(-)Outras Deduções"                             ,oFont8)
oPrint:Say  (1750,1910,"(+)Mora/Multa"                                  ,oFont8)
oPrint:Say  (1820,1910,"(+)Outros Acr?cimos"                           ,oFont8)
oPrint:Say  (1890,1910,"(=)Valor Cobrado"                               ,oFont8)

oPrint:Say  (1960 ,100 ,"Sacado:"                                         ,oFont8)
oPrint:Say  (1988 ,210 ,aDatSacado[1]+" ("+aDatSacado[2]+")"             ,oFont8)
oPrint:Say  (2030 ,210 ,aDatSacado[3]                                    ,oFont8)
oPrint:Say  (2070 ,210 ,aDatSacado[6]+"  "+aDatSacado[4]+" - "+aDatSacado[5]+"         CGC/CPF: "+Iif(Len(AllTrim(aDatSacado[7]))==14,Transform(aDatSacado[7],"@R 99.999.999/9999-99"),Transform(aDatSacado[7],"@R 999.999.999-99")) ,oFont8)
oPrint:Say  (2070 ,200 ,aDatSacado[6]                                    ,oFont10)

oPrint:Say  (1925,100 ,"Sacador/Avalista"+Iif(_lBcoCorrespondente,aDadosEmp[1],"")                               ,oFont8)
oPrint:Say  (2110,1500,"Autentica o Mec?ica "                        ,oFont8)
oPrint:Say  (1204,1850,"Recibo do Sacado"                              ,oFont10)

oPrint:Line (1270,1900,1960,1900 )
oPrint:Line (1680,1900,1680,2300 )
oPrint:Line (1750,1900,1750,2300 )
oPrint:Line (1820,1900,1820,2300 )
oPrint:Line (1890,1900,1890,2300 )
oPrint:Line (1960,100 ,1960,2300 )

oPrint:Line (2105,100,2105,2300  )

Return Nil




/*
==============================================================================================================================================================
Fun o     : RetDac
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/

Static Function RetDac(cCodBarra)

Local i 			:= 44
Local nDac
Local nResto
Local nSoma 	:= 0
Local nMult 	:= 2

for i := 44 to 1 step -1
	if i # 5
		If nMult > 9
			nMult := 2
		End If
		nSoma := nSoma + val(substr(alltrim(cCodBarra),i,1)) * nMult
		nMult++
	Endif
next i

nResto 	:= nSoma % 11
nDac 		:= 11 - nResto

If (nDac == 0 .Or. nDac == 1 .Or. nDac == 10 .Or. nDac == 11)
	nDac := 1
EndIf

Return nDac




/*
==============================================================================================================================================================
Fun o     : CalcDigitao
Autor      : Tiago Filho
Data       : 27/06/2014
Finalidade :
==============================================================================================================================================================
*/

Static Function CalcDigitao(cData)

Local nMult 			:= 1
Local i 					:= 1
Local nSoma1 			:= 0
Local nSoma2 			:= 0
Local nResto			:= 0
Local nRet				:= 0

For i := 1 to 24
	nSoma1 := val(Substr(cData,i,1))*nMult
	If nSoma1 >= 10
		nSoma2 := nSoma2 + (val(substr(alltrim(str(nSoma1)),1,1)) + val(substr(alltrim(str(nSoma1)),2,1)) )
	Else
		nSoma2 := nSoma2 + nSoma1
	EndIf
	
	If nMult == 1
		nMult := 2
	ElseIf nMult == 2
		nMult := 1
	EndIf
Next i

nResto 	:= nSoma2 % 10
nRet 		:= 10-nResto

If nRet == 10
	nRet := 0
End If

cDigitao := alltrim(str(nRet))

Return alltrim(str(nRet))




Static Function Mod10Boleto(cSeq)

cDoc 		:= Alltrim(cSeq)
nSoma		:= 0

nMult	:= 2

For i := len(cDoc) to 1 Step -1                  // 8 x 2 = 16
	// 7 x 1 = 07
	nDigDoc 	:= val(substr(cDoc,i,1))         // 7 x 2 = 14
	// 4 x 1 = 04
	nCalc 	:= nDigDoc*nMult                     // 1 x 2 = 02
	
	if nCalc > 9
		cCalc := Str(nCalc,2)
		nCalc := Val(Substr(cCalc,1,1)) + Val(Substr(cCalc,2,1))
	endif
	
	nSoma	+= nCalc                             // 2 x 1 = 02
	// 1 x 2 =  2
	nMult := if(nMult == 1, 2, 1) 				 // 1 x 1 =  1
	// 1 x 2 =  2
Next                                             //--->     46 / 10 = 4,6 rest 6
//D?. = 10 - 6 = --> 4 <--
nResto 	:= (nSoma % 10)
if nResto == 0
	nDigNN	:= '0'
else
	nDigNN	:= Str(10 - nResto,1)
endif

Return(nDigNN)



User Function GRDA013(cAlias, nReg, nOpc)
Local cQuery		:= ""
Local cAliasQry	:= GetNextAlias()
Local cMail			:= ""
Local cFilename	:= ""
Local cMesRef		:= ""
Local cAnoRef		:= ""
Local cPerg			:= 'GRD010'
Local lOk			:= .F.

If Select( cAliasQry ) > 0
	dbSelectArea( cAliasQry )
	dbCloseArea()
Endif

Pergunte( cPerg, .F. )

cQuery := "SELECT DISTINCT ZTB_EMAIL, ZTB_ARQUI, ZTB_REFERE "
cQuery += "FROM " + RetSqlName( "ZTB" ) + " ZTB "
cQuery += "WHERE ZTB_FILIAL = '" + xFilial( "ZTB" ) + "' "
cQuery += "AND ZTB_REFERE = '" + MV_PAR11 + "' "
cQuery += "AND ( ZTB_STATU1 = '1' "
cQuery += " OR  ZTB_STATU1 = '3' ) "
cQuery += "AND ZTB_STATUS = '2' "
cQuery += "AND D_E_L_E_T_ = ' ' "

cQuery := ChangeQuery(cQuery)

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasQry, .F., .T.)

cMesRef := Left( MV_PAR11, 2 )
cAnoRef := Right( MV_PAR11, 4 )

If (cAliasQry)->(Eof())
	ApmsgAlert( "N? existem e-mails pendentes a serem enviados!", "Aviso" )
Endif

If ApMsgYesNo( "Confirma o envio dos boletos pendentes?", "Confirmar Envio" )
	If (cAliasQry)->( !eof() )
		msgRun( "Enviando emails pendentes","Aguarde...",{ || envPend( cAliasQry, cMesRef, cAnoRef ) } )
		LoK		:= .T.
	Endif
Endif

If Select( cAliasQry ) > 0
	dbSelectArea( cAliasQry )
	dbCloseArea()
Endif
If lOk
	MsgRun( "Limpeza da base de dados", "Aguarde...", { || LimpaBas( {.F., .F., .T., .F., .F.} ) } )
Endif
Return Nil




Static Function SendMail(cMail, cFilename, cMesRef, cAnoRef, cUserMail, cemailSent, cSenhaMail)
Local nStatus		:= -1
Local cAnexos		:= ""
Local aFiles		:= {}
Local x				:= 0
Local oMail
Local nErro			:= 0
Local cFrom			:= ""
Local cSubject		:= "Boleto Cobran? Graded School"
Local cTexto		:= ""
Local cDiretorio	:= "\Spool\boletos\"
Local cLocalSpool	:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )

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
oMail:Init( '', Alltrim(GetMV("MV_SZPREC4",,'smtp.gmail.com')) , Alltrim(cemailSent),Alltrim(cSenhaMail), 0, GetMv( "MV_SZPREC5",,465) )
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

oMessage := TMailMessage():New()
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



User Function GRDA014(cAlias, nReg, nOpc)
Local cMesAno	:= ""
Local nTipoRel	:= 3
Local cPerg		:= 'GRD010'

Ajustaperg( cPerg )
Pergunte( cPerg, .F. )
If !Empty( MV_PAR11 )
	cMesAno := MV_PAR11
	
	SaveInter()
	
	U_GRDA020( cMesAno, nTipoRel )
	
	RestInter()
	
Endif

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




User Function GRDA016()
Local aPergs		:= {}
Local aRet			:= {}
Local cSql			:= ""
Local cWhere		:= ""
Local cPref			:= " ( "
Local cAliasQry	:= GetNextAlias()
Local cLocalSpool	:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )
Local nStatus		:= 0
Local nSelect		:= 0
Local oDlg
Local cCadastro	:= "Limpeza de base"
Local aResult		:= {}
Local nOpca 		:= 0
Local aAreaSav		:= GetArea()
Local oCheck1
Local lCheck1		:= .F.
Local oCheck2
Local lCheck2		:= .F.
Local oCheck3
Local lCheck3		:= .F.
Local oCheck4
Local lCheck4		:= .F.
Local oAmarelo
Local oCheck5
Local lCheck5		:= .F.
Local oVermelho
Local oAzul
Local oVerde
Local oPreto
//DEFINE MSDIALOG oDlgSenha TITLE cTitle FROM 20, 20 TO 225,310 Of oMainWnd Pixel

DEFINE MSDIALOG oDlg TITLE cCadastro From 20, 20 TO 245,330 OF oMainWnd PIXEL

@ 005, 005 Say "Efetuar limpeza de base "  	SIZE 210,08 	PIXEL OF oDlg

@ 020, 025 CHECKBOX oCheck1 VAR lCheck1 PROMPT "N? Gerados ?" SIZE 080,010  OF oDlg PIXEL
@ 020, 005 BITMAP oAmarelo RESOURCE "BR_AMARELO" 	oF  oDlg PIXEL SIZE 08,08 ADJUST WHEN .F. NOBORDER

@ 035, 025 CHECKBOX oCheck2 VAR lCheck2 PROMPT "Gerados     ?" SIZE 080,010  OF oDlg PIXEL
@ 035, 005 BITMAP oAzul RESOURCE "BR_AZUL" 			oF  oDlg PIXEL SIZE 08,08 ADJUST WHEN .F. NOBORDER

@ 050, 025 CHECKBOX oCheck3 VAR lCheck3 PROMPT "Enviados    ?" SIZE 080,010  OF oDlg PIXEL
@ 050, 005 BITMAP oVerde RESOURCE "BR_VERDE" 		oF  oDlg PIXEL SIZE 08,08 ADJUST WHEN .F. NOBORDER

@ 065, 025 CHECKBOX oCheck4 VAR lCheck4 PROMPT "Pendentes   ?" SIZE 080,010  OF oDlg PIXEL
@ 065, 005 BITMAP oVermelho RESOURCE "BR_VERMELHO" oF  oDlg PIXEL SIZE 08,08 ADJUST WHEN .F. NOBORDER

@ 080, 025 CHECKBOX oCheck5 VAR lCheck5 PROMPT "Veracross   ?" SIZE 080,010  OF oDlg PIXEL
@ 080, 005 BITMAP oPreto RESOURCE "BR_Preto" oF  oDlg PIXEL SIZE 08,08 ADJUST WHEN .F. NOBORDER

ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{||nOpcA:=1,oDlg:End()},{||oDlg:End()})

If nOpca == 1
	
	IF ApMsgYesNo( "Confirma a limpeza da base de dados? ", "Confirma o" )
		aRet := {}
		aadd( aRet, lCheck1 )
		aadd( aRet, lCheck2 )
		aadd( aRet, lCheck3 )
		aadd( aRet, lCheck4 )
		aadd( aRet, lCheck5 )
		
		MsgRun( "Limpeza da base de dados", "Aguarde...", { || LimpaBas( aRet ) } )
	Endif
	
Endif

Return Nil




Static Function LimpaBas( aRet )
Local cSql			:= ""
Local cWhere		:= ""
Local cPref			:= " ( "
Local cAliasQry	:= GetNextAlias()
Local cLocalSpool	:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )
Local nStatus		:= 0
Local nSelect		:= 0
Local cNovoLocal	:= ""

If right( cLocalSpool, 1 ) <> "\"
	cLocalSpool += "\"
Endif

cNovoLocal := cLocalSpool + "Enviados\"

cNovoLocal := U_FSMakeDir( cNovoLocal )

cSql := "SELECT R_E_C_N_O_ AS NUMREGZTB "
cSql += "FROM " + RetSqlName( "ZTB" ) + " ZTB "
cSql += "WHERE "

If aRet[1]
	cWhere += cPref + " (ZTB_STATUS = '1') "
	cPref := " OR "
	nSelect := 1
Endif
If aRet[2]
	cWhere += cPref + " ( ZTB_STATUS = '2' AND ZTB_STATU1 = '1' ) "
	cPref := " OR "
	nSelect := 1
Endif
If aRet[3]
	cWhere += cPref + " ( ZTB_STATUS = '2' AND ZTB_STATU1 = '2' ) "
	cPref := " OR "
	nSelect := 1
Endif
If aRet[4]
	cWhere += cPref + " ( ZTB_STATUS <> '1' AND ZTB_STATUS <> '2' ) "
	cPref := " OR "
	nSelect := 1
Endif
If aRet[5]
	cWhere += cPref + " ( ZTB_STATUS = '2' AND ZTB_STATU1 = '4' ) "
	cPref := " OR "
	nSelect := 1
Endif

If nSelect == 1
	cWhere += " ) AND " + " D_E_L_E_T_ = ' ' "
	
	cSql += cWhere
	
	If Select( cAliasQry ) > 0
		dbSelectArea( cAliasQry )
		(cAliasQry)->( dbCloseArea() )
	Endif
	
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cSql), cAliasQry, .F., .T.)
	tcSetField(cAliasQry, "NUMREGZTB", "N", 10, 00 )
	
	While (cAliasQry)->( !eof() )
		
		ZTB->(dbGoto( (cAliasQry)->NUMREGZTB ))
		If file( cLocalSpool + Alltrim(ZTB->( ZTB_ARQUI )))
			nStatus := __CopyFile( cLocalSpool + Alltrim(ZTB->( ZTB_ARQUI )), cNovoLocal + Alltrim(ZTB->( ZTB_ARQUI )) )
			nStatus := fErase( cLocalSpool + Alltrim(ZTB->( ZTB_ARQUI )) )
		Endif
		
		(cAliasQry)->( dbSkip() )
		
	End
	
	If Select( cAliasQry ) > 0
		dbSelectArea( cAliasQry )
		(cAliasQry)->( dbCloseArea() )
	Endif
	
	cSql := "DELETE FROM " + RetSqlName( "ZTB" ) + " WHERE "
	cSql += cWhere
	
	nStatus := tcSqlExec( cSql )
	tcRefresh( Alltrim( RetSqlName( "ZTB" ) ) )
	
Else
	ApMsgAlert( "Nada foi selecionado para limpeza", "Aviso" )
Endif

Return Nil





Static Function envPend( cAliasQry, cMesRef, cAnoRef )
LOcal cMail			:= ""
Local cFilename	:= ""
Local lOk			:= .F.
Local aUsuario		:= {}

aUsuario := GetUsermail()
If len(aUsuario) == 3
	cUserMail 	:= aUsuario[1]
	cemailSent 	:= aUsuario[2]
	cSenhaMail	:= aUsuario[3]
	
	
Else
	ApMsgAlert( "Operacao de envio de e-mail abortada", "Envio" )
	Return Nil
Endif


While (cAliasQry)->(!eof())
	
	cMail := (cAliasQry)->ZTB_EMAIL
	cFileName := Alltrim( (cAliasQry)->ZTB_ARQUI )
	
	lOk := SendMail(cMail, cFilename, cMesRef, cAnoRef, cUserMail, cemailSent, cSenhaMail)
	
	If lOk
		dbSelectArea( "ZTB" )
		dbSetOrder( 2 )
		dbSeek( xFilial( "ZTB" ) + (cAliasQry)->ZTB_REFERE + (cAliasQry)->ZTB_EMAIL )
		While ZTB->( !Eof() ) .and. (cAliasQry)->( ZTB_REFERE + ZTB_EMAIL ) == ZTB->( ZTB_REFERE + ZTB_EMAIL )
			RecLock("ZTB", .F.)
			ZTB->ZTB_DTENVI := dDataBase
			ZTB->ZTB_STATU1 := "2"
			ZTB->( msUnlock() )
			ZTB->( dbSkip() )
		End
	Endif
	(cAliasQry)->( dbSkip() )
	
End

Return Nil



Static Function envAuto( nRegZTB, cEmail, cAnexo, cUserMail, cemailSent, cSenhaMail )
LOcal cMail			:= ""
Local cFilename	:= ""
Local lOk			:= .F.
Local aAreaSav		:= GetArea()
Local aAreaZTB		:= ZTB->( GetArea() )
Local cMesRef		:= ""
Local cAnoRef		:= ""
Local cRefereAnt	:= ""
Local eEmailAnt	:= ""


ZTB->( dbGoto( nRegZTB ) )
If ZTB->( !Eof() )
	cMesRef 		:= left( ZTB->ZTB_REFERE, 2 )
	cAnoRef		:= right( ZTB->ZTB_REFERE, 4 )
	
	cMail 		:= ZTB->ZTB_EMAIL
	cFileName 	:= Alltrim( ZTB->ZTB_ARQUI )
	cRefereAnt	:= ZTB->ZTB_REFERE
	cEmailAnt	:= ZTB->ZTB_EMAIL
	
	If Alltrim(Upper( cMail )) == Alltrim(Upper( cEmail )) .and. ZTB->ZTB_STATU1 <> "2"
		
		lOk := SendMail(cMail, cFilename, cMesRef, cAnoRef, cUserMail, cemailSent, cSenhaMail)
		
		If lOk
			
			dbSelectArea( "ZTB" )
			dbSetOrder( 2 ) //ZTB_FILIAL+ZTB_REFERE+ZTB_EMAIL+ZTB_TIPO
			dbSeek( xFilial( "ZTB" ) + cRefereAnt + cEmailAnt )
			
			While ZTB->( !Eof() ) .and. cRefereAnt + cEmailAnt == ZTB->( ZTB_REFERE + ZTB_EMAIL )
				RecLock("ZTB", .F.)
				ZTB->ZTB_DTENVI := dDataBase
				ZTB->ZTB_STATU1 := "2"
				ZTB->( msUnlock() )
				ZTB->( dbSkip() )
			End
			
		Endif
	Endif
Endif

RestArea( aAreaZTB )
RestArea( aAreaSav )

Return Nil


Static Function Verchk(oListBox1,aListBox1,lCheck)
Local nX		:= 0

For nX := 1 to len( aListBox1 )
	aListBox1[nX][1] := lCheck
Next nX

SetLst1(oListBox1, aListBox1 ) // atualiza o vetor da listbox
Return Nil




Static Function trname( xemail )
Local cRet		:= ""

cRet := alltrim( xEmail )

cRet := strTran( cRet, ".", "_" )

cRet := strTran( cRet, "@", "_" )

Return cRet



Static Function GetUsermail()
Local aUsuario		:= {}
Local aRet			:= {}
Local aParambox	:= {}
Local aResp			:= {}

PswOrder(1)
PswSeek(__cUserId)
aUsuario :=	PswRet()

aadd( aRet, aUsuario[1][04] )
aadd( aRet, aUsuario[1][14] )
aadd( aRet, "" )

While .T.
	aParambox 	:= {}
	aResp			:= {}
	
	aAdd(aParamBox,{1,"Assinatura" 		,padr(aRet[1], 40),"","","","",0, .F.  })
	aAdd(aParamBox,{1,"Email"          	,Padr(aRet[2], 50),"","","","",0, .F.  })
	aAdd(aParamBox,{1,"Senha Email"     ,Space(15)			,"","","","",0, .T.  })
	
	If ParamBox(aParamBox,"Usuario Envio Email",@aResp)
		If Conecta( aResp[2], aResp[3] )
			aRet[1] := Alltrim( aResp[1] )
			aRet[2] := Alltrim( aResp[2] )
			aRet[3] := Alltrim( aResp[3] )
			Exit
		Else
			ApMsgAlert( "Falha de conex? ao tentar enviar email! Verifique a senha!", "Senha" )
		Endif
	Else
		aRet		:= {}
		Exit
	Endif
End

Return aRet



Static Function Conecta( cEmail, cSenha )
Local lRet		:= .T.
Local oMail
Local nErro		:= 0
Local lConect	:= .F.

lConect := GetMV( "MV_SZPREC1",, .F.)
If lConect
	oMail := TMailManager():New()
	oMail:SetUseSSL(.T.)
	oMail:Init( '', Alltrim(GetMv("MV_SZPREC4",,'smtp.gmail.com')) , Alltrim(cEmail),Alltrim(cSenha), 0, GetMv("MV_SZPREC5",,465) )
	oMail:SetSmtpTimeOut( GetMv("MV_SZPREC6",,60) )
	nErro := oMail:SmtpConnect()
	If nErro <> 0
		conout( "ERROR: Conectando - " + oMail:GetErrorString( nErro ) )
		oMail:SMTPDisconnect()
		lRet := .F.
	Endif
	If lRet
		nErro := oMail:SmtpAuth( Alltrim(cEmail), Alltrim(cSenha) )
		If nErro <> 0
			conout( "ERROR:2 autenticando - " + oMail:GetErrorString( nErro ) )
			oMail:SMTPDisconnect()
			lRet := .F.
		Endif
	Endif
	
	oMail:SMTPDisconnect()
Else
	lRet := .T.
Endif

Return lRet




Static Function ChecaPend()
Local cQuery		:= ""
Local cAliasQry	:= GetNextAlias()
Local lRet			:= .F.

cQuery := ""
cQuery += "SELECT TOP 10 ZTB_EMAIL, ZTB_REFERE, ZTB.R_E_C_N_O_ AS ZTB_NUMREG "
cQuery += "FROM " + RetSqlName( "ZTB" ) + " ZTB "
cQuery += "WHERE ZTB_FILIAL = '" + xFilial( "ZTB" ) + "' "
cQuery += "AND ZTB_STATUS = '2' "
cQuery += "AND ZTB_STATU1 IN ( '1', '3' ) "
cQuery += "AND ZTB.D_E_L_E_T_ = ' ' "
cQuery += "ORDER BY ZTB_EMAIL, ZTB_COD_AL "

cQuery := ChangeQuery(cQuery)

If Select( cAliasQry ) > 0
	dbSelectArea( cAliasQry )
	( cAliasQry )->( dbCloseArea() )
Endif

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasQry, .F., .T.)
TcSetField( cAliasQry, 	"ZTB_NUMREG", 	"N", 	10,	00 )

If ( cAliasQry )->( !Eof() )
	lRet := .T.
Endif

If Select( cAliasQry ) > 0
	dbSelectArea( cAliasQry )
	( cAliasQry )->( dbCloseArea() )
Endif

Return lRet




User Function FSMakeDir(cOrigem)
Local cRet 		:= Alltrim(cOrigem)
Local nPOs		:= 0
Local cDir		:= ""
Local cTrab		:= ""
Local cDrive	:= ""
Local lDisco	:= .F.
Local aPath		:= {}

If Right(cRet,1) <> "\"
	cRet += "\"
Endif

cTrab := cRet

//drive
nPos := at(":\",cRet)
If nPos > 0
	cDrive := left(cRet, nPos+1)
	cRet := Substr(cRet, nPos+2)
	lDisco := .T.
Endif

If !lDisco
	//drive
	nPos := at("\\",cRet)
	If nPos > 0
		cDrive := left(cRet, nPos+1)
		cRet := Substr(cRet, nPos+2)
		lDisco := .T.
		nPos := at("\",cRet)
		If nPos > 0
			cDrive += left(cRet, nPos-1)
			cRet := Substr(cRet, nPos+1)
		Endif
		If right(cDrive,1) <> "\"
			cDrive += "\"
		Endif
	Endif
Endif

While len(cRet) > 0  .and. lDisco
	
	cDir := ""
	nPos := at("\",cRet)
	If nPos <> 0
		If nPos <> 1
			If substr(cRet, nPos-1,1) <> ":"
				cDir := left(cRet, nPos -1 )
				cRet := Substr(cRet, nPos+1)
			Else
				cRet := Substr(cRet, nPos+1)
			Endif
		Else
			cRet := Substr(cRet,2)
		Endif
	Else
		cDir := cRet
		cRet := ""
	Endif
	If !Empty(cDir)
		aadd(aPath, cDir)
	Endif
End
cRet := cDrive
For nPos := 1 to len(aPath)
	cRet += aPath[nPos]
	MakeDir( cRet)
	cRet += "\"
Next
cRet := cTrab
Return(cRet)



User Function GRDA017(cAlias, nReg, nOpc)
local aAreaSAv			:= GetArea()

dbSelectArea( cAlias )
dbGoto( nReg )

If Alltrim(Upper( cAlias )) == "ZTB"
	
	If (ZTB->ZTB_STATUS == "2" .and. ZTB->ZTB_STATU1 == "1" ) .or. (ZTB->ZTB_STATUS == "2" .and. ZTB->ZTB_STATU1 == "3" )
		RecLock( "ZTB", .F. )
		ZTB->ZTB_STATU1	:= "2"
		ZTB->ZTB_DTENVI	:= dDataBase
		ZTB->( MsUnlock() )
		ApMsgInfo( "email de " + Alltrim( ZTB->ZTB_EMAIL ) + " marcado como enviado!", "Marcar como enviado" )
	Else
		ApMsgAlert( "Este registro n? pode ter seu status modificado, somente emails aguardando envio podem ter seu status trocado!", "Marcar como enviado" )
	Endif
	
Endif

RestArea( aAreaSav )
Return Nil



User Function GRDA018(cAlias, nReg, nOpc)
local aAreaSAv			:= GetArea()
Local cLocalSpool		:= Alltrim( GetMV("MV_SZPREC3",,"\spool\boletos\") )
Local cNomFile1		:= ""

dbSelectArea( cAlias )
dbGoto( nReg )

If Right( cLocalSpool, 1 ) <> "\"
	cLocalSpool += "\"
Endif

If Alltrim(Upper( cAlias )) == "ZTB"
	
	If (ZTB->ZTB_STATUS == "2" .and. ZTB->ZTB_STATU1 == "2" )
		cNomFile1 := Alltrim( ZTB->ZTB_ARQUI )
		If File( cLocalSpool + cNomFile1 )
			
			RecLock( "ZTB", .F. )
			ZTB->ZTB_STATU1	:= "1"
			ZTB->ZTB_DTENVI	:= cTod( " " )
			ZTB->( MsUnlock() )
			ApMsgInfo( "email de " + Alltrim( ZTB->ZTB_EMAIL ) + " marcado como pendente de envio!", "Marcar como pendente" )
		Else
			ApMsgAlert( "Este registro n? pode ter seu status modificado, o arquivo PDF com o boleto n? foi localizado!", "Marcar como pendente" )
		Endif
	Else
		ApMsgAlert( "Este registro n? pode ter seu status modificado, somente emails enviados podem ser marcados como n? enviados!", "Marcar como pendente" )
	Endif
	
Endif

RestArea( aAreaSav )
Return Nil
