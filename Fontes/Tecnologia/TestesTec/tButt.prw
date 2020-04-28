#include 'protheus.ch'
User Function MyTestGet()
Local oDlg, oButton, oCombo, cCombo
aItems:= {'item1','item2','item3'}
cCombo:= aItems[2]
DEFINE MSDIALOG oDlg FROM 0,0 TO 300,300 PIXEL TITLE 'Meu Combo'
oCombo:= tComboBox():New(10,10,{|u|if(PCount()>0,cCombo:=u,cCombo)},;
aItems,100,20,oDlg,,{||MsgStop('Mudou item')},,,,.T.,,,,,,,,,'cCombo')
// Botão para fechar a janela
oButton:=tButton():New(30,10,'fechar',oDlg,{||oDlg:End()},100,20,,,,.T.)
ACTIVATE MSDIALOG oDlg CENTERED
MsgStop( 'O valor é '+cCombo )
Return NIL