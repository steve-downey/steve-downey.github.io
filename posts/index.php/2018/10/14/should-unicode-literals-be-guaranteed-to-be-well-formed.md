<html><body><p>TL;DR Betteridge's law applies: No. 

 Are you still here? 

</p><div id="outline-container-org399ca07" class="outline-2">
<h2 id="org399ca07">Unicode Literals</h2>
<div class="outline-text-2" id="text-org399ca07">
 In C++ 20 there are 2 kinds and 6 forms of Unicode literals. Character literals and string literals, in UTF-8, UTF-16, and UTF-32 encodings. Each of them uses a distinct char type to signal in the type system what the encoding is for the data. For plain <code>char</code> literals, the encoding is the execution character set, which is implementation defined. It might be something useful, like UTF-8, or old, like UCS-2, or something distinctly unhelpful, like EBCDIC. Whatever it is, it was fixed at compilation time, and is not affected by things like LOCALE settings. The source character set is the encoding the compiler believes your source code is written in. Including the octets that happen to be between <code>"</code> and <code>'</code> characters. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-type">char32_t</span> <span class="org-variable-name">s1</span>[] = <span class="org-constant">U</span><span class="org-string">"\u0073tring"</span>;
<span class="org-type">char16_t</span> <span class="org-variable-name">s2</span>[] = <span class="org-constant">U</span><span class="org-string">"\u0073tring"</span>;
<span class="org-type">char8_t</span> <span class="org-variable-name">s2</span>[] = <span class="org-constant">U</span><span class="org-string">"\u0073tring"</span>;

<span class="org-type">char32_t</span> <span class="org-variable-name">c1</span> = U<span class="org-warning">'</span>\u0073<span class="org-warning">'</span>;
<span class="org-type">char16_t</span> <span class="org-variable-name">c1</span> = u<span class="org-warning">'</span>\u0073<span class="org-warning">'</span>;
<span class="org-type">char8_t</span> <span class="org-variable-name">c1</span> = u8<span class="org-warning">'</span>\u0073<span class="org-warning">'</span>;
</pre>
</div>

 Unicode codepoint U+0073 is 's'. So all of the strings are "string", and all of the characters are 's', however the rendering of each in memory is different. For the string types, each unit in the string is 32, 16 or 8 bits respectively, and for the character literals, each is one code unit, again of 32, 16, or 8 bits. 
</div>
</div>

<div id="outline-container-org636cf76" class="outline-2">
<h2 id="org636cf76">Suprises</h2>
<div class="outline-text-2" id="text-org636cf76">
 This is due to Zach Laine, an actual expert, and sorting out what happened took several other experts, so the rest of us have little hope. 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-type">char8_t</span> <span class="org-variable-name">suprise</span>[] = <span class="org-constant">u8</span><span class="org-string">"ς"</span>;
assert(strlen(surprise) == 5);
</pre>
</div>

 This comes down to your editor and compiler having a minor disagreement about encoding. The compiler was under the impression that the encoding was cp-1252, where the editor believed it to be UTF-8. The underlying octets for ς are 0xCF 0x82, each of which is a character in cp-1252. All octets are valid characters in cp-1252. So each was converted to UTF-8, resulting in 0xC3 0x8F and 0xE2 0x80 0x9A. 

 Of course. 

 The contents of the string are still in the source character set, not in any of the Unicode forms. Unless that happens to be the source character set. 

 But at least it's well formed. 
</div>
</div>

<div id="outline-container-orgfe5e3b6" class="outline-2">
<h2 id="orgfe5e3b6">Escapes</h2>
<div class="outline-text-2" id="text-orgfe5e3b6">
 The <code>\u</code> escapes, which identify Unicode codepoints by number, will produce well formed Unicode encoding in strings, and in character literals if they fit. That is, in a <code>char32_t</code>, you can put any code point. In a <code>char16_t</code> you can put any character from the basic multilingual plane. In a <code>char8_t</code> you can put 7 bit ASCII characters. 

 Or you can use hex or octal escapes, which will be widened to code unit size and the value placed into the resultant character or string. And no current compiler checks if that makes sense, although they will warn you if, for example you try to write something like: 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-type">char16_t</span> <span class="org-variable-name">w4</span> = u<span class="org-warning">'</span>\x0001f9ff<span class="org-warning">'</span>; <span class="org-comment-delimiter">// </span><span class="org-comment">NAZAR AMULET - Unicode 11.0 (June 2018)</span>
<span class="org-type">char16_t</span> <span class="org-variable-name">sw4</span>[] = <span class="org-constant">u</span><span class="org-string">"\x0001f9ff"</span>;
</pre>
</div>

 where you're trying to put a value that won't fit into a code unit into the result. 

<pre class="example">
warning: hex escape sequence out of range
</pre>

 The <code>\xnn</code> and <code>\nnn</code> hex and octal escapes are currently a hole that lets you construct ill-formed string literals. For example 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-type">char8_t</span> <span class="org-variable-name">oops</span> = <span class="org-constant">u8</span><span class="org-string">"\xfe\xed"</span>;

</pre>
</div>

 But there are lots of ways of constructing ill-formed arrays of <code>char8_t</code> or <code>char16_t</code>. Just spell them out as arrays: 

<div class="org-src-container">
<pre class="src src-C++"><span class="org-type">char8_t</span> <span class="org-variable-name">ill</span> = {<span class="org-keyword">0x</span><span class="org-constant">fe</span>, <span class="org-keyword">0x</span><span class="org-constant">ed</span>};
</pre>
</div>

 The type system doesn't provide that <code>char8_t</code> means well formed UTF-8. All it does is tell you that the intended encoding is UTF-8. Which is a huge improvement over <code>char</code>. 

 But it does not provide any guarantee to an API taking a <code>char8_t*</code>. 
</div>
</div>

<div id="outline-container-org3e19119" class="outline-2">
<h2 id="org3e19119">\0 is an octal escape sequence</h2>
<div class="outline-text-2" id="text-org3e19119">
 You can spell it \u0000. But that's weird, since we spell it as <code>\0</code> everywhere, and that it's an octal escape is a C++ trivia question. 
</div>
</div>

<div id="outline-container-org07823cd" class="outline-2">
<h2 id="org07823cd">I want to be told if I'm forming ill-formed Unicode.</h2>
<div class="outline-text-2" id="text-org07823cd">
 Then don't use escape sequences. If you use either well encoded source code encodings or universal character names you will get well formed Unicode. 

 The primary reason for wanting ill-formed Unicode is for testing. It's a convenience. And there are straightforward workarounds. 

 But disallowing hex and octal escapes in Unicode strings makes the language less regular while preventing an error that you had to go out of your way to create, and does not actually produce more runtime safety. 
</div>
</div></body></html>