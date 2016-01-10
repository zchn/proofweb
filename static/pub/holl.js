function next(str) {
  return str.indexOf (";;") + 2;
}

function last(str) {
  return str.lastIndexOf (";;") + 2;
}

function prev(str) {
  return str.lastIndexOf (";;");
}

function unicode(str) {
  return str;
}

function unquote_str (oldstr) {
  var str = oldstr.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&apos;/g, "'").replace(/&amp;/g, "&").replace(/<br>/g,"\n").replace(/<BR>/g,"\n").replace(/<BR\/>/g,"\n");
  return str;
}
