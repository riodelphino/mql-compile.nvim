// Failed with errors

#include "class/file_1.mqh" // [INFO] Include existing file
#include "class/file_2.mqh" // [ERROR] Include no existing file

int OnInit() {
   return INIT_SUCCEEDED;
}

void OnTick() {
   string test; // [WARN] Unused variable
}

aaa // [ERROR] Syntax error
