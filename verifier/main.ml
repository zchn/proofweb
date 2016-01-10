if Array.length Sys.argv < 2 then failwith "Filename required";;
(* Fixme: assumes that name is "files/.../login/file" *)
let f = Sys.argv.(1);;
let slash = String.rindex f '/';;
let file = String.sub f (slash + 1) (String.length f - slash - 1);;
let dir = String.sub f 0 slash;;
let slash = String.rindex dir '/';;
let top = String.sub dir 6 (slash - 6);;

let inf = open_in f;;
let int = open_in ("tasks/" ^ top ^ "/" ^ file);;

let lexf = Lexing.from_channel inf;;
let lext = Lexing.from_channel int;;

let linef = ref 0;;
let linet = ref 0;;

open Lexer;;

let readf () = file := "f"; lex lexf;;
let readt () = file := "t"; lex lext;;

let rec print_line = function
  | (Word w) :: t -> print_string w; print_char ' '; print_line t
  | (Place w) :: t -> print_string w; print_char ' '; print_line t
  | _ -> print_newline (); flush stdout 
;;

(* FOR DEBUG *)
let dbg s = ();; (*print_endline ("   dbg: " ^ s); flush stdout;;*)

let rec read_rest reader =
  match reader () with
  | Word w -> dbg w; (Word w) :: (read_rest reader)
  | Semi -> []
  | Dot -> []
  | Place "term" -> (Place "term") :: (read_rest reader)
  | Place x -> failwith ("read_rest "^ !file ^": unknown placeholder: " ^ x)
  | Eof -> failwith "read_rest: Eof"
;;

let read_line reader =
  match reader () with
  | Place "proof" -> [Place "proof"]
  | Place "classical_proof" -> [Place "classical_proof"]
  | Place "constructive_proof" -> [Place "constructive_proof"]
  | Place "prop_proof" -> [Place "prop_proof"]
  | Place "pred_proof" -> [Place "pred_proof"]
  | Place x -> failwith ("read_line "^ !file ^": unknown placeholder: " ^ x)
  | Word w -> dbg w; (Word w) :: (read_rest reader)
  | Eof -> [Eof]
  | Semi -> failwith "read_line: Semi"
  | Dot -> failwith "read_line: Dot"
;;

let ignored_tacs = ["Check"; "Print"; "Eval"];;
let general_tacs = ["Focus"; "Unfocus"; "SearchAbout"];;
let allowed_tacs_tt = [
  "intro"; "intros"; "apply"; "exact"; "unfold"; "fold"; "elim";
  "split"; "left"; "right"; "assumption"; "simpl"; "elimtype";
  "inversion"; "induction"; "exists"; "reflexivity"; "absurd";
  "inversion_clear"; "clear"; "constructor"; "rewrite";
  "assert"; "destruct"; "replace"; "symmetry"
] @ general_tacs;;

let allowed_tacs_bb = ["con_in"; "con_ell"; "con_elr"; "dis_inl"; "dis_inr"; "dis_el"; 
  "imp_in"; "imp_el"; "equ_in"; "equ_el"; "neg_in"; "neg_el"; "efq"; "ass"; "neg_els";
  "tnd_axiom"; "dn"; "dn_axiom"; "all_in"; "all_el"; "exi_in"; "exi_el"; "equ_eli"; 
   "rewrite"] @ general_tacs
;;

let allowed_tacs_co = ["con_in"; "con_ell"; "con_elr"; "dis_inl"; "dis_inr";
  "dis_el"; "imp_in"; "imp_el"; "equ_in"; "equ_el"; "neg_in"; "neg_el"; "efq"; "ass"; "all_in";
  "all_el"; "exi_in"; "exi_el"; "equ_eli"] @ general_tacs
;;

let allowed_tacs_po = ["ass"; "copy"; "exact"; "insert"; "con_i"; "con_e1"; "con_e2"; "dis_i1"; "dis_i2"; "dis_e"; "imp_i"; "imp_e"; "neg_i"; "neg_e"; "fls_e"; "tru_i"; "negneg_i"; "negneg_e"; "LEM"; "PBC"; "MT"; "b_con_i"; "b_con_e1"; "b_con_e2"; "b_dis_i1"; "b_dis_i2"; "b_dis_e"; "b_imp_i"; "b_imp_e"; "b_neg_i"; "b_neg_e"; "b_fls_e"; "b_tru_i"; "b_negneg_i"; "b_negneg_e"; "b_LEM"; "b_PBC"; "b_MT"; "f_con_i"; "f_con_e1"; "f_con_e2"; "f_dis_i1"; "f_dis_i2"; "f_imp_e"; "f_neg_e"; "f_fls_e"; "f_tru_i"; "f_negneg_i"; "f_negneg_e"; "f_LEM"; "f_MT"; "f_dis_e"; "f_exi_e"];;

let allowed_tacs_pe = ["all_i"; "all_e"; "exi_i"; "exi_e"; "equ_i"; "equ_e"; "equ_e'"; "b_all_i"; "b_all_e"; "b_exi_i"; "b_exi_e"; "b_equ_i"; "b_equ_e"; "b_equ_e'"; "f_all_e"; "f_exi_i"; "f_equ_i"; "f_equ_e"] @ allowed_tacs_po;;

let allowed_tacs = ref [];;
let hyps = ref [];;

let rec read_proof () =
  let rec read_proof_aux = function
    | Place _ :: t -> read_proof_aux t
    | [Word "Proof"] -> print_endline "+Proof"; read_proof ()
    | [Word "Qed"] -> print_endline "+Qed"; ()
    | (Word x :: (_ as l)) -> 
        if List.mem x !allowed_tacs then (print_char '+'; print_line l; read_proof ())
        else 
          if x = "apply" then match l with
          | Word h :: _ -> if List.mem h !hyps then read_proof () else failwith ("Read proof: unallowed apply: " ^ h)
          | _ -> failwith "Read proof: empty apply"
          else failwith ("Read proof: unallowed word: [" ^ x ^ "]")
    | Semi :: _ -> failwith "read_proof: semi"
    | Dot :: _ -> failwith "read_proof: dot"
    | Eof :: _ -> failwith "read_proof: eof"
    | [] -> read_proof ()
  in
  let l = read_line readf in
  read_proof_aux l
;;

let rec find_max_sequence acc = function
  | (Word w) :: t -> find_max_sequence ((Word w) :: acc) t
  | (((Place "term") :: t) as l) -> (List.rev acc), l
  | [] -> (List.rev acc), []
  | _ -> failwith "find_max_sequence"
;;

let rec includes_seq = function
  | (x::xt, y::yt) -> if x = y then includes_seq (xt, yt) else None
  | x, [] -> Some x
  | [], y :: yt -> None
;;

let rec find_sequence seq = function
  | h :: t ->
      begin match includes_seq ((h :: t), seq) with
      | None -> find_sequence seq t
      | Some x -> x
      end
  | [] -> failwith "find_sequence: not_found"
;; 

let rec compare_line_rest = function
  | (((Word w1)::t1), ((Word w2)::t2)) -> 
      if w1 <> w2 then failwith ("compare_line_rest [" ^ w1 ^ "]<>[" ^ w2 ^ "]")
      else compare_line_rest (t1, t2)
  | ([], []) -> ()
  | ((((Place "term") :: t1) as l1), l2) -> 
      begin match List.nth l1 ((List.length l1) - 1) with
      | Word _ -> compare_line_rest (List.rev l1, List.rev l2)
      | _ -> 
          (print_char '-'; print_line l1; print_char '+'; print_line l2;);
          let (seq, new_l1) = find_max_sequence [] t1 in
          (print_char 's'; print_line seq; print_char '='; print_line new_l1;);

          if seq = [] then () else
          let new_l2 = find_sequence seq l2 in
          compare_line_rest (new_l1, new_l2)
      end
  | ((Place x :: _), _) -> failwith "compare_line_rest: unknown placeholder"
  | _ -> failwith "compare_line_rest"
;;

let rec compare_line = function
  | (((Word w1)::t1 as l1), (((Word w2)::t2) as l2)) -> 
      if w1 <> w2 then 
        if w2 = "Check" || w2 = "Print" || w2 = "Eval" then compare_line (l1, (read_line readf))
        else failwith ("compare_line [" ^ w1 ^ "]<>[" ^ w2 ^ "]")
      else begin
        if t1 = t2 then (print_char ' '; print_line l1)
        else (print_char '-'; print_line l1; print_char '+'; print_line l2; compare_line_rest (t1, t2); )
      end
  | ([], []) -> ()
  | ([Word s], _) -> failwith ("compare_line: " ^ s)
  | (l1, l2) -> failwith ("compare_line: " ^ (string_of_int (List.length l1)) ^ " " ^ (string_of_int (List.length l2)))
;;

let remove_qed () =
  if read_line readt <> [Word "Qed"] then failwith "remove_qed" else ()
;;

let rec compare () =
  let l = read_line readt in
  match l with
  | [Place "proof"] -> 
      allowed_tacs := allowed_tacs_tt; print_endline "-(*! proof *)"; read_proof ();  remove_qed (); compare ()
  | [Place "classical_proof"] -> 
      allowed_tacs := allowed_tacs_bb; print_endline "-(*! cl_proof *)"; read_proof (); remove_qed (); compare ()
  | [Place "constructive_proof"] -> 
      allowed_tacs := allowed_tacs_co; print_endline "-(*! co_proof *)"; read_proof (); remove_qed (); compare ()
  | [Place "prop_proof"] -> 
      allowed_tacs := allowed_tacs_po; print_endline "-(*! po_proof *)"; read_proof (); remove_qed (); compare ()
  | [Place "pred_proof"] -> 
      allowed_tacs := allowed_tacs_pe; print_endline "-(*! pe_proof *)"; read_proof (); remove_qed (); compare ()
  | [Eof] -> if read_line readf <> [Eof] then failwith "compare: Eof" else ()
  | x -> 
      begin match x with
      | (Word "Hypothesis") :: (Word h) :: _ -> print_endline ("*Hyp : " ^ h); hyps := h :: !hyps
      | _ -> ()
      end;
      compare_line (x, (read_line readf)); compare ()
;;


try 
  compare () 
with Failure x -> 
  let t = try Hashtbl.find line "t" with _ -> -1 
  and f = try Hashtbl.find line "f" with _ -> -1 in
  failwith (Printf.sprintf "[t:%i,f:%i] %s]" t f x)
;;
