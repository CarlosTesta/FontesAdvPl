#include 'protheus.ch'

user function MyJsonTst()
local aUsers :=  GetUserInfoArray()
local aCab := {"USUARIO","ESTACAO","ID","SERVIDOR","PROGRAMA","ENVIRONMENT","START","TEMPO_CONEXAO","N_INSTR_SEC","N_INSTR","OBS","MEMORIA","SID","OPCAO","ESP"}
local cJSON := '{"USER": [' 
 
FOR L:= 1 TO LEN( aUsers )
    cJSON += '{'
    for C:= 1 to Len( aCab ) 
        IF VALTYPE(aUsers[L][C]) = "C"  
            cConteudo := '"'+aUsers[L][C]+'" '
        ELSEIF VALTYPE(aUsers[L][C]) = "N"
            cConteudo := ALLTRIM(STR(aUsers[L][C]))
        ELSEIF VALTYPE(aUsers[L][C]) = "D"
            cConteudo := '"'+DTOC(aUsers[L][C])+'"'
        ELSEIF VALTYPE(aUsers[L][C]) = "L"
            cConteudo := IF(aUsers[L][C], '"true"' , '"false"') 
        ELSE
            cConteudo := '"'+aUsers[L][C]+'"'
        ENDIF               
        cJSON += '"'+aCab[C]+'":' + cConteudo
        IF C < LEN(aCab)
            cJSON += ','
        ENDIF
    Next
    cJSON += '}'
    IF L < LEN(aUsers)
        cJSON += ','
    ENDIF
Next
cJSON += ']}'

cJSON := StrTran(cJSON,chr(10),'')
cJSON := StrTran(cJSON,'\','\\')

conout(cJSON)

Return nil