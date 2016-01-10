let uid = ref 1018;;
let port_no = ref 1024;;
let localhost = ref "localhost";;
let address = ref "127.0.0.1";;
let files = ref "files";; (* Temporarily ignored *)
let token = "__PWT__";;

let lego = ref "/bin/lego";;
let plastic = ref "/plastic/plastic-linux";;

let pass = ref "Ch1cken";;

let coqopts = ref " -R /coqtrunk/CoRN CoRN -I . -I /coq/contribs/Eindhoven/POCKLINGTON -I /coq/contribs/Berkeley/Godel ";;

let wiki = ref false;;

let daemon = ref true;;

let log_file = ref "log";;  

let pid_file = ref "webserve.pid";;  

let log_f = ref Format.std_formatter;;
