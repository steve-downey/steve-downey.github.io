<html><body><p>A further digression, because it turns out I want to be able to permute a tuple at run time. That means treating the element of a tuple generically. And I can just barely do this, for some tuples, in c++17. 

 So a slight digression into ADTs. Which in this case means Algebraic Data Types, not Abstract Data Types. But just algebra. No calculus, or differentiation, of data types. Not today. 

</p><div id="outline-container-org2cdd471" class="outline-2">
<h2 id="org2cdd471"><span class="section-number-2">1</span> Tuple is Product, Variant is Sum</h2>
<div class="outline-text-2" id="text-1">
</div><div id="outline-container-orge3984c5" class="outline-3">
<h3 id="orge3984c5"><span class="section-number-3">1.1</span> Products</h3>
<div class="outline-text-3" id="text-1-1">
 In algebra, we usually start out with addition. It's simpler. But for types, multiplication, or product, is in many ways much more natural. Your basic struct, record, etc is a natural product of types. A type is some kind of collection of things. And I'm being a bit vague here because this is right in the area where set seems like a good idea, and then we get into sets of sets, sets that might contain themselves, and barbers who shave all the people who don't shave themselves. There is rigour, but I don't really want to have to go there. 

 But, if we start with the idea that a type is a collection of things, and that we don't look to closely at the infinities, we are not going to be terribly wrong. So a type is a way of describing if a thing is in or out of the collection. 

 Now, I could pretend we don't know what a struct is. Start with pairs, where there are no names of the components of the struct, and build that up. But we all have a notion of struct. It's an ordered collection of types. The instances of the struct are all of the elements of each type contained in the struct, matched up with all of the other elements of all the other types in the struct. Known as the Cartesion product. So if you have a type A, and a type B, the collection of things in struct {A a; B b;} is the cross of As and Bs. That is {{a<sub>1</sub>, b<sub>1</sub>}, {a<sub>1</sub>, b<sub>2</sub>}, {a<sub>1</sub>, b<sub>3</sub>}, … , {a<sub>2</sub>, b<sub>1</sub>}, {a<sub>2</sub>, b<sub>2</sub>}, … {a<sub>n</sub>, b<sub>1</sub>}, … {a<sub>n</sub>, b<sub>m</sub>}} is all of the elements that are part of the type struct {A a; B b;}. The cardinality of {A, B} is the product of the cardinalities of A and B. 

 Structs are very natural in C++, but hard to deal with generically, so there's a type that does it all for you, std::tuple. Getting at the parts of the tuple is a little more difficult that with a struct. You have to say std::get&lt;0&gt;(tuple), or std::get&lt;int&gt;(tuple). And the second might not even compile, if the tuple has more than one int. But you get tools for composing and decomposing tuples at compile time. And std::tuple lets you put pretty much any C++ type into the tuple, only restricting you when you try to, e.g. move a tuple that has an element that can't be moved. 

 There should also be a type that acts as a unit for the product, the equivalent of 1 for multiplication. The empty tuple can work as a unit. It contains any of the list of no types. This implies that all empty tuples are equivalent, so its cardinality is 1. There can be only one. The product of a type with the empty tuple is entirely equivalent to the the type itself. There are no additional elements in the type, and you can convert back and forth between them. They are isomorphic, having the same shape. 

 Isomorphisms are important in talking about types, because most of the time we can't actually distinguish between isomorphic types, at least for proving things. The phrase "up to isomorphism" shows up a lot. To be isomorphic means that we can write a transformation $LATEX X$ from type A to type B, and a reverse transformation $LATEX Y$ from type B to type A, such that $latex Y(X(a)) == a$ for all a, and that for any function from a<sub>1</sub> to a<sub>2</sub>, there is an equivalent function from b<sub>1</sub> to b<sub>2</sub>. We could mechanically replace instances of a with the appropriate b and add calls to X and Y without changing the behavior of a program. 
</div>
</div>

<div id="outline-container-orgab373e6" class="outline-3">
<h3 id="orgab373e6"><span class="section-number-3">1.2</span> Sums</h3>
<div class="outline-text-3" id="text-1-2">
 The other basic algebraic type is the sum type. The corresponding primitive in C++ is a union, with one difference. In most type systems, the sum type automatically remembers which of the allowed types is in it. A union doesn't, so the standard technique is to embed the union in a struct that carries a tag saying which type in the union was most recently written, and can be read from. I'll be ignoring type-punning schemes allowing a read of a different type than was written. 

 So a Sum type of type A and type B is the union of all of the things in A and all of the things in B. {a<sub>1</sub>, a<sub>2</sub>, a<sub>3</sub>, … , a<sub>n</sub>, b<sub>1</sub>, b<sub>2</sub>, … , b<sub>m</sub>}. The cardinality of is the sum of the cardinalities of A and B. 

 The unit type of the sum is equivalent to zero. The empty sum type, although a valid type, has no elements in the type. It's like the empty set. It's often known as Void, where the unit for product is often called Unit. It may also be known as Bottom, where that is a computation that never completes. Since there are no elements of the type Void, it can't be instantiated. And a product of Void and any other type is equivalent to Void. The c++ type <code>void</code> is related, but not exactly the same, because it also represents an empty argument list, a function that returns, but does not return any value (a subroutine), and is also functions as the universal pointer. 

 C++17 recently standardized a sum type to go with the long standardized std::tuple, std::variant. Std::variant remembers which of the alternative types was last set. It is almost never empty, only so if a write into one of the alternatives threw an exception. It is not allowed to hold <code>void</code>, references, arrays, or to contain no types. This is a bit unfortunate, because except for <code>void</code> std::tuple can do all of those things. 

 There were several competing models for what std::variant should be, with various tradeoffs being made. It was always clear that std::tuple had to be able to represent everything a struct can, and in fact there are now language features to destructure a struct into a tuple. There is no equivalent model for sum types. Union can't hold anything but trivial types because there is no mechanism to track what to do on destruction, since there is no built-in mechanism to determine what the union was last written as. 

 One of the popular models for variant rises out of database-like interfaces. Even though databases are internally strongly typed, SQL queries are not. And the model of sending text over and getting some kind of response back makes it difficult to expose that to a host language. Particularly when the database schema may change, the query still be perfectly valid, but no longer return the same types. However, since we do know there is a relatively short list of permitted types in the database, a variant that allows just those types and the ability to query what type was returned can be quite useful, and not terribly hard to implement. There are JSON parsers taking similar approaches, only with the addition that a JSON type may have JSON objects contained in them recursively, and those have to be outside the object somehow, or the size of the object is unbounded. 

 From the implementors point of view, supporting pointers and arrays is a huge amout of extra work. Not allowing an array to decay to a pointer is quite difficult. References have issues when treated generically. Not to mention that references have decidely odd semantics in the differences between construction and assignment. And the degenerate case of an empty variant was also difficult. If that needs to be represented, the type std::monostate has been introduced, which is a type designed to have exactly one item in it, so that all instances of std::monostate are identical. This is also the same as the unit type for product types. It's not an accident that it's represented in Haskell as (), which is the empty tuple. All empty lists are equivalent. It could have been <code>std::tuple&lt;&gt;</code>, but no one in the room happened to think of that. 
</div>
</div>
</div>

<div id="outline-container-org7c3ced4" class="outline-2">
<h2 id="org7c3ced4"><span class="section-number-2">2</span> Tuple is a Heterogenous Container, what is the iterator?</h2>
<div class="outline-text-2" id="text-2">
 The C++ standard says "tuples are heterogeneous, fixed-size collections of values" - [tuple.general]. Collections generally have iterator types associated with them, but that's a bit of a challenge since the iterator model in C++ assumes that for a collection, the type of *(Collection&lt;T&gt;::iterator) is T. But if the collection isn't on T, but on Types…, you doesn't quite work to say *(Collection&lt;typename… Types&gt;) is of type …Types. You need something to hold that. But in many cases, std::variant can work. It doesn't quiet work, since we'd really need a variant of references to the elements of the tuple, so that they could be written to. However, for many purposes we can come close. For the case I was looking at, making copies is perfectly fine. What I'm looking for is something roughly with the signature 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span>... Types
<span class="org-keyword">auto</span> getElement(<span class="org-type">size_t</span> <span class="org-variable-name">i</span>, <span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;Types...&gt; <span class="org-variable-name">tuple</span>) -&gt; <span class="org-constant">std</span>::<span class="org-type">variant</span>&lt;Types...&gt;;
</pre>
</div>

 That is, something that will get me the i<sub>th</sub> element of a tuple, as a variant with the same typelist as the tuple, with the index determined at runtime. All of the normal accessors are compile time. So need to do something that will make the compile time information available at runtime. 

 Start with something I do know how to do, idiomatically printing a tuple. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span> <span class="org-type">Func</span>, <span class="org-keyword">typename</span> <span class="org-type">Tuple</span>, <span class="org-constant">std</span>::<span class="org-type">size_t</span>... <span class="org-variable-name">I</span>&gt;
<span class="org-type">void</span> <span class="org-function-name">tuple_for_each_impl</span>(<span class="org-type">Tuple</span>&amp;&amp; <span class="org-variable-name">tuple</span>, <span class="org-type">Func</span>&amp;&amp; <span class="org-variable-name">f</span>, <span class="org-constant">std</span>::<span class="org-type">index_sequence</span>&lt;I...&gt;)
{
    <span class="org-keyword">auto</span> <span class="org-variable-name">swallow</span> = {0,
                    (<span class="org-constant">std</span>::forward&lt;<span class="org-type">Func</span>&gt;(f)(
                        I, <span class="org-constant">std</span>::get&lt;I&gt;(<span class="org-constant">std</span>::forward&lt;<span class="org-type">Tuple</span>&gt;(tuple))))...};
    (<span class="org-type">void</span>)swallow;
}

<span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span> <span class="org-type">Func</span>, <span class="org-keyword">typename</span>... Args&gt;
<span class="org-type">void</span> <span class="org-function-name">tuple_for_each</span>(<span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;Args...&gt; <span class="org-keyword">const</span>&amp; <span class="org-variable-name">tuple</span>, <span class="org-variable-name">Func</span>&amp;&amp; f)
{
    tuple_for_each_impl(tuple, f, <span class="org-constant">std</span>::<span class="org-type">index_sequence_for</span>&lt;Args...&gt;{});
}

<span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span>... Args&gt;
<span class="org-type">void</span> <span class="org-function-name">print</span>(<span class="org-constant">std</span>::<span class="org-type">ostream</span>&amp; <span class="org-variable-name">os</span>, <span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;Args...&gt; <span class="org-keyword">const</span>&amp; <span class="org-variable-name">tuple</span>)
{
    <span class="org-keyword">auto</span> <span class="org-variable-name">printer</span> = [&amp;os](<span class="org-keyword">auto</span> <span class="org-variable-name">i</span>, <span class="org-keyword">auto</span> <span class="org-variable-name">el</span>) {
        os &lt;&lt; (i == 0 ? <span class="org-string">""</span> : <span class="org-string">", "</span>) &lt;&lt; el;
        <span class="org-keyword">return</span> 0;
    };
    <span class="org-keyword">return</span> tuple_for_each(tuple, printer);
}
</pre>
</div>

 Actually, a bit more complicated than the totally standard idiom, since it factors out the printer into a application across the tuple, but it's not much more compilcated. The tuple_for_each constructs an index sequence based on the argument list, and delegates that to the impl, which uses it to apply the function to each element of the tuple. The _impl ought to be in a nested detail namespace, so as not to leak out. Swallow is the typical name for using an otherwise unnamed, and uninteresting, type to apply something to each element of the tuple for a side-effect. The void cast is to make sure the variable is used, and is evaluated. 

 The next step is, instead of an application of a function for its side-effect, instead a mapping of the tuple, returning the transformed tuple. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span> <span class="org-type">Func</span>, <span class="org-keyword">typename</span> <span class="org-type">Tuple</span>, <span class="org-constant">std</span>::<span class="org-type">size_t</span>... <span class="org-variable-name">I</span>&gt;
<span class="org-keyword">auto</span> <span class="org-function-name">tuple_transform_impl</span>(<span class="org-type">Tuple</span>&amp;&amp; <span class="org-variable-name">tuple</span>, <span class="org-type">Func</span>&amp;&amp; <span class="org-variable-name">f</span>, <span class="org-constant">std</span>::<span class="org-type">index_sequence</span>&lt;I...&gt;)
{
    <span class="org-keyword">return</span> <span class="org-constant">std</span>::make_tuple(
        <span class="org-constant">std</span>::forward&lt;<span class="org-type">Func</span>&gt;(f)(<span class="org-constant">std</span>::get&lt;I&gt;(<span class="org-constant">std</span>::forward&lt;<span class="org-type">Tuple</span>&gt;(tuple)))...);
}

<span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span> <span class="org-type">Func</span>, <span class="org-keyword">typename</span>... Args&gt;
<span class="org-keyword">auto</span> <span class="org-function-name">tuple_transform</span>(<span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;Args...&gt;&amp;&amp; <span class="org-variable-name">tuple</span>, <span class="org-variable-name">Func</span>&amp;&amp; f)
{
    <span class="org-keyword">return</span> tuple_transform_impl(tuple, f, <span class="org-constant">std</span>::<span class="org-type">index_sequence_for</span>&lt;Args...&gt;{});
}

<span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span> <span class="org-type">Func</span>, <span class="org-keyword">typename</span>... Args&gt;
<span class="org-keyword">auto</span> <span class="org-function-name">tuple_transform</span>(<span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;Args...&gt; <span class="org-keyword">const</span>&amp; <span class="org-variable-name">tuple</span>, <span class="org-variable-name">Func</span>&amp;&amp; f)
{
    <span class="org-keyword">return</span> tuple_transform_impl(tuple, f, <span class="org-constant">std</span>::<span class="org-type">index_sequence_for</span>&lt;Args...&gt;{});
}
</pre>
</div>

 Because the std::tuple is not a template parameter, I have to supply a const&amp; and a forwarding-reference form to cover both cases. And I'm ignoring volatile quals. The _impl function uses forwarding-reference parameters, which will decay or forward properly using std::forward. Using it is straightforward. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;<span class="org-type">int</span>, <span class="org-type">double</span>, <span class="org-type">long</span>&gt; <span class="org-variable-name">t</span> = <span class="org-constant">std</span>::make_tuple(1, 2.3, 1l);
<span class="org-keyword">auto</span> <span class="org-variable-name">transform</span> = <span class="org-constant">tupleutil</span>::tuple_transform(t,
                                            [](<span class="org-keyword">auto</span> <span class="org-variable-name">i</span>) { <span class="org-keyword">return</span> i + 1; });

EXPECT_EQ(3.3, <span class="org-constant">std</span>::get&lt;1&gt;(transform));

<span class="org-keyword">auto</span> <span class="org-variable-name">t2</span> = <span class="org-constant">tupleutil</span>::tuple_transform(<span class="org-constant">std</span>::make_tuple(4, 5.0),
                                     [](<span class="org-keyword">auto</span> <span class="org-variable-name">i</span>) { <span class="org-keyword">return</span> i + 1; });
EXPECT_EQ(6, <span class="org-constant">std</span>::get&lt;1&gt;(t2));
</pre>
</div>

 So, for functions over all the types in a tuple, tuple is a Functor. That is, we can apply the function to all elements in the tuple, and it's just like making a tuple out of applying the functions to elements before making the tuple. If this sounds like a trivial distinction, you are mostly right. Almost all container-ish things are Functors, and a few non-containerish things are also. Plus Functor sounds more impressive. 

 The transform also suggests a way of solving the problem I was originally looking at. An array of the elements of the tuple each as a variant will let me permute them with std tools. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span>... Args, <span class="org-constant">std</span>::<span class="org-type">size_t</span>... <span class="org-variable-name">I</span>&gt;
<span class="org-keyword">constexpr</span> <span class="org-constant">std</span>::<span class="org-type">array</span>&lt;<span class="org-constant">std</span>::<span class="org-type">variant</span>&lt;Args...&gt;, <span class="org-keyword">sizeof</span>...(Args)&gt;
<span class="org-function-name">tuple_to_array_impl</span>(<span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;Args...&gt; <span class="org-keyword">const</span>&amp; <span class="org-variable-name">tuple</span>,
                    <span class="org-constant">std</span>::<span class="org-type">index_sequence</span>&lt;I...&gt;)
{
    <span class="org-keyword">using</span> <span class="org-type">V</span> = <span class="org-constant">std</span>::<span class="org-type">variant</span>&lt;Args...&gt;;
    <span class="org-constant">std</span>::<span class="org-type">array</span>&lt;<span class="org-type">V</span>, <span class="org-keyword">sizeof</span>...(Args)&gt; <span class="org-variable-name">array</span> = {
        {<span class="org-function-name">V</span>(<span class="org-constant">std</span>::<span class="org-type">in_place_index_t</span>&lt;I&gt;{}, <span class="org-constant">std</span>::get&lt;I&gt;(<span class="org-variable-name">tuple</span>))...}};
    <span class="org-keyword">return</span> array;
}

<span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span>... Args&gt;
<span class="org-keyword">constexpr</span> <span class="org-constant">std</span>::<span class="org-type">array</span>&lt;<span class="org-constant">std</span>::<span class="org-type">variant</span>&lt;Args...&gt;, <span class="org-keyword">sizeof</span>...(Args)&gt;
<span class="org-function-name">tuple_to_array</span>(<span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;Args...&gt; <span class="org-keyword">const</span>&amp; <span class="org-variable-name">tuple</span>)

{
    <span class="org-keyword">return</span> tuple_to_array_impl(tuple, <span class="org-constant">std</span>::<span class="org-type">index_sequence_for</span>&lt;Args...&gt;{});
}
</pre>
</div>

 And that can be used something like: 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-function-name">TEST</span>(TupleTest, to_array)
{
    <span class="org-keyword">constexpr</span> <span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;<span class="org-type">int</span>, <span class="org-type">double</span>, <span class="org-type">long</span>&gt; <span class="org-variable-name">t</span> = <span class="org-constant">std</span>::make_tuple(1, 2.3, 1l);
    <span class="org-keyword">auto</span> <span class="org-variable-name">arr</span> = <span class="org-constant">tupleutil</span>::tuple_to_array(t);
    <span class="org-type">int</span>  <span class="org-variable-name">i</span>   = <span class="org-constant">std</span>::get&lt;<span class="org-type">int</span>&gt;(arr[0]);
    EXPECT_EQ(1, i);
}

<span class="org-function-name">TEST</span>(TupleTest, to_array_repeated)
{
    <span class="org-keyword">constexpr</span> <span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;<span class="org-type">int</span>, <span class="org-type">int</span>, <span class="org-type">int</span>&gt; <span class="org-variable-name">t</span> = <span class="org-constant">std</span>::make_tuple(1, 2, 3);
    <span class="org-keyword">auto</span> <span class="org-variable-name">arr</span> = <span class="org-constant">tupleutil</span>::tuple_to_array(t);
    <span class="org-type">int</span>  <span class="org-variable-name">i</span>   = <span class="org-constant">std</span>::get&lt;2&gt;(arr[2]);
    EXPECT_EQ(3, i);
}
</pre>
</div>

 The second test is there because I was about to write, "as you can see, we can tell the differece between variants holding the same type", except that wasn't true. The original version of to_ar 

<div class="org-src-container">
<pre class="src src-C++">    <span class="org-keyword">constexpr</span> <span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;<span class="org-type">int</span>, <span class="org-type">double</span>, <span class="org-type">long</span>&gt; <span class="org-variable-name">t</span> = <span class="org-constant">std</span>::make_tuple(1, 2.3, 1l);
    <span class="org-constant">std</span>::<span class="org-type">variant</span>&lt;<span class="org-type">int</span>, <span class="org-type">double</span>, <span class="org-type">long</span>&gt; <span class="org-variable-name">v0</span>{1};
    <span class="org-keyword">auto</span> <span class="org-variable-name">v</span> = <span class="org-constant">tupleutil</span>::get(0, t);
    EXPECT_EQ(v0, v);
</pre>
</div>
 ray didn't use the constructor form with std::in_place_index_t. The code I ended up with did, but not at this point. There's nothing like writing out what something is supposed to do to make you look and keep you honest. 

 So here, we're constructing an array of std::variant&lt;Args…&gt; and constructing each member with the argument pack expansion into the std::variant constructor using the I<sub>th</sub> index value to get that element of the tuple, and recording that we're constructing the i<sub>th</sub> alternative of the variant. The second test checks that. The 2nd element of the array must be the 2nd variant of the tuple, and can be retrieved only by std::get&lt;2&gt;(). 

 This would allow me to permutate the elements of a tuple, but I'm fairly close now to being able to writing a version that allows choice of the element at runtime, rather than at compile time. 

<div class="org-src-container">
<pre class="src src-C++">    <span class="org-keyword">constexpr</span> <span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;<span class="org-type">int</span>, <span class="org-type">double</span>, <span class="org-type">long</span>&gt; <span class="org-variable-name">t</span> = <span class="org-constant">std</span>::make_tuple(1, 2.3, 1l);
    <span class="org-constant">std</span>::<span class="org-type">variant</span>&lt;<span class="org-type">int</span>, <span class="org-type">double</span>, <span class="org-type">long</span>&gt; <span class="org-variable-name">v0</span>{1};
    <span class="org-keyword">auto</span> <span class="org-variable-name">v</span> = <span class="org-constant">tupleutil</span>::get(0, t);
    EXPECT_EQ(v0, v);
</pre>
</div>

 What I'm going to do is construct an array of the getters for the tuple, each of which will return the element wrapped in a variant. The signature of the array will be of function pointer type, because, quite conveniently, a non-capturing lambda can decay to a function pointer. 

 First getting the array of getters for the tuple 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span> <span class="org-type">V</span>, <span class="org-keyword">typename</span> <span class="org-type">T</span>, <span class="org-type">size_t</span> <span class="org-variable-name">I</span>&gt; <span class="org-keyword">auto</span> <span class="org-function-name">get_getter</span>()
{
    <span class="org-keyword">return</span> [](<span class="org-type">T</span> <span class="org-keyword">const</span>&amp; <span class="org-variable-name">t</span>) {
        <span class="org-keyword">return</span> V{<span class="org-constant">std</span>::<span class="org-type">in_place_index_t</span>&lt;I&gt;{}, <span class="org-constant">std</span>::get&lt;I&gt;(t)};
    };
}

<span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span>... Args, <span class="org-constant">std</span>::<span class="org-type">size_t</span>... <span class="org-variable-name">I</span>&gt;
<span class="org-keyword">auto</span> <span class="org-function-name">tuple_getters_impl</span>(<span class="org-constant">std</span>::<span class="org-type">index_sequence</span>&lt;I...&gt;)
{
    <span class="org-keyword">using</span> <span class="org-type">V</span> = <span class="org-constant">std</span>::<span class="org-type">variant</span>&lt;Args...&gt;;
    <span class="org-keyword">using</span> <span class="org-type">T</span> = <span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;Args...&gt;;
    <span class="org-keyword">using</span> <span class="org-type">F</span> = V (*)(<span class="org-type">T</span> <span class="org-keyword">const</span>&amp;);
    <span class="org-constant">std</span>::<span class="org-type">array</span>&lt;<span class="org-type">F</span>, <span class="org-keyword">sizeof</span>...(Args)&gt; <span class="org-variable-name">array</span>
        <span class="org-comment-delimiter">//        </span><span class="org-comment">= {{[](T const&amp; tuple){return V{std::get&lt;I&gt;(tuple)};}...}};</span>
        = {{get_getter&lt;<span class="org-type">V</span>, <span class="org-type">T</span>, I&gt;()...}};
    <span class="org-keyword">return</span> array;
}

<span class="org-keyword">template</span> &lt;<span class="org-keyword">typename</span>... Args&gt; <span class="org-keyword">auto</span> <span class="org-function-name">tuple_getters</span>(<span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;Args...&gt;)
{
    <span class="org-keyword">return</span> tuple_getters_impl&lt;Args...&gt;(<span class="org-constant">std</span>::<span class="org-type">index_sequence_for</span>&lt;Args...&gt;{});
}
</pre>
</div>

 So first a function that returns a function that constructs a variant around the value of what's returned from std::get&lt;I&gt;. Well, it could return anything that happens to have a constructor that takes a an in_place_index_t, take as the thing to be converted something that std::get&lt;I&gt; can extract from. This is actually a separate function because GCC was unhappy doing the template parameter pack expansion inline in the _impl function. Clang was happy with the expansion noted in the comment. I really have no idea who is wrong here, and the workaround was straight forward. The array is one of function pointers, which the returned lambdas can decay to. 

 Now the only remaining trick is to use this array as a table to dispatch to the appropriate getter for the tuple. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-keyword">const</span> <span class="org-keyword">auto</span> get = [](<span class="org-type">size_t</span> <span class="org-variable-name">i</span>, <span class="org-keyword">auto</span> <span class="org-variable-name">t</span>) {
    <span class="org-keyword">static</span> <span class="org-keyword">auto</span> <span class="org-variable-name">tbl</span> = <span class="org-constant">tupleutil</span>::tuple_getters(t);
    <span class="org-keyword">return</span> tbl[i](t);
};
</pre>
</div>

 Get the array as a static, so we only need to computer it once, and simply return <code>tbl[i](t)</code> 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-function-name">TEST</span>(TupleTest, gettersStatic)
{
    <span class="org-keyword">constexpr</span> <span class="org-constant">std</span>::<span class="org-type">tuple</span>&lt;<span class="org-type">int</span>, <span class="org-type">double</span>, <span class="org-type">long</span>&gt; <span class="org-variable-name">t</span> = <span class="org-constant">std</span>::make_tuple(1, 2.3, 1l);
    <span class="org-constant">std</span>::<span class="org-type">variant</span>&lt;<span class="org-type">int</span>, <span class="org-type">double</span>, <span class="org-type">long</span>&gt; <span class="org-variable-name">v0</span>{1};
    <span class="org-keyword">auto</span> <span class="org-variable-name">v</span> = <span class="org-constant">tupleutil</span>::get(0, t);
    EXPECT_EQ(v0, v);

    <span class="org-type">int</span>  <span class="org-variable-name">i</span> = <span class="org-constant">std</span>::get&lt;0&gt;(v);
    EXPECT_EQ(1, i);

    <span class="org-keyword">auto</span> <span class="org-variable-name">v2</span> = <span class="org-constant">tupleutil</span>::get(1, t);

    EXPECT_EQ(1ul, v2.index());
    <span class="org-type">double</span> <span class="org-variable-name">d</span> = <span class="org-constant">std</span>::get&lt;<span class="org-type">double</span>&gt;(v2);

    EXPECT_EQ(2.3, d);

    <span class="org-keyword">constexpr</span> <span class="org-keyword">auto</span> t2 = <span class="org-constant">std</span>::make_tuple(2.4, 1l);
    <span class="org-keyword">auto</span>           <span class="org-variable-name">v3</span> = <span class="org-constant">tupleutil</span>::get(0, t2);
    <span class="org-type">double</span>         <span class="org-variable-name">d2</span> = <span class="org-constant">std</span>::get&lt;<span class="org-type">double</span>&gt;(v3);

    EXPECT_EQ(2.4, d2);
}
</pre>
</div>
</div>
</div>

<div id="outline-container-orgd331339" class="outline-2">
<h2 id="orgd331339"><span class="section-number-2">3</span> Source</h2>
<div class="outline-text-2" id="text-3">
 All source is available at <a href="https://github.com/steve-downey/tupleutil">TupleUtil</a> on GitHub, including org source for this post. 
</div>
</div></body></html>