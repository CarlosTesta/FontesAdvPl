#include "protheus.ch"
User Function PrtChat()
Local oDlg, oMemo, cMemo:= space(50)
Local aList := {} // Vetor com elementos do Browse
DEFINE MSDIALOG oDlg FROM 0,0 TO 400,400 PIXEL TITLE "Chat Protheus"
oMemo:= tMultiget():New(10,10,{|u|if(Pcount()>0,cMemo:=u,cMemo)},oDlg,100,100,,,,,,.T.)
@ 150,10 BUTTON oBtn PROMPT "Fecha" OF oDlg PIXEL ACTION oDlg:End()
ACTIVATE MSDIALOG oDlg CENTERED
MsgStop(cMemo)
Return NIL


user function TcBrowse_EX()
Local oOK := LoadBitmap(GetResources(),'br_verde')
Local oNO := LoadBitmap(GetResources(),'br_vermelho')
Local aList := {} // Vetor com elementos do Browse
Local nX

// Cria Vetor para teste
// for nX := 1 to 100
//     aListAux := {.T., strzero(nX,10), 'Descrição do Produto '+strzero(nX,3), 1000.22+nX}
//     aadd(aList, aListAux)
// next

MyArray(@aList)

DEFINE MSDIALOG oDlg FROM 0,0 TO 520,600 PIXEL TITLE 'Exemplo da TCBrowse'
// Cria objeto de fonte que sera usado na Browse
Define Font oFont Name 'Courier New' Size 0, -12
// Cria Browse
oList := TCBrowse():New( 01 , 01, 300, 200,,{'','Codigo','Descrição','Valor'},{20,50,50,50},oDlg,,,,,{||},,oFont,,,,,.F.,,.T.,,.F.,,, )
// Seta o vetor a ser utilizado
oList:SetArray(aList)
oList:Refresh() // refresh da lista
// Monta a linha a ser exibina no Browse
oList:bLine := {||{ If(aList[oList:nAt,01],oOK,oNO),aList[oList:nAt,02],aList[oList:nAt,03],Transform(aList[oList:nAT,04],'@E 99,999,999,999.99') } }
// Evento de DuploClick (troca o valor do primeiro elemento do Vetor)
oList:bLDblClick := {|| aList[oList:nAt][1] := !aList[oList:nAt][1],oList:DrawSelect() }
// Principais commandos
oBtn := TButton():New( 210, 001,'Refresh' , oDlg,{||MyArray(@aList),oList:Refresh()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
// oBtn := TButton():New( 210, 001,'GoUp()' , oDlg,{||oList:GoUp()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
oBtn := TButton():New( 220, 001,'GoDown()', oDlg,{||oList:GoDown()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
oBtn := TButton():New( 230, 001,'GoTop()' , oDlg,{||oList:GoTop()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
oBtn := TButton():New( 240, 001,'GoBottom()', oDlg,{||oList:GoBottom()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
oBtn := TButton():New( 210, 060, 'nAt (Linha selecionada)' ,oDlg,{|| Alert(oList:nAt)},90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
oBtn := TButton():New( 220, 060, 'nRowCount (Nr de linhas visiveis)',oDlg,{|| Alert(oList:nRowCount()) }, 90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
oBtn := TButton():New( 230, 060, 'nLen (Numero total de linhas)', oDlg,{|| Alert(oList:nLen) }, 90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
oBtn := TButton():New( 240, 060, 'lEditCell (Edita a celula)', oDlg,{|| lEditCell(@aList,oList,'@!',3) }, 90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )

ACTIVATE MSDIALOG oDlg CENTERED
return

Static Function MyArray(aList)
local aListAux := {}
// Cria Vetor para teste
if Len(aList) < 10
    for nX := 1 to 10
        aListAux := {.T., strzero(nX,10), 'Descrição do Produto '+strzero(nX,3), 1000.22+nX}
        aadd(aList, aListAux)
    next
else
    nValNew := Len(aList)+1
    AADD(aList,{.T., strzero(nValNew,10), 'Descrição do Produto '+strzero(nValNew,3), 1000.22+nValNew})
endif

Return(aList)