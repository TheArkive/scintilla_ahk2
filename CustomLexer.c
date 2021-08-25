#include <stdio.h>

#define NOGDI
#define WIN32_LEAN_AND_MEAN
#define NOCRYPT
#define NOSERVICE

#define NOATOM
#define NOGDICAPMASKS
#define NOMETAFILE
#define NOMINMAX
#define NOMSG
// #define NOOPENFILE
#define NORASTEROPS
#define NOSCROLL
#define NOSOUND
#define NOSYSMETRICS
#define NOTEXTMETRIC
#define NOWH
#define NOCOMM
#define NOKANJI
#define NOMCX


#include <windows.h>

typedef uintptr_t uptr_t;   // Define uptr_t, an unsigned integer type large enough to hold a pointer.
typedef intptr_t sptr_t;    // Define sptr_t, a signed integer large enough to hold a pointer.

typedef sptr_t (*SciFnDirect)(sptr_t ptr, unsigned int iMessage, uptr_t wParam, sptr_t lParam);
typedef sptr_t (*SciFnDirectStatus)(sptr_t ptr, unsigned int iMessage, uptr_t wParam, sptr_t lParam, int *pStatus);

typedef long Sci_PositionCR;

#define SCINT_NONE 0
#define SCINT_STRING1 1
#define SCINT_STRING2 2
#define SCINT_COMMENT1 3
#define SCINT_COMMENT2 4
#define SCINT_NUMBER 5
#define SCINT_BRACE 6
#define SCINT_PUNCT 7


struct Sci_CharacterRange {
    Sci_PositionCR cpMin;
    Sci_PositionCR cpMax;
};

struct Sci_TextRange {
    struct Sci_CharacterRange chrg;
    char *lpstrText;
};

struct sci_ctl {
    HWND hwnd;
    int status;
} sci_ctl;

struct scint {
    int pos;
    int length;
    int line;
    int linesAdded;
    
    char strStyle1; // 7 styles
    char strStyle2;
    char commentStyle1;
    char commentStyle2;
    char braceStyle;
    char braceBadStyle;
    char punctStyle;
    char numStyle;
    
    char *braces;
    char *comment1;
    char *comment2a;
    char *comment2b;
    char *escape;
    char *punct;
    HWND hwnd;
} scint;


SciFnDirect pSciMsg; // declare direct function
SciFnDirectStatus pSciMsgStat; // declare direct function

sptr_t directPtr = 0;
HWND scintHwnd = 0;


// thanks to TutorialsPoint.com for making this easy to understand
// Link: https://www.tutorialspoint.com/cprogramming/c_variable_arguments.htm
//
// and thanks to robodesign on AHK forums for pointing out the OutputDebugStringA() func.
void dbg(int num, ...) {
    
    int i, total_sz = 5, offset = 5;
    
    va_list valist;
    char *outStr = calloc(1, sizeof(char)), *curStr = "";
    outStr = realloc(outStr, 6);
    memcpy(outStr, "AHK: ", 5);
    outStr[5] = '\0';
    
    /* initialize valist for num number of arguments */
    va_start(valist, num);
    
    for (i=0 ; i<num ; i++) {
        curStr = va_arg(valist, char *);
        total_sz += strlen(curStr);
        
        outStr = realloc(outStr, total_sz + 1);
        memcpy(outStr + offset, curStr, strlen(curStr));
        outStr[total_sz] = '\0';
        offset += strlen(curStr);
    }
    
    OutputDebugStringA(outStr);
    free(outStr);
}


// thanks to Andreas Storvik Strauman for this variable array code
// Link: https://stackoverflow.com/questions/30280444/array-of-unknown-number-of-elements-in-c
typedef struct {
    unsigned int size;
    unsigned int capacity;
    unsigned int *array;
} array_t;

#define ARRAY_INIT_CAPACITY 4

array_t *new_array(){
    array_t *arr=malloc(sizeof(array_t));
    arr->array=malloc(sizeof(int)*ARRAY_INIT_CAPACITY);
    arr->size=0;
    arr->capacity=ARRAY_INIT_CAPACITY;
    return arr;
}

void increase_array(array_t *array){
    int new_capacity=array->capacity*2;
    int *new_location = realloc(array->array, new_capacity*sizeof(int));
    if (!new_location) {
        fprintf(stderr, "Out of memory");
        exit(1);
    }
    array->capacity=new_capacity;
    array->array=new_location;
}

void array_append(array_t *array, int item){
    if (array->size >= array->capacity){
        increase_array(array);
    }
    array->array[array->size]=item;
    array->size+=1;
}

/*
Error Codes:

0 - no error


*/



sptr_t CallStatus(unsigned int iMessage, uptr_t wParam, sptr_t lParam) {    // DirectStatus func does not work :(
    int *pStatus;                                                           // causes error 0x00000005
    sptr_t result = pSciMsgStat(directPtr, iMessage, wParam, lParam, 0);
    sci_ctl.status = *pStatus;
    return result;
}

sptr_t Call(unsigned int iMessage, uptr_t wParam, sptr_t lParam) { // direct func works!
    return pSciMsg(directPtr, iMessage, wParam, lParam);;
}

// sptr_t Call(unsigned int iMessage, uptr_t wParam, sptr_t lParam) { // direct func works!
    // return SendMessage(scintHwnd, iMessage, wParam, lParam);;
// }

__declspec(dllimport) sptr_t Init(struct sci_ctl *data) {
    scintHwnd = data->hwnd;
    
    // It appears to work, but calling pSciMsgStat() always results in error 0x00000005.
    pSciMsgStat = (SciFnDirectStatus) SendMessage(scintHwnd, 0xAD4, 0, 0); // SCI_GETDIRECTSTATUSFUNCTION
    
    // This one works.
    pSciMsg = (SciFnDirect) SendMessage(scintHwnd, 0x888, 0, 0); // SCI_GETDIRECTFUNCTION
    
    directPtr = (sptr_t) SendMessage(scintHwnd, 0x889, 0, 0); // SCI_GETDIRECTPOINTER
    
    // dbg(2,"hello world asdf asdf: ", "poof");
    
    return directPtr;
};



unsigned int DelBrace(unsigned int startPos
                    , unsigned int endPos
                    , int brace
                    , int braceBad
                    , char *braces) {

    unsigned int mPos = 0;
    unsigned int curPos = 0, style_check = 0;

    unsigned int chunkLen  = endPos - startPos;
    unsigned int docLength = Call(0x7D6, 0, 0); // SCI_GETLENGTH // mostly for screen styling
    char *curChar;
    
    // -----------------------------------------------------------------
    struct Sci_CharacterRange cr;
    struct Sci_TextRange tr;
    
    cr.cpMin = startPos;
    cr.cpMax = endPos;
    tr.chrg = cr;
    tr.lpstrText = calloc(endPos-startPos+2, sizeof(char));
    
    Call(0x872, 0, (LPARAM) &tr); // SCI_GETTEXTRANGE
    // char *docTextRange = tr.lpstrText;
    // -----------------------------------------------------------------
    // char *docTextRange = (char *) Call(0xA53, startPos, endPos); // SCI_GETCHARACTERPOINTER (0x9D8) / SCI_GETRANGEPOINTER (0xA53)
    // -----------------------------------------------------------------
    
    for (int j=0 ; j<chunkLen ; j++) {
        
        // curChar = &docTextRange[j];
        curChar = &tr.lpstrText[j];
        curPos = startPos + j;
        
        if (curPos > (docLength-1))
            return 0;
        
        if (strchr(braces, *curChar)) {
        
            style_check = Call(0x7DA, curPos, 0); // SCI_GETSTYLEAT
            if (style_check != brace) {
                
                continue;
            }
            
            mPos = Call(0x931, curPos, 0);
            if (mPos != -1) {
                Call(0x7F0, mPos, 0);                       // SCI_STARTSTYLING
                Call(0x7F1, 1, (LPARAM) braceBad);  // SCI_SETSTYLING
                Call(0x7F0, curPos, 0);                     // SCI_STARTSTYLING
                Call(0x7F1, 1, (LPARAM) braceBad);  // SCI_SETSTYLING
                
            }
            
            // reset last style pos checking
            style_check = Call(0x7DA, docLength-1, 0); // SCI_GETSTYLEAT
            Call(0x7F0, docLength-1, 0);    // SCI_STARTSTYLING
            Call(0x7F1, 1, (LPARAM) style_check);    // SCI_SETSTYLING
        }
    }
    
    free(tr.lpstrText);
    
    return 0;

}

__declspec(dllimport) unsigned int DeleteRoutine(unsigned int startPos
                                               , unsigned int endPos
                                               , int brace
                                               , int braceBad
                                               , char *braces) {
    
    return DelBrace(startPos, endPos, brace, braceBad, braces);
}



__declspec(dllimport) unsigned int ChunkColoring(struct scint *data) { // experimenting
    
    unsigned int mPos = 0;
    
    array_t *braceList = new_array();
    
    unsigned int docLength = Call(0x7D6, 0, 0); // SCI_GETLENGTH // mostly for screen styling
    unsigned int startPos = 0, endPos = 0, startLine = 0, diff = 0, lastLine = 0, lines = 0;
    
    if (data->linesAdded) { // full chunk styling, or line styling
    
        startLine = Call(0x876, data->pos, 0); // SCI_LINEFROMPOSITION
        startPos  = Call(0x877, startLine, 0); // SCI_POSITIONFROMLINE
        
        diff      = data->pos - startPos;
        endPos    = startPos + data->length + diff;
        
    } else {
        
        startLine = Call(0x876, data->pos, 0); // SCI_LINEFROMPOSITION
        startPos  = Call(0x877, startLine, 0); // SCI_POSITIONFROMLINE
        endPos    = startPos + Call(0x92E, startLine, 0); // SCI_LINELENGTH

    }
    
    // char buf1[10], buf2[10], buf3[10];
    // dbg(6,"startPos: " , itoa(data->pos,buf1,10), " / endPos: ", itoa(endPos,buf2,10), " / len: ", itoa(data->length,buf3,10));
    
    unsigned int chunkLen  = endPos - startPos;
    char *docTextRange = (char *) Call(0xA53, startPos, endPos); // SCI_GETCHARACTERPOINTER (0x9D8) / SCI_GETRANGEPOINTER (0xA53)
    
    mPos = 0;
    unsigned int style_st = 0, style_len = 0, style_check = 0, curPos = 0, curStyle = SCINT_NONE, x_count = 0, isWord = 0, i = 0;
    
    char *style_type = "", *curChar = "", *curChar2 = "", *prevChar = "", *prevChar2 = "", *nextChar = "";
    char *com1    = data->comment1;
    char *com1_test = calloc(1,sizeof(char));
    char *escChar = data->escape;
    
    char *com2a   = data->comment2a;
    char *com2b   = data->comment2b;
    
    char *com2a_test = calloc(1,sizeof(char)); // Init /* block comment */ match ...
    char *com2b_test = calloc(1,sizeof(char)); // and prepare for look ahead match.
    
    // int j = 0;
    
    // while (j < chunkLen) {
    for (int j=0 ; j<chunkLen ; j++) {
        
        curChar = &docTextRange[j];
        curPos = startPos + j;
        
        if (curPos > (docLength-1))
            return 0;
        
        switch (curStyle) {
            
            case (SCINT_STRING1):
                
                prevChar = &docTextRange[j-1];
                prevChar2 = &docTextRange[j-2];
                
                if (*curChar != '"' || (*prevChar == *escChar && *prevChar2 != *escChar))
                    continue;
                
                Call(0x7F0, (style_st), 0);  // SCI_STARTSTYLING
                Call(0x7F1, (curPos-style_st+1), (LPARAM) data->strStyle1);  // SCI_SETSTYLING
                curStyle = SCINT_NONE, style_st = 0;
                    
                break;
                
            case (SCINT_STRING2):
                
                prevChar = &docTextRange[j-1];
                prevChar2 = &docTextRange[j-2];
                
                if (*curChar != '\'' || (*prevChar == *escChar && *prevChar2 != *escChar))
                    continue;
                
                Call(0x7F0, (style_st), 0);  // SCI_STARTSTYLING
                Call(0x7F1, (curPos-style_st+1), (LPARAM) data->strStyle2);  // SCI_SETSTYLING
                curStyle = SCINT_NONE, style_st = 0;
                    
                break;
                
            case (SCINT_COMMENT1):
                
                if (*curChar == '\n' || curPos == (docLength-1)) {
                    DelBrace(style_st, curPos+1, data->braceStyle, data->braceBadStyle, data->braces);
                    
                    Call(0x7F0, (style_st), 0);  // SCI_STARTSTYLING
                    Call(0x7F1, (curPos-style_st+1), (LPARAM) data->commentStyle1);  // SCI_SETSTYLING
                    curStyle = SCINT_NONE, style_st = 0;
                    
                }
                break;
                
            case (SCINT_COMMENT2):
            
                free(com2b_test); // block comment end
                com2b_test = calloc(strlen(com2b)+1, sizeof(char));
                strncpy(com2b_test, docTextRange+j, strlen(com2b));
                
                if (!strcmp(com2b, com2b_test)) {
                    Call(0x7F0, (style_st), 0);  // SCI_STARTSTYLING
                    Call(0x7F1, (curPos-style_st+strlen(com2b)), (LPARAM) data->commentStyle2);  // SCI_SETSTYLING
                    j = j + strlen(com2b) - 1;
                    curStyle = SCINT_NONE, style_st = 0;
                    
                }
                
                break;
                
            case (SCINT_NUMBER):
                
                i++;
                nextChar = (j < (chunkLen-1)) ? &docTextRange[j+1] : "";
                
                if (*curChar != 'x' && !isxdigit(*curChar)) {
                    Call(0x7F0, (style_st), 0);  // SCI_STARTSTYLING
                    Call(0x7F1, (curPos-style_st+1), (LPARAM) 32);  // SCI_SETSTYLING
                    style_st = 0, i = 0, isWord = 0, curStyle = SCINT_NONE, x_count = 0;
                    continue;
                    
                } else if (*curChar == 'x') {
                    x_count++;
                    if (x_count > 1 || i != 2) {
                        Call(0x7F0, (style_st), 0);  // SCI_STARTSTYLING
                        Call(0x7F1, (curPos-style_st+1), (LPARAM) 32);  // SCI_SETSTYLING
                        style_st = 0, i = 0, isWord = 0, curStyle = SCINT_NONE, x_count = 0;

                    }
                    continue;
                
                } else if (isspace(*nextChar) || ispunct(*nextChar) || curPos == (chunkLen-1)) {
                    Call(0x7F0, (style_st), 0);  // SCI_STARTSTYLING
                    Call(0x7F1, (curPos-style_st+1), (LPARAM) data->numStyle);  // SCI_SETSTYLING
                    style_st = 0, i = 0, isWord = 0, curStyle = SCINT_NONE, x_count = 0;
                    
                }
                
                i++;
                break;
                
            case (SCINT_NONE):
                
                free(com1_test); // line comments
                com1_test = calloc(strlen(com1)+1, sizeof(char));
                strncpy(com1_test, docTextRange+j, strlen(com1));
                
                free(com2a_test); // block comment beginning
                com2a_test = calloc(strlen(com2a)+1, sizeof(char));
                strncpy(com2a_test, docTextRange+j, strlen(com2a));
                
                if (*curChar == '"') {
                    
                    style_check = Call(0x7DA, curPos, 0); // SCI_GETSTYLEAT
                    if (style_check == data->commentStyle1 || style_check == data->commentStyle2)
                        continue;
                    curStyle = SCINT_STRING1, style_st = curPos;
                    
                } else if (*curChar == '\'') {
                    
                    style_check = Call(0x7DA, curPos, 0); // SCI_GETSTYLEAT
                    if (style_check == data->commentStyle1 || style_check == data->commentStyle2)
                        continue;
                    curStyle = SCINT_STRING2, style_st = curPos;
                
                } else if (!strcmp(com1, com1_test)) {
                    
                    if (*curChar == ';' && curPos == (docLength-1)) {
                        Call(0x7F0, (curPos), 0);  // SCI_STARTSTYLING
                        Call(0x7F1, strlen(com1), (LPARAM) data->commentStyle1);  // SCI_SETSTYLING
                        continue;
                    }
                    
                    curStyle = SCINT_COMMENT1, style_st = curPos;
                
                } else if (!strcmp(com2a, com2a_test)) {
                    curStyle = SCINT_COMMENT2, style_st = curPos;
                
                } else if (isdigit(*curChar)) {
                    nextChar = (j < (chunkLen-1)) ? &docTextRange[j+1] : "";
                    prevChar = (j > 0) ? &docTextRange[j-1] : "";
                    
                    if (isspace(*prevChar) || ispunct(*prevChar) || curPos == 0) {
                        
                        if (isspace(*nextChar) || ispunct(*nextChar) || curPos == (chunkLen-1)) {
                            Call(0x7F0, (curPos), 0);  // SCI_STARTSTYLING
                            Call(0x7F1, 1, (LPARAM) data->numStyle);  // SCI_SETSTYLING

                        } else if (*nextChar == 'x' || isdigit(*nextChar)) {
                            curStyle = SCINT_NUMBER, style_st = curPos, i = 1, x_count = 0;
                            
                        }
                    }
                    
                }
                else if (strchr(data->braces, *curChar)) {
                    style_check = Call(0x7DA, curPos, 0); // SCI_GETSTYLEAT
                    if (style_check == data->braceStyle)
                        continue;
                    
                    array_append(braceList, curPos);
                    Call(0x7F0, (curPos), 0);  // SCI_STARTSTYLING
                    Call(0x7F1, 1, (LPARAM) data->braceBadStyle);  // SCI_SETSTYLING
                    
                }
                else if (strchr(data->punct, *curChar)) {
                    Call(0x7F0, (curPos), 0);  // SCI_STARTSTYLING
                    Call(0x7F1, 1, (LPARAM) data->punctStyle);  // SCI_SETSTYLING
                    
                }
                // else {
                    // Call(0x7F0, (curPos), 0);  // SCI_STARTSTYLING
                    // Call(0x7F1, 1, (LPARAM) 32);  // SCI_SETSTYLING
                
                // }
                break;
                
        } // switch statement
        
    } // for loop
    
    // reset last style pos checking - required for properly matching braces
    style_check = Call(0x7DA, docLength-1, 0); // SCI_GETSTYLEAT
    Call(0x7F0, docLength-1, 0);    // SCI_STARTSTYLING
    Call(0x7F1, 1, (LPARAM) style_check);    // SCI_SETSTYLING
    
    unsigned int k = braceList->size;
    i = 0;
    while (i < k) {
        
        curPos = braceList->array[i];
        mPos = Call(0x931, curPos, 0);

        if (mPos != -1) {
            style_check = Call(0x7DA, curPos, 0); // SCI_GETSTYLEAT
            if (style_check != data->braceBadStyle) {
                i++;
                continue;
            }
            
            Call(0x7F0, mPos, 0);                       // SCI_STARTSTYLING
            Call(0x7F1, 1, (LPARAM) data->braceStyle);  // SCI_SETSTYLING
            Call(0x7F0, curPos, 0);                     // SCI_STARTSTYLING
            Call(0x7F1, 1, (LPARAM) data->braceStyle);  // SCI_SETSTYLING
            
            // reset last style pos checking
            style_check = Call(0x7DA, docLength-1, 0);  // SCI_GETSTYLEAT
            Call(0x7F0, docLength-1, 0);                // SCI_STARTSTYLING
            Call(0x7F1, 1, (LPARAM) style_check);       // SCI_SETSTYLING
            
        }
        
        i++;
    }
    
    free(braceList->array);
    free(braceList);
    
    if (com1_test)
        free(com1_test);
    if (com2a_test)
        free(com2a_test);
    if (com2b_test)
        free(com2b_test);
    
    return 0;
};


























