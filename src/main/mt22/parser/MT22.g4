//MSSV 2052649

grammar MT22;

@lexer::header {
from lexererr import *
}

options{
	language=Python3;
}

// PARSER
program: declarationlist EOF ;
declaration: (vardecl|funcdecl) ;
declarationlist: declaration declarationlisttail|declaration;
declarationlisttail: declaration declarationlisttail|;

//Types and values
atomicType: BOOLEAN|INTEGER|FLOAT|STRING;
dimension: INTLIT dimensiontail| INTLIT;
dimensiontail: CM INTLIT dimensiontail| ;
arrayType: ARRAY LSQ dimension RSQ OF atomicType ;
voidType: VOID ;
autoType: AUTO;

//Declarations
idlist:ID idtail|ID ;
idtail: CM ID idtail| ; 
vardecl : idlist CL (atomicType|autoType|dimension|arrayType) SM |vardeclnosemi SM;
vardeclnosemi: ID CL (atomicType|autoType|dimension|arrayType) ASSIGN expr | ID CM vardeclnosemi CM expr;
vardecllist: vardecl vardecllisttail| vardecl;
vardecllisttail: vardecl vardecllisttail|;
para: (INHERIT| ) (OUT|) ID CL (atomicType|autoType|dimension|arrayType) ;
paralist: para paratail| para;
paratail: CM para paratail|;
funcdecl: funcpropo funcbody ;
funcpropo: ID CL FUNCTION (atomicType|voidType|arrayType|autoType) 
	LP (paralist|) RP ((INHERIT ID)|) ;
funcbody:blockstmt;
callexpr: ID LP (exprlist|) RP;

//index operators
idxOp: ID LSQ exprlist RSQ;

//Expressions (Checking the unary again)
expr: expr1 STRCONCAT expr1 | expr1;
expr1: expr2 (EQ|NOTEQ|LESS|GREATER|GREATEREQ|LESSEQ) expr2| expr2 ;
expr2: expr2 (AND|OR) expr3| expr3;
expr3: expr3 (PLUS|MINUS) expr4| expr4; 
expr4: expr4 (MUL|DIVIDE|MODULO) expr5| expr5; 
expr5: (NOT) expr5| expr6;
expr6: (MINUS) expr6| expr7; 
expr7: idxOp | expr8; 
expr8: ID|numOperand|booleanOperand|stringOperand|relationalOperand|callexpr|subexpr|arraylit;

//List of operands
exprlist: expr exprlisttail| expr;
exprlisttail: CM expr exprlisttail|;
subexpr: LP expr RP ;
numOperand: INTLIT|FLOATLIT ;
booleanOperand: boolean;
stringOperand: STRLIT;
relationalOperand: INTLIT|boolean;


//Statements
stmt:assignstmt|ifstmt|forstmt|whilestmt|do_whilestmt|breakstmt
	|continuestmt|returnstmt|callstmt|blockstmt;
stmtlist: stmt stmtlisttail| stmt;
stmtlisttail: stmt stmtlisttail| ;
lhs: ID|idxOp;
assignstmt: lhs ASSIGN expr SM ;
ifstmt: IF LP expr RP stmt ((ELSE stmt)|) ;
forstmt: FOR LP lhs ASSIGN expr CM expr CM expr RP
    stmt  ;//different from Parser
whilestmt: WHILE LP expr RP stmt;
do_whilestmt: DO blockstmt WHILE LP expr RP SM;
breakstmt: BREAK SM;
continuestmt: CONTINUE SM;
returnstmt: RETURN (expr| ) SM;
callstmt: ID LP (exprlist|) RP SM;
blockstmt: LC (blockcontentlist| ) RC;
blockcontent: (stmt|vardecl);
blockcontentlist: blockcontent blockcontentlisttail| blockcontent;
blockcontentlisttail: blockcontent blockcontentlisttail|;

boolean: TRUE|FALSE ;
arraylit: LC (exprlist) RC;
comment: COMMENTCPP| COMMENTC;

// LEXER
WS : [ \t\r\n\b\f]+ -> skip ; // skip spaces, tabs, newlines, return, backspace, formfeed
COMMENT: '//';
LCOMMENT: '/*';
RCOMMENT: '*/';

//Comment
COMMENTLINE: '//' ~[\r\n\f]* -> skip;
COMMENTGRAPH: '/*' .*? '*/' -> skip;
COMMENTC : '/*' .*? '*/' -> skip;
COMMENTCPP : '//' (~[\r\f\n])* -> skip;

//Keywords
AUTO: 'auto';
INTEGER: 'integer';
VOID: 'void';
ARRAY:'array';
BREAK: 'break';
FLOAT: 'float';
RETURN: 'return';
OUT: 'out';
BOOLEAN: 'boolean';
FOR: 'for';
STRING: 'string';
CONTINUE: 'continue';
DO: 'do';
FUNCTION: 'function';
OF: 'of';
ELSE: 'else';
IF: 'if';
WHILE: 'while';
INHERIT: 'inherit';
TRUE: 'true';
FALSE: 'false';

//Operators
PLUS: '+';
NOT: '!';
NOTEQ: '!=';
MINUS: '-';
MUL:'*';
AND: '&&';
LESS: '<';
OR: '||';
LESSEQ: '<=';
DIVIDE: '/';
EQ: '==';
GREATER: '>';
MODULO: '%';
GREATEREQ: '>=';
STRCONCAT: '::';

//Seperators
DOT: '.';
CL: ':';
CM : ',' ;
SM : ';' ;
LP : '(' ;
RP : ')' ;
LC : '{' ;
RC : '}' ;
ASSIGN: '=';
LSQ: '[';
RSQ: ']';

//Literals
ID: [a-zA-Z_][a-zA-Z_0-9]* ;
INTLIT : [0]|[1-9]+[0-9_]* {
    self.text = self.text.replace("_", "")
};
FLOATLIT: (INTPART|) (DECIMAL|EXP|DECIMAL EXP?) {
    self.text = self.text.replace("_", "")
};
fragment DECIMAL: '.' [0-9]*;
fragment EXP: ('e'|'E') (MINUS|PLUS)? [0-9]+;
fragment INTPART: [0]|[1-9]+[0-9_]*  ;
STRLIT: '"'StrChar?'"' {
    self.text = self.text[1:-1]
};
fragment StrChar:(~["\\\r\n] | EscSe)+;
fragment EscSe:'\\' [btnfr"'\\];

//Identifiers
UNCLOSE_STRING: ["](~[\\'"\b\f\r\n\t]|EscSe)*EOF?{
    y = str(self.text)
    raise UncloseString(y[1:])
};
ILLEGAL_ESCAPE: '"' (~["\\\r\n\b\t\f]|'\\' [btnfr"\\])* '\\' (~[btnfr"\\])? {
    raise IllegalEscape(self.text[1:])
};
ERROR_CHAR: . {
    raise ErrorToken(self.text)
};
// fragment StrChar: ~["\\\r\n];
// fragment Escape: '\\' [btnfr"'\\];
// //Error
// UNCLOSE_STRING: '"' (~["\\\r\n] | Escape)* {raise UncloseString(self.text[1:])};
// ILLEGAL_ESCAPE: '"' (StrChar | Escape)* '\\' ~[btnfr"'\\] {raise IllegalEscape(self.text[1:])};
// ERROR_CHAR: . {raise ErrorToken(self.text)};