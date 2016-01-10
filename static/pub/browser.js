function get_frame (name) {
  var d;
  if (document.all) {
    d=frames[name].document;
  } else {
    f = document.getElementById(name);
    //if (typeof f.contentWindow == 'undefined') {
    //    alert("KHTML/KJS bug workaround - please click OK\n(You can safely ignore the following):\n\n" + typeof f.contentWindow);
    //}
    e = f.contentWindow; // yes, KJS does this now!
    d = e.document; // do not use d = f.contentWindow.document directly
  }
  return d;
}

function set_event (doc, event, fun) {
  if (doc.addEventListener) {
    doc.addEventListener(event.substring(2), fun, true);
  } else if (doc.setEvent) {
    doc.setEvent(event, fun);
  } else if (doc.attachEvent) {
    alert("Warning, setting keys in IE may fail");
    doc.attachEvent(event, fun);
  } else {
    var original = doc[event];
    if (original) {
      doc[event] = function(e){original(e); fun(e);};
    } else {
      doc[event] = fun;
    }
  }
}
