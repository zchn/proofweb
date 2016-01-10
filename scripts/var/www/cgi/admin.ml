#!/usr/bin/ocamlscript
Ocaml.packs := ["cgi"];;
Ocaml.sources := [ "utils.ml" ];;
--
let chroot = "/chroot"
let cgi = new Netcgi.std_activation ()
let out = cgi # output # output_string
let get default name = cgi # argument_value ~default name;;

cgi # set_header ();

out "<HTML><HEAD><TITLE>Course Admin Interface</TITLE></HEAD><BODY>";;

let login = get "" "login";;
let pass = get "" "pass";;
let course = get "" "course";;

if not (Utils.authenticate get) then begin
(*  ignore (Sys.command ("echo \"" ^ login ^ "\n" ^ pass ^ "\n" ^ course ^ "\" >> /substa/admin_login_fail"));*)
  out "Not authenticated!";
  out "</BODY></HTML>";
  exit 0;
end;;



(* Data for a participant that will undergo change *)
let action = get "" "action";;
let username = get "" "username";;
let userlogin = get "" "userlogin";;
let userpwd = get "" "userpwd";;


let users = Utils.read_comma_separated (chroot ^ "/logins");;
let users = List.filter (fun s -> List.length s = 3) users;;
let logins = List.map List.hd users;;
let tasks = try Utils.readdir (chroot ^ "/tasks/" ^ course) with _ -> [];;
let tasks = List.filter (fun x -> x <> "comments") tasks;;


(* First we modify the list of course participants, if necessary *)

let users , change = 
  if action = "create" then
    if not (List.mem (course ^ "/" ^ userlogin) logins || userlogin = "" || userpwd = "" || username = "") then
      (List.append [[course ^ "/" ^ userlogin ; userpwd ; username]] users ,
      let outc = open_out_gen [Open_append] 0o660 (chroot ^ "/logins") in
	output_string outc (course ^ "/" ^ userlogin ^ "," ^ (Digest.to_hex (Digest.string userpwd)) ^ "," ^ username ^ "\n");
	close_out outc;
	"<span style=\"color: green;\">The new participant " ^ userlogin ^ " has been created successfully.</span>")
    else
      (users, "<span style=\"color: red;\">The login " ^ userlogin ^ " already exists, or you forgot to give a name, login or password.</span>")
  else if action = "change" then
    let fulllogin = course ^ "/" ^ userlogin in
      if (List.mem fulllogin logins) then begin
	let newpwd = if (userpwd = "") then List.hd (List.tl (List.hd (List.filter (fun s -> (List.hd s = fulllogin)) users))) else Digest.to_hex (Digest.string userpwd)
	in
	let newname = if (username = "") then List.hd (List.tl (List.tl (List.hd (List.filter (fun s -> (List.hd s = fulllogin)) users)))) else username 
	in
	let users = List.filter (fun s -> not (List.hd s = fulllogin)) users in
	  ( List.append [[fulllogin ; newpwd ; newname]] users ,
	    let outc = open_out (chroot ^ "/logins") in 
	    List.iter (fun s -> output_string outc (List.hd s ^ "," ^ List.hd (List.tl s) ^ "," ^ List.hd (List.tl (List.tl s)) ^ "\n")) users;
	      output_string outc (fulllogin ^ "," ^ newpwd ^ "," ^ newname ^ "\n");
	      close_out outc;
	      "<span style=\"color: green;\">Data for participant " ^ userlogin ^ " changed.</span>")
      end
      else
	(users, "<span style=\"color: red;\">The participant " ^ userlogin ^ " does not exist.</span>")
  else if action = "delete" then
    let fulllogin = course ^ "/" ^ userlogin in
      if (List.mem fulllogin logins) then begin
	let users = List.filter (fun s -> not (List.hd s = fulllogin)) users in
	let outc = open_out (chroot ^ "/logins") in 
	  List.iter (fun s -> output_string outc (List.hd s ^ "," ^ List.hd (List.tl s) ^ "," ^ List.hd (List.tl (List.tl s)) ^ "\n")) users;
	  close_out outc;
	  (users , "<span style=\"color: green;\">Participant " ^ userlogin ^ " deleted.</span>")
      end
      else
	(users, "<span style=\"color: red;\">The participant " ^ userlogin ^ " does not exist.</span>")
  else if action = "tgz" then begin
    let name = Digest.to_hex (Digest.string (string_of_int (Random.bits ()))) in
    ignore (Sys.command ("cd " ^ chroot ^ "/files/" ^ course ^ "; tar czvf /var/www/tmp/" ^ name ^ ".tgz . &> /dev/null"));
    (users, "<span style=\"color: green;\">Course prepared: <a href=\"/tmp/" ^ name ^ ".tgz\">download</a></span>")
  end else
    (users, "")
;;

let users = List.sort (fun l1 l2 -> compare (List.hd (List.tl (List.tl l1))) (List.hd (List.tl (List.tl l2)))) users;;


(* And now the rendering of the page *)

out ("<h1>Administration page for the course " ^ course ^ "</h1>");;

out ("<div style=\"position: absolute; top: 20pt; right: 10pt;\">
     <form action=\"http://prover.cs.ru.nl/\" method=\"get\">
     <input type=\"submit\" value=\"Return to login page\">
     </form></div>");;

out ("<b>Status:</b> " ^ change ^ "<br /><br />");;

out "<b>Get a TGZ of the course</b><br /><br />";;

out ("<form action=\"admin.ml\" method=\"post\">
    <input type=\"hidden\" name=\"login\" value=\"" ^ login ^ "\">
    <input type=\"hidden\" name=\"pass\" value=\"" ^ pass ^ "\">
    <input type=\"hidden\" name=\"course\" value=\"" ^ course ^ "\">
    <input type=\"submit\" value=\"Get TGZ\">
    <input type=\"hidden\" name=\"action\" value=\"tgz\")
    </form><br /><br />");;


out "<b>Create a new course participant</b><br /><br />";;

out ("<form action=\"admin.ml\" method=\"post\">
    <input type=\"hidden\" name=\"login\" value=\"" ^ login ^ "\">
    <input type=\"hidden\" name=\"pass\" value=\"" ^ pass ^ "\">
    <input type=\"hidden\" name=\"course\" value=\"" ^ course ^ "\">
    Name of new participant:
    <input type=\"text\" name=\"username\" value=\"\">
    Login of new participant:
    <input type=\"text\" name=\"userlogin\" value=\"\">
    Password of new participant:
    <input type=\"password\" name=\"userpwd\" value=\"\">
    <input type=\"submit\" value=\"Create new participant\">
    <input type=\"hidden\" name=\"action\" value=\"create\")
    </form><br /><br />");;

out "<b>Change the data of a course participant</b><br /><br />";;

out ("<form action=\"admin.ml\" method=\"post\">
    <input type=\"hidden\" name=\"login\" value=\"" ^ login ^ "\">
    <input type=\"hidden\" name=\"pass\" value=\"" ^ pass ^ "\">
    <input type=\"hidden\" name=\"course\" value=\"" ^ course ^ "\">
    Login of participant:
    <input type=\"text\" name=\"userlogin\" value=\"\">
    New name for participant:
    <input type=\"text\" name=\"username\" value=\"\">
    New password for participant:
    <input type=\"password\" name=\"userpwd\" value=\"\">
    <input type=\"submit\" value=\"Change participant data\">
    <input type=\"hidden\" name=\"action\" value=\"change\")
    </form><br /><br />");;

out "<b>Delete a course participant</b><br /><br />";;

out ("<form action=\"admin.ml\" method=\"post\">
    <input type=\"hidden\" name=\"login\" value=\"" ^ login ^ "\">
    <input type=\"hidden\" name=\"pass\" value=\"" ^ pass ^ "\">
    <input type=\"hidden\" name=\"course\" value=\"" ^ course ^ "\">
    Login of participant to be deleted:
    <input type=\"text\" name=\"userlogin\" value=\"\">
    <input type=\"submit\" value=\"Delete participant\">
    <input type=\"hidden\" name=\"action\" value=\"delete\")
    </form><br /><br />");;

out "<b>Course participants</b><br /><br />";;

out "<table border=1><tr><td><b>Name (login)</b></td><td><b>Not touched</b></td>
     <td style=\"color: red;\"><b>Incomplete</b></td><td style=\"color: orange;\"><b>Correct</b></td><td style=\"color: green;\"><b>Solved</b></td><td>Look</td></tr>"
let tablerow userdata =
  let userlogin = List.hd userdata in
  let slogin , dir = try
    let slash = String.rindex userlogin '/' in
      (String.sub userlogin (slash + 1) (String.length userlogin - slash - 1)),
    (String.sub userlogin 0 slash)
  with _ -> userlogin, ""
  in
    if dir <> course then () else begin
      let files = try (Utils.readdir (chroot ^ "/files/" ^ userlogin)) with _ -> [] in
      let (solved, notcorrect, notcompile, nottouched) = (ref 0, ref 0, ref 0, ref 0) in
      let iterator name =
	if not (List.mem name files) then incr nottouched else
	  if not (List.mem (name ^ "o") files) then incr notcompile else
	    if not (List.mem (name ^ "ok") files) then incr notcorrect else
	      incr solved
      in
	List.iter iterator tasks;
	out ("<tr><td>" ^ (List.hd (List.tl (List.tl userdata))) ^ " (" ^ slogin ^ ")</td><td>" ^ (string_of_int !nottouched) ^ 
	       "</td><td>" ^ (string_of_int !notcompile) ^ "</td><td>" ^ (string_of_int !notcorrect) ^ 
	       "</td><td>" ^ (string_of_int !solved) ^ "</td>\n" ^
               "<td><form action=\"../logged.html\" method=\"post\"><input type=\"hidden\" name=\"adminlogin\" value=\"" ^ login ^ "\"><input type=\"hidden\" name=\"adminpass\" value=\"" ^ pass ^ "\"><input type=\"hidden\" name=\"login\" value=\"" ^ userlogin ^ "\"><input type=\"submit\" value=\"Look\"></form></td></tr>\n");
    end
in
List.iter tablerow users;;


out "</table>";;
out "</body></html>";;






