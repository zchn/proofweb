open Utils;;

type t = {
  send : int -> string -> int -> unit;
  check : unit -> (string * string * int * bool) option;
  close : unit -> unit;
  wait : float -> unit;
  undo : int -> string * int;
};;

let fake = {
  send = (fun _ _ _ -> ());
  check = (fun _ -> Some ("","",0,false));
  close = (fun _ -> ());
  wait = (fun _ -> ());
  undo = (fun _ -> "", 0)
};;

module X = Xstr_match;;

let list_matcher lst =
  let matches = List.map (fun x -> [X.Literal x]) lst in
  let pattern = [ X.Anystring; X.Alternative matches; X.Anystring ] in
  fun s -> X.match_string pattern s
;;

let testerror s =
  list_matcher ["FAIL"; "Error"; "error"; "Anomaly"; "No intros to undo"; "Uncaught exception"; "Toplevel input"] s
;;

let new_prover program user stop_string =
  let slen = String.length stop_string in
  let cwd = Unix.getcwd () in
  begin
    let dir = "files/" ^ user in
    try Unix.chdir dir with _ -> Unix.mkdir dir 0o755; Unix.chdir dir
  end;
  let inc, outc, errc, pid = Utils.open_process_full program [|"HOME=/tmp"; "PATH=/bin"; "USER=nobody"|] in
  Utils.time_log "Open PID %i@." pid;
  Unix.chdir cwd;
  let send_to_prover _ str _ = output_string outc (str ^ "\n"); flush outc in
  let idesc = Unix.descr_of_in_channel inc in
  let edesc = Unix.descr_of_in_channel errc in
  Unix.set_nonblock idesc;
  Unix.set_nonblock edesc;
  let incbuf = Buffer.create 100 in
  let errbuf = Buffer.create 100 in
  let strbuf = String.create 4096 in
  let pos = ref 0 in
  let dest = ref 0 in
  let check () =
(*    log "in check\n%!";*)
    begin try while true do
      let i = Unix.read idesc strbuf 0 4096 in
      (if i = 0 then 
        let i = Unix.read edesc strbuf 0 4096 in
        Buffer.add_substring errbuf strbuf 0 i;
        failwith ("Prover died: [" ^ Buffer.contents errbuf ^ "] : [" ^ Buffer.contents incbuf ^ "]")
      );
      Buffer.add_substring incbuf strbuf 0 i;
    done with Unix.Unix_error (e, _, _) -> (*log "%s\n%!" (Unix.error_message e)*)() end;
    begin try while true do
      let i = Unix.read edesc strbuf 0 4096 in
      (if i = 0 then raise Exit);
      Buffer.add_substring errbuf strbuf 0 i;
    done with Unix.Unix_error (e, _, _) -> (*log "%s\n%!" (Unix.error_message e)*)() | Exit -> (*log "Exit\n%!"; *)() end;
    (* Check prover die *)
    let elen = Buffer.length errbuf in
    let ilen = Buffer.length incbuf in
    if ((elen >= slen) && (Buffer.sub errbuf (elen - slen) slen = stop_string)
     || (ilen >= slen) && (Buffer.sub incbuf (ilen - slen) slen = stop_string)) then begin
      (*log "{{%s||%s}}\n%!" (Buffer.contents errbuf) (Buffer.contents incbuf);*)
      let i = replace "ý" "" (Buffer.contents incbuf) in
      let e = replace "ý" "" (Buffer.contents errbuf) in
        Buffer.reset errbuf; Buffer.reset incbuf;
        (if testerror i || testerror e then dest := !pos else pos := !dest);
        Some (i, e, !pos, (testerror i || testerror e))
    end else None
  in
  let wait time =
(*    Printf.printf "wait.in\n%!"; *)
    try
      ignore (Unix.select [edesc; idesc] [] [] time)
(*      let l1,l2,l3 = List.length l1, List.length l2, List.length l3 in
      log "%i,%i,%i\n%!" l1 l2 l3*)
    with _ -> (); (*Utils.time_log "Wait error@.";*)
  in
  let close () = 
    Utils.time_log "Close PID %i@." pid;
    (try Unix.kill pid 9 with _ -> ());    
    (try Unix.close idesc with _ -> ());
    (try Unix.close edesc with _ -> ());
    (try Unix.close (Unix.descr_of_out_channel outc) with _ -> ());
    (try ignore (Unix.wait ()) with _ -> ());        
  in
  {
    send = (fun p s d -> dest := d; send_to_prover p s d);
    check = check;
    close = close;
    wait = wait;
    undo = (fun _ -> ("", 0));
  }
;;

let rec block prover =
  match prover.check () with
  | None -> (*log "block->wait\n%!"; *)prover.wait 0.1; block prover
  | Some r -> r
;;

let remove_chars s =
  let l = String.length s in
  let b = Buffer.create l in
  let iterator c =
    if Char.code c < 128 then Buffer.add_char b c else
    if Char.code c = 250 then Buffer.add_string b "</font><font color='blue'>" else
    if Char.code c = 251 then Buffer.add_string b "</font><font color='red'>" else
    if Char.code c = 252 then Buffer.add_string b "</font><font color='red'>" else
    if Char.code c = 253 then Buffer.add_string b "</font><font color='green'>" else
    if Char.code c = 254 then Buffer.add_string b "</font><font color='magenta'>" else
    if Char.code c = 255 then Buffer.add_string b "</font><font color='brown'>"
  in
  String.iter iterator s;
  Buffer.contents b
;;

let cut_last_line_and_remove_chars s =
  let s = string_list_of_string s '\n' in
  let s = String.concat "\n" (List.rev (List.tl (List.rev s))) in
  remove_chars s
;;

let new_lego user =
  let prover = new_prover !Options.lego user (String.make 1 (Char.chr 249)) in
  let cur_pos = ref 0 in
  let positions = ref [] in
  let lego_check () =
    match prover.check () with
    | None -> None
    | Some (o, e, p, r) ->
        cur_pos := p;
        if not r then positions := p :: !positions;
        Some (cut_last_line_and_remove_chars o, e, p, r)
  in
  let lego_send s a e = 
    if a = "" then () else begin
      let a = remove_ml_comment (replace "\n" " " a) in
      prover.send s a e
    end
  in
  let lego_undo pos =
    let undo_no = ref 0 in
      while !cur_pos > pos do
        match !positions with
        | pos :: rest ->
            cur_pos := pos;
            incr undo_no;
            positions := rest;
        | _ -> failwith "lego_undo: unable to find a valid undo state"
      done;
      let a = "Undo " ^ (string_of_int !undo_no) ^ ";" in
      (a, !cur_pos)
  in
  prover.send 0 "Init XCC; Configure PrettyOn; Configure AnnotateOn;" 0;
(*  prover.wait 1.; ignore (prover.check ());*)
  {prover with check = lego_check; send = lego_send; undo = lego_undo;}
;;

let new_plastic user =
  let prover = new_prover (!Options.plastic ^ " -proof-general") user (String.make 1 (Char.chr 249)) in
  let lego_check () =
    match prover.check () with
    | None -> None
    | Some (o, e, p, r) -> Some (cut_last_line_and_remove_chars o, e, p, r)
  in
  {prover with check = lego_check;}
;;

let extension = function
  | "lego" -> ".l"
  | "plastic" -> ".lf"
  | "isahol" -> ".thy"
  | "isazf" -> ".thy"
  | "coq" -> ".v"
  | "coqtrunk" -> ".v"
  | "matita" -> ".ma"
  | "holl" -> ".ml"
  | _ -> Utils.time_log "Prover.extension: unknown prover!\n"; ".v"
;;

