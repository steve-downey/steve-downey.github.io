<html><body><div id="outline-container-org8869472" class="outline-2">
<h2 id="org8869472">Yes: std::bind should be replaced by lambda</h2>
<div class="outline-text-2" id="text-org8869472">
 For almost all cases, <code>std::bind</code> should be replaced by a lambda expression. It's idiomatic, and results in better code. There is almost no reason post C++11 to use <code>std::bind</code>. 

 Doing so is quite straightforward, capture each bind argument by value in the lambda capture list, and provide auto parameters for each of the placeholders, then call the bound callable using <code>std::invoke()</code>. That will handle the cases of member function pointers, as well as regular functions. Now, this is how to do it mechanically, if you were doing this as part of a manual refactoring, the lambda can be made even clearer. 

<div class="org-src-container">
<pre class="src src-c++"><span class="org-preprocessor">#include</span> <span class="org-string">&lt;functional&gt;</span>
<span class="org-preprocessor">#include</span> <span class="org-string">&lt;iostream&gt;</span>

<span class="org-type">void</span> <span class="org-function-name">f</span>(<span class="org-type">int</span> <span class="org-variable-name">n1</span>, <span class="org-type">int</span> <span class="org-variable-name">n2</span>, <span class="org-type">int</span> <span class="org-variable-name">n3</span>) {
  <span class="org-constant">std</span>::cout &lt;&lt; n1 &lt;&lt; <span class="org-string">' '</span> &lt;&lt; n2 &lt;&lt; <span class="org-string">' '</span> &lt;&lt; n3 &lt;&lt; <span class="org-string">'\n'</span>;
}

<span class="org-type">int</span> <span class="org-function-name">main</span>() {
  <span class="org-keyword">using</span> <span class="org-keyword">namespace</span> <span class="org-constant">std</span>::<span class="org-constant">placeholders</span>;
  <span class="org-type">int</span> <span class="org-variable-name">n</span> = 5;
  <span class="org-keyword">auto</span> <span class="org-variable-name">f1</span> = <span class="org-constant">std</span>::bind(f, 2, n, _1);
  f1(10); <span class="org-comment-delimiter">// </span><span class="org-comment">calls f(2, 5, 10);</span>

  <span class="org-keyword">auto</span> <span class="org-variable-name">l1</span> = [ p1 = 2, p2 = n ](<span class="org-keyword">auto</span> <span class="org-variable-name">_1</span>) { <span class="org-keyword">return</span> <span class="org-constant">std</span>::invoke(f, p1, p2, _1); };
  l1(10);

  <span class="org-comment-delimiter">// </span><span class="org-comment">idiomatically</span>
  <span class="org-keyword">auto</span> <span class="org-variable-name">l1a</span> = [=](<span class="org-keyword">auto</span> <span class="org-variable-name">_1</span>){<span class="org-keyword">return</span> f(2, n, _1);};
  l1a(10);

  <span class="org-keyword">auto</span> <span class="org-variable-name">f2</span> = <span class="org-constant">std</span>::bind(f, 2, <span class="org-constant">std</span>::cref(n), _1);
  <span class="org-keyword">auto</span> <span class="org-variable-name">l2</span> = [ p1 = 2, p2 = <span class="org-constant">std</span>::cref(n) ](<span class="org-keyword">auto</span> <span class="org-variable-name">_1</span>) {
      <span class="org-keyword">return</span> <span class="org-constant">std</span>::invoke(f, p1, p2, _1);
  };
  <span class="org-comment-delimiter">// </span><span class="org-comment">or</span>
  <span class="org-keyword">auto</span> <span class="org-variable-name">l2a</span> = [ p1 = 2, &amp;p2 = n ](<span class="org-keyword">auto</span> <span class="org-variable-name">_1</span>) {
      <span class="org-keyword">return</span> <span class="org-constant">std</span>::invoke(f, p1, p2, _1);
  };
  <span class="org-comment-delimiter">// </span><span class="org-comment">more idiomatically</span>
  <span class="org-keyword">auto</span> <span class="org-variable-name">l2b</span> = [&amp;](<span class="org-keyword">auto</span> <span class="org-variable-name">_1</span>){f(2, n, _1);};

  n = 7;
  f2(10); <span class="org-comment-delimiter">// </span><span class="org-comment">calls f(2, 7, 10);</span>

  l2(10);
  l2a(10);
  l2b(10);
}
</pre>
</div>


 Which results in: 

<pre class="example">
2 5 10
2 5 10
2 5 10
2 7 10
2 7 10
2 7 10
2 7 10

</pre>
</div>
</div>

<div id="outline-container-org783d5d0" class="outline-2">
<h2 id="org783d5d0">No: std::bind provides one thing lambda doesn't</h2>
<div class="outline-text-2" id="text-org783d5d0">
 The expression <code>std::bind</code> evaluates flattens <code>std::bind</code> sub-expressions, and passes the same placeholder parameters down. A nested bind is evaluated with the given parameters, and the result is passed in to the outer bind. So you can have a bind that does something like <code>g( _1, f(_1))</code>, and when you call it with a parameter, that same value will be passed to both g and f. The function g will receive <code>f(_1)</code> as its second parameter. 

 Now, you could rewrite the whole thing as a lambda, but <code>auto</code> potentially makes this a little more difficult. The result of <code>std::bind</code> is an unutterable type. They weren't supposed to be naked. However, <code>auto</code> means the expression could be broken down into parts, meaning that the translation from a <code>std::bind</code> expression to a lambda expression is potentially not mechanical. Or, the bind could be part of a template, where the subexpression is a template parameter, which is likely working by accident, rather than design. 

 In any case, <code>std::bind</code> does not treat its arguments uniformly. It treats a bind expression distinctly differently. At the time, it made some sense. But it makes reasoning about bind expressions difficult. 

 Don't do this. But it is why formally deprecating <code>std::bind</code> is difficult. They can be replaced, but not purely mechanically. 

 There isn't a simple translation that works, unlike converting from <code>std::auto_ptr</code> to <code>std::unique_ptr</code>, or putting a space after a string where it now looks like a conversion. And, <code>std::bind</code> isn't broken. It's sub-optimal because of the complicated machinery to support all of the flexibility, where a lambda allows the compiler to do much better. Also, since the type isn't utterable, it often ends up in a std::function, which erases the type, removing optimization options. 
</div>
</div>

<div id="outline-container-org74c813b" class="outline-2">
<h2 id="org74c813b">Example of fail code</h2>
<div class="outline-text-2" id="text-org74c813b">
<div class="org-src-container">
<pre class="src src-C++"><span class="org-preprocessor">#include</span> <span class="org-string">&lt;functional&gt;</span>
<span class="org-preprocessor">#include</span> <span class="org-string">&lt;iostream&gt;</span>

<span class="org-type">void</span> <span class="org-function-name">f</span>(<span class="org-type">int</span> <span class="org-variable-name">n1</span>, <span class="org-type">int</span> <span class="org-variable-name">n2</span>, <span class="org-type">int</span> <span class="org-variable-name">n3</span>)
{
    <span class="org-constant">std</span>::cout &lt;&lt; n1 &lt;&lt; <span class="org-string">' '</span> &lt;&lt; n2 &lt;&lt; <span class="org-string">' '</span> &lt;&lt; n3 &lt;&lt; <span class="org-string">'\n'</span>;
}

<span class="org-type">int</span> <span class="org-function-name">g</span>(<span class="org-type">int</span> <span class="org-variable-name">n1</span>) { <span class="org-keyword">return</span> n1; }

<span class="org-type">int</span> <span class="org-function-name">main</span>()
{
    <span class="org-keyword">using</span> <span class="org-keyword">namespace</span> <span class="org-constant">std</span>::<span class="org-constant">placeholders</span>;

    <span class="org-keyword">auto</span> <span class="org-variable-name">g1</span> = <span class="org-constant">std</span>::bind(g, _1);
    <span class="org-keyword">auto</span> <span class="org-variable-name">f2</span> = <span class="org-constant">std</span>::bind(f, _1, g1, 4);
    f2(10); <span class="org-comment-delimiter">// </span><span class="org-comment">calls f(10, g(10), 4);</span>

    <span class="org-comment-delimiter">// </span><span class="org-comment">THIS DOES NOT WORK</span>
    <span class="org-comment-delimiter">// </span><span class="org-comment">auto l2 = [p1 = g1, p2 = 4](auto _1) {std::invoke(f, _1, p1, p2);};</span>
    <span class="org-comment-delimiter">// </span><span class="org-comment">l2(10);</span>

    <span class="org-comment-delimiter">// </span><span class="org-comment">The bind translation needs to be composed:</span>
    <span class="org-keyword">auto</span> <span class="org-variable-name">l1</span> = [](<span class="org-keyword">auto</span> <span class="org-variable-name">_1</span>){<span class="org-keyword">return</span> g(_1);};
    <span class="org-keyword">auto</span> <span class="org-variable-name">l2</span> = [p1 = l1, p2 = 4](<span class="org-keyword">auto</span> <span class="org-variable-name">_1</span>){f(_1, p1(_1), p2); };
    <span class="org-comment-delimiter">// </span><span class="org-comment">idiomatically</span>
    <span class="org-keyword">auto</span> <span class="org-variable-name">l2a</span> = [](<span class="org-keyword">auto</span> <span class="org-variable-name">_1</span>) { <span class="org-keyword">return</span> f(_1, g(_1), 4);};
    l2(10);
    l2a(10);
}


</pre>
</div>

<pre class="example">
10 10 4
10 10 4
10 10 4

</pre>
</div>
</div>

<div id="outline-container-orgbe0a9a3" class="outline-2">
<h2 id="orgbe0a9a3"><span class="todo TODO">TODO</span> </h2>
<div class="outline-text-2" id="text-orgbe0a9a3">
 If someone can figure out a fixit recommendation that could be safely applied, transforming the old bind to a lambda, then <code>std::bind</code> could be deprecated in C++Next, and removed as soon as C++(Next++). But that right now is non-trivial in some cases. 
</div>
</div>

<div id="outline-container-orgd9aeff5" class="outline-2">
<h2 id="orgd9aeff5">Updates:</h2>
<div class="outline-text-2" id="text-orgd9aeff5">
<ul class="org-ul">
<li>Fix incorrect statement about type-erasure in std::bind. I was thinking std::function</li>
<li>Add more idiomatic transliterations of the std::bind lambdas</li>
</ul>
</div>
</div>

<div id="outline-container-org1041288" class="outline-2">
<h2 id="org1041288">Building and running the examples</h2>
<div class="outline-text-2" id="text-org1041288">
</div><div id="outline-container-orgc36032d" class="outline-3">
<h3 id="orgc36032d">Makefile</h3>
<div class="outline-text-3" id="text-orgc36032d">
<div class="org-src-container">
<pre class="src src-makefile"><span class="org-makefile-targets">clean</span>:
    <span class="org-type">-</span><span class="org-makefile-shell">rm example1</span>
    <span class="org-type">-</span><span class="org-makefile-shell">rm example2</span>

<span class="org-makefile-targets">example1</span>: example1.cpp
    clang++ --std=c++1z example1.cpp -o example1

<span class="org-makefile-targets">example2</span>: example2.cpp
    clang++ --std=c++1z example2.cpp -o example2

<span class="org-makefile-targets">example3</span>: example3.cpp
    clang++ --std=c++1z example3.cpp -o example3 2&gt;&amp;1

<span class="org-makefile-targets">all</span>: example1 example2

</pre>
</div>
</div>
</div>


<div id="outline-container-org9675a68" class="outline-3">
<h3 id="org9675a68">Build</h3>
<div class="outline-text-3" id="text-org9675a68">
<pre class="example">
rm example1
rm example2
clang++ --std=c++1z example1.cpp -o example1
clang++ --std=c++1z example2.cpp -o example2

</pre>
</div>
</div>
<div id="outline-container-org92834af" class="outline-3">
<h3 id="org92834af">Original source</h3>
<div class="outline-text-3" id="text-org92834af">
 Original document is available on <a href="https://raw.githubusercontent.com/steve-downey/what-comes-to-mind/master/why-bind-cant-be-deprecated.org">Github</a> 
</div>
</div>
</div></body></html>