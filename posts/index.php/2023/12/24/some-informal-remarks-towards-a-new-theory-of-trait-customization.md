<html><body><div id="outline-container-org0a7dcc5" class="outline-2">
<h2 id="org0a7dcc5">A Possible Technique</h2>
<div class="outline-text-2" id="text-org0a7dcc5">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="org-keyword">constexpr</span> <span class="org-type">bool</span> <span class="org-function-name">g</span>(<span class="org-type">int</span> <span class="org-variable-name">lhs</span>, <span class="org-type">int</span> <span class="org-variable-name">rhs</span>) {
    <span class="org-keyword">auto</span>&amp; <span class="org-variable-name">op</span> = <span class="org-type">partial_eq</span>&lt;<span class="org-type">int</span>&gt;;
    <span class="org-keyword">return</span> op.ne(lhs, rhs);
}
</pre>
</div>
<a href="https://godbolt.org/z/Ge43cWfn8">Compiler Explorer with Supporting Code</a>

A trait is defined as a template variable that implements the required operations. Implementation of those operations is possible via a variety of techniques, but existence is concept checkable. It might prove useful to explicitly opt in to a sufficiently generic trait.

The technique satisfies the openness requirement, that the trait can be created independently of the type that models the trait. There can still only be one definition, but this enables opting std:: types into new traits, for example.

It also doesn't universally grab an operation name. The trait variable is namespaceable.

Syntax isn't really awesome, but not utterly unworkable.

</div>
</div>
<div id="outline-container-org5ad6709" class="outline-2">
<h2 id="org5ad6709">Background</h2>
<div class="outline-text-2" id="text-org5ad6709">

 Several years ago, Barry Revzin in "<a href="https://brevzin.github.io/c++/2020/12/01/tag-invoke/">Why tag_invoke is not the solution I want"</a> outlined the characteristics that a good customization interface would have. Quoting
<blockquote>
<ol class="org-ol">
 	<li>The ability to see clearly, in code, what the interface is that can (or needs to) be customized.</li>
 	<li>The ability to provide default implementations that can be overridden, not just non-defaulted functions.</li>
 	<li>The ability to opt in explicitly to the interface.</li>
 	<li>The inability to incorrectly opt in to the interface (for instance, if the interface has a function that takes an int, you cannot opt in by accidentally taking an unsigned int).</li>
 	<li>The ability to easily invoke the customized implementation. Alternatively, the inability to accidentally invoke the base implementation.</li>
 	<li>The ability to easily verify that a type implements an interface.</li>
</ol>
</blockquote>
I believe that with some support on the implementation side, and some <code>concept</code> definitions to assert correct usage, having an explicit object that implements the required traits for a concept can satisfy more of the requirements than <code>tag_invoke</code> or <code>std::</code> customization points. The trade-off is that usage of the trait is explicit and not dependent on arguments to the trait, which means that it is more verbose and possible to get wrong in both subtle and gross ways.

</div>
</div>
<div id="outline-container-org87d886f" class="outline-2">
<h2 id="org87d886f"><code>concept_map</code></h2>
<div class="outline-text-2" id="text-org87d886f">

 In the original proposal for C++ concepts, there was a facility called ~concept_map~s where
<blockquote> Concept maps describe how a set of template arguments satisfy the requirements stated in the body of a concept definition.</blockquote>
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="org-keyword">class</span> <span class="org-type">student_record</span> {
  <span class="org-keyword">public</span>:
    <span class="org-type">string</span> <span class="org-variable-name">id</span>;
    <span class="org-type">string</span> <span class="org-variable-name">name</span>;
    <span class="org-type">string</span> <span class="org-variable-name">address</span>;
};

<span class="org-keyword">concept</span> <span class="org-type">EqualityComparable</span>&lt;<span class="org-keyword">typename</span> <span class="org-type">T</span>&gt; {
    <span class="org-type">bool</span> <span class="org-keyword">operator</span><span class="org-variable-name">==</span>(<span class="org-type">T</span>, <span class="org-type">T</span>);
}

<span class="org-type">concept_map</span> <span class="org-type">EqualityComparable</span><span class="org-variable-name">&lt;student_record&gt;</span> {
    <span class="org-type">bool</span> <span class="org-keyword">operator</span><span class="org-variable-name">==</span>(<span class="org-keyword">const</span> <span class="org-type">student_record</span>&amp; <span class="org-variable-name">a</span>, <span class="org-keyword">const</span> <span class="org-type">student_record</span>&amp; <span class="org-variable-name">b</span>) {
        <span class="org-keyword">return</span> a.id == b.id;
    }
};

<span class="org-keyword">template</span>&lt;<span class="org-keyword">typename</span> <span class="org-type">T</span>&gt; <span class="org-keyword">requires</span> <span class="org-type">EqualityComparable</span>&lt;<span class="org-type">T</span>&gt;
<span class="org-type">void</span> <span class="org-function-name">f</span>(<span class="org-type">T</span>);

f(student_record()); <span class="org-comment-delimiter">// </span><span class="org-comment">okay, have concept_map EqualityComparable&lt;student_record&gt;</span>
</pre>
</div>
<a href="https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2008/n2617.pdf">n2617</a>

This allowed for customizing how the various requirements for a concept were implemented for a particular type.

This was lost in Concepts Lite, a.k.a C++20 Concepts.

Other generic type systems have implemented something like this feature, as well as definition checking. In particular, Rust Traits are an analagous feature.

</div>
</div>
<div id="outline-container-org71089d8" class="outline-2">
<h2 id="org71089d8">Rust Traits</h2>
<div class="outline-text-2" id="text-org71089d8">
<blockquote> A trait is a collection of methods defined for an unknown type: <code>Self</code>. They can access other methods declared in the same trait.</blockquote>
An example that Revzin mentions, and that my first example alludes to is PartialEq:
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-rust" id="nil"><span class="org-keyword">pub</span> <span class="org-keyword">trait</span> <span class="org-type">PartialEq</span>&lt;<span class="org-variable-name">Rhs</span>: <span class="org-rust-question-mark">?</span><span class="org-type">Sized</span> = <span class="org-type">Self</span>&gt; {
    <span class="org-doc">/// This method tests for `self` and `other` values to be equal, and is used</span>
    <span class="org-doc">/// by `==`.</span>
    <span class="org-keyword">fn</span> <span class="org-function-name">eq</span>(<span class="org-rust-ampersand">&amp;</span><span class="org-keyword">self</span>, <span class="org-variable-name">other</span>: <span class="org-rust-ampersand">&amp;</span><span class="org-type">Rhs</span>) -&gt; <span class="org-type">bool</span>;

    <span class="org-doc">/// This method tests for `!=`. The default implementation is almost always</span>
    <span class="org-doc">/// sufficient, and should not be overridden without very good reason.</span>
    <span class="org-keyword">fn</span> <span class="org-function-name">ne</span>(<span class="org-rust-ampersand">&amp;</span><span class="org-keyword">self</span>, <span class="org-variable-name">other</span>: <span class="org-rust-ampersand">&amp;</span><span class="org-type">Rhs</span>) -&gt; <span class="org-type">bool</span> {
        !<span class="org-keyword">self</span>.eq(other)
    }
}
</pre>
</div>
From <a href="https://doc.rust-lang.org/src/core/cmp.rs.html#219">https://doc.rust-lang.org/src/core/cmp.rs.html#219</a>

In Rust this is built into the language, and operators like == are automatically rewritten into <code>eq</code> and <code>ne</code>. At least that's my understanding. We're not going to get that in C++, ever. With both Rust and Concept Maps, though, we do get new named operations that can be used unqualified in generic code and the compiler will be directed to the correct implementation.

Giving up on that is key to a way forward in C++.

</div>
</div>
<div id="outline-container-org9dd42da" class="outline-2">
<h2 id="org9dd42da">A trait object</h2>
<div class="outline-text-2" id="text-org9dd42da">

 The technique I'm considering and describing here is modeled loosly after the implementation of Haskell typeclasses in GHC. For a particular instance of a typeclass, a record holding the operations based on the actual type in use is created and made available, and the named operations are lifted into scope and the functions in the record called when used. It is as if a virtual function table was implemented with name lookup rather than index.

In C++, particularly in current post-C++20 C++, we can look up an object via a template variable. The implementations of different specializations of a template variable do not need to be connected in any way. We have to provide a definition, since to make it look like a declaration it's necessary to provide some type such as false_type. Alternatively, we could declare it as an int, but mark it as <code>extern</code> and not define it. I'm still researching alternatives.
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-C++" id="nil"><span class="org-keyword">template</span>&lt;<span class="org-keyword">class</span> <span class="org-type">T</span>&gt; <span class="org-keyword">auto</span> <span class="org-variable-name">someTrait</span> = <span class="org-constant">std</span>::false_type{};

<span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span> <span class="org-type">T</span>&gt;
<span class="org-keyword">extern</span> <span class="org-type">int</span> <span class="org-variable-name">otherTrait</span>;
</pre>
</div>
These are useful if there is no good generic definition of the trait.

If there is a good generic definition of a trait, the trait variable is straightforward:
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="org-keyword">constexpr</span> <span class="org-keyword">inline</span> <span class="org-keyword">struct</span> {
    <span class="org-keyword">constexpr</span> <span class="org-keyword">auto</span> <span class="org-function-name">eq</span>(<span class="org-keyword">auto</span> <span class="org-variable-name">rhs</span>, <span class="org-keyword">auto</span> <span class="org-variable-name">lhs</span>) <span class="org-keyword">const</span> {<span class="org-keyword">return</span> rhs == lhs;}
    <span class="org-keyword">constexpr</span> <span class="org-keyword">auto</span> <span class="org-function-name">ne</span>(<span class="org-keyword">auto</span> <span class="org-variable-name">rhs</span>, <span class="org-keyword">auto</span> <span class="org-variable-name">lhs</span>) <span class="org-keyword">const</span> {<span class="org-keyword">return</span> <span class="org-negation-char">!</span>eq(lhs, rhs);}
} <span class="org-variable-name">partial_eq_default</span>;

<span class="org-keyword">template</span>&lt;<span class="org-keyword">class</span> <span class="org-type">T</span>&gt;
<span class="org-keyword">constexpr</span> <span class="org-keyword">inline</span> <span class="org-keyword">auto</span> <span class="org-variable-name">partial_eq</span> = partial_eq_default;
</pre>
</div>
In this case, though, there probably ought to be an opt in so that the trait can be checked by concept.

An opt in mechanism is a bit verbose, but not necessarily complicated:
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-c++" id="nil"><span class="org-keyword">template</span>&lt;<span class="org-keyword">class</span> <span class="org-type">T</span>&gt; <span class="org-keyword">constexpr</span> <span class="org-keyword">auto</span> <span class="org-variable-name">partial_eq_type</span> = <span class="org-constant">false</span>;
<span class="org-keyword">template</span>&lt;&gt; <span class="org-keyword">constexpr</span> <span class="org-keyword">auto</span> <span class="org-type">partial_eq_type</span><span class="org-variable-name">&lt;int&gt;</span> = <span class="org-constant">true</span>;
<span class="org-keyword">template</span>&lt;&gt; <span class="org-keyword">constexpr</span> <span class="org-keyword">auto</span> <span class="org-type">partial_eq_type</span><span class="org-variable-name">&lt;double&gt;</span> = <span class="org-constant">true</span>;

<span class="org-keyword">template</span>&lt;<span class="org-keyword">typename</span> <span class="org-type">T</span>&gt;
<span class="org-keyword">concept</span> <span class="org-type">is_partial_eq</span> =
  <span class="org-type">partial_eq_type</span>&lt;<span class="org-type">T</span>&gt; &amp;&amp;
    <span class="org-keyword">requires</span>(<span class="org-type">T</span> <span class="org-variable-name">lhs</span>, <span class="org-type">T</span> <span class="org-variable-name">rhs</span>) {
    <span class="org-type">partial_eq</span>&lt;<span class="org-type">T</span>&gt;.eq(lhs, rhs);
    <span class="org-type">partial_eq</span>&lt;<span class="org-type">T</span>&gt;.ne(lhs, rhs);
};

<span class="org-keyword">constexpr</span> <span class="org-type">bool</span> <span class="org-function-name">h</span>(<span class="org-type">is_partial_eq</span> <span class="org-keyword">auto</span> <span class="org-variable-name">lhs</span>, <span class="org-type">is_partial_eq</span> <span class="org-keyword">auto</span> <span class="org-variable-name">rhs</span>) {
    <span class="org-keyword">return</span> <span class="org-type">partial_eq</span>&lt;<span class="org-keyword">decltype</span>(lhs)&gt;.eq(lhs, rhs);
}
</pre>
</div>
I have not done a good job at allocating names to the various bits and pieces. Please excuse this.

</div>
</div>
<div id="outline-container-orgf6b19fc" class="outline-2">
<h2 id="orgf6b19fc">What have I missed?</h2>
<div class="outline-text-2" id="text-orgf6b19fc">

 We've been making variable templates more capable in many ways, and the concept checks to ensure correctness are new, but has anyone else explored this and found insurmountable problems?

</div>
</div></body></html>