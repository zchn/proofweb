open Utils;;
open Session;;
open Format;;

let output_provers (cgi:Netcgi_types.cgi_activation) =
  cgi # output # output_string "<select name=\"prover\">";
  cgi # output # output_string "<option value=\"coq\">Coq</option>";
  cgi # output # output_string "<option value=\"coqtrunk\">Coq/Trunk</option>";
  cgi # output # output_string "<option value=\"isahol\" >Isabelle/HOL</option>";
  cgi # output # output_string "<option value=\"isazf\" >Isabelle/ZF</option>";
  cgi # output # output_string "<option value=\"matita\">Matita (incomplete)</option>";
  cgi # output # output_string "<option value=\"lego\">Lego (incomplete)</option>";
  cgi # output # output_string "<option value=\"plastic\">Plastic (incomplete)</option>";
  cgi # output # output_string "<option value=\"holl\">HOL Light (incomplete)</option></select><br/>";
;;

let auth (cgi:Netcgi_types.cgi_activation) =
  let login = cgi # argument_value "login" in
  let login = (cgi # argument_value ~default:"" "logingrp") ^ login in
  let adminlogin = cgi # argument_value ~default:"" "adminlogin" in
  let adminpass = cgi # argument_value ~default:"" "adminpass" in
  Utils.time_log "Try login1: %s@." login;
  let admin_logins = read_comma_separated "/admin_logins" in
  let admin_logins = List.map (fun x -> (List.hd x, (List.hd (List.tl x)))) admin_logins in
  Utils.time_log "Try login2: %s@." login;
  let goodpass = try List.assoc adminlogin admin_logins with _ -> "" in 
  let pass = cgi # argument_value ~default:"" "pass" in
  Utils.time_log "Try login3: %s@." login;
  let l = read_comma_separated "/logins" in
  let t = List.find (fun x -> try List.hd x = login with _ -> false) l in
  Utils.time_log "Try login4: %s@." login;
  if (goodpass = Digest.to_hex (Digest.string adminpass)) || (Digest.to_hex (Digest.string pass) = List.hd (List.tl t)) then login,pass,adminlogin,adminpass else raise Exit
;;

let logged _ (cgi:Netcgi_types.cgi_activation) =
  (try let login,pass,adminlogin,adminpass = auth cgi in
  cgi # set_header ~content_type:"text/html" ~cache:`No_cache ();
  cgi # output # output_string "<html><head><link rel=\"stylesheet\" href=\"pub/control.css\"></head><body>\n";
  let slogin, dir = try
    let slash = String.rindex login '/' in
    (String.sub login (slash + 1) (String.length login - slash - 1)),
    (String.sub login 0 slash)
  with _ -> login, "" in
  if slogin <> "nobody" then (
    cgi # output # output_string ("<h3>You are logged in as: " ^ slogin ^ "</h3>(<a href=\"index.html\">logout</a>)\n");
    if dir <> "" then cgi # output # output_string ("<h3>You belong to group: " ^ dir ^ "</h3>\n");
  );
  cgi # output # output_string "<ul>";
  let tasks = if dir = "" then [] else try readdir ("tasks/" ^ dir) with _ -> [] in
  let tasks = List.filter (fun x -> x <> "comments") tasks in
  let files = try (readdir ("files/" ^ login)) with _ -> [] in
  let comments = try read_comma_pairs ("tasks/" ^ dir ^ "/comments") with _ -> [] in
  cgi # output # output_string "<li><h4>Experiment with an empty buffer, select prover:</h4>";
  cgi # output # output_string "<form action=\"index.html\" method=\"post\">\n";
  cgi # output # output_string ("<input type=\"hidden\" name=\"login\" value=\"" ^ login ^ "\">\n");
  cgi # output # output_string ("<input type=\"hidden\" name=\"pass\" value=\"" ^ pass ^ "\">\n");
  cgi # output # output_string ("<input type=\"hidden\" name=\"adminlogin\" value=\"" ^ adminlogin ^ "\">\n");
  cgi # output # output_string ("<input type=\"hidden\" name=\"adminpass\" value=\"" ^ adminpass ^ "\">\n");
  output_provers cgi;
  cgi # output # output_string "<input type=\"submit\" value=\"ACCESS THE INTERFACE\"></form></li>\n";
  if slogin = "nobody" then (
    cgi # output # output_string "<li><h4>You are not logged in as a registered user.
       Go <a href=\"/\">back to main page</a> if guest access is not what you want</h3>\n");
  if tasks <> [] then begin
    cgi # output # output_string "<li><h3>Tasks</h3>\n";
    cgi # output # output_string "<form action=\"index.html\" method=\"post\"><table border=1>\n";
    cgi # output # output_string "<tr><td>Load</td><td>Comment</td><td>Status</td><td>Reset</td></tr>";
    let iterator name =
      let comment = try List.assoc name comments with _ -> "" in
      (*let dot = String.rindex name '.' in*)
      (*let sname = String.sub name 0 dot in*)
      let status = 
        if slogin = "nobody" then "<font color=\"grey\">Cannot save as nobody</font>" else
        if not (List.mem name files) then "<font color=\"grey\">Not touched</font>" else
        if not (List.mem (name ^ "o") files) then 
          let hint = replace "\n" "\\n" (replace "'" "&quot;" (replace "\"" "&quot;" (try read_file ("files/" ^ login ^ "/" ^ name ^ "nok") with _ -> ""))) in
          (*"<a class=\"nocompile\" href=\"#\" title=\"" ^ hint ^ "\">Incomplete</a>"*) 
          let nw = "var okno = window.open('about:blank', 'why'); okno.window.document.open(); okno.window.document.write('<html><body><pre>" ^ hint ^ "</html>'); okno.window.document.close();" in
          "<font color=\"red\">Incomplete</font> (<a href=\"#\" onclick=\"" ^ nw ^ "\">why?</a>)"
        else
          if not (List.mem (name ^ "ok") files) then 
            let hint = replace "\n" "\\n" (replace "'" "&quot;" (replace "\"" "&quot;" (try read_file ("files/" ^ login ^ "/" ^ name ^ "nok") with _ -> ""))) in
            let nw = "var okno = window.open('about:blank', 'why'); okno.window.document.open(); okno.window.document.write('<html><body><pre>" ^ hint ^ "</html>'); okno.window.document.close();" in
            "<font color=\"orange\">Correct</font> (<a href=\"#\" onclick=\"" ^ nw ^ "\">why?</a>)"
          else
            "<font color=\"green\">Solved</font>"
      in
      cgi # output # output_string ("<tr><td><input type=\"submit\" name=\"cmdarguments\" value=\"" ^ name ^ "\"></td>");
      cgi # output # output_string ("<td>" ^ comment ^ "</td><td>" ^ status ^ "</td>");
      cgi # output # output_string ("<td><input class=\"resetbutton\" type=\"submit\" name=\"cmdarguments\" value=\"Reset " ^ name ^ "\"></td></tr>\n")
    in
    cgi # output # output_string ("<input type=\"hidden\" name=\"login\" value=\"" ^ login ^ "\">\n");
    cgi # output # output_string ("<input type=\"hidden\" name=\"pass\" value=\"" ^ pass ^ "\">\n");
    cgi # output # output_string ("<input type=\"hidden\" name=\"adminlogin\" value=\"" ^ adminlogin ^ "\">\n");
    cgi # output # output_string ("<input type=\"hidden\" name=\"adminpass\" value=\"" ^ adminpass ^ "\">\n");
    cgi # output # output_string ("<input type=\"hidden\" name=\"prover\" value=\"coq\">\n");
    List.iter iterator tasks;
    cgi # output # output_string "</form></li>"
  end;
  cgi # output # output_string "<li><h4>Select a saved file to load:</h4>";
  let iterator name =
    if List.mem name tasks then () else
    let len = String.length name in
    if (len > 2 && (String.sub name (len - 3) 3 = ".vo")) then () else
    if (len > 3 && (String.sub name (len - 4) 4 = ".vok")) then () else
    if (len > 4 && (String.sub name (len - 5) 5 = ".vnok")) then () else
    cgi # output # output_string ("<input type=\"radio\" name=\"cmdarguments\" value=\"" ^ name ^ "\">" ^ name ^ "<br/>\n")
  in
  cgi # output # output_string "<form action=\"index.html\" method=\"post\">\n";
  cgi # output # output_string ("<input type=\"hidden\" name=\"login\" value=\"" ^ login ^ "\">\n");
  cgi # output # output_string ("<input type=\"hidden\" name=\"pass\" value=\"" ^ pass ^ "\">\n");
  cgi # output # output_string ("<input type=\"hidden\" name=\"adminlogin\" value=\"" ^ adminlogin ^ "\">\n");
  cgi # output # output_string ("<input type=\"hidden\" name=\"adminpass\" value=\"" ^ adminpass ^ "\">\n");
  List.iter iterator files;
  output_provers cgi;
  cgi # output # output_string "<input type=\"submit\" value=\"Load\"></form></li>";
  cgi # output # output_string "</li></ul>";
  cgi # output # output_string "</body></html>"
  with _ -> login_page cgi);  
  cgi # output # commit_work ();
;;
