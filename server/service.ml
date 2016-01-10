open Utils;;
open Session;;
open Format;;

let serve_listen (cgi:Netcgi.cgi_activation) session =
  cgi # set_header ~content_type:"text/html" ~cache:`No_cache ();
  cgi # output # output_string (session_listen session)
;;

let serve_say (cgi:Netcgi.cgi_activation) session argument =
  session_queue session argument;
  serve_listen cgi session
;;

let serve_undo (cgi:Netcgi.cgi_activation) session argument =
  begin try session_undo session (int_of_string argument);
  with Failure s ->
    cgi # set_header ~content_type:"text/html" ~cache:`No_cache ();
    cgi # output # output_string ("+" ^ s ^ Options.token ^ "0" ^ Options.token)
  end;
  serve_listen cgi session
;;

let unhtml s = replace_list s
    ["<br>", "\n";
     "<br =\"\">", "\n";
     "<BR>", "\n";
     "<BR/>", "\n";
     "&gt;", ">";
     "&lt;", "<";
     "&amp;", "&";
     "\r", ""
];;

let tohtml s = replace_list s
    ["&", "&amp;";
     "<", "&lt;";
     ">", "&gt;";
     "\"", "&quot;";
     "\n", "<br>";
     "\r", ""
];;

let tohtmlmini s = replace_list s [("\n", "<br>"); ("\\", "\\\\")];;

let escape s = replace "'" "\\'" (replace "\"" "\\\"" s);;

let serve_save (cgi:Netcgi.cgi_activation) session name content =
  cgi # set_header ~content_type:"text/html" ();
  try
    let fname = "files/" ^ session.user ^ "/" ^ name in
    let outc = open_out fname in
    output_string outc (unhtml content);
    close_out outc;
    let len = String.length fname in
    if (len > 1 && String.sub fname (len - 2) 2 = ".v") then begin
      ignore (Sys.command ("/bin/rm -f " ^ fname ^ "o"));
      ignore (Sys.command ("/bin/rm -f " ^ fname ^ "ok"));
      let coq = if session.provert = "coq" then "/coq/bin/coqc" else "/coqtrunk/bin/coqc" in
      let coq = coq ^ !Options.coqopts in
      let cmd = "cd files/" ^ session.user ^ "; " ^ coq ^ " " ^ name ^ " &> " ^ name ^ "nok" in
      let ret = Sys.command cmd in
      if ret = 0 then begin
        ignore (Sys.command ("/bin/touch " ^ fname ^ "o"));
        let ret = Sys.command ("/bin/verify " ^ fname ^ " &> " ^ fname ^ "nok") in
        if ret = 0 then ignore (Sys.command ("/bin/touch " ^ fname ^ "ok")) else ();
      end
    end else ();
    cgi # output # output_string "++"
  with _ ->
    Utils.time_log "Save Failed@.";
    cgi # output # output_string "+-"
;;

let serve_restart (cgi:Netcgi.cgi_activation) session =
  session_restart session;
  cgi # set_header ~content_type:"text/html" ();
  cgi # output # output_string "++"
;;

let match_end str mat =
  let len = String.length str in
  let mlen = String.length mat in
  if len > mlen && String.sub str (len - mlen) mlen = mat then true else false
;;

let getfile name user prover olderr =
  if name = "" then "", olderr else
  if name.[0] = '.' || name.[0] = '/' then "", "Cannot read this file\\n" ^ olderr else
  try (read_file ("files/" ^ user ^ "/" ^ name)), olderr
  with _ ->
    let slogin, dir = try
      let slash = String.rindex user '/' in
      (String.sub user (slash + 1) (String.length user - slash - 1)),
      (String.sub user 0 slash)
    with _ -> user, "" in
    try (read_file ("tasks/" ^ dir ^ "/" ^ name)), olderr
    with _ -> "", ("Tried to load a nonexisting file: " ^ name)
;;

let serve_auth (cgi:Netcgi.cgi_activation) session =
  (*Utils.time_log "In auth@.";*)
  let packet = try int_of_string (cgi # argument_value "callnr") with _ -> 0 in
  let command = cgi # argument_value "command" in
  let argument = cgi # argument_value "cmdarguments" in
  let ip = cgi#environment#cgi_remote_addr in
  match command with
  | "addtobuf" ->
      (*Utils.time_log "In add [%s]@." argument;*)
      let lst = Xstr_split.split_string " " true true [Options.token] argument in
      let rec queue = function
        | adds :: add :: adde :: t ->
            Utils.time_log "%15s %9n %3n %s A %s@." ip session.id packet session.user (replace "\n" " " add);
            queue (adde :: t)
        | _ -> ()
      in
      queue lst;
      serve_say cgi session argument
  | "undo" ->
      Utils.time_log "%15s %9n %3n %s U %s@." ip session.id packet session.user argument;
      serve_undo cgi session argument
  | "listen" ->
      Utils.time_log "%15s %9n %3n %s U@." ip session.id packet session.user;
      serve_listen cgi session
  | "r" ->
      Utils.time_log "%15s %9n %3n %s R@." ip session.id packet session.user;
      serve_restart cgi session
  | "quit" ->
      Utils.time_log "%15s %9n %3n %s Q@." ip session.id packet session.user;
      session_delete session
  | "save" ->
      let index = String.index argument '*' in
      let name = String.sub argument 0 index in
      let content = String.sub argument (index + 1) (String.length argument - index - 1) in
      Utils.time_log "%15s %9n %3n %s S %s@." ip session.id packet session.user name;
      Utils.save_log "%15s %9n %3n %s S %s %s@." ip session.id packet session.user name argument;
      serve_save cgi session name content
  | x ->
      let argument =
        if String.length argument > 5 && String.sub argument 0 6 = "Reset " then begin
          if Pcre.pmatch ~rex:(Pcre.regexp "[.][.]\\|/") argument then failwith "service: Invalid argument";
          let arg = String.sub argument 6 (String.length argument - 6) in
          let file = "files/" ^ session.user ^ "/" ^ arg in
          ignore (Sys.command ("rm -f " ^ file));
          arg
        end else argument
      in
      cgi # set_header ~content_type:"text/html" ~cache:`No_cache ();
      session_restart session;
      Utils.time_log "%15s %9n %3n %s O %s %s@." ip session.id packet session.user argument session.provert;
      let out, err = replace "\n" "\\n" session.out, replace "\n" "\\n" session.err in
      let out, err = replace "\r" "" out, replace "\r" "" err in
(*      Utils.log "[[[[[[[%s]]]]]@." out;*)
      let tohtml = if cgi # argument_value ~default:"" "html" <> "" then tohtmlmini else tohtml in
      let file, err = getfile argument session.user session.provert err in
      let i = tohtml file in
      let content = replace "__PROVER__" session.provert (read_file "index.html") in
      let content = replace "__INP__" i content in
      let content = replace "__OUT__" (replace "\"" "\\\"" out) content in
      let content = replace "__ERR__" (replace "\"" "\\\"" err) content in
      let content = replace "__SESSION__" (string_of_int session.id) content in
      let content = replace "__USER__" (cgi # argument_value "login") content in
      let content = replace "__PASS__" (cgi # argument_value "pass") content in
      let content = replace "__FILENAME__" argument content in
      let content =
        if !Options.wiki then content else
        replace "__PREFIX__" "pub/" (replace "__DESIGN__" "true" content) (* pub *)
      in
      cgi # output # output_string content;
;;

let wikisessionno = ref 0 ;;

let newcalcsession () =
  let news = session_new "coqtrunk" "calc" in
  session_queue news "0__PWT__Require Import CoRN.reals.fast.CRArith.__PWT__0";
  Utils.time_log "Starting calc: 10%%@."; ignore (session_listen news);
  session_queue news "0__PWT__Require Import CoRN.reals.fast.CRexp.__PWT__0";
  Utils.time_log "Starting calc: 20%%@."; ignore (session_listen news);
  session_queue news "0__PWT__Require Import CoRN.reals.fast.CRln.__PWT__0";
  Utils.time_log "Starting calc: 30%%@."; ignore (session_listen news);
  session_queue news "0__PWT__Require Import CoRN.reals.fast.CRroot.__PWT__0";
  Utils.time_log "Starting calc: 40%%@."; ignore (session_listen news);
  session_queue news "0__PWT__Require Import CoRN.reals.fast.Compress.__PWT__0";
  Utils.time_log "Starting calc: 50%%@."; ignore (session_listen news);
  session_queue news "0__PWT__Require Import CoRN.reals.fast.CRpi_fast.__PWT__0";
  Utils.time_log "Starting calc: 60%%@."; ignore (session_listen news);
  session_queue news "0__PWT__Require Import CoRN.reals.fast.CRsign.__PWT__0";
  Utils.time_log "Starting calc: 70%%@."; ignore (session_listen news);
  session_queue news "0__PWT__Require Import CoRN.reals.fast.CRsin.__PWT__0";
  Utils.time_log "Starting calc: 80%%@."; ignore (session_listen news);
  session_queue news "0__PWT__Require Import CoRN.reals.fast.CRcos.__PWT__0";
  Utils.time_log "Starting calc: 90%%@."; ignore (session_listen news);
  session_queue news "0__PWT__Definition answer (n:positive) (r:CR) := let m := (iter_pos n _ (Pmult 10) 1%positive) in let (a,b) := (approximate (CRplus r (' (1#(Pmult 2 m)))%CR) (1#(Pmult 2 m))%Qpos)*m in Zdiv a b.__PWT__0";
  Utils.time_log "Starting calc:100%%@."; ignore (session_listen news);
  news.id
;;

let prepare_calc_session () =
  let s = newcalcsession () in
  Utils.time_log "saving.@.";
  Mutex.lock mutex; calcsession := Some s; Mutex.unlock mutex;
  Utils.time_log "saved.@."
;;

prepare_calc_session ();;

let getcalcsession () =
  Utils.time_log "getcalcsession ().@.";
  Mutex.lock mutex;
  match !calcsession with
  | Some s -> calcsession := None; Mutex.unlock mutex; ignore (Thread.create prepare_calc_session ()); s
  | None -> Mutex.unlock mutex; newcalcsession ()
;;

let authenticate (cgi:Netcgi.cgi_activation) =
  (*if (try cgi # argument_value "prover" with _ -> "") = "calc" then begin
    Utils.time_log "Try open calc session.@.";
    Some (session_get (getcalcsession ()));
  end else *)
  if !Options.wiki then begin
    try Some (session_get !wikisessionno)
    with _ ->
      let news = session_new "coq" "wiki" in
      wikisessionno := news.id;
      Some news
  end else begin
    let sess = try int_of_string (cgi # argument_value "s") with _ -> 0 in
    let sess = if sess <> 0 then try Some (session_get sess) with _ -> None else None in
    match sess with
    | Some _ -> sess
    | None ->
        let login = cgi # argument_value "login" in
        let login = (cgi # argument_value ~default:"" "logingrp") ^ login in
        let pass = try cgi # argument_value "pass" with _ -> "" in
        let adminlogin = cgi # argument_value ~default:"" "adminlogin" in
        let adminpass = cgi # argument_value ~default:"" "adminpass" in
        let admin_logins = read_comma_separated "/admin_logins" in
        let admin_logins = List.map (fun x -> (List.hd x, (List.hd (List.tl x)))) admin_logins in
        let goodpass = try List.assoc adminlogin admin_logins with _ -> "" in
        Utils.time_log "Try open session: %s@." login;
        let logins = read_comma_separated "logins" in
        try
          let t = List.find (fun x -> try List.hd x = login with _ -> false) logins in
          if (goodpass = Digest.to_hex (Digest.string adminpass)) || (Digest.to_hex (Digest.string pass) = List.hd (List.tl t)) then
            Some (session_fake (cgi # argument_value "prover") login) else None
        with _ -> None
  end
;;

let calc _ (cgi:Netcgi.cgi_activation) =
  (try Unix.setuid !Options.uid with _ -> ());
  let sess = getcalcsession () in
  let content = replace "__SESSION__" (string_of_int sess) (read_file "calc.html") in
  cgi # output # output_string content;
  cgi # output # commit_work ()
;;

let serve _ (cgi:Netcgi.cgi_activation) =
  (try Unix.setuid !Options.uid with _ -> ());
  try
    begin match authenticate cgi with
    | Some session -> serve_auth cgi session
    | None -> login_page cgi
    end;
    cgi # output # commit_work ();
  with x ->
    cgi # output # rollback_work ();
    let s = match x with
      | Exit -> "Exit"
      | Failure s -> "Failure: " ^ s
      | Unix.Unix_error (e,f,p) -> "Unix_error: " ^ (Unix.error_message e) ^ " in " ^ f ^ " with " ^ p
      | Not_found -> "Not found"
      | Invalid_argument s -> "Invalid Argument: " ^ s
      | End_of_file -> "End_of_file: Prover died unexpectedly!"
      | x -> Printexc.to_string x
    in
    cgi # output # output_string ("-Exception: " ^ s);
    cgi # output # commit_work ()
;;
