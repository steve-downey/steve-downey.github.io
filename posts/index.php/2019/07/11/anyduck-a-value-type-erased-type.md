<html><body><div id="outline-container-org9373ade" class="outline-2">
<h2 id="org9373ade">A Constrained Duck Typed Value Type</h2>
<div class="outline-text-2" id="text-org9373ade">
 For yak shaving reasons, I need a type able to hold any type conforming to a particular interface. I'd like this to act as a (Semi)Regular value type. That is, I'd like it to be copyable, assignable, and so forth, and not be sliced or otherwise mangeled in the process. I want it to be reasonably efficient, not significantly worse than traditional virtual function overhead. I also don't want to be terribly creative in implementing, using existing std library types.

The overall pattern I've settled on for now is to hold the type in a <code>std::any</code> and dispatch to the held type through function pointers referring to lambdas. The lambda allows me to capture the type being stored into the <code>AnyDuck</code> and safely recover it. There's some boilerplate to write to dispatch to the lambda. Perhaps one day, when we have reflection, that can be automated.

For purposes of this paper, I'll assume I have an interface Duck that I want to model:
<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">class</span> <span class="org-type">Duck</span> {
  <span class="org-keyword">public</span>:
    <span class="org-type">void</span> <span class="org-function-name">quack</span>(<span class="org-type">int</span> <span class="org-variable-name">length</span>) <span class="org-keyword">const</span>;
};
</pre>
</div>
Ducks are defined as things that quack, and quack is a const function. I want to be able to put any type that models Duck into an AnyDuck, and pass AnyDuck into any generic function expecting a Duck. I also want to be able to extend AnyDuck to unrelated types, as long as they model Duck. Mallard, for example:
<div class="org-src-container">
<pre class="src src-c++"><span class="org-keyword">class</span> <span class="org-type">Mallard</span> {
  <span class="org-keyword">public</span>:
    <span class="org-type">void</span> <span class="org-function-name">quack</span>(<span class="org-type">int</span> <span class="org-variable-name">length</span>) <span class="org-keyword">const</span>;
};

</pre>
</div>
The core of the idea, is to capture the Duck type in a templated constructor where I know the exact type, and create the appropriate lambda:
<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">auto</span> <span class="org-variable-name">quack_</span> = [](<span class="org-constant">std</span>::<span class="org-type">any</span> <span class="org-keyword">const</span>&amp; <span class="org-variable-name">d</span>, <span class="org-type">int</span> <span class="org-variable-name">i</span>) {
    <span class="org-keyword">return</span> <span class="org-constant">std</span>::any_cast&lt;<span class="org-constant">std</span>::<span class="org-type">remove_reference_t</span>&lt;Duck&gt;&gt;(&amp;d)-&gt;quack(i);
}
</pre>
</div>
And then wrap the public facing call so that quackfn can be stored as a function pointer
<div class="org-src-container">
<pre class="src src-C++"><span class="org-type">void</span> <span class="org-constant">AnyDuck</span>::<span class="org-function-name">quack</span>(<span class="org-type">int</span> <span class="org-variable-name">length</span>) <span class="org-keyword">const</span> { <span class="org-keyword">return</span> quack_(<span class="org-keyword">this</span>-&gt;duck_, length); }
</pre>
</div>
Here's the whole thing:
<div class="org-src-container">
<pre class="src src-c++"><span class="org-keyword">class</span> <span class="org-type">AnyDuck</span> {
    <span class="org-constant">std</span>::<span class="org-type">any</span> <span class="org-variable-name">duck_</span>;
    <span class="org-keyword">using</span> <span class="org-type">quackfn</span> = <span class="org-type">void</span> (*)(<span class="org-constant">std</span>::<span class="org-type">any</span> <span class="org-keyword">const</span>&amp;, <span class="org-type">int</span>);
    <span class="org-type">quackfn</span> <span class="org-variable-name">quack_</span>;

  <span class="org-keyword">public</span>:
    <span class="org-function-name">AnyDuck</span>(<span class="org-type">AnyDuck</span> <span class="org-keyword">const</span>&amp;) = <span class="org-keyword">default</span>;
    <span class="org-function-name">AnyDuck</span>(<span class="org-type">AnyDuck</span>&amp;)       = <span class="org-keyword">default</span>;

    <span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span> <span class="org-type">Duck</span>&gt;
    <span class="org-function-name">AnyDuck</span>(<span class="org-type">Duck</span>&amp;&amp; <span class="org-variable-name">duck</span>)
        : duck_(<span class="org-constant">std</span>::forward&lt;<span class="org-type">Duck</span>&gt;(duck)),
          quack_([](<span class="org-constant">std</span>::<span class="org-type">any</span> <span class="org-keyword">const</span>&amp; <span class="org-variable-name">d</span>, <span class="org-type">int</span> <span class="org-variable-name">i</span>) {
              <span class="org-keyword">return</span> <span class="org-constant">std</span>::any_cast&lt;<span class="org-constant">std</span>::<span class="org-type">remove_reference_t</span>&lt;<span class="org-type">Duck</span>&gt;&gt;(&amp;d)-&gt;quack(
                  i);
          }) {}

    <span class="org-type">void</span> <span class="org-function-name">quack</span>(<span class="org-type">int</span> <span class="org-variable-name">length</span>) <span class="org-keyword">const</span> { <span class="org-keyword">return</span> quack_(<span class="org-keyword">this</span>-&gt;duck_, length); }
};
</pre>
</div>
The copy constructors are there to be a better match than the templated constructor for copy by value. Codegen is surprisingly good. If the types are all present, the functions are inlined well, except for the overhead of storage into the any. For any unknown AnyDuck, there's a dispatch via pointer indirection:
<div class="org-src-container">
<pre class="src src-c++"><span class="org-type">void</span> <span class="org-function-name">test</span>(<span class="org-type">AnyDuck</span> <span class="org-variable-name">a</span>) {
    a.quack(1);
}
</pre>
</div>
results in something like
<div class="org-src-container">
<pre class="src src-asm"><span class="org-function-name">0000000000000050</span> &lt;test(scratch::AnyDuck)&gt;:
  <span class="org-keyword">50</span>:   48 8b 47 10             mov    0x10(<span class="org-variable-name">%rdi</span>),<span class="org-variable-name">%rax</span>
  <span class="org-keyword">54</span>:   be 01 00 00 00          mov    $0x1,<span class="org-variable-name">%esi</span>
  <span class="org-keyword">59</span>:   ff e0                   jmpq   *<span class="org-variable-name">%rax</span>
  <span class="org-keyword">5b</span>:   0f 1f 44 00 00          nopl   0x0(<span class="org-variable-name">%rax</span>,<span class="org-variable-name">%rax</span>,1)

</pre>
</div>
and the <code>any_cast&lt;&gt;</code> from the address of the passed in std::any is noexcept, but does in general have to check if the <code>any</code> has a value. Not as cheap as pure an interface type, but not terribly more expensive.

For the case where the <code>quack</code> is known, codegen is something like
<div class="org-src-container">
<pre class="src src-asm"><span class="org-function-name">scratch</span>::AnyDuck::AnyDuck&lt;Duck&amp;&gt;(Duck&amp;)::{lambda(std::any const&amp;, int)#1}::__invoke(std::any const&amp;, int): # @scratch::AnyDuck::AnyDuck&lt;Duck&amp;&gt;(Duck&amp;)::{lambda(std::any const&amp;, int)#1}::__invoke(std::any const&amp;, int)
        <span class="org-keyword">movl</span>    <span class="org-variable-name">%esi</span>, <span class="org-variable-name">%edi</span>
        <span class="org-keyword">jmp</span>     bell(int)                # TAILCALL
</pre>
</div>
If the implementation of the underlying quack is not available there's a little more work
<div class="org-src-container">
<pre class="src src-asm"><span class="org-function-name">scratch</span>::AnyDuck::AnyDuck&lt;Mallard&amp;&gt;(Mallard&amp;)::{lambda(std::any const&amp;, int)#1}::__invoke(std::any const&amp;, int): # @scratch::AnyDuck::AnyDuck&lt;Mallard&amp;&gt;(Mallard&amp;)::{lambda(std::any const&amp;, int)#1}::__invoke(std::any const&amp;, int)
        <span class="org-keyword">movl</span>    $_ZNSt3any17_Manager_internalI7MallardE9_S_manageENS_3_OpEPKS_PNS_4_ArgE, <span class="org-variable-name">%ecx</span>
        <span class="org-keyword">xorl</span>    <span class="org-variable-name">%eax</span>, <span class="org-variable-name">%eax</span>
        <span class="org-keyword">cmpq</span>    <span class="org-variable-name">%rcx</span>, (<span class="org-variable-name">%rdi</span>)
        <span class="org-keyword">leaq</span>    8(<span class="org-variable-name">%rdi</span>), <span class="org-variable-name">%rcx</span>
        <span class="org-keyword">cmoveq</span>  <span class="org-variable-name">%rcx</span>, <span class="org-variable-name">%rax</span>
        <span class="org-keyword">movq</span>    <span class="org-variable-name">%rax</span>, <span class="org-variable-name">%rdi</span>
        <span class="org-keyword">jmp</span>     Mallard::quack(int) const    # TAILCALL
</pre>
</div>
But far less than I would have expected. <code>std::any</code> is less awful than I thought.

You can take a look at the code so far here <a href="https://godbolt.org/#z:OYLghAFBqd5QCxAYwPYBMCmBRdBLAF1QCcAaPECAKxAEZSAbAQwDtRkBSAJgCFufSAZ1QBXYskwgA5NwDMeFsgYisAag6yAwqwCeG7BwAMAQTkKlKzOq0EdAB0wB9AsSaFB%2Bo6ZMsmAW0xBOyYJVUFkVwJkBHUAdj4TLyUmQUFVYxYdABERZABrOITjVRKwgnQQEF1VdFy8xw0i0tURQQVgVQBHERC8gDMWayzVADdUPHRVCAAqAEoIQXLK6rQWRe4ANlJVBQJZxq9m7t6Brp78htkiw9U7EQAjBjxkEBuSjOy6iA%2Bc/NVV9ZcDazIY1TB9JgiBgEA4mZo/L4I/KbEEaYZYCFQmFXN7pTK/PIQVGydHgyHQ2HeYqlAiYPx2Zi06yaWwOXwBVQEzxw0pIwlcoGbGp1fY85olEDCi4LJYgPokADuTGI6A0mi5smwEFq%2BVms1IuPFZ16jggHAArHxzVkZRUqpl/qg1jCgTVtrsdqj4oajaViJgCGJBos7bpHMgUtjNCHKv6/KgRk5/X1MP7FE4oxqDJqzUD0LMALT6Y75M1i30VvD7HHlo0cWJZL18BteXFjCbG0sehiYNgEBAggEEQqqf2B4iDEv1CD9vCCIuanX1bY9vsDxpxLKtls1qn14YAegPqnZgWCoXCkWirZMmAAHrSJ6NxpN7pgGAwIB6q5SksxUpydSFDcdyPM8rzlu2kxTl%2BLDDquwD9oOTqLIUY5Bqob4fhACFIQcLaJDu1wmMkAEALJMB%2ByqTPWTS3A8TwvG2L6doS3a9ohA6Os6v5ETexhHs%2BHYUVRKqVDB7FrshzrASYgnNDGKCiMOapquoXBcCJzBiepXDMmpuExKpWiqGAMjmpoLBmZSgn7vxUGqLSiwQFp1FCn4lHafmsnUiUl5MFESAgHyqhMBAHmifmlLNEwAB0MG0NW1wEVSDlOQQCwRAF0SVCFQ5CkwTa4nFCVJduW6JJVxgeh5CiwcOB7TMqwDINMB7bNEyrTNMqiNc1IxtaKpjeuWrTtCe/hniEVj%2BYF0WlASNTzX5WWBbl%2BJAWFUW7jF8XnISiW/uWglDoBfzIKqO2lIJs05cFG3nWFF1lcdx4RntvQQIdu64jdq13SF/guZ5bneg2L2%2Bb1x7%2BB9pZcBDv3HulwORbR%2B4Q80gnI4VR2Q4t6BcMtNRcLDhLw7xFXGFI%2BoMNI5pSKQLDSIYDOoNImj8PwYSiOIVhyLQDMEMz1P6nkICyAALLFsS0BssRy4YEu0AAnAAHLIhixIw0gSwzTNSCzpBs1IDOCCAhikELBvU6QcCwEgaD0ngPZkBQECO3YzupigzBsKrhgW30zuPmbED3MLpD3Aoyo6NIAukI7ARwQA8iwDCx9bpBYB5bA9hH%2BD%2BsgBB4ImZuZ/emDICItJxwzuzvrXjB4PcrjEDomgYJImcuHgfi1zTrDsJzvBN/cZuwKeKB%2BMgiwMFwpCJsQIAuCILB5HqRt2MXKHSAWyeyKoBYhminC8PwXBMKops8xIdA03TesR8bd6qxsBYbBL/y%2Bx0quxYYf9TFwIQEg6lZD0FUB3J2LtQGJQgcPHggthYbzFmA2KysJZq2VsrDYXAJYbHVlsWmUhdaMyftIU25tLZINtjARAIBlJ3AIOQSgHsvZL3oJgfARB2GkAVK4Ow/dtZSHpqQzOxt%2BaqAVIQGIL834fy/oPVQv9/6GytizZB4tZCxVkDo3Rei9FCJIfrQ2xsKEWzUSLIRXAGZ91oAHURJjyFUOthvRebQnQgAlkAA">Compiler Explorer Link to see the results</a>

I'll clean up my scratch project and push it at some point.

</div>
</div></body></html>