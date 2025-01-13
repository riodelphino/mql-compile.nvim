// Failed with errors

#include "dir_1/file_1.mqh" // [info] Include existing file
#include "dir_1/file_2.mqh" // [error] Include no existing file

int OnInit() {
   return INIT_SUCCEEDED;
}

void OnTick() {
   string test; // [warn] Unused variable
}

aaa // [error] Syntax error

