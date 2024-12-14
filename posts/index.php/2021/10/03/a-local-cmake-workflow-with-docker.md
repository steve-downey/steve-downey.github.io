<html><body><p> l#+BLOG: sdowney </p>

<p> An outline of a template that provides an automated workflow driving a CMake project in a docker container. </p>

<p> This post must be read in concert with <a href="https://github.com/steve-downey/scratch">https://github.com/steve-downey/scratch</a> of which it is part. </p>

<div id="outline-container-orge73d9dc" class="outline-2">
<h2 id="orge73d9dc">Routine process should be automated</h2>
<div class="outline-text-2" id="text-orge73d9dc">
<p> Building a project that uses cmake runs through a predictable lifecycle that you should be able to pick up where you left off without remembering, and for which you should be able to state your goal, not the step you are on. <code>make</code> is designed for this, and can drive the processs. </p>
</div>

<!-- TEASER_END -->

<div id="outline-container-org7268417" class="outline-3">
<h3 id="org7268417">The workflow</h3>
<div class="outline-text-3" id="text-org7268417">
<ul class="org-ul">
<li>Update any submodules</li>
<li>Create a build area specific to the toolchain</li>
<li>Run cmake with that toolchain in the build area</li>
<li>Run the build in the build area</li>
<li>Run tests, either dependent or independent of rebuild</li>
<li>Run the intall</li>
<li>(optionally) Clean the build</li>
<li>(optionally) Clean the configuration</li>
</ul>

<p> All of the steps have recognizable filesystem artifacts, need to be run in order, and if there are any failures, the process should stop. </p>

<p> So we want a <code>make</code> system on top of our meta-make build system. </p>

<p> The one thing this system does, that plain cmake doesn't automate, is making sure that any changes are incorporated into a build before tests are run. CMake splits these, in order to provide the option of running tests without a recompile. I think that is a mistake to automate, but I do provide a target that just runs ctest. </p>

<p> My normal target is <code>test</code> </p>

<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-bash" id="nil">make test
</pre>
</div>

<p> This will run through all of the steps, but only those, necessary to compile and run tests. The core commands for the build driver are </p>

<dl class="org-dl">
<dt>compile</dt><dd>Compile all out of date source</dd>
<dt>install</dt><dd>Install into the INSTALL_PREFIX</dd>
<dt>ctest</dt><dd>Run the currently build test suite</dd>
<dt>test</dt><dd>Build and run the test suite</dd>
<dt>cmake</dt><dd>run cmake again in the build area</dd>
<dt>clean</dt><dd>Clean the build area</dd>
<dt>realclean</dt><dd>Delete the build area</dd>
</dl>

<p> There are several makefile variables controlling the details of what toolchain is used and where things are located. By default the build and install are completely out of the source tree, in ../cmake.bld and ../install respectively, with the build directory further refined by the project name, which defaults to the current directory name, and the toolchain if that is overridden. </p>

<p> The build is a Ninja Multi-config build, supporting RelWithDebInfo, Debug, Tsan, and Asan, with the particular flavor being selectable by the CONFIG variable. See <code>targets.mk</code> for the variables and details, such as they are. </p>

<p> Because other tools, unfortunately, rely on a <code>compile_commands.json</code> this system symlinks one from the build area when reconfiguration is done. </p>

<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-makefile" id="nil"><span style="color: #f78fe7;">default</span>: compile

<span style="color: #f78fe7;">$(</span><span style="color: #f78fe7;">_build_path</span><span style="color: #f78fe7;">)</span>:
    mkdir -p $(<span style="color: #79a8ff;">_build_path</span>)

<span style="color: #f78fe7;">$(</span><span style="color: #f78fe7;">_build_path</span><span style="color: #f78fe7;">)/CMakeCache.txt</span>: | $(<span style="color: #79a8ff;">_build_path</span>) .gitmodules
    cd $(<span style="color: #79a8ff;">_build_path</span>) &amp;&amp; $(<span style="color: #79a8ff;">run_cmake</span>)
    <span style="color: #b6a0ff; font-weight: bold;">-</span>rm compile_commands.json
    ln -s $(<span style="color: #79a8ff;">_build_path</span>)/compile_commands.json

<span style="color: #f78fe7;">compile</span>: $(<span style="color: #79a8ff;">_build_path</span>)/CMakeCache.txt <span style="color: #a8a8a8; font-style: italic;">## </span><span style="color: #a8a8a8; font-style: italic;">Compile the project</span>
    cmake --build $(<span style="color: #79a8ff;">_build_path</span>)  --config $(<span style="color: #79a8ff;">CONFIG</span>) --target all -- -k 0

<span style="color: #f78fe7;">install</span>: $(<span style="color: #79a8ff;">_build_path</span>)/CMakeCache.txt <span style="color: #a8a8a8; font-style: italic;">## </span><span style="color: #a8a8a8; font-style: italic;">Install the project</span>
    <span style="color: #79a8ff;">DESTDIR</span>=$(<span style="color: #79a8ff;">abspath</span> $(<span style="color: #79a8ff;">DEST</span>)) ninja -C $(<span style="color: #79a8ff;">_build_path</span>) -k 0  install

<span style="color: #f78fe7;">ctest</span>: $(<span style="color: #79a8ff;">_build_path</span>)/CMakeCache.txt <span style="color: #a8a8a8; font-style: italic;">## </span><span style="color: #a8a8a8; font-style: italic;">Run CTest on current build</span>
    cd $(<span style="color: #79a8ff;">_build_path</span>) &amp;&amp; ctest

<span style="color: #f78fe7;">ctest_</span> : compile
    cd $(<span style="color: #79a8ff;">_build_path</span>) &amp;&amp; ctest

<span style="color: #f78fe7;">test</span>: ctest_ <span style="color: #a8a8a8; font-style: italic;">## </span><span style="color: #a8a8a8; font-style: italic;">Rebuild and run tests</span>

<span style="color: #f78fe7;">cmake</span>: |  $(<span style="color: #79a8ff;">_build_path</span>)
    cd $(<span style="color: #79a8ff;">_build_path</span>) &amp;&amp; ${<span style="color: #79a8ff;">run_cmake</span>}

<span style="color: #f78fe7;">clean</span>: $(<span style="color: #79a8ff;">_build_path</span>)/CMakeCache.txt <span style="color: #a8a8a8; font-style: italic;">## </span><span style="color: #a8a8a8; font-style: italic;">Clean the build artifacts</span>
    cmake --build $(<span style="color: #79a8ff;">_build_path</span>)  --config $(<span style="color: #79a8ff;">CONFIG</span>) --target clean

<span style="color: #f78fe7;">realclean</span>: <span style="color: #a8a8a8; font-style: italic;">## </span><span style="color: #a8a8a8; font-style: italic;">Delete the build directory</span>
    rm -rf $(<span style="color: #79a8ff;">_build_path</span>)

</pre>
</div>
</div>
</div>
</div>

<div id="outline-container-orgd013026" class="outline-2">
<h2 id="orgd013026">To Docker or Not to Docker</h2>
<div class="outline-text-2" id="text-orgd013026">
<p> The reason for the separate <code>targets.mk</code> file is to simplify running the build purely locally in the host, or in a docker containter. The structure of the build is the same either way. In fact, before I dockerized this template project, there was a single makefile which was mostly the current contents of targets.mk. However, splitting does make the template easier, as project specific targets can naturally be placed in <code>targets</code>. </p>

<p> Tha outer <code>Makefile</code> is responsible for checking if Docker has been requested and for making sure the container is ready. The makefile has a handful of targets of its own, but otherwide defers everything to <code>targets.mk</code>. </p>

<dl class="org-dl">
<dt>use-docker</dt><dd>set a flag file, USE_DOCKER_FILE, indicating to forward to docker</dd>
<dt>remove-docker</dt><dd>remove the flag file</dd>
<dt>docker-rebuild</dt><dd>rebuild the docker image</dd>
<dt>docker-clean</dt><dd>Clean volumes and rebuild image</dd>
<dt>docker-shell</dt><dd>Shell in the docker container</dd>
</dl>

<p> The docker container is build via <code>docker-compose</code> with the configuration <code>docker-compose.yml</code>. It uses the <code>Dockerfile</code> which uses <code>steve-downey/cxx-dev:latest</code> as the base image, and mounts the current source directory as a bind mount and a volume for ../cmake.bld. </p>

<p> I don't publish steve-downey/cxx-dev:latest and you should build your own BASE. I do provide the recipe for the base image as a subprojct in <code>docker-inf/docker-cxx-dev</code>. </p>

<p> You running unknown things as root scares me. </p>

<p> The image is assumed to provide current version of gcc and clang as c++ or gcc, or clang++ respectively. </p>

<p> The intent of the image is to provide compilation services and operate as an lsp server using clangd. Mine doesn't provide X, editors, IDEs, etc. The intent isn't a VM, it's a controlled compiler installation. </p>

<p> Compiler installations bleed in to each other. Mutliple compilers installed onto the same base system can't be assumed to behave the same way as a compier installed as the only compiler. The ABI libraries vary, as do the standard libaries. Deployment just makes this all an even worse problem. As a Rule I use for production Red Hat's DTS compilers and only deploy on later OSs than I've built on, with strict controls on OS deployments and statically linking everything I possibly can. </p>

<p> The base image I am using here, steve-downey/cxx-dev, works for me, and is avaiable at <a href="https://github.com/steve-downey/docker-cxx-dev">https://github.com/steve-downey/docker-cxx-dev</a> as a definition as well. </p>

<p> It is based on current Ubuntu (jammy), installs gcc-12 from the ubuntu repositories, adds the LLVM repos and installs clang-14 from them based on how <a href="https://apt.llvm.org/llvm.sh">https://apt.llvm.org/llvm.sh</a> does. </p>

<p> It then installs the current release of cmake from <a href="https://apt.kitware.com/ubuntu/">https://apt.kitware.com/ubuntu/</a> because using out of date build tools is a bad idea all around. </p>

<p> I also configure it to run as USER 1000, because running everything as root is strictly worse, and 1000 is a 99.99 percent solution/ </p>

<div class="org-src-container">
<label class="org-src-name"><em></em></label>
<pre class="src src-makefile" id="nil"><span style="color: #f78fe7;">.update-submodules</span>:
    git submodule update --init --recursive
    touch .update-submodules

<span style="color: #f78fe7;">.gitmodules</span>: .update-submodules

<span style="color: #f78fe7;">.PHONY</span>: use-docker
<span style="color: #f78fe7;">use-docker</span>: <span style="color: #a8a8a8; font-style: italic;">## </span><span style="color: #a8a8a8; font-style: italic;">Create docker switch file so that subsequent `make` commands run inside docker container.</span>
    touch $(<span style="color: #79a8ff;">USE_DOCKER_FILE</span>)

<span style="color: #f78fe7;">.PHONY</span>: remove-docker
<span style="color: #f78fe7;">remove-docker</span>: <span style="color: #a8a8a8; font-style: italic;">## </span><span style="color: #a8a8a8; font-style: italic;">Remove docker switch file so that subsequent `make` commands run locally.</span>
    $(<span style="color: #79a8ff;">RM</span>) $(<span style="color: #79a8ff;">USE_DOCKER_FILE</span>)

<span style="color: #f78fe7;">.PHONY</span>: docker-rebuild
<span style="color: #f78fe7;">docker-rebuild</span>: <span style="color: #a8a8a8; font-style: italic;">## </span><span style="color: #a8a8a8; font-style: italic;">Rebuilds the docker file using the latest base image.</span>
    docker-compose build

<span style="color: #f78fe7;">.PHONY</span>: docker-clean
<span style="color: #f78fe7;">docker-clean</span>: <span style="color: #a8a8a8; font-style: italic;">## </span><span style="color: #a8a8a8; font-style: italic;">Clean up the docker volumes and rebuilds the image from scratch.</span>
    docker-compose down -v
    docker-compose build

<span style="color: #f78fe7;">.PHONY</span>: docker-shell
<span style="color: #f78fe7;">docker-shell</span>: <span style="color: #a8a8a8; font-style: italic;">## </span><span style="color: #a8a8a8; font-style: italic;">Shell in container</span>
    docker-compose run --rm dev

</pre>
</div>
</div>
</div>

<div id="outline-container-orgcca1c34" class="outline-2">
<h2 id="orgcca1c34">Work In Progress</h2>
<div class="outline-text-2" id="text-orgcca1c34">
<p> I expect I will make many changes to all of this. I'm providing no facilities for you to pick them up. Sorry. </p>

<p> Please consider this as an exhibition of techniques rather than as a solution. </p>
</div>
</div>
</body></html>
