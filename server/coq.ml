open Utils;;
open Prover;;

(* let print str = Printexc.print (fun e -> e) str;; *)

let match_unallowed s =
  let nok = Pcre.pmatch ~rex:(Pcre.regexp "\\bQuit.|\\bDebug|\\bBackTo|\\bSuspend|\\bResume") s in
  let unok = Pcre.pmatch ~rex:(Pcre.regexp "\\bUndo|") s in
  let uok = Pcre.pmatch ~rex:(Pcre.regexp "\\bSet\\bUndo|") s in
  nok || (unok && (not uok))
;;

let parse_prompt str =
  try
    let lst = string_list_of_string str '<' in
    let lst2 = string_list_of_string (List.hd (List.tl lst)) '|' in
    let global = int_of_string_space (List.hd lst2) in
    let local = int_of_string_space (List.hd (List.rev lst2)) in
    let current = List.hd lst in
    let rest = List.tl (List.rev (List.tl lst2)) in
    (global, local, current, rest)
  with e -> failwith ("parse_prompt: [" ^  str ^ "] failed! \n"
              ^ (Printexc.to_string e))
;;

let rec listmatch (g,l,c,r) p lst =
  match lst with
  | [] -> failwith "Unable to find undo state"
  | ((hg, hl, hc, hr), hp) :: t ->
(*Printf.printf "(%i,%i,%s,%i) (%i,%i,%s,%i) %i\n%!" g l c (List.length r) hg hl hc (List.length hr) hp;*)
      if hp > p then listmatch (g,l,c,r) p t else
      if hl = 0 && l = 0 && hg <= g && containslist r hr then
        hp, (Printf.sprintf "Backtrack %i 0 0." hg), lst else
      if l > 0 && hr = r && hl <= l then
        hp, (Printf.sprintf "Backtrack %i %i 0." hg hl), lst else
      if l > 0 && hr <> r && containslist r hr then
        hp, (Printf.sprintf "Backtrack %i %i %i." hg hl ((List.length r) - (List.length hr))), lst
      else listmatch (g,l,c,r) p t
;;

let clean_string s =
  let pos = ref 0 in
  String.iter (fun c -> (if Char.code c > 127 then s.[!pos] <- ' '); incr pos) s
;;

let new_coq coq user =
  let prover = Prover.new_prover (coq ^ " -emacs") user (String.make 1 (Char.chr 249)) in
  let send_lst = ref [] in
  let cur_no = ref (1, 0, "", []) in
  let cur_pos, cur_dest = ref 0, ref 0 in
  let what = ref "" in
  let csend s a e =
(* if !cur_pos != s then failwith "Coq.send curpos <> start"; *)
    let a = remove_ml_comment a in
    if match_unallowed a then begin
      send_lst := (!cur_no, s) :: !send_lst;
      prover.send s "This command is not allowed." e
    end else begin
      cur_dest := e;
      what := a;
      let a = if a = "Dump Natural Deduction" || a = "Dump Fitch Deduction" || a = "Dump Gentzen Deduction" then "Dump Tree." else a in
      send_lst := (!cur_no, s) :: !send_lst;
(*      log "Csend: [%s]\n%!" a;*)
      prover.send s a e
    end
  in
  let cundo s =
    let (dest, s, nl) = listmatch !cur_no s !send_lst in
(*    Printf.printf "Cundo: len: %i\n%!" (List.length !send_lst);*)
    send_lst := nl;
    cur_dest := dest;
    (s, dest)
  in
  let rec ccheck () =
    match prover.check () with
    | None -> None
    | Some (o, e, p, err) ->
        clean_string o;
	clean_string e;
        let ret = string_list_of_string e '\n' in
        let (nglobal, nlocal, ncurrent, nrest) = parse_prompt (List.hd (List.rev ret)) in
        if o = "User error: Unknown state number\n" then begin
          send_lst := List.tl !send_lst;
          let to_send, pos = cundo (!cur_dest - 1) in
          csend (-1) to_send pos;
          ccheck ()
        end else begin
          let o, err = try
            match !what with
            | "Dump Natural Deduction" ->
                let xml = Xml.parse_string o in
                let coqtree = Coqtree.parse_tree xml in
                let o = Coqtree.print_natural coqtree in
                o, false
            | "Dump Fitch Deduction" ->
                let xml = Xml.parse_string o in
                let coqtree = Coqtree.parse_tree xml in
                let o = Coqtree.print_fitch coqtree in
                o, false
            | "Dump Gentzen Deduction" ->
                let xml = Xml.parse_string o in
                let coqtree = Coqtree.parse_tree xml in
                let o = Coqtree.print_gentzen coqtree in
                o, false
            | _ -> o, err
          with _ -> "", false in (* Error in XML trees is because not in proof *)
          if err then begin
            cur_dest := !cur_pos;
            send_lst := List.tl !send_lst;
          end;
(*        Printf.printf "Cchk: len: %i\n%!" (List.length !send_lst);*)
          if !cur_dest < !cur_pos then begin
(*          Printf.printf "  d%i p%i\n%!" !cur_dest !cur_pos;*)
            send_lst := List.filter (fun (a, b) -> b < !cur_dest && b >= 0) !send_lst;
(*          Printf.printf "Cch!: len: %i\n%!" (List.length !send_lst);*)
          end;
          cur_pos := !cur_dest;
          cur_no := (nglobal, nlocal, ncurrent, nrest);
          let e = String.concat "\n" (List.tl (List.rev ret)) in
          Some (o, e, !cur_pos, err)
        end
  in
  {prover with send = csend; check = ccheck; undo = cundo}
;;
