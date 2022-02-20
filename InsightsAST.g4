/** 
* Grammar for edge query streaming model
*/
grammar InsightsAST;
//import CommonLexerRules;
queries                 : (functions SEMI_COLON)? insights;
functions               :  function ( SEMI_COLON function)*
;
function                : 'FUNCTION' udfName LPAR params? RPAR '{'  code '}'
;
code                    : '...'
;
params                  : param (COMMA param)*
;
param                   : ID
;
insights                :  insight ( SEMI_COLON insight)* SEMI_COLON? EOF
;
insight                 :  ID ASSIGNMENT body
;
body                    : COMPUTE composition (EVERY interval)? (WITH optimizations)?
;
groupBY                 :  BY metric
;
composition             : compositeExpression (FROM metricStream)? (groupBY)? 
;
compositeExpression     : LPAR compositeExpression BINARY_OPERATOR compositeExpression (BINARY_OPERATOR compositeExpression)* RPAR
                        | LPAR INSIGHT ID BINARY_OPERATOR INSIGHT ID RPAR (WHEN filters)?
                        | expression
                        | LPAR expression RPAR
                        | INSIGHT ID (WHEN filters)?
;
expression              : aggregate (WHEN filters)?
                        | number
                        | metricStream
                        | mapOp LPAR expression RPAR
;
aggregate               : windowed_function LPAR composition  (COMMA composition)* RPAR
                        | windowed_function LPAR metricStream COMMA window RPAR
                        | windowed_function LPAR metricStream COMMA window COMMA offset RPAR
                        | accumulated_function LPAR metricStream  RPAR
;
windowed_function       : windowed_parameterized
                        | WINDOWED_FUNCTION
;
accumulated_function    : accumulated_parameterized
                        | ACCUMULATED_FUNCTION
;
metricStream            : metrics (WHEN filters)?
;
metrics                 : metric (COMMA metric)*
;
metric                  : ID;
interval                : timeperiod | tuplebased;
tuplebased              : POSITIVE_INT sizeUnit;
sizeUnit                : 'D' | 'H' | 'K' | 'M';
window                  : timeperiod;
offset                  : timeperiod;
timeperiod              : POSITIVE_INT TIME_PERIOD (AT SPECIFIC_TIME)?
                        ;
optimizations           : optimization (AND optimization)*;
optimization            : salience
                        | confidence AND 'AWARENESS' 'ON' awareness
                        | SAMPLE PERCENT
                        | 'SIGNATURE'  '\'' ID '\''  
                        | 'ALLOW' WHEN filters
                        | 'ALLOW ON' ('DEDICATED'|POSITIVE_INT 'NODES')
;
awareness               : 'COMPUTATIONS' | 'ACCURACY'
;
salience                : SALIENCE POSITIVE_INT
;
confidence              : MAX_ERROR PERCENT AND CONFIDENCE PERCENT
                        | CONFIDENCE PERCENT AND  MAX_ERROR PERCENT
;
filters                 : filter ( (AND|OR)   filter)*
                        ;
filter                  : RELATIONAL_OPERATOR compositeExpression
                        | compositeExpression RELATIONAL_OPERATOR compositeExpression
;
number                  : PERCENT |  POSITIVE_INT | FLOAT
;
windowed_parameterized    : key=('PERCENTILE'| 'TOP_K' |'FORECAST' | 'HISTOGRAM' ) LBR number RBR ;
accumulated_parameterized : key=('EWMA'|'PEWMA') LBR number RBR;
mapOp                   : MAP_OPERATION | udfName
;
udfName                 : ID
;
MAP_OPERATION           :  'SQRT' | 'ABS' | 'SQR' | 'GEOHASH' LBR POSITIVE_INT RBR  ;
WINDOWED_FUNCTION       :  'MEAN'  | 'COUNT' | 'SUM' | 'MAX' | 'MIN'
                         | 'SDEV' | 'MODE' | 'MEDIAN' | 'VARIANCE' | 'GEOMETRIC_MEAN' | 'CORRELATION'
;
ACCUMULATED_FUNCTION    :  'RUNNING_COUNT' | 'RUNNING_MEAN' | 'RUNNING_MAX' | 'RUNNING_MIN' | 'RUNNING_SDEV' | 'DIFF' ;
TIME_PERIOD             : 'MILLIS' | 'SECONDS' | 'MINUTES' | 'HOURS' | 'DAYS' | 'MONTHS' ;
INSIGHT                 : 'INSIGHT';
RELATIONAL_OPERATOR     :  GE | GT  | LT  | LE| EQ | NQ | IN;
GE                      : '>=';
GT                      : '>';
LE                      : '<=';
LT                      : '<';
EQ                      : '==';
NQ                      : '!=';
IN                      : 'IN';
BINARY_OPERATOR         :  ADD |  MUL | SUB | DIV ;
ADD                     : 'ADD' | '+';
DIV                     : 'DIV' | '/';
MUL                     : 'MUL' | '*';
SUB                     : 'SUB' | '-';
POSITIVE_INT            : [0-9]+ ;
PERCENT                 : '0'? '.' POSITIVE_INT+
                        | '1' ('.' '0'+ )?
;
FLOAT                   : ('+' | '-') ?  [0-9] + ('.' [0-9] +)? ;
SPECIFIC_TIME           : [0-9]+':'[0-9]+;
ASSIGNMENT : '=';
COMMA : ',';
COLON : ':';
SEMI_COLON : ';';
DOT   :  '.';
LPAR         : '(' ;
RPAR         : ')' ;
LBR          : '[' ;
RBR          : ']' ;
COMPUTE         : 'COMPUTE' ;
EVERY           : 'EVERY' ;
WITH            : 'WITH' ;
AND             : 'AND' | 'and' ;
OR             : 'OR' | 'or' ;
WHEN            : 'WHEN' | 'when' ;
BY              : 'BY' ;
FROM            : 'FROM' ;
SALIENCE        : 'SALIENCE' ;
SAMPLE          : 'SAMPLE' ;
CONFIDENCE      : 'CONFIDENCE' ;
MAX_ERROR       : 'MAX_ERROR' ;
AT              : 'AT' | 'at' ;
ID              : [a-zA-Z_.]+[a-zA-Z_0-9.]*;
REGX            : [a-zA-Z_.*]+[a-zA-Z_0-9.*]*;
COMMENT         : '/*' .*? '*/' -> skip ;
LINE_COMMENT    : '//' ~[\r\n]* -> skip ;
WS              : [ \t\n\r] -> skip ;