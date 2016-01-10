// AJAX communication
function ajax_new_object() {
  var o;
  try {
    o=new ActiveXObject("Msxml2.XMLHTTP");
  } catch (e) {
    try {
      o=new ActiveXObject("Microsoft.XMLHTTP");
    } catch (e2) {
      o=null;
    }
  }
  if(!o && typeof XMLHttpRequest != "undefined")
    o = new XMLHttpRequest();
  return o;
}

var call_number=1;

function ajax_call(func_name, args) {
  var post = "command=" + func_name + "&callnr=" + call_number;
  if (session) post = post + "&s=" + session;
  if (func_name == "save" && pass != "__PASS__") post = post + "&pass=" + escape(pass).replace(/[+]/g,"%2B") + "&prover=" + prover + "&login=" + user;
  if (mode != "__MODE__") post = post + "&user=" + user + "&mode=" + mode;
  call_number = call_number + 1;
  var i;
  for (i = 0; i < args.length - 1; i++)
    post = post + "&cmdarguments=" + escape(args[i]).replace(/[+]/g,"%2B").replace(/%u/g,"%25u");
  var o = ajax_new_object();
  o.open("POST", prefix + "index.html", true);
  o.setRequestHeader("Method", "POST " + prefix + "index.html HTTP/1.1");
  o.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  o.onreadystatechange = function() {
    if (o.readyState != 4) return;
    var out = get_frame("frame_output");
	out.open();
	out.write('<pre>' + o.responseText + '</pre>');
	out.close();
    var status = o.responseText.charAt(0);
    var data = o.responseText.substring(1);
    if (status == "-")
      alert("Error: " + data);
    else if (status == "<") {
//      alert("Rerequest");
      delete o;
      ajax_call(func_name, args);
      return;
    } else
      args[args.length-1](data);
  }
  var inp = get_frame("frame_input");
  inp.open();
  inp.write('<pre>' + post + '</pre>');
  try { o.send(post); }
    catch (e) {alert ("Cannot connect to server: " + e.message); inp.write("\n\n+++FAILED+++\n\n") }
  inp.close();
  delete o;
}
