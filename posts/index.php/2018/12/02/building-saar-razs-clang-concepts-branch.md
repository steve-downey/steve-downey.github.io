<html><body><div id="outline-container-org1603cfb" class="outline-2">
<h2 id="org1603cfb">A Recipe for building Saar Raz's clang concepts branch</h2>
<div class="outline-text-2" id="text-org1603cfb">
 Saar Raz has been working on a Concepts implementation, available at <a href="https://github.com/saarraz/clang-concepts">https://github.com/saarraz/clang-concepts</a> It's not much harder to build it than clang usually is, it's just a matter of getting things checked out into the right places before configuring the build. Just like LLVM and clang normally. 

 In order to double check how, I peeked at the shell script used by the compiler explorer image to build the clang-concepts compiler: <a href="https://github.com/mattgodbolt/compiler-explorer-image/blob/master/clang/build/build-concepts.sh">https://github.com/mattgodbolt/compiler-explorer-image/blob/master/clang/build/build-concepts.sh</a> 

 The really important bit is getting exactly the right commit from LLVM, 893a41656b527af1b00a1f9e5c8fcecfff62e4b6. 

 To get a working directory something like: Starting from where you want your working tree and build tree, e.g ~/bld/llvm-concepts 

<div class="org-src-container">
<pre class="src src-shell">git clone https://github.com/llvm-mirror/llvm.git

<span class="org-builtin">pushd</span> llvm
git reset --hard 893a41656b527af1b00a1f9e5c8fcecfff62e4b6
<span class="org-builtin">popd</span>

<span class="org-builtin">pushd</span> llvm/tools
git clone https://github.com/saarraz/clang-concepts.git clang
<span class="org-builtin">popd</span>

<span class="org-builtin">pushd</span> llvm/projects
git clone https://github.com/llvm-mirror/libcxx.git
git clone https://github.com/llvm-mirror/libcxxabi.git
<span class="org-comment-delimiter"># </span><span class="org-comment">The sanitizers: this is optional but you want them</span>
git clone https://github.com/llvm-mirror/compiler-rt.git
<span class="org-builtin">popd</span>

</pre>
</div>

 Then to build and install 

<div class="org-src-container">
<pre class="src src-shell">mkdir build &amp;&amp; <span class="org-builtin">cd</span> build

cmake <span class="org-sh-escaped-newline">\</span>
    -DCMAKE_INSTALL_PREFIX=~/install/llvm-concepts/ <span class="org-sh-escaped-newline">\</span>
    -DLLVM_ENABLE_LIBCXX=yes  <span class="org-sh-escaped-newline">\</span>
    -DCMAKE_BUILD_TYPE=Release  <span class="org-sh-escaped-newline">\</span>
    -DLLVM_ENABLE_ASSERTIONS=yes <span class="org-sh-escaped-newline">\</span>
    -DLLVM_PARALLEL_LINK_JOBS=1 <span class="org-sh-escaped-newline">\</span>
    -G Ninja  <span class="org-sh-escaped-newline">\</span>
    ../llvm/

ninja

ninja check

ninja install
</pre>
</div>

 Note that I install into a separate prefix, keeping it isolated from everything else. The compiler can be invoked as ~/install/llvm-concepts/bin/clang++. There's no particular reason to put the compiler on your PATH. 
</div>
</div></body></html>