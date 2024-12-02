<html><body><div id="outline-container-orga656deb" class="outline-2">
<h2 id="orga656deb"><span class="section-number-2">1</span> A batch of tasks to run</h2>
<div class="outline-text-2" id="text-1">
 This adds a rather simple component to spingate orchestrating a batch of tasks to be run, gated by the spingate. The tasks are added one at a time, a thread is created for the task, and the thread waits on the spingate to open before calling the task. 

 Or at least that's how it started. Task was originally a std::function&lt;void()&gt;, which is essentially the interface of the thread pool I use. I realized, however, that I don't actually need to restrict the interface quite that much. Thread takes a much wider range of things to run, and I can do the same thing. I have to forward the supplied callable and arguments into the lambda that the thread is running. 

 The key bit of code is 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">template</span> &lt;<span class="org-keyword">class</span> <span class="org-type">Function</span>, <span class="org-keyword">class</span>... Args&gt;
<span class="org-type">void</span> <span class="org-constant">Batch</span>::<span class="org-function-name">add</span>(<span class="org-type">Function</span>&amp;&amp; <span class="org-variable-name">f</span>, <span class="org-type">Args</span>&amp;&amp;... args) {
    workers_.emplace_back([ <span class="org-keyword">this</span>, f = <span class="org-constant">std</span>::forward&lt;<span class="org-type">Function</span>&gt;(f), args... ]() {
            gate_.wait();
            f(args...);
        });
}
</pre>
</div>

 There's a lot of line noise in there, and it really looked simpler when it was just taking a std::function&lt;void()&gt;, but it's not terrible. We take an object of type Function and a parameter pack of type Args by forwarding reference. That gets captured by the lambda, where we forward the function to the lambda, and capture the parameter pack. Inside the lambda we call the function with the pack, f(args). It's probable that I should have used std::invoke there, which handles some of the more interesting cases of calling a thing with arguments. But this was sufficient unto the day. The captured this allows access to the gate_ variable the we're waiting on. The workers_ are a vector of threads that we'll later run run through and join() on, after open()ing the gate_. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-type">void</span> <span class="org-constant">Batch</span>::<span class="org-function-name">run</span>() {
    gate_.open();
    <span class="org-keyword">for</span> (<span class="org-keyword">auto</span>&amp; <span class="org-variable-name">thr</span> : workers_) {
        thr.join();
    }
}
</pre>
</div>


 That's really all there is to Batch. It's a middle connective glue component. Does one thing, and tries to do it obviously well. That is important since I'm trying to build up test infrastructure, and testing the test infrastrucure is a hard problem. 

 I have reorganized the code repo in order to do some light testing, though. 
</div>
</div>

<div id="outline-container-org135204d" class="outline-2">
<h2 id="org135204d"><span class="section-number-2">2</span> GTest</h2>
<div class="outline-text-2" id="text-2">
 I've pushed things about in the source repo, moving the code into a library directory, which means I can link it into the existing mains, as well as into new gtests. In the CMake system, I've conditioned building tests on the existence of the googletest project being available as a subdirectory. I use enough different compilers and build options that trying to use a system build of gtest just doesn't work. The best, and recommended, choice, is to build googletest as part of your project. That way any ABI impacting subtlety, like using a different C++ standard library, is take care of automatically. The bit of cmake magic is in the top level CMakeLists.txt : 

<div class="org-src-container">
<pre class="src src-cmake"><span class="org-comment"># A directory to find Google Test sources.</span>
<span class="org-keyword">if</span> (EXISTS <span class="org-string">"${</span><span class="org-variable-name">CMAKE_CURRENT_SOURCE_DIR</span><span class="org-string">}/googletest/CMakeLists.txt"</span>)
  <span class="org-function-name">add_subdirectory</span>(googletest EXCLUDE_FROM_ALL)
  <span class="org-function-name">add_subdirectory</span>(tests)
<span class="org-keyword">else</span>()
  <span class="org-function-name">message</span>(<span class="org-string">"GTEST Not Found at ${</span><span class="org-variable-name">CMAKE_CURRENT_SOURCE_DIR</span><span class="org-string">}/googletest/CMakeLists.txt"</span>)
<span class="org-keyword">endif</span>()
</pre>
</div>
 This looks for googletest to be available, and if it is, add it to the project, and my tests subdirectory, otherwise issue a message. I prefer this to attempting to fix up the missing gtest automatically. That always seems to cause me problems, such as when I'm operating disconnected, on a train, like right now. 

 The tests I have are pretty simple, not much more than primitive breathing tests. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-function-name">TEST_F</span>(BatchTest, run1Test)
{
    <span class="org-type">Batch</span> <span class="org-variable-name">batch</span>;
    batch.add([<span class="org-keyword">this</span>](){incrementCalled();});

    EXPECT_EQ(0u, called);

    batch.run();

    EXPECT_EQ(1u, called);
}
</pre>
</div>

 or, to make sure that passing arguments worked 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-function-name">TEST_F</span>(BatchTest, runArgTest)
{
    <span class="org-type">Batch</span> <span class="org-variable-name">batch</span>;
    <span class="org-type">int</span> <span class="org-variable-name">i</span> = 0;
    batch.add([&amp;i](<span class="org-type">int</span> <span class="org-variable-name">k</span>){ i = k;}, 1);

    EXPECT_EQ(0, i);

    batch.run();

    EXPECT_EQ(1, i);
}
</pre>
</div>

 I don't actually expect to find runtime errors with these tests. They exercise ths component just enough that I'm not generating compile errors in expected use cases. Template code can be tricky that way. Templates that aren't instantiated can have horrible errors, but the compiler is willing to let them pass, if they mostly parse. 

 SFINAE may not be your friend. 
</div>
</div>

<div id="outline-container-orgf36cf22" class="outline-2">
<h2 id="orgf36cf22"><span class="section-number-2">3</span> Clang builds with current libc++</h2>
<div class="outline-text-2" id="text-3">
 Building clang and libc++ locally is getting easier and easier. Using that is still a bit difficult. But there are some reasons to do so. One is just being able to cross check your code for sanity. I won't reproduce building clang and libc++ here. It's really at this point just checking out the repos in the right places and running cmake with something like: 

<div class="org-src-container">
<pre class="src src-shell">cmake  -DCMAKE_INSTALL_PREFIX=~/install/llvm-master/ -DLLVM_ENABLE_LIBCXX=yes  -DCMAKE_BUILD_TYPE=Release   ../llvm/
</pre>
</div>

 Using that, at least from within cmake, is more complicated. Cmake has a strong bias towards using the system compiler. It also has a distinct problem with repeating builds. 

 NEVER edit your CMakeCache.txt. You can't do anything with it. All the paths are hard coded. Always start over. Either keep the command line around, or create a cmake initial cache file, which isn't the same thing at all as the CMakeCache.txt file. 

 Right now, I'm cargo-culting around code in my cmake files that checks if I've defined an LLVM_ROOT, and if I have supply the flags to ignore all the system files, and use the ones from the installed LLVM_ROOT, including some rpath fixup. There might be some way to convince cmake to do it, but there's also only so much I will fight my metabuild system. 

<div class="org-src-container">
<pre class="src src-cmake">  <span class="org-keyword">if</span>(LLVM_ROOT)
    <span class="org-function-name">message</span>(STATUS <span class="org-string">"LLVM Root: ${</span><span class="org-variable-name">LLVM_ROOT</span><span class="org-string">}"</span>)
    <span class="org-function-name">set</span>(CMAKE_CXX_FLAGS <span class="org-string">"${</span><span class="org-variable-name">CMAKE_CXX_FLAGS</span><span class="org-string">} -nostdinc++ -isystem ${</span><span class="org-variable-name">LLVM_ROOT</span><span class="org-string">}/include/c++/v1"</span>)
    <span class="org-function-name">set</span>(CMAKE_EXE_LINKER_FLAGS <span class="org-string">"${</span><span class="org-variable-name">CMAKE_EXE_LINKER_FLAGS</span><span class="org-string">} -L ${</span><span class="org-variable-name">LLVM_ROOT</span><span class="org-string">}/lib -l c++ -l c++abi"</span>)
    <span class="org-function-name">set</span>(CMAKE_EXE_LINKER_FLAGS <span class="org-string">"${</span><span class="org-variable-name">CMAKE_EXE_LINKER_FLAGS</span><span class="org-string">} -Wl,-rpath,${</span><span class="org-variable-name">LLVM_ROOT</span><span class="org-string">}/lib"</span>)
  <span class="org-keyword">else</span>()
</pre>
</div>

 I only check for that if the compiler I've chosen is a clang compiler, and it's not normally part of my environment. 
</div>
</div>

<div id="outline-container-org2ba138e" class="outline-2">
<h2 id="org2ba138e"><span class="section-number-2">4</span> Direction</h2>
<div class="outline-text-2" id="text-4">
 Overall, what I want out of this library is to be able to stress test some nominally mt-safe code, and check that the conditions that I think hold are true. It's heavily influenced by jcstress, but, because this is C+++, it will be rendered quite differently. 

 For what I'm considering, look at <a href="https://shipilev.net/blog/2016/close-encounters-of-jmm-kind/">Close Encounters of The Java Memory Model Kind</a> 

 I want to be able to specify a state, with operations that mutate and observe the state. I want to be able to collect those observations in a deterministic way, which may require cooperation from the observers. I want to be able to collect the observations and report how many times each set of observations was obtained. 

 Something like: 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">class</span> <span class="org-type">State</span> {
    <span class="org-type">int</span> <span class="org-variable-name">x_</span>;
    <span class="org-type">int</span> <span class="org-variable-name">y_</span>;

  <span class="org-keyword">public</span>:
    <span class="org-keyword">typedef</span> <span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;<span class="org-type">int</span>, <span class="org-type">int</span>, <span class="org-type">int</span>, <span class="org-type">int</span>&gt; <span class="org-type">Result</span>;
    <span class="org-function-name">State</span>() : x_(0), y_(0) {}
    <span class="org-type">void</span> <span class="org-function-name">writer1</span>() {
        y_ = 1;
        x_ = 1;
    }
    <span class="org-type">void</span> <span class="org-function-name">reader1</span>(<span class="org-type">Result</span>&amp; <span class="org-variable-name">read</span>) {
        <span class="org-constant">std</span>::get&lt;0&gt;(read) = x_;
        <span class="org-constant">std</span>::get&lt;1&gt;(read) = y_;
    }
    <span class="org-type">void</span> <span class="org-function-name">reader2</span>(<span class="org-type">Result</span>&amp; <span class="org-variable-name">read</span>) {
        <span class="org-constant">std</span>::get&lt;2&gt;(read) = x_;
        <span class="org-constant">std</span>::get&lt;3&gt;(read) = y_;
    }
};
</pre>
</div>

 Running the writers and readers over different threads and observing the possible results. On some architectures, reader1 and reader2 can see entirely different orders, even though y_ will happen before x_, you might see x_ written and not y_. 

 What I'd eventually like to be able to do is say things like, "This function will only be evaluated once", and have some evidence to back that up. 

 So the next step is something that will take a State and schedule all of the actions with appropriate parameters in a Batch, and produce the overall Result. Then something that will do that many many times, accumulating all of the results. And since this isn't java, so we don't have reflection techniques, the State class is going to have to cooperate a bit. The Result typedef is one way. It will also have to produce all of the actions that need to be batched, in some heterogenous form that I can then run. 
</div>
</div>

<div id="outline-container-orga889604" class="outline-2">
<h2 id="orga889604"><span class="section-number-2">5</span> Source Code</h2>
<div class="outline-text-2" id="text-5">
 Exported from an org-mode doc, batch.org, which is available, with all of the source on github at <a href="https://github.com/steve-downey/spingate">SpinGate</a>. 
</div>
</div></body></html>