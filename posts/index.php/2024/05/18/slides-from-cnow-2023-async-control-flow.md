<html><body><div id="outline-container-org8b3a3c0" class="outline-2">
<h2 id="org8b3a3c0">Using Sender/Receiver for Async Control Flow</h2>
<div class="outline-text-2" id="text-org8b3a3c0">
<p> Steve Downey </p>

<p> These are the slides, slightly rerendered, from my presentation at C++Now 2023. </p>
</div>
</div>
<div id="outline-container-orga88bc52" class="outline-2">
<h2 id="orga88bc52">Abstract</h2>
<div class="outline-text-2" id="text-orga88bc52">
<p> How can P2300 Senders be composed using sender adapters and sender factories to provide arbitrary program control flow? </p>

<ul class="org-ul">
<li>How do I use these things?</li>
</ul>
<ul class="org-ul">
<li>Where can I steal from?</li>
</ul>

<!-- TEASER_END -->

<div class="notes" id="org36cf365">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-org236dff5" class="outline-2">
<h2 id="org236dff5"><code>std::execution</code></h2>
<div class="outline-text-2" id="text-org236dff5">
<p> <a href="https://wg21.link/P2300">P2300</a> </p>

<p> Recent version at <a href="https://isocpp.org/files/papers/P2300R7.html">https://isocpp.org/files/papers/P2300R7.html</a> </p>

<blockquote>
<p> A self-contained design for a Standard C++ framework for managing asynchronous execution on generic execution resources. </p>
</blockquote>

<div class="notes" id="org8339640">
<p>  </p>

</div>
</div>
<div id="outline-container-orgc5b1e38" class="outline-3">
<h3 id="orgc5b1e38">Three Key Abstractions</h3>
<div class="outline-text-3" id="text-orgc5b1e38">
<ol class="org-ol">
<li><p> Schedulers </p></li>
<li><p> Senders </p></li>
<li>Receivers</li>
</ol>
</div>
<div id="outline-container-org6ffab16" class="outline-4">
<h4 id="org6ffab16">Schedulers</h4>
<div class="outline-text-4" id="text-org6ffab16">
<p> Responsible for scheduling work on execution resources. </p>

<p> Execution resources are things like threads, GPUs, and so on. </p>

<p> Sends work to be done in a place. </p>

<div class="notes" id="orga800408">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-orgf878c5c" class="outline-4">
<h4 id="orgf878c5c">Senders</h4>
<div class="outline-text-4" id="text-orgf878c5c">
<p> Senders describe work. </p>

<div class="notes" id="org3d29294">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-orgf5c2ed9" class="outline-4">
<h4 id="orgf5c2ed9">Receivers</h4>
<div class="outline-text-4" id="text-orgf5c2ed9">
<p> Receivers are where work terminates. </p>

<ul class="org-ul">
<li><p> Value channel </p></li>
<li><p> Error channel </p></li>
<li>Stopped channel</li>
</ul>

<div class="notes" id="org5d9d478">
<p> Work can terminate in three different ways. </p>

<ul class="org-ul">
<li>Return a value.</li>
<li>Throw an exception</li>
<li>Be canceled</li>
</ul>

<p> It's been a few minutes. Lets see some simple code. </p>

</div>
</div>
</div>
<div id="outline-container-orgd098f7f" class="outline-4">
<h4 id="orgd098f7f">Hello Async World</h4>
<div class="outline-text-4" id="text-orgd098f7f">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-C++" id="nil"><span class="linenr"> 1: </span>
<span class="linenr"> 2: </span><span class="org-preprocessor">#include</span> <span class="org-string">&lt;stdexec/execution.hpp&gt;</span>
<span class="linenr"> 3: </span><span class="org-preprocessor">#include</span> <span class="org-string">&lt;exec/static_thread_pool.hpp&gt;</span>
<span class="linenr"> 4: </span><span class="org-preprocessor">#include</span> <span class="org-string">&lt;iostream&gt;</span>
<span class="linenr"> 5: </span>
<span class="linenr"> 6: </span><span class="org-type">int</span> <span class="org-function-name">main</span>() {
<span class="linenr"> 7: </span>  <span class="org-constant">exec</span>::<span class="org-type">static_thread_pool</span> <span class="org-variable-name">pool</span>(8);
<span class="linenr"> 8: </span>
<span class="linenr"> 9: </span>  <span class="org-constant">stdexec</span>::<span class="org-type">scheduler</span> <span class="org-keyword">auto</span> <span class="org-variable-name">sch</span> = pool.get_scheduler();
<span class="linenr">10: </span>
<span class="linenr">11: </span>  <span class="org-constant">stdexec</span>::<span class="org-type">sender</span> <span class="org-keyword">auto</span> <span class="org-variable-name">begin</span> = <span class="org-constant">stdexec</span>::schedule(sch);
<span class="linenr">12: </span>  <span class="org-constant">stdexec</span>::<span class="org-type">sender</span> <span class="org-keyword">auto</span> <span class="org-variable-name">hi</span>    = <span class="org-constant">stdexec</span>::then(begin, [] {
<span class="linenr">13: </span>    <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"Hello world! Have an int.\n"</span>;
<span class="linenr">14: </span>    <span class="org-keyword">return</span> 13;
<span class="linenr">15: </span>  });
<span class="linenr">16: </span>
<span class="linenr">17: </span>  <span class="org-keyword">auto</span> <span class="org-variable-name">add_42</span> = <span class="org-constant">stdexec</span>::then(hi, [](<span class="org-type">int</span> <span class="org-variable-name">arg</span>) { <span class="org-keyword">return</span> arg + 42; });
<span class="linenr">18: </span>
<span class="linenr">19: </span>  <span class="org-keyword">auto</span> [i] = <span class="org-constant">stdexec</span>::sync_wait(add_42).value();
<span class="linenr">20: </span>
<span class="linenr">21: </span>  <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"The int is "</span> &lt;&lt; i &lt;&lt; <span class="org-string">'\n'</span>;
<span class="linenr">22: </span>
<span class="linenr">23: </span>  <span class="org-keyword">return</span> 0;
<span class="linenr">24: </span>}
<span class="linenr">25: </span>
</pre>
</div>


<p> <a href="https://godbolt.org/z/1M5enroaE">Compiler Explorer</a> </p>

<div class="notes" id="org2eb3f3f">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-orgf7d68f0" class="outline-4">
<h4 id="orgf7d68f0">Hello Async World Results</h4>
<div class="outline-text-4" id="text-orgf7d68f0">
<em></em>
<pre class="example" id="nil">
Hello world! Have an int.
The int is 55
</pre>

<div class="notes" id="orgbf13cfb">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-orgd5015b3" class="outline-4">
<h4 id="orgd5015b3">When All - Concurent Async</h4>
<div class="outline-text-4" id="text-orgd5015b3">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="linenr"> 1: </span><span class="org-constant">exec</span>::<span class="org-type">static_thread_pool</span> <span class="org-variable-name">pool</span>(3);
<span class="linenr"> 2: </span>
<span class="linenr"> 3: </span><span class="org-keyword">auto</span> <span class="org-variable-name">sched</span> = pool.get_scheduler();
<span class="linenr"> 4: </span>
<span class="linenr"> 5: </span><span class="org-keyword">auto</span> <span class="org-variable-name">fun</span> = [](<span class="org-type">int</span> <span class="org-variable-name">i</span>) { <span class="org-keyword">return</span> i * i; };
<span class="linenr"> 6: </span>
<span class="linenr"> 7: </span><span class="org-keyword">auto</span> <span class="org-variable-name">work</span> = <span class="org-constant">stdexec</span>::when_all(
<span class="linenr"> 8: </span>    <span class="org-constant">stdexec</span>::on(sched, <span class="org-constant">stdexec</span>::just(0) | <span class="org-constant">stdexec</span>::then(fun)),
<span class="linenr"> 9: </span>    <span class="org-constant">stdexec</span>::on(sched, <span class="org-constant">stdexec</span>::just(1) | <span class="org-constant">stdexec</span>::then(fun)),
<span class="linenr">10: </span>    <span class="org-constant">stdexec</span>::on(sched, <span class="org-constant">stdexec</span>::just(2) | <span class="org-constant">stdexec</span>::then(fun)));
<span class="linenr">11: </span>
<span class="linenr">12: </span><span class="org-keyword">auto</span> [i, j, k] = <span class="org-constant">stdexec</span>::sync_wait(<span class="org-constant">std</span>::move(work)).value();
<span class="linenr">13: </span>
<span class="linenr">14: </span><span class="org-constant">std</span>::printf(<span class="org-string">"%d %d %d\n"</span>, i, j, k);
</pre>
</div>

<div class="notes" id="org5b2f4f0">
<p> Describe some work: </p>

<p> Creates 3 sender pipelines that are executed concurrently by passing to `when_all` </p>

<p> Each sender is scheduled on `sched` using `on` and starts with `just(n)` that creates a Sender that just forwards `n` to the next sender. </p>

<p> After `just(n)`, we chain `then(fun)` which invokes `fun` using the value provided from `just()` </p>

<p> Note: No work actually happens here. Everything is lazy and `work` is just an object that statically represents the work to later be executed </p>

</div>
</div>
</div>
<div id="outline-container-org8c3d7d7" class="outline-4">
<h4 id="org8c3d7d7">When All - Concurent Async - Results</h4>
<div class="outline-text-4" id="text-org8c3d7d7">
<em></em>
<pre class="example" id="nil">
0 1 4
</pre>

<div class="notes" id="orgebda57b">
<p> Order of execution is by chance, order of results is determined. </p>

</div>
</div>
</div>
<div id="outline-container-orgb1730fb" class="outline-4">
<h4 id="orgb1730fb">Dynamic Choice of Sender</h4>
<div class="outline-text-4" id="text-orgb1730fb">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="linenr"> 1: </span><span class="org-constant">exec</span>::<span class="org-type">static_thread_pool</span> <span class="org-variable-name">pool</span>(3);
<span class="linenr"> 2: </span>
<span class="linenr"> 3: </span><span class="org-keyword">auto</span> <span class="org-variable-name">sched</span> = pool.get_scheduler();
<span class="linenr"> 4: </span>
<span class="linenr"> 5: </span><span class="org-keyword">auto</span> <span class="org-variable-name">fun</span> = [](<span class="org-type">int</span> <span class="org-variable-name">i</span>) -&gt; <span class="org-constant">stdexec</span>::sender <span class="org-keyword">auto</span> {
<span class="linenr"> 6: </span>  <span class="org-keyword">using</span> <span class="org-keyword">namespace</span> <span class="org-constant">std</span>::<span class="org-constant">string_literals</span>;
<span class="linenr"> 7: </span>  <span class="org-keyword">if</span> ((i % 2) == 0) {
<span class="linenr"> 8: </span>    <span class="org-keyword">return</span> <span class="org-constant">stdexec</span>::just(<span class="org-string">"even"</span>s);
<span class="linenr"> 9: </span>  } <span class="org-keyword">else</span> {
<span class="linenr">10: </span>    <span class="org-keyword">return</span> <span class="org-constant">stdexec</span>::just(<span class="org-string">"odd"</span>s);
<span class="linenr">11: </span>  }
<span class="linenr">12: </span>};
<span class="linenr">13: </span>
<span class="linenr">14: </span><span class="org-keyword">auto</span> <span class="org-variable-name">work</span> = <span class="org-constant">stdexec</span>::when_all(
<span class="linenr">15: </span>    <span class="org-constant">stdexec</span>::on(sched, <span class="org-constant">stdexec</span>::just(0) | <span class="org-constant">stdexec</span>::let_value(fun)),
<span class="linenr">16: </span>    <span class="org-constant">stdexec</span>::on(sched, <span class="org-constant">stdexec</span>::just(1) | <span class="org-constant">stdexec</span>::let_value(fun)),
<span class="linenr">17: </span>    <span class="org-constant">stdexec</span>::on(sched, <span class="org-constant">stdexec</span>::just(2) | <span class="org-constant">stdexec</span>::let_value(fun)));
<span class="linenr">18: </span>
<span class="linenr">19: </span><span class="org-keyword">auto</span> [i, j, k] = <span class="org-constant">stdexec</span>::sync_wait(<span class="org-constant">std</span>::move(work)).value();
<span class="linenr">20: </span>
<span class="linenr">21: </span><span class="org-constant">std</span>::printf(<span class="org-string">"%s %s %s"</span>, i.c_str(), j.c_str(), k.c_str());
</pre>
</div>

<p> <a href="https://godbolt.org/z/7vx69cMj9">Compiler Explorer</a> </p>

<div class="notes" id="org8b2f9b4">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-orgb681eb0" class="outline-4">
<h4 id="orgb681eb0">Enough API to talk about control flow</h4>
<div class="outline-text-4" id="text-orgb681eb0">
<p> The minimal set being: </p>

<ul class="org-ul">
<li>stdexec::on</li>
<li>stdexec::just</li>
<li>stdexec::then</li>
<li>stdexec::let_value</li>
<li>stdexec::sync_wait</li>
</ul>


<p> I will mostly ignore the error and stop channels </p>

<div class="notes" id="orgd3933b4">
<p>  </p>

</div>
</div>
</div>
</div>
</div>
<div id="outline-container-org294db44" class="outline-2">
<h2 id="org294db44">Vigorous Handwaving</h2>
<div class="outline-text-2" id="text-org294db44">
</div>
<div id="outline-container-orgaa994df" class="outline-3">
<h3 id="orgaa994df">Some Theory</h3>
<div class="outline-text-3" id="text-orgaa994df">
<p> Continuation Passing Style </p>

<div class="notes" id="orgfcb288c">
<p>  </p>

</div>
</div>
<div id="outline-container-orgd5b64c5" class="outline-4">
<h4 id="orgd5b64c5">Not At All New</h4>
<div class="outline-text-4" id="text-orgd5b64c5">
<p> Sussman and Steele in 1975 </p>

<p> <a href="https://dspace.mit.edu/bitstream/handle/1721.1/5794/AIM-349.pdf">AI Memo 349: "Scheme: An Interpreter for Extended Lambda Calculus"</a> </p>

<div class="notes" id="org4fc8969">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-org0871c6c" class="outline-4">
<h4 id="org0871c6c">Pass a "Continuation"</h4>
<div class="outline-text-4" id="text-org0871c6c">
<p> Where to go next rather than return the value. </p>

<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-haskell" id="nil"><span class="org-haskell-definition">add</span> <span class="org-haskell-operator">::</span> <span class="org-haskell-type">Float</span> <span class="org-haskell-operator">-&gt;</span> <span class="org-haskell-type">Float</span> <span class="org-haskell-operator">-&gt;</span> <span class="org-haskell-type">Float</span>
<span class="org-haskell-definition">add</span> a b <span class="org-haskell-operator">=</span> a <span class="org-haskell-operator">+</span> b

<span class="org-haskell-definition">add_cps</span> <span class="org-haskell-operator">::</span> <span class="org-haskell-type">Float</span> <span class="org-haskell-operator">-&gt;</span> <span class="org-haskell-type">Float</span> <span class="org-haskell-operator">-&gt;</span> (<span class="org-haskell-type">Float</span> <span class="org-haskell-operator">-&gt;</span> a) <span class="org-haskell-operator">-&gt;</span> a
<span class="org-haskell-definition">add_cps</span> a b cont <span class="org-haskell-operator">=</span> cont (a <span class="org-haskell-operator">+</span> b)
</pre>
</div>

<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="org-keyword">auto</span> <span class="org-function-name">add</span>(<span class="org-type">float</span> <span class="org-variable-name">a</span>, <span class="org-type">float</span> <span class="org-variable-name">b</span>) -&gt; <span class="org-type">float</span> {
    <span class="org-keyword">return</span> a + b;
}

<span class="org-keyword">template</span>&lt;<span class="org-keyword">typename</span> <span class="org-type">Cont</span>&gt;
<span class="org-keyword">auto</span> <span class="org-function-name">add_cps</span>(<span class="org-type">float</span> <span class="org-variable-name">a</span>, <span class="org-type">float</span> <span class="org-variable-name">b</span>, <span class="org-type">Cont</span> <span class="org-variable-name">k</span>) {
    <span class="org-keyword">return</span> k(a+b);
}
</pre>
</div>

<div class="notes" id="org83586c7">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-org0559af1" class="outline-4">
<h4 id="org0559af1">Inherently a tail call</h4>
<div class="outline-text-4" id="text-org0559af1">
<p> In continuation passing style we never return. </p>

<p> We send a value to the rest of the program. </p>

<p> Hard to express in C++. </p>

<p> Extra machinery necessary to do the plumbing. </p>

<p> Also, some risk, so we don't always do TCO. </p>

<p> We keep the sender "thunks" live so we don't dangle references. </p>

<div class="notes" id="org7ce856a">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-org1e75715" class="outline-4">
<h4 id="org1e75715">Intermittently Popular as a Compiler Technique</h4>
<div class="outline-text-4" id="text-org1e75715">
<p> The transformations of direct functions to CPS are mechanical. </p>

<p> The result is easier to optimize and mechanically reason about. </p>

<p> Equivalent to Single Static Assignment. </p>

<p> Structured Programming can be converted to CPS. </p>

<div class="notes" id="org6493700">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-org9562d05" class="outline-4">
<h4 id="org9562d05">Delimted Continuations</h4>
<div class="outline-text-4" id="text-org9562d05">
<p> General continuations reified as a function. </p>

<blockquote>
<p> Everyone knows that when a process executes a system call like ‘read’, it gets suspended. When the disk delivers the data, the process is resumed. That suspension of a process is its continuation. It is delimited: it is not the check-point of the whole OS, it is the check-point of a process only, from the invocation of main() up to the point main() returns. Normally these suspensions are resumed only once, but can be zero times (exit) or twice (fork). </p>
</blockquote>

<p> Oleg Kiselyov <a href="https://okmij.org/ftp/continuations/Fest2008-talk-notes.pdf">Fest2008-talk-notes.pdf</a> </p>

<div class="notes" id="orgf6e78f9">
<p> If this qoute reminds you of coroutines, you are paying attention. </p>

</div>
</div>
</div>
<div id="outline-container-org9068f85" class="outline-4">
<h4 id="org9068f85">Haskell's Cont Type</h4>
<div class="outline-text-4" id="text-org9068f85">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-haskell" id="nil"><span class="org-haskell-keyword">newtype</span> <span class="org-haskell-type">Cont</span> r a <span class="org-haskell-operator">=</span> <span class="org-haskell-constructor">Cont</span> { runCont <span class="org-haskell-operator">::</span> (a <span class="org-haskell-operator">-&gt;</span> r) <span class="org-haskell-operator">-&gt;</span> r }
</pre>
</div>

<p> This is <u>roughly</u> equivalent to the sender value channel. A Cont takes a reciever, a function that consumes the value being sent, and produces an r, the result type. </p>

<p> The <code>identity</code> function is often used. </p>
</div>
</div>
<div id="outline-container-org172f559" class="outline-4">
<h4 id="org172f559">Underlies <code>std::execution</code></h4>
<div class="outline-text-4" id="text-org172f559">
<p> The plumbing is hidden. </p>

<p> Senders "send" to their continuations, delimted by the Reciever. </p>

<div class="notes" id="orgd311a42">
<p>  </p>

</div>
</div>
</div>
</div>
<div id="outline-container-orgf9763ec" class="outline-3">
<h3 id="orgf9763ec">Another Level of Indirection</h3>
<div class="outline-text-3" id="text-orgf9763ec">
</div>
<div id="outline-container-org68f9649" class="outline-4">
<h4 id="org68f9649">Solves all problems</h4>
<div class="outline-text-4" id="text-org68f9649">
<p> Adds two more. </p>

<p> At least </p>

<div class="notes" id="orgb13c3fd">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-orga29d66f" class="outline-4">
<h4 id="orga29d66f">CPS Indirects Function Return</h4>
<div class="outline-text-4" id="text-orga29d66f">
<p> Transform a function </p>

<p style="text-align:center"> $latex   A  \rightarrow B   $ </p>


<p> to </p>

<p style="text-align:center"> $latex   A  \rightarrow B  \rightarrow ( B \rightarrow R ) \rightarrow R   $ </p>


<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-haskell" id="nil"><span class="org-haskell-definition">add</span> <span class="org-haskell-operator">::</span> <span class="org-haskell-type">Float</span> <span class="org-haskell-operator">-&gt;</span> <span class="org-haskell-type">Float</span> <span class="org-haskell-operator">-&gt;</span> <span class="org-haskell-type">Float</span>
<span class="org-haskell-definition">add</span> a b <span class="org-haskell-operator">=</span> a <span class="org-haskell-operator">+</span> b

<span class="org-haskell-definition">add_cps</span> <span class="org-haskell-operator">::</span> <span class="org-haskell-type">Float</span> <span class="org-haskell-operator">-&gt;</span> <span class="org-haskell-type">Float</span> <span class="org-haskell-operator">-&gt;</span> (<span class="org-haskell-type">Float</span> <span class="org-haskell-operator">-&gt;</span> <span class="org-haskell-type">A</span>) <span class="org-haskell-operator">-&gt;</span> <span class="org-haskell-type">A</span>
<span class="org-haskell-definition">add_cps</span> a b cont <span class="org-haskell-operator">=</span> cont (a <span class="org-haskell-operator">+</span> b)
</pre>
</div>


<div class="notes" id="orgde3c0e9">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-orgaf9b3e1" class="outline-4">
<h4 id="orgaf9b3e1">Sender Closes Over A</h4>
<div class="outline-text-4" id="text-orgaf9b3e1">
<p style="text-align:center"> $latex   B  \rightarrow ( B \rightarrow R ) \rightarrow R   $ </p>

<p> The $LATEX A$ is (mostly) erased from the Sender. </p>
</div>
</div>
<div id="outline-container-org2621484" class="outline-4">
<h4 id="org2621484">Reciever Is The Transform to Result</h4>
<div class="outline-text-4" id="text-org2621484">
<p style="text-align:center"> $latex   ( B \rightarrow R ) \rightarrow R   $ </p>
</div>
</div>
</div>
<div id="outline-container-org4c55ea0" class="outline-3">
<h3 id="org4c55ea0">Some Pictures</h3>
<div class="outline-text-3" id="text-org4c55ea0">
</div>
<div id="outline-container-org5e7ea49" class="outline-5">
<h5 id="org5e7ea49">Sender</h5>
<div class="outline-text-5" id="text-org5e7ea49">
<div id="org2d613b7" class="figure"> <p><img src="/wp-content/uploads/2024/05/sender.png" alt="sender.png"> </p> </div>
</div>
</div>
<div id="outline-container-orgb5de8b8" class="outline-5">
<h5 id="orgb5de8b8"><code>just</code></h5>
<div class="outline-text-5" id="text-orgb5de8b8">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="org-constant">stdexec</span>::just(0)
</pre>
</div>

<div id="org23c38c7" class="figure"> <p><img src="/wp-content/uploads/2024/05/just.png" alt="just.png"> </p> </div>
</div>
</div>
<div id="outline-container-org533dd2e" class="outline-5">
<h5 id="org533dd2e"><code>then</code></h5>
<div class="outline-text-5" id="text-org533dd2e">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="org-keyword">auto</span> <span class="org-function-name">f</span>(<span class="org-type">A</span> <span class="org-variable-name">a</span>) -&gt; <span class="org-type">B</span>;
<span class="org-keyword">auto</span> <span class="org-variable-name">s</span> = <span class="org-constant">stdexec</span>::just(a) | <span class="org-constant">stdexec</span>::then(f);
</pre>
</div>

<div id="org7400c8c" class="figure"> <p><img src="/wp-content/uploads/2024/05/then.png" alt="then.png"> </p> </div>
</div>
</div>
<div id="outline-container-orgf0c5b3f" class="outline-5">
<h5 id="orgf0c5b3f"><code>let_value</code></h5>
<div class="outline-text-5" id="text-orgf0c5b3f">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="org-type">sender_of</span>&lt;<span class="org-type">set_value_t</span>(<span class="org-variable-name">B</span>)&gt; <span class="org-keyword">auto</span> <span class="org-function-name">snd</span>(<span class="org-type">A</span> <span class="org-variable-name">a</span>);
<span class="org-keyword">auto</span> <span class="org-variable-name">s</span> = <span class="org-constant">stdexec</span>::just(a) | <span class="org-constant">stdexec</span>::let_value(snd);
</pre>
</div>

<div id="org8f34211" class="figure"> <p><img src="/wp-content/uploads/2024/05/let_value.png" alt="let_value.png"> </p> </div>
</div>
</div>
</div>
<div id="outline-container-org5ac08ab" class="outline-3">
<h3 id="org5ac08ab">In which we use the M word</h3>
<div class="outline-text-3" id="text-org5ac08ab">
</div>
<div id="outline-container-org134a392" class="outline-4">
<h4 id="org134a392">Sender is a Monad</h4>
<div class="outline-text-4" id="text-org134a392">
<p> (surprise) </p>

<p> (shock, dismay) </p>

<div class="notes" id="orgdbe487b">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-org8b69996" class="outline-4">
<h4 id="org8b69996">Function Composition is the hint</h4>
<div class="outline-text-4" id="text-org8b69996">
<p> Functions are units of work. </p>

<p> We compose them into programs. </p>

<p> The question is if the rules apply. </p>

<div class="notes" id="org981c41e">
<p>  </p>

</div>
</div>
</div>
<div id="outline-container-orge30880f" class="outline-4">
<h4 id="orge30880f">Monadic Interface</h4>
<div class="outline-text-4" id="text-orge30880f">
<dl class="org-dl">
<dt>bind or and_then</dt><dd><p style="text-align:center"> $latex   M \langle a \rangle \rightarrow (a \rightarrow M \langle b \rangle ) \rightarrow M \langle b \rangle   $ </p></dd>

<dt>fish or kleisli arrow </dt><dd><p style="text-align:center"> $latex   (a \rightarrow M \langle b \rangle ) \rightarrow (b \rightarrow M \langle c \rangle ) \rightarrow (a \rightarrow M \langle c \rangle )   $ </p></dd>

<dt>join or flatten or mconcat</dt><dd><p style="text-align:center"> $latex   M \langle M \langle a \rangle \rangle \rightarrow  M \langle a \rangle   $ </p></dd>
</dl>

<div class="notes" id="orgb4e34d8">
<p> Monad Interface </p>

</div>
</div>
</div>
<div id="outline-container-orgadd7e17" class="outline-4">
<h4 id="orgadd7e17">Applicative and Functor parts</h4>
<div class="outline-text-4" id="text-orgadd7e17">
<dl class="org-dl">
<dt>make or pure or return</dt><dd><p style="text-align:center"> $latex   a  \rightarrow  M \langle a \rangle   $ </p></dd>

<dt>fmap or transform</dt><dd><p style="text-align:center"> $latex     (a \rightarrow b) \rightarrow M \langle a \rangle \rightarrow M \langle b \rangle    $ </p></dd>
</dl>

<p> Any one of the first three and one of the second two can define the other three </p>

<div class="notes" id="org1ea8d66">
<p> Monad Interface </p>

</div>
</div>
</div>
<div id="outline-container-org8809cf7" class="outline-4">
<h4 id="org8809cf7">Monad Laws</h4>
<div class="outline-text-4" id="text-org8809cf7">
<dl class="org-dl">
<dt>left identity</dt><dd>bind(pure(a), h) == h(a)</dd>
<dt>right identity</dt><dd>bind(m, pure) == m</dd>
<dt>associativity</dt><dd>bind(bind(m, g), h) == bind(m, bind((\x -&gt; g(x), h))</dd>
</dl>

<div class="notes" id="orgdeee1f4">
<p> Monad Laws </p>

</div>
</div>
</div>
<div id="outline-container-org4a2ed42" class="outline-4">
<h4 id="org4a2ed42">Sender is Three Monads in a Trench-coat</h4>
<div class="outline-text-4" id="text-org4a2ed42">
<p> Stacked up. </p>

<ul class="org-ul">
<li>Value</li>
<li>Error</li>
<li>Stopped</li>
</ul>

<div class="notes" id="orge90651e">
<p> The three channels can be crossed, mixed, and remixed. Focus on the value channel for simplicity. </p>

</div>
</div>
</div>
</div>
<div id="outline-container-orgd26dd21" class="outline-3">
<h3 id="orgd26dd21">The Three Monadic Parts</h3>
<div class="outline-text-3" id="text-orgd26dd21">
<div class="notes" id="org2736585">
<p>  </p>

</div>
</div>
<div id="outline-container-orgec26678" class="outline-4">
<h4 id="orgec26678"><code>just</code></h4>
<div class="outline-text-4" id="text-orgec26678">
<p> Send a value. </p>

<p> <code>pure</code> </p>

<div class="notes" id="orga22f135">
<p> just lifts a value into the monad </p>

</div>
</div>
</div>
<div id="outline-container-orgfe3008d" class="outline-4">
<h4 id="orgfe3008d"><code>then</code></h4>
<div class="outline-text-4" id="text-orgfe3008d">
<p> Send a value returned from a function that takes its argument from a Sender. </p>

<p> <code>fmap</code> or <code>transform</code> </p>

<div class="notes" id="org4ce6d5a">
<p> then is the functor fmap </p>

</div>
</div>
</div>
<div id="outline-container-org19ddb5d" class="outline-4">
<h4 id="org19ddb5d"><code>let_value</code></h4>
<div class="outline-text-4" id="text-org19ddb5d">
<p> Send what is returned by a Sender returned from a function that takes its argument from a Sender. </p>

<p> <code>bind</code> </p>

<div class="notes" id="orga0ab095">
<p> let value is the monadic bind </p>

</div>
</div>
</div>
<div id="outline-container-org65d75e4" class="outline-4">
<h4 id="org65d75e4">Necessary and Sufficient</h4>
<div class="outline-text-4" id="text-org65d75e4">
<p> The monadic bind gives us the runtime choices we need. </p>

<div class="notes" id="org3710183">
<p>  </p>

</div>
</div>
</div>
</div>
<div id="outline-container-org9a8af39" class="outline-3">
<h3 id="org9a8af39">Basis of Control</h3>
<div class="outline-text-3" id="text-org9a8af39">
<ul class="org-ul">
<li>Sequence</li>
<li>Decision</li>
<li>Recursion</li>
</ul>

<div class="notes" id="org24383ab">
<p>  </p>

</div>
</div>
<div id="outline-container-org9ba54a2" class="outline-4">
<h4 id="org9ba54a2">Sequence</h4>
<div class="outline-text-4" id="text-org9ba54a2">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="linenr"> 1: </span>  <span class="org-constant">stdexec</span>::<span class="org-type">sender</span> <span class="org-keyword">auto</span> <span class="org-variable-name">work</span> =
<span class="linenr"> 2: </span>      <span class="org-constant">stdexec</span>::schedule(sch)
<span class="linenr"> 3: </span>      | <span class="org-constant">stdexec</span>::then([] {
<span class="linenr"> 4: </span>          <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"Hello world! Have an int."</span>;
<span class="linenr"> 5: </span>          <span class="org-keyword">return</span> 13;
<span class="linenr"> 6: </span>      })
<span class="linenr"> 7: </span>      | <span class="org-constant">stdexec</span>::then([](<span class="org-type">int</span> <span class="org-variable-name">arg</span>) { <span class="org-keyword">return</span> arg + 42; });
<span class="linenr"> 8: </span>
<span class="linenr"> 9: </span>  <span class="org-keyword">auto</span> [i] = <span class="org-constant">stdexec</span>::sync_wait(work).value();
<span class="linenr">10: </span>
</pre>
</div>

<div class="notes" id="org27c1c32">
<p> One thing after another. </p>

</div>
</div>
</div>
<div id="outline-container-org72e7b8d" class="outline-4">
<h4 id="org72e7b8d">Decision</h4>
<div class="outline-text-4" id="text-org72e7b8d">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="linenr"> 1: </span><span class="org-constant">exec</span>::<span class="org-type">static_thread_pool</span> <span class="org-variable-name">pool</span>(8);
<span class="linenr"> 2: </span>
<span class="linenr"> 3: </span><span class="org-constant">stdexec</span>::<span class="org-type">scheduler</span> <span class="org-keyword">auto</span> <span class="org-variable-name">sch</span> = pool.get_scheduler();
<span class="linenr"> 4: </span>
<span class="linenr"> 5: </span><span class="org-constant">stdexec</span>::<span class="org-type">sender</span> <span class="org-keyword">auto</span> <span class="org-variable-name">begin</span>  = <span class="org-constant">stdexec</span>::schedule(sch);
<span class="linenr"> 6: </span><span class="org-constant">stdexec</span>::<span class="org-type">sender</span> <span class="org-keyword">auto</span> <span class="org-variable-name">seven</span>  = <span class="org-constant">stdexec</span>::just(7);
<span class="linenr"> 7: </span><span class="org-constant">stdexec</span>::<span class="org-type">sender</span> <span class="org-keyword">auto</span> <span class="org-variable-name">eleven</span> = <span class="org-constant">stdexec</span>::just(11);
<span class="linenr"> 8: </span>
<span class="linenr"> 9: </span><span class="org-constant">stdexec</span>::<span class="org-type">sender</span> <span class="org-keyword">auto</span> <span class="org-variable-name">branch</span> =
<span class="linenr">10: </span>    begin
<span class="linenr">11: </span>    | <span class="org-constant">stdexec</span>::then([]() { <span class="org-keyword">return</span> <span class="org-constant">std</span>::make_tuple(5, 4); })
<span class="linenr">12: </span>    | <span class="org-constant">stdexec</span>::let_value(
<span class="linenr">13: </span>        [=](<span class="org-keyword">auto</span> <span class="org-variable-name">tpl</span>) {
<span class="linenr">14: </span>        <span class="org-keyword">auto</span> <span class="org-keyword">const</span>&amp; [<span class="org-constant">i</span>, <span class="org-constant">j</span>] = tpl;
<span class="linenr">15: </span>
<span class="linenr">16: </span>        <span class="org-keyword">return</span> tst((i &gt; j),
<span class="linenr">17: </span>                   seven | <span class="org-constant">stdexec</span>::then([&amp;](<span class="org-type">int</span> <span class="org-variable-name">k</span>) <span class="org-keyword">noexcept</span> {
<span class="linenr">18: </span>                       <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"true branch "</span> &lt;&lt; k &lt;&lt; <span class="org-string">'\n'</span>;
<span class="linenr">19: </span>                   }),
<span class="linenr">20: </span>                   eleven | <span class="org-constant">stdexec</span>::then([&amp;](<span class="org-type">int</span> <span class="org-variable-name">k</span>) <span class="org-keyword">noexcept</span> {
<span class="linenr">21: </span>                       <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"false branch "</span> &lt;&lt; k &lt;&lt; <span class="org-string">'\n'</span>;
<span class="linenr">22: </span>                   }));
<span class="linenr">23: </span>    });
<span class="linenr">24: </span>
<span class="linenr">25: </span><span class="org-constant">stdexec</span>::sync_wait(<span class="org-constant">std</span>::move(branch));
</pre>
</div>

<em></em>
<pre class="example" id="nil">
true branch 7
</pre>

<div class="notes" id="org6433988">
<p> Control what sender is sent at rentime depending on the state of the program when the work is executing rather than in the structure of the senders. </p>

</div>
</div>
<div id="outline-container-orgbaa8db1" class="outline-5">
<h5 id="orgbaa8db1"><code>tst</code> function</h5>
<div class="outline-text-5" id="text-orgbaa8db1">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="linenr"> 1: </span><span class="org-keyword">inline</span> <span class="org-keyword">auto</span> <span class="org-variable-name">tst</span> = [](<span class="org-type">bool</span>                 <span class="org-variable-name">cond</span>,
<span class="linenr"> 2: </span>                     <span class="org-constant">stdexec</span>::<span class="org-type">sender</span> <span class="org-keyword">auto</span> <span class="org-variable-name">left</span>,
<span class="linenr"> 3: </span>                     <span class="org-constant">stdexec</span>::<span class="org-type">sender</span> <span class="org-keyword">auto</span> <span class="org-variable-name">right</span>)
<span class="linenr"> 4: </span>    -&gt; <span class="org-constant">exec</span>::<span class="org-type">variant_sender</span>&lt;<span class="org-keyword">decltype</span>(left),
<span class="linenr"> 5: </span>                            <span class="org-keyword">decltype</span>(right)&gt; {
<span class="linenr"> 6: </span>  <span class="org-keyword">if</span> (cond)
<span class="linenr"> 7: </span>    <span class="org-keyword">return</span> left;
<span class="linenr"> 8: </span>  <span class="org-keyword">else</span>
<span class="linenr"> 9: </span>    <span class="org-keyword">return</span> right;
<span class="linenr">10: </span>};
<span class="linenr">11: </span>
</pre>
</div>
</div>
</div>
</div>
<div id="outline-container-org84e1bd6" class="outline-4">
<h4 id="org84e1bd6">Recursion</h4>
<div class="outline-text-4" id="text-org84e1bd6">
<div class="notes" id="org5757047">
<p>  </p>

</div>
</div>
<div id="outline-container-org64da46e" class="outline-5">
<h5 id="org64da46e">Simple Recursion</h5>
<div class="outline-text-5" id="text-org64da46e">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="linenr"> 1: </span>
<span class="linenr"> 2: </span><span class="org-keyword">using</span> <span class="org-type">any_int_sender</span> =
<span class="linenr"> 3: </span>    <span class="org-type">any_sender_of</span>&lt;<span class="org-constant">stdexec</span>::set_value_t(<span class="org-type">int</span>),
<span class="linenr"> 4: </span>                  <span class="org-constant">stdexec</span>::set_stopped_t(),
<span class="linenr"> 5: </span>                  <span class="org-constant">stdexec</span>::set_error_t(<span class="org-constant">std</span>::exception_ptr)&gt;;
<span class="linenr"> 6: </span>
<span class="linenr"> 7: </span><span class="org-keyword">auto</span> <span class="org-function-name">fac</span>(<span class="org-type">int</span> <span class="org-variable-name">n</span>) -&gt; <span class="org-type">any_int_sender</span> {
<span class="linenr"> 8: </span>    <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"factorial of "</span> &lt;&lt; n &lt;&lt; <span class="org-string">"\n"</span>;
<span class="linenr"> 9: </span>    <span class="org-keyword">if</span> (n == 0)
<span class="linenr">10: </span>        <span class="org-keyword">return</span> <span class="org-constant">stdexec</span>::just(1);
<span class="linenr">11: </span>
<span class="linenr">12: </span>    <span class="org-keyword">return</span> <span class="org-constant">stdexec</span>::just(n - 1)
<span class="linenr">13: </span>        | <span class="org-constant">stdexec</span>::let_value([](<span class="org-type">int</span> <span class="org-variable-name">k</span>) { <span class="org-keyword">return</span> fac(k); })
<span class="linenr">14: </span>        | <span class="org-constant">stdexec</span>::then([<span class="org-constant">n</span>](<span class="org-type">int</span> <span class="org-variable-name">k</span>) { <span class="org-keyword">return</span> k * n; });
<span class="linenr">15: </span>}
<span class="linenr">16: </span>
</pre>
</div>

<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="linenr"> 1: </span>
<span class="linenr"> 2: </span>    <span class="org-type">int</span>                  <span class="org-variable-name">k</span> = 10;
<span class="linenr"> 3: </span>    <span class="org-constant">stdexec</span>::<span class="org-type">sender</span> <span class="org-keyword">auto</span> <span class="org-variable-name">factorial</span> =
<span class="linenr"> 4: </span>        begin
<span class="linenr"> 5: </span>        | <span class="org-constant">stdexec</span>::then([=]() { <span class="org-keyword">return</span> k; })
<span class="linenr"> 6: </span>        | <span class="org-constant">stdexec</span>::let_value([](<span class="org-type">int</span> <span class="org-variable-name">k</span>) { <span class="org-keyword">return</span> fac(k); });
<span class="linenr"> 7: </span>
<span class="linenr"> 8: </span>    <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"factorial built\n\n"</span>;
<span class="linenr"> 9: </span>
<span class="linenr">10: </span>    <span class="org-keyword">auto</span> [i] = <span class="org-constant">stdexec</span>::sync_wait(<span class="org-constant">std</span>::move(factorial)).value();
<span class="linenr">11: </span>    <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"factorial "</span> &lt;&lt; k &lt;&lt; <span class="org-string">" = "</span> &lt;&lt; i &lt;&lt; <span class="org-string">'\n'</span>;
<span class="linenr">12: </span>
</pre>
</div>

<em></em>
<pre class="example" id="nil">
factorial built

factorial of 10
factorial of 9
factorial of 8
factorial of 7
factorial of 6
factorial of 5
factorial of 4
factorial of 3
factorial of 2
factorial of 1
factorial of 0
factorial 10 = 3628800
</pre>
</div>
</div>
<div id="outline-container-orgfc40dd9" class="outline-5">
<h5 id="orgfc40dd9">General Recursion</h5>
<div class="outline-text-5" id="text-orgfc40dd9">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="linenr"> 1: </span><span class="org-keyword">auto</span> <span class="org-function-name">fib</span>(<span class="org-type">int</span> <span class="org-variable-name">n</span>) -&gt; <span class="org-type">any_int_sender</span> {
<span class="linenr"> 2: </span>    <span class="org-keyword">if</span> (n == 0)
<span class="linenr"> 3: </span>        <span class="org-keyword">return</span> <span class="org-constant">stdexec</span>::on(getDefaultScheduler(),  <span class="org-constant">stdexec</span>::just(0));
<span class="linenr"> 4: </span>
<span class="linenr"> 5: </span>    <span class="org-keyword">if</span> (n == 1)
<span class="linenr"> 6: </span>        <span class="org-keyword">return</span> <span class="org-constant">stdexec</span>::on(getDefaultScheduler(), <span class="org-constant">stdexec</span>::just(1));
<span class="linenr"> 7: </span>
<span class="linenr"> 8: </span>    <span class="org-keyword">auto</span> <span class="org-variable-name">work</span> = <span class="org-constant">stdexec</span>::when_all(
<span class="linenr"> 9: </span>                    <span class="org-constant">stdexec</span>::on(getDefaultScheduler(), <span class="org-constant">stdexec</span>::just(n - 1)) |
<span class="linenr">10: </span>                        <span class="org-constant">stdexec</span>::let_value([](<span class="org-type">int</span> <span class="org-variable-name">k</span>) { <span class="org-keyword">return</span> fib(k); }),
<span class="linenr">11: </span>                    <span class="org-constant">stdexec</span>::on(getDefaultScheduler(), <span class="org-constant">stdexec</span>::just(n - 2)) |
<span class="linenr">12: </span>                        <span class="org-constant">stdexec</span>::let_value([](<span class="org-type">int</span> <span class="org-variable-name">k</span>) { <span class="org-keyword">return</span> fib(k); })) |
<span class="linenr">13: </span>                <span class="org-constant">stdexec</span>::then([](<span class="org-keyword">auto</span> <span class="org-variable-name">i</span>, <span class="org-keyword">auto</span> <span class="org-variable-name">j</span>) { <span class="org-keyword">return</span> i + j; });
<span class="linenr">14: </span>
<span class="linenr">15: </span>    <span class="org-keyword">return</span> work;
<span class="linenr">16: </span>}
<span class="linenr">17: </span>
</pre>
</div>

<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="linenr"> 1: </span>
<span class="linenr"> 2: </span><span class="org-type">int</span>                  <span class="org-variable-name">k</span> = 30;
<span class="linenr"> 3: </span>    <span class="org-constant">stdexec</span>::<span class="org-type">sender</span> <span class="org-keyword">auto</span> <span class="org-variable-name">fibonacci</span> =
<span class="linenr"> 4: </span>        begin | <span class="org-constant">stdexec</span>::then([=]() { <span class="org-keyword">return</span> k; }) |
<span class="linenr"> 5: </span>        <span class="org-constant">stdexec</span>::let_value([](<span class="org-type">int</span> <span class="org-variable-name">k</span>) { <span class="org-keyword">return</span> fib(k); });
<span class="linenr"> 6: </span>
<span class="linenr"> 7: </span>    <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"fibonacci built\n"</span>;
<span class="linenr"> 8: </span>
<span class="linenr"> 9: </span>    <span class="org-keyword">auto</span> [i] = <span class="org-constant">stdexec</span>::sync_wait(<span class="org-constant">std</span>::move(fibonacci)).value();
<span class="linenr">10: </span>    <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"fibonacci "</span> &lt;&lt; k &lt;&lt; <span class="org-string">" = "</span> &lt;&lt; i &lt;&lt; <span class="org-string">'\n'</span>;
</pre>
</div>

<em></em>
<pre class="example" id="nil">
fibonacci built
fibonacci 30 = 832040
fibonacci 30 = 832040
</pre>
</div>
</div>
<div id="outline-container-org5fd882c" class="outline-5">
<h5 id="org5fd882c">Fold</h5>
<div class="outline-text-5" id="text-org5fd882c">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="linenr"> 1: </span>
<span class="linenr"> 2: </span>        <span class="org-keyword">if</span> (first == last) {
<span class="linenr"> 3: </span>            <span class="org-keyword">return</span> <span class="org-constant">stdexec</span>::just(U{<span class="org-constant">std</span>::move(init)});
<span class="linenr"> 4: </span>        }
<span class="linenr"> 5: </span>
<span class="linenr"> 6: </span>        <span class="org-keyword">auto</span> <span class="org-variable-name">nxt</span> =
<span class="linenr"> 7: </span>            <span class="org-constant">stdexec</span>::just(<span class="org-constant">std</span>::invoke(f, <span class="org-constant">std</span>::move(init), *first)) |
<span class="linenr"> 8: </span>            <span class="org-constant">stdexec</span>::let_value([<span class="org-keyword">this</span>,
<span class="linenr"> 9: </span>                                <span class="org-variable-name">first</span> = first,
<span class="linenr">10: </span>                                <span class="org-variable-name">last</span> = last,
<span class="linenr">11: </span>                                <span class="org-variable-name">f</span> = f
<span class="linenr">12: </span>                                ](<span class="org-type">U</span> <span class="org-variable-name">u</span>) {
<span class="linenr">13: </span>                <span class="org-type">I</span> <span class="org-variable-name">i</span> = first;
<span class="linenr">14: </span>                <span class="org-keyword">return</span> (*<span class="org-keyword">this</span>)(++i, last, u, f);
<span class="linenr">15: </span>            });
<span class="linenr">16: </span>        <span class="org-keyword">return</span> <span class="org-constant">std</span>::move(nxt);
</pre>
</div>

<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="linenr"> 1: </span>
<span class="linenr"> 2: </span>    <span class="org-keyword">auto</span> <span class="org-variable-name">v</span> = <span class="org-constant">std</span>::<span class="org-constant">ranges</span>::iota_view{1, 10'000};
<span class="linenr"> 3: </span>
<span class="linenr"> 4: </span>    <span class="org-constant">stdexec</span>::<span class="org-type">sender</span> <span class="org-keyword">auto</span> <span class="org-variable-name">work</span> =
<span class="linenr"> 5: </span>        begin
<span class="linenr"> 6: </span>        | <span class="org-constant">stdexec</span>::let_value([<span class="org-variable-name">i</span> = <span class="org-constant">std</span>::<span class="org-constant">ranges</span>::begin(v),
<span class="linenr"> 7: </span>                              <span class="org-variable-name">s</span> = <span class="org-constant">std</span>::<span class="org-constant">ranges</span>::end(v)]() {
<span class="linenr"> 8: </span>            <span class="org-keyword">return</span> fold_left(i, s, 0, [](<span class="org-type">int</span> <span class="org-variable-name">i</span>, <span class="org-type">int</span> <span class="org-variable-name">j</span>) { <span class="org-keyword">return</span> i + j; });
<span class="linenr"> 9: </span>        });
<span class="linenr">10: </span>
<span class="linenr">11: </span>    <span class="org-keyword">auto</span> [i] = <span class="org-constant">stdexec</span>::sync_wait(<span class="org-constant">std</span>::move(work)).value();
<span class="linenr">12: </span>
</pre>
</div>

<em></em>
<pre class="example" id="nil">
work  = 49995000
</pre>
</div>
</div>
<div id="outline-container-orgcb782a7" class="outline-5">
<h5 id="orgcb782a7">Backtrack</h5>
<div class="outline-text-5" id="text-orgcb782a7">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="org-keyword">using</span> <span class="org-type">any_node_sender</span> =
    <span class="org-type">any_sender_of</span>&lt;<span class="org-constant">stdexec</span>::set_value_t(<span class="org-constant">tree</span>::<span class="org-type">NodePtr</span>&lt;<span class="org-type">int</span>&gt;),
                  <span class="org-constant">stdexec</span>::set_stopped_t(),
                  <span class="org-constant">stdexec</span>::set_error_t(<span class="org-constant">std</span>::exception_ptr)&gt;;

<span class="org-keyword">auto</span> <span class="org-function-name">search_tree</span>(<span class="org-keyword">auto</span>                    <span class="org-variable-name">test</span>,
                 <span class="org-constant">tree</span>::<span class="org-type">NodePtr</span>&lt;<span class="org-type">int</span>&gt;      <span class="org-variable-name">tree</span>,
                 <span class="org-constant">stdexec</span>::<span class="org-type">scheduler</span> <span class="org-keyword">auto</span> <span class="org-variable-name">sch</span>,
                 <span class="org-type">any_node_sender</span>&amp;&amp;       <span class="org-variable-name">fail</span>) -&gt; <span class="org-type">any_node_sender</span> {
    <span class="org-keyword">if</span> (tree == <span class="org-constant">nullptr</span>) {
        <span class="org-keyword">return</span> <span class="org-constant">std</span>::move(fail);
    }
    <span class="org-keyword">if</span> (test(tree)) {
        <span class="org-keyword">return</span> <span class="org-constant">stdexec</span>::just(tree);
    }
    <span class="org-keyword">return</span> <span class="org-constant">stdexec</span>::on(sch, <span class="org-constant">stdexec</span>::just()) |
           <span class="org-constant">stdexec</span>::let_value([=, <span class="org-variable-name">fail</span> = <span class="org-constant">std</span>::move(fail)]() <span class="org-keyword">mutable</span> {
               <span class="org-keyword">return</span> search_tree(
                   test,
                   tree-&gt;left(),
                   sch,
                   <span class="org-constant">stdexec</span>::on(sch, <span class="org-constant">stdexec</span>::just()) |
                       <span class="org-constant">stdexec</span>::let_value(
                           [=, <span class="org-variable-name">fail</span> = <span class="org-constant">std</span>::move(fail)]() <span class="org-keyword">mutable</span> {
                               <span class="org-keyword">return</span> search_tree(
                                   test, tree-&gt;right(), sch, <span class="org-constant">std</span>::move(fail));
                           }));
           });
    <span class="org-keyword">return</span> fail;
}
</pre>
</div>

<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil">    <span class="org-constant">tree</span>::<span class="org-type">NodePtr</span>&lt;<span class="org-type">int</span>&gt; <span class="org-variable-name">t</span>;
    <span class="org-keyword">for</span> (<span class="org-keyword">auto</span> <span class="org-variable-name">i</span> : <span class="org-constant">std</span>::<span class="org-constant">ranges</span>::<span class="org-constant">views</span>::iota(1, 10'000)) {
        <span class="org-constant">tree</span>::<span class="org-constant">Tree</span>&lt;<span class="org-type">int</span>&gt;::insert(i, t);
    }

    <span class="org-keyword">auto</span> <span class="org-variable-name">test</span> = [](<span class="org-constant">tree</span>::<span class="org-type">NodePtr</span>&lt;<span class="org-type">int</span>&gt; <span class="org-variable-name">t</span>) -&gt; <span class="org-type">bool</span> {
        <span class="org-keyword">return</span> t ? t-&gt;data() == 500 : <span class="org-constant">false</span>;
    };

    <span class="org-keyword">auto</span> <span class="org-variable-name">fail</span> = begin | <span class="org-constant">stdexec</span>::then([]() { <span class="org-keyword">return</span> <span class="org-constant">tree</span>::<span class="org-type">NodePtr</span>&lt;<span class="org-type">int</span>&gt;{}; });

    <span class="org-constant">stdexec</span>::<span class="org-type">sender</span> <span class="org-keyword">auto</span> <span class="org-variable-name">work</span> =
        begin | <span class="org-constant">stdexec</span>::let_value([=]() {
            <span class="org-keyword">return</span> search_tree(test, t, sch, <span class="org-constant">std</span>::move(fail));
        });

    <span class="org-keyword">auto</span> [n] = <span class="org-constant">stdexec</span>::sync_wait(<span class="org-constant">std</span>::move(work)).value();

    <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"work "</span>
              &lt;&lt; <span class="org-string">" = "</span> &lt;&lt; n-&gt;data() &lt;&lt; <span class="org-string">'\n'</span>;
</pre>
</div>

<em></em>
<pre class="example" id="nil">
work  = 500
</pre>
</div>
</div>
</div>
</div>
</div>
<div id="outline-container-org91abfba" class="outline-2">
<h2 id="org91abfba">Don't Do That</h2>
<div class="outline-text-2" id="text-org91abfba">
</div>
<div id="outline-container-org1aa4228" class="outline-3">
<h3 id="org1aa4228">Can is not Should</h3>
</div>
<div id="outline-container-orga3f48a3" class="outline-3">
<h3 id="orga3f48a3">Write an Algorithm</h3>
</div>
<div id="outline-container-orgbea3c89" class="outline-3">
<h3 id="orgbea3c89">Why You Might</h3>
<div class="outline-text-3" id="text-orgbea3c89">
<ul class="org-ul">
<li>Throughput</li>
<li>Interruptable</li>
</ul>


<div class="notes" id="orgd77b1a9">
<p>  </p>

</div>
</div>
</div>
</div>
<div id="outline-container-org03d3e92" class="outline-2">
<h2 id="org03d3e92">Thank You</h2>
<div class="outline-text-2" id="text-org03d3e92">
<div class="notes" id="org76ec745">
<p>  </p>

</div>
</div>
</div>
</body></html>
