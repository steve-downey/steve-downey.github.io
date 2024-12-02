<html><body><p> What feels like actual productive work, but is only work adjacent? Fixing up the blog. </p>

<p> I managed to gradually destroy the whole thing after a decade or more of platform migrations and upgrades. This is a new and from (mostly) scratch install, into which I've imported the contents of the old one. Good backups and some hints from the excellent staff at <a href="https://www.panix.com">panix.com</a> got me back in shape. I hope. </p>

<div id="outline-container-org0967571" class="outline-2">
<h2 id="org0967571">Notes to my future self:</h2>
<div class="outline-text-2" id="text-org0967571">
<p> Start with a clean and empty database after backing up. In this case moved to the new db server at mysql3, which runs a non-antique version of mysql. </p>

<p> Shell permissions are tight, so need to chmod anything I create by hand to a+r or it can't be read. </p>

<p> Installed into root of ~/public_html so as to stop the weird rewrite rules. </p>

<p> Still have rewrite rules to handle ~sdowney vs sdowney.org. </p>

<p> Using the wp Twenty Nineteen theme because it's not a narrow column format. Created a child theme, and pasted the custom css into the child/style.css. </p>

<p> CSS is generated from M-x org-html-htmlize-generate-css in order to get my defaults in code blocks and such from org export. </p>

<p> Tweaked the .pre.src block to use better fonts. Consider fixing the trendy fonts used in the main theme. </p>

<p> Latex is on via Jetpack plugin. </p>
</div>
</div>


<div id="outline-container-org7c18127" class="outline-2">
<h2 id="org7c18127">Testing out posting to blog from emacs</h2>
<div class="outline-text-2" id="text-org7c18127">
<p> Using <a href="https://github.com/org2blog/org2blog">org2blog.</a> </p>
</div>
</div>

<div id="outline-container-orgfe73d07" class="outline-2">
<h2 id="orgfe73d07">Test LaTex</h2>
<div class="outline-text-2" id="text-orgfe73d07">
<ul class="org-ul">
<li>The word LaTeX

<ul class="org-ul">
<li>$latex \LaTeX$</li>
</ul></li>
<li>Inline

<ul class="org-ul">
<li>$latex \sum_{i=0}^n i^2 = \frac{(n^2+n)(2n+1)}{6}$</li>
</ul></li>
<li>Equation

<ul class="org-ul">
<li><p style="text-align:center"> $latex \sum_{i=0}^n i^2 = \frac{(n^2+n)(2n+1)}{6}$ </p></li>
</ul></li>
</ul>
</div>
</div>

<div id="outline-container-org23fe210" class="outline-2">
<h2 id="org23fe210">Src blocks</h2>
<div class="outline-text-2" id="text-org23fe210">
</div>
<div id="outline-container-orgda28895" class="outline-3">
<h3 id="orgda28895">C++</h3>
<div class="outline-text-3" id="text-orgda28895">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-C++" id="nil"><span class="org-keyword">class</span> <span class="org-type">windows_1252_convert_view</span>
    : <span class="org-keyword">public</span> <span class="org-constant">rng</span>::<span class="org-type">view_facade</span>&lt;<span class="org-type">windows_1252_convert_view</span>&lt;Range&gt;, <span class="org-constant">rng</span>::unknown&gt;;

</pre>
</div>
</div>
</div>

<div id="outline-container-org262b086" class="outline-3">
<h3 id="org262b086">Python</h3>
<div class="outline-text-3" id="text-org262b086">
<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-python" id="nil"><span class="org-keyword">print</span> (<span class="org-string">'Hello, world!'</span>)
</pre>
</div>
</div>
</div>
</div>
</body></html>