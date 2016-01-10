open Nethttpd_types;;
open Nethttpd_services;;
open Nethttpd_reactor;;
open Format;;

let fs_spec =
  { file_docroot = "./pub/";
    file_uri = "/";
    file_suffix_types = [
        "js",   "text/javascript";
        "css",  "text/css";
        "xml",  "text/xml";
        "html", "text/html" ;
        "v",    "text/plain" ];
    file_default_type = "application/octet-stream";

    file_options = [ `Enable_gzip;
                     `Enable_listings (simple_listing ?hide:None);
                     `Enable_index_file ["index.html"]
                   ]
  }
;;

let options =
  ["-coqtop",
   Arg.String (fun x -> ()), (* TODO *)
   "Specify which coqtop to run";

   "-lego",
   Arg.String (fun x -> Options.lego := x),
   "Specify which lego to run";

   "-port"    ,
   Arg.Set_int Options.port_no,
   "Specify port number";

   "-files"   ,
   Arg.String (fun x -> Options.files := x),
   "Specify directory where to read/store files";

   "-localhost" ,
   Arg.String (fun x -> Options.localhost := x),
   "Specify name of local host";

   "-address" ,
   Arg.String (fun x -> Options.address := x),
   "Specify ip of local host";

   "-wiki",
   Arg.Set Options.wiki,
   "Set wiki mode";

   "-nodaemon",
   Arg.Clear Options.daemon,
   "Do not fork on startup (debug)";

   "-pidfile",
   Arg.Set_string Options.pid_file,
   "Change the PID file name (webserve.pid)";

   "-logfile",
   Arg.Set_string Options.log_file,
   "Change the log file name (log)"
];;

let anon_fun s =
  failwith (sprintf "No such option : %S " s);;

let description = "The prover-web prototype";;





let srv =
  host_distributor
    [ default_host ~pref_name:!Options.localhost ~pref_port:!Options.port_no (),
      uri_distributor
	[ "*", (options_service());
	  "/", (file_service fs_spec);
	  "/files", (options_service());
	  "/logins", (options_service());
	  "/files/nobody", (file_service fs_spec);
	  "/index.html", (dynamic_service
			   { dyn_handler = Service.serve;
			     dyn_activation = std_activation `Std_activation_buffered;
			     dyn_uri = Some "/index.html";
			     dyn_translator = file_translator fs_spec;
			     dyn_accept_all_conditionals = false
			   });
	  "/logged.html", (dynamic_service
			   { dyn_handler = Control.logged;
			     dyn_activation = std_activation `Std_activation_buffered;
			     dyn_uri = Some "/logged.html";
			     dyn_translator = file_translator fs_spec;
			     dyn_accept_all_conditionals = false
			   });
	  "/calc.html", (dynamic_service
			   { dyn_handler = Service.calc;
			     dyn_activation = std_activation `Std_activation_buffered;
			     dyn_uri = Some "/calc.html";
			     dyn_translator = file_translator fs_spec;
			     dyn_accept_all_conditionals = false
			   });
	]
    ]
;;

let start () =
  let config : http_reactor_config = Nethttpd_reactor.default_http_reactor_config in
    (* object *)
    (*   method config_timeout_next_request = 15.0 *)
    (*   method config_timeout = 300.0 *)
    (*   method config_reactor_synch = `Write *)
    (*   method config_cgi = Netcgi.default_config *)
    (*   method config_error_response n = *)
    (*     "<html>Error " ^ string_of_int n ^ "</html>" *)
    (*   method config_log_error _ sock meth header msg = *)
    (*     let ip = match sock with Some (Unix.ADDR_INET (addr, _)) -> Unix.string_of_inet_addr addr | _ -> "" in *)
    (*     let meth, uri = match meth with Some (a, b) -> a, b | _ -> "", "" in *)
    (*     Utils.time_log "%15s %s %s %s \n%!" ip meth uri msg *)
    (*   method config_max_reqline_length = 256 *)
    (*   method config_max_header_length = 32768 *)
    (*   method config_max_trailer_length = 32768 *)
    (*   method config_limit_pipeline_length = 0 *)
    (*   method config_limit_pipeline_size = 250000 *)
    (*   method config_announce_server = `Ignore *)
    (* end in *)

  let master_sock = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Unix.setsockopt master_sock Unix.SO_REUSEADDR true;
  let address = Unix.inet_addr_of_string !Options.address in
  Unix.bind master_sock (Unix.ADDR_INET(address, !Options.port_no));
  (try Unix.setuid !Options.uid with _ -> ());
  Unix.listen master_sock 100;
  Utils.time_log "Starting on port %d@." !Options.port_no;
  ignore (Thread.create Session.session_killer ());
  while true do
    try
      let conn_sock, _ = Unix.accept master_sock in
      Unix.set_nonblock conn_sock;
      let _ =
	Thread.create
	  (process_connection config conn_sock)
	  srv
      in
      ()
    with
        Unix.Unix_error(Unix.EINTR,_,_) -> ()  (* ignore *)
  done
;;

let create_pid_file () =
  let outc =
    open_out_gen [Open_creat;Open_excl;Open_wronly] 0o644 !Options.pid_file in
      output_string outc (string_of_int (Unix.getpid ()));
    close_out outc
;;

let sigterm_handler log_chan signum =
  Utils.time_log "SIGTERM: Exiting.@.";
  close_out log_chan;
  exit 0
;;

let main =
  Arg.parse options anon_fun description;
  Sys.set_signal Sys.sigpipe Sys.Signal_ignore;
  (*if !Options.daemon && Sys.file_exists !Options.pid_file then exit 0;*)
  let log_chan = open_out_gen [Open_append;Open_wronly;Open_creat] 0o644 !Options.log_file in
  Options.log_f := formatter_of_out_channel log_chan;
  Unix.close Unix.stdin;
  Unix.close Unix.stdout;
  Unix.close Unix.stderr;
  if !Options.daemon && Unix.fork () > 0 then begin
    close_out log_chan;
    exit 0
  end;
  Sys.set_signal Sys.sigpipe Sys.Signal_ignore;
  Sys.set_signal Sys.sighup Sys.Signal_ignore;
  Sys.set_signal Sys.sigterm
    (Sys.Signal_handle (sigterm_handler log_chan));
  if !Options.daemon then create_pid_file ();
  start ()
;;
