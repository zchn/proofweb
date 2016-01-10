open Prover;;

Random.self_init ();;

type t = {
  id : int;
  mutable prover : Prover.t;
  mutable waiting : bool ref;
  user : string;
  mutable packet_number : int;
  provert : string;
  mutable queue : (int * string * int) Queue.t;
  mutable pos : int;
  mutable changed : bool;
  mutable out : string;
  mutable err : string;
  mutable time : float;
};;

let hash = Hashtbl.create 10;;
let mutex = Mutex.create ();;
let calcsession : ((int option) ref) = ref None;;

let session_get id =
  Mutex.lock mutex;
  try let ret = Hashtbl.find hash id in Mutex.unlock mutex; ret
  with Not_found -> Mutex.unlock mutex; failwith "Session.get: No such session"
;;

let new_prover prover user =
  match prover with
  | "lego" -> new_lego user
  | "plastic" -> new_plastic user
  | "matita" -> Matita.new_matita user
  | "isahol" -> Isa.new_isa "HOL" user
  | "isazf" -> Isa.new_isa "ZF" user
  | "coq" -> Coq.new_coq ("/coq/bin/coqtop.opt " ^ !Options.coqopts) user
  | "coqtrunk" -> Coq.new_coq ("/coqtrunk/bin/coqtop.opt " ^ !Options.coqopts) user
  | "holl" -> Holl.new_holl user
  | "fake" -> Prover.fake
  | x -> Utils.time_log "Unknown new prover: %s@." x; Prover.fake
;;

let session_fake provert user =
  Mutex.lock mutex;
  let ret = {
    id = (Random.bits () mod 1000000000);
    waiting = ref false;
    user = user;
    prover = Prover.fake;
    out = "";
    err = "";
    packet_number = 0;
    provert = provert;
    queue = Queue.create ();
    pos = 0;
    changed = false;
    time = Unix.gettimeofday ();
  } in
  Hashtbl.replace hash ret.id ret;
  Mutex.unlock mutex;
  ret
;;

let session_new provert user =
  let session = session_fake provert user in
  let prover = new_prover provert user in
  session.prover <- prover;
  let o, e, _, _ = block prover in
  session.out <- o; session.err <- e;
  session
;;


let session_restart session =
  session.prover.close ();
  let prover = new_prover session.provert session.user in
  session.waiting <- ref false;
  session.prover <- prover;
  session.queue <- Queue.create ();
  let o, e, _, _ = block session.prover in
  session.out <- o; session.err <- e; session.changed <- false;
;;

let session_process session =
  if (not !(session.waiting)) && (Queue.length session.queue > 0) then
    let (s, a, e) = Queue.pop session.queue in
    session.prover.send s a e;
    session.waiting := true; 
(*    Printf.printf "process: send: [%s]\n%!" a;*)
  else ();
(*  Printf.printf "process: queue len: %i\n%!" (Queue.length session.queue)*)
;;

let session_queue session argument =
(*  Printf.printf "queueing\n%!";*)
  let lst = Xstr_split.split_string " " true true [Options.token] argument in
  let rec queue = function
    | adds :: add :: adde :: t -> 
        Queue.add (int_of_string adds, add, int_of_string adde) session.queue;
        queue (adde :: t)
    | _ -> ()
  in
  queue lst;
(*  Printf.printf "  queue len: %i\n%!" (Queue.length session.queue);*)
  session_process session;
;;

let session_undo session argument =
  (* TODO First remove from queue, then we assume queue is empty *)
  let to_send, npos = session.prover.undo argument in
  Queue.add (-1 , to_send, npos) session.queue;
  session_process session
;;

let rec session_listen session =
  if !(session.waiting) then begin
    match session.prover.check () with
    | Some (out, err, pos, waserror) ->
(*        Utils.log "+";*)
        session.waiting := false;
        session.err <- err; session.out <- out; session.changed <- true;
        if not waserror then begin
          session.pos <- pos;
        end else begin
          Queue.clear session.queue;
        end;
        session_process session;
        session_listen session;
    | None -> 
        let timeused = Unix.gettimeofday () -. session.time in
        if ( timeused > 0. && 1. -. timeused > 0. ) then begin
          session.prover.wait (1. -. timeused);
          session_listen session
        end else begin
(*          Utils.log "\n%!";*)
          if session.changed then begin
            session.changed <- false;
            "+" ^ session.out ^ Options.token ^ (string_of_int session.pos) ^ Options.token ^ session.err
          end else ""
        end
  end else begin
(*    Utils.log "=\n%!";*)
    if session.changed then begin
      session.changed <- false;
      "+" ^ session.out ^ Options.token ^ (string_of_int session.pos) ^ Options.token ^ session.err
    end else begin
(*      Utils.log "  not waiting\n%!";*)
      "++"
    end
  end
;;

let session_listen session =
  session.time <- Unix.gettimeofday ();
  session_listen session
;;

let session_delete session =
  session.prover.Prover.close ();
  Mutex.lock mutex;
  Hashtbl.remove hash session.id;
  Mutex.unlock mutex;
  Gc.major ();
;;

let rec session_killer () =
  (try ignore (Thread.select [] [] [] 60.) with _ -> ());
  Mutex.lock mutex;
  let h = Hashtbl.copy hash in
  Mutex.unlock mutex;
  let iterator id session =
    if (Unix.gettimeofday () -. session.time) > 7200. then session_delete session else ()
  in
  Hashtbl.iter iterator h;
  session_killer ()
;;
