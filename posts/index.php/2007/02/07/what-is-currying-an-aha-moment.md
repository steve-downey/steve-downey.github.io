<html><body><p>Since it really is an aha! moment, the best I can do is tell you what led me to it, and hope that helps.<br><br>There is a difference between partial application and currying that most experts ignore, because they already understand, but they lie in wait ready to tell you that you have it all wrong.<br><br>And you won't understand because the concepts are &gt;thatI'll start with Haskell syntax for the type of a function that takes two integers and returns one.</p><p>Integer -&gt; Integer -&gt; Integer</p>
<p>in C that would be<br></p>
<p> int (*T)(int , int )<br><br></p>
<p>Now. what about a function that takes an int and returns a function<br>that takes an int and returns an int?</p>
<p>(using cdecl syntax)<br>declare T as  function (int) returning pointer to function (int) returning int<br></p>
<p>int (*T(int ))(int )<br></p>
<p>or, in Haskell<br>Integer -&gt; Integer -&gt; Integer</p>
<p>Wait.<br></p>
<p>Shouldn't those have different types in Haskell?  They look really much more different in C !<br></p>
<p>I can't tell the difference in Haskell between a function that takes two ints and returns an int, and a function that takes one int and returns a function that takes one int and returns an int.</p>
<p>Yes.</p>
<p>Exactly.</p>
<p>AHA!</p>
<p>a -&gt; b -&gt; c<br><br>a function that takes an a and returns a function that maps b to c, or a function that takes an a and a b and returns a c. They are entirely equivalent.</p>
<br><p><br></p>
<p><br></p></body></html>