if (user.substr(0,3) == "il/") trees = 2;
//if (user.substr(0,4) == "pca/") trees = 2;
if (user.substr(0,3) == "bb/") trees = 1;
if (user.substr(0,7) == "g5200a/") trees = 2;

function prover_down () {
  var index = next(provedit);
  if (index == 0) return;
  var sendtext = provedit.substring(0, index);
  provedit = provedit.substring(index);
  if (active == 1) set_part ("edit", provedit);
  provwill += sendtext;
  need_tidy=true;
  prover_send_if_can ();
}

function prover_bottom () {
  var index = last(provedit);
  if (index == 0) return;
  var sendtext = provedit.substring(0, index);
  provwill += sendtext;
  provedit = provedit.substring(index);
  if (active == 1) set_part ("edit", provedit);
  need_tidy=true;
  prover_send_if_can ();
}

var token = "__PWT__";

function prover_send_if_can () {
  if (sent == true) return;
  if (provwill == '') {
    if ((trees == 1) && (provwill == '') && (proving == '')) {
      return (query("Dump Natural Deduction"));
    }
    if ((trees == 2) && (provwill == '') && (proving == '')) {
      return (query("Dump Fitch Deduction"));

    }
    if ((trees == 3) && (provwill == '') && (proving == '')) {
      return (query("Dump Gentzen Deduction"));
    }
    return;
  }
  var pos = proved.length + proving.length;
  var text = '' + pos;
  while (provwill != '') {
    var index = next(provwill);
    if (index == 0) break;
    pos = pos + index;
    text = text + token + provwill.substring(0, index) + token + pos;
    proving = proving + provwill.substring(0, index);
    provwill = provwill.substring(index);
  }
  tosend = (unquote_str(text));
  myx_say(tosend, undo_cb);
  need_tidy=true;
}

function myx_say () {
  sent = true;
  doc_edit.designMode = "Off";
  ajax_call("addtobuf", myx_say.arguments);
}

function myx_listen () {
  sent = true;
  doc_edit.designMode = "Off";
  ajax_call("listen", myx_listen.arguments);
}

function myx_undo () {
  sent = true;
  doc_edit.designMode = "Off";
  ajax_call("undo", myx_undo.arguments);
}

function undo_cb(z) {
  if (z == "") { myx_listen (undo_cb); return; }
  if (z == "+") {
    provedit = proving + provwill + provedit;
    proving = ""; provwill = "";
    need_tidy=true; sent = false;
    doc_edit.designMode = "On";
    return;
  }
  var index = z.indexOf ("__PWT__");
  var out = "<pre>" + z.substring(0, index) + "</pre>";
  var out = unicode(out);
  get_frame("frame_state").body.innerHTML = out;
  var rest = z.substring(index + 7);
  index = rest.indexOf ("__PWT__");
  get_frame("frame_error").body.innerHTML = "<pre>" + unicode(rest.substring(index + 7)) + "</pre>";
  rest = rest.substring(0, index);
  sent = false;
  doc_edit.designMode = "On";
  if (proved.length > rest) {
    provedit = proved.substring(rest) + proving + provwill + provedit;
    proved = proved.substring(0, rest); proving = ""; provwill = "";
  } else if (proved.length == rest) {
    provedit = proving + provwill + provedit;
    proving = ""; provwill = "";
  } else {
    var tocut = rest - proved.length;
    proved = (proved + proving).substring(0, rest);
    proving = proving.substring(tocut);
  }
  need_tidy=true;
  if (proving == "") prover_send_if_can ();
  else myx_listen (undo_cb);
}

function prover_up () {
  if (sent == true) return;
  var index = 0;
  if (provwill != "") {
    index = proved.length + proving.length + prev(provwill);
  } else if (proving != "") {
    index = proved.length + prev(proving);
  } else if (proved != "") {
    index = prev(proved);
  }
  myx_undo (index, undo_cb);
}

function prover_top () {
  if (sent == true) return;
  myx_undo (0, undo_cb);
}

function get_cursor () {
  var sel = document.getElementById("frame_edit").contentWindow.getSelection();
  var range = sel.getRangeAt(0);
  var finder = document.createTextNode("\001");
  range.insertNode(finder);
  var all = doc_edit.body.innerHTML;
  all = all.replace(/<span[^>]*>/g, '').replace(/<P>/g, '');
  all = all.replace(/<\/span>/g, '').replace(/<\/P>/g, '<BR>');
  all = all.replace(/<SPAN[^>]*>/g, '').replace(/<\/SPAN>/g, '');
  all = all.replace(/<pre>/g, '').replace(/<\/pre>/g, '');
  var index = all.indexOf("\001");
  set_part("edit", provedit);
  need_tidy=true;
  return index;
  //alert(index);
  //return 0;
}

function set_cursor_real () {
  if (document.all) return;
  var sel = document.getElementById("frame_edit").contentWindow.getSelection();
  sel.removeAllRanges();
  var range = doc_edit.createRange();
  range.setStart(doc_edit.getElementById("edit"), 0);
  range.setEnd(doc_edit.getElementById("edit"), 0);
  sel.addRange(range);
}


function set_cursor () {
  setTimeout("set_cursor_real ();", 10);
}

function prover_point () {
  if (document.all) return;
  if (sent == true) return;
  var len = get_cursor();
  if (len < proved.length) {
    myx_undo (len, undo_cb);
    set_cursor ();
    return;
  }
  len = len - proved.length - proving.length - provwill.length;
  var old = provedit.length;
  if (len > 0) prover_down ();
  while ((provedit.length < old) && (len > 0)) { // No infinite loop
  len = len + provedit.length - old;
    old = provedit.length;
    if (len > 0) prover_down ();
  }
  set_cursor ();
}

function myx_save () {
  ajax_call("save", myx_save.arguments);
}

function prover_save () {
  if (file_name == null || file_name == "") return (prover_save_as ());
  var tosend = proved + proving + provwill + provedit;
  myx_save(file_name + "*" + tosend, prover_save_ok);
}

function prover_save_as () {
  var name = prompt ("Please select name under which you wish your prover buffer contents to be saved on server. Please include the extension.", file_name);
  if (name == null || name == "") return;
  file_name = name;
  document.title = (file_name + " - WebProof");
  prover_save ();
}

function prover_save_ok (arg) {
  if (arg == "+") alert ("Saved ok");
  else alert (arg);
}

function prover_load () {
  document.gateway.submit();
}

function query (qry) {
  if (sent == true) return;
  var pos = proved.length + proving.length;
  var text = '' + pos;
  var index = qry.length;
  pos = pos + index;
  text = text + token + qry + token + pos;
  tosend = (unquote_str(text));
  myx_say(tosend, query_cb);
}

function query_ask () {
  var qry = prompt ("Query command:", "Show.");
  if ((qry == "") || (qry.indexOf('.') == -1)) return;
  query(qry);
}

function query_cb(z) {
  if (z == "") { myx_listen (query_cb); return; }
  var index = z.indexOf ("__PWT__");
  var rest = z.substring(index + 7);
  var index2 = rest.indexOf ("__PWT__");
  var out = "<pre>" + unicode(z.substring(0, index)) + unicode(rest.substring(index2 + 7)) + "</pre>";
  get_frame("frame_error").body.innerHTML = out;
  sent = false;
  myx_undo (proved.length, query_undo_cb);
}

function query_undo_cb(z) {
  if (z == "") { myx_listen (query_undo_cb); return; }
  sent = false;
  doc_edit.designMode = "On";
  set_cursor();
  if (provwill != '') prover_send_if_can ();
}

function set_trees(z) {
  trees = z;
  if ((trees == 1) && (provwill == '') && (proving == '')) {query("Dump Natural Deduction");}
  if ((trees == 2) && (provwill == '') && (proving == '')) {query("Dump Fitch Deduction");}
  if ((trees == 3) && (provwill == '') && (proving == '')) {query("Dump Gentzen Deduction");}
}

function unload() {
  ajax_call("quit", "");
}

window.onbeforeunload = confirmExit;
function confirmExit() {
  return "You have attempted to leave ProofWeb.  If you have made any changes to the buffer without clicking the Save button, your changes will be lost.  Are you sure you want to exit this page?";
}
