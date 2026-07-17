// Failed to compile with errors

#property version "1.00"

#include "MQL5\Include\Trade\Trade.mqh"
#include "dir_1/file_1.mqh" // [info] Include existing file
#include "dir_1/file_2.mqh" // [error] Include no existing file

int OnInit() {
   return INIT_SUCCEEDED;
}

void OnTick() {
   string test; // [warn] Unused variable
}

aaa // [error] Syntax error
