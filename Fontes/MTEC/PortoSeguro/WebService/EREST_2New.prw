#Include 'protheus.ch'
#Include 'parmtype.ch'
#Include 'RestFul.ch'
//#Include 'aarray.ch'
#Include 'json.ch'

/*/{Protheus.doc} EREST_02
__Dummy function
@author Leandro Heilig
@since  14/10/2017
@version 1
@type function
/*/
User Function EREST_2New()	
Return

/*/{Protheus.doc} CLIENTES
WebService Rest para realizar a manipulação de clientes
@author Leandro Heilig
@since  14/10/2017
@type class
/*/
WSRESTFUL CLITESTE DESCRIPTION "Teste REST Porto Seguro"

WSMETHOD GET DESCRIPTION "Retorna lista de clientes" 	WSSYNTAX ""
 
END WSRESTFUL

/*/{Protheus.doc} GET
        Retorna uma lista de clientes.
@author Leandro Heilig
@since  14/10/2017
@type   function
/*/
WSMETHOD GET WSSERVICE CLITESTE
//WSMETHOD POST WSRECEIVE RECEIVE WSSERVICE PROSPECTS
Local oCliente	 := CLIENTES():New() // --> Objeto da classe cliente
Local oResponse  := FULL_CLIENTES():New() // --> Objeto que será serializado
Local cJSON		 := ""
Local lRet		 := .T.

::SetContentType("application/json")

For nCnt := 1 To 10 		
	oCliente:SetCodigo( "0016/" + AllTrim(Str(nCnt)) )
	oCliente:SetLoja( 	AllTrim(Str(nCnt)) )
	oCliente:SetNome( 	"Fulano da Silva" )
	oCliente:SetCGC( 	"21942625049" )
	oCliente:SetCEP( 	"02510-000" )
	oCliente:SetEnd( 	"Rua Logo Ali, 1234A" )
	oCliente:SetDDD( 	"24111293")
	oCliente:SetTel(	"999887-6655" )
	
	oResponse:Add(oCliente)
		
Next	

	// somente para debug
	/*
	ConOut("----------------------")
	VarInfo("oResponse",oResponse)
	ConOut("----------------------")
	*/
	
cJSON := FWJsonSerialize(oResponse, .T., .T.,,.F.)
::SetResponse(cJSON)
		

Return(lRet)
