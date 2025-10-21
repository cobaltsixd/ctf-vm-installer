#include <stdio.h>
#include <string.h>
int main(int argc, char **argv){
    if(argc<2){ puts("Usage: checker <password>"); return 1; }
    char *p = argv[1];
    if(strlen(p)==12 && p[0]=='s' && p[1]=='3' && p[2]=='c' && p[3]=='r' && p[11]=='X'){
        puts("OK");
        return 0;
    }
    puts("NO");
    return 1;
}
