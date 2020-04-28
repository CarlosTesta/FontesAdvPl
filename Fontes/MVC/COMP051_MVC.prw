#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

//-------------------------------------------------------------------
/*/{Protheus.doc} COMP051_MVC
Exemplo de montagem da modelo e interface para uma estrutura
pai/filho em MVC.
Emula um mini pedido de venda

@author Rodrigo Antonio Godinho
@since 18/03/2011
@version P10
/*/
//-------------------------------------------------------------------
User Function COMP051_MVC()
Local oBrowse

oBrowse := FWmBrowse():New()
oBrowse:SetAlias( 'ZAB' )
oBrowse:SetDescription( 'Mini Pedido de Venda' )
oBrowse:Activate()

Return NIL


//-------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}
								

ADD OPTION aRotina Title 'Pesquisar'   Action 'PesqBrw'             OPERATION 1 ACCESS 0
ADD OPTION aRotina Title 'Visualizar'  Action 'VIEWDEF.COMP051_MVC' OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Incluir'     Action 'VIEWDEF.COMP051_MVC' OPERATION 3 ACCESS 0
ADD OPTION aRotina Title 'Alterar'     Action 'VIEWDEF.COMP051_MVC' OPERATION 4 ACCESS 0
ADD OPTION aRotina Title 'Excluir'     Action 'VIEWDEF.COMP051_MVC' OPERATION 5 ACCESS 0
ADD OPTION aRotina Title 'Imprimir'    Action 'VIEWDEF.COMP051_MVC' OPERATION 8 ACCESS 0
ADD OPTION aRotina Title 'Copiar'      Action 'VIEWDEF.COMP051_MVC' OPERATION 9 ACCESS 0

Return aRotina


//-------------------------------------------------------------------
Static Function ModelDef()
// Cria a estrutura a ser usada no Modelo de Dados
Local oStruZAB := FWFormStruct( 1, 'ZAB', /*bAvalCampo*/, /*lViewUsado*/ )
Local oStruZAC := FWFormStruct( 1, 'ZAC', /*bAvalCampo*/, /*lViewUsado*/ )
Local oModel
Local oEngine

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New( 'COMP051M', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )
//oModel := MPFormModel():New( 'COMP021M', /*bPreValidacao*/, { | oMdl | COMP021POS( oMdl ) } , /*bCommit*/, /*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
oModel:AddFields( 'ZABMASTER', /*cOwner*/, oStruZAB )

// Adiciona ao modelo uma estrutura de formulário de edição por grid
oModel:AddGrid( 'ZACDETAIL', 'ZABMASTER', oStruZAC, /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

// Faz relaciomaneto entre os compomentes do model
oModel:SetRelation( 'ZACDETAIL', { { 'ZAC_FILIAL', 'xFilial( "ZAC" )' }, { 'ZAC_NUM', 'ZAB_NUM' } }, ZAC->( IndexKey( 1 ) ) )

// Liga o controle de nao repeticao de linha
oModel:GetModel( 'ZACDETAIL' ):SetUniqueLine( { 'ZAC_ITEM' } )

// Adiciona a descricao do Modelo de Dados
oModel:SetDescription( 'Modelo de Musicas' )

// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel( 'ZABMASTER' ):SetDescription( 'Cabeçalho de Pedido' )
oModel:GetModel( 'ZACDETAIL' ):SetDescription( 'Itens do Pedido'  )

oEngine := MyMathEngine(oModel)
//-----------------------------------
/*oEngine:addLink("ZACDETAIL","ZAC_QTDVEN","QUANTIDADE")
oEngine:addLink("ZACDETAIL","ZAC_PRCVEN","PRECOUNITARIO")
oEngine:addLink("ZACDETAIL","ZAC_VALOR","CALCTOTAL")
//-----------------------------------
oEngine:addLink("ZACDETAIL","ZAC_DESCON","PERCDESCONTO")
oEngine:addLink("ZACDETAIL","ZAC_VALDES","CALCDESC")
*/
oEngine:addLink("ZACDETAIL","ZAC_TIPOOP","TIPO_OP")
oEngine:addLink("ZACDETAIL","ZAC_CONSUM","TIPO_CLI")
oEngine:addLink("ZACDETAIL","ZAC_ESTORI","EST_ORI")
oEngine:addLink("ZACDETAIL","ZAC_ESTDES","EST_DES")
oEngine:addLink("ZACDETAIL","ZAC_ICMSAL","ALIC_ICMS")
oEngine:addLink("ZACDETAIL","ZAC_BAICMS","BASE_ICMS")
oEngine:addLink("ZACDETAIL","ZAC_ICMSVA","ICMS_VALOR")
          
           
           //oEngine:addLink("ZACDETAIL","ZAC_TIPOOP","TIPOEDU")
     
             
   


oEngine:Activate()
oModel:SetMathEngine(oEngine)

Return oModel


//-------------------------------------------------------------------
Static Function ViewDef()
// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oStruZAB := FWFormStruct( 2, 'ZAB' )
Local oStruZAC := FWFormStruct( 2, 'ZAC' )
// Cria a estrutura a ser usada na View
Local oModel   := ModelDef()
Local oView
// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel( oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField( 'VIEW_ZAB', oStruZAB, 'ZABMASTER' )

//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
oView:AddGrid(  'VIEW_ZAC', oStruZAC, 'ZACDETAIL' )

// Criar um "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox( 'SUPERIOR', 30 )
oView:CreateHorizontalBox( 'INFERIOR', 70 )

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView( 'VIEW_ZAB', 'SUPERIOR' )
oView:SetOwnerView( 'VIEW_ZAC', 'INFERIOR' )

// Define campos que terao Auto Incremento
oView:AddIncrementField( 'VIEW_ZAC', 'ZAC_ITEM' )

// Criar novo botao na barra de botoes
oView:AddUserButton( 'Inclui Autor', 'CLIPS', { |oView| COMP021BUT() } )

// Liga a identificacao do componente
//oView:EnableTitleView('VIEW_ZAC')
oView:EnableTitleView('VIEW_ZAC','Itens')

Return oView


Static Function MyMathEngine(oModel)
//Local oMnemonico := FWMnemonicoFactory():New()
Local oEngine
//Local oWorkSheet := FwWorkSheet():New()


oEngine := FWMathEngine():New("000004")
oEngine:oModel := oModel
//oEngine:addMenmonico(oMnemonico)
//oEngine:addWorkSheet(oWorkSheet)
	

Return oEngine



/*
BASEICMS
ALIQUOTA
VALORICMS
TIPO_OPERACAO = "eNTRA OU saida"
TIPO_CONSUMIDOR ="iNSCRITO OU NAO"
ESTADO_ORIGEM
ESTADO_DESTINO


DETALICoTa
   SE CONSUMDOR_FINAL
	SE OPERACAO_SAIDA
		RETURN ALICINTERNA (MV_ICMPAD)	
	SENAO
		return AT(do estado origem) MV_ESTICM
	
	Endif
   ELse

   sE  origem = DESTINO
	RETURN ALICINTERNA (MV_ICMPAD)
   SENAO
	SE ORIGEM == SUL AND DESTINO == NORTE
		RETURN 7%
	ELSE
		RETURN 12%
	ENDIF
	
    Endif

Iif(TIPO_CLI == 1,
	Iif(TIPO_OP==2,
		GETMV("MV_ICMPAD"),
		
		SUBSTR(GETMV("MV_ESTICM"),AT(EST_ORI,GetMv("MV_ESTICM") )+2,2)  )
	,Iif(EST_ORI== EST_DES,GETMV("MV_ICMPAD"),Iif (!(EST_ORI $ ISNORTE) .And. EST_DES $ ISNORTE ,7,12)))
*/
//SUBSTR(GETMV("MV_ESTICM"),AT(EST_ORI,GetMv("MV_ESTICM") ),2)


