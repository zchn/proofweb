domMenu_data.set('domMenu_BJ', new Hash(
    1, new Hash(
        'contents', '<img src="' + prefix + 'arrow-down.png" style="padding:0px; border:none; margin:0px;">',
        'uri', 'javascript:prover_down();',
        'statusText', 'Verify one'
    ),
    2, new Hash(
        'contents', '<img src="' + prefix + 'arrow-up.png" style="padding:0px; border:none; margin:0px;">',
        'uri', 'javascript:prover_up();',
        'statusText', 'Undo'
    ),
    3, new Hash(
        'contents', '<img src="' + prefix + 'arrow-point.png" style="padding:0px; border:none; margin:0px;">',
        'uri', 'javascript:prover_point();',
        'statusText', 'Goto point'
    ),
    4, new Hash(
        'contents', '<img src="' + prefix + 'arrow-bottom.png" style="padding:0px; border:none; margin:0px;">',
        'uri', 'javascript:prover_bottom();',
        'statusText', 'Go to bottom'
    ),
    5, new Hash(
        'contents', '<img src="' + prefix + 'arrow-top.png" style="padding:0px; border:none; margin:0px;">',
        'uri', 'javascript:prover_top();',
        'statusText', 'Retract buffer'
    ),
    6, new Hash(
        'contents', 'File',
        'uri', '',
        'statusText', 'File',
        1, new Hash(
            'contents', 'Load / New',
            'uri', 'javascript:prover_load();',
            'statusText', 'Load / New'
        ),
        2, new Hash(
            'contents', 'Save',
            'uri', 'javascript:prover_save();',
            'statusText', 'Save'
        ),
        3, new Hash(
            'contents', 'Save as',
            'uri', 'javascript:prover_save_as();',
            'statusText', 'Save as'
        )

    ),
    7, new Hash(
        'contents', 'Display',
        'uri', '',
        'statusText', 'Display',
        1, new Hash(
            'contents', 'No proofs',
            'uri', 'javascript:set_trees (0);',
            'statusText', 'No proofs'
        ),
        2, new Hash(
            'contents', 'Gentzen style tree proofs (statements)',
            'uri', 'javascript:set_trees (1);',
            'statusText', 'Gentzen style tree proofs (statements)'
        ),
        3, new Hash(
            'contents', 'Gentzen style tree proofs (full sequents)',
            'uri', 'javascript:set_trees (3);',
            'statusText', 'Gentzen style tree proofs (full sequents)'
        ),
        4, new Hash(
            'contents', 'Fitch style box proofs',
            'uri', 'javascript:set_trees (2);',
            'statusText', 'Fitch style box proofs'
        ),
        5, new Hash(
            'contents', '<hr />',
            'uri', '',
            'statusText', ''
        ),
        6, new Hash(
            'contents', 'Print proof in separate window',
            'uri', 'javascript:var okno = window.open("about:blank", "tree"); okno.window.document.open(); okno.window.document.write("<html><body>" + doc_error.body.innerHTML + "</body></html>"); okno.window.document.close();',
            'statusText', 'Print proof in separate window'
        )
    ),
    8, new Hash(
        'contents', 'Templates',
        'uri', '',
        'statusText', 'Templates',
        1, new Hash(
            'contents', 'Theorem template',
            'uri', 'javascript:template("Require Import ProofWeb.<br/><br/>Parameter A B C : Prop.<br/><br/>Theorem exercise_? : ?.<br/>Proof.<br/><br/>Qed.<br/>");',
            'statusText', 'Theorem template'
        ),
        2, new Hash(
            'contents', '<hr/>',
            'uri', '',
            'statusText', ''
        ),
        3, new Hash(
            'contents', 'exact (close with an assumption)',
            'uri', 'javascript:template("exact ?");',
            'statusText', 'exact (close with an assumption)'
        ),
        4, new Hash(
            'contents', 'insert (insert a new proof step)',
            'uri', 'javascript:template("insert ? (?)");',
            'statusText', 'ins (insert a new proof step)ert'
        )
    ),
    9, new Hash(
        'contents', 'Backward',
        'uri', '',
        'statusText', 'Backward',
        1, new Hash(
            'contents', '\u2227i',
            'uri', 'javascript:template("con_i");',
            'statusText', '\u2227i'
        ),
        2, new Hash(
            'contents', '\u2227e1',
            'uri', 'javascript:template("con_e1 (?)");',
            'statusText', '\u2227e1'
        ),
        3, new Hash(
            'contents', '\u2227e2',
            'uri', 'javascript:template("con_e2 (?)");',
            'statusText', '\u2227e2'
        ),
        4, new Hash(
            'contents', '\u2228i1',
            'uri', 'javascript:template("dis_i1");',
            'statusText', '\u2228i1'
        ),
        5, new Hash(
            'contents', '\u2228i2',
            'uri', 'javascript:template("dis_i2");',
            'statusText', '\u2228i2'
        ),
        6, new Hash(
            'contents', '\u2228e',
            'uri', 'javascript:template("dis_e (? \\\\/ ?) ? ?");',
            'statusText', '\u2228e'
        ),
        7, new Hash(
            'contents', '\u2192i',
            'uri', 'javascript:template("imp_i ?");',
            'statusText', '\u2192i'
        ),
        8, new Hash(
            'contents', '\u2192e (modus ponens)',
            'uri', 'javascript:template("imp_e (?)");',
            'statusText', '\u2192e (modus ponens)'
        ),
        9, new Hash(
            'contents', '\u2194i',
            'uri', 'javascript:template("iff_i ? ?");',
            'statusText', '\u2194i'
        ),
        10, new Hash(
            'contents', '\u2194e1',
            'uri', 'javascript:template("iff_e1 (?)");',
            'statusText', '\u2194e1'
        ),
        11, new Hash(
            'contents', '\u2194e2',
            'uri', 'javascript:template("iff_e2 (?)");',
            'statusText', '\u2194e2'
        ),
        12, new Hash(
            'contents', '\u00aci',
            'uri', 'javascript:template("neg_i ?");',
            'statusText', '\u00aci'
        ),
        13, new Hash(
            'contents', '\u00ace',
            'uri', 'javascript:template("neg_e (?)");',
            'statusText', '\u00ace'
        ),
        14, new Hash(
            'contents', '\u22a5e',
            'uri', 'javascript:template("fls_e");',
            'statusText', '\u22a5e'
        ),
        15, new Hash(
            'contents', '\u22a4i',
            'uri', 'javascript:template("tru_i");',
            'statusText', '\u22a4i'
        ),
        16, new Hash(
            'contents', '\u00ac\u00aci',
            'uri', 'javascript:template("negneg_i");',
            'statusText', '\u00ac\u00aci'
        ),
        17, new Hash(
            'contents', '\u00ac\u00ace',
            'uri', 'javascript:template("negneg_e");',
            'statusText', '\u00ac\u00ace'
        ),
        18, new Hash(
            'contents', 'LEM (law of excluded middle)',
            'uri', 'javascript:template("LEM");',
            'statusText', 'LEM (law of excluded middle)'
        ),
        19, new Hash(
            'contents', 'PBC (proof by contradiction)',
            'uri', 'javascript:template("PBC ?");',
            'statusText', 'PBC (proof by contradiction)'
        ),
        20, new Hash(
            'contents', 'MT (modus tollens)',
            'uri', 'javascript:template("MT (?)");',
            'statusText', 'MT (modus tollens)'
        ),
        21, new Hash(
            'contents', '\u2200i',
            'uri', 'javascript:template("all_i ?");',
            'statusText', '\u2200i'
        ),
        22, new Hash(
            'contents', '\u2200e',
            'uri', 'javascript:template("all_e (all ?, ?)");',
            'statusText', '\u2200e'
        ),
        23, new Hash(
            'contents', '\u2203i',
            'uri', 'javascript:template("exi_i ?");',
            'statusText', '\u2203i'
        ),
        24, new Hash(
            'contents', '\u2203e',
            'uri', 'javascript:template("exi_e (exi ?, ?) ? ?");',
            'statusText', '\u2203e'
        ),
        25, new Hash(
            'contents', '=i',
            'uri', 'javascript:template("equ_i");',
            'statusText', '=i'
        ),
        26, new Hash(
            'contents', '=e (simple version)',
            'uri', 'javascript:template("equ_e (? = ?)");',
            'statusText', '=e (simple version)'
        ),
        27, new Hash(
            'contents', '=e (general version)',
            'uri', 'javascript:template("equ_e\' (? = ?) (fun ? => ?)");',
            'statusText', '=e (general version)'
        )
    ),
    10, new Hash(
        'contents', 'Forward',
        'uri', '',
        'statusText', 'Forward',
        1, new Hash(
            'contents', '\u2227i',
            'uri', 'javascript:template("f_con_i ? ?");',
            'statusText', '\u2227i'
        ),
        2, new Hash(
            'contents', '\u2227e1',
            'uri', 'javascript:template("f_con_e1 ?");',
            'statusText', '\u2227e1'
        ),
        3, new Hash(
            'contents', '\u2227e2',
            'uri', 'javascript:template("f_con_e2 ?");',
            'statusText', '\u2227e2'
        ),
        4, new Hash(
            'contents', '\u2228i1',
            'uri', 'javascript:template("f_dis_i1 ?");',
            'statusText', '\u2228i1'
        ),
        5, new Hash(
            'contents', '\u2228i2',
            'uri', 'javascript:template("f_dis_i2 ?");',
            'statusText', '\u2228i2'
        ),
        6, new Hash(
            'contents', '\u2228e',
            'uri', 'javascript:template("f_dis_e ? ? ?");',
            'statusText', '\u2228e'
        ),
        7, new Hash(
            'contents', '\u2192e (modus ponens)',
            'uri', 'javascript:template("f_imp_e ? ?");',
            'statusText', '\u2192e (modus ponens)'
        ),
        8, new Hash(
            'contents', '\u2194e1',
            'uri', 'javascript:template("f_iff_e1 ? ?");',
            'statusText', '\u2194e1'
        ),
        9, new Hash(
            'contents', '\u2194e2',
            'uri', 'javascript:template("f_iff_e2 ? ?");',
            'statusText', '\u2194e2'
        ),
        10, new Hash(
            'contents', '\u00ace',
            'uri', 'javascript:template("f_neg_e ? ?");',
            'statusText', '\u00ace'
        ),
        11, new Hash(
            'contents', '\u22a5e',
            'uri', 'javascript:template("f_fls_e");',
            'statusText', '\u22a5e'
        ),
        12, new Hash(
            'contents', '\u22a4i',
            'uri', 'javascript:template("f_tru_i");',
            'statusText', '\u22a4i'
        ),
        13, new Hash(
            'contents', '\u00ac\u00aci',
            'uri', 'javascript:template("f_negneg_i ?");',
            'statusText', '\u00ac\u00aci'
        ),
        14, new Hash(
            'contents', '\u00ac\u00ace',
            'uri', 'javascript:template("f_negneg_e ?");',
            'statusText', '\u00ac\u00ace'
        ),
        15, new Hash(
            'contents', 'LEM (law of excluded middle)',
            'uri', 'javascript:template("f_LEM");',
            'statusText', 'LEM (law of excluded middle)'
        ),
        16, new Hash(
            'contents', 'MT (modus tollens)',
            'uri', 'javascript:template("f_MT ? ?");',
            'statusText', 'MT (modus tollens)'
        ),
        17, new Hash(
            'contents', '\u2200e',
            'uri', 'javascript:template("f_all_e ?");',
            'statusText', '\u2200e'
        ),
        18, new Hash(
            'contents', '\u2203i',
            'uri', 'javascript:template("f_exi_i ?");',
            'statusText', '\u2203i'
        ),
        19, new Hash(
            'contents', '\u2203e',
            'uri', 'javascript:template("f_exi_e ? ? ?");',
            'statusText', '\u2203e'
        ),
        20, new Hash(
            'contents', '=i',
            'uri', 'javascript:template("f_equ_i");',
            'statusText', '=i'
        ),
        21, new Hash(
            'contents', '=e',
            'uri', 'javascript:template("f_equ_e ? ?");',
            'statusText', '=e (simple version)'
        )
    ),
    11, new Hash(
        'contents', 'Query',
        'uri', 'javascript:query_ask();',
        'statusText', 'Query'
    ),
    12, new Hash(
        'contents', 'Debug',
        'uri', '',
        'statusText', 'Debug',
        1, new Hash(
            'contents', 'Show Script',
            'uri', 'javascript:alert("[" + proved + "|" + provedit + "]");',
            'statusText', 'Show Script'
        ),
        2, new Hash(
            'contents', 'Toggle Debug View',
            'uri', 'javascript:toggle_debug ();',
            'statusText', 'Toggle Debug View'
        ),
	3, new Hash(
	    'contents', 'Toggle Electric Terminator',
	    'uri', 'javascript:toggle_electric();',
	    'statusText', 'Toggle Electric Terminator'
        )
    ),
    13, new Hash(
        'contents', 'Help',
        'uri', '',
        'statusText', 'Help',
        1, new Hash(
            'contents', 'Send bug report',
            'uri', 'mailto:proofweb@cs.ru.nl',
            'statusText', 'Send bug report'
        ),
        2, new Hash(
            'contents', 'Proofweb Interface manual',
            'uri', '',
            'statusText', 'Proofweb Interface manual'
        ),
        3, new Hash(
            'contents', 'Coq webpage',
            'uri', 'javascript:var wnd = window.open("http://coq.inria.fr/"); wnd.focus();',
            'statusText', 'Coq webpage'
        ),
        4, new Hash(
            'contents', 'Developers homepage',
            'uri', 'javascript:var wnd = window.open("http://www.cs.ru.nl/~cek/proofweb/", "", ""); wnd.focus();',
            'statusText', 'Developers homepage'
        )
    ),
    14, new Hash(
        'contents', 'Logout',
        'uri', 'javascript:window.location="http://prover.cs.ru.nl/";',
        'statusText', 'Logout'
    )
));

domMenu_settings.set('domMenu_BJ', new Hash(
    'menuBarWidth', '0%',
    'menuBarClass', 'BJ_menuBar',
    'menuElementClass', 'BJ_menuElement',
    'menuElementHoverClass', 'BJ_menuElementHover',
    'menuElementActiveClass', 'BJ_menuElementActive',
    'subMenuBarClass', 'BJ_subMenuBar',
    'subMenuElementClass', 'BJ_subMenuElement',
    'subMenuElementHoverClass', 'BJ_subMenuElementHover',
    'subMenuElementActiveClass', 'BJ_subMenuElementHover',
    'subMenuMinWidth', 'auto',
    'distributeSpace', false,
    'openMouseoverMenuDelay', -1,
    'openMousedownMenuDelay', 0,
    'closeClickMenuDelay', 0,
    'closeMouseoutMenuDelay', -1,
    'expandMenuArrowUrl', 'arrow.gif'
));
