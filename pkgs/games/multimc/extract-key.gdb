b main
run
b Secrets::getMSAClientID
j Secrets::getMSAClientID
p (void*)malloc(0x1000)
set $rsi=$1
b QString::fromUtf8_helper
c
p (char*)$rsi
