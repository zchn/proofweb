open Xml;;

type tree = T of string * (string * string) list * (string * tree list) option;;

let rec matchlst rule ass = function
  | [] -> []
  | h :: t ->
      let len = String.length h and rlen = String.length rule in
      if rlen < len then matchlst rule ass t else (
      if String.sub rule 0 len <> h then matchlst rule ass t else (
      let rest = String.sub rule len (rlen - len) in
      let rest = Utils.string_list_of_string rest ' ' in
      let nos = List.map (fun s -> try List.assoc s !ass with _ -> 0) rest in
      List.map (fun n -> n, n) nos))
;;

let rec matchlstname rule ass = function
  | [] -> ""
  | h :: t ->
      let len = String.length h and rlen = String.length rule in
      if rlen < len then matchlstname rule ass t else (
      if String.sub rule 0 len <> h then matchlstname rule ass t else (
      let rest = String.sub rule len (rlen - len) in
      let rest = Utils.string_list_of_string rest ' ' in
      let fil_fun x =
        try ignore (List.find (fun (name, _) -> name = x) ass); true with Not_found -> false
      in
      (String.concat " " (List.filter fil_fun rest))
     ))
;;

let hannos_space s =
  let r p s = Pcre.substitute ~rex:(Pcre.regexp p) ~subst:(fun _ -> s) in
  let s = r "\\\\u2200 " "\\u2200" s in
  let s = r "\\\\u2203 " "\\u2203" s in
  let s = r "\\\\u00ac " "\\u00ac" s in
  let s = r " : " ":" s in
  let subst s =
    let index = String.index s ':' in
    let stype = String.sub s (index + 1) (String.length s - index - 1) in
    let svar = String.sub s 6 (index - 6) in
    let varl = Utils.string_list_of_string svar ' ' in
    "\\u2200" ^ (String.concat (":" ^ stype ^ ", \\u2200") varl) ^ ":" ^ stype
  in
  let s = Pcre.substitute ~rex:(Pcre.regexp "\\\\u2200[^:]*:[a-zA-Z_0-9]*") ~subst s in
  let s = r " in " "\\u2208" s in
  let s = r " [+] " "+" s in
  let s = r " - " "-" s in
  let subst s =
    let index = String.index s ',' in
    let beg = String.sub s 0 index in
    let ends = String.sub s (index + 2) (String.length s - index - 2) in
    beg ^ "," ^ ends
  in
  let s = Pcre.substitute ~rex:(Pcre.regexp "[[{][a-zA-Z0-9+-_ */()]*, [a-zA-Z0-9+-_ */()]*[]}]") ~subst s in
  s
;;

let replacements = [
  "con_in", "con_i";
  "con_e1", "con_ell";
  "con_e2", "con_elr";
  "dis_i1", "dis_inl";
  "dis_i2", "dis_inr";
  "dis_el", "dis_e";
  "imp_in", "imp_i";
  "imp_el", "imp_e";
  "negneg_in", "negneg_i";
  "negneg_el", "negneg_e";
  "dn", "negneg_e";
  "neg_in", "neg_i";
  "neg_el", "neg_e";
  "eqv_in", "eqv_i";
  "eqv_e1", "eqv_ell";
  "eqv_e2", "eqv_elr";
  "fls_el", "fls_e";
  "efq", "fls_el";
  "RAA", "PBC";
  "tnd_axiom", "LEM";
  "equ_in", "equ_i";
  "equ_el", "equ_e";
  "equ_e'", "equ_els";
  "all_in", "all_i";
  "all_el", "all_e";
  "exi_in", "exi_i";
  "exi_el", "exi_e";

  "ass .*",     "ass";
  "copy .*",    "copy";

  "con_i.*",   "∧i";
  "con_ell.*",  "∧e₁";
  "con_elr.*",  "∧e₂";
  "dis_inl.*",  "∨i₁";
  "dis_inr.*",  "∨i₂";
  "dis_e.*",   "∨e";
  "dis_els.*",  "∨e*";
  "imp_i.*",   "→i";
  "imp_e.*",   "→e";
  "negneg_i.*","~~i";
  "negneg_e.*","~~e";
  "neg_i",   "~i";
  "neg_e.*",   "~e";
  "eqv_i.*",   "↔i";
  "eqv_ell.*",  "↔e₁";
  "eqv_elr.*",  "↔e₂";
  "fls_e.*",   "⊥e";
  "tru_i.*",   "\\u22a4i";

  "Dn_axiom.*", "~~A";
  "Neg_els.*",  "~E*";
  "Mt.*",       "Mt";
(*  "PBC.*",      "PBC";*)
  "MT.*",      "MT";
  "Lem.*",      "Lem";
  "all_i.*",   "∀i";
  "all_e.*",   "∀e";
  "exi_i.*",   "∃i";
  "exi_e",   "∃e";
  "exi_els.*",  "∃e*";
  "equ_i.*",   "=i";
  "equ_e.*",   "=e";
  "equ_els.*",  "=e*";

  "insert.*", "insert";

  "f_", "";
  "b_", "";

  " + "," ";
  "[~]","\\u00ac";
  "→", "\\u2192";
  "∨", "\\u2228";
  "∧", "\\u2227";
  "₁", "\\u2081";
  "₂", "\\u2082";
  "∀", "\\u2200";
  "∃", "\\u2203";
  "⊥", "\\u22a5";
];;

let gentzen_rep = [
  "imp_in", "imp_i";
  "imp_i",   "→i";
  "dis_el", "dis_e";
  "dis_e ([(][^)]*[)]|[^ (]*) ", "∨e ";
  "neg_in", "neg_i";
  "neg_i ([(][^)]*[)]|[^ (]*) ", "~i "
];;

let fitch_rep = [
  "neg_i.*", "neg_i";
  "PBC.*",   "PBC"
];;

(* removes first and last args *)
let exi_remove_first_arg gentzen s =
  if String.length s > 6 && String.sub s 0 7 = "\\u2203e" then
    if gentzen then
      let s = Utils.string_list_of_string s ' ' in
      let len = List.length s in
      String.concat " " (List.hd s :: (List.nth s (len - 1)) :: []) (*  :: [List.nth s (len - 2)] *)
    else "\\u2203e"
  else s
;;

let rule_replace gentzen s =
  let replacements = if gentzen then gentzen_rep @ replacements else fitch_rep @ replacements in
  let r t (p, s) = Pcre.substitute ~rex:(Pcre.regexp p) ~subst:(fun _ -> s) t in
  let s = List.fold_left r s replacements in
  let s = exi_remove_first_arg gentzen s in
  let space_to_comma s = Pcre.substitute ~rex:(Pcre.regexp " ") ~subst:(fun _ -> ",") s in
  let cut_first s = String.sub s 1 (String.length s - 1) in
  let s = Pcre.substitute ~rex:(Pcre.regexp " .*") ~subst:(fun s -> "<font color=\"green\">[" ^ space_to_comma (cut_first s) ^ "]</font>") s in
  s
;;

let concl_replace s =
  let r p s = Pcre.substitute ~rex:(Pcre.regexp p) ~subst:(fun _ -> s) in
  let s = r "\\bforall\\b" "\\u2200" s in
  let s = r "\\ball  -\\b" "\\u2200_" s in
  let s = r "\\ball\\b" "\\u2200" s in
  let s = r "\\bexists\\b" "\\u2203" s in
  let s = r "\\bexi  -\\b" "\\u2203_" s in
  let s = r "\\bexi\\b" "\\u2203" s in
  let s = r "/\\\\" "\\u2227" s in
  let s = r "\\\\/" "\\u2228" s in
  let s = r "[~]" "\\u00ac" s in
  let s = r "&lt;->" "\\u2194" s in
  let s = r "->" "\\u2192" s in
  let s = r " + " " " s in
  let s = r "False" "⊥" s in
  let s = r "True" "\\u22a4" s in
  hannos_space s
;;

let mylength s =
  let s2 = Pcre.substitute
      ~rex:(Pcre.regexp "<sup>|</sup>|<font color=\"green\">|</font>|[&]lt|\\\\u[0-9a-f][0-9a-f][0-9a-f]")
      ~subst:(fun _ -> "") s
  in
  String.length s2
;;

let parse_goal_concl = function
  | Xml.Element ("concl", [("type", concl)], []) -> concl
  | _ -> failwith "parse_goal_concl"
;;

let parse_goal_hyp = function
  | Xml.Element ("hyp", [("id", id); ("type", concl)], []) -> id, concl
  | _ -> failwith "parse_goal_hyp"
;;

let parse_rule = function
  | Xml.Element ("rule", ["text", text], []) -> text (*failwith "parse_rule_rule"*)
  | Xml.Element ("cmpdrule", [], subs) ->
      begin match List.hd subs with
      | Xml.Element ("tactic", ["cmd", text], []) -> 
          if (text.[0] = ' ') then String.sub text 1 (String.length text - 1) else text
      | _ -> failwith "parse_rule_tactic"
      end
  | _ -> failwith "parse_rule"
;;

let parse_goal = function
  | Xml.Element ("goal", [], subs) ->
      (parse_goal_concl (List.hd subs)),
      (List.map parse_goal_hyp (List.tl subs))
  | _ -> failwith "parse_goal"
;;

let rec parse_tree = function
  | Xml.Element ("tree", [], subs) ->
      let concl, hyps = parse_goal (List.hd subs) in
      let subtree = parse_subtree (List.tl subs) in
      T (concl, hyps, subtree)
  | _ -> failwith "parse_tree"
and parse_subtree = function
  | [] -> None
  | h :: t -> Some (parse_rule h, List.map parse_tree t)
;;

let rec remove_evar = function
  | T (s, sl, Some ("Evar change", [T (s2, sl2, rest)])) -> T (s2, sl @ sl2, rest)
  | T (s, sl, Some ("Evar change", _)) -> failwith "remove_evar"
  | T (s, sl, (Some (xx, tl))) -> (T (s, sl, (Some (xx, List.map remove_evar tl))))
  | x -> x
;;

let parse_tree x = remove_evar (parse_tree x)

let str_to_box s =
  mylength s, 0, 1, [s]
;;

let print_hyps x =
  let r = String.concat " , " (List.map (fun (x, y) -> x ^ ":" ^ y) x) in
  if r = "" then "" else r ^ " "
;;

let print_hyps_noname x =
  String.concat " , " (List.map (fun (x, y) -> y) x)
;;

let rec make_bar n =
  if n < 1 then "" else "\\u2502" ^ (make_bar (n - 1))
;;

let rec make_line n =
  if n < 1 then "" else "\\u2500" ^ (make_line (n - 1))
;;


let expand_box nw (ow, owr, h, lst) =
  let add = nw - ow in
  let add_r = add / 2 in
  let add_l = add - add_r in
  let add_rs = String.make add_r ' ' in
  let add_ls = String.make add_l ' ' in
  let mapper str = add_ls ^ str ^ add_rs in
  (nw, owr + add_r, h, List.map mapper lst)
;;

let extend_box nw (ow, owr, h, lst) =
  let add = nw - ow in
  let adds = String.make add ' ' in
  let mapper str = str ^ adds in
  (nw, owr + add, h, List.map mapper lst)
;;

let line_boxes rule (w1, r1, h1, s1) (w2, r2, h2, s2) =
  let rule = " " ^ rule in
  let rl = mylength rule in
  let lw = max (w1 - r1) (w2 - r2) in
  let tw = max (max w1 w2) (lw + rl) in
  let w1e = min (lw - w1 + r1) (tw - w1) in
  let (w1, r1, _, s1) = if w1e > 0 then expand_box (w1 + w1e) (w1, r1, h1, s1) else (w1, r1, 0, s1) in
  let w2e = min (lw - w2 + r2) (tw - w2) in
  let (w2, r2, _, s2) = if w2e > 0 then expand_box (w2 + w2e) (w2, r2, h2, s2) else (w2, r2, 0, s2) in
  let (w1, r1, _, s1) = if w1 < tw then extend_box tw (w1, r1, h1, s1) else (w1, r1, 0, s1) in
  let (w2, r2, _, s2) = if w2 < tw then extend_box tw (w2, r2, h2, s2) else (w2, r2, 0, s2) in
  let r = min (min r1 r2) (tw - lw) in
  let rs = (make_line lw) ^ rule ^ String.make (tw - lw - rl) ' ' in
  (tw, r, h1 + h2 + 1, s1 @ (rs :: s2))
;;

let height_expand nh (w, r, h, s) =
  let rec make n = if n = 0 then [] else (String.make w ' ') :: (make (n - 1)) in
  (w, r, nh, (make (nh - h)) @ s)
;;

let concat_boxes lst =
  let max_height = List.fold_left (fun mh (_,_,h,_) -> max mh h) 0 lst in
  let lst = List.map (height_expand max_height) lst in
  let w = if lst = [] then 0 else List.fold_left (fun mw (w,_,_,_) -> w + mw + 1) (-1) lst in
  let ss = List.map (fun (_, _, _, l) -> l) lst in
  let rec flater lst =
    match List.hd lst with
    | [] -> []
    | _ -> (String.concat " " (List.map List.hd lst)) :: (flater (List.map List.tl lst))
  in
  let (_, r, _, _) = if ss = [] then (0, 0, 0, []) else List.hd (List.rev lst) in
  (w, r, max_height, (if ss = [] then [] else flater ss))
;;

let clean_concl concl =
  let concl = Pcre.substitute ~rex:(Pcre.regexp "^\n[ ]*") ~subst:(fun _ -> "") concl in
  let concl = Pcre.substitute ~rex:(Pcre.regexp "\n[ ]*") ~subst:(fun _ -> " ") concl in
  concl_replace (Utils.replace "ipattern:" "" concl)
;;

let clean_rule gentzen rule =
  let rule = Pcre.substitute ~rex:(Pcre.regexp "^\n[ ]*") ~subst:(fun _ -> "") rule in
  let rule = Pcre.substitute ~rex:(Pcre.regexp "\n[ ]*") ~subst:(fun _ -> " ") rule in
  rule_replace gentzen (Utils.replace "ipattern:" "" rule)
;;

let clean_hyps hyps =
  let l1, l2 = List.split hyps in
  let l2 = List.map clean_concl l2 in
  List.combine l1 l2
;;

let fwd_rules = ["f_con_i "; "f_con_e1 "; "f_con_e2 "; "f_dis_i1 "; "f_dis_i2 "; "f_imp_e "; "f_neg_e "; "f_fls_e "; "f_negneg_i "; "f_negneg_e "; "f_MT "; "f_all_e "; "f_exi_i "; "f_equ_i "; "f_equ_e "];;

let rec print_tree gentzen ohyps = function
  | T (concl, hyps, None) ->
      let assums = if gentzen then (print_hyps (clean_hyps (ohyps @ hyps)) ^ "\\u22a2 ") else "" in
      line_boxes ""
        (str_to_box "...")
        (str_to_box (assums ^ (clean_concl concl)))
  | T (concl, hyps, Some (rule,lst)) ->
      let assums = if gentzen then (print_hyps (clean_hyps (ohyps @ hyps)) ^ "\\u22a2 ") else "" in
      let hyps = ohyps @ hyps in
      if matchlst rule (ref []) ["insert "] <> [] then
        let arg = clean_concl (List.hd (List.tl (Utils.string_list_of_string rule ' '))) in
        (match lst with
        | [T(sproofconcl, _, _) as sideproof; T(proofconcl, _, _) as proof] ->
            let proof, sideproof = print_tree gentzen hyps proof, print_tree gentzen hyps sideproof in
            let proofconcl, sproofconcl = clean_concl proofconcl, clean_concl sproofconcl in
            line_boxes "\\u2192e"
              (concat_boxes 
                 [ line_boxes ("\\u2192i<font color=\"green\">[" ^ arg ^ "]</font>")
                     (proof)
                     (str_to_box ("(" ^ assums ^ sproofconcl ^ ") \\u2192 " ^ proofconcl))
                     ; sideproof
                 ])
              (str_to_box (assums ^ (clean_concl concl)))
        | _ -> failwith "wrong insert"
        )
      else if matchlst rule (ref []) ["ass "; "copy "; "exact "] <> [] then
        let args = List.tl (Utils.string_list_of_string rule ' ') in
        let types = List.map (fun a -> "[" ^ (try List.assoc a (clean_hyps hyps) with _ -> "?") ^ "]<sup><font color=\"green\">" ^ a ^ "</font></sup>") args in
        let s = String.concat " " types in
        (str_to_box s)
      else let up = if matchlst rule (ref []) fwd_rules <> [] then 
        let args = List.tl (Utils.string_list_of_string rule ' ') in
        let types = List.map (fun a -> "[" ^ (try List.assoc a (clean_hyps hyps) with _ -> "?") ^ "]<sup><font color=\"green\">" ^ a ^ "</font></sup>") args in
        let s = String.concat " " types in
        (str_to_box s) 
      else 
        let mnos = matchlst rule (ref []) ["f_dis_e "; "f_exi_e "] in
        let lst =
          if mnos = [] then lst else
          (Utils.log "in";
           (T ("", [], Some ("copy " ^ (matchlstname rule hyps ["f_dis_e "; "f_exi_e "]), []))) :: lst
          )
        in
        (concat_boxes (List.map (print_tree gentzen hyps) lst))
      in
      line_boxes (clean_rule true rule) up (str_to_box (assums ^ (clean_concl concl)))

;;



type fitch = Concl of int * string * string * string | Box of fitch list * fitch list | Dots;;

let phyp no ass text (label, concl) =
  if concl = "D" then Concl (-1, "", label, "") else (
  incr no;
  ass := (label, !no) :: (List.remove_assoc label !ass);
  Concl (!no, clean_concl concl, ("<font color='green'>" ^ label ^ ":&nbsp;</font>"), if text = "" then "assumption" else text))
;;

let pconcl no concl rule oldconcl label =
  if concl = oldconcl then [] else begin
    incr no;
    let label = if label = "" then label else "<font color='green'>" ^ label ^ ":&nbsp;</font>" in
    [Concl (!no, clean_concl concl, label, rule)]
  end
;;

let print_nos x =
  let iterator (x, y) = if x = y then string_of_int x else string_of_int x ^ "-" ^ string_of_int y in
  String.concat "," (List.map iterator x)
;;


  



let rec print_fitch_tree no ass oldconcl oldrule label (T (concl, hyps, ruleopt)) =
  let startno = !no in
  let ph = List.map (phyp no ass !oldrule) hyps in
  let nos, rule, pr, doconcl, possconcl = prule no ass concl oldrule ruleopt in
  let doconcl = if not doconcl && possconcl then match hyps with
  | [] -> false
  | [(label, value)] -> concl <> oldconcl && value <> concl
  | _ -> concl <> oldconcl
  else doconcl in
  let pc = if doconcl then pconcl no concl (clean_rule false rule ^ " " ^ print_nos nos) oldconcl label else [] in
  if concl <> oldconcl && hyps <> [] then ((*Utils.log "b %i %i [%s] {%s} '%s'%s'\n%!" startno !no rule (print_nos nos) concl oldconcl; *)[startno + 1, !no], [Box (ph, pr @ pc)])
  else 
    let nos = if doconcl then [!no, !no] else nos in
(*    (Utils.log "i: %i [%s] {%s}\n%!" !no rule (print_nos nos);*) nos, (ph @ pr @ pc)
and prule no ass oldconcl oldrule = function
  | None -> [], "", [Dots], true, true
  | Some (rule, trees) ->
      let trees, doconcl, possconcl, rets, oldconcl =
        if String.length rule > 6 && String.sub rule 0 7 = "insert " then match trees with
        | [t1; T(c2, h2, r2)] -> 
            let label = fst (List.hd h2) in
            let ((nos, _) as rets) = print_fitch_tree no ass oldconcl oldrule label t1 in
            (try ass := (label, int_of_string (print_nos [(List.hd nos)])) :: !ass with _ -> (*Utils.log "[[%s]]\n%!" (print_nos nos)*) () ); 
            [T(c2, [], r2)], false, false, [rets], "." ^ oldconcl
        | _ -> trees, true, true, [], oldconcl
        else trees, true, true, [], oldconcl
      in
      let mnos = matchlst rule ass ["ass "; "copy "; "exact "] in
      if mnos <> [] then (mnos, rule, [], false, true) else
      let mnos = matchlst rule ass ["f_con_i "; "f_con_e1 "; "f_con_e2 "; "f_dis_i1 "; "f_dis_i2 "; "f_imp_e "; "f_neg_e "; "f_fls_e "; "f_negneg_i "; "f_negneg_e "; "f_MT "; "f_all_e "; "f_exi_i "; "f_equ_i "; "f_equ_e "] in
      if mnos <> [] then (mnos, rule, [], true, true) else
      let mnos = matchlst rule ass ["f_dis_e "; "f_exi_e "] in
      let trees = 
        if mnos = [] then trees else
        (T ("", [], Some ("copy " ^ (matchlstname rule !ass ["f_dis_e "; "f_exi_e "]), []))) :: trees
      in
      let l1, l2 = List.partition (fun (T (concl, _, _)) -> concl = oldconcl) trees in
      let oldconcl = if l1 = [] || (l2 = [] && List.length l1 = 1) then oldconcl else "." ^ oldconcl in
      let rets = rets @ (List.map (print_fitch_tree no ass oldconcl oldrule "") trees) in
      let nos, rets = List.split rets in
      let rets = List.fold_left (@) [] rets in
      let nos = List.concat nos in
      nos, rule, rets, doconcl, possconcl
;;

let rec print_fitch level = function
  | Dots -> [-1, make_bar level ^ ".....", "", ""]
  | Concl (a, b, c, d) -> [a, make_bar level ^ b, c, d]
  | Box (hyps, deds) ->
      (List.concat (List.map (print_fitch (level + 1)) hyps)) @
      [-1, make_bar level ^ "\\u251c\\u2500\\u2500\\u2500\\u2500\\u2500", "", ""] @
      (List.concat (List.map (print_fitch (level + 1)) deds))
;;

let print_fitch t =
  let cnt, lst = print_fitch_tree (ref 0) (ref []) "" (ref "") "" t in
  let lst = List.concat (List.map (print_fitch 0) lst) in
  let len = String.length (string_of_int (List.length lst)) in
  let lens = List.map (fun (_,a,_,_) -> mylength a) lst in
  let len2 = List.fold_left (max) 0 lens in
  let lens = List.map (fun (_,_,a,_) -> mylength a) lst in
  let len3 = List.fold_left (max) 0 lens in
  let mapper (n, s, h, r) =
    let n = string_of_int n in
    let l = String.length n in
    let n =
      if n = "-1" then String.make len ' ' else
      if l < len then (String.make (len - l) ' ') ^ n else n
    in
    let l = mylength s in
    let l3 = mylength h in
    n ^ " " ^ s ^ (String.make ((1 + len2) - l) ' ') ^ " " ^ h ^ (String.make ((1 + len3) - l3) ' ') ^ " " ^ r
  in
  String.concat "\n" (List.map mapper lst)
;;

(* html version *)
let print_fitch t = 
  let _, lst = print_fitch_tree (ref 0) (ref []) "" (ref "") "" t in
  let lst =
    match lst with
    | [Box (a, t)] -> 
        let folder acc = function
          | Concl (a, b, c, "") -> acc
          | Concl (a, b, c, _) -> Concl (a, b, c, "premise") :: acc
          | x -> x :: acc
        in
        (List.fold_left folder [] a) @ t
    | _ -> lst
  in
  let maxlist = List.fold_left max 0 in
  let rec maxdepth = function
    | Dots -> 0
    | Concl _ -> 0
    | Box (x, y) -> 1 + max (maxlist (List.map maxdepth x)) (maxlist (List.map maxdepth y))
  in
  let depth = maxlist (List.map maxdepth lst) in
  let draw top bottom left txt =
    let style = 
      (if top then "border-top:1px solid black;" else "") ^
      (if bottom then "border-bottom:1px solid black;" else "") ^
      (if left then "border-left:1px solid black;" else "")
    in "<td" ^ (if style = "" then ">" else " style='" ^ style ^ "'>") ^ 
    (if txt = "" then "&nbsp;" else txt) ^ "</td>"
  in
  let rec line top bottom left more b c d =
    if more < 2 then (* For 0 and 1 we dont need additional levels, just maybe a box *)
      (draw (top <= 1) (bottom <= 1) (left > 0) b) ^
      (draw (top <= 1) (bottom <= 1) false c) ^
      (draw (top <= 1) (bottom <= 1) false d) ^ "</tr>"
    else
      (draw (top <= 1) (bottom <= 1) (left > 0) "") ^
      (line (top - 1) (bottom - 1) (left - 1) (more - 1) b c d)
  in
  let rec printer top bottom level = function
    | Dots -> "<tr><td></td><td></td>" ^ (line top bottom level depth "" "..." "")
    | Concl (a, c, b, d) -> "<tr><td align=right>" ^ (if a < 0 then "" else string_of_int a) ^ "&nbsp;</td><td></td>" ^ (line top bottom level depth b c ("&nbsp; " ^ d))
    | Box (hyps, deds) ->
        let level = level + 1 in
        let lst = hyps @ deds in match lst with
        | [] -> "FAILURE"
        | h :: [] -> printer (min top level) (min bottom level) level h
        | h :: t -> (printer (min top level) 1000 level h) ^ "\n" ^
            begin match List.rev t with
            | [] -> "FAILURE2"
            | h :: t -> (String.concat "\n" (List.map (printer 1000 1000 level) (List.rev t))) ^ "\n" ^
                (printer 1000 (min bottom level) level h)
            end
  in
  let s = " <style> table {border-collapse:collapse;} td {white-space: nowrap;} </style><table cellpadding=0 cellspacing=0>\n" ^ (String.concat "\n" (List.map (printer 1000 1000 0) lst)) ^ "\n</table>" in
  s
;;

let print_natural t =
  let _, _, _, b = print_tree false [] t in
  String.concat "\n" b
;;

let print_gentzen t =
  let _, _, _, b = print_tree true [] t in
  String.concat "\n" b
;;

