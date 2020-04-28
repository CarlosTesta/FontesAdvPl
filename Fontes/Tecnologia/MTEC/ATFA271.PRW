#INCLUDE "ATFA271.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE 'FWMVCDEF.CH'

STATIC lArgentina 	:= If(cPaisLoc$"ARG",.T.,.F.)
STATIC lIsRussia	:= If(cPaisLoc$"RUS",.T.,.F.) // CAZARINI - Flag to indicate if is Russia location

//------------------------------------------------------------------------------------------
/* {Protheus.doc} ATFA271
Manutencao de grupo de bens utilizando a tabela FNG para facilitar a classificação dos tipos de ativo

@author    Alvaro Camillo Neto
@version   11.80
@since     13/05/2013admin
@protected
*/
//------------------------------------------------------------------------------------------

Function ATFA271()
Local oBrowse := Nil

// Incluido por causa da rotina MSDOCUMENT, o MVC não precisa de nenhuma variável private
Private cCadastro	:= STR0001 //"Grupo de Bens"
Private aRotina		:= MenuDef()

If FWHASMVC()
	CHKFile("SNG")
	CHKFile("FNG")

	oBrowse := BrowseDef()

	oBrowse:Activate()
Else
	Help(" ",1,"AF271MVC",,STR0013,1,0) //"Ambiente desatualizado, por favor atualizar com o ultimo pacote da lib "
EndIf

Return Nil

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} BrowseDef
Defines the standard browse to Asset Group file

@type function
 
@author Fabio Cazarini
@since 21/04/2017
@version P12.1.17
 
/*/
//------------------------------------------------------------------------------------------
Static Function BrowseDef()
Local oBrowse
	
oBrowse := FWmBrowse():New()

//Graphics and Visions of Browse
oBrowse:SetAttach( .T. )
oBrowse:SetOpenChart( .T. )

oBrowse:SetAlias( 'SNG' )
oBrowse:SetDescription( STR0001 )	//"Grupo de Bens"
		
Return oBrowse

//------------------------------------------------------------------------------------------
/* {Protheus.doc} MenuDef
Menu Funcional

@author    Alvaro Camillo Neto
@version   11.80
@since     13/05/2013
@protected

*/
//------------------------------------------------------------------------------------------

Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE STR0005	 ACTION 'PesqBrw'				OPERATION 1 ACCESS 0	//'Pesquisar'
ADD OPTION aRotina TITLE STR0006	 ACTION 'VIEWDEF.ATFA271'	OPERATION 2 ACCESS 0	//'Visualizar'
ADD OPTION aRotina TITLE STR0007	 ACTION 'VIEWDEF.ATFA271'	OPERATION 3 ACCESS 0	//'Incluir'
ADD OPTION aRotina TITLE STR0008	 ACTION 'VIEWDEF.ATFA271'	OPERATION 4 ACCESS 0	//'Alterar'
ADD OPTION aRotina TITLE STR0009	 ACTION 'VIEWDEF.ATFA271'	OPERATION 5 ACCESS 0	//'Excluir'
ADD OPTION aRotina TITLE STR0017	 ACTION 'Af271Exp'			OPERATION 5 ACCESS 0	//'Exportar'
ADD OPTION aRotina TITLE STR0018	 ACTION 'Af271Imp'			OPERATION 3 ACCESS 0	//'Importar'



Return aRotina

//------------------------------------------------------------------------------------------
/* {Protheus.doc} ModelDef
Modelo de negócio do cadastro de grupo de ativo

@author    Alvaro Camillo Neto
@version   11.80
@since     13/05/2013
@protected

*/
//------------------------------------------------------------------------------------------
Static Function Modeldef()
Local oStruSNG		:= FWFormStruct( 1, "SNG" )
Local oStruFNG		:= FWFormStruct( 1, "FNG" )
Local oModel		:= Nil
Local aRelacFNG		:= {}
Local __nQuantas	:= AtfMoedas()
Local nX			:= 0
Local lArgentina 	:= cPaisLoc == "ARG"  
Local lArgentina 	:= cPaisLoc == "ARG"  
Private cCampoSNG	:= ""
Private cCampoFNG	:= ""

//Gatilhos
oStruSNG:AddTrigger( "NG_TXDEPR1", "NG_TXDEPR1" , {|| .T. }  , {|| AF271GAT("NG_TXDEPR1","FNG_TXDEP1") }  )
oStruSNG:AddTrigger( "NG_TXDEPR2", "NG_TXDEPR2" , {|| .T. }  , {|| AF271GAT("NG_TXDEPR2","FNG_TXDEP2") }  )
oStruSNG:AddTrigger( "NG_TXDEPR3", "NG_TXDEPR3" , {|| .T. }  , {|| AF271GAT("NG_TXDEPR3","FNG_TXDEP3") }  )
oStruSNG:AddTrigger( "NG_TXDEPR4", "NG_TXDEPR4" , {|| .T. }  , {|| AF271GAT("NG_TXDEPR4","FNG_TXDEP4") }  )
oStruSNG:AddTrigger( "NG_TXDEPR5", "NG_TXDEPR5" , {|| .T. }  , {|| AF271GAT("NG_TXDEPR5","FNG_TXDEP5") }  )

oStruSNG:AddTrigger( "NG_TPDEPR", "NG_TPDEPR" , {|| .T. }  , {|| AF271GAT("NG_TPDEPR","FNG_TPDEPR") }  )
oStruSNG:AddTrigger( "NG_TPSALDO", "NG_TPSALDO", {|| .T. }, {|| AF271GAT("NG_TPSALDO","FNG_TPSALD") }  )

If lArgentina
	oStruSNG:AddTrigger( "NG_CRIDEPR", "NG_CRIDEPR" , {|| .T. }  , {|| AF271GAT("NG_CRIDEPR","FNG_CRIDEP") }  )
Endif

oStruSNG:AddTrigger( "NG_CALDEPR", "NG_CALDEPR" , {|| .T. }  , {|| AF271GAT("NG_CALDEPR","FNG_CALDEP") }  )

oStruFNG:AddTrigger( "FNG_TXDEP1", "FNG_TXDEP1" , {|| .T. }  , {|| AF271TAXA() }  )

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New( 'ATFA271', /*bPreValidacao*/, {|oModel| AF271TOk(oModel) },  /*bGravacao*/ , /*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
oModel:AddFields( 'SNGMASTER', /*cOwner*/, oStruSNG )

// Adiciona ao modelo uma estrutura de formulário de edição por grid
oModel:AddGrid( 'FNGDETAIL'	, 'SNGMASTER'	, oStruFNG, /*bLinePre*/, { |oModelGrid,cAction| AF271LOK(oModelGrid,cAction) } , /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

//Relacionamento da tabela Item da Provisao
aAdd(aRelacFNG,{ 'FNG_FILIAL'	, 'xFilial( "FNG" )'	})
aAdd(aRelacFNG,{ 'FNG_GRUPO'		, 'NG_GRUPO'		    })

// Faz relaciomaneto entre os compomentes do model
oModel:SetRelation( 'FNGDETAIL', aRelacFNG , FNG->( IndexKey( 1 ) )  )

// Liga o controle de nao repeticao de linha
oModel:GetModel( 'FNGDETAIL' ):SetUniqueLine( { 'FNG_TIPO','FNG_TPSALD' } )

// Adiciona a descricao do Modelo de Dados
oModel:SetDescription( STR0001 )  //'Grupo de Bens'

// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel( 'SNGMASTER' ):SetDescription( STR0001 ) //"Grupo de Bens"
oModel:GetModel( 'FNGDETAIL' ):SetDescription( STR0014 ) //"Itens do Grupo de Bens"

// Ativa o uso do aHeader/aCols 
oModel:GetModel( 'FNGDETAIL' ):SetUseOldGrid( .T. )

oModel:SetVldActivate( {|oModel| AF271OkDel(oModel) } )

Return oModel

//------------------------------------------------------------------------------------------
/* {Protheus.doc} ModelDef
Modelo de negócio do cadastro de grupo de ativo

@author    Alvaro Camillo Neto
@version   11.80
@since     13/05/2013
@protected

*/
//------------------------------------------------------------------------------------------

Static Function Viewdef()
// Cria a estrutura a ser usada na View
Local oStruSNG := FWFormStruct( 2, 'SNG' )
Local oStruFNG := FWFormStruct( 2, 'FNG' )

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel	:= FWLoadModel( 'ATFA271' )
Local oView		:= Nil

// Remove campos da estrutura para nao aparecer na grid

oStruFNG:RemoveField( 'FNG_FILIAL' )
oStruFNG:RemoveField( 'FNG_GRUPO' )

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel( oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField( 'VIEW_SNG', oStruSNG, 'SNGMASTER' )

//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
oView:AddGrid(  'VIEW_FNG', oStruFNG, 'FNGDETAIL' )

// Criar "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox( 'SUPERIOR' , 50 )
oView:CreateHorizontalBox( 'INFERIOR' , 50 )

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView( 'VIEW_SNG', 'SUPERIOR' )
oView:SetOwnerView( 'VIEW_FNG', 'INFERIOR' )

// Liga a identificacao do componente
oView:EnableTitleView( 'VIEW_SNG' )
oView:EnableTitleView( 'VIEW_FNG' )

Return oView

//------------------------------------------------------------------------------------------
/* {Protheus.doc} AF271LOK
Validacao para linha OK

@author    Alvaro Camillo Neto
@version   11.80
@since     13/05/2013
@protected

*/
//------------------------------------------------------------------------------------------

Static Function AF271LOK(oModelFNG)
Local lRet			:= .T.
Local nI			:= 0
Local cTipoAtf		:= oModelFNG:GetValue("FNG_TIPO")
Local aSaveLines	:= FWSaveRows()
Local nLinha		:= oModelFNG:GetLine()

If cTipoAtf $ "01#03"
	oModelFNG:GoLine(1)

	For nI := 1 to oModelFNG:Length()
		oModelFNG:GoLine(nI)
		If nI != nLinha .And. oModelFNG:GetValue("FNG_TIPO") == cTipoAtf .And. !oModelFNG:IsDeleted()
			Help(" ",1,"AF271TIP0",,STR0003,1,0)  //"É permitido a inclusão de apenas um item do tipo 01/03 por grupo"
		    lRet := .F.
		    Exit
		EndIf
	Next nI

	oModelFNG:GoLine(nLinha)
EndIf

//Verifica se possui ativos de aquisicao e ativos de aquisicao na configuracao ao mesmo tempo
If lRet
	//ativo de aquisicao
	If cTipoAtf $ "01#10#16#17" 
		oModelFNG:GoLine(1)
		For nI := 1 to oModelFNG:Length()
			oModelFNG:GoLine(nI)
			If nI != nLinha .And. oModelFNG:GetValue("FNG_TIPO") $ "03#13" .And. !oModelFNG:IsDeleted()
				Help(" ",1,"AF271TPAQ",,STR0015,1,0)  //"Não é permitido a configuração de ativos de aquisição com ativos de adiantamento."
				lRet := .F.
				Exit
			EndIf
		Next nI
		oModelFNG:GoLine(nLinha)
	EndIf

	//ativo de adiantamento
	If cTipoAtf $ "03#13"
		oModelFNG:GoLine(1)
		For nI := 1 to oModelFNG:Length()
			oModelFNG:GoLine(nI)
			If nI != nLinha .And. oModelFNG:GetValue("FNG_TIPO") $ "01#10#16#17" .And. !oModelFNG:IsDeleted()
				Help(" ",1,"AF271TPAD",,STR0016,1,0)  //"Não é permitido a configuração de ativos de adiantamento com ativos de aquisição."
				lRet := .F.
				Exit
			EndIf
		Next nI
		oModelFNG:GoLine(nLinha)
	EndIf
Endif

If lRet
	If lArgentina
		If Alltrim(oModelFNG:GetValue("FNG_CRIDEP")) $ "03|04"
			If !(oModelFNG:GetValue("FNG_TIPO") $ "10|12|16|17")
				Help(" ",1,"AF271VDEPC",,STR0012,1,0)//"Critério de depreciação não é valido para o tipo de ativo em questão"
				lRet:= .F.
			EndIf
		Endif
	EndIf
EndIf

If lRet
	lRet:= ATFSALDEPR(oModelFNG:GetValue("FNG_TIPO"), oModelFNG:GetValue("FNG_TPSALD"), oModelFNG:GetValue("FNG_TPDEPR") )
EndIf

FWRestRows(aSaveLines)

Return lRet

//------------------------------------------------------------------------------------------
/* {Protheus.doc} AF271LOK
Validação do campo FNG_TPDEPR

@author    Alvaro Camillo Neto
@version   11.80
@since     13/05/2013
@protected

*/
//------------------------------------------------------------------------------------------

Function AF271AVTIP(cTpDepr)
Local lRet		:= .T.
Local oModel	:= FWModelActive()
Local oModelFNG	:= oModel:GetModel("FNGDETAIL")

Default cTpDepr	:= oModelFNG:GetValue("FNG_TPDEPR")

If lRet
	lRet:= ATFSALDEPR(oModelFNG:GetValue("FNG_TIPO"), oModelFNG:GetValue("FNG_TPSALD"), cTpDepr )
EndIf

Return lRet

//------------------------------------------------------------------------------------------
/* {Protheus.doc} AF271LOK
Validação do campo FNG_TPDEPR

@author    Alvaro Camillo Neto
@version   11.80
@since     13/05/2013
@deprecated   Funcao nao mais utilizada devido a conversão para o MVC

*/
//------------------------------------------------------------------------------------------

Function AFA271TX(cCampo)

Return .T.

//------------------------------------------------------------------------------------------
/* {Protheus.doc} AF271GAT
Gatilho dos campos da tabela FNG

@author    Alvaro Camillo Neto
@version   11.80
@since     13/05/2013
@protected

*/
//------------------------------------------------------------------------------------------

Static Function AF271GAT(cCampoNG,cCampoFNG)
Local oModel		:= FWModelActive()
Local oView			:= FWViewActive()
Local oModelFNG		:= oModel:GetModel("FNGDETAIL")
Local nX			:= 0
Local aSaveLines	:= FWSaveRows()
Local uConteud		:= oModel:GetValue("SNGMASTER",cCampoNG)

For nX:= 1 to oModelFNG:Length()
	oModelFNG:GoLine(nX)
	If Empty(oModelFNG:GetValue(cCampoFNG))
		oModelFNG:SetValue(cCampoFNG,uConteud)
	EndIf
Next nX

FWRestRows(aSaveLines)

//--------------------------------------------------------------------------------------------------------------------
//Incluída validação para a função de importação, pois após realizar operações(incluir, alterar, excluir ou visualizar 
//e retornar ao browser, o objeto oView não é está sendo destruido, continua instanciado.
//--------------------------------------------------------------------------------------------------------------------

If oView != Nil .AND. !FWIsInCallStack("Af271Imp")
	oView:Refresh()
EndIf

Return uConteud



//------------------------------------------------------------------------------------------
/* {Protheus.doc} AF271OkDel
Valida a exclusao do Grupo de Bens

@author    Alvaro Camillo Neto
@version   11.80
@since     13/05/2013
@protected

*/
//------------------------------------------------------------------------------------------

Static Function AF271OkDel(oModel)
Local aArea			:= GetArea()
Local lDefTop		:= IfDefTop()
Local cAliasBem		:= GetNextAlias()
Local lRet			:= .T.
Local nOperation	:= oModel:GetOperation()
Local cGrupo		:= ''

If nOperation == MODEL_OPERATION_DELETE

	cGrupo := SNG->NG_GRUPO

	If lDefTop

		If Select(cAliasBem) > 0
			(cAliasBem)->(dbCloseArea())
		EndIf

		cQuery := " SELECT N1_GRUPO FROM " + RetSQLTab("SN1")+ " WHERE "
		cQuery += " N1_GRUPO  = '" + cGrupo          +"' AND "
		cQuery += RetSQLCond("SN1")

		cQuery := ChangeQuery(cQuery)

		DbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ), cAliasBem )

		If (cAliasBem)->(!EOF())
			Help(" ",1,"AF270DEL")
			lRet := .F.
		EndIf

		(cAliasBem)->(dbCloseArea())

	Else

		SN1->(dbSetOrder(1))
		If SN1->(MsSeek(xFilial("SN1")))
			While !(SN1->(Eof()))
				If SN1->N1_GRUPO == M->NG_GRUPO
					Help(" ",1,"AF270DEL")
					lRet := .F.
					Exit
				Endif
				dbSkip()
			Enddo
		Endif

	Endif
Endif

RestArea(aArea)

Return lRet


//------------------------------------------------------------------------------------------
/* {Protheus.doc} AF271TOk
O Grupo de Bens

@author    Eduardo Lima
@version   12.70
@since     18/12/2015
@protected

*/
//------------------------------------------------------------------------------------------

Static Function AF271TOk(oModel)
Local aArea			:= GetArea()
Local lDefTop		:= IfDefTop()
Local cAliasBem		:= GetNextAlias()
Local lRet			:= .T.
Local nOperation	:= oModel:GetOperation()
Local cGrupo		:= ''
lRet := lRet .and. CtbAmarra(M->NG_CCONTAB,M->NG_CUSTBEM,M->NG_SUBCCON,M->NG_CLVLCON,.T.,.T.)
lRet := lRet .and. CtbAmarra(M->NG_CDEPREC,M->NG_CCDESP,M->NG_SUBCDEP,M->NG_CLVLDEP,.T.,.T.)
lRet := lRet .and. CtbAmarra(M->NG_CCDEPR,M->NG_CCCDEP,M->NG_SUBCCDE,M->NG_CLVLCDE,.T.,.T.)
lRet := lRet .and. CtbAmarra(M->NG_CDESP,M->NG_CCCDES,M->NG_SUBCDES,M->NG_CLVLDES,.T.,.T.)
lRet := lRet .and. CtbAmarra(M->NG_CCORREC,M->NG_CCCORR,M->NG_SUBCCOR,M->NG_CLVLCOR,.T.,.T.)

RestArea(aArea)

Return lRet

//------------------------------------------------------------------------------------------
/* {Protheus.doc} AF271TAXA
Gatilho para preenchimento das taxas das demais moedas com base na moeda 1 (tabela FNG)

@author    Marcos R. Pires
@version   11.80
@since     24/07/2013
@protected

*/
//------------------------------------------------------------------------------------------

Static Function AF271TAXA()
Local oModel		:= FWModelActive()
Local oView			:= FWViewActive()
Local oModelFNG		:= oModel:GetModel("FNGDETAIL")
Local uConteud		:= oModelFNG:GetValue("FNG_TXDEP1")
Local __nQuantas	:= AtfMoedas()
Local nX			:= 0

If !IsInCallStack("AF271GAT") //Evita que o gatilho do campo NG_TXDEPR1 ative o gatilho do FNG_TXDEP1

	For nX := 2 To __nQuantas

		If AScan(oModelFNG:aHeader,{|x| AllTrim(x[2]) == "FNG_TXDEP"+AllTrim(Str(nX)) }) <= 0 .Or.;	//Avalia se o campo de taxa da moeda esta presente
			Empty(GetMv("MV_MOEDA" + AllTrim(Str(nX))))												//Se não tem a moeda informada no parâmetro (Moeda em branco)
			Loop
		EndIf

		oModelFNG:SetValue("FNG_TXDEP" + AllTrim(Str(nX)),uConteud)

	Next nX

	If oView != Nil
		oView:Refresh()
	EndIf

EndIf

Return uConteud

//-------------------------------------------------------------------
/*/{Protheus.doc} Af271Exp
Pergunta de exportacao de grupo de ativo

@author alvaro.camillo

@since 26/11/2013
@version 1.0
/*/
//-------------------------------------------------------------------

Function Af271Exp()
Local lRet    := .T.
Local aSelFil	:= {}

SaveInter()

If Pergunte("AF271EXP",.T.)
	If MV_PAR04 == 1
		aSelFil := AdmGetFil(.F.,.T.,"SNG")
		If Empty(aSelFil)
			Help(" ",1,"AF271FIL",,STR0032, 1, 0 ) //"Selecione a filial para consulta"
			lRet := .F.
		EndIf
	Else
		aSelFil := {cFilAnt}
	EndIf

	If lRet
		MsgRun( STR0023 ,, {||	lRet := ExportGrp(MV_PAR01,MV_PAR02,MV_PAR03,aSelFil ) } )//"Exportando Grupo... "
	EndIf
EndIf

RestInter()

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} Af271Exp
Pergunta de exportacao de grupo de ativo

@author alvaro.camillo

@since 26/11/2013
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function ExportGrp(cArq,cGrupoDe,cGrupoAte,aSelFil )
Local lRet 		:= .T.
Local aArea		:= GetArea()
Local aAreaSNG	:= SNG->(GetArea())
Local aAreaFNG	:= FNG->(GetArea())

Local aTabela		:= {}
Local nX			:= 0
Local nY			:= 0
Local nFil			:= 0
Local cID			:= ""
Local cLin			:= ""
Local cAux			:= ""

Local aStrSNG	:= SNG->(DbStruct())
Local aStrFNG	:= FNG->(DbStruct())

Local nHandle 	:= 0
Local aStruct	:= {}

Local cFilX := cFilAnt

Default cArq := ""

SNG->(dbSetOrder(1))//NG_FILIAL+NG_GRUPO
FNG->(dbSetOrder(1))//FNG_FILIAL+FNG_GRUPO+FNG_TIPO+FNG_TPSALD


IF lRet .And. Empty( cArq )
	Help(" ",1,"AF271IMP01",,STR0024 ,1,0)//"Arquivo nao informado!"
	lRet := .F.
Endif

If lRet
	//Campo de Controle da Filial
	aAdd(aStrSNG,{"FILIALORIG","C",12,0})
	aAdd(aTabela,{"SNG",aStrSNG})
	aAdd(aTabela,{"FNG",aStrFNG})

	If At('.',cArq) == 0
		cArq	:=	AllTrim(cArq)+'.CSV'
	EndIf

	If (nHandle := FCreate(cArq))== -1
		Help(" ",1,"AF271IMP02",,STR0025 ,1,0)//"Erro na criacao do arquivo!"
	Return
	EndIf

	// Lista de tabelas
	cLin:="0"
	For nY := 1 to len(aTabela)
		cLin += ';'+aTabela[nY,1]
	Next
	cLin += CRLF
	FWrite(nHandle,cLin,Len(cLin))

	//Lista de Campos das tabelas
	For nY := 1 to len(aTabela)
		cId		:= Alltrim(str(nY))
		cLin 		:= cId
		aStruct	:= aTabela[nY,2]
		For nX:=1 To Len(aStruct)
			cLin	+=	';'+aStruct[nX,1]
		Next nX
		cLin += CRLF
		FWrite(nHandle,cLin,Len(cLin))
	Next nY

	For nFil := 1 to Len(aSelFil)

		cFilAnt := aSelFil[nFil]

		If cAux == xFilial("SNG")
			Loop
		Else
			cAux := xFilial("SNG")
		EndIf

		SNG->(dbSeek( xFilial("SNG") + cGrupoDe ,.T. ))
		While SNG->(!EOF()) .And. SNG->NG_FILIAL == xFilial("SNG") .AND. SNG->NG_GRUPO <= cGrupoAte

			cID	:= "1"
			cLin  := ExpLinGrp("SNG", aStrSNG, SNG->(Recno()),cId )
			FWrite(nHandle,cLin,Len(cLin))

			FNG->(MsSeek(  xFilial("FNG") + SNG->NG_GRUPO ))
			While FNG->(!EOF()) .And. FNG->(FNG_FILIAL+FNG_GRUPO) == xFilial("FNG") + SNG->NG_GRUPO

				cID	:= "2"
				cLin  := ExpLinGrp("FNG", aStrFNG, FNG->(Recno()),cId )
				FWrite(nHandle,cLin,Len(cLin))

				FNG->(dbSkip())
			EndDo

			SNG->(dbSkip())
		EndDo
	Next nFil

	FClose(nHandle)

	Aviso(STR0026,STR0027,{STR0028})//"Finalizado"##"Exportacao gerada com sucesso"##"OK"

EndIf

cFilAnt := cFilX
RestArea(aAreaFNG)
RestArea(aAreaSNG)
RestArea(aArea)

Return lRet



//-------------------------------------------------------------------
/*/{Protheus.doc} ExpLinGrp
Monta a linha da exportacao

@author alvaro.camillo

@since 24/10/2013
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function ExpLinGrp(cTab, aStruct, nRecno,cId)
Local aArea := GetArea()
Local cRet	:= ""
Local nX		:= 0

DbSelectArea(cTab)
(cTab)->(DbGoTo(nRecno))

cRet :=cId
For nX := 1 To Len(aStruct)
	Do Case
	Case aStruct[nX,1] == "FILIALORIG"
		cRet += ';'+cFilAnt
	Case aStruct[nX,2] == "C"
		cRet += ';'+(cTab)->( FieldGet(FieldPos(aStruct[nX,1])) )
	Case aStruct[nX,2] == "L"
		cRet += ';'+(cTab)->(IIf(FieldGet(FieldPos(aStruct[nX,1])),"T","F"))
	Case aStruct[nX,2] == "D"
		cRet += ';'+(cTab)->(Dtos(FieldGet(FieldPos(aStruct[nX,1]))))
	Case aStruct[nX,2] == "N"
		cRet += ';'+(cTab)->(Str(FieldGet(FieldPos(aStruct[nX,1]))))
	Otherwise
		cRet += ';'
	EndCase
Next
cRet += CRLF



RestArea(aArea)
Return cRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Af271Imp
Rotina de importacao de grupo de ativo

@author alvaro.camillo

@since 26/11/2013
@version 1.0
/*/
//-------------------------------------------------------------------

Function Af271Imp()

Local lRet    := .T.
Local aSelFil	:= {}

SaveInter()

If Pergunte("AF271IMP",.T.)

	If lRet
		MsgRun( STR0033 ,, {||	lRet := ImportGrp(MV_PAR01) } )//"Importando Grupo... "
	EndIf
EndIf

RestInter()

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} ImportGrp
Realiza a importação do grupo

@author alvaro.camillo

@since 24/10/2013
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ImportGrp(cArq)
Local lRet 		:= .T.
Local nHandle  	:= 0
Local aTabela		:= {}
Local aLinha		:= {}
Local aEstruct	:= {}
Local aDados		:= {}
Local aDadosAux	:= {}
Local cTabela		:= ""
Local nX			:= 0
Local nY			:= 0
Local nEtapa 		:= 0
Local nItem  		:= 0
Local nCfg			:= 0
Local aSNG			:= {}
Local aFNG 		:= {}
Local cArqDest	:= ""
Local cExt			:= ""
Local nCodGrupo	:= 0
Local cCodGrupo	:= ""
Local cCodFilial	:= ""
Local nFilialX	:= 0


SplitPath(cArq,,,@cArqDest,@cExt)

If (nHandle := FT_FUse(AllTrim(cArq)))== -1
	Help(" ",1,"NOFILEIMPOR")
	lRet:= .F.
EndIf

If lRet
	nTot:=FT_FLASTREC()
	FT_FGOTOP()

	//Realiza a Leitura da 1 linha para capturar as tabelas
	aLinha := AF271RDLN()
	FT_FSKIP()

	If Alltrim(aLinha[1]) != "0"
		Aviso(STR0034,STR0035,{STR0036})//"Estrutura incorreta."##"Cabecalho nao encontrado"##"Abandona"
		lRet := .F.
	EndIf

	If lRet
		For nX := 2 to Len(aLinha)
			AADD( aTabela, {aLinha[nX], {} } )
		Next nX
	EndIf

	// Carrega a estrutura da tabela
	If lRet
		For nX := 1 to Len(aTabela)
			aLinha := AF271RDLN()
			aEstruct := {}

			For nY := 2 to Len(aLinha)
				aAdd(aEstruct,aLinha[nY])
			Next nX

			aTabela[nX][2] := aClone(aEstruct)

			FT_FSKIP()
		Next nX
	EndIf

	//Realiza a Leitura dos dados
	Do While lRet .And. !FT_FEOF()

		aLinha := AF271RDLN()

		If Len(aLinha) <= 0
			FT_FSKIP()
			Loop
		EndIf

		nId := Val(aLinha[1])

		If nId <= 0 .Or. nId > Len(aTabela)
			lRet:= .F.
			Aviso(STR0034,STR0037,{STR0036})//"Estrutura incorreta."##"1º Elemento da Linha não contem Id da Tabela, por favor conferir layout"##"Abandona"
			Exit
		EndIf

		aDel(aLinha,1)
		aSize(aLinha,Len(aLinha)-1)

		cTabela	:= Alltrim(aTabela[nId][1])
		aEstruct := aTabela[nId][2]

		If ( Len(aLinha) ) != Len( aEstruct )
			lRet:= .F.
			Aviso(STR0034,STR0038,{STR0036})//"Estrutura incorreta."##"Quantidade de colunas de dados não confere com a quantidade de campos configurados nas primeiras linhas"##"Abandona"
			Exit
		EndIf

		aDadosAux := {}

		For nX := 1 to Len(aLinha)
			aAdd(aDadosAux,{ aEstruct[nX] , aLinha[nX] } )
		Next nX

		// Prepara as informações
		// Convertendo para os tipos corretos e verificando se o campo existe no dicionario
		aDados := AF271Dado(cTabela,aDadosAux)

		If cTabela == "SNG"
			nCodGrupo  := aScan( aDados, { |x| AllTrim( x[1] ) ==  "NG_GRUPO" } )
			nFilialX    := aScan( aDados, { |x| AllTrim( x[1] ) ==  "FILIALORIG" } )

			If nCodGrupo > 0 .And. nFilialX >0
				cCodGrupo := aDados[nCodGrupo][2]
				cCodFilial := aDados[nFilialX][2]
				aSNG := aClone(aDados)
			Else
				Aviso(STR0034,STR0050,{STR0036})//"Estrutura incorreta."##"Os campos obrigatorios não estão presentes na estrutrura, por favor verifique."##"Abandona"
				lRet := .F.
			EndIf

		ElseIf cTabela == "FNG"
			nTipo  := aScan( aDados, { |x| AllTrim( x[1] ) ==  "FNG_TIPO" } )
			nSaldo := aScan( aDados, { |x| AllTrim( x[1] ) ==  "FNG_TPSALD" } )

			If nTipo > 0 .And. nSaldo > 0
				aAdd(aFNG, { aDados[nTipo][2]+aDados[nSaldo][2] , aClone(aDados) } )
			EndIf

		EndIf

		FT_FSKIP()

		aLinha := AF271RDLN()

		If lRet .And. ( FT_FEOF() .Or. (!Empty(aLinha) .And. Val(aLinha[1]) == 1) )
			lRet := af271AUT(aSNG,aFNG,3,cCodFilial,cCodGrupo)
			aSNG 		:= {}
			aFNG 		:= {}
			cCodGrupo	:= ""
		EndIf
	EndDo

	FT_FUSE()


EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} af271AUT
Prepara as informações,Convertendo para os tipos corretos
  e verificando se o campo existe no dicionario

@author alvaro.camillo

Rotina de criação automatica de projetos.

Parametros:
Estruta dos Arrays
aSNG
[ [ cCampo , xConteudo ] ]
[ [ cCampo , xConteudo ] ]

aFNG
[ cTipo+cTpSald , [ [cCampo , xConteudo ] ] ]
[ cTipo+cTpSald  , [ [cCampo , xConteudo ] ] ]


nOperation : Opção para executar a importação

@since 24/10/2013
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function af271AUT(aSNG,aFNG,nOperation,cCodFilial,cCodGrupo)
Local lRet 			:= .T.
Local nCampo			:= 0
Local nEtapa   		:= 0
Local nItem			:= 0
Local nCFG 			:= 0
Local oModel			:= Nil
Local oModelSNG		:= Nil
Local oModelFNG		:= Nil

Local aCpoSNG  		:= {}
Local aCpoFNG			:= {}
Local aAuxFNG 	 	:= {}

Local nLinFNG			:= 0

Local nPos				:= 0
Local cDetalhe		:= ""
Local aArea			:= GetArea()
Local aAreaSNG		:= SNG->(GetArea())

Local lExistAud		:= .F.
Local nOper

Local nItErro			:= 0

Local cFilX			:= cFilAnt

Default nOperation   := MODEL_OPERATION_INSERT


//Ordenação dos array de entrada
aSort(aFNG,,,{|x,y| x[1] < y[1] })

SNG->(dbSetOrder(1))//NG_FILIAL+NG_GRUPO
FNG->(dbSetOrder(1))//FNG_FILIAL+FNG_GRUPO+FNG_TIPO+FNG_TPSALD

cFilAnt := cCodFilial

lExistAud := SNG->(MSSeek(xFilial("SNG") + cCodGrupo ))

If lExistAud //  Retorno da função
	lRet := .F.
	Help(" ",1,"af271IMPNAO",,STR0039 ,1,0)//"Esse grupo já existe."
EndIf

If lRet
	oModel := FWLoadModel( 'ATFA271' )
	oModel:SetOperation( nOperation )
	lRet := oModel:Activate()
EndIf

If lRet
	oModelSNG	:= oModel:GetModel( "SNGMASTER" )
	oModelFNG	:= oModel:GetModel( "FNGDETAIL" )

	aCpoSNG	:= oModelSNG:GetStruct():GetFields()
	aCpoFNG	:= oModelFNG:GetStruct():GetFields()

EndIf


//Carrega Cabeçalho
If lRet
	For nCampo := 1 To Len( aSNG )
		If ( nPos := aScan( aCpoSNG, { |x| AllTrim( x[3] ) ==  AllTrim( aSNG[nCampo][1] ) } ) ) > 0
			If !( lAux := af271SetVl("SNG",oModelSNG,aSNG[nCampo][1], aSNG[nCampo][2] ) )
				lRet    := .F.
				Exit
			EndIf
		EndIf
	Next nCampo
EndIf

If lRet
	nLinFNG := 1

	For nItem := 1 To Len( aFNG )
		aDadosFNG	:= aFNG[nItem][2]
		cItem		:= aFNG[nItem][1]

		If nLinFNG > 1
			// Incluimos uma nova linha de item
			If  ( nItErro := oModelFNG:AddLine() ) != nLinFNG
				// Se por algum motivo o metodo AddLine() não consegue incluir a linha,
				// ele retorna a quantidade de linhas já
				// existem no grid. Se conseguir retorna a quantidade mais 1
				lRet    := .F.
				Exit
			EndIf
		EndIf

		For nCampo := 1 To Len( aDadosFNG )
			If ( nPos := aScan( aCpoFNG, { |x| AllTrim( x[3] ) ==  AllTrim( aDadosFNG[nCampo][1] ) } ) ) > 0
				If !( lAux := af271SetVl("FNG",oModelFNG,aDadosFNG[nCampo][1], aDadosFNG[nCampo][2]  ) )
					lRet    := .F.
					nItErro := nLinFNG
					Exit
				EndIf
			EndIf
		Next nCampo

		nLinFNG++

		If !lRet
			Exit
		EndIf

	Next nItem

EndIf

If lRet .And. oModel:VldData()

	cCodAud := oModelSNG:GetValue("NG_GRUPO")

	oModel:CommitData()


	If lRet
		If oModel != Nil
			oModel:DeActivate()
		EndIf
	EndIf
Else
	lRet := .F.
EndIf

If oModel != Nil .And. !lRet
	// Se os dados não foram validados obtemos a descrição do erro para gerar LOG ou mensagem de aviso
	aErro   := oModel:GetErrorMessage()
	// A estrutura do vetor com erro é:
	//  [1] Id do formulário de origem
	//  [2] Id do campo de origem
	//  [3] Id do formulário de erro
	//  [4] Id do campo de erro
	//  [5] Id do erro
	//  [6] mensagem do erro
	//  [7] mensagem da solução
	//  [8] Valor atribuido
	//  [9] Valor anterior

	AutoGrLog( STR0040 + ' [' + AllToChar( aErro[1]  ) + ']' )//"Id do formulário de origem:"
	AutoGrLog( STR0041 + ' [' + AllToChar( aErro[2]  ) + ']' )//"Id do campo de origem:     "
	AutoGrLog( STR0042 + ' [' + AllToChar( aErro[3]  ) + ']' )//"Id do formulário de erro:  "
	AutoGrLog( STR0043 + ' [' + AllToChar( aErro[4]  ) + ']' )//"Id do campo de erro:       "
	AutoGrLog( STR0044 + ' [' + AllToChar( aErro[5]  ) + ']' )//"Id do erro:                "
	AutoGrLog( STR0045 + ' [' + AllToChar( aErro[6]  ) + ']' )//"Mensagem do erro:          "
	AutoGrLog( STR0046 + ' [' + AllToChar( aErro[7]  ) + ']' )//"Valor atribuido:           "
	AutoGrLog( STR0047  + ' [' + AllToChar( aErro[8]  ) + ']' )//"Valor atribuido:           "
	AutoGrLog( STR0048 + ' [' + AllToChar( aErro[9]  ) + ']' )//"Valor anterior:            "

	If nItErro > 0
		AutoGrLog( STR0049 + ' [' + AllTrim( AllToChar( nItErro  ) ) + ']' )//" Erro na Importação, verifique "
	EndIf

	MostraErro()
	If oModel != Nil
	// Desativamos o Model
		oModel:DeActivate()
	EndIf
EndIf


cFilAnt := cFilX
RestArea(aAreaSNG)
RestArea(aArea)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} af271SetVl
Valida o campo para importação

@author alvaro.camillo

@since 24/10/2013
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function af271SetVl(cTabela,oModel,cCampo,cConteudo)
Local lRet 		:= .T.
Local aArea 		:= GetArea()
Local aAreaSX3	:= SX3->(GetArea())

cCampo := Alltrim(cCampo)

SX3->(dbSetOrder(2)) // X3_CAMPO

If SX3->(MsSeek(cCampo))
	If X3USO(SX3->X3_USADO) .And. SX3->X3_VISUAL != "V" .And. SX3->X3_CONTEXT != "V" .And. !( "_MSBLQL" $ SX3->X3_CAMPO )
		If !Empty(cConteudo)
			If Empty(oModel:GetValue(cCampo))
				lRet := oModel:SetValue( cCampo , cConteudo )
			EndIf
		EndIf
	EndIf
EndIf

RestArea(aAreaSX3)
RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} af271Dado
Prepara as informações,Convertendo para os tipos corretos
  e verificando se o campo existe no dicionario
@author alvaro.camillo

@since 24/10/2013
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function AF271Dado(cTabela,aDados)
Local aRet 		:= {}
Local aStruct  := (cTabela)->(dbStruct())
Local nX			:= 0
Local nPos		:= 0


For nX := 1 to Len(aDados)
	If ( nPos := aScan( aStruct, { |x| AllTrim( x[1] ) ==  AllTrim( aDados[nX][1] ) } ) ) > 0
		Do Case
			Case aStruct[nPos][2] == "C"
				AADD(aRet,{aStruct[nPos][1] , Alltrim(aDados[nX][2]) })

			Case aStruct[nPos][2] == "L"
				AADD(aRet,{aStruct[nPos][1] , aDados[nX][2]=="T" })

			Case aStruct[nPos][2] == "D"
				AADD(aRet,{aStruct[nPos][1] , STOD( aDados[nX][2] ) })

			Case aStruct[nPos][2] == "N"
				AADD(aRet,{aStruct[nPos][1] , Val( aDados[nX][2] ) })
		EndCase
	ElseIf Alltrim(aDados[nX][1]) == "FILIALORIG"
		AADD(aRet,{"FILIALORIG" , Alltrim(aDados[nX][2]) })
	EndIf
Next nX


Return aClone(aRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} AF271RDLN
Realiza a Leitura da Linha e retorna um array com os dados já separados

@author alvaro.camillo

@since 24/10/2013
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function AF271RDLN()
Local aLinha := {}
Local cLinha := ""

//Tratamento para linhas com tamanho superior a 1020 Bytes
If ( Len(FT_FREADLN()) < 1023 )
	cLinha	:= FT_FREADLN()
Else
	cLinha	:= ""
	While .T.
		/*Verifica se encontrou o final da linha.*/
		If ( Len(FT_FREADLN()) < 1023 )
			cLinha += FT_FREADLN()
			Exit
		Else
			cLinha += FT_FREADLN()
			FT_FSKIP()
		EndIf
	EndDo
EndIf

aLinha := StrToKarr( cLinha, ";" )

Return aLinha

//-------------------------------------------------------------------
/*/{Protheus.doc}AF271ACTA

Check if the account is valid

@author Fabio Cazarini
@since  21/04/2017
@version 12
/*/
//-------------------------------------------------------------------
Function AF271ACTA()
Local lRet   := .T.
Local cAlias := Alias( )
	
If lRet
	If !Empty(&(ReadVar()))
		lRet := Ctb105Cta()
		dbSelectArea( cAlias )
	EndIf
EndIf
	
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc}AF271ATIPO

Asset type validation

@author Fabio Cazarini
@since  24/04/2017
@version 12
/*/ 
//-------------------------------------------------------------------
Function AF271ATIPO( cTipo, nLinha, lLinOk )
Local oModel  := FWModelActive()
Local oAuxBusca := oModel:GetModel('FNGDETAIL')
Local cPatrim := ""
Local oStruct := oAuxBusca:GetStruct()
Local aAux := oStruct:GetFields()
Local lRet:= .T.
Local nx, ny
// *******************************
// Controle de multiplas moedas  *
// *******************************
Local aTipos 		:= {}
// ***********************************************************
// Tipos de ativo que podem possuir multiplas cópias ativas  *
// ***********************************************************
Local aTiposMulti 	:= {"02","03","05","10","11","15"}
Local aTiposBase   	:= {"01","03","10","13"}
Local aTiposTrans		:= {"01","10"}
Local nTipoUnico		:= 0
Local nVTip			:= 1
//AVP
Local aTipoADT   		:= {}

Local cNValMod		:= ""
Local aNValMod		:= {}
Local nNValMod		:= 0
Local cTypes10		:= "" // CAZARINI - 13/03/2017 - If is Russia, add new valuations models - main models
Local cTypeAux		:= ""

Default lLinOk := .F.
Default nLinha := oAuxBusca:GetLine()
Default cTipo  := oAuxBusca:GetValue('FNG_TIPO', nLinha)

If Ascan(aAux, {|e| Alltrim(e[3]) = "FNG_PATRIM"}) > 0
	cPatrim := oAuxBusca:GetValue('FNG_PATRIM', nLinha)
Endif	

If lIsRussia // CAZARINI - Flag to indicate if is Russia location
	cNValMod := AtfNValMod({1}, ";")
	aNValMod := Separa(cNValMod, ';', .f.)
	For nNValMod := 1 to len(aNValMod)
		cTypeAux := aNValMod[nNValMod]
		cTypes10 += "|" + cTypeAux
		
		Aadd(aTiposMulti	, cTypeAux)
		Aadd(aTiposBase	, cTypeAux)
		Aadd(aTiposTrans	, cTypeAux)
	Next nNValMod
Endif

//Expressão removida da validação direta do campo para contemplar os novos tipos incluido no SX5->TABELA G1
//PERTENCE("01\02\03\04\05\06\07")
If Len(aTipos) == 0
	SX5->(DbSetOrder(1))
	SX5->(DbSeek(xFilial("SX5")+"G1"))
	While SX5->(!Eof()) .AND. SX5->X5_TABELA == "G1"
		AADD(aTipos,AllTrim(SX5->X5_CHAVE))
		SX5->(DbSkip())
	End
EndIf

If cPatrim == "T" .AND. !oAuxBusca:GetValue('FNG_TIPO',nLinha) $ ('01|10' + cTypes10) .AND. !oAuxBusca:IsDeleted(nLinha)
	Help( " ",1,"AF012PERM" ) // "Não é permitido usar o tipo nesta operação!"
	lRet := .F.
EndIf

If lRet .And. aScan(aTipos,{|cTipos| cTipos == cTipo}) == 0 .AND. !oAuxBusca:IsDeleted(nLinha)
	Help( " ",1,"AF012PERM" ) // "Não é permitido usar o tipo nesta operação!"
	lRet := .F.
EndIf

//AVP
If lRet .And. !lLinOk .and. cTipo == "14" .And. !oAuxBusca:IsDeleted() //Linha nova
	Help( " ", 1, "AF012NOT14")	//"Não é permitida a inclusão manual de Tipo 14. Utilize o processo de AVP padrão."
	lRet := .F.
EndIf

//MRG
If lRet .And. !lLinOk .and. cTipo == "15" .And. !oAuxBusca:IsDeleted() //Linha nova
	Help( " ", 1, "AF012NOT15",,)	//"Não é permitida a inclusão manual de Tipo 15. Utilize o processo de Margem Gerencial padrão."
	lRet := .F.
EndIf

// *********************************************************************
// Valida os tipos de ativo que podem possuir multiplas cópias ativas  *
// *********************************************************************
If lRet .And. !oAuxBusca:IsDeleted()
	nTipoUnico := 0
	For nX := 1 To oAuxBusca:Length()
		If !oAuxBusca:IsDeleted(nX)
			If oAuxBusca:GetValue('FNG_TIPO', nX) == cTipo .AND. (aScan(aTiposMulti,{|x| oAuxBusca:GetValue('FNG_TIPO', nX) == x}) == 0)
				nTipoUnico++
			Endif	
		Endif
	Next nX
	
	If nTipoUnico > 1
		Help( " ", 1, "A010JADIG") //"O tipo já foi informado!"
		lRet := .F.
	EndIf
Endif

// ***************************************************************************************************
// Valida os tipos de bens base, ou seja bens que podem ser cadastrados independentes de outros tipos*
// ***************************************************************************************************
If lRet .AND. aScan(aTiposBase,{|x| cTipo == x}) == 0 .and. !Empty(cTipo) 
	
	nTipoUnico := 0
	For nX := 1 To oAuxBusca:Length()		
		If !oAuxBusca:IsDeleted(nX)
			If aScan(aTiposBase,{|x| oAuxBusca:GetValue('FNG_TIPO', nX) == x}) != 0
				nTipoUnico++
			Endif
		Endif
	Next nx
	
	If Empty(nTipoUnico)
		Help( " ", 1, "AF012TIP",, STR0053, 1, 0 ) //"Tipo de ativo não é um tipo base"
		lRet := .F.
	EndIf

Endif

If lRet
	// Na reavaliacao ou depreciacao acelerada, copia os itens
	If cTipo $ "02,05,07,08,11" .And. oAuxBusca:Length() > 1 .And. !oAuxBusca:IsDeleted() //Linha nova
		
		For nY := 1 To Len(aAux)
			
			If cTipo $ "11" .And. Trim(aAux[ny][3]) = "FNG_TPDEPR"
				
				//Variavel nVTip armaneza a linha do N3_TIPO = 1
				For nVTip := 1 To oAuxBusca:Length()
					If oAuxBusca:GetValue('FNG_TIPO', nVTip) == '01' //nVTip -> Linha Posicionada no Detail
						oAuxBusca:SetValue('FNG_TPDEPR', oAuxBusca:GetValue('FNG_TPDEPR',nVTip))
						Exit
					EndIf
				Next nVTip

			EndIf
			
		Next nY
		
	Endif
EndIf

// Realiza a validação do tipo de ativo 03 ativo
If lRet .AND. lLinOk

	aAdd(aTipoADT,{"03","03/13/15" })
	aAdd(aTipoADT,{"13","03/13/15" })

	For nY := 1 to Len(aTipoADT)
		
		cTpAux := aTipoADT[nY][1] 
		l03 := .F. 
		
		For nX := 1 To oAuxBusca:Length()
			If !oAuxBusca:IsDeleted(nX) .AND. (oAuxBusca:GetValue('FNG_TIPO', nX) == cTpAux )
				l03 := .T. 
				Exit 
			EndIf
		Next nX
		
		If l03 
			For nX := 1 To oAuxBusca:Length()
				
				cTpAux := If( nX == oAuxBusca:GetLine(), cTipo, oAuxBusca:GetValue('FNG_TIPO', nX)) 
				If !oAuxBusca:IsDeleted(nX) .AND. !( cTpAux $ aTipoADT[nY][2] )
					Help( " ", 1, "AF012TPADT",, STR0051 + " " +aTipoADT[nY][2]+" " + STR0052+ " "  + aTipoADT[nY][1] , 1, 0 ) //'Apenas os tipos' -- " podem ser cadastrados em conjunto com o tipo de ativo "
					lRet := .F.
					Exit
				EndIf
				
			Next nX
		EndIf
		
		If !lRet
			Exit
		EndIf 		
	Next nY
	
EndIf

If lRet .and. cPatrim = 'E' .and. !(cTipo $ "03/13/10"+cTypes10) .And. !oAuxBusca:IsDeleted()
	Help( " ", 1, "AF012EMP") //""Só permitidos os tipos 03 ou 13 quando o Bem for classificado como Custo de Emprestimo"
	lRet := .F.
Endif

Return lRet
