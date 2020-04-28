#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWEBSRV.CH"


       //u_B198Ntfy( 'N/A', cOportu, 'Regra nao foi encontrada.' )
       //u_B198Ntfy( cIncide, cOportu, 'Erro no Retorno do WebService.' )
       //u_B198Ntfy( cIncide, cOportu, 'Erro no WebService' + cErroWs + '.' )
       //u_B198Ntfy( cIncide, cOportu, 'Contrato sofreu alteracao.' )


//--------------------------------------------------------------
/*/{Protheus.doc} B198Ntfy

Funcao que Notifica o usuario do Status [ Resolvido com Erro ]
do Incidente. 

Projeto : 150.178 - Entrega 2 - Comunicacao Protheus e CRMOD        
@Param  : Incidente , Oportunidade
@return : 

@author  - Carlos E. Chigres
@since 29/03/2016
/*/
//--------------------------------------------------------------
User Function B198Ntfy( cInciden, cOportu, cMsgErr )

//--- Variaveis inseridas para envio de email em caso de erro no processamento do cliente - FSW 26/03/2013
Local cMailConta  := AllTrim( GetMV( "MV_RELACNT" ) )   //Conta utilizada p/envio do email
Local cMailServer := AllTrim( GetMV( "MV_RELSERV" ) )   //Server
Local cMailSenha  := AllTrim( GetMV( "MV_RELPSW" ) )    //Password
Local nMailTMO	  := AllTrim( GetMV( "MV_RELTIME" ) )   //Time-out
Local lAut		  := AllTrim( GetMV( "MV_RELAUTH" ) )   //Autenticacao
Local cEmail	  := AllTrim( GetMV( "ES_RESPCLI" ) )   //Email

Local cCorpo	  := AllTrim( "\cartas\Erroincidente.html" )
Local cDetalher  := ' '
Local nErro      := 0
Local oMsg, oServer

 If cInciden == 'N/A'

cDetalhe := 'Erro na Reativacao de Cliente, ' + cMsgErr

Else

    cDetalhe := 'Incidente Nro. ' + cInciden 

 EndIf  

 oMsg 	 := TMailMessage():New()
 oServer := TMailManager():New()
 oServer:Init( "", cMailServer, "", "", 0, 25 )

 If( ( nErro := oServer:SmtpConnect() ) != 0 )			
     Return( u_vsErro( "N? foi poss?el conectar ao servidor de e-mail: " + cMailServer + CRLF + oServer:GetErrorString( nErro ) ) )
 EndIf

 oMsg:Clear()
 oMsg:cFrom	 := cMailConta
 oMsg:cTo	 := Alltrim( cEmail )
 oMsg:cSubject := "Incidente do RightNow Resolvido com Erro"
 oMsg:cBody	   := StrTran( StrTran( StrTran( MemoRead( cCorpo ), "!INCIDENTE!", cDetalhe ), "!DATA!", DToC(Date())), "!OPORTUNIDADE!", cOportu )
 oMsg:MsgBodyType( "text/html" )

 nErro := oMsg:Send( oServer )

 If( nErro != 0 )

	u_vsErro( "N? enviou o e-mail." + CRLF + oServer:GetErrorString( nErro ) )						
	
oServer:Init( "", cMailServer, "", "", 0, 25 )
If( (nErro := oServer:SmtpConnect()) != 0 )
	u_vsErro( "N? foi poss?el conectar ao servidor de e-mail: " + cMailServer + CRLF + oServer:GetErrorString( nErro ) )
Else
	nErro := oMsg:Send( oServer )
	If( nErro != 0 )
		u_vsErro( "N? enviou o e-mail." + CRLF + oServer:GetErrorString( nErro ) )						
		EndIf
	EndIf
EndIf
	
Return Nil
