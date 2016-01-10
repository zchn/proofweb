open Prover;;
open Utils;;

let match_diag = list_begin_matcher ["ML"; "ML_command"; "cd"; "commit";
  "disable_pr"; "display_drafts"; "enable_pr"; "find_theorems"; "full_prf";
  "header"; "kill_thy"; "pr"; "pretty_setmargin"; "prf";
  "print_antiquotations"; "print_attributes"; "print_binds"; "print_cases";
  "print_claset"; "print_commands"; "print_context"; "print_drafts";
  "print_facts"; "print_induct_rules"; "print_interps"; "print_locale";
  "print_locales"; "print_methods"; "print_rules"; "print_simpset";
  "print_syntax"; "print_theorems"; "print_theory"; "print_trans_rules";
  "prop"; "pwd"; "quickcheck"; "refute"; "remove_thy"; "term"; "thm";
  "thm_deps"; "touch_all_thys"; "touch_child_thys"; "touch_thy"; "typ";
  "update_thy"; "update_thy_only"; "use"; "use_thy"; "use_thy_only"; "value";
  "welcome" ];;

let match_error = 
  let rex = Pcre.regexp ".*errorresponse.*" in 
  let rexwarn = Pcre.regexp ".*errorresponse fatality = \"warning\".*" in
  fun s -> ((Pcre.pmatch ~rex s) && (not (Pcre.pmatch ~rex:rexwarn s)))
;;

(*list_begin_matcher ["\244"; "\\*\\*\\*"; "Error"; "uncaught exception "; "Exception-"];;*)

let match_goal = list_begin_matcher ["have"; "hence"; "interpret"; "show";
  "thus"; "obtain"; "ax_specification"; "corollary"; "cpodef"; "instance";
  "interpretation"; "lemma"; "pcpodef"; "recdef_tc"; "specification";
  "theorem"; "typedef"];;

let match_qed = list_begin_matcher ["\\."; "\\.\\."; "by"; "done"; "sorry"; "qed"];;

let match_theory = list_begin_matcher ["theory"];;

let match_end = list_begin_matcher ["end"];;

let match_qedglobal = list_begin_matcher ["oops"];;

let rec search test = function
  | [] -> failwith "Isa.search: unable to find undo state"
  | h :: t -> if test h then (h, t) else search test t
;;

let update_nest cmd old =
  if match_goal cmd then old + 1
  else if match_qed cmd then old - 1
  else if match_qedglobal cmd then 0
  else old
;;

let new_isa logic user =
  let prover = new_prover ("/isa/bin/isabelle-process -I -X -S " ^ logic) user "<ready/></pgip>\n" in
  let cur_pos, cur_dest, cur_nest, sent = ref 0, ref 0, ref 0, ref [] in
  let isa_send s a e =
    let a = remove_ml_comment a in
    cur_dest := e;
    sent := (!cur_pos, !cur_nest, a) :: !sent;
    cur_nest := update_nest a !cur_nest;
    let a = replace "<" "&lt;" a in
    prover.send s ("<pgip class = \"pa\" seq=\"1\"><doitem>" ^ a ^ "</doitem></pgip>") e
  in
  let isa_undo_one () =
    let undo_pos, undo_nest, to_undo = List.hd !sent in
    (*Utils.log "UOne \"%s\", %i\n%!" to_undo undo_pos;*)
    if match_diag to_undo then begin
      cur_pos := undo_pos;
      sent := List.tl !sent;
      ("", undo_nest, undo_pos)
    end else if match_qed to_undo then
      if !cur_nest > 0 then begin
        cur_pos := undo_pos;
        sent := List.tl !sent;
        ("undo", undo_nest, undo_pos)
      end else begin        
        let ((new_pos, new_nest, said), new_lst) = search (fun (_, x, _) -> x = 0) (List.tl !sent) in
        cur_pos := new_pos;
        sent := new_lst;
        ("undo", new_nest, new_pos)
      end
    else if match_end to_undo then begin
      let ((new_pos, new_nest, said), new_lst) = search (fun (_, _, s) -> match_theory s) (List.tl !sent) in
      cur_pos := new_pos;
      sent := new_lst;
      let to_say = Pcre.replace ~pat:"imports.*begin" (replace "theory" "remove_thy" said) in
      (to_say, new_nest, new_pos)
    end else if match_qedglobal to_undo then begin
      let ((new_pos, new_nest, said), new_lst) = search (fun (_, x, _) -> x = 0) (List.tl !sent) in
      cur_pos := new_pos;
      sent := new_lst;
      ("undo", new_nest, new_pos)
    end else begin
      cur_pos := undo_pos;
      sent := List.tl !sent;
      ("undo", undo_nest, undo_pos)
    end
  in
  let isa_check () =
    match prover.check () with
      | None -> None
      | Some (o, e, _, _) ->
          let waserr = match_error o in
          if waserr then begin
            cur_dest := !cur_pos;
            sent := List.tl !sent;
          end else begin
            begin try let (_, _, sents) = List.hd !sent in 
            if sents = "undo" || sents = "" || (String.length sents > 10 && String.sub sents 0 10 = "remove_thy") then 
              sent := List.tl !sent
            with _ -> ()
            end;
            cur_pos := !cur_dest;
          end;
          Some (cut_last_line_and_remove_chars o, e, !cur_pos, waserr)
  in
  let rec isa_undo pos =
    if (!cur_pos <= pos) then ("", !cur_pos) else
    let (tosay, tonest, topos) = isa_undo_one () in
    cur_nest := tonest;
    if topos > pos then begin
      (*Utils.log "HSnd: (%s)\n%!" tosay;*)
      prover.send 0 ("<pgip class = \"pa\"><doitem>" ^ tosay ^ "</doitem></pgip>") 0;
      ignore (Prover.block {prover with check = isa_check});
      cur_pos := topos;
      isa_undo pos
    end else (tosay, topos)
  in  
  {prover with check = isa_check; send = isa_send; undo = isa_undo;}
;;
