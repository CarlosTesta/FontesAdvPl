/*
Uso:
  u_ChatLogin
*/

#include "protheus.ch"
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// Static cRedisServer     := "127.0.0.1"
// Static nRedisPort       := 6379
// Static cRedisAuth       := ""
// Static cFlLsServer      := "127.0.0.1"
// Static nFlLsPort        := 6379
// Static cFlLsAuth        := ""

// Static oRedis := Nil
// Static oLista := Nil
// Static oFila  := Nil

#define LISTA_USUARIOS  "CHAT_LISTA_USUARIOS"   
#define LISTA_CONVERSAS "CHAT_LISTA_CONVERSAS"
#define FILA_IMAGENS    "CHAT_FILA_IMAGENS"

#define PRT_ERROR(x)   ConOut(time() + " [Thr: " + Strzero(ThreadId(), 5) + "]" + " # ERROR # " + x)
#define PRT_MSG(x)     ConOut(time() + " [Thr: " + Strzero(ThreadId(), 5) + "]" + "           " + x)

//////////////////////////////////////////////////////////////////////////////////////////////////////////
User Function ChatLogin()
  Local oDlg1
  Local oButton1
  Local oButton3
  Local oButton9
  Local oGet1

  Private cGet1
  Public aList  := {}
  Public cUsuario := nil

  cGet1 := Space(20)
    
  DEFINE MSDIALOG oDlg1 FROM 0,0 TO 160,250 PIXEL TITLE "TOTVS CHAT - Velho Novo ADVPL"

  @ 01,01 SAY "Usuario:"
  @ 01,04 MSGET oGet1 VAR cGet1 SIZE 80,10

  oButton1 := tButton():New(30, 85, 'Login',          oDlg1, {||cUsuario:=AllTrim(cGet1),TcUser(cUsuario)},35,15, ,,,.T.) 
  oButton3 := tButton():New(50, 47, 'Lista Usuarios', oDlg1, {||ListaUsers({}, Nil)}, 35, 15, ,,,.T.)
  oButton9 := tButton():New(50, 85, 'SAIR',           oDlg1, {||oDlg1:End()},       35, 15, ,,,.T.)

  ACTIVATE MSDIALOG oDlg1 CENTERED

Return nil

Static Function obtemLista(cLog)
  Local nX := 0
  Local nElem := 0
  Local aItens := {}
  
  nElem := Randomize(3, 10)
  For nX := 1 to nElem
    AAdd(aItens, {.F., "User" + cValToChar(nX)})
    PRT_MSG(cLog + "[" + cValToChar(nX) + "] = " + "User" + cValToChar(nX))
  Next

  If cUsuario != Nil
    AAdd(aItens, {.F., cUsuario})
    PRT_MSG(cLog + "[" + cValToChar(nX) + "] = " + cUsuario)
    // cUsuario := nil
  EndIf
aList := aClone(aItens)
varinfo("aList",aList)

if oListUsr != nil
  oListUsr:SetArray(aList)
  // Monta a linha a ser exibida no Browse
  oListUsr:bLine := {||{ Iif(aList[oListUsr:nAt,01],oOK,oNO),aList[oListUsr:nAt,02] } }
  // Evento de DuploClick (troca o valor do primeiro elemento do Vetor)
  oListUsr:bLDblClick := {|| If(aList != Nil .AND. oListUsr != Nil, aList[oListUsr:nAt][1] := !aList[oListUsr:nAt][1], ), If(aList != Nil .AND. oListUsr != Nil, oListUsr:DrawSelect(), ), If(aList != Nil .AND. oListUsr != Nil, Alert(aList[oListUsr:nAt][2]),Alert(aList[oListUsr:nAt][2])) }
EndIf

Return 

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function ListaUsers()
// Se passar o usuario (cUsuario) filtra e nao mostra na lista (deixando por hora so para demonstracao erro ao se tentar conversar consigo mesmo)
// Return obtemLista(LISTA_USUARIOS, @aList, "Usuario", cUser)
obtemLista("Usuario")

Return nil

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static function TcUser(cUsuario)
  Local oDlg,oBtn1,oBtn2,oBtn3,oBtn4,oBtn5,oBtn6,oBtn7,oBtn8

  Private oOK := LoadBitmap(GetResources(),'br_verde')
  Private oNO := LoadBitmap(GetResources(),'br_vermelho')
  Private oListUsr

  ListaUsers()

  DEFINE MSDIALOG oDlg FROM 0,0 TO 520,600 PIXEL TITLE 'Lista amigos de: ' + cUsuario + " - Velho ADVPL"
  // Cria objeto de fonte que sera usado na Browse
  Define Font oFont Name 'Courier New' Size 0, -12
  // Cria Browse
  oListUsr := TCBrowse():New( 01 , 01, 300, 200,,{'','Usuario'},{30,50},oDlg,,,,,{||},,oFont,,,,,.F.,,.T.,,.F.,,, )
  // Seta o vetor a ser utilizado
  oListUsr:SetArray(aList)
  // Monta a linha a ser exibida no Browse
  oListUsr:bLine := {||{ Iif(aList[oListUsr:nAt,01],oOK,oNO),aList[oListUsr:nAt,02] } }
  // Evento de DuploClick (troca o valor do primeiro elemento do Vetor)
  oListUsr:bLDblClick := {|| If(aList != Nil .AND. oListUsr != Nil, aList[oListUsr:nAt][1] := !aList[oListUsr:nAt][1], ), If(aList != Nil .AND. oListUsr != Nil, oListUsr:DrawSelect(), ), If(aList != Nil .AND. oListUsr != Nil, Alert(aList[oListUsr:nAt][2]),Alert(aList[oListUsr:nAt][2])) }
  // oList:Refresh() // refresh de tela
  // Principais commandos
  oBtn1 := TButton():New( 210, 001,'Refresh' , oDlg,{||ListaUsers()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn2 := TButton():New( 220, 001,'GoDown()', oDlg,{||oListUsr:GoDown()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn3 := TButton():New( 230, 001,'GoTop()' , oDlg,{||oListUsr:GoTop()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn4 := TButton():New( 240, 001,'GoBottom()', oDlg,{||oListUsr:GoBottom()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn5 := TButton():New( 210, 060, 'nAt (Linha selecionada)' ,oDlg,{|| Alert(oListUsr:nAt)},90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn6 := TButton():New( 220, 060, 'nRowCount (Nr de linhas visiveis)',oDlg,{|| Alert(oListUsr:nRowCount()) }, 90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn7 := TButton():New( 230, 060, 'nLen (Numero total de linhas)', oDlg,{|| Alert(oListUsr:nLen) }, 90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn8 := TButton():New( 240, 060, 'lEditCell (Edita a celula)', oDlg,{|| lEditCell(@aList,oListUsr,'@!',3) }, 90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )

  ACTIVATE MSDIALOG oDlg CENTERED on init (oListUsr:gotop())

return

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static function NovaConversa(cNovoUser)
  Local cMsg := ""

  if(cUsuario == Nil .Or. Len(cUsuario) <= 0)
    PRT_ERROR("Nao tem usuario Logado")
    Return .F.
  EndIf

  If(cUsuario == cNovoUser)
      cMsg := 'E "' + cUsuario + '" disse: ' + CRLF + '- Voce nao deve conversar com voce mesmo "' + cUsuario + '"'
      MessageBox(cMsg, "???", 48)
      PRT_ERROR(cMsg)
    Return .F.
  EndIf

  PRT_MSG(cUsuario + " iniciando com versa com: " + cNovoUser)

  StartJob("U_TcConversa", getenvserver(), .f., cUsuario, cNovoUser)
  StartJob("U_TcConversa", getenvserver(), .f., cNovoUser, cUsuario)
Return .T.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

User function TcConversa(cMeuUsuario, cNovoUser)
  Local oDlg2
  Local nId := cMeuUsuario + "_" + cNovoUser

  PRT_MSG(nId + " " + cMeuUsuario + " conversando com " + cNovoUser)
  
  ListaUsers(@aList, /*cUsuario*/)

  DEFINE MSDIALOG oDlg2 FROM 0,0 TO 520,600 PIXEL TITLE 'Lista amigos de: ' + cUsuario + " - Velho ADVPL"
  // Cria objeto de fonte que sera usado na Browse
  Define Font oFont Name 'Courier New' Size 0, -12
  // Cria Browse
  oList := TCBrowse():New( 01 , 01, 300, 200,,{'CHAT', 'Usuario'},{30,50},oDlg2,,,,,{||},,oFont,,,,,.F.,,.T.,,.F.,,, )
  // Seta o vetor a ser utilizado
  oList:SetArray(@aList)
  If(Len(aList) > 0)
    // Monta a linha a ser exibida no Browse
    //oList:bLine := {||{ If(aList[oList:nAt,01],oOK,oNO),aList[oList:nAt,02],aList[oList:nAt,03],Transform(aList[oList:nAT,04],'@E 99,999,999,999.99') } }
    oList:bLine := {||{ If(aList != Nil .AND. oList != Nil .AND. aList[oList:nAt, 01], oOK, oNO), If(aList != Nil .AND. oList != Nil, aList[oList:nAt,02], ) } }
    // Evento de DuploClick (troca o valor do primeiro elemento do Vetor)
    oList:bLDblClick := {|| If(aList != Nil .AND. oList != Nil, aList[oList:nAt][1] := !aList[oList:nAt][1], ), If(aList != Nil .AND. oList != Nil, oList:DrawSelect(), ), If(aList != Nil .AND. oList != Nil, NovaConversa(aList[oList:nAt][2]), ) }
  EndIf
  // Principais commandos
  //oBtn := TButton():New( 210, 001,'Refresh' , oDlg2,{||TcUser()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 210, 001,'Refresh' , oDlg2,{||, oList:Refresh(), ListaUsers(@aList, /*cUsuario*/), oList:SetArray(@aList), oList:Refresh()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  // oBtn := TButton():New( 210, 001,'GoUp()' , oDlg2,{||oList:GoUp()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 220, 001,'GoDown()', oDlg2,{||oList:GoDown()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 230, 001,'GoTop()' , oDlg2,{||oList:GoTop()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 240, 001,'GoBottom()', oDlg2,{||oList:GoBottom()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 210, 060, 'nAt (Linha selecionada)' ,oDlg2,{|| Alert(oList:nAt)},90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 220, 060, 'nRowCount (Nr de linhas visiveis)',oDlg2,{|| Alert(oList:nRowCount()) }, 90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 230, 060, 'nLen (Numero total de linhas)', oDlg2,{|| Alert(oList:nLen) }, 90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 240, 060, 'lEditCell (Edita a celula)', oDlg2,{|| lEditCell(@aList,oList,'@!',3) }, 90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )

  oList:Refresh() // refresh da lista
  ACTIVATE MSDIALOG oDlg2 CENTERED
return

//////////////////////////////////////////////////////////////////////////////////////////////////////////
user function TcBrowse_EX()
  Local oOK := LoadBitmap(GetResources(),'br_verde')
  Local oNO := LoadBitmap(GetResources(),'br_vermelho')
  Local aList := {} // Vetor com elementos do Browse
  //Local nX := 0

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
  oBtn := TButton():New( 210, 001,'Refresh' , oDlg,{||MyArray(@aList)},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  // oBtn := TButton():New( 210, 001,'GoUp()' , oDlg,{||oList:GoUp()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 220, 001,'GoDown()', oDlg,{||oList:GoDown()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 230, 001,'GoTop()' , oDlg,{||oList:GoTop()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 240, 001,'GoBottom()', oDlg,{||oList:GoBottom()},40, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 210, 060, 'nAt (Linha selecionada)' , oDlg,{|| Alert(oList:nAt)},90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 220, 060, 'nRowCount (Nr de linhas visiveis)',oDlg,{|| Alert(oList:nRowCount()) }, 90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 230, 060, 'nLen (Numero total de linhas)', oDlg,{|| Alert(oList:nLen) }, 90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
  oBtn := TButton():New( 240, 060, 'lEditCell (Edita a celula)', oDlg,{|| lEditCell(@aList,oList,'@!',3) }, 90, 010,,,.F.,.T.,.F.,,.F.,,,.F. )

  ACTIVATE MSDIALOG oDlg CENTERED
return

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function MyArray(aList)
local aListAux := {}
local nX := 0
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

//////////////////////////////////////////////////////////////////////////////////////////////////////////
