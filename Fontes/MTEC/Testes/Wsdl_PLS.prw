#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'TOPCONN.CH'
//#INCLUDE "APWIZARD.CH"
User Function WSDLPLS()
Local oWsdl
Local cRet       := ""
Local nOperation := 0
Local cUrl       := "http://10.172.18.192:8051/wsConsultaSQL/MEX?wsdl"
Local cXml       := ""

RPCSETTYPE(3)
PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FAT"


cXml := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tot="http://www.totvs.com/">'
cXml += '  <soapenv:Header/>'
cXml += '   <soapenv:Body>'
cXml += '      <tot:RealizarConsultaSQL>'
cXml += '         <tot:codSentenca>INTRMPLS</tot:codSentenca>'
cXml += '         <tot:codColigada>1</tot:codColigada>'
cXml += '         <tot:codSistema>O</tot:codSistema>'
cXml += '         <tot:parameters>CODCOLIGADA=1;CODUSUARIO=mestre;CODPACIENTE=10</tot:parameters>'
cXml += '      </tot:RealizarConsultaSQL>'
cXml += '   </soapenv:Body>'
cXml += '</soapenv:Envelope>'

If !Empty(cUrl)
      oWsdl := TwsdlManager():New()
      
      If oWsdl:ParseURL(cURL)
        aOps := oWsdl:ListOperations()
            oWsdl:SetAuthentication('mestre','totvs')
            oWsdl:GetAuthentication('mestre','totvs')

        If len(aOps) > 0 .And. ( nOperation := Ascan(aOps,{|x|x[1] == 'RealizarConsultaSQL'}) ) > 0
                //Seta a Operacao
                If oWsdl:SetOperation(aOps[nOperation][1])
                    
                    oWsdl:SendSoapMsg(EncodeUTF8(cXml))
                    cRet := (oWsdl:GetSoapResponse() )    
                    
                    If !Empty(oWsdl:cError)
                            ConOut("Não foi possível atualizar dados da marcação realizada, contate o Administrador do sistema: <<"+ Alltrim(oWsdl:cError)+">>")
                    EndIf
                EndIf
        EndIf
      Else
            ConOut("Não foi possível conectar com o WebService da RM, contate o Administrador do sistema <<"+ Alltrim(oWsdl:cError)+">>")
      EndIf
EndIf

Return cRet
