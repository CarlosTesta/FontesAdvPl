#Include "protheus.ch"
#Include "parmtype.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} FWMsgRun
Exibe um painel com animação e texto durante o processamento de um bloco de código
permite atualizar o texto em tempo de execução

@sample
// Executa destacado e centralizado
FWMsgRun(, {|oSay| ExecTest(oSay) }, "Processando", "Processando a rotina...")
// Executa sobrepondo um container
FWMsgRun(oPanel1, {|oSay| ExecTest(oSay) }, "Processando", "Processando a rotina...")
                 
@param oComponent Componente que será sobreposto com o painel (opcional)
@param bAction Bloco de código a ser executado (o Bloco de código recebera o objeto TSay para atualizações)
@param cHeader Texto do Header
@param cText Texto do Corpo
@author Ricardo Mansano
@since 28/11/2010
@version 1.0
/*/
//-------------------------------------------------------------------
Function FWMsgRun(oComponent, bAction, cHeader, cText)
Local oDlgSVG           As Object
Local oSVG              As Object
Local oSay              As Object
Local aBounds           As Array
Local AdjustWithoutText As Logical
Local IsContainered     As Logical
// Caracteristicas dos paineis
Local nBoundSVG         As Numeric
Local nWndWidth         As Numeric
Local nWndHeight        As Numeric
Local oFont             As Object

PARAMTYPE 0 VAR oComponent AS OBJECT OPTIONAL
PARAMTYPE 1 VAR bAction    AS BLOCK 
PARAMTYPE 2 VAR cHeader    AS CHARACTER OPTIONAL DEFAULT ""
PARAMTYPE 3 VAR cText      AS CHARACTER OPTIONAL DEFAULT ""

If !IsBlind() // Somente para execução com tela
	nBoundSVG         := 19  
	nWndWidth         := 400
	nWndHeight        := 98
	AdjustWithoutText := Empty(cText)
	IsContainered     := (oComponent <> Nil) // Verifica se foi passado container
	oFont             := TFont():New("Verdana",,012,,.T.,,,,,.F.,.F.)

	// Trata se aparecera em um container ou destacado
	If IsContainered
		// Painel
		aBounds := {((oComponent:oParent:nClientHeight/2)-(nBoundSVG))-23, (oComponent:oParent:nClientWidth/2)-(nBoundSVG)}
		@ 0,0 MSPANEL oDlgSVG SIZE 0,0 OF oComponent:oParent
		oDlgSVG:Align := CONTROL_ALIGN_ALLCLIENT

		// Animação SVG
		oSVG := TSVG():New(aBounds[1]/2+Iif(AdjustWithoutText,5,0), aBounds[2]/2,oDlgSVG,nBoundSVG,nBoundSVG,FWSvgWait())
		oSVG:SetCSS( FWCSSVerify( GetClassName(oSVG), "QWidget", "QWidget{border: none; background: transparent;}" ) )

		// Texto
		@ (aBounds[1]/2)+23, 000 SAY oSay PROMPT cText SIZE oComponent:oParent:nClientWidth/2, 007 OF oDlgSVG FONT oFont HTML CENTERED PIXEL
		oSay:SetCSS( FWCSSVerify( GetClassName(oSay), "QLabel", "QLabel{Border:none; background: transparent;}" ) )
	Else
		// Cria dialog estilizada
		oDlgSVG := FWStyledDialog():New(0,0,nWndHeight,nWndWidth,cHeader,{||})

		// Compensa altura da dialog
		oDlgSVG:nHeight := oDlgSVG:nHeight - (oDlgSVG:nClientHeight-nWndHeight)
		oDlgSVG:Refresh()

		// Animação SVG
		oSVG := TSVG():New(18+Iif(AdjustWithoutText,5,0),0,oDlgSVG,nBoundSVG,nBoundSVG,FWSvgWait())
		oSVG:SetCSS( FWCSSVerify( GetClassName(oSVG), "QWidget", "QWidget{border: none; background: transparent;}" ) )
		oSVG:nLeft := (nWndWidth/2) - (nBoundSVG/2)

		// Texto
		@ 040, 002 SAY oSay PROMPT cText SIZE nWndWidth/2, 007 OF oDlgSVG FONT oFont HTML CENTERED PIXEL
		oSay:SetCSS( FWCSSVerify( GetClassName(oSay), "QLabel", "QLabel{Border:none; background: transparent;}" ) )
	EndIf

	// Processa e libera
	ProcessMessages()
	If IsContainered
		Eval(bAction, oSay)
 
		FreeObj(oSay)
		oSay := Nil
		FreeObj(oSVG)
		oSVG := Nil
		oDlgSVG:lVisible := .F.
		FreeObj(oDlgSVG)
		oDlgSVG := Nil
        
        // Este ProcessMessages, que receberá .T., fará um Flush das mensagens
        // entre Server e Client, permitindo liberar corretamente os objetos acima
        lOnlyFlush:= .T.   
		ProcessMessages(lOnlyFlush)
	Else
		oDlgSVG:Activate(,,,.T.,,, {|| Eval(bAction, oSay), oDlgSVG:End() })
	Endif
Else
	Eval(bAction, oSay)
EndIf

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} FWSvgWait
Retorna o CSS da Animação

@author Ricardo Mansano
@since 28/11/2010
@version 1.0
/*/
//-------------------------------------------------------------------
Function FWSvgWait( cBGColor )
	Local cSVG As Char

	Default cBGColor := "#FFFFFF"

	cSVG := "<?xml version='1.0' standalone='no'?> <!DOCTYPE svg PUBLIC '-//W3C//DTD SVG 1.1//EN' "
	cSVG += "'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'>"
	cSVG += "<svg width='36' height='36' version='1.1' xmlns='http://www.w3.org/2000/svg'>"
	cSVG += "<g transform='translate(18,18)' >"
	cSVG += "  <g transform='rotate(45)' >"
	cSVG += "    <circle fill='none' stroke='#424142' cx='0' cy='0' r='16' stroke-width='3' />"
	cSVG += "    <line x1='-13' y1='-13' x2='13' y2='13' stroke='"+ cBGColor +"' stroke-width='4'  />"
	cSVG += "    <animateTransform attributeName='transform' type='rotate' values='0; 360'"
	cSVG += "      dur='2s' repeatCount='indefinite' rotate='auto'/>"
	cSVG += "  </g>"
	cSVG += "</g>"
	cSVG += "<circle fill='"+ cBGColor +"' cx='18' cy='18' r='11' stroke-width='3'/>"
	cSVG += "<g transform='translate(18,18)' >"
	cSVG += "  <g transform='rotate(45)' >"
	cSVG += "	<circle fill='none' stroke='#9C9A9C' cx='0' cy='0' r='11' stroke-width='3'/>"
	cSVG += "	<circle fill='"+ cBGColor +"' cx='2' cy='0' r='11.5' stroke-width='3'/>"
	cSVG += "	<line x1='0' y1='13' x2='2' y2='-12' stroke='"+ cBGColor +"' stroke-width='5'  />"
	cSVG += "	<line x1='2' y1='14' x2='4' y2='-14' stroke='"+ cBGColor +"' stroke-width='2'  />"
	cSVG += "	<line x1='4' y1='13' x2='6' y2='-13' stroke='"+ cBGColor +"' stroke-width='2'  />"
	cSVG += "	<animateTransform attributeName='transform' type='rotate' values='360; 0'"
	cSVG += " 	 dur='1.3s' repeatCount='indefinite' rotate='auto'/>"
	cSVG += "  </g>"
	cSVG += "</g>"
	cSVG += "</svg>"

Return cSVG
