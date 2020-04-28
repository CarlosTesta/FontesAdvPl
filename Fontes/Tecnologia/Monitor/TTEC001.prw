#Include "MATA075.CH"
#include "PROTHEUS.CH"
#INCLUDE 'FWMVCDEF.CH'

//------------------------------------------------------------------------------
/*/{Protheus.doc} MATA075
Rotina de cadastro de grupo de depositos, construida usando MVC

@author alexandre.gimenez
@since 14/06/2013
@version P11
/*/
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³         ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL.             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador ³Data    ³ BOPS     ³ Motivo da Alteracao                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Jonathan Glz³08/07/15³PCREQ-4256³Se elimina la funcion AjustaHlp() que ³±±
±±³            ³        ³          ³hace modificacion a SX1 por motivo de ³±±
±±³            ³        ³          ³adecuacion a fuentes a nuevas estruc- ³±±
±±³            ³        ³          ³turas SX para Version 12.             ³±±
±±³M.Camargo   ³09.11.15³PCREQ-4262³Merge sistemico v12.1.8		           ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
//------------------------------------------------------------------------------
Function MATA075()
Local oBrowse

oBrowse := FWMBrowse():New()
oBrowse:SetAlias('SX5')
oBrowse:SetFilterDefault( "X5_TABELA=='74'" )
oBrowse:SetDescription('Grupo de Depositos')// Grupo de depositos
oBrowse:SetOnlyFields({'X5_CHAVE','X5_DESCRI'})

oBrowse:Activate()

Return NIL


//------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina MenuDef defini o menu da aplicação

@return aRotina Array de menu
@author alexandre.gimenez
@since 14/06/2013
@version P11.80
/*/
//------------------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE OemToAnsi(STR0001) ACTION 'VIEWDEF.mata075' OPERATION 2 ACCESS 0 // pesquisar
ADD OPTION aRotina TITLE OemToAnsi(STR0002) ACTION 'VIEWDEF.mata075' OPERATION 2 ACCESS 0 // visualizar
ADD OPTION aRotina TITLE OemToAnsi(STR0003) ACTION 'VIEWDEF.mata075' OPERATION 3 ACCESS 0 // Incluir
ADD OPTION aRotina TITLE OemToAnsi(STR0004) ACTION 'VIEWDEF.mata075' OPERATION 4 ACCESS 0 // Alterar
ADD OPTION aRotina TITLE OemToAnsi(STR0005) ACTION 'VIEWDEF.mata075' OPERATION 5 ACCESS 0 // Excluir

If ExistBlock ("MTA075MNU")
	ExecBlock  ("MTA075MNU",.F.,.F.) 
Endif

Return aRotina

//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina ModelDef defini o modelo de dados da aplicação

@return oModel Objeto modelo de dados da aplicação
@author alexandre.gimenez
@since 14/06/2013
@version P11.80
/*/
//------------------------------------------------------------------------------
Static Function ModelDef()
Local oStruTRB := NIL
Local oModel

//----------------------------------------------------
//		Cria a estrutura da Tabela TRB manualmente
//---------------------------------------------------
oStruTRB := FWFormModelStruct():New()
//-- Campo TRB_CHAVE 
oStruTRB:AddField("TRB_CHAVE" 														,;	// 	[01]  C   Titulo do campo  
				 STR0006																,;	// 	[02]  C   ToolTip do campo  //'Grupo'
				 "TRB_CHAVE"															,;	// 	[03]  C   Id do Field
				 "C"																	,;	// 	[04]  C   Tipo do campo
				 Len( SX5->X5_CHAVE ) 												,;	// 	[05]  N   Tamanho do campo
				 0  																	,;	// 	[06]  N   Decimal do campo
				 FWBuildFeature( STRUCT_FEATURE_VALID , "A075Valid(a,b,c,d)" )	,;	// 	[07]  B   Code-block de validação do campo
				 NIL																	,;	// 	[08]  B   Code-block de validação When do campo
				 NIL																	,;	//	[09]  A   Lista de valores permitido do campo
				 .T.																	,;	//	[10]  L   Indica se o campo tem preenchimento obrigatório
				 NIL																	,; //	[11]  B   Code-block de inicializacao do campo				
				 .T.																	,;	//	[12]  L   Indica se trata-se de um campo chave
				 .F.																	,;	//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
				 .F.																	)	// 	[14]  L   Indica se o campo é virtual
//-- Campo TRB_DESCRI 
oStruTRB:AddField("TRB_DESCRI" 													    ,;	// 	[01]  C   Titulo do campo  
				 STR0007																,;	// 	[02]  C   ToolTip do campo //'Deposito'
				 "TRB_DESCRI"															,;	// 	[03]  C   Id do Field
				 "C"																	,;	// 	[04]  C   Tipo do campo
				 Len( SX5->X5_DESCRI ) 												,;	// 	[05]  N   Tamanho do campo
				 0  																	,;	// 	[06]  N   Decimal do campo
				 NIL																	,;	// 	[07]  B   Code-block de validação do campo
				 NIL																	,;	// 	[08]  B   Code-block de validação When do campo
				 NIL																	,;	//	[09]  A   Lista de valores permitido do campo
				 .T.																	,;	//	[10]  L   Indica se o campo tem preenchimento obrigatório
				 NIL																	,; // [11]  B   Code-block de inicializacao do campo
				 .F.																	,;	//	[12]  L   Indica se trata-se de um campo chave
				 NIL																	,;	//	[13]  L   Indica se o campo pode receber valor em uma operação de update.
				 .F.																	)	// 	[14]  L   Indica se o campo é virtual


oModel := MPFormModel():New('mata075', /*bPreValidacao*/ , /*bPosValidacao*/,{|oModel| A075Commit(oModel)}, /*bCancel*/ )
oModel:AddFields( 'TRB_MASTER', /*cOwner*/, oStruTRB, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ {| | A075Load()} )
oModel:SetDescription( 'Grupo de Depositos' ) 
oModel:GetModel( 'TRB_MASTER' ):SetDescription( 'Grupo de Depositos' )
oModel:SetPrimarykey({})

Return oModel

//------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina ViewDef defini o modelo da Interface da aplicação

@return oView Objeto de Interface da aplicação
@author alexandre.gimenez
@since 14/06/2013
@version P11.80
/*/
//------------------------------------------------------------------------------
Static Function ViewDef()
Local oModel   := FWLoadModel( 'mata075' )
Local oStruTRB
Local oView

//----------------------------------------------------
//		Cria a estrutura da Tabela TRB manualmente
//---------------------------------------------------
oStruTRB  :=FWFormViewStruct():New()
//-- Campo TRB_CHAVE 
oStruTRB:AddField("TRB_CHAVE"													,;	// [01]  C   Nome do Campo
				"01"																,;	// [02]  C   Ordem
				STR0006															,;	// [03]  C   Titulo do campo
				STR0006															,;	// [04]  C   Descricao do campo
				NIL																	,;	// [05]  A   Array com Help
				"C"																	,;	// [06]  C   Tipo do campo
				""																	,;	// [07]  C   Picture
				NIL																	,;	// [08]  B   Bloco de Picture Var
				NIL																	,;	// [09]  C   Consulta F3
				.T.																	,;	// [10]  L   Indica se o campo é alteravel
				NIL																	,;	// [11]  C   Pasta do campo
				NIL																	,;	// [12]  C   Agrupamento do campo
				NIL																	,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL																	,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL																	,;	// [15]  C   Inicializador de Browse
				.F.																	,;	// [16]  L   Indica se o campo é virtual
				NIL																	,;	// [17]  C   Picture Variavel
				.T.																	)	// [18]  L   Indica pulo de linha após o campo	
//-- Campo TRB_DESCRI
oStruTRB:AddField("TRB_DESCRI"													,;	// [01]  C   Nome do Campo
				"02"																,;	// [02]  C   Ordem
				STR0007															,;	// [03]  C   Titulo do campo
				STR0007															,;	// [04]  C   Descricao do campo
				NIL																	,;	// [05]  A   Array com Help
				"C"																	,;	// [06]  C   Tipo do campo
				""																	,;	// [07]  C   Picture
				NIL																	,;	// [08]  B   Bloco de Picture Var
				NIL																	,;	// [09]  C   Consulta F3
				.T.																	,;	// [10]  L   Indica se o campo é alteravel
				NIL																	,;	// [11]  C   Pasta do campo
				NIL																	,;	// [12]  C   Agrupamento do campo
				NIL																	,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL																	,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL																	,;	// [15]  C   Inicializador de Browse
				.F.																	,;	// [16]  L   Indica se o campo é virtual
				NIL																	,;	// [17]  C   Picture Variavel
				NIL																	)	// [18]  L   Indica pulo de linha após o campo	


oView := FWFormView():New()
oView:SetModel( oModel )
oView:AddField( 'VIEW_TRB', oStruTRB, 'TRB_MASTER' )
oView:CreateHorizontalBox( 'TELA' , 100 )
oView:SetOwnerView( 'VIEW_TRB', 'TELA' )

Return oView

//------------------------------------------------------------------------------
/*/{Protheus.doc} A075load
Função que carrega dados da tabela SX5 para a Tabela TRB na inicialização do modelo

@return aCampos Array com dados para carga na tabela TRB
@author alexandre.gimenez
@since 14/06/2013
@version P11.80
/*/
//------------------------------------------------------------------------------
Static Function A075Load()
Local aCampos := {SX5->X5_CHAVE,SX5->X5_DESCRI}

Return aCampos 

//------------------------------------------------------------------------------
/*/{Protheus.doc} A075Valid
Função para validar chave primaria no campo TBB_chave

@param oModel Modelo de dados.
@param cField Campo de referência.
@param cConteud Conteudo do campo.
@param cOldConteud Conteudo anterior do campo. 
@return lRet Lógico com confirmação ou não da validação da chave primaria
@author alexandre.gimenez
@since 14/06/2013
@version P11.80
/*/
//------------------------------------------------------------------------------
Function A075Valid(oModel,cField,cConteud,cOldConteud)
Local lRet := .F.

If !Empty(cConteud) .And. ExistChav("SX5","74"+cConteud)
	lRet := .T.
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A075Commit
Função de gravação dos dados da tabela TRB na Tabela SX5

@param oModel Modelo de dados.
@return lRet Lógico com confirmação ou não da gravação.
@author alexandre.gimenez
@since 14/06/2013
@version P11.80
/*/
//------------------------------------------------------------------------------
Static Function A075Commit(oModel)
Local lRet    := .T.
Local lInsert := (oModel:GetOperation() == MODEL_OPERATION_INSERT)
Local cDescri
Local cChave

If lInsert .Or. oModel:GetOperation() == MODEL_OPERATION_UPDATE
	cDescri := FwFldGet("TRB_DESCRI")
	cChave  := FwFldGet("TRB_CHAVE")
	RecLock("SX5",lInsert)
	SX5->X5_FILIAL  := xFilial("SX5")
	SX5->X5_TABELA  := "74"
	SX5->X5_CHAVE   := cChave
	SX5->X5_DESCRI  := cDescri
	SX5->X5_DESCSPA := cDescri
	SX5->X5_DESCENG := cDescri
	MsUnlock()
ElseIf oModel:GetOperation() == MODEL_OPERATION_DELETE
	RecLock("SX5",.F.)
	SX5->(DbDelete())
	MsUnlock()
EndIf

Return (lRet)
