<html><body><div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#orgheadline1">1. Why notes</a></li>
<li><a href="#orgheadline2">2. Getting Ready</a></li>
<li><a href="#orgheadline3">3. Configure and build with magic option</a></li>
</ul>
</div>
</div>

<div id="outline-container-orgheadline1" class="outline-2">
<h2 id="orgheadline1"><span class="section-number-2">1</span> Why notes</h2>
<div class="outline-text-2" id="text-1">
 Making notes so I don't forget, although the key problem is fixed upstream. 

 Ubuntu 16.10 (Yakkety Yak) has made a critical change to the system compiler, and everything is by default built with position independent executable support (PIE), in order to get better support for address space layout randomization. Here are the security notes for <a href="https://wiki.ubuntu.com/SecurityTeam/PIE">PIE</a>. Emacs does not dump successfully with this. The compiler option -no-pie needs to be added into CLFAGS. 

 The option also means that static libraries you've built before will probably need to be rebuilt. See the link above for typical errors. 
</div>
</div>

<div id="outline-container-orgheadline2" class="outline-2">
<h2 id="orgheadline2"><span class="section-number-2">2</span> Getting Ready</h2>
<div class="outline-text-2" id="text-2">
 First get dpkg-dev, g++, gcc, libc, make: 

<div class="org-src-container">

<pre class="src src-bash">sudo apt-get install build-essentials
</pre>
</div>

 Then get the full set of build dependencies for last emacs, emacs24: 

<div class="org-src-container">

<pre class="src src-bash">sudo apt-get build-dep emacs24
</pre>
</div>

 Decide if you want to build just this version, or track emacs. I track from git, because. So I have a directory for emacs where I have master, emacs25, and build directories. I try to avoid building in src dirs. It makes it easier to try out different options without polluting the src. 

<div class="org-src-container">

<pre class="src src-bash">mkdir -p ~/bld/emacs
<span class="org-builtin">cd</span> ~/bld/emacs
git clone git://git.savannah.gnu.org/emacs.git
<span class="org-builtin">cd</span> emacs.git
git worktree add ../emacs-25.1 emacs-25.1
<span class="org-builtin">cd</span> ..
mkdir bld-25.1
</pre>
</div>
</div>
</div>

<div id="outline-container-orgheadline3" class="outline-2">
<h2 id="orgheadline3"><span class="section-number-2">3</span> Configure and build with magic option</h2>
<div class="outline-text-2" id="text-3">
 Now configure in the build directory: 

<div class="org-src-container">

<pre class="src src-bash"><span class="org-builtin">cd</span> bld-25.1
../emacs-25.1/configure <span class="org-sh-escaped-newline">\</span>
  --prefix=~/install/emacs-25.1 <span class="org-sh-escaped-newline">\</span>
  --with-x-toolkit=gtk3 <span class="org-sh-escaped-newline">\</span>
  --with-xwidgets <span class="org-sh-escaped-newline">\</span>
  <span class="org-variable-name">CFLAGS</span>=-no-pie
</pre>
</div>

 I built with xwidget support to play with the embedded webkit widget. It's not really useable as a browser, but has uses for rendering. I also install into a local program directory, under my homedir. 

 Build and install: 

<div class="org-src-container">

<pre class="src src-bash">make
make install
</pre>
</div>

 I have a bin directory early in $PATH so that I can select versions of local software ahead of system software. 

<div class="org-src-container">

<pre class="src src-bash"><span class="org-builtin">cd</span> ~/bin
ln -s ~/install/emacs-25.1/bin/emacs
ln -s ~/install/emacs-25.1/bin/emacsclient
</pre>
</div>

 Now you should have a working emacs 25.1 available. 
</div>
</div></body></html>