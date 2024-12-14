<html><body><p> Some thoughts on the <a href="https://wg21.link/p2300">std::execution</a> proposal and my understanding of the underlying theory. </p>

<div id="outline-container-org6280fb4" class="outline-2">
<h2 id="org6280fb4">What's proposed</h2>
<div class="outline-text-2" id="text-org6280fb4">
<p> From the paper's <a href="https://brycelelbach.github.io/wg21_p2300_std_execution/std_execution.html#intro">Introduction</a> </p>

<blockquote>
<p> This paper proposes a self-contained design for a Standard C++ framework for managing asynchronous execution on generic execution contexts. It is based on the ideas in [P0443R14] and its companion papers. </p>
</blockquote>

<p> Which doesn't tell you much. </p>

<p> It proposes a framework where the principle abstractions are Senders, Receivers, and Schedulers. </p>

<dl class="org-dl">
<dt>Sender</dt><dd>A composable unit of work.</dd>
<dt>Receiver</dt><dd>Delimits work, handling completion, exceptions, or cancellation.</dd>
<dt>Schedulers</dt><dd>Arranges for the context work is done in.</dd>
</dl>

<!-- TEASER_END -->

<p> The primary user facing concept is the sender. Values and functions can be lifted directly into senders. Senders can be stacked together, with a sender passing its value on to another function. Or stacking exception or cancellation handling the same way. </p>

<p> Receivers handle the three ways a sender can complete, by returning a value, throwing an exception, or being canceled. As described, receivers are most likely to be implemented within particular algorithms that combine senders, such as <a href="https://brycelelbach.github.io/wg21_p2300_std_execution/std_execution.html#example-then">`then`</a> or <a href="https://brycelelbach.github.io/wg21_p2300_std_execution/std_execution.html#example-retry">`retry`</a>. </p>

<p> Schedulers provide access to execution contexts. Like inline, single thread, a thread pool, a GPU, and so on, would all have schedulers that provide for putting a sender into the context they manage. </p>

<p> There's a fairly large API surface being proposed. But there's an underlying theory about this, governing what algorithms need to be there and how the pieces fit together. </p>
</div>
</div>

<div id="outline-container-org8699f4f" class="outline-2">
<h2 id="org8699f4f">Continuation Passing Style and the Continuation Monad</h2>
<div class="outline-text-2" id="text-org8699f4f">
<p> Continuation passing style is a transformation from a normal function and a call stack to a direction to send the result to the "continuation" without returning. This means the functions context can be cleaned up. Delimited continuations are a slight variation, where instead of an unbounded "rest of the program", the continuation has an end point and a value. It's essentially a function, and can be handled as such. There is a purely mechanical method for converting all of the lambda calculus transforms into CPS form, and this can be profitable for compilers based on lambda, or related logics, like system F. </p>

<p> The mechanical transformation also means that all the control structures, like loops, gotos, coroutines, exceptions, have CPS equivalents. </p>

<p> CPS is tedious, though. Having to explicitly add a continuation to everything is complicated. </p>

<p> However, there's also a typeclass, or concept, that allows you to convert regular functions into continuation passing style, automatically. It's then rather straightforward to involve concerns like where work is being run for something that wraps up the entire work. Even being able to switch back and forth between contexts. That's the continuation monad. </p>

<p> And unfortunately monads became an organizing principle in programming language theory one or two decades after most CS programs were standardized. So it's all complicated and involves things we weren't trained on. Fitting it into C++ has been an ongoing challenge, and until we had generic lambda was neither reasonbly concise nor idiomatic. </p>

<p> See, however, the new monadic interface additions for std::optional for why you want this. Or Ranges, which are solidly based in the 'list' or non-deterministic monad. </p>
</div>
</div>

<div id="outline-container-org32f30b7" class="outline-2">
<h2 id="org32f30b7">We have a poor relationship with Theory</h2>
<div class="outline-text-2" id="text-org32f30b7">
<p> There is no satisfactory PL theory for object oriented programming. There's lots of work, but it mostly ends up describing something that OO programmers don't think is quite the same as what they do. Even the ones who spend a lot of time doing theory. </p>

<p> Yet OO was, and is, a successful discipline. Working with identity, behavior, and state has produced remarkable results. Temporal calculi, not so much. </p>

<p> For a long while, we as a discipline thought that multi-threading was similar. There was poor theory, but we had hardware, and libraries that let us use that hardware to do concurrent work correctly. </p>

<p> That turned out not to be the case. </p>

<p> Concurrency can't be just a library, unfortunately. Concurrency models that hardware vendors will commit to won't promise not to violate causality. That makes producing a programming model programmers can use frighteningly difficult. </p>

<p> Which is why having a sound theory for std::execution is a good thing, even if the theory is unfamiliar. </p>

<p> But as a group, we learned the wrong lessons from the 80s and thought it was a researcher's job to take the successes of practitioners and put a sound basis to them. Ignoring that it is a feedback loop. In the 60s and 70s, those researchers were also the practitioners. It's not wrong to get out ahead of theory, but we do need to check back. </p>
</div>
</div>

<div id="outline-container-org4d78be1" class="outline-2">
<h2 id="org4d78be1">p2300 std::execution</h2>
<div class="outline-text-2" id="text-org4d78be1">
<p> Senders, via the Decorator pattern, lift ordinary functions into the continuation passing style. People writing functions only need to be concerned with handling the arguments they are passed, without concern for execution context or continuations. Functions used by senders act like, and are, normal functions. </p>

<p> Senders manage a bundle of channels, representing normal return of a value, throwing an exception, or an error channel to handle cancellation, or other errors not within the bound of ordinary functions. All of these channels can be composed taking the result to another function, or monadically with a function returning a sender, where that function can determine the kind of sender based on the values of the arguments. The channels can be combined or rerouted, connecting one to another, or presenting a variant containing either result, exception, and/or error to the continuation function. </p>

<p> Although senders form a logical graph of units of work, the physical type model is containment, much like expression templates. The result of binding senders together via an algorithm is a sender that contains the bound together senders. There are no nodes or allocations inherent to the model, just function calls. </p>

<p> C++ coroutines fit into this model. C++ coroutines are, from the outside, functions with rules about the interaction patterns with the returned value. Making a coroutine owning type a sender, and a sender co_awaitable, is possible and has been demonstrated. </p>

<p> std::execution takes the Continuation Monad and fits it to C++ control flow, return or exception, and adds cancellation, which incidentally allows a channel for failures from execution contexts. The thread pool can potentially signal failure via the error channel, without aliasing problems from application function code. However, for advanced users, these can be folded back into the normal function arguments and handled by application code. Policy decisions are not burned into the ROM of std::execution, but there are defaults that can be provided by application infrastructure authors. </p>

<p> Those infrastructure authors do not have to be std library vendors. The protocols, rendered as concepts, are available to normal users. </p>
</div>
</div>

<div id="outline-container-org2dd1cec" class="outline-2">
<h2 id="org2dd1cec">Network TS</h2>
<div class="outline-text-2" id="text-org2dd1cec">
<dl class="org-dl">
<dt><span class="underline">Eppur si muove</span></dt><dd>And yet it moves</dd>
</dl>

<p> I do not believe ASIO's model is a firm foundation for all async programming. However, it is well proven, and exists. It works. </p>
</div>
</div>


<div id="outline-container-org5f111d1" class="outline-2">
<h2 id="org5f111d1">And …</h2>
<div class="outline-text-2" id="text-org5f111d1">
<p> I have confidence that a networking library can and will be built using p2300. I am less confident that can be done in the timeframe for C++26. I do not believe for a moment we could have one for C++23, even with an existence proof a networking library appearing now. It's simply too late to review and agree. We're in the same place as coroutines. We can have the machinery, but without all of the application user facing infrastructure we should have. </p>

<p> I think this was the right choice with coroutines, and I think providing the machinery for general continuation based async in the standard library so that we can build on top of it is the right choice. The authors have committed to making sure all the facilities are available for programmers, in particular the pipe syntax (an issue for ranges) as well as providing bases or adapters for coroutine promises and typed senders. We can experiment and add existing practice as we go. </p>
</div>
</div>


<div id="outline-container-orgb7e8b70" class="outline-2">
<h2 id="orgb7e8b70">Disclaimer</h2>
<div class="outline-text-2" id="text-orgb7e8b70">
<p> This is <b>all</b> my personal opinion, based on my own understanding. I've been in the meetings, I've been in discussions, asked questions. But if I'm wrong about some aspect of the proposal, that's on me. Certainly not a formal opinion of Bloomberg, where I work. While we do lots of network services, and async programming, this isn't what our tech looks like at all. Getting from here to there is an open question, but it would be for ASIO, too. </p>

<p> At least it isn't CORBA. </p>

<p> <a href="https://github.com/steve-downey/what-comes-to-mind/blob/master/send-rec.org">Source For Blog</a> </p>
</div>
</div>
</body></html>
