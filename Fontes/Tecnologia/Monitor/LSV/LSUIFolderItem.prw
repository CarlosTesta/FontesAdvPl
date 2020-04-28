#include 'totvs.ch'

#DEFINE PANELCSS "TPanelCss { border: none; }"

//-------------------------------------------------------------------
/*/{Protheus.doc} Function_name
long_description
	
@author bruno.lopes
@since 03/05/2016
@version version
/*/
//-------------------------------------------------------------------
CLASS LSUIFolderItem

	DATA bAction

	DATA cID
	DATA cTitle

	DATA nLeft
	DATA nWidth
	
	DATA oBtnFolder
	DATA oOwnerContent
	DATA oOwnerFolder
	DATA oPanel
	DATA oWidget

	METHOD New() CONSTRUCTOR

	METHOD Activate()
	METHOD DeActivate()

	METHOD GetPanel()

	METHOD Hide()

	METHOD Refresh()

	METHOD SetBtnAction()
	METHOD SetBtnCSS()
	METHOD SetID()
	METHOD SetLeft()
	METHOD SetOwnerContent()
	METHOD SetOwnerFolder()
	METHOD SetTitle()
	METHOD SetWidth()
	METHOD SetWidget()

	METHOD Show()

ENDCLASS

//-------------------------------------------------------------------
/*/{Protheus.doc} Function_name
long_description
	
@author bruno.lopes
@since 03/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD New( oOwnerFolder, oOwnerContent ) CLASS LSUIFolderItem
	::oOwnerFolder := oOwnerFolder
	::oOwnerContent := oOwnerContent
	
	::nLeft := 0
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} Activate
long_description
	
@author bruno.lopes
@since 03/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD Activate() CLASS LSUIFolderItem
	//--------------------------------------------------------------
	// Bot�o do item da folder
	//--------------------------------------------------------------
	@ 000,::nLeft BUTTON ::oBtnFolder PROMPT ::cTitle ACTION Eval( ::bAction, ::cID ) SIZE ::nWidth/2,017 OF ::oOwnerFolder PIXEL
	::oBtnFolder:lCanGotFocus := .F.
	
	//--------------------------------------------------------------
	// Cria Painel de fundo para a cria��o dos componentes
	//--------------------------------------------------------------
	::oPanel := tPanelCss():New(000,000,,::oOwnerContent,,,,,,000,000,.F.,.F.)
	::oPanel:Align := CONTROL_ALIGN_ALLCLIENT
	::oPanel:SetCSS( PANELCSS )
	::oPanel:ReadClientCoors(.T., .T.)
	::oPanel:Hide()
RETURN

METHOD DeActivate() CLASS LSUIFolderItem

	Self:oWidget:DeActivate()

Return 

//-------------------------------------------------------------------
/*/{Protheus.doc} GetPanel
M�todo retorna o painel correspondente ao item
	
@author bruno.lopes
@since 03/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD GetPanel() CLASS LSUIFolderItem
RETURN ::oPanel

//-------------------------------------------------------------------
/*/{Protheus.doc} Hide
M�todo respons�vel por esconder o painel de conteudo da folder

@author bruno.lopes
@since 05/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD Hide() CLASS LSUIFolderItem
	::oPanel:Hide()
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} Refresh
M�todo respons�vel por atualizar o widget vinculado a folder
	
@author bruno.lopes
@since 06/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD Refresh() CLASS LSUIFolderItem
	//::oWidget:Refresh()	// depois tem que reabilitar este parametro para fazer o refresh e trazer os dados novos
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} SetBtnAction
M�todo respons�vel por atribuir a a��o que ser� disparada 
no clique da folder
	
@author bruno.lopes
@since 03/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD SetBtnAction( bAction ) CLASS LSUIFolderItem
	::bAction := bAction
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} SetBtnCSS
M�todo respons�vel por atribuir o CSS do item
	
@author bruno.lopes
@since 03/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD SetBtnCSS( cCSS ) CLASS LSUIFolderItem
	::oBtnFolder:SetCSS(cCSS)
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} SetID
M�todo respons�vel por atribuir c�digo de identifica��o do Item
	
@author bruno.lopes
@since 03/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD SetID( cID ) CLASS LSUIFolderItem
	::cID := cID
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} SetLeft
M�todo respons�vel por atribuir a coordenada da esquerda do item
	
@author bruno.lopes
@since 03/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD SetLeft( nLeft ) CLASS LSUIFolderItem
	::nLeft := nLeft
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} SetOwnerContent
M�todo respons�vel por atribuir onde o conte�do ser� criado
	
@author bruno.lopes
@since 03/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD SetOwnerContent( oOwner ) CLASS LSUIFolderItem
	::oOwnerContent := oOwner
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} SetOwnerFolder
M�todo respons�vel por atribuir onde a aba ser� criada
	
@author bruno.lopes
@since 03/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD SetOwnerFolder( oOwner ) CLASS LSUIFolderItem
	::oOwnerFolder := oOwner
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} SetTitle
M�todo respons�vel por atribuir t�tulo do item
	
@author bruno.lopes
@since 03/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD SetTitle( cTitle ) CLASS LSUIFolderItem
	::cTitle := cTitle
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} SetWidget
M�todo respons�vel por atribuir o widget da folder
	
@author bruno.lopes
@since 06/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD SetWidget( oWidget ) CLASS LSUIFolderItem
	::oWidget := oWidget
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} SetWidth
M�todo respons�vel por atribuir a largura do t�tulo

@author bruno.lopes
@since 03/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD SetWidth( nWidth ) CLASS LSUIFolderItem
	::nWidth := nWidth
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} Show
M�todo respons�vel por apresentar o painel de conteudo da folder

@author bruno.lopes
@since 05/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD Show() CLASS LSUIFolderItem
	::oPanel:Show()
RETURN
