{
  let depth = ref 0;; 
  open Lexing;;
  type t = Eof | Dot | Semi | Word of string | Place of string
  let line = Hashtbl.create 5;;
  let file = ref "";;
  let incrl () =
    Hashtbl.replace line !file (try Hashtbl.find line !file + 1 with _ -> 1)
  ;;
}

let skip = [' ' '\t' '\r']+
let nl = ['\n']
let letter = ['a'-'z' 'A'-'Z']
let digit = ['0'-'9']
let sign = letter | digit | '_' | '\''
let symbol = ['+' '-' '*' '/' '(' '[' '{' '}' ']' ')' '=' '>' '<' ',' ':' '~' '\\' '?' '|']

rule lex = parse
| skip            {lex lexbuf}
| nl              {incrl (); lex lexbuf}
| '.'             {Dot}
| ';'             {Semi}
| '('             {Word "("}
| ')'             {Word ")"}
| "(*!"           {place "" lexbuf}
| "(*"            {incr depth; comment lexbuf}
| "\""            {string lexbuf}

| sign+ as id     {Word id}
| symbol+ as id   {Word id}
| eof             {Eof}
| _               {failwith ("Unable to lex: [" ^ (lexeme lexbuf) ^ "]")}

and comment = parse
| nl             {incrl (); comment lexbuf}
| "*)"           {decr depth; if !depth = 0 then lex lexbuf else comment lexbuf}
| "(*"           {incr depth; comment lexbuf}
| eof            {raise End_of_file}
| _              {comment lexbuf}

and place s = parse
| "*)"           {Place s}
| skip           {place s lexbuf}
| nl             {incrl (); place s lexbuf}
| eof            {raise End_of_file}
| _              {place (s ^ (lexeme lexbuf)) lexbuf}

and string = parse
| [^ '\"']* "\"" {Word ("\"" ^ (lexeme lexbuf))}

{
}
