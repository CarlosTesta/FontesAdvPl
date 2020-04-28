#INCLUDE 'PROTHEUS.CH'
#include "fileio.ch"

#define CRLF Chr(13) + Chr(10)
//+----------------------------------------------------------------------------+
//|Exemplo de uso da função Encode64 e Decode64                                |
//+----------------------------------------------------------------------------+
User Function MyEncode()
Local cEncode64 := ""
Local cEncodeAntes := ""

// modelo funcional
fHdl := fOpen("d:\\temp\\feliz.jpg",FO_READ,,.F.)
FRead(fHdl, cEncodeAntes,1000000)   // chutei este numero pq o Terceiro parâmetro é obrigatório
cEncode64 := Encode64(cEncodeAntes)

varinfo("cEncode64 >> ",cEncode64)

// Baseado no exemplo do TDN http://tdn.totvs.com.br/display/tec/Encode64
cEncode64 := Encode64(,"c:\\temp\\feliz.jpg",.T.,.F.)

Return