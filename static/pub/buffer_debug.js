var proved="";
var proving="";
var provwill="";
var sent=false;
var doc_edit;
var doc_state;
var doc_error;
var active=0;
var electric=false;

function all_load () {
//  alert('0');
  try{doc_edit=get_frame("frame_edit");} catch(e) {setTimeout("all_load();",10); return;}
  doc_edit.open ();
  doc_edit.write(initial);
  doc_edit.close ();
  if (design=="true") {
    doc_edit.designMode = "On";
  }
  try {doc_edit.body.setAttribute("spellcheck",false);} catch (e) {}
//  alert('a');
  try{doc_error=get_frame("frame_error");} catch(e) {setTimeout("all_load();",10); return;}
  //doc_error=get_frame("frame_error");
  doc_error.open();
  doc_error.write(initial_empty);
  doc_error.close();
  //alert('b');
  try{doc_input=get_frame("frame_input");} catch(e) {setTimeout("all_load();",10); return;}
  doc_input.open();
  doc_input.write(initial_empty);
  doc_input.close();

  try{doc_output=get_frame("frame_output");} catch(e) {setTimeout("all_load();",10); return;}
  //doc_output=get_frame("frame_output");
  doc_output.open();
  doc_output.write(initial_empty);
  doc_output.close();

  try{doc_state=get_frame("frame_state");} catch(e) {setTimeout("all_load();",10); return;}
  //doc_state=get_frame("frame_state");
  doc_state.open();
  doc_state.write(initial_empty);
  doc_state.close();

  try {
    set_event(doc_edit, "onmouseup", deactivate_menu);
    set_event(document, 'onkeypress', kb_handler);
    set_event(doc_state, 'onkeypress', kb_handler);
    set_event(doc_error, 'onkeypress', kb_handler);
    set_event(doc_edit, 'onkeypress', kb_handler);
  } catch (e){setTimeout("active=1; alert('Cannot set key handlers in IE, active polling used...'); set_all(provedit);",10);}
  post_load ();
}

function deactivate_menu () {
  setTimeout("domMenu_deactivate('domMenu_BJ')", 10);
  need_getedit=true;
  need_tidy=true;
}

var need_tidy=true;
var need_getedit=false;

function remove_sec (name, str) {
  var index = str.indexOf('<span id=\"' + name + '\"');
  if (index == -1) index = str.indexOf("<SPAN id=" + name);
  if (index == -1) index = str.indexOf('<SPAN id=\"' + name + '\"');
  if (index == -1) return str;
  var newstr = str.substring(index);
  var index2 = newstr.indexOf('</span>');
  if (index2 == -1) index2 = newstr.indexOf("</SPAN>");
    if (index2 == -1) return str.substring(0, index);
  return (str.substring (0, index) + newstr.substring(index2 + 7));
}

function set_all (edit) {
  var all;
  if ((document.all) && (domLib_userAgent.indexOf('opera') == -1)) {
    all  = "<PRE><SPAN id=ed>"   + proved   + "</SPAN>";
    all += "<SPAN id=ing>"  + proving  + "</SPAN>";
    all += "<SPAN id=will>" + provwill + "</SPAN>";
    all += "<SPAN id=edit>" + provedit + "</SPAN>";
    all += "</PRE>"
    if (all.toLowerCase() != doc_edit.body.innerHTML.toLowerCase()) {
      alert("A-" + doc_edit.body.innerHTML.toLowerCase());
      alert("A+" + all.toLowerCase());
      doc_edit.body.innerHTML = all;
      set_cursor();
    }
  } else {
    all = "<pre>";
    if ((proved   != "") || (domLib_isOpera == 0)) all += '<span id="ed">'   + proved   + "</span>";
    if ((proving  != "") || (domLib_isOpera == 0)) all += '<span id="ing">'  + proving  + "</span>";
    if ((provwill != "") || (domLib_isOpera == 0)) all += '<span id="will">' + provwill + "</span>";
    if (provedit != "") {all += '<span id="edit">' + provedit + '</span></pre>';}
    else {all += '<span id="edit"><br></span></pre>';}
    if (all.toLowerCase().replace(/\n/g,"<br>").replace(/<br class="webkit-block-placeholder">/,"<br>") != doc_edit.body.innerHTML.toLowerCase().replace(/\n/g,"<br>").replace(/<br class="webkit-block-placeholder">/,"<br>")) {
      alert("A-" + doc_edit.body.innerHTML.toLowerCase());
      alert("A+" + all.toLowerCase());
      doc_edit.body.innerHTML = all;
      set_cursor();
    }
  }
}

function set_part (name, content) {
  try {
    if (doc_coq.getElementById(name).innerHTML.replace(/\n/g,"").replace(/<br class="webkit-block-placeholder">/,"<br>") != content.replace(/\n/g,"").replace(/<br class="webkit-block-placeholder">/,"<br>")) {
      alert("PA" + doc_edit.body.innerHTML.toLowerCase());
      alert("P-" + doc_coq.getElementById(name).innerHTML.replace(/\n/g,""));
      alert("P+" + content.replace(/\n/g,""));
      doc_coq.getElementById(name).innerHTML = content;
      set_cursor ();
    }
  } catch (e) {
  }
}

function tidy_iframe () {
  if ((need_getedit == true) || (active == 1)) {
    provedit = get_edit ();
    need_getedit = false;
  }
  set_part ("ed", proved);
  set_part ("ing", proving);
  set_part ("will", provwill);
  // If only edit changed try not to loose the cursor position
  set_part ("edit", provedit);
  set_all (provedit);
  try {document.editform.wpTextbox1.value = proved + proving + provwill + provedit; } catch (e){}
}

function get_edit () {
  var all = doc_edit.body.innerHTML;
  //  alert("GET1: " + all);
  all = remove_sec ("ed", all);
  all = remove_sec ("ing", all);
  all = remove_sec ("will", all);
  //TODO IE add BRs and remove SPANS
  all = all.replace(/<span[^>]*>/g, '').replace(/<P>/g, '<BR>').replace(/<p>/g, '<br>').replace(/\xA0/g, ' ');
  all = all.replace(/<\/span>/g, '').replace(/<\/P>/g, '').replace(/<\/p>/g, '');
  all = all.replace(/<SPAN[^>]*>/g, '').replace(/<\/SPAN>/g, '');
  all = all.replace(/<pre[^>]*>/g, '').replace(/<\/pre[^>]*>/g, '').replace(/<PRE[^>]*>/g,'').replace(/<\/PRE[^>]*>/g,'');
  all = all.replace(/&nbsp;/g, ' ').replace(/<font[^>]*>/g, '').replace(/<\/font>/g,'');
  all = all.replace(/<FONT[^>]*>/g, '').replace(/<\/FONT>/g,'');
  //  alert("GET2: " + all);
  return all;
}

function kb_handler(evt) {
  if (evt.ctrlKey) {
    if (evt.keyCode == 40 || evt.keyCode == 10) { //DOWN_ARROW
      prover_down();
      try {
        evt.preventDefault();
        evt.stopPropagation();
      } catch (e) {}
    } else if (evt.keyCode == 38) { //UP_ARROW
      prover_up();
      evt.preventDefault();
      evt.stopPropagation();
    } else if (evt.keyCode == 34) { //PGDN
      prover_bottom();
      evt.preventDefault();
      evt.stopPropagation();
    } else if (evt.keyCode == 33) { //PGUP
      prover_top();
      evt.preventDefault();
      evt.stopPropagation();
    } else if (evt.keyCode == 13) { //ENTER
      prover_point();
      evt.preventDefault();
      evt.stopPropagation();
    } else {
//      alert(evt.keyCode);
      need_getedit=true;
    }
    need_tidy=true;
  } else {
    need_getedit=true;
    need_tidy=true;
  }
  if (electric==true && prover=="coq" && evt.charCode == 46) {setTimeout("tidy_iframe (); prover_point ();", 1);}
}

function time_tider () {
  if ((need_tidy==false) && (active==0)) {
  } else try {
    tidy_iframe ();
    need_tidy=false;
  } catch (e) {}
  setTimeout("time_tider ()", 10);
}

var initial='\
<html><head>\
<style>\
  span#ed {background-color:#CFFFCF;}\
  span#ing{background-color:#BFBFFF;}\
  span#will{background-color:#FFFF8F;}\
</style>\
</head><body id="all">\
<span id="ed"></span>\
<span id="ing"></span>\
<span id="will"></span>\
<span id="edit"><br> <br></span>\
</body></html>';

var initial_empty='<html><head></head><body></body></html>';

function template (arg) {
  if (document.all) {
    if (doc_edit.selection.createRange().parentElement() == doc_edit.getElementById("edit"))
      try {doc_edit.selection.createRange().pasteHTML(arg);}
      catch (e) {}
    else alert ("Please first select location");
  } else {
    doc_edit.execCommand('insertHTML', false, arg);
  }
  need_getedit=true;                                                                                                                      
  need_tidy=true; 
//  provedit=get_edit ();
//  if (active == 1) set_part ("edit", provedit);
}

function toggle_electric () {
  electric = !electric;
}
