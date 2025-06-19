%{
    // Prologue
%}

%union {
    int i;
}

%token <i> NUM
%start number sum
%start minus

%%

number: NUM
      ;

sum: NUM '+' NUM
   ;

minus: NUM '-' NUM
     ;

%%

// Epilogue
