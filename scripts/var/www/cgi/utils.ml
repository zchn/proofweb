let string_list_of_string str sep =
  let rec slos_aux str ans =
    if str = "" then List.rev ans else
    try
      let first_space = String.index str sep in
      if first_space = 0 then
        slos_aux (String.sub str 1 (String.length str - 1)) ans
      else
        slos_aux
          (String.sub str (first_space + 1)(String.length str - 1 - first_space))
          ((String.sub str 0 (first_space)) :: ans)
    with
      Not_found ->
        List.rev (str :: ans)
  in slos_aux str []
;;

let read_comma_separated name =
  let inc = open_in name in
  let rec read_aux a =
    try
      let line = input_line inc in
      let s = string_list_of_string line ',' in
      read_aux (s :: a)
    with End_of_file -> a
  in
  let ret = read_aux [] in
  close_in inc;
  ret
;;

let authenticate get = try
  let login = get "" "login" in
  let pass = get "" "pass" in
  let admin_logins = read_comma_separated "/substa/admin_logins" in
  let admin_logins = List.map (fun x -> (List.hd x, (List.hd (List.tl x)))) admin_logins in
  let goodpass = List.assoc login admin_logins in
  goodpass = Digest.to_hex (Digest.string pass)
  with _ -> false
;;

let readdir dir =
  let handle = Unix.opendir dir in
  let lst = ref [] in
  (try while true do lst := Unix.readdir handle :: !lst done with _ -> ());
  Unix.closedir handle;
  List.sort compare (List.filter (fun x -> x.[0] <> '.') !lst)
;;
