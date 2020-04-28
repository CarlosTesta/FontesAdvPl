#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TBICONN.CH'

User Function MyDTOC()

ConOut("Função Principal | ANTES do RPCSetEnv() <<"+DTOC(Date())+">>" )
RPCSetType(3)
RPCSetEnv("T1","D MG 01 ",,,"EST")
ConOut("Função Principal | DEPOIS do RPCSetEnv() <<"+DTOC(dDataBase)+">>" )

StartJob("U_MyStartJ",GetEnvServer(),.F.,"T1","D MG 01 ")

Return Nil

User Function MyStartJ(cEmp,cFil)
SET CENTURY ON
ConOut("StartJob MyStartJ | ANTES do RPCSetEnv() <<"+DTOC(Date())+">>" )
RPCSetType(3)
RPCSetEnv(cEmp,cFil,,,"EST")

ConOut("StartJob MyStartJ | DEPOIS do RPCSetEnv() <<"+DTOC(DATE())+">>" )

Return Nil
