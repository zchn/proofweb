function my_index (str) {
  if (prover == "lego" || prover == "plastic" || prover == "isa")
    return str.replace(/&amp;/g,'&amp&').replace(/&lt;/g,'&lt&').replace(/&gt;/g,'&gt&').replace(/&quot;/g,'&quot&').replace(/&apos;/g, '&apos&').indexOf(";")
  else if (prover == "matita") return str.replace(/\lambda([^.]*)[.]/g,"______$1_").replace(/\\forall([^.]*)[.]/g,"_______$1_").replace(/\\exists([^.]*)[.]/g,"_______$1_").replace(/\cic:\/([^.]*)[.]/g,"______$1_").indexOf(".")
  else return str.indexOf(".");
}

function unquote_str (oldstr) {
  var str = oldstr.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&apos;/g, "'").replace(/&amp;/g, "&").replace(/<br>/g,"\n").replace(/<BR>/g,"\n").replace(/<BR\/>/g,"\n");
  return str;
}

function count (str, pat) {
  var arr = str.split (pat);
  return (arr.length);
}

function coq_undot(str) {
  return str.replace(/Undo.Undo/g, 'Undo. ndo').replace(/[.][.][.]/g, '__.').replace(/[.][.]/g, '__').replace(/[.][a-zA-Z1-9_]/g, 'AA');
}

function coq_find_dot (str, toclose) {
  var index = my_index(str);
  if (index == -1) return index;
  var tocheck = str.substring (0, index);
  var opened = count (tocheck, "(*") + toclose - count (tocheck, "*)");
  if (opened <= 0) {
    return index;
  } else {
    var newindex = coq_find_dot (str.substring(index + 1), opened);
    if (newindex == -1) return (-1);
    return (index + newindex + 1);
  }
}  

function coq_get_last_dot(str) {
  var modified = str;
  var index = -1;
  while (my_index(modified) >= 0) {
    index = my_index(modified);
    modified = modified.substring(0, index) + " " + 
      modified.substring(index + 1);
  } 
  return index;
}

function coq_find_last_dot (str, toopen) {
  var index = coq_get_last_dot(str);
  if (index == -1) return index;
  var tocheck = str.substring (index + 1);
  var closed = count (tocheck, "*)") + toopen - count (tocheck, "(*");
  if (closed <= 0) {
    return index;
  } else {
    var newindex = coq_find_last_dot (str.substring(0, index), closed);
//    alert(index);
//    alert(newindex);
    return (newindex);
  }
}  

function next(str) {
  return (coq_find_dot (coq_undot(str), 0) + 1);
}

function last(str) {
  return (coq_get_last_dot(str) + 1);
}

function prev(str) {
  return (coq_find_last_dot(coq_undot(str.substring(0,str.length - 1)), 0) + 1);
}

function unicode(str) {
  if (prover == "matita") {
    var str = str.replace(/\\forall /g,"∀");
    var str = str.replace(/\\exists /g,"∃");
    var str = str.replace(/\\not /g,"̸");
    var str = str.replace(/\\rarr /g,"→");
    var str = str.replace(/\\land /g,"\u2227");
    var str = str.replace(/\\lor /g,"\u2228");
    var str = str.replace(/\\lnot /g,"¬");
    return str;
  }
  if (prover == "coq" || prover == "coqtrunk") {
    var str = str.replace(/\\u2500/g,"\u2500");
    var str = str.replace(/\\u2194/g,"\u2194");
    var str = str.replace(/\\u2192/g,"\u2192");
    var str = str.replace(/\\u22c0/g,"\u22c0");
    var str = str.replace(/\\u22c1/g,"\u22c1");
    var str = str.replace(/\\u2200/g,"\u2200");
    var str = str.replace(/\\u2203/g,"\u2203");
    var str = str.replace(/\\u22a2/g,"\u22a2");
    var str = str.replace(/\\u00ac/g,"\u00ac");
    var str = str.replace(/\\u2227/g,"\u2227");
    var str = str.replace(/\\u2228/g,"\u2228");
    var str = str.replace(/\\u2502/g,"\u2502");
    var str = str.replace(/\\u2514/g,"\u2514");
    var str = str.replace(/\\u1d3f/g,"\u1d3f");
    var str = str.replace(/\\u1d38/g,"\u1d38");
    var str = str.replace(/\\u1d35/g,"\u1d35");
    var str = str.replace(/\\u2208/g,"\u2208");
    var str = str.replace(/\\u2081/g,"\u2081");
    var str = str.replace(/\\u2082/g,"\u2082");
    var str = str.replace(/\\u251c/g,"\u251c");
    var str = str.replace(/\\u22a5/g,"\u22a5");
    var str = str.replace(/\\u22a4/g,"\u22a4");


//    var str = str.replace(/forall /g,"∀");
//    var str = str.replace(/exists /g,"∃");
//    var str = str.replace(/\/\\/g,"\u2227");
//    var str = str.replace(/\\\//g,"\u2228");
    return str;
  }
  return str;
}
