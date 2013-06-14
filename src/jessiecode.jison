/* -- JavaScript code -- */
%{

    this.createNode = function (type, value, children) {
        var n = this.node(type, value, []),
            i;

        for (i = 2; i < arguments.length; i++) {
            n.children.push(arguments[i]);
        }

        n.line = this.parCurLine;
        n.col = this.parCurColumn;

        return n;
    };

    this.execute = function (node) {
        console.log('execute', node);
    };

%}

/* ----------------------------------------------------------------- */
/*  Grammar definition of JessieCode                                 */
/* ----------------------------------------------------------------- */
/*                                                                   */
/* Copyright 2011-2013                                               */
/*   Michael Gerhaeuser,                                             */
/*   Alfred Wassermann                                               */
/*                                                                   */
/* JessieCode is free software dual licensed under the GNU LGPL or   */
/* MIT License.                                                      */
/*                                                                   */
/* You can redistribute it and/or modify it under the terms of the   */
/*                                                                   */
/*  * GNU Lesser General Public License as published by              */
/*    the Free Software Foundation, either version 3 of the License, */
/*    or (at your option) any later version                          */
/*  OR                                                               */
/*  * MIT License:                                                   */
/*    https://github.com/jsxgraph/jsxgraph/blob/master/LICENSE.MIT   */
/*                                                                   */
/* JessieCode is distributed in the hope that it will be useful,     */
/* but WITHOUT ANY WARRANTY; without even the implied warranty of    */
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the     */
/* GNU Lesser General Public License for more details.               */
/*                                                                   */
/* You should have received a copy of the GNU Lesser General Public  */
/* License and the MIT License along with JessieCode. If not, see    */
/* <http://www.gnu.org/licenses/> and                                */
/* <http://opensource.org/licenses/MIT/>.                            */
/*                                                                   */
/* ----------------------------------------------------------------- */

%lex
%%

    \s+                                 /* ignore */
    [A-Za-z_\$][A-Za-z0-9_]*\b          return 'IDENTIFIER';
    [0-9]+\.[0-9]*|[0-9]*\.[0-9]+\b     return 'NUMBER';


    %x string
    %%

    "'"                                 this.begin('string');
    <string>\''                         this.popState();
    <string>(\\\'|[^'])*                { return 'STRING'; }

    %x comment
    %%

    "//"                                this.begin('comment');
    <comment>"\n"                       this.popState();
    <comment>[^\n]*                     /* ignore */


    "IF"                                return 'IF';
    "ELSE"                              return 'ELSE';
    "WHILE"                             return 'WHILE';
    "DO"                                return 'DO';
    "FOR"                               return 'FOR';
    "FUNCTION"                          return 'FUNCTION';
    "USE"                               return 'USE';
    "RETURN"                            return 'RETURN';
    "DELETE"                            return 'DELETE';
    "TRUE"                              return 'TRUE';
    "FALSE"                             return 'FALSE';
    "<<"                                return '<<';
    ">>"                                return '>>';
    "{"                                 return '{';
    "}"                                 return '}';
    ";"                                 return ';';
    "#"                                 return '#';
    "?"                                 return '?';
    ":"                                 return ':';
    "NaN"                               return 'NAN';
    "."                                 return '.';
    "["                                 return '[';
    "]"                                 return ']';
    "("                                 return '(';
    ")"                                 return ')';
    "!"                                 return '!';
    "^"                                 return '^';
    "*"                                 return '*';
    "/"                                 return '/';
    "%"                                 return '%';
    "+"                                 return '+';
    "-"                                 return '-';
    "<="                                return '<=';
    "<"                                 return '<';
    ">="                                return '>=';
    ">"                                 return '>';
    "=="                                return '==';
    "~="                                return '~=';
    "!="                                return '!=';
    "&&"                                return '&&';
    "||"                                return '||';
    "="                                 return '=';
    ","                                 return ',';

    <<EOF>>

/lex

/* operator association and precedence */

%left ','               /* comma */
%right '='              /* assignment */
%left '||'              /* logical or */
%left '&&'              /* logical and */
%left '==' '~=' '!='    /* equality */
%left '<=' '<' '>=' '>' /* relational */
%left '+' '-'           /* addition arithmetic */
%left '*' '/' '%'       /* multiplication arithmetic */
%left NEG               /* unary minus */
%right '^'              /* exponentiation */
%right '!'              /* unary logical */
%left '(' ')'           /* function call */
%left '.' '[' ']'       /* member access */


%start Program
%%

/* language grammar */

Program:  Program Stmt                                                       { this.execute($2); }
        |
        ;

Stmt_List:     Stmt_List Stmt                                                { $$ = this.createNode('node_op', 'op_none', $1, $2); }
        |
        ;

Param_List:    Param_List ',' Expression                                     { $$ = this.createNode('node_op', 'op_param', $3, $1); }
        | Expression                                                         { $$ = this.createNode('node_op', 'op_param', $1); }
        |
        ;

Prop_List:     Prop_List ',' Prop                                            { $$ = this.createNode('node_op', 'op_proplst', $1, $3); }
        | Prop
        |
        ;

Prop:          Identifier ':' Expression                                     { $$ = this.createNode('node_op', 'op_prop', $1, $3); }
        ;

Param_Def_List:Param_Def_List ',' Identifier                                 { $$ = this.createNode('node_op', 'op_paramdef', $3, $1); }
        | Identifier                                                         { $$ = this.createNode('node_op', 'op_paramdef', $1); }
        |
        ;

Attr_List:    Attr_List ',' ExtValue                                         { $$ = this.createNode('node_op', 'op_param', $3, $1); }
        | ExtValue                                                           { $$ = this.createNode('node_op', 'op_param', $1); }
        ;

Assign:       Lhs '=' Expression                                             { $$ = this.createNode('node_op', 'op_assign', $1, $3); }
        ;

Stmt:          IF Expression Stmt                                            { $$ = this.createNode('node_op', 'op_if', $2, $3); }
        | IF Expression Stmt ELSE Stmt                                       { $$ = this.createNode('node_op', 'op_if_else', $2, $3, $5); }
        | WHILE Expression Stmt                                              { $$ = this.createNode('node_op', 'op_while', $2, $3); }
        | DO Stmt WHILE Expression ';'                                       { $$ = this.createNode('node_op', 'op_do', $2, $4); }
        | FOR '(' Assign ';' Expression ';' Assign ')' Stmt                  { $$ = this.createNode('node_op', 'op_for', $3, $5, $7, $9); }
        | USE Identifier ';'                                                 { $$ = this.createNode('node_op', 'op_use', $2); }
        | DELETE Identifier                                                  { $$ = this.createNode('node_op', 'op_delete', $2); }
        | RETURN Stmt                                                        { $$ = this.createNode('node_op', 'op_return', $2); }
        | Assign ';'
        | Expression ';'                                                     { $$ = this.createNode('node_op', 'op_noassign', $1); }
        | '{' Stmt_List '}'                                                  { $$ = $2;
                    $$.needsBrackets = true; }
        | ';'                                                                { $$ = this.createNode('node_op', 'op_none'); }
        ;

Lhs:          ExtValue '.' Identifier                                        { $$ = this.createNode('node_op', 'op_lhs', $3, $1, 'dot'); }
        | ExtValue '[' AddSubExp ']'                                         { $$ = this.createNode('node_op', 'op_lhs', $3, $1, 'bracket'); }
        | Identifier                                                         { $$ = this.createNode('node_op', 'op_lhs', $1); }
        ;

Expression:       LogExp '||' CmpExp                                         { $$ = this.createNode('node_op', 'op_or', $1, $3); }
        | LogExp '&&' CmpExp                                                 { $$ = this.createNode('node_op', 'op_and', $1, $3); }
        | '!' LogExp                                                         { $$ = this.createNode('node_op', 'op_not', $2); }
        | CmpExp
        ;

CmpExp:    CmpExp '==' AddSubExp                                             { $$ = this.createNode('node_op', 'op_equ', $1, $3); }
        | CmpExp '<' AddSubExp                                               { $$ = this.createNode('node_op', 'op_lot', $1, $3); }
        | CmpExp '>' AddSubExp                                               { $$ = this.createNode('node_op', 'op_grt', $1, $3); }
        | CmpExp '<=' AddSubExp                                              { $$ = this.createNode('node_op', 'op_loe', $1, $3); }
        | CmpExp '>=' AddSubExp                                              { $$ = this.createNode('node_op', 'op_gre', $1, $3); }
        | CmpExp '!=' AddSubExp                                              { $$ = this.createNode('node_op', 'op_neq', $1, $3); }
        | CmpExp '~=' AddSubExp                                              { $$ = this.createNode('node_op', 'op_approx', $1, $3); }
        | CmpExp '?' Value ':' Value                                         { $$ = this.createNode('node_op', 'op_conditional', $1, $3, $5); }
        | AddSubExp
        ;

AddSubExp:    AddSubExp '-' MulDivExp                                        { $$ = this.createNode('node_op', 'op_sub', $1, $3); }
        | AddSubExp '+' MulDivExp                                            { $$ = this.createNode('node_op', 'op_add', $1, $3); }
        | MulDivExp
        ;

MulDivExp:    MulDivExp '*' NegExp                                           { $$ = this.createNode('node_op', 'op_mul', $1, $3); }
        | MulDivExp '/' NegExp                                               { $$ = this.createNode('node_op', 'op_div', $1, $3); }
        | MulDivExp '%' NegExp                                               { $$ = this.createNode('node_op', 'op_mod', $1, $3); }
        | NegExp
        ;

ExpExp:      ExtValue '^' ExpExp                                             { $$ = this.createNode('node_op', 'op_exp', $1, $3); }
        | ExtValue
        ;

NegExp:        '-' ExpExp    %prec NEG                                       { $$ = this.createNode('node_op', 'op_neg', $2); }
        | '+' ExpExp         %prec NEG                                       { $$ = $2; }
        | ExpExp
        ;

ExtVWPL:       ExtValue '(' Param_List ')'                                        { $$ = this.createNode('node_op', 'op_execfun', $1, $3); }
        ;

ExtValue:      ExtValue '[' AddSubExp ']'                                    { $$ = this.createNode('node_op', 'op_extvalue', $1, $3); }
        | ExtVWPL '[' AddSubExp ']'                      { $$ = this.createNode('node_op', 'op_extvalue', $1, $3); }
        | ExtVWPL                                        { $$ = this.createNode('node_op', 'op_execfun', $1, $3); }
        | ExtVWPL Attr_List                              { $$ = this.createNode('node_op', 'op_execfunw_al', $1); }
        | ExtValue '.' Identifier                                            { $$ = this.createNode('node_op', 'op_property', $1, $3); }
        | Value
        ;

Value:        NUMBER                                                         { $$ = this.createNode('node_const', $1); }
        | IDENTIFIER                                                         { $$ = this.createNode('node_var', $1); }
        | '(' Expression ')'                                                 { $$ = $2; }
        | STRING                                                             { $$ = this.createNode('node_str', $1); }
        | FUNCTION '(' Param_Def_List ')' '{' Stmt_List '}'                  { $$ = this.createNode('node_op', 'op_function', $3, $6); }
        | '<<' Prop_List '>>'                                                { $$ = this.createNode('node_op', 'op_proplst_val', $2); }
        | '[' Param_List ']'                                                 { $$ = this.createNode('node_op', 'op_array', $2); }
        | TRUE                                                               { $$ = this.createNode('node_const_bool', $1); }
        | FALSE                                                              { $$ = this.createNode('node_const_bool', $1); }
        | NAN                                                                { $$ = this.createNode('node_const', NaN); }
        ;


