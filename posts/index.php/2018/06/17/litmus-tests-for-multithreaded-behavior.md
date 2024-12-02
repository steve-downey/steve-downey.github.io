<html><head><style type="text/css">
 <!--/*--><![CDATA[/*><!--*/ .title { text-align: center; margin-bottom: .2em; } .subtitle { text-align: center; font-size: medium; font-weight: bold; margin-top:0; } .todo { font-family: monospace; color: red; } .done { font-family: monospace; color: green; } .priority { font-family: monospace; color: orange; } .tag { background-color: #eee; font-family: monospace; padding: 2px; font-size: 80%; font-weight: normal; } .timestamp { color: #bebebe; } .timestamp-kwd { color: #5f9ea0; } .org-right { margin-left: auto; margin-right: 0px; text-align: right; } .org-left { margin-left: 0px; margin-right: auto; text-align: left; } .org-center { margin-left: auto; margin-right: auto; text-align: center; } .underline { text-decoration: underline; } #postamble p, #preamble p { font-size: 90%; margin: .2em; } p.verse { margin-left: 3%; } pre { border: 1px solid #ccc; box-shadow: 3px 3px 3px #eee; padding: 8pt; font-family: monospace; overflow: auto; margin: 1.2em; } pre.src { position: relative; overflow: visible; padding-top: 1.2em; } pre.src:before { display: none; position: absolute; background-color: white; top: -10px; right: 10px; padding: 3px; border: 1px solid black; } pre.src:hover:before { display: inline;} /* Languages per Org manual */ pre.src-asymptote:before { content: 'Asymptote'; } pre.src-awk:before { content: 'Awk'; } pre.src-C:before { content: 'C'; } /* pre.src-C++ doesn't work in CSS */ pre.src-clojure:before { content: 'Clojure'; } pre.src-css:before { content: 'CSS'; } pre.src-D:before { content: 'D'; } pre.src-ditaa:before { content: 'ditaa'; } pre.src-dot:before { content: 'Graphviz'; } pre.src-calc:before { content: 'Emacs Calc'; } pre.src-emacs-lisp:before { content: 'Emacs Lisp'; } pre.src-fortran:before { content: 'Fortran'; } pre.src-gnuplot:before { content: 'gnuplot'; } pre.src-haskell:before { content: 'Haskell'; } pre.src-hledger:before { content: 'hledger'; } pre.src-java:before { content: 'Java'; } pre.src-js:before { content: 'Javascript'; } pre.src-latex:before { content: 'LaTeX'; } pre.src-ledger:before { content: 'Ledger'; } pre.src-lisp:before { content: 'Lisp'; } pre.src-lilypond:before { content: 'Lilypond'; } pre.src-lua:before { content: 'Lua'; } pre.src-matlab:before { content: 'MATLAB'; } pre.src-mscgen:before { content: 'Mscgen'; } pre.src-ocaml:before { content: 'Objective Caml'; } pre.src-octave:before { content: 'Octave'; } pre.src-org:before { content: 'Org mode'; } pre.src-oz:before { content: 'OZ'; } pre.src-plantuml:before { content: 'Plantuml'; } pre.src-processing:before { content: 'Processing.js'; } pre.src-python:before { content: 'Python'; } pre.src-R:before { content: 'R'; } pre.src-ruby:before { content: 'Ruby'; } pre.src-sass:before { content: 'Sass'; } pre.src-scheme:before { content: 'Scheme'; } pre.src-screen:before { content: 'Gnu Screen'; } pre.src-sed:before { content: 'Sed'; } pre.src-sh:before { content: 'shell'; } pre.src-sql:before { content: 'SQL'; } pre.src-sqlite:before { content: 'SQLite'; } /* additional languages in org.el's org-babel-load-languages alist */ pre.src-forth:before { content: 'Forth'; } pre.src-io:before { content: 'IO'; } pre.src-J:before { content: 'J'; } pre.src-makefile:before { content: 'Makefile'; } pre.src-maxima:before { content: 'Maxima'; } pre.src-perl:before { content: 'Perl'; } pre.src-picolisp:before { content: 'Pico Lisp'; } pre.src-scala:before { content: 'Scala'; } pre.src-shell:before { content: 'Shell Script'; } pre.src-ebnf2ps:before { content: 'ebfn2ps'; } /* additional language identifiers per "defun org-babel-execute" in ob-*.el */ pre.src-cpp:before { content: 'C++'; } pre.src-abc:before { content: 'ABC'; } pre.src-coq:before { content: 'Coq'; } pre.src-groovy:before { content: 'Groovy'; } /* additional language identifiers from org-babel-shell-names in ob-shell.el: ob-shell is the only babel language using a lambda to put the execution function name together. */ pre.src-bash:before { content: 'bash'; } pre.src-csh:before { content: 'csh'; } pre.src-ash:before { content: 'ash'; } pre.src-dash:before { content: 'dash'; } pre.src-ksh:before { content: 'ksh'; } pre.src-mksh:before { content: 'mksh'; } pre.src-posh:before { content: 'posh'; } /* Additional Emacs modes also supported by the LaTeX listings package */ pre.src-ada:before { content: 'Ada'; } pre.src-asm:before { content: 'Assembler'; } pre.src-caml:before { content: 'Caml'; } pre.src-delphi:before { content: 'Delphi'; } pre.src-html:before { content: 'HTML'; } pre.src-idl:before { content: 'IDL'; } pre.src-mercury:before { content: 'Mercury'; } pre.src-metapost:before { content: 'MetaPost'; } pre.src-modula-2:before { content: 'Modula-2'; } pre.src-pascal:before { content: 'Pascal'; } pre.src-ps:before { content: 'PostScript'; } pre.src-prolog:before { content: 'Prolog'; } pre.src-simula:before { content: 'Simula'; } pre.src-tcl:before { content: 'tcl'; } pre.src-tex:before { content: 'TeX'; } pre.src-plain-tex:before { content: 'Plain TeX'; } pre.src-verilog:before { content: 'Verilog'; } pre.src-vhdl:before { content: 'VHDL'; } pre.src-xml:before { content: 'XML'; } pre.src-nxml:before { content: 'XML'; } /* add a generic configuration mode; LaTeX export needs an additional (add-to-list 'org-latex-listings-langs '(conf " ")) in .emacs */ pre.src-conf:before { content: 'Configuration File'; } table { border-collapse:collapse; } caption.t-above { caption-side: top; } caption.t-bottom { caption-side: bottom; } td, th { vertical-align:top; } th.org-right { text-align: center; } th.org-left { text-align: center; } th.org-center { text-align: center; } td.org-right { text-align: right; } td.org-left { text-align: left; } td.org-center { text-align: center; } dt { font-weight: bold; } .footpara { display: inline; } .footdef { margin-bottom: 1em; } .figure { padding: 1em; } .figure p { text-align: center; } .inlinetask { padding: 10px; border: 2px solid gray; margin: 10px; background: #ffffcc; } #org-div-home-and-up { text-align: right; font-size: 70%; white-space: nowrap; } textarea { overflow-x: auto; } .linenr { font-size: smaller } .code-highlighted { background-color: #ffff00; } .org-info-js_info-navigation { border-style: none; } #org-info-js_console-label { font-size: 10px; font-weight: bold; white-space: nowrap; } .org-info-js_search-highlight { background-color: #ffff00; color: #000000; font-weight: bold; } .org-svg { width: 90%; } /*]]>*/--><br />
</style>

<script type="text/javascript">
/*
@licstart  The following is the entire license notice for the
JavaScript code in this tag.

Copyright (C) 2012-2018 Free Software Foundation, Inc.

The JavaScript code in this tag is free software: you can
redistribute it and/or modify it under the terms of the GNU
General Public License (GNU GPL) as published by the Free Software
Foundation, either version 3 of the License, or (at your option)
any later version.  The code is distributed WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU GPL for more details.

As additional permission under GNU GPL version 3 section 7, you
may distribute non-source (e.g., minimized or compacted) forms of
that code without the copy of the GNU GPL normally required by
section 4, provided you include this license notice and a URL
through which recipients can access the Corresponding Source.


@licend  The above is the entire license notice
for the JavaScript code in this tag.
*/
<!--/*--><![CDATA[/*><!--*/ function CodeHighlightOn(elem, id) { var target = document.getElementById(id); if(null != target) { elem.cacheClassElem = elem.className; elem.cacheClassTarget = target.className; target.className = "code-highlighted"; elem.className = "code-highlighted"; } } function CodeHighlightOff(elem, id) { var target = document.getElementById(id); if(elem.cacheClassElem) elem.className = elem.cacheClassElem; if(elem.cacheClassTarget) target.className = elem.cacheClassTarget; } /*]]>*///-->
</script>

<script type="text/x-mathjax-config">
    MathJax.Hub.Config({
        displayAlign: "center",
        displayIndent: "0em",

        "HTML-CSS": { scale: 100,
                        linebreaks: { automatic: "false" },
                        webFont: "TeX"
                       },
        SVG: {scale: 100,
              linebreaks: { automatic: "false" },
              font: "TeX"},
        NativeMML: {scale: 100},
        TeX: { equationNumbers: {autoNumber: "AMS"},
               MultLineWidth: "85%",
               TagSide: "right",
               TagIndent: ".8em"
             }
});
</script>

<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.0/MathJax.js?config=TeX-AMS_HTML"></script>

</head><body><div id="content">
<h1 class="title">Litmus Tests for Multithreaded Behavior

<span class="subtitle">Or How Processors Don't Do What You Think</span></h1>
Modern multicore processors are entirely weirder than almost anyone thinks possible. They are somewhat weirder than chip makers were willing to admit until fairly recently. They are sufficiently weird enough that almost all multi-threaded programs, and many lock-free algorithms, had bugs because the hardware just does not work the way anyone would reasonably expect. And, in addition, optimizing compilers did not actually know how to not break your code. [<a href="#boehm2005threads">boehm2005threads</a>]

I'm in the (slow) process of writing some test cases for multi-threaded code. I eventually want to have some confidence that some code is executed once, and only once, in an efficient manner. It's the 'efficient' part that worries me, because for efficient, it also has a tendency to be clever, and I'm learning that clever MT code is often subtly broken. [<a href="#bacon2000double">bacon2000double</a>] So if smarter people than me make mistakes about MT code, I need tests to compensate. And ones that will cover occasional allowed but unexpected behavior. Which means the test framework should be able to detect them.

Also, fortunately, the RPi is a computer that exhibits some odd behavior, as it is an ARM system. X86 has a much stronger model. However, even the x86 model is allowed to perform in odd ways.

Starting in 2007, Intel has started publishing short snippets of assembly and documenting what are the allowed and disallowed results running them in parallel. [<a href="#IWPAug2007">IWPAug2007</a>] These snippets have come to be called litmus tests, and are used to confirm the behavior of hardware, and confirm models of the hardware behavior. A particularly important model for C++ programmers is the x86 Total Store Order model [<a href="#owens2009better">owens2009better</a>] which provides a way of mapping the C++11 memory model to X86 hardware. X86 hardware provides a strongly consistent memory model. Power and ARM provide fewer guarantees, and mapping the C++ memory model to these architectures is more challenging. [<a href="#maranget2012tutorial">maranget2012tutorial</a>]
<div id="outline-container-org6552108" class="outline-2">
<h2 id="org6552108">Message Passing</h2>
<div id="text-org6552108" class="outline-text-2">

The tests outlined in the Intel paper are short pieces of assembly to be exercised on different processors, with guarantees about behavior that will not happen. The first one essentially promises that message passing will work, and is now known as the MP test.
<table border="2" frame="hsides" rules="groups" cellspacing="0" cellpadding="6"><colgroup> <col class="org-left"> <col class="org-left"> </colgroup>
<thead>
<tr>
<th class="org-left" scope="col">Processor 0</th>
<th class="org-left" scope="col">Processor 1</th>
</tr>
</thead>
<tbody>
<tr>
<td class="org-left">mov [ _x], 1 // M1</td>
<td class="org-left">mov r1, [ _y] // M3</td>
</tr>
<tr>
<td class="org-left">mov [ _y], 1 // M2</td>
<td class="org-left">mov r2, [ _x] // M4</td>
</tr>
</tbody>
</table>
Initially x = y = 0

r1 = 1 and r2 = 0 is not allowed

That says that we can't read the writes of x and y out of order, which ensures that if we're waiting to see the write to the flag y, we can be guaranteed to see the payload in x. If we change it slightly to wait for the write to _y to be visible, we can pass a message from one thread to anothher in _x. This is also known as Dekards Algorithm.

ARM and Power do not provide that guarantee without additional synchronization instructions.

In C++ that looks something like the following, using the test framework I'm writing.
<div class="org-src-container">
<pre class="src src-C++"><span class="org-constant">MP</span>::<span class="org-function-name">MP</span>() : x_(0), y_(0) {}
<span class="org-type">void</span> <span class="org-constant">MP</span>::<span class="org-function-name">t1</span>() {
    x_.store(1, <span class="org-constant">std</span>::memory_order_relaxed);
    y_.store(1, <span class="org-constant">std</span>::memory_order_relaxed);
}
<span class="org-type">void</span> <span class="org-constant">MP</span>::<span class="org-function-name">t2</span>(<span class="org-type">Result</span>&amp; <span class="org-variable-name">read</span>) {
    <span class="org-keyword">while</span> (<span class="org-negation-char">!</span>y_.load(<span class="org-constant">std</span>::memory_order_relaxed)){}
    <span class="org-constant">std</span>::get&lt;0&gt;(read) = x_.load(<span class="org-constant">std</span>::memory_order_relaxed);
}

</pre>
</div>
Here, x_ and y_ are atomic&lt;int&gt;s, and we're using the lowest possible atomic guarantee in C++, relaxed. Relaxed guarantees that the operation happens atomically. but there are no synchronization properties with anything else. This usally corresponds to the basic int type. Unless you're using a really insane processor that might let an int be partially written and observable. Like you might get the top half of the int, or the middle byte. The commercial processors that allowed this have pretty much died out.

The test spins on seeing the load of y to be complete. It loads the value of x_ into a result tuple. The tuple is used as the key to a map which accumulates how many times each result has been seen.
Running the above on my x86 laptop:
<pre class="example">[ RUN      ] ExperimentTest.MPTest1
(1) : 2000000

</pre>
on my Raspberry Pi 3:
<pre class="example">[ RUN      ] ExperimentTest.MPTest1
(0) : 483
(1) : 1999517

</pre>
Using objdump to check the generated assembly
<pre class="example">00000088 &lt;litmus::MP::MP()&gt;:
  88:   mov     r2, #0
  8c:   str     r2, [r0]
  90:   str     r2, [r0, #64]   ; 0x40
  94:   bx      lr

00000098 &lt;litmus::MP::t1()&gt;:
  98:   mov     r3, #1
  9c:   str     r3, [r0]
  a0:   str     r3, [r0, #64]   ; 0x40
  a4:   bx      lr

000000a8 &lt;litmus::MP::t2(std::tuple&lt;int&gt;&amp;)&gt;:
  a8:   ldr     r3, [r0, #64]   ; 0x40
  ac:   cmp     r3, #0
  b0:   beq     a8 &lt;litmus::MP::t2(std::tuple&lt;int&gt;&amp;)&gt;
  b4:   ldr     r3, [r0]
  b8:   str     r3, [r1]
  bc:   bx      lr
</pre>
So, out of the 2,000,000 times that I ran the experiment, there were 483 times that reading x_ resulted in 0, even though y_ was 1. ARM has a weaker memory model than x86. This has some advantages in processor implementation. It has distinct disadvantages in how our brains work. X86 tries to preserve the model that there is shared memory that everyone sees and works with. That's not strictly true, even for X86, but ARM and Power don't even come close. On the other hand, it's also why it's easier to add more cores to Power and ARM chips and systems. I routinely work with Power systems with 512 physical cores.

</div>
</div>
<div id="outline-container-orgdbab232" class="outline-2">
<h2 id="orgdbab232">Store Buffering</h2>
<div id="text-orgdbab232" class="outline-text-2">

Store buffering is the odd case that is allowed in the Intel memory model. When assigning locations in two threads, and then reading them on opposite threads, both threads are allowed to read the older state. The stores get buffered.
From the Intel White Paper:
<table border="2" frame="hsides" rules="groups" cellspacing="0" cellpadding="6"><colgroup> <col class="org-left"> <col class="org-left"> </colgroup>
<thead>
<tr>
<th class="org-left" scope="col">Processor 0</th>
<th class="org-left" scope="col">Processor 1</th>
</tr>
</thead>
<tbody>
<tr>
<td class="org-left">mov [ _x], 1 // M1</td>
<td class="org-left">mov [ _y], 1 // M3</td>
</tr>
<tr>
<td class="org-left">mov r1, [ _y] // M2</td>
<td class="org-left">mov r2, [ _x] // M4</td>
</tr>
</tbody>
</table>
Initially x = y = 0

r1 = 0 and r2 ==0 is allowed

Note, in particular, there is no interleaving of M1 - 4 that could result in r1 and r2 being 0. Not without interupting an instruction in the middle. But the instructions themselves are atomic, and indivisible. If they were actually operating on shared memory, this would not be possible. However, it does happen.
<div class="org-src-container">
<pre class="src src-c++"><span class="org-constant">SB</span>::<span class="org-function-name">SB</span>() : x_(0), y_(0) {}
<span class="org-type">void</span> <span class="org-constant">SB</span>::<span class="org-function-name">t1</span>(<span class="org-type">Result</span>&amp; <span class="org-variable-name">read</span>) {
    y_.store(1, <span class="org-constant">std</span>::memory_order_relaxed);
    <span class="org-constant">std</span>::get&lt;0&gt;(read) = x_.load(<span class="org-constant">std</span>::memory_order_relaxed);
}
<span class="org-type">void</span> <span class="org-constant">SB</span>::<span class="org-function-name">t2</span>(<span class="org-type">Result</span>&amp; <span class="org-variable-name">read</span>) {
    x_.store(1, <span class="org-constant">std</span>::memory_order_relaxed);
    <span class="org-constant">std</span>::get&lt;1&gt;(read) = y_.load(<span class="org-constant">std</span>::memory_order_relaxed);
}

</pre>
</div>
That generates the x86 code
<pre class="example">00000000000000f0 &lt;litmus::SB::t1(std::__1::tuple&lt;int, int&gt;&amp;)&gt;:
  f0:   mov    DWORD PTR [rdi+0x40],0x1
  f7:   mov    eax,DWORD PTR [rdi]
  f9:   mov    DWORD PTR [rsi],eax
  fb:   ret

0000000000000100 &lt;litmus::SB::t2(std::__1::tuple&lt;int, int&gt;&amp;)&gt;:
 100:   mov    DWORD PTR [rdi],0x1
 106:   mov    eax,DWORD PTR [rdi+0x40]
 109:   mov    DWORD PTR [rsi+0x4],eax
 10c:   ret

</pre>
And on my x86 machine:
<pre class="example">[ RUN      ] ExperimentTest.SBTest1
(0, 0) : 559
(0, 1) : 999858
(1, 0) : 999576
(1, 1) : 7

</pre>
So 559 times neither core saw the other core's store.

</div>
</div>
<div id="outline-container-orga3dd0b6" class="outline-2">
<h2 id="orga3dd0b6">Load Buffering</h2>
<div id="text-orga3dd0b6" class="outline-text-2">

Load Buffering is the dual of store buffering. Loads into registers might be delayed, or buffered, and actually performed after following instructions. It's not allowed in the Intel architecture.

From the Intel White Paper
<table border="2" frame="hsides" rules="groups" cellspacing="0" cellpadding="6"><colgroup> <col class="org-left"> <col class="org-left"> </colgroup>
<thead>
<tr>
<th class="org-left" scope="col">Processor 0</th>
<th class="org-left" scope="col">Processor 1</th>
</tr>
</thead>
<tbody>
<tr>
<td class="org-left">mov r1, [ _x] // M1</td>
<td class="org-left">mov r2, [ _y] // M3</td>
</tr>
<tr>
<td class="org-left">mov [ _y], 1 // M2</td>
<td class="org-left">mov [ _x], 1 // M4</td>
</tr>
</tbody>
</table>
Initially x = y = 0

r1 = 1 and r2 = 1 is not allowed
<div class="org-src-container">
<pre class="src src-C++"><span class="org-constant">LB</span>::<span class="org-function-name">LB</span>() : x_(0), y_(0) {}
<span class="org-type">void</span> <span class="org-constant">LB</span>::<span class="org-function-name">t1</span>(<span class="org-type">Result</span>&amp; <span class="org-variable-name">read</span>) {
    <span class="org-constant">std</span>::get&lt;0&gt;(read) = x_.load(<span class="org-constant">std</span>::memory_order_relaxed);
    y_.store(1, <span class="org-constant">std</span>::memory_order_relaxed);
}
<span class="org-type">void</span> <span class="org-constant">LB</span>::<span class="org-function-name">t2</span>(<span class="org-type">Result</span>&amp; <span class="org-variable-name">read</span>) {
    <span class="org-constant">std</span>::get&lt;1&gt;(read) = y_.load(<span class="org-constant">std</span>::memory_order_relaxed);
    x_.store(1, <span class="org-constant">std</span>::memory_order_relaxed);
}
</pre>
</div>
This is the x86 asm code
<pre class="example">00000000000000c0 &lt;litmus::LB::t1(std::__1::tuple&lt;int, int&gt;&amp;)&gt;:
  c0:   mov    eax,DWORD PTR [rdi]
  c2:   mov    DWORD PTR [rsi],eax
  c4:   mov    DWORD PTR [rdi+0x40],0x1
  cb:   ret
  cc:   nop    DWORD PTR [rax+0x0]

00000000000000d0 &lt;litmus::LB::t2(std::__1::tuple&lt;int, int&gt;&amp;)&gt;:
  d0:   mov    eax,DWORD PTR [rdi+0x40]
  d3:   mov    DWORD PTR [rsi+0x4],eax
  d6:   mov    DWORD PTR [rdi],0x1
  dc:   ret
  dd:   nop    DWORD PTR [rax]

</pre>
And the ARM code, at -O1
<pre class="example">000000d0 &lt;litmus::LB::t1(std::tuple&lt;int, int&gt;&amp;)&gt;:
  d0:   ldr     r3, [r0]
  d4:   str     r3, [r1, #4]
  d8:   mov     r3, #1
  dc:   str     r3, [r0, #64]   ; 0x40
  e0:   bx      lr

000000e4 &lt;litmus::LB::t2(std::tuple&lt;int, int&gt;&amp;)&gt;:
  e4:   ldr     r3, [r0, #64]   ; 0x40
  e8:   str     r3, [r1]
  ec:   mov     r3, #1
  f0:   str     r3, [r0]
  f4:   bx      lr

</pre>
ARM generally allows it, but per [<a href="#maranget2012tutorial">maranget2012tutorial</a>] it's very sensitive, and dependencies will make it not appear. In my tests, I did not observe an instance of a buffering, but it may be due to the first store the compiler introduces, in order to actually get the data into the tuple. That it's documented as possible is still exceedingly strange.

</div>
</div>
<div id="outline-container-orgb59ad3f" class="outline-2">
<h2 id="orgb59ad3f">Independent Reads of Independent Writes</h2>
<div id="text-orgb59ad3f" class="outline-text-2">

IRIW is a generalization of store buffering, where two reader threads each read different apparent orderings of writes from two distinct writer threads.
<table border="2" frame="hsides" rules="groups" cellspacing="0" cellpadding="6"><colgroup> <col class="org-left"> <col class="org-left"> <col class="org-left"> <col class="org-left"> </colgroup>
<thead>
<tr>
<th class="org-left" scope="col">T1</th>
<th class="org-left" scope="col">T2</th>
<th class="org-left" scope="col">T3</th>
<th class="org-left" scope="col">T4</th>
</tr>
</thead>
<tbody>
<tr>
<td class="org-left">X = 1</td>
<td class="org-left">Y = 1</td>
<td class="org-left">R1 = X</td>
<td class="org-left">R3 = y</td>
</tr>
<tr>
<td class="org-left"></td>
<td class="org-left"></td>
<td class="org-left">R2 = Y</td>
<td class="org-left">R4 = X</td>
</tr>
<tr>
<td class="org-left"></td>
<td class="org-left"></td>
<td class="org-left"></td>
<td class="org-left"></td>
</tr>
</tbody>
</table>
Initially X=Y=0
Allowed in ARM, not in x86 r1=1, r2=0, r3=1, r4=0 [<a href="#maranget2012tutorial">maranget2012tutorial</a>,<a href="#owens2009better">owens2009better</a>]

This is not observed in x86 processors, but is in some ARM and POWER, more often in POWER. X86 hardware has a consistent view of memory where other hardware can see memory writes in different orders on different threads. On my rPi, I didn't observe any incidents of X and Y being read out of order, over 40 million runs.
<div class="org-src-container">
<pre class="src src-C++"><span class="org-constant">IRIW</span>::<span class="org-function-name">IRIW</span>() : x_(0), y_(0) {}
<span class="org-type">void</span> <span class="org-constant">IRIW</span>::<span class="org-function-name">t1</span>() {
    x_.store(1, <span class="org-constant">std</span>::memory_order_relaxed);
}

<span class="org-type">void</span> <span class="org-constant">IRIW</span>::<span class="org-function-name">t2</span>() {
    y_.store(1, <span class="org-constant">std</span>::memory_order_relaxed);
}

<span class="org-type">void</span> <span class="org-constant">IRIW</span>::<span class="org-function-name">t3</span>(<span class="org-type">Result</span>&amp; <span class="org-variable-name">read</span>) {
    <span class="org-constant">std</span>::get&lt;0&gt;(read) = x_.load(<span class="org-constant">std</span>::memory_order_relaxed);
    <span class="org-constant">std</span>::get&lt;1&gt;(read) = y_.load(<span class="org-constant">std</span>::memory_order_relaxed);
}

<span class="org-type">void</span> <span class="org-constant">IRIW</span>::<span class="org-function-name">t4</span>(<span class="org-type">Result</span>&amp; <span class="org-variable-name">read</span>) {
    <span class="org-constant">std</span>::get&lt;2&gt;(read) = y_.load(<span class="org-constant">std</span>::memory_order_relaxed);
    <span class="org-constant">std</span>::get&lt;3&gt;(read) = x_.load(<span class="org-constant">std</span>::memory_order_relaxed);
}

</pre>
</div>
</div>
</div>
<div id="outline-container-org5fcde9b" class="outline-2">
<h2 id="org5fcde9b">Summary</h2>
<div id="text-org5fcde9b" class="outline-text-2">

The allowed behavior of modern processors is very different than our mental model of a Von Neumann architecture computer. Each core can have a different view of memory, and without additional controls, writes and reads can break the illusion of a single unified memory. The C++ memory model gives the controls and guarantees about what happens when different threads read and write memory, and here I've deliberately used the weakest version available, relaxed, in order to allow the processors the wideest latitude in behavior. Relaxed is, for processors that have it, often just an unconstrained int, which means that you will get odd behavior if you are running shared state multithreaded code that uses plain native types. It is a particular problem with code that was originally written and tested on a x86 architecture because the native model is fairly strong. This frequently causes problems when porting to a mobile platform, where ARM is a very popular hardware choice.

</div>
</div>
<div id="outline-container-org3e9feb6" class="outline-2">
<h2 id="org3e9feb6">Org-mode source and git repo</h2>
<div id="text-org3e9feb6" class="outline-text-2">

Exported from an org-mode doc. All of the source is available on github at <a href="https://github.com/steve-downey/spingate">SpinGate</a>

</div>
</div>
<div id="outline-container-org6b2f228" class="outline-2">
<h2 id="org6b2f228">References</h2>
<div id="text-org6b2f228" class="outline-text-2">
<h1 class="org-ref-bib-h1">Bibliography</h1>
<ul class="org-ref-bib">
    <li><a id="boehm2005threads"></a>[boehm2005threads] <a name="boehm2005threads"></a>Boehm, Threads cannot be implemented as a library, 261-268, in in: ACM Sigplan Notices, edited by (2005)</li>
    <li><a id="bacon2000double"></a>[bacon2000double] <a name="bacon2000double"></a>@miscbacon2000double,
title=The “double-checked locking is broken” declaration,
author=Bacon, David and Bloch, Joshua and Bogda, Jeff and Click, Cliff and Haahr, Paul and Lea, Doug and May, Tom and Maessen, Jan-Willem and Mitchell, JD and Nilsen, Kelvin and others,
year=2000</li>
    <li><a id="IWPAug2007"></a>[IWPAug2007] <a name="IWPAug2007"></a>@miscIWPAug2007,
howpublished =
\urlhttp://www.cs.cmu.edu/~410-f10/doc/Intel_Reordering_318147.pdf,
note = Accessed: 2017-04-30,
title = Intel® 64 Architecture Memory Ordering
White Paper,</li>
    <li><a id="owens2009better"></a>[owens2009better] <a name="owens2009better"></a>Owens, Sarkar &amp; Sewell, A better x86 memory model: x86-TSO, 391-407, in in: International Conference on Theorem Proving in Higher Order Logics, edited by (2009)</li>
    <li><a id="maranget2012tutorial"></a>[maranget2012tutorial] <a name="maranget2012tutorial"></a>Maranget, Sarkar &amp; Sewell, A tutorial introduction to the ARM and POWER relaxed memory models, <i>Draft available from http://www. cl. cam. ac. uk/\~ pes20/ppc-supplemental/test7. pdf</i>, (2012).</li>
</ul>
</div>
</div>
</div>

<div id="postamble" class="status">
<p class="date">Date: 2017-04-30 Sun 00:00</p>
<p class="author">Author: Steve Downey</p>
<p class="date">Created: 2018-06-17 Sun 14:07</p>
<p class="validation"><a href="http://validator.w3.org/check?uri=referer">Validate</a></p>

</div>

 </body></html>