all: all2

ifndef CHROOT
all2:
	@echo "Set the CHROOT variable first!"
endif
ifdef CHROOT
all2: $(CHROOT)/lib/ld-linux.so.2 $(CHROOT)/lib/libgcc_s.so.1 $(CHROOT)/index.html
	wget prover.cs.ru.nl/inst/scripts.tar.gz
	tar xzpf scripts.tar.gz
	@echo "Edit files from 'scripts' directory and move them to the root directory"
	@echo "  In particular change the location of CHROOT in etc/init.d/proofweb"
	@echo "Then restart apache: sudo /etc/init.d/apache2 restart"
	@echo "And start proofweb:  sudo /etc/init.d/proofweb start"
	@echo "And prove!"
endif


$(CHROOT)/webserve:
	# wget prover.cs.ru.nl/inst/server.tar.gz
	# tar xzpf server.tar.gz
	make -C server
	mkdir -p $(CHROOT)
	cp server/webserve $(CHROOT)

$(CHROOT)/bin/verify:
	# wget prover.cs.ru.nl/inst/verifier.tar.gz
	# tar xzpf verifier.tar.gz
	make -C verifier
	mkdir -p $(CHROOT)/bin
	cp verifier/verify $(CHROOT)/bin/

$(CHROOT)/coq/bin/coqtop.opt:
	wget https://coq.inria.fr/distrib/V8.4pl6/files/coq-8.4pl6.tar.gz
	tar xzf coq-8.4pl6.tar.gz
	cd coq-8.4pl6; ./configure -prefix /coq -coqide no -with-doc no
	make -C coq-8.4pl6 world
	COQINSTALLPREFIX=$(CHROOT) make -C coq-8.4pl6 install
	# wget http://coq.inria.fr/distrib/8.2/files/coq-8.2.tar.gz
	# tar xzf coq-8.2.tar.gz
	# cd coq-8.2; ./configure -prefix /coq -fsets all -reals all -coqide no -with-doc no
	# make -C coq-8.2 world
# COQINSTALLPREFIX=$(CHROOT) make -C coq-8.2 install

$(CHROOT)/bin/sh: $(CHROOT)/coq/bin/coqtop.opt
	mkdir -p $(CHROOT)/bin
	cp -u /bin/sh /usr/bin/nice /bin/rm /usr/bin/touch $(CHROOT)/bin

$(CHROOT)/index.html:
	wget http://prover.cs.ru.nl/inst/static.tar.gz
	sudo tar xzpf static.tar.gz
	sudo cp -r -f static/* $(CHROOT)

$(CHROOT)/lib/ld-linux.so.2: $(CHROOT)/bin/sh $(CHROOT)/bin/sh $(CHROOT)/index.html $(CHROOT)/coq/bin/coqtop.opt $(CHROOT)/bin/verify $(CHROOT)/webserve
	for j in $(CHROOT)/bin/* $(CHROOT)/coq/bin/coqtop.opt $(CHROOT)/webserve; do \
	  for i in `ldd $$j | cut -d "(" -f 1 | cut -d ">" -f 2`; do \
	    mkdir -p $(CHROOT)`dirname $$i`; cp -u $$i $(CHROOT)`dirname $$i`; done; done

# Newer versions of the pthreads library (e.g. version 2.11.2 in Debian Squeeze)
# require the library below in the CHROOT, to prevent webserve crashing with:
# "libgcc_s.so.1 must be installed for pthread_cancel to work"

# $(CHROOT)/lib/libgcc_s.so.1: /lib/libgcc_s.so.1
$(CHROOT)/lib/libgcc_s.so.1: /lib/x86_64-linux-gnu/libgcc_s.so.1
	cp -u $< $@

clean:
	rm *.tar.gz
	rm -fr scripts
	rm -fr static
	make -C server clean
	make -C verifier clean
