// Success with warnings

#include "dir_1/file_1.mqh" // [info] Include existing file

int OnInit() {
   return INIT_SUCCEEDED;
}

void OnTick() {
   string test; // [warn] Unused variable
}

