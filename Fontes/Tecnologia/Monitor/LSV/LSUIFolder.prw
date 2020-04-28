#INCLUDE "PROTHEUS.CH"

#DEFINE FOLDERSPACE 30

STATIC __oFontSize := FWFontSize():New()
STATIC __oFontDef := FWGetFont( "p" ) 

//-------------------------------------------------------------------
/*/{Protheus.doc} LSUIFolder
Classe responsável por listar conexões em uso do license
	
@author Bruno Lopes Malafaia
@since 09/06/2014
@version version 1.0
/*/
//-------------------------------------------------------------------
CLASS LSUIFolder FROM LongClassName

	DATA aFolderItems

	DATA cIDActive
	
	DATA cCSSBtn
	DATA cCSSBtnSelect

	DATA oOwner
	DATA oMsgBar
	DATA oItemLastRefresh

	DATA nLastRefresh
	
	METHOD New()
	METHOD Activate()
	METHOD Deactivate()

	METHOD Click()

	METHOD Hide()

	METHOD GetPanel()
	
	METHOD Refresh()

	METHOD Show()

ENDCLASS

//-------------------------------------------------------------------
/*/{Protheus.doc} New
Método construtor da classe

@param oOwner Objeto proprietário

@return oSelf Objeto LSUIFolder

@author Bruno Lopes Malafaia
@since 09/06/2014
@version 1.0
/*/
//-------------------------------------------------------------------
METHOD New( oOwner ) CLASS LSUIFolder

	::aFolderItems := {}

	::cCSSBtn := "TButton { font: normal; background-color: transparent; border: none; border-bottom: none; "+;
					"  background-image: url(''); "+;
					"  background-repeat: no-repeat; "+;
					"  background-position: bottom; }"

	::cCSSBtnSelect := "TButton { font: bold; background-color: transparent; border: none; border-bottom: 2px solid #397A9A; "+;
					"  background-image: url(rpo:ls_tab_selected.png); "+;
					"  background-repeat: no-repeat; "+;
					"  background-position: bottom; }"

	::oOwner := oOwner
	::nLastRefresh := Seconds()
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} New
Método construtor da classe

@param oOwner Objeto proprietário

@return oSelf Objeto LSUIFolder

@author Bruno Lopes Malafaia
@since 09/06/2014
@version 1.0
/*/
//-------------------------------------------------------------------
METHOD Activate() CLASS LSUIFolder
	Local aCfgTimer := { { 180, 300, 600 }, { "3 min", "5 min", "10 min"} } 
	Local aFolders := {{"MONITOR", "Armazenados", 0, Nil }, ;
                       {"HISTORY", "Testar Ambiente", 0, Nil}, ; 
                       {"LICMANAGER", "Aba 03", 0, Nil}}

	Local cCfgTimer

	Local nFolderSpace := 30
	Local nLeft := 0
	Local nSpace := 5
	Local nTotBtnWidth := 0
	Local nWBtn := 12
	Local nWidth := 0
	Local nX
	Local nWUser
	
	Local oBtnUpd
	Local oCfgTimer
	Local oFolderItem
	Local oPBar
	Local oSeparator
	Local oTimer
	Local oWidget
	Local oItemUser
	Local oItemLastRefresh
	Local lHTML := IsHTML()
	//--------------------------------------------------------------
	// Cria barra de status emulada
	//--------------------------------------------------------------
	::oMsgBar := FWMsgBar():New( ::oOwner, CONTROL_ALIGN_TOP )
	::oMsgBar:SetTitle( "Monitor Ambiente Protheus" ) 
	::oMsgBar:Activate()
	
	oItemUser := ::oMsgBar:AddItem( "USER", "USUARIO" , {|| } )
	::oItemLastRefresh := ::oMsgBar:AddItem( "USER", I18N("#1 Refresh: #2",{'Ultimo Refresh',Time()}) , {|| } ) 

	nWUser := ::oItemLastRefresh:oMsgBarItem:nWidth/2 + oItemUser:oMsgBarItem:nWidth/2
	//--------------------------------------------------------------
	// Cria botões que emulam folder
	//--------------------------------------------------------------
	oPBar := ::oMsgBar:oBar
	oPBar:ReadClientCoors(.T.,.T.)
		//--------------------------------------------------------------
		// Cálculo de posicionamento de interface
		//--------------------------------------------------------------
		For nX := 1 To Len(aFolders)
			nWidth := __oFontSize:getTextWidth( aFolders[nX][2], __oFontDef:Name, ABS(__oFontDef:nHeight)-3, __oFontDef:Bold, __oFontDef:Italic, __oFontDef:Underline )+FOLDERSPACE
			nTotBtnWidth += nWidth
			
			aFolders[nX][3] := nWidth
		Next nX
		//--------------------------------------------------------------
		// Posição inicial deve considerar a diferença entre a largura
		// total, menos a largura dos botões menos a largura das 
		// separações dos botões (1 pixel) 
		//--------------------------------------------------------------
		nLeft := (oPBar:nWidth-nTotBtnWidth-Len(aFolders)-1)/2/2
		
		//--------------------------------------------------------------
		// Monitoramento
		//--------------------------------------------------------------
		For nX := 1 To Len(aFolders)
			oFolderItem := LSUIFolderItem():New(oPBar, ::oOwner)
			oFolderItem:SetID(aFolders[nX][1])
			oFolderItem:SetBtnAction( {|cID| ::Click(cID) } )
			oFolderItem:SetLeft(nLeft)
			oFolderItem:SetTitle(aFolders[nX][2])
			oFolderItem:SetWidth(aFolders[nX][3])
			oFolderItem:Activate() 
			oFolderItem:SetBtnCSS(::cCSSBtn)
			
			Do Case
				Case aFolders[nX][1] == "MONITOR"
					//oWidget := LSUIMonitor():New(oFolderItem:GetPanel())
				Case aFolders[nX][1] == "HISTORY"
					//oWidget := LSUIHistory():New(oFolderItem:GetPanel())
				Case aFolders[nX][1] == "LICMANAGER"
					//oWidget := LSUILicManager():New(oFolderItem:GetPanel())
			End Case
			
			//oWidget:Activate()
			
			oFolderItem:SetWidget(oWidget)
			
			aAdd( ::aFolderItems, oFolderItem )

			nLeft += aFolders[nX][3]/2
			
			If nX < Len(aFolders)
				oSeparator := tPanelCss():New(000,nLeft,,oPBar,,,,,,0.5,017,.F.,.F.)
				oSeparator:SetCSS( "TPanelCss { background-color: transparent; margin-top: 5px; margin-bottom: 5px; border: none; border-left: 1px dotted #757776; }" )

				nLeft += 0.5
			EndIf
		Next nX
		//--------------------------------------------------------------
		// Cria Itens de Atualização
		//--------------------------------------------------------------
		cCfgTimer := "1"
		@ (oPBar:nHeight/2-010)/2,oPBar:nWidth/2-(045+nWUser)-nWBtn-10 COMBOBOX oCfgTimer VAR cCfgTimer ITEMS aCfgTimer[2] SIZE 045,010 OF oPBar ON CHANGE {|| MsgAlert("Timer") } PIXEL
		oCfgTimer:bChange :=  {|| oTimer:Deactivate(), oTimer:nInterval := aCfgTimer[1][oCfgTimer:nAt]*1000, oTimer:Activate() }
	
		nWidth := __oFontSize:getTextWidth( "Atualização Automatica", __oFontDef:Name, ABS(__oFontDef:nHeight)-3, __oFontDef:Bold, __oFontDef:Italic, __oFontDef:Underline ) + If(lHTML,20,0) 
	
		@ If(lHTML,5,0),(oCfgTimer:nLeft-nWidth-nSpace)/2 SAY oSay PROMPT "Atualização Automatica" FONT __oFontDef SIZE nWidth/2,017 OF oPBar PIXEL 
		oSay:SetCSS( FWGetCSS( GetClassName(oSay), CSS_SAY )+"TSay { qproperty-alignment: 'AlignVCenter | AlignLeft' }" )
	
		@ (oPBar:nHeight/2-012)/2,(oCfgTimer:nLeft+oCfgTimer:nWidth)/2+nSpace BUTTON oBtnUpd PROMPT "" SIZE 012,012 ACTION {|| self:Refresh(::cIDActive) } OF oPBar PIXEL
		oBtnUpd:SetCSS( FWGetCSS( oBtnUpd, CSS_BUTTON )+"TButton { background: url(rpo:ls_ico_update.png);"+;
							"      background-repeat: no-repeat; background-position: center; }" )
		
		oTimer := TTimer():New( 180000, {|| ::Refresh() }, oMainWnd )
		oTimer:Activate()

	::Click("MONITOR")
	
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} Deactivate
Método para desativar a classe

@author Bruno Lopes Malafaia
@since 09/06/2014
@version 1.0
/*/
//-------------------------------------------------------------------
METHOD Deactivate() CLASS LSUIFolder
Local nX	:= 0

	For nX := 1 To Len( Self:aFolderItems )
		Self:aFolderItems[nX]:DeActivate()
	Next nX

	FreeObj( Self:oItemLastRefresh )

RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} Click
Método de controle das abas emuladas

@author Bruno Lopes Malafaia
@since 09/06/2014
@version 1.0
/*/
//-------------------------------------------------------------------
METHOD Click( cButton ) CLASS LSUIFolder

	If !(cButton == ::cIDActive)
		If !Empty(::cIDActive)
			::Hide(::cIDActive)
		EndIf
	
		::Show(cButton)
	EndIf
	
	::cIDActive := cButton

RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} Hide
Método responsável por esconder a folder passada por parâmetro

@param cID Id da folder que precisa ser escondida

@author bruno.lopes
@since 05/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD Hide( cID ) CLASS LSUIFolder

	Local nAscan := 0
	
	If (nAscan := aScan(::aFolderItems, {|x| x:cID == cID } )) > 0
		::aFolderItems[nAscan]:Hide()
		::aFolderItems[nAscan]:SetBtnCSS(::cCSSBtn)
	EndIf

RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} GetPanel
Método responsável por retornar o painel do ID passado por parâmetro

@return oPanel painel do item passado por parâmetro

@author bruno.lopes
@since 03/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD GetPanel( cID ) CLASS LSUIFolder
	Local oPanel
	
	Local nAscan
	
	If (nAscan := aScan(::aFolderItems, {|x| x:cID == cID }) ) > 0
		oPanel := ::aFolderItems[nAscan]:GetPanel()
	EndIf

RETURN oPanel

//-------------------------------------------------------------------
/*/{Protheus.doc} Refresh
Método para atualizar o widget

@author Bruno Lopes Malafaia
@since 09/06/2014
@version 1.0
/*/
//-------------------------------------------------------------------
METHOD Refresh( cID ) CLASS LSUIFolder
	Local nDiff
	Local nAscan := 0

	Default cID := ""
	
	nDiff := IIf(Seconds() - ::nLastRefresh<0,86400+Seconds(),Seconds()) - ::nLastRefresh

	If nDiff > 5
		::nLastRefresh := Seconds()
		::oItemLastRefresh:SetText(I18N("#1 Refresh: #2",{"Ultimo Refresh",Time()})) 

		If Empty(cID)
			For nAscan:=1 to Len(::aFolderItems)
				::aFolderItems[nAscan]:Refresh()
			Next nX
		Else
			If (nAscan := aScan(::aFolderItems, {|x| x:cID == cID } )) > 0
				::aFolderItems[nAscan]:Refresh()
			EndIf
		EndIf
	EndIf
RETURN

//-------------------------------------------------------------------
/*/{Protheus.doc} Show
Método responsável por apresentar a folder passada por parâmetro

@param cID Id da folder que precisa ser apresentada

@author bruno.lopes
@since 05/05/2016
@version version
/*/
//-------------------------------------------------------------------
METHOD Show( cID ) CLASS LSUIFolder

	Local nAscan := 0
	
	If (nAscan := aScan(::aFolderItems, {|x| x:cID == cID } )) > 0
		::aFolderItems[nAscan]:Show()
		::aFolderItems[nAscan]:SetBtnCSS(::cCSSBtnSelect)
	EndIf

RETURN