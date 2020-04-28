#Include 'protheus.ch'
#Include 'parmtype.ch'

/*/{Protheus.doc} EREST_02A
__Dummy function
@author Leandro Heilig
@since 14/10/2017
@version undefined
@type function
/*/
User Function EREST_2A()
Return

Class CLIENTES
	
	DATA codigo		As String
	DATA loja		As String
	DATA nome		As String
	DATA cgc		As String
	DATA cep		As String
	DATA endereco	As String
	DATA ddd		As String
	DATA telefone	As String
	
	Method New() Constructor
	Method SetCodigo(cCodigo)
	Method SetLoja(cLoja)
	Method SetNome(cNome)
	Method SetCGC(cCGC)
	Method SetCEP(cCep)
	Method SetEnd(cEndereco)
	Method SetDDD(cDDD)
	Method SetTel(cTel)
	
EndClass

/*/{Protheus.doc} New
Método Construtor
@author Leandro Heilig
@since 14/10/2017
@version undefined
@type function
/*/
Method New() Class CLIENTES

::codigo 	:= ""
::loja 		:= ""
::nome     	:= ""
::cgc 	   	:= ""
::cep 	   	:= ""
::endereco 	:= ""
::ddd 		:= ""
::telefone 	:= ""

Return(Self)

// --> Métodos Setters
Method SetCodigo(cCodigo) Class CLIENTES
Return(::codigo := cCodigo)

Method SetLoja(cLoja) Class CLIENTES
Return(::loja := cLoja)
	
Method SetNome(cNome) Class CLIENTES
Return(::nome := cNome)
	
Method SetCGC(cCGC) Class CLIENTES
Return(::cgc := cCGC)

Method SetCEP(cCep) Class CLIENTES
Return(::cep := cCep)

Method SetEnd(cEndereco) Class CLIENTES
Return(::endereco := cEndereco)

Method SetDDD(cDDD) Class CLIENTES
Return(::ddd := cDDD)

Method SetTel(cTel) Class CLIENTES
Return(::telefone := cTel)