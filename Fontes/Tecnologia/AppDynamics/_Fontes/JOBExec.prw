#INCLUDE 'PROTHEUS.CH'
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"

/*/
Rotina com o intuito de stressar hardware com rotina pesadas do protheus, 
coletando informações de consumo do sistema operacional e tomada de tempo das rotinas.
Rotina desenvolvida para ser um "Orchestra Monitor" que dispara e sincroniza a execução
das rotinas entre um ou vários Slave´s Protheus e, estes por sua vez, devolvem um JSON
de resultados para ser compilado no Monitor da Rotina
Autor: Carlos Testa
Uso: Amplo com algumas funções de uso específico a partir do "Build 7.00.131227A - Nov  7 2017 - 22:39:07 NG "


Testes Contemplados
    * Consumo de IO utilizando SPF
    * Acesso ao banco de dados e velocidade de processamento
    * Rotinas Automáticas Protheus (MATA010 e MATA103) para teste de processo
    * Consumo de Web Service nos Slaves
    * 

Parâmetros de Uso: Os parametros setados no monitor serão replicados para os Slaves para 
que todos trabalhem dentro do mesmo cenário.
/*/
User Function JOBExec()
// Controles da Janela de Parametros
Local oDlg,oButton02,oCmb01,oGet01,oGet02,oSay01,oSay02,oSay03
Local oSay04,oSay05,oSay06,oSay07,oSay08,oSay09,oSay10,_oBtnPath,_cFileTrans
Local aItems    := {'Produto','Contas a Pagar','Contas a Receber'}
Local aRotinas  := {'MATA010','FINA040','FINA050'}
Local _cRotina  := aItems[1]
Local oFont:= TFont():New('ARRUS BT',,-11,.T.)
// Parametros do INI
Local _cPathOri := GetSrvProfString("StartPath", "\undefined")
Local _cEXEC010 := GetPvProfString("APPTEST","EXEC010","undefined","appserver.ini")     // pega os parametros de start da rotina contidos no INI
Local _nThreads := Val(SubStr(_cEXEC010,1,At("/",_cEXEC010)-1))
Local _nInserts	:= IIf(!Empty(_cExec010),Val(SubStr(_cExec010,At("/",_cExec010)+1)),10)	    // caso sem valor, assume 10
Local _cSrvIP	:= GetServerIP()	// IP do servidor atual
Local _cEnvWork	:= GetEnvServer()	// Environment atual de trabalho
Local _cRCBin   := GetSrvVersion()  // Versão do Binário em uso
Local _aMsgRun  := {"Aguardando...","<<< Executando >>>","TERMINADO!!! Selecione pasta para DESTINO da cópia."}
Private _cGetpath	:= Space(30)	// Path + o arquivo escolhido atrave do cGetFile()

DEFINE MSDIALOG oDlg FROM 0,0 TO 300,300 PIXEL TITLE 'Testes AppDynamics'
oSay01 := tSay():New(10,05,{||'Número de Threads'},oDlg,,,,,,.T.,CLR_BLUE,CLR_WHITE,80,10)
oGet01 := TGet():New(10,70,{|u| if(PCount()>0,_nThreads:=u,_nThreads)}, oDlg,80,10,'@E 999,999',,,,,,,.T.,,,,,,,,,,'_nThreads')
oSay02 := tSay():New(25,05,{||'Número de Inserts'},oDlg,,,,,,.T.,CLR_BLUE,CLR_WHITE,80,10)
oGet02 := TGet():New(25,70,{|u| if(PCount()>0,_nInserts:=u,_nInserts)}, oDlg,80,10,'@E 999,999',,,,,,,.T.,,,,,,,,,,'_nInserts')
oSay03 := tSay():New(40,05,{||'Rotina Para Teste'},oDlg,,,,,,.T.,CLR_BLUE,CLR_WHITE,80,10)
oCmb01 := tComboBox():New(40,70,{|u|if(PCount()>0,_cRotina:=u,_cRotina)},aItems,80,10,oDlg,,,,,,.T.,,,,,,,,,'_cRotina')
// Msg´s do ambiente em uso
oSay03 := tSay():New(70,05,{||'IP Servidor:'},oDlg,,,,,,.T.,CLR_BLUE,CLR_WHITE,80,10)
oSay04 := tSay():New(70,70,{||_cSrvIP},oDlg,,,,,,.T.,CLR_BLACK,CLR_BLUE,80,10)
oSay05 := tSay():New(80,05,{||'Environment:'},oDlg,,,,,,.T.,CLR_BLUE,CLR_WHITE,80,10)
oSay06 := tSay():New(80,70,{||_cEnvWork},oDlg,,,,,,.T.,CLR_BLACK,CLR_BLUE,80,10)
oSay07 := tSay():New(90,05,{||'Protheus Version:'},oDlg,,,,,,.T.,CLR_BLUE,CLR_WHITE,80,10)
oSay08 := tSay():New(90,70,{||_cRCBin},oDlg,,,,,,.T.,CLR_BLACK,CLR_BLUE,80,10)
// Browse de Seleção de arquivo para transferência
oSay09 := tSay():New(100,05,{||'Status:'},oDlg,,,,,,.T.,CLR_BLUE,CLR_BLUE,80,10)
oSay10 := tSay():New(100,25,{||_aMsgRun[1]},oDlg,,oFont,,,,.T.,CLR_BLACK,CLR_BLUE,100,20)
_oBtnPath	:= SButton():New(100,125,14,{||_cGetpath:=ALLTRIM(cGetFile("Arquivos CSV (*.CSV) |*.csv",'Transferência de Arquivo', 1,"",.T.,GETF_RETDIRECTORY + GETF_LOCALHARD,.F.)),oDlg:Refresh(),.F.,CpyS2T(_cPathOri+_cFileTrans,_cGetpath,.T.),oSay10:SetText(_aMsgRun[1]),oSay10:nClrText:=CLR_BLACK,_oBtnPath:Hide()},oDlg,.T.,,)
_oBtnPath:Hide()
// Botão para fechar a janela
oButton1 := tButton():New(120,10,'&Teste',oDlg,{||oSay10:SetText(_aMsgRun[2]),oSay10:nClrText:=CLR_RED,_cFileTrans:=U_RunJobs(_nThreads,_nInserts,aRotinas[aScan(aItems,{|x| x == Alltrim(_cRotina)})]),oSay10:SetText(_aMsgRun[3]),oSay10:nClrText:=CLR_GREEN,_oBtnPath:Show()},50,10,,,,.T.)
oButton2 := tButton():New(120,80,'&Fechar',oDlg,{||oDlg:End()},50,10,,,,.T.)
oButton1:nClrText:=CLR_BLACK
oButton2:nClrText:=CLR_BLACK
ACTIVATE MSDIALOG oDlg CENTERED

Return Nil

User Function RunJobs(_nThreads,_nInserts,_cRotina)
Local _nCnt,_cKeyCTL,_nHndCSV,_nJob,_nLin,_nCol,_cLinIns,_cHeader,_cFileRes,_cService
Local _cRCBin   := GetSrvVersion()  // Versão do Binário em uso
Local _aJobs    := {}               // Nome das Keys que foram processadas
Local _aRetCTL  := {}               // Array para pegar os retornos das globais e avaliar se já terminaram
Local _aRetEnd  := {}               // Array com o conteúdo final de todos os processos
Local _cUIDCtl  := "AppDTst"        // UID para CONTROLE dos testes
Local _cRCBTMon := GetPvProfString("BTMonitor","Enable","undefined","appserver.ini")    // verIfIfca se tem ou não os parametros do BTMonitor no INI
Local _cSrvIP	:= GetServerIP()								// IP do servidor atual
Local _cEnvWork	:= GetEnvServer()								// Environment atual de trabalho
Local _cSrvPort	:= GetPvProfString("TCP","Port","undefined","appserver.ini")	// Porta do AppServer

lRetRun := VarClean(_cUIDCtl)
lRetRun := VarSetUID(_cUIDCtl)

// ajusta a qtd de registros a serem inseridos em cada thread
_nInserts := _nInserts / _nThreads

// nome do serviço a ser patrulhado baseado no binário utilizado nos testes
If IsSrvUnix()
    If "btmonitor" $ _cRCBin
        If _cRCBTMon == 'undefined'
            _cService := "appsrvlinux_off"
        Else
            _cService := "appsrvlinux_on"
        EndIf
    Else
        _cService := "appsrvlinux_no_bt"
    EndIf
Else
    If "btmonitor" $ _cRCBin
        If _cRCBTMon == 'undefined'
            _cService := "appserver_off.exe"
        Else
            _cService := "appserver_on.exe"
        EndIf
    Else
        _cService := "appserver_no_bt.exe"
    EndIf
EndIf

ConOut()
Conout("== _cRotina ==============")
Conout(_cRotina)
Conout("== _cRotina ==============")

//JOB´s de inserção de Produtos para simular usabilidade de usuários Protheus
For _nCnt := 1 To _nThreads
    _cKeyCTL := "THR"+AllTrim(StrZero(_nCnt,4))
    AADD(_aJobs,{_cKeyCTL,.F.})   // armazena os JOB´s criados para verIficar se todos os JOB´s já encerraram seus processos.
    lRetRun := VarSetA(_cUIDCtl,_cKeyCTL,{''})     // flag para dIferenciar a thread em processo e aquela que já terminou
    Startjob('U_RunIns',getenvserver(),.F.,_cUIDCtl,_cKeyCTL,_nInserts,_cService,_cRotina)
    Inkey(1)    // pausa de 1 segundo entre as subidas de JOB´s 
Next

// verIficação se todas as chaves já possuem valor, uma vez que os JOB´s efetuaram a gravação
// somente no final ainda por desenvolver
lEndRun := .F.
Do While !(lEndRun)
    For _nCnt:= 1 to Len(_aJobs)
        If !(_aJobs[_nCnt][2])  // enquanto falso, JOB ainda em processamento
            _aRetCTL := {}
            lRetRun := VarGetA(_cUIDCtl,_aJobs[_nCnt][1],@_aRetCTL)
            // ConOut("== _aRetCTL[1] ===========")
            // ConOut(_aRetCTL[1])
            // ConOut("== _aRetCTL[1] ===========")
            If !Empty(_aRetCTL[1])
                AADD(_aRetEnd,_aRetCTL) // acrescenta o contéudo do JOB no array de dados final
                _aJobs[_nCnt][2] := .T.
            EndIf
        EndIf
    Next

    // enquanto houver .F. no array, ainda existem threads rodando.
    If aScan(_aJobs,{|x| x[2] == .F.}) == 0 
        lEndRun := .T.
    EndIf

    Inkey(2)    // segundo(s) de pausa para próxima verIficação
EndDo

// geração de um CSV para abrir no excel
_cFileRes := "AP_"

// AQUI TRATAR SE A ROTINA IRÁ RODAR EM WINDOWS OU LINUX ... 
// SE FOR WINDOWS VER A POSSIBILIDADE DE USAR O MESMO PROGRAMA NO WINDOWS QUE NO LINUX
If IsSrvUnix()
    If "btmonitor" $ _cRCBin
        If _cRCBTMon == 'undefined'
            _cFileRes += "Lnx_BT_OFF_"
        Else
            _cFileRes += "Lnx_BT_ON_"
        EndIf
    Else
        _cFileRes += "Lnx_NO_BT_"
    EndIf
Else
    If "btmonitor" $ _cRCBin
        If _cRCBTMon == 'undefined'
            _cFileRes += "Win_BT_OFF_"
        Else
            _cFileRes += "Win_BT_ON_"
        EndIf
    Else
        _cFileRes += "Win_NO_BT_"
    EndIf
EndIf
_cFileRes += DTOS(Date()) + "_"
_cFileRes += StrTran(StrTran(TimeFull(),":",""),".","") + ".csv"

// Geração do Nome de Arquivos baseado na Regra
If File(_cFileRes)
    FErase(_cFileRes)
EndIf
_nHndCSV := FCREATE(_cFileRes)
If _nHndCSV = -1
    conout("Erro ao criar arquivo - ferror " + Str(Ferror()))
else
    _cHeader := '"ROTINA";"VERSION";"THREAD";"INSERTS";"OPER";"TIME";"ELAPTIME";"CPU";"MEMOHDW";"MEMOAPP"'

    // ConOut(Repl("=",60))
    // VarInfo("_aRetEnd",_aRetEnd)
    // ConOut(Repl("=",60))

    FWrite(_nHndCSV, _cHeader + CRLF)
    For _nJob := 1 to Len(_aRetEnd)

        // ConOut(Repl("=",60))
        // VarInfo("_aRetEnd",_aRetEnd[_nJob])
        // ConOut(Repl("=",60))

        For _nLin := 1 to Len(_aRetEnd[_nJob])
            _cLinIns := ""
            For _nCol := 1 to Len(_aRetEnd[_nJob][_nLin])
                _cLinIns += _aRetEnd[_nJob][_nLin][_nCol]
                If _nCol < Len(_aRetEnd[_nJob][_nLin])
                    _cLinIns += ";"
                EndIf
            Next
            FWrite(_nHndCSV, _cLinIns + CRLF)
        Next
    Next
    FClose(_nHndCSV)
EndIf

// ConOut(Repl("-",80))
// ConOut("LOG de Processo. Server:" + _cSrvIP + " | Porta:" + _cSrvPort + " | Environment: " + _cEnvWork)
// VarInfo("Jobs",_aJobs)
// VarInfo("Result",_aRetEnd)
// ConOut(Repl("-",80))

lRetRun := VarClean(_cUIDCtl)   // limpeza da global ao final de tudo
ConOut("Variável Global eliminada!!!")

Return _cFileRes
