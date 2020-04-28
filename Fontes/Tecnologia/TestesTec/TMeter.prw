#include 'TOTVS.ch'
STATIC lRunning:=.F., lStop:=.F.

User Function MyTMeter()
Local nMeter:=0, oBtn1, oBtn2
Public oDlg,oMeter

DEFINE MSDIALOG oDlg FROM 0,0 TO 400,400 TITLE 'Teste' Pixel
// oMeter:= tMeter():New(10,10,{|u|if(Pcount()>0,nMeter:=u,nMeter)},100,oDlg,100,16,,.T.,,,.F.,255,,16711680,,) // cria a régua
oMeter:= TMeter():Create(oDlg,{|u|if(Pcount()>0,nMeter:=u,nMeter)},25,02,100,100,16,,.T.,,,,,,255,)
cSetCss := "QProgressBar::chunk {background-color: #32cd32;}"
oMeter:SetCSS(cSetCss)
//New([anRow], [anCol], [abSetGet], [anTotal], [aoWnd], [anWidth],[anHeight], [lPar8], [alPixel], [oPar10], [cPar11], [alNoPerc],[anClrPane], [nPar14], [anClrBar], [nPar16], [lPar17]) // oMeter:NCLRBAR := 383 
// botão para ativar andamento da régua
@ 50,10 BUTTON oBtn1 PROMPT 'Run ' OF oDlg PIXEL ACTION RunMeter()
@ 70,10 BUTTON oBtn2 PROMPT 'Stop' OF oDlg PIXEL ACTION lStop:=.T.
ACTIVATE MSDIALOG oDlg CENTERED
Return NIL

STATIC Function RunMeter()
If lRunning
    Return
Endif
lRunning:= .T.
oMeter:Set(0)
// inicia a régua
While .T. .and. !lStop
    Sleep(1000) // pára 1 segundo
    ProcessMessages() // atualiza a pintura da janela, processa mensagens do windows
    nCurrent:= Eval(oMeter:bSetGet) // pega valor corrente da régua
    nCurrent+=10 // atualiza régua
    oMeter:Set(nCurrent)
    If nCurrent==oMeter:nTotal
        Return
    EndIf

    // mudança da cor da régua
    If (nCurrent > 60 .AND. nCurrent < 90)
        cSetCss := "QProgressBar::chunk {background-color: #ffa500;}"
        oMeter:SetCSS(cSetCss)
    ElseIf nCurrent >= 90
        cSetCss := "QProgressBar::chunk {background-color: #ff2800;}"
        oMeter:SetCSS(cSetCss)
    EndIf
    oMeter:Refresh()
    SysRefresh()
Enddo
lRunning:= .F.
lStop:= .F.
Return