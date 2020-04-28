#include "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#include "TBICONN.CH"
// #include "MsButton.ch"

User Function CHGTST()
Local oDlg,oButton2,oTsay

Private oButton1,oTsay1
Private nTimeSleep := 5000


DEFINE MSDIALOG oDlg FROM 0,0 TO 300,300 PIXEL TITLE 'CHG Teste'
oTsay:=tSay():New(10,10,{ ||"Teste FwMsgRun"},oDlg,,,,,,.T.,,,110,20)
oTsay1:=tSay():New(20,20,{ ||"..."},oDlg,,,,,,.T.,,,110,20)

// Botão para fechar a janela
oButton1:=tButton():New(60,10,'&Processa',oDlg,{||FwMsgRun(,{|| FwMsgRun(,{||Sleep(60000)},'Lock Estoque '+time(),'Processo sendo usado por outra pessoa.')},Nil,"Executando...")},50,20,,,,.T.)
oButton2:=tButton():New(90,10,'&Fechar',oDlg,{||oDlg:End()},50,20,,,,.T.) 

ACTIVATE MSDIALOG oDlg CENTERED

Return NIL

User Function RunLocka()
While .T.
	FwMsgRun(,{||Sleep(60000)},'Lock Estoque '+time(),'Processo sendo usado por outra pessoa.')
EndDo
Return Nil

