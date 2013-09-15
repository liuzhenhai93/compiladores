/*
PROLOGUE
http://www.gnu.org/software/bison/manual/bison.html#Prologue
*/

%{
#include <stdio.h>
#include <stdlib.h>
#include "comp_grammar.h"
#include "comp_dict.h"
#include "comp_tree.h"
#include "iks_ast.h"
//#include "hash_table.h"

%}

/*
DECLARATIONS
*/

/* Declaração dos tokens da gramática da Linguagem K */
%token TK_PR_INT	256		
%token TK_PR_FLOAT	257
%token TK_PR_BOOL	258
%token TK_PR_CHAR	259
%token TK_PR_STRING	260
%token TK_PR_IF		261
%token TK_PR_THEN	262
%token TK_PR_ELSE	263
%token TK_PR_WHILE	264
%token TK_PR_DO		265
%token TK_PR_INPUT	267
%token TK_PR_OUTPUT	268
%token TK_PR_RETURN	269

%token TK_OC_LE		270
%token TK_OC_GE		271
%token TK_OC_EQ		272	
%token TK_OC_NE		273
%token TK_OC_AND	274
%token TK_OC_OR		275

%union {
    comp_grammar_symbol_t *symbol;
    comp_tree_t *nt;
}
%token<symbol> TK_LIT_INT	280
%token<symbol> TK_LIT_FLOAT	281
%token<symbol> TK_LIT_FALSE	282
%token<symbol> TK_LIT_TRUE	283
%token<symbol> TK_LIT_CHAR	284	
%token<symbol> TK_LIT_STRING	285
%token<symbol> TK_IDENTIFICADOR 286

%token TOKEN_ERRO	290

%start prog

/* declaracoes nao sao nodos da arvore? */
%type<nt> prog
%type<nt> func
%type<nt> command_block 
%type<nt> command_seq 
%type<nt> command 
%type<nt> ctrl_flow 
%type<nt> output_list 
%type<nt> expr 
%type<nt> func_param_list
%type<nt> param_list 
%type<nt> terminal_value

%%

/*
GRAMMAR RULES
http://www.gnu.org/software/bison/manual/bison.html#Rules
*/

/* 2 */
prog:
	  prog global_decl
	| prog func
        {
            /* 3.A.1 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_PROGRAMA,NULL);
            comp_tree_set_item(ast,(void*)v);
            // just the first function is child of ast
            if (comp_list_is_empty(ast->children)) {
                iks_ast_append(ast,$func);
            }
            else {
                iks_ast_append((comp_tree_t*)ast->children->prev->item,$func);
            
            }
            $$ = ast;
        }
	| { $$ = NULL; } /* empty */
	;

/* 2.1 */
global_decl:
	  decl ';'
	| array_decl ';'
	;

array_decl:
	  decl '[' TK_LIT_INT ']'
	;

decl:
      type ':' TK_IDENTIFICADOR  
    ;

/*
type_and_id:
	  type ':' TK_IDENTIFICADOR
	;
*/

type:
	  TK_PR_INT
	| TK_PR_FLOAT
	| TK_PR_BOOL
	| TK_PR_CHAR
	| TK_PR_STRING
	;

/* 2.2 */
func:
	  type ':' TK_IDENTIFICADOR '(' func_param_decl_list ')' decl_list command_block
        {
            /* 3.A.2 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_FUNCAO,yylval.symbol);
            comp_tree_set_item($func,(void*)v);
            iks_ast_append($func,$command_block);
            $$ = $func;
        }
	;

func_param_decl_list:
	  param_decl_list
	| /* empty */
	;

param_decl_list:
	  decl ',' param_decl_list
	| decl
	;

decl_list: // pode ser vazia?
	  decl ';' decl_list
    | /* empty */
	;

/* 2.3 */
command_block:
	  '{' command_seq '}'
        {
            $$ = $2;
        }
	;

command_seq:
	  command ';' command_seq
        {
            /* 3.A.10 */
            iks_ast_append($command,$3);
        }
	| command
	| { $$ = NULL; } /* empty */
	;

/* 2.4 */
command:
	  command_block
    | ctrl_flow
	| TK_IDENTIFICADOR '=' expr
        {
            /* 3.A.8 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_ATRIBUICAO,NULL);
            comp_tree_t *atribuicao;
            atribuicao = new_comp_tree();
            comp_tree_set_item(atribuicao,(void*)v);

            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            iks_ast_node_value_set(v1,IKS_AST_IDENTIFICADOR,$1);
            comp_tree_t *identificador;
            identificador = new_comp_tree();
            comp_tree_set_item(identificador,(void*)v1);

            iks_ast_append(atribuicao,identificador);
            iks_ast_append(atribuicao,$3);
            $$ = atribuicao;
                    
        }
    | TK_IDENTIFICADOR '[' expr ']' '=' expr
        {
            /* 3.A.8 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_ATRIBUICAO,NULL);
            comp_tree_t *atribuicao;
            atribuicao = new_comp_tree();
            comp_tree_set_item(atribuicao,(void*)v);

            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            //criar um atributo na tabela de simbolos para o tamanho do array?
            iks_ast_node_value_set(v1,IKS_AST_VETOR_INDEXADO,$1);
            comp_tree_t *identificador;
            identificador = new_comp_tree();
            comp_tree_set_item(identificador,(void*)v1);

            iks_ast_append(atribuicao,identificador);
            iks_ast_append(atribuicao,$3);
            $$ = atribuicao;
        }            
	| TK_PR_OUTPUT output_list
        {
            /* 3.A.7 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_OUTPUT,NULL);
            comp_tree_t *output;
            output = new_comp_tree();
            comp_tree_set_item(output,(void*)v);

            iks_ast_append(output,$2);
            $$ = output;
        }
    | TK_PR_INPUT TK_IDENTIFICADOR
        {
            /* 3.A.6 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_INPUT,NULL);
            comp_tree_t *input;
            input = new_comp_tree();
            comp_tree_set_item(input,(void*)v);

            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            iks_ast_node_value_set(v1,IKS_AST_IDENTIFICADOR,$2);
            comp_tree_t *identificador;
            identificador = new_comp_tree();
            comp_tree_set_item(identificador,(void*)v1);

            iks_ast_append(input,identificador);
            $$ = input;
        }
    | TK_PR_RETURN expr 
        {
            /* 3.A.9 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_RETURN,NULL);
            comp_tree_t *ret;
            ret = new_comp_tree();
            comp_tree_set_item(ret,(void*)v);

            iks_ast_append(ret,$expr);
            $$ = ret;
        }
	| { $$ = NULL; } /* empty */
	;

output_list:
	  expr
	| expr ',' output_list
        {
            iks_ast_append($expr,$3);
        }
	;

/* 2.5 */
expr:
	  TK_IDENTIFICADOR
        {
            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            iks_ast_node_value_set(v1,IKS_AST_LITERAL,$1);
            comp_tree_t *lit;
            lit = new_comp_tree();
            comp_tree_set_item(lit,(void*)v1);
            $$ = lit;
        }
	| TK_IDENTIFICADOR '[' expr ']'
        {
            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            iks_ast_node_value_set(v1,IKS_AST_LITERAL,$1);
            comp_tree_t *lit;
            lit = new_comp_tree();
            comp_tree_set_item(lit,(void*)v1);
            $$ = lit;
        }
	| terminal_value
	| '(' expr ')'
        {
            $$ = $2;
        }
	| expr '+' expr
        {
            /* 3.A.12 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_ARIM_SOMA,NULL);
            comp_tree_t *oo;
            oo = new_comp_tree();
            comp_tree_set_item(oo,(void*)v);

            iks_ast_append(oo,$1);
            iks_ast_append(oo,$3);
            $$ = oo;
        }
	| expr '-' expr
        {
            /* 3.A.12 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_ARIM_SUBTRACAO,NULL);
            comp_tree_t *oo;
            oo = new_comp_tree();
            comp_tree_set_item(oo,(void*)v);

            iks_ast_append(oo,$1);
            iks_ast_append(oo,$3);
            $$ = oo;
        }
	| expr '*' expr
        {
            /* 3.A.12 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_ARIM_MULTIPLICACAO,NULL);
            comp_tree_t *oo;
            oo = new_comp_tree();
            comp_tree_set_item(oo,(void*)v);

            iks_ast_append(oo,$1);
            iks_ast_append(oo,$3);
            $$ = oo;
        }
	| expr '/' expr
        {
            /* 3.A.12 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_ARIM_DIVISAO,NULL);
            comp_tree_t *oo;
            oo = new_comp_tree();
            comp_tree_set_item(oo,(void*)v);

            iks_ast_append(oo,$1);
            iks_ast_append(oo,$3);
            $$ = oo;
        }
	| expr '<' expr
        {
            /* 3.A.14 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_LOGICO_COMP_L,NULL);
            comp_tree_t *oo;
            oo = new_comp_tree();
            comp_tree_set_item(oo,(void*)v);

            iks_ast_append(oo,$1);
            iks_ast_append(oo,$3);
            $$ = oo;
        }
	| expr '>' expr
        {
            /* 3.A.14 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_LOGICO_COMP_G,NULL);
            comp_tree_t *oo;
            oo = new_comp_tree();
            comp_tree_set_item(oo,(void*)v);

            iks_ast_append(oo,$1);
            iks_ast_append(oo,$3);
            $$ = oo;
        }
	| '!' expr
        {
            /* 3.A.15 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_LOGICO_COMP_NEGACAO,NULL);
            comp_tree_t *inv;
            inv = new_comp_tree();
            comp_tree_set_item(inv,(void*)v);

            iks_ast_append(inv,$2);
            $$ = inv;
        }
	| expr TK_OC_LE expr
        {
            /* 3.A.14 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_LOGICO_COMP_LE,NULL);
            comp_tree_t *oo;
            oo = new_comp_tree();
            comp_tree_set_item(oo,(void*)v);

            iks_ast_append(oo,$1);
            iks_ast_append(oo,$3);
            $$ = oo;
        }
	| expr TK_OC_GE expr
        {
            /* 3.A.14 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_LOGICO_COMP_GE,NULL);
            comp_tree_t *oo;
            oo = new_comp_tree();
            comp_tree_set_item(oo,(void*)v);

            iks_ast_append(oo,$1);
            iks_ast_append(oo,$3);
            $$ = oo;
        }
	| expr TK_OC_EQ expr
        {
            /* 3.A.14 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_LOGICO_COMP_IGUAL,NULL);
            comp_tree_t *oo;
            oo = new_comp_tree();
            comp_tree_set_item(oo,(void*)v);

            iks_ast_append(oo,$1);
            iks_ast_append(oo,$3);
            $$ = oo;
        }
	| expr TK_OC_NE expr
        {
            /* 3.A.14 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_LOGICO_COMP_DIF,NULL);
            comp_tree_t *oo;
            oo = new_comp_tree();
            comp_tree_set_item(oo,(void*)v);

            iks_ast_append(oo,$1);
            iks_ast_append(oo,$3);
            $$ = oo;
        }
	| expr TK_OC_AND expr
        {
            /* 3.A.14 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_LOGICO_E,NULL);
            comp_tree_t *oo;
            oo = new_comp_tree();
            comp_tree_set_item(oo,(void*)v);

            iks_ast_append(oo,$1);
            iks_ast_append(oo,$3);
            $$ = oo;
        }
	| expr TK_OC_OR expr
        {
            /* 3.A.14 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_LOGICO_OU,NULL);
            comp_tree_t *oo;
            oo = new_comp_tree();
            comp_tree_set_item(oo,(void*)v);

            iks_ast_append(oo,$1);
            iks_ast_append(oo,$3);
            $$ = oo;
        }
	| '*' TK_IDENTIFICADOR //essa expr existe?
	| '&' TK_IDENTIFICADOR //essa expr existe?
	| TK_IDENTIFICADOR '(' func_param_list ')'
        {
            /* 3.A.17 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_CHAMADA_DE_FUNCAO,NULL);
            comp_tree_t *x;
            x = new_comp_tree();
            comp_tree_set_item(x,(void*)v);

            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            iks_ast_node_value_set(v1,IKS_AST_IDENTIFICADOR,$1);
            comp_tree_t *identificador;
            identificador = new_comp_tree();
            comp_tree_set_item(identificador,(void*)v1);

            iks_ast_append(x,identificador);
            iks_ast_append(x,$3);
            $$ = x;
                    
        }
	;

terminal_value:
        /* 3.A.11 */
	  TK_LIT_INT
        {
            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            iks_ast_node_value_set(v1,IKS_AST_LITERAL,$1);
            comp_tree_t *lit;
            lit = new_comp_tree();
            comp_tree_set_item(lit,(void*)v1);
            $$ = lit;
        }
	| '-' TK_LIT_INT
        {
            /* 3.A.13 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_ARIM_INVERSAO,NULL);
            comp_tree_t *inv;
            inv = new_comp_tree();
            comp_tree_set_item(inv,(void*)v);

            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            iks_ast_node_value_set(v1,IKS_AST_LITERAL,$2);
            comp_tree_t *lit;
            lit = new_comp_tree();
            comp_tree_set_item(lit,(void*)v1);
            
            iks_ast_append(inv,lit);
            $$ = inv;
        }
	| TK_LIT_FLOAT
        {
            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            iks_ast_node_value_set(v1,IKS_AST_LITERAL,$1);
            comp_tree_t *lit;
            lit = new_comp_tree();
            comp_tree_set_item(lit,(void*)v1);
            $$ = lit;
        }
	| '-' TK_LIT_FLOAT
        {
            /* 3.A.13 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_ARIM_INVERSAO,NULL);
            comp_tree_t *inv;
            inv = new_comp_tree();
            comp_tree_set_item(inv,(void*)v);

            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            iks_ast_node_value_set(v1,IKS_AST_LITERAL,$2);
            comp_tree_t *lit;
            lit = new_comp_tree();
            comp_tree_set_item(lit,(void*)v1);
            
            iks_ast_append(inv,lit);
            $$ = inv;
        }
	| TK_LIT_FALSE
        {
            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            iks_ast_node_value_set(v1,IKS_AST_LITERAL,$1);
            comp_tree_t *lit;
            lit = new_comp_tree();
            comp_tree_set_item(lit,(void*)v1);
            $$ = lit;
        }
	| TK_LIT_TRUE
        {
            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            iks_ast_node_value_set(v1,IKS_AST_LITERAL,$1);
            comp_tree_t *lit;
            lit = new_comp_tree();
            comp_tree_set_item(lit,(void*)v1);
            $$ = lit;
        }
	| TK_LIT_CHAR
        {
            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            iks_ast_node_value_set(v1,IKS_AST_LITERAL,$1);
            comp_tree_t *lit;
            lit = new_comp_tree();
            comp_tree_set_item(lit,(void*)v1);
            $$ = lit;
        }
	| TK_LIT_STRING
        {
            iks_ast_node_value_t *v1;
            v1 = new_iks_ast_node_value();
            iks_ast_node_value_set(v1,IKS_AST_LITERAL,$1);
            comp_tree_t *lit;
            lit = new_comp_tree();
            comp_tree_set_item(lit,(void*)v1);
            $$ = lit;
        }
	;
	
func_param_list:
	  param_list
	| { $$ = NULL; } /* empty */
	;

param_list:
	  expr
	| expr ',' param_list
	;

/* 2.6 */
ctrl_flow:
      TK_PR_IF '(' expr ')' TK_PR_THEN command
        {
            /* 3.A.3 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_IF_ELSE,NULL);
            comp_tree_t *if_else;
            if_else = new_comp_tree();
            comp_tree_set_item(if_else,(void*)v);

            iks_ast_append(if_else,$expr);
            iks_ast_append(if_else,$command);
            $$ = if_else;
        }
	| TK_PR_IF '(' expr ')' TK_PR_THEN command TK_PR_ELSE command
        {
            /* 3.A.3 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_IF_ELSE,NULL);
            comp_tree_t *if_else;
            if_else = new_comp_tree();
            comp_tree_set_item(if_else,(void*)v);

            iks_ast_append(if_else,$expr);
            iks_ast_append(if_else,$6);
            iks_ast_append(if_else,$8);
            $$ = if_else;
        }
	| TK_PR_WHILE '(' expr ')' TK_PR_DO command
        {
            /* 3.A.5 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_WHILE_DO,NULL);
            comp_tree_t *while_do;
            while_do = new_comp_tree();
            comp_tree_set_item(while_do,(void*)v);

            iks_ast_append(while_do,$expr);
            iks_ast_append(while_do,$command);
            $$ = while_do;
        }
    | TK_PR_DO command TK_PR_WHILE '(' expr ')' 
        {
            /* 3.A.4 */
            iks_ast_node_value_t *v;
            v = new_iks_ast_node_value();
            iks_ast_node_value_set(v,IKS_AST_DO_WHILE,NULL);
            comp_tree_t *do_while;
            do_while = new_comp_tree();
            comp_tree_set_item(do_while,(void*)v);

            iks_ast_append(do_while,$command);
            iks_ast_append(do_while,$expr);
            $$ = do_while;
        }
	;

%%

/*
void yyerror(char* str)
{
	fflush(stderr);
	fprintf(stderr, "ERRO: \"%s\"\t Linha: %d token: %s\n", str, yy_line_number_get(), yy_last_token_identifier_get());
	exit(RS_ERRO);
}
*/	