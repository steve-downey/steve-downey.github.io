<html><body><div id="outline-container-org3e3344d" class="outline-2">
<h2 id="org3e3344d"><span class="section-number-2">1</span> Building a simple spin gate in C++</h2>
<div class="outline-text-2" id="text-1">
 This is a very simplified latch which allows several threads to block and busywait until they are released to begin work in parallel. I'm using this to do some multi-thread stress testing, where I want to maximize the overlapping work in order to check for suprising non-deterministic behavior. There's no count associated with the gate, nor is it reuseable. All we need is the one bit of information, weather the gate is open or closed. 

 The simplest atomic boolean is the std::atomic_flag. It's guaranteed by standard to be lock free. Unfortunately, to provide that guarantee, it provides no way to do an atomic read or write to the flag, just a clear, and a set and return prior value. This isn't rich enough for multiple threads to wait, although it is enough to implement a spinlock. 

 std::atomic&lt;bool&gt; isn't guaranteed to be lock free, but in practice, any architecture I'm interested has at least 32bit aligned atomics that are lock free. Older hardware, such as ARMv5, SparcV8, and 80386 are missing cmpxchg, so loads are generally implemented with a lock in order to maintain the guarantees if there were a simultaneous load and exchange. See, for example, <a href="http://llvm.org/docs/Atomics.html">LLVM Atomic Instructions and Concurrency Guide</a>. Modern ARM, x86, Sparc, and Power chips are fine. 

 When the spin gate is constructed, we'll mark the gate as closed. Threads will then wait on the flag, spinning until the gate is opened. For this we use Release-Acquire ordering between the open and wait. This will ensure any stores done before the gate is opened will be visible to the thread waiting. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-comment-delimiter">// </span><span class="org-comment">spingate.h                                                       -*-C++-*-</span>
<span class="org-preprocessor">#if</span><span class="org-negation-char"><span class="org-preprocessor">n</span></span><span class="org-preprocessor">def</span> INCLUDED_SPINGATE
<span class="org-preprocessor">#define</span> <span class="org-variable-name">INCLUDED_SPINGATE</span>

<span class="org-preprocessor">#include</span> <span class="org-string">&lt;atomic&gt;</span>
<span class="org-preprocessor">#include</span> <span class="org-string">&lt;thread&gt;</span>

<span class="org-keyword">class</span> <span class="org-type">SpinGate</span>
{
    <span class="org-constant">std</span>::<span class="org-type">atomic_bool</span> <span class="org-variable-name">flag_</span>;

  <span class="org-keyword">public</span>:
    <span class="org-function-name">SpinGate</span>();
    <span class="org-type">void</span> <span class="org-function-name">wait</span>();
    <span class="org-type">void</span> <span class="org-function-name">open</span>();
};

<span class="org-keyword">inline</span>
<span class="org-constant">SpinGate</span>::<span class="org-function-name">SpinGate</span>() {
    <span class="org-comment-delimiter">// </span><span class="org-comment">Close the gate</span>
    flag_.store(<span class="org-constant">true</span>, <span class="org-constant">std</span>::memory_order_release);
}

<span class="org-keyword">inline</span>
<span class="org-type">void</span> <span class="org-constant">SpinGate</span>::<span class="org-function-name">wait</span>() {
    <span class="org-keyword">while</span> (flag_.load(<span class="org-constant">std</span>::memory_order_acquire))
        ; <span class="org-comment-delimiter">// </span><span class="org-comment">spin</span>
}

<span class="org-keyword">inline</span>
<span class="org-type">void</span> <span class="org-constant">SpinGate</span>::<span class="org-function-name">open</span>() {
    flag_.store(<span class="org-constant">false</span>, <span class="org-constant">std</span>::memory_order_release);
    <span class="org-constant">std</span>::<span class="org-constant">this_thread</span>::yield();
}


<span class="org-preprocessor">#endif</span>
</pre>
</div>

<div class="org-src-container">
<pre class="src src-C++"><span class="org-preprocessor">#include</span> <span class="org-string">"spingate.h"</span>
<span class="org-comment-delimiter">// </span><span class="org-comment">Test that header is complete by including</span>
</pre>
</div>


 Using a SpinGate is fairly straightfoward. Create an instance of SpinGate and wait() on it in each of the worker threads. Once all of the threads are created, open the gate to let them run. In this example, I sleep for one second in order to check that none of the worker threads get past the gate before it is opened. 

 The synchronization is on the SpingGate's std::atomic_bool, flag_. The flag_ is set to true in the constructor, with release memory ordering. The function wait() spins on loading the flag_ with acquire memory ordering, until open() is called, which sets the flag_ to false with release semantics. The other threads that were spinning may now proceed. The release-acquires ordering ensures that happens-before writes by the thread setting up the work and calling open will be read by the threads that were spin waiting. 
</div>

<div id="outline-container-org632ad29" class="outline-3">
<h3 id="org632ad29"><span class="section-number-3">1.1</span> Update:</h3>
<div class="outline-text-3" id="text-1-1">
 I've added a yield() call after the open, hinting that the thread opening the gate may be rescheduled and allow the other threads to run. On the system I'm testing on, it doesn't seem to make a difference, but it does seem like the right thing to do, and it does not seem to hurt. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-preprocessor">#include</span> <span class="org-string">"spingate.h"</span>

<span class="org-preprocessor">#include</span> <span class="org-string">&lt;vector&gt;</span>
<span class="org-preprocessor">#include</span> <span class="org-string">&lt;chrono&gt;</span>
<span class="org-preprocessor">#include</span> <span class="org-string">&lt;thread&gt;</span>
<span class="org-preprocessor">#include</span> <span class="org-string">&lt;iostream&gt;</span>


<span class="org-type">int</span> <span class="org-function-name">main</span>()
{
    <span class="org-constant">std</span>::<span class="org-type">vector</span>&lt;<span class="org-constant">std</span>::thread&gt; <span class="org-variable-name">workers</span>;
    <span class="org-type">SpinGate</span> <span class="org-variable-name">gate</span>;
    <span class="org-keyword">using</span> <span class="org-type">time_point</span> = <span class="org-constant">std</span>::<span class="org-constant">chrono</span>::<span class="org-type">time_point</span>&lt;<span class="org-constant">std</span>::<span class="org-constant">chrono</span>::high_resolution_clock&gt;;
    <span class="org-type">time_point</span> <span class="org-variable-name">t1</span>;
    <span class="org-keyword">auto</span> <span class="org-variable-name">threadCount</span> = <span class="org-constant">std</span>::<span class="org-constant">thread</span>::hardware_concurrency();
    <span class="org-constant">std</span>::<span class="org-type">vector</span>&lt;<span class="org-type">time_point</span>&gt; <span class="org-variable-name">times</span>;
    times.resize(threadCount);

    <span class="org-keyword">for</span> (<span class="org-type">size_t</span> <span class="org-variable-name">n</span> = 0; n &lt; threadCount; ++n) {
        workers.emplace_back([&amp;gate, t1, &amp;times, n]{
                gate.wait();
                <span class="org-type">time_point</span> <span class="org-variable-name">t2</span> = <span class="org-constant">std</span>::<span class="org-constant">chrono</span>::<span class="org-constant">high_resolution_clock</span>::now();
                times[n] = t2;
            });
    }

    <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"Open the gate in 1 second: "</span> &lt;&lt; <span class="org-constant">std</span>::endl;
    <span class="org-keyword">using</span> <span class="org-keyword">namespace</span> <span class="org-constant">std</span>::<span class="org-constant">chrono_literals</span>;
    <span class="org-constant">std</span>::<span class="org-constant">this_thread</span>::sleep_for(1s);
    t1 = <span class="org-constant">std</span>::<span class="org-constant">chrono</span>::<span class="org-constant">high_resolution_clock</span>::now();
    gate.open();

    <span class="org-keyword">for</span> (<span class="org-keyword">auto</span>&amp; <span class="org-variable-name">thr</span> : workers) {
        thr.join();
    }

    <span class="org-type">int</span> <span class="org-variable-name">threadNum</span> = 0;
    <span class="org-keyword">for</span> (<span class="org-keyword">auto</span>&amp; <span class="org-variable-name">time</span>: times) {
        <span class="org-keyword">auto</span> <span class="org-variable-name">diff</span> = <span class="org-constant">std</span>::<span class="org-constant">chrono</span>::duration_cast&lt;<span class="org-constant">std</span>::<span class="org-constant">chrono</span>::nanoseconds&gt;(time - t1);
        <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"Thread "</span> &lt;&lt; threadNum++ &lt;&lt; <span class="org-string">" waited "</span> &lt;&lt; diff.count() &lt;&lt; <span class="org-string">"ns\n"</span>;
    }
}
</pre>
</div>

 I'd originally had the body of the threads just spitting out that they were running on std::cout, and the lack of execution before the gate, plus the overlapping output, being evidence of the gate working. That looked like: 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">for</span> (<span class="org-constant">std</span>::<span class="org-type">size_t</span> <span class="org-variable-name">n</span> = 0; n &lt; <span class="org-constant">std</span>::<span class="org-constant">thread</span>::hardware_concurrency(); ++n) {
    workers.emplace_back([&amp;gate, n]{
            gate.wait();
            <span class="org-constant">std</span>::cout &lt;&lt; <span class="org-string">"Output from gated thread "</span> &lt;&lt; n &lt;&lt; <span class="org-constant">std</span>::endl;
        });
}
</pre>
</div>

 The gate is captured in the thread lambda by reference, the thread number by value, and when run, overlapping gibberish is printed to the console as soon as open() is called. 

 But then I became curious about how long the spin actually lasted. Particularly since the guarantees for atomics with release-acquire semantics, or really even sequentially consistent, are about once a change is visible, that changes before are also visible. It's really a function of the underlying hardware how fast the change is visible, and what are the costs of making the happened-before writes available. I'd already observed better overlapping execution using the gate, as opposed to just letting the threads run, so for my initial purposes of making contention more likely, I was satisfied. Visibility, on my lightly loaded system, seems to be in the range of a few hundred to a couple thousand nanoseconds, which is fairly good. 

 Checking how long it took to start let me do two thing. First, play with the new-ish chrono library. Second, check that the release-acquire sync is working the way I expect. The lambdas that the threads are running capture the start time value by reference. The start time is set just before the gate is opened, and well after the threads have started running. The spin gate's synchronization ensures that if the state change caused by open is visible, the setting of the start time is also visible. 

 Here are one set of results from running a spingate: 

<pre class="example">
Open the gate in 1 second: 
Thread 0 waited 821ns
Thread 1 waited 14490ns
Thread 2 waited 521ns
Thread 3 waited 817ns
</pre>
</div>
</div>
</div>

<div id="outline-container-org5bc686f" class="outline-2">
<h2 id="org5bc686f"><span class="section-number-2">2</span> Comparison with Condition Variable gate</h2>
<div class="outline-text-2" id="text-2">
 The normal way of implementing a gate like this is with a condition variable, associated mutex, and a plain bool. The mutex guarantees synchronization between the wait and open, rather than the atomic variable in the SpinGate. The unlock/lock pair in mutex have release-acquire semantics. The actual lock and unlock are done by the unique_lock guard. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-comment-delimiter">// </span><span class="org-comment">cvgate.h                                                           -*-C++-*-</span>
<span class="org-preprocessor">#if</span><span class="org-negation-char"><span class="org-preprocessor">n</span></span><span class="org-preprocessor">def</span> INCLUDED_CVGATE
<span class="org-preprocessor">#define</span> <span class="org-variable-name">INCLUDED_CVGATE</span>

<span class="org-preprocessor">#include</span> <span class="org-string">&lt;mutex&gt;</span>
<span class="org-preprocessor">#include</span> <span class="org-string">&lt;condition_variable&gt;</span>
<span class="org-preprocessor">#include</span> <span class="org-string">&lt;atomic&gt;</span>
<span class="org-preprocessor">#include</span> <span class="org-string">&lt;thread&gt;</span>

<span class="org-keyword">class</span> <span class="org-type">CVGate</span>
{
    <span class="org-constant">std</span>::<span class="org-type">mutex</span> <span class="org-variable-name">lock_</span>;
    <span class="org-constant">std</span>::<span class="org-type">condition_variable</span> <span class="org-variable-name">cv_</span>;
    <span class="org-type">bool</span> <span class="org-variable-name">flag_</span>;

  <span class="org-keyword">public</span>:
    <span class="org-function-name">CVGate</span>();

    <span class="org-type">void</span> <span class="org-function-name">wait</span>();
    <span class="org-type">void</span> <span class="org-function-name">open</span>();
};

<span class="org-keyword">inline</span>
<span class="org-constant">CVGate</span>::<span class="org-function-name">CVGate</span>()
: lock_(),
  cv_(),
  flag_(<span class="org-constant">true</span>)
{}

<span class="org-keyword">inline</span>
<span class="org-type">void</span> <span class="org-constant">CVGate</span>::<span class="org-function-name">wait</span>() {
    <span class="org-constant">std</span>::<span class="org-type">unique_lock</span>&lt;<span class="org-constant">std</span>::<span class="org-type">mutex</span>&gt; <span class="org-function-name">lk</span>(lock_);
    cv_.wait(lk, [&amp;](){<span class="org-keyword">return</span> <span class="org-negation-char">!</span>flag_;});
}

<span class="org-keyword">inline</span>
<span class="org-type">void</span> <span class="org-constant">CVGate</span>::<span class="org-function-name">open</span>() {
    <span class="org-constant">std</span>::<span class="org-type">unique_lock</span>&lt;<span class="org-constant">std</span>::<span class="org-type">mutex</span>&gt; <span class="org-function-name">lk</span>(lock_);
    flag_ = <span class="org-constant">false</span>;
    cv_.notify_all();
    <span class="org-constant">std</span>::<span class="org-constant">this_thread</span>::yield();
}
<span class="org-preprocessor">#endif</span>
</pre>
</div>

<div class="org-src-container">
<pre class="src src-C++"><span class="org-preprocessor">#include</span> <span class="org-string">"cvgate.h"</span>
<span class="org-comment-delimiter">// </span><span class="org-comment">Test that header is complete by including</span>
</pre>
</div>

 This has the same interface as SpinGate, and is used exactly the same way. 

 Running it shows: 

<pre class="example">
Open the gate in 1 second: 
Thread 0 waited 54845ns
Thread 1 waited 76125ns
Thread 2 waited 91977ns
Thread 3 waited 128816ns
</pre>


 That the overhead of the mutex and condition variable is significant. On the other hand, the system load while it's waiting is much lower. Spingate will use all available CPU, while CVGate yields, so useful work can be done byu the rest of the system. 

 However, for the use I was originally looking at, releasing threads for maximal overlap, spinning is clearly better. There is much less overlap as the cv blocked threads are woken up. 
</div>
</div>

<div id="outline-container-orgf2ae95b" class="outline-2">
<h2 id="orgf2ae95b"><span class="section-number-2">3</span> Building and Running</h2>
<div class="outline-text-2" id="text-3">
 This is a minimal CMake file for building with the system compiler. 

<div class="org-src-container">
<pre class="src src-cmake"><span class="org-function-name">cmake_minimum_required</span>(VERSION 3.5)
<span class="org-function-name">set</span>(CMAKE_LEGACY_CYGWIN_WIN32 0)

<span class="org-function-name">project</span>(SpinGate C CXX)

<span class="org-function-name">set</span>(THREADS_PREFER_PTHREAD_FLAG ON)
<span class="org-function-name">find_package</span>(Threads REQUIRED)

<span class="org-function-name">set</span>(CMAKE_EXPORT_COMPILE_COMMANDS ON)

<span class="org-function-name">set</span>(CMAKE_CXX_FLAGS <span class="org-string">"${</span><span class="org-variable-name">CMAKE_CXX_FLAGS</span><span class="org-string">} -std=c++14 -ftemplate-backtrace-limit=0"</span>)
<span class="org-function-name">set</span>(CMAKE_CXX_FLAGS <span class="org-string">"${</span><span class="org-variable-name">CMAKE_CXX_FLAGS</span><span class="org-string">} -Wall -Wextra -march=native"</span>)
<span class="org-function-name">set</span>(CMAKE_CXX_FLAGS_DEBUG <span class="org-string">"-O0 -fno-inline -g3"</span>)
<span class="org-function-name">set</span>(CMAKE_CXX_FLAGS_RELEASE <span class="org-string">"-Ofast -g0 -DNDEBUG"</span>)

<span class="org-function-name">include_directories</span>(${<span class="org-variable-name">CMAKE_CURRENT_SOURCE_DIR</span>})

<span class="org-function-name">add_executable</span>(spingate main.cpp spingate.cpp)
<span class="org-function-name">add_executable</span>(cvgate cvmain.cpp cvgate.cpp)
<span class="org-function-name">target_link_libraries</span>(spingate Threads::Threads)
<span class="org-function-name">target_link_libraries</span>(cvgate Threads::Threads)
</pre>
</div>

 And here we build a release version of the test executable: 

<div class="org-src-container">
<pre class="src src-shell" id="org9a6ea8d">mkdir -p build
<span class="org-builtin">cd</span> build
cmake -DCMAKE_BUILD_TYPE=Release ../
make
</pre>
</div>

<pre class="example">
-- Configuring done
-- Generating done
-- Build files have been written to: /home/sdowney/src/spingate/build
[ 50%] Built target cvgate
[100%] Built target spingate
</pre>
</div>
</div>

<div id="outline-container-orgd97c46f" class="outline-2">
<h2 id="orgd97c46f"><span class="section-number-2">4</span> Org-mode source and git repo</h2>
<div class="outline-text-2" id="text-4">
 Exported from an org-mode doc. All of the source is available on github at <a href="https://github.com/steve-downey/spingate">SpinGate</a> 
</div>
</div></body></html>