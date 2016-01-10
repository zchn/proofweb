open Prover;;
open Utils;;


let parse_prompt str = 
  try
    let len = String.length str in
    let newline = try String.rindex_from str (len - 2) '\n' with Not_found -> -1 in
    let state = int_of_string (String.sub str (newline + 1) (len - newline - 3)) in
    let new_str = if newline = -1 then "" else String.sub str 0 newline in
    (new_str, state)
  with e -> failwith ("matita.parse_prompt: [" ^  str ^ "] failed! \n" 
              ^ (Printexc.to_string e)) 
;; 
     

let new_matita user =
  let prompt = String.make 2 (Char.chr 249) in
  prompt.[1] <- '\n';
  let prover = new_prover ("/matita/matitawiki -nodb") user prompt in
  let cur_pos, cur_dest, cur_state = ref 0, ref 0, ref 1 in
  let positions = ref [] in
  let matita_send s a e =
    if a = "" then () else begin
      let a = remove_ml_comment a in
      let a = replace "<" "&lt;" a in
      let a = "<pgip class = \"pa\" seq=\"1\"><doitem>" ^ a ^ "</doitem></pgip>" in
      (*Utils.log "[{[%s]}]" a;*)
      cur_dest := e;
      prover.send s a e
    end
  in
  let matita_check () =
    match prover.check () with
    | None -> None
    | Some (o, e, _, r) -> 
        let (e, state) = parse_prompt e in
        if (state = -1) then begin
          cur_dest := !cur_pos;
          Some (o, e, !cur_pos, true)
        end else begin
          if state > !cur_state then begin
            positions := (!cur_pos, !cur_state) :: !positions;
            (*log "Mat: Push: %i %i" !cur_pos !cur_state;*)
            cur_pos := !cur_dest;
          end else ();
          cur_state := state;
          Some (o, e, !cur_pos, false)
        end
  in
  let matita_undo pos =
    let new_state = ref 0 in
    while !cur_pos > pos do
      match !positions with
      | (pos, state) :: rest ->
          cur_pos := pos;
          cur_dest := pos;
          new_state := state;
          positions := rest;
      | _ -> failwith "matita_undo: unable to find a valid undo state"
    done;
    let a = "<pgip class = \"pa\"><undoitem>" ^ (string_of_int !new_state) ^ "</undoitem></pgip>" in
    (*Utils.log "[{[%s]}]%i %i" a !cur_pos !cur_state;*)
    prover.send 0 a 0;
    ("", !cur_pos)
  in
  (*Utils.log "new_matita\n%!";*)
  {prover with check = matita_check; send = matita_send; undo = matita_undo}
;;

