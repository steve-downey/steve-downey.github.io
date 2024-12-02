<html><body><div id="outline-container-org43806e8" class="outline-2">
<h2 id="org43806e8">An Experiment Collects Samples</h2>
<div class="outline-text-2" id="text-org43806e8">
 I'm modelling this in order to run bits of code like the various litmus tests used to describe multi-core architectures. A set of functions to be run in parallel that may or may not write to a result, which type is a property of the Test being run. The Experiment will run the Test collecting Samples. The Test type will provide a tuple of functions to run. They will be run under a spingate in all permutations in order to remove scheduling bias. 
</div>
</div>

<div id="outline-container-org699e7ae" class="outline-2">
<h2 id="org699e7ae">What a Test looks like</h2>
<div class="outline-text-2" id="text-org699e7ae">
<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">class</span> <span class="org-type">MP</span> { <span class="org-comment-delimiter">// </span><span class="org-comment">Message Passing</span>
    <span class="org-type">int</span> <span class="org-variable-name">x_</span>;
    <span class="org-type">int</span> <span class="org-variable-name">y_</span>;

  <span class="org-keyword">public</span>:
    <span class="org-keyword">typedef</span> <span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;<span class="org-type">int</span>&gt; <span class="org-type">Result</span>;
    <span class="org-function-name">MP</span>();
    <span class="org-type">void</span> <span class="org-function-name">t1</span>();
    <span class="org-type">void</span> <span class="org-function-name">t2</span>(<span class="org-type">Result</span>&amp; <span class="org-variable-name">read</span>);

    <span class="org-keyword">auto</span> <span class="org-function-name">actions</span>() {
        <span class="org-keyword">return</span> <span class="org-constant">std</span>::make_tuple([<span class="org-keyword">this</span>]() { t1(); },
                               [<span class="org-keyword">this</span>](<span class="org-type">Result</span>&amp; <span class="org-variable-name">result</span>) { t2(result); });
    }
};
</pre>
</div>

 The Test interface must provide a Result type, and an actions() member that will produce a tuple of functions to run which either take no arguments or a reference to a result. 

 The test being defined here is the basic Message Passing litmus test. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-constant">MP</span>::<span class="org-function-name">MP</span>() : x_(0), y_(0) {}

<span class="org-type">void</span> <span class="org-constant">MP</span>::<span class="org-function-name">t1</span>() {
    x_ = 1;
    y_ = 1;
}

<span class="org-type">void</span> <span class="org-constant">MP</span>::<span class="org-function-name">t2</span>(<span class="org-type">Result</span>&amp; <span class="org-variable-name">read</span>) {
    <span class="org-keyword">while</span> (<span class="org-negation-char">!</span>y) {
    }
    <span class="org-constant">std</span>::get&lt;0&gt;(read) = x_;
}
</pre>
</div>

 Two variables are initialized to 0. One thread stores 1 to x first, then to 1 to y. The other thread loops until it reads a non-zero in y, and then reads x. The value in x is the message being passed between threads. 

 In an actual test, the variables would be atomics, specifiying load and store strength, and the variables might have constraints on layout to help sharing cache line updates. 
</div>
</div>

<div id="outline-container-org991602e" class="outline-2">
<h2 id="org991602e">An Experiment</h2>
<div class="outline-text-2" id="text-org991602e">
 An Experiment samples a test a number of times. It takes the result of each sample, and puts in a map of the results to count, incrementing the count for each distinct result. The actions to run are permuted each time, to help remove bias about which action is loaded behind the spingate first. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-type">void</span> <span class="org-constant">Experiment</span>::<span class="org-function-name">run</span>(<span class="org-type">size_t</span> <span class="org-variable-name">count</span>) {
    <span class="org-keyword">using</span> <span class="org-type">Actions</span> = <span class="org-keyword">decltype</span>(<span class="org-constant">std</span>::declval&lt;Test&gt;().actions());
    <span class="org-keyword">auto</span> <span class="org-variable-name">getters</span> = <span class="org-constant">tupleutil</span>::tuple_getters&lt;<span class="org-type">Actions</span>&gt;();
    <span class="org-keyword">for</span> (<span class="org-type">size_t</span> <span class="org-variable-name">i</span> = 0; i &lt; count; ++i) {
        <span class="org-type">Sample</span>&lt;Test&gt; <span class="org-variable-name">sample</span>;
        sample.run(getters);
        resultMap_[sample.result_]++;
        <span class="org-constant">std</span>::next_permutation(getters.begin(), getters.end());
    }
}

</pre>
</div>
 <code>tupleutil::tuple_getters</code> returns an array of getters each of which returns a std::variant&lt;Types…&gt; with the same parameter pack as the tuple. 

 Sample runs all of the actions in a batch that locks them behind a spingate, and collects the results for each action. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">template</span> &lt;<span class="org-keyword">class</span> <span class="org-type">Test</span>&gt; <span class="org-keyword">class</span> <span class="org-type">Sample</span> {
  <span class="org-keyword">public</span>:
    <span class="org-type">Batch</span>                 <span class="org-variable-name">batch_</span>;
    <span class="org-type">Test</span>                  <span class="org-variable-name">test_</span>;
    <span class="org-keyword">typename</span> <span class="org-constant">Test</span>::<span class="org-type">Result</span> <span class="org-variable-name">result_</span>;

    <span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span> <span class="org-type">V</span>, <span class="org-type">size_t</span> <span class="org-variable-name">I</span>&gt; <span class="org-type">void</span> <span class="org-function-name">run</span>(<span class="org-constant">std</span>::<span class="org-type">array</span>&lt;<span class="org-type">V</span>, I&gt; <span class="org-keyword">const</span>&amp; <span class="org-variable-name">getters</span>) {
        <span class="org-keyword">auto</span> <span class="org-keyword">const</span>&amp; <span class="org-variable-name">actions</span> = test_.actions();
        add(actions, getters);
        batch_.run();
    }
};
</pre>
</div>

 Add is a templated member function that loops over the array, uses the getter to pull a function out of the tuple of actions and visits that with a lambda that will add either the function with no arguments, or that function with a reference to the results, to the batch. 

<div class="org-src-container">
<pre class="src src-C++">    <span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span> <span class="org-type">Tuple</span>, <span class="org-keyword">typename</span> <span class="org-type">Variant</span>, <span class="org-type">size_t</span> <span class="org-variable-name">I</span>&gt;
    <span class="org-type">void</span> <span class="org-function-name">add</span>(<span class="org-type">Tuple</span> <span class="org-keyword">const</span>&amp; <span class="org-variable-name">actions</span>, <span class="org-constant">std</span>::<span class="org-type">array</span>&lt;<span class="org-type">Variant</span>, I&gt; <span class="org-keyword">const</span>&amp; <span class="org-variable-name">getters</span>) {
        <span class="org-keyword">auto</span> <span class="org-variable-name">adder</span> = [<span class="org-keyword">this</span>](<span class="org-keyword">auto</span>&amp;&amp; <span class="org-variable-name">f</span>) {
            <span class="org-keyword">using</span> <span class="org-type">F</span> = <span class="org-constant">std</span>::<span class="org-type">remove_cv_t</span>&lt;<span class="org-constant">std</span>::<span class="org-type">remove_reference_t</span>&lt;<span class="org-keyword">decltype</span>(f)&gt;&gt;;
            <span class="org-keyword">if</span> <span class="org-keyword">constexpr</span> (<span class="org-constant">std</span>::<span class="org-type">is_invocable_v</span>&lt;<span class="org-type">F</span>&gt;) {
                batch_.add(f);
            } <span class="org-keyword">else</span> {
                batch_.add(f, <span class="org-constant">std</span>::ref(result_));
            }
        };
        <span class="org-keyword">for</span> (<span class="org-keyword">auto</span>&amp;&amp; <span class="org-variable-name">get_n</span> : getters) {
            <span class="org-constant">std</span>::visit(adder, get_n(actions));
        }
        <span class="org-keyword">return</span>;
    }
</pre>
</div>

 I am a bit dissatisfied with the else case not being constexpr if followed by a static assert, but getting the condition right didn't work the obvious way, so I punted. There will be a compiler error if f(result_) can't actually be called by the batch. 
</div>
</div>

<div id="outline-container-org3e10cba" class="outline-2">
<h2 id="org3e10cba">Batch recapped:</h2>
<div class="outline-text-2" id="text-org3e10cba">
 The key bit of code is 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">template</span> &lt;<span class="org-keyword">class</span> <span class="org-type">Function</span>, <span class="org-keyword">class</span><span class="org-function-name">...</span> <span class="org-type">Args</span>&gt;
<span class="org-type">void</span> <span class="org-constant">Batch</span>::<span class="org-function-name">add</span>(<span class="org-type">Function</span>&amp;&amp; <span class="org-variable-name">f</span>, <span class="org-type">Args</span>&amp;&amp;<span class="org-function-name">...</span> <span class="org-variable-name">args</span>) {
    workers_.emplace_back([ <span class="org-keyword">this</span>, <span class="org-variable-name">f</span> = <span class="org-constant">std</span>::forward&lt;<span class="org-type">Function</span>&gt;(f), <span class="org-constant">args</span><span class="org-function-name">...</span> ]() {
            gate_.wait();
            f(args<span class="org-function-name">...</span>);
        });
}

</pre>
</div>

 Batch has a spingate and runs all of the functions that are added sitting behind it. The <code>run()</code> function opens the gate and joins all the worker threads. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-type">void</span> <span class="org-constant">Batch</span>::<span class="org-function-name">run</span>() {
    gate_.open();
    <span class="org-keyword">for</span> (<span class="org-keyword">auto</span>&amp; <span class="org-variable-name">thr</span> : workers_) {
        thr.join();
    }
}

</pre>
</div>
</div>
</div>

<div id="outline-container-orge172530" class="outline-2">
<h2 id="orge172530">Summary</h2>
<div class="outline-text-2" id="text-orge172530">
 With all the machinery in place, the test infrascructure can aggressively run multi-threaded tests, giving the thread scheduler the best opportunity to run all of the actions in any order. This allows multi thread bugs to be shaken out by looking for surprising results from the experiment. 
</div>
</div>

<div id="outline-container-orgc9ec895" class="outline-2">
<h2 id="orgc9ec895">Source Code</h2>
<div class="outline-text-2" id="text-orgc9ec895">
 Exported from an org-mode doc, experiment.org, which is available, with all of the source on github at <a href="https://github.com/steve-downey/spingate">SpinGate</a>. 
</div>
</div></body></html>