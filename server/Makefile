
MAIN = webserve

SOURCES = options.ml utils.ml prover.ml isa.ml coqtree.ml coq.ml matita.ml holl.ml session.ml \
 control.ml service.ml main.ml

ALLSOURCES = $(SOURCES)

GENFILES = 

COPT = -thread

BYTECODEOBJ = $(ALLSOURCES:.ml=.cmo)

NATIVEOBJ = $(ALLSOURCES:.ml=.cmx)

BINARIES = $(MAIN) $(MAIN).byte $(MAIN).top

INCLUDES = -I +pcre -I +cgi -I +nethttpd -I +netstring -I +threads -I +xstr  -I +xml-light -dtypes -I +netcgi1 -I +nethttpd-for-netcgi1 -I +netsys
 
BYTECODELIBS = unix.cma pcre.cma netsys.cma netstring.cma cgi.cma nethttpd-for-netcgi1.cma \
 threads.cma xstr.cma xml-light.cma

NATIVELIBS = $(BYTECODELIBS:.cma=.cmxa)

all: $(MAIN) clean.obj

opt: $(MAIN)

byte: $(MAIN).byte

gen: $(GENFILES)

%.ml: %.mly
	ocamlyacc -v $<

%.ml: %.mll
	ocamllex $<

%.cmi: %.mli
	ocamlc -c $(COPT) $(INCLUDES) $<

%.cmo: %.ml
	ocamlc -c $(COPT) $(INCLUDES) $<                

%.cmx: %.ml
	ocamlopt -c $(COPT) $(INCLUDES) $<                

$(MAIN).byte: $(BYTECODEOBJ)
	ocamlc $(COPT) $(INCLUDES) $(BYTECODELIBS) $(BYTECODEOBJ) -o $(MAIN).byte

$(MAIN): $(NATIVEOBJ)
	ocamlopt $(COPT) $(INCLUDES) $(NATIVELIBS) $(NATIVEOBJ) -o $(MAIN)

top : $(SOURCES:.ml=.cmo)
	ocamlmktop $(COPT) $(INCLUDES) $(BYTECODELIBS) $(SOURCES:.ml=.cmo) -o $(MAIN).top

clean.obj:
	rm -f $(GENFILES) *.cm? *.o *.annot

clean : clean.obj
	rm -f $(BINARIES)

.depend dep: $(GENFILES)
	rm -f .depend; ocamldep *.ml *.mli > .depend

include .depend
