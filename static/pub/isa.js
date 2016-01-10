var kwd_major = /\.\.|\.|\bML\b|\bML_command\b|\bML_setup\b|\balso\b|\bapply\b|\bapply_end\b|\barities\b|\bassume\b|\bautomaton\b|\bax_specification\b|\baxclass\b|\baxioms\b|\bback\b|\bby\b|\bcannot_undo\b|\bcase\b|\bcd\b|\bchapter\b|\bclasses\b|\bclassrel\b|\bclear_undos\b|\bcode_library\b|\bcode_module\b|\bcoinductive\b|\bcommit\b|\bconstdefs\b|\bconsts\b|\bconsts_code\b|\bcontext\b|\bcorollary\b|\bcpodef\b|\bdatatype\b|\bdeclare\b|\bdef\b|\bdefaultsort\b|\bdefer\b|\bdefer_recdef\b|\bdefs\b|\bdisable_pr\b|\bdisplay_drafts\b|\bdomain\b|\bdone\b|\benable_pr\b|\bend\b|\bexit\b|\bextract\b|\bextract_type\b|\bfinalconsts\b|\bfinally\b|\bfind_theorems\b|\bfix\b|\bfixpat\b|\bfixrec\b|\bfrom\b|\bfull_prf\b|\bglobal\b|\bhave\b|\bheader\b|\bhence\b|\bhide\b|\binductive\b|\binductive_cases\b|\binit_toplevel\b|\binstance\b|\binterpret\b|\binterpretation\b|\bjudgment\b|\bkill\b|\bkill_thy\b|\blemma\b|\blemmas\b|\blet\b|\blocal\b|\blocale\b|\bmethod_setup\b|\bmoreover\b|\bnext\b|\bno_syntax\b|\bnonterminals\b|\bnote\b|\bobtain\b|\boops\b|\boracle\b|\bparse_ast_translation\b|\bparse_translation\b|\bpcpodef\b|\bpr\b|\bprefer\b|\bpresume\b|\bpretty_setmargin\b|\bprf\b|\bprimrec\b|\bprint_antiquotations\b|\bprint_ast_translation\b|\bprint_attributes\b|\bprint_binds\b|\bprint_cases\b|\bprint_claset\b|\bprint_commands\b|\bprint_context\b|\bprint_drafts\b|\bprint_facts\b|\bprint_induct_rules\b|\bprint_interps\b|\bprint_locale\b|\bprint_locales\b|\bprint_methods\b|\bprint_rules\b|\bprint_simpset\b|\bprint_syntax\b|\bprint_theorems\b|\bprint_theory\b|\bprint_trans_rules\b|\bprint_translation\b|\bproof\b|\bprop\b|\bpwd\b|\bqed\b|\bquickcheck\b|\bquickcheck_params\b|\bquit\b|\brealizability\b|\brealizers\b|\brecdef\b|\brecdef_tc\b|\brecord\b|\bredo\b|\brefute\b|\brefute_params\b|\bremove_thy\b|\brep_datatype\b|\bsect\b|\bsection\b|\bsetup\b|\bshow\b|\bsorry\b|\bspecification\b|\bsubsect\b|\bsubsection\b|\bsubsubsect\b|\bsubsubsection\b|\bsyntax\b|\bterm\b|\btext\b|\btext_raw\b|\bthen\b|\btheorem\b|\btheorems\b|\btheory\b|\bthm\b|\bthm_deps\b|\bthus\b|\btoken_translation\b|\btouch_all_thys\b|\btouch_child_thys\b|\btouch_thy\b|\btranslations\b|\btxt\b|\btxt_raw\b|\btyp\b|\btyped_print_translation\b|\btypedecl\b|\btypedef\b|\btypes\b|\btypes_code\b|\bultimately\b|\bundo\b|\bundos_proof\b|\bupdate_thy\b|\bupdate_thy_only\b|\buse\b|\buse_thy\b|\buse_thy_only\b|\busing\b|\bvalue\b|\bwelcome\b|\bwith\b|\{|\}/m;

var astring = /`([^`]|\\`)*`/g; var qstring = /"([^"]|\\")*"/g; var 
comment = /\(\*([^*]|\*[^)])*\*\)/g;

function isok(str) {
  str = str.replace(qstring,"").replace(astring,"").replace(comment,"");
  if (str.indexOf('`') >= 0) return false;
  if (str.indexOf('"') >= 0) return false;
  if (str.indexOf('(*') >= 0) return false;
  return true;
}

function trailingwhitespace (str, res) {
  var r = str.length;
  if (r > 0 && str[r-1] == ' ')
    return (trailingwhitespace (str.substring(0, r - 1), res + 1));
  if (r > 0 && str[r-1] == '\n')
    return (trailingwhitespace (str.substring(0, r - 1), res + 1));
  if (r > 3 && str.substring(r - 4) == '<br>')
    return (trailingwhitespace (str.substring(0, r - 4), res + 4));
  if (r > 3 && str.substring(r - 4) == '<BR>')
    return (trailingwhitespace (str.substring(0, r - 4), res + 4));
  if (r > 4 && str.substring(r - 5) == '<BR/>')
    return (trailingwhitespace (str.substring(0, r - 5), res + 5));
  return res;
}

function one (str) {
  var s = str.split(kwd_major);
  //  alert(s + "****" + s.length);
  if (s.length < 2) return ([-1,-1]);
  var t = s[0];
  var o = 0;
  var r = s[0].length;
  while (!(isok(t))) {
    if (s.length < o+3) return ([-1,-1]);
    t = t + s[o+1] + s[o+2];
    r = r + s[o+1].length + s[o+2].length;
    o = o + 2;
  }
  var n = 0;
  if (s[o+1]) n = s[o+1].length;
  var tomove = trailingwhitespace(t, 0);
  r = r - tomove;
  n = n + tomove;
  return ([r,n]);
}

function fastone (str, start) {
  var m = kwd_major.exec(str.substring(start));
  if (m == null) return ([-1, -1]);
  var pre = str.substring(0, start + m.index);
  if (!(isok(pre))) return (fastone (str, start + m.index + m[0].length));
  var tomove = trailingwhitespace(pre, 0);
  return ([start + m.index - tomove, m[0].length + tomove]);
}

function next (str) {
  str=str.replace(/\{\*/g,"(*").replace(/\*\}/g,"*)");
  var l1 = fastone(str, 0);
  if (l1[0] == (-1)) return 0;
  var l2 = fastone(str.substring(l1[0] + l1[1]), 0);
  if (l2[0] == (-1)) return (str.length - trailingwhitespace(str, 0));
  var t1 = str.substring(0,l1[0]+l2[0]+l1[1]);
  var t2 = str.substring(l1[0]+l2[0]+l1[1]);
  return (l1[0] + l2[0] + l1[1]);
}

function prev (str) {
  return (proved.length + proving.length + provwill.length - 1);
}

function unquote_str (oldstr) {
  var str = oldstr.replace(/<br>/g, ' ').replace(/<br\/>/g, ' ').replace(/\n/g, ' ');
  str = str.replace(/<BR>/g, ' ').replace(/<BR\/>/g, ' ');
  str = str.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&nbsp;/g, " ");
  str = str.replace(/&amp;/g, "&");
  return str;
}

function last(str) {
  var old = provedit.length + 1;
  while (provedit.length < old) {
    old = provedit.length;
    prover_down ();
  }
}

function unicode(str) {
  return str;
}