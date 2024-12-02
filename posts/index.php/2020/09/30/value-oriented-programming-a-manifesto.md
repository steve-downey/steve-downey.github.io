<html><body><div id="outline-container-org5372f25" class="outline-2">
<h2 id="org5372f25">Object Oriented Programming</h2>
<div class="outline-text-2" id="text-org5372f25">
 The primitive entities are objects which have certain properties 

<ul class="org-ul">
<li>Objects have Identity</li>
<li>Objects have State</li>
<li>Objects have Behavior</li>
</ul>
</div>
</div>

<div id="outline-container-orgae5a05b" class="outline-2">
<h2 id="orgae5a05b">Values are not Objects</h2>
<div class="outline-text-2" id="text-orgae5a05b">
 The primitive entities are values which have none of the properties of Objects 

<ul class="org-ul">
<li>Values have no identity</li>
<li>Values have no State</li>
<li>Values have no Behavior</li>
</ul>
</div>
</div>

<div id="outline-container-org559c00a" class="outline-2">
<h2 id="org559c00a">A positive definition of VOP</h2>
<div class="outline-text-2" id="text-org559c00a">
<ul class="org-ul">
<li>Values are Equivalent</li>
<li>Values are Immutable</li>
<li>Values are Side-effect Free</li>
</ul>
</div>
</div>

<div id="outline-container-orgc5cb65c" class="outline-2">
<h2 id="orgc5cb65c">Values are Equivalent</h2>
<div class="outline-text-2" id="text-orgc5cb65c">
 One entity with a value will give the same results as a different entity with the same value. All 'fives' are the same. This allows equational reasoning. If `a` and `b` have the same value, `f(a)` and `f(b)` have the same value. 
</div>
</div>

<div id="outline-container-org24467e2" class="outline-2">
<h2 id="org24467e2">Values are Immutable</h2>
<div class="outline-text-2" id="text-org24467e2">
 'five' never becomes 'six'. Values do not change. 
</div>
</div>

<div id="outline-container-org5833d94" class="outline-2">
<h2 id="org5833d94">Values are Side-effect free</h2>
<div class="outline-text-2" id="text-org5833d94">
 No operation on a value has an effect on other values. Temporal changes are explicit. 
</div>
</div>

<div id="outline-container-org44be465" class="outline-2">
<h2 id="org44be465">Value Oriented Programming does not deny Objects</h2>
<div class="outline-text-2" id="text-org44be465">
<ul class="org-ul">
<li>There are things with identity</li>
<li>There are things that vary over time</li>
<li>There are things that affect the state of other things</li>
</ul>
</div>
</div>

<div id="outline-container-orge78ff25" class="outline-2">
<h2 id="orge78ff25">Values are are a better basis</h2>
<div class="outline-text-2" id="text-orge78ff25">
 We can, and do, build objects out of values, but objects in the OO sense are impossible to reason about. 

 Values are. 
</div>
</div></body></html>