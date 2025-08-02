%{
    // Prologue
%}

%union {
    int i;
}

%token <i> NUM
%start sum

%%

number: NUM
      ;

sum: number '+' number
   ;

%%

// Epilogue
