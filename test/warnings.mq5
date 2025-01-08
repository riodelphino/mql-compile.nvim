// Success with warnings

#include "class/file_1.mqh" // Infomation: Include existing file
/*#include "class/file_2.mqh" // Error: Include no existing file*/

int OnInit() {
   return INIT_SUCCEEDED;
}

void OnTick() {
   string test; // Warning: Unused variable
}

// aaa // Error: Syntax error
