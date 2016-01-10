open Utils;;
open Prover;;

let match_error =
  let rex = Pcre.regexp "Unbound value|Unbound constructor|Exception|Parse error|This expression has type" in
  fun s -> Pcre.pmatch ~rex s
;;

let new_holl user =
  let prover = Prover.new_prover ("expect -c \"spawn /holl/hol\" -c \"interact\"")  user "\n# " in
  let send_lst = ref [] in
  let cur_pos = ref 0 in
  let cur_dest = ref 0 in
  let csend s a e =
    send_lst := (s, a) :: !send_lst;
    cur_dest := e;
    prover.send s a e
  in
  let cundoone () =
    let (pos, str) = List.hd !send_lst in
    send_lst := List.tl !send_lst;
    if Pcre.pmatch ~rex:(Pcre.regexp ~flags:[`ANCHORED] "[ \t\r\n]*g[ ]*`") str then ("current_goalstack := [];;", pos) else
    if Pcre.pmatch ~rex:(Pcre.regexp ~flags:[`ANCHORED] "[ \t\r\n]*e[ (\t\r\n]") str then ("b ();;", pos) else
    ("();;", pos)
  in
  let rec ccheck () =
    match prover.check () with
    | None -> None
    | Some (o, e, _, _) ->
        let err = match_error o in
        if err then begin
          if cur_dest < cur_pos then cur_pos := !cur_dest;
          send_lst := List.tl !send_lst;
          cur_dest := !cur_pos;
        end else begin
          if cur_dest < cur_pos then send_lst := List.tl !send_lst;
          cur_pos := !cur_dest;
        end;
        Some (o, e, !cur_pos, err)
  in
  let rec cundo pos =
    if (!cur_pos <= pos) then ("();;", !cur_pos) else
    let (tosay, topos) = cundoone () in
    if topos > pos then begin
      prover.send 0 tosay 0;
      ignore (Prover.block {prover with check = ccheck});
      cur_pos := topos;
      cundo pos
    end else (tosay, topos)
  in
  {prover with send = csend; check = ccheck; undo = cundo}
;;
