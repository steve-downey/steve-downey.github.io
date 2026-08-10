# Brno 2026 Trip Report: Library Evolution, Safety, and SG16

## Summary

The June 2026 ISO C++ meeting in Brno was a strong week for the standard library. Over a dozen proposals advanced into the C++ working paper for C++29, alongside critical C++26 Defect Reports. The headline — highlighted in [Herb Sutter's trip report](https://herbsutter.com/2026/06/13/brno-trip-report/) — is the formal adoption of P3091 ("Better Lookups") for `std::map`, `std::unordered_map`, and `std::flat_map`. P3091's `lookup` returns `optional<T&>`, the type I delivered in P2988. That is the enabling foundation. P2988 finishing too late was the sole reason this feature missed C++26.

Study Group 23 (Safety and Security) approved a structural roadmap for safety profiles but left deep technical concerns unresolved. The framework risks becoming unimplementable without sustained expert intervention — Joshua Berne (BDE team, leading our Contracts efforts) has expressed similar and overlapping concerns to me independently. My continued active role in SG23 is directly aligned with the organization's focus on C++ safety.

As SG16 Chair, I conducted off-cycle coordination on the Units library, identifier modernization, and formatting string alignment with EWG — clearing upcoming LEWG scheduling bottlenecks.

---

## Hallway Track

These came from in-person conversations during the week.

### glibc Deployment Strategy

Confirmed over lunch with glibc maintainers: the `--enable-kernel=` compile-time setting controls the minimum kernel fallback, but glibc dynamically uses newer kernel interfaces it knows about at compile time. The current minimum is kernel 3.2, and there are no plans to raise it.

GLIBCXX (all the GCC C++ runtime) has no kernel interface use at all — it uses glibc-supplied interfaces exclusively, by policy and design.

The practical consequence worth investigating: we could build against glibc 2.39 (RHEL10), mark RHEL7 as the minimum kernel, and deploy that single build everywhere without shipping multiple glibc versions. The only caveat is static-vs-dynamic linking for Python modules — if we set the GLIBCXX fill-in version too high when building Python modules, we could hit issues with a system Python interpreter using a different ld interpreter. But for our own libraries this is straightforward.

### Binary Module Interfaces (BMI) and Module Caching

Treat BMI like any other direct compiler output and let the cache layer deal with it. Their fragility is exactly equivalent to the correctness of object files, so the same reuse strategy applies.

The corollary: pre-compiled shared artifacts (modules, PCH) are only a throughput win when the number of consumers exceeds the available parallelism. You need more users of an artifact than the number of parallel jobs for pre-compilation to pay for itself.

### Source-to-Source Build Migration

Heard several war stories from organizations attempting source-to-source builds at smaller scale than ours, not built from the ground up to make that the default. Nothing surprising — we've discussed most of these issues — but problems were more frequent than they'd expected. A few surprises: needing response files to work because of thousands of `-I` rules, and assorted filesystem path length and normalization issues. Google has invested heavily in clang to solve these; GCC has less support.

The real takeaway: source-to-source can be a big win, but once you've done it you have to lock it in hard or someone will break it. The secondary benefit is that it becomes much easier to provide and share dev tools because everything is a known quantity.

Separately, I talked with people about the next step — package-to-source — and the consistent message is that however hard you think it is, it's harder. It requires more control over the dependency graph than we currently have. CMake-to-CMake composition does not scale well for this use case right now.

---

## My Direct Contributions

### P2988 → P3091: Foundation Shipped

P3091R6 ("Better Lookups") is in the working paper. Its `lookup` function returns `optional<T&>` — the type I specified in P2988. The entire API design depends on `optional<T&>` existing as a vocabulary type. That infrastructure is now paying off.

Why `optional<T&>` matters here — before and after:

**P3091 — map lookup:** The old way requires iterator ceremony and risks double-lookup:

```cpp
// Before: check-then-access, or iterator dance
auto it = m.find(key);
if (it != m.end()) use(it->second);

// After: one call, direct reference, no copy
if (auto val = m.lookup(key)) use(*val);
```

The returned `optional<T&>` is a direct reference into the map — no copy, no iterator, no second lookup.

**P3981R2 — inplace_vector:** A fixed-capacity vector that can fail to insert. The natural return is "a reference to what was inserted, or nothing":

```cpp
// try_push_back returns optional<T&> — either a reference to the
// newly inserted element, or empty if capacity is exhausted
if (auto ref = vec.try_push_back(value)) { /* use *ref */ }
```

Returning a pointer would work mechanically, but `optional<T&>` makes the "might not be there" semantics explicit in the type system.

**P2927 — exception_ptr_cast (shipped C++26):** Inspecting a stored exception without rethrowing:

```cpp
// Before: rethrow and catch to inspect — expensive and awkward
// After: direct non-throwing inspection
if (auto ex = std::exception_ptr_cast<std::system_error>(eptr)) {
    log(ex->code());
}
```

Returns `optional<E const&>` — either a reference to the stored exception or empty. The alternative was a raw pointer, which loses the vocabulary-type benefit and the explicit emptiness semantics.

P2988 is not a one-off; it is load-bearing vocabulary infrastructure with compounding returns across multiple standard library surfaces.

P4139R2 ("Better Name for Better Lookups in P3091") also advanced to LWG at this meeting, finalizing the naming of the API surface I enabled.

### P4189R0: The Wrong Fix

I cast the only Strongly Against vote on P4189R0 ("get()ing the pointer from optional<T&>"). It was forwarded to LWG over my objection. My position: the paper removes a hardened precondition on `operator->()` — a precondition added because it caught real errors involving dereferences of low-value pointers offset from nullptr. The proposal does not solve the underlying problem that `std::to_address` cannot do its job correctly on `optional<T&>`. We need a principled resolution that addresses both, not one that trades a safety guarantee for convenience.

I intend to follow up with a formal response.

### SG16 Chair: Off-Cycle Coordination

SG16 did not have scheduled sessions at this meeting. I used the week to clear upcoming bottlenecks:

* **Units Library (P3045):** Met directly with lead author Mateusz Pusz to plan LEWG scheduling. Strong alignment on the proposal's necessity; the committee process is the current blocker. This coordination gets LEWG to a formal timeline.
* **Identifier Modernization (`$` character):** Evaluated compilation and toolchain consequences of permitting `$` in standard identifiers. No major technical hazards. This can be resolved via email review, preserving teleconference bandwidth for contested items.
* **Formatting Strings (EWG alignment):** Worked with feature authors to verify that language formatting string proposals meet EWG's design requirements before they hit the LEWG floor — avoiding the rework cycles that burn live meeting time.

---

## LEWG Technical Outcomes

The library evolution pipeline was efficient. Significant volume forwarded to LWG for C++29:

### Monday–Wednesday

* **Fixes & Numerics:** P4206R0 (reverting string support in `constant_wrapper`, C++26 DR), P3395R5 (encoding fixes and `std::error_code` formatter), P3793R1 (better shifting), P3724R4 (integer division) — all forwarded to LWG.
* **Performance Primitives:** P2929R4 (`chunked_invoke`), P3642R5 (`std::clmul`), P3772R1 (`std::simd` bit permutation overloads), P3125R5 (`constexpr` pointer tagging) — forwarded.
* **Better Lookups finalized:** P4139R2 (naming for P3091) forwarded to LWG.
* **Defect Triage:** LWG4156 resolved via P3395R5. LWG1488, LWG2884, LWG2885, LWG4250 closed as NAD.

### Thursday–Friday

* **Concurrency:** P3669R3 (non-blocking `std::execution`) and P3427R4 (hazard pointer synchronous reclamation) forwarded.
* **Views & Containers:** P3242R2 (`mdspan` copy/fill), P3220R2 (`views::take_before`), P3411R6 (`any_view`), P3049R1 (node-handles for lists) — forwarded.
* **Cross-Committee:** Joint EWG-LEWG session secured design approval for P3666R4 (bit-precise integers).
* **`std::embed` (P1040R10):** Design approved by LEWG. The requested revisions are minor — not enough to warrant "forward with changes" but more than editorial. Compile-time resource embedding is firmly on track for C++29.

---

## SG23 Safety Track

I attended the Friday morning (10:30) and late afternoon (15:30) SG23 sessions, returning to LEWG for the 13:30 block.

### P4186R0 — "A Plan For Profiles" (Peter Bindels)

The committee approved a structural roadmap for standardizing safety profiles. This is agreement on process and direction, not finalized technical content. The debate: does this blueprint offer implementable engineering solutions, or does it simply layer additional complexity onto compiler vendors and build systems?

### P4222R0 — "An initialization profile" (Bjarne Stroustrup)

A concrete profile draft attempting to enforce strict object initialization guarantees. The consensus from experienced reviewers is that the framework remains overly complicated and requires substantial real-world implementation verification before advancing. It is fortunate this did not ship unexamined while the committee was focused on C++26.

### The Modules Precedent

The safety profile framework shows early signs of repeating the adoption failure of C++20 Modules. The parallel is specific: Modules shipped with a specification that exceeded vendor implementation capacity and could not fit into existing build infrastructure. Years later, tracking data (arewemodulesyet.org) shows approximately 100 open-source projects with even minimal module support. If safety profiles trend toward an idealized design without implementability constraints, the same adoption paralysis follows.

A reasonable counterargument from internal discussion: if 95% of profiles is just standardizing how warnings are enabled and named, why the pessimism? The implementation ask isn't that huge. This is fair — and it cuts both ways. If the scope really were that modest, profile advocates should have already shipped a clang tool demonstrating what they want.

But the scope is not that modest. P3589R2 (Dos Reis, "C++ Profiles: The Framework") proposes new attribute syntax — `[[profiles::enforce(...)]]`, `[[profiles::suppress(...)]]`, `[[profiles::require(...)]]` — with novel scoping rules ("dominion" over token sequences, distinct from lexical scope), integration with the module system for expressing interface guarantees across translation units, and an open-ended third-party plugin architecture. Profiles may enable runtime instrumentation. Their static semantic effects are specified "as if applied only after translation phase 7" — meaning they cannot participate in overload resolution or SFINAE. The review comments in the current draft show active disagreement on fundamental concepts.

This is not `-Werror=type-safety` with a standard name. It is new language machinery with novel semantics, and the gap between "no one has implemented this" and "let's standardize it" is precisely where the Modules precedent applies.

This is not solely my assessment. Joshua Berne (BDE team, leading our Contracts work) has expressed similar and overlapping concerns to me independently. The risk is real and requires intervention from people with both committee standing and implementation experience.

I deliberately did not work on Contracts during C++26 — we had more than enough effort on it, I was comfortable with the direction the team was taking, and I judged it would be far worse to leave other areas uncovered. The Contracts Study Group has now been suspended; further work will proceed directly in the Evolution Working Group, with obvious overlaps with Safety and Security. SG23 and my SG16 Chair responsibilities are where my presence is non-fungible.

An unimplementable safety specification delivers zero near-term value regardless of when it ships. My continued presence in SG23 — applying the same pragmatic pressure that moved P2988 from proposal to shipped infrastructure — is how we ensure the safety work produces something we can actually deploy.

---

## Plenary Results

The following motions were approved at plenary, applying changes to the C++ working paper:

### Core Language (CWG) — 20 Polls

1. [P4271R0](https://wg21.link/P4271R0) — Core Language Working Group "ready" Issues (DR)
2. [P3596R3](https://wg21.link/P3596R3) — Undefined Behavior and IFNDR Annexes
3. [P2287R6](https://wg21.link/P2287R6) — Designated-initializers for Base Classes
4. [P3899R3](https://wg21.link/P3899R3) — Clarify the behavior of floating-point overflow (DR)
5. [P3668R4](https://wg21.link/P3668R4) — Defaulting Postfix Increment and Decrement Operations
6. [P2953R5](https://wg21.link/P2953R5) — Adding restrictions to defaulted assignment operator functions
7. [P2434R5](https://wg21.link/P2434R5) — Nondeterministic pointer provenance (DR)
8. [P3347R6](https://wg21.link/P3347R6) — Invalid Pointer Operations (DR)
9. [P3658R1](https://wg21.link/P3658R1) — Adjust *identifier* following new Unicode recommendations (DR)
10. [P3950R1](https://wg21.link/P3950R1) — return_value and return_void Are Not Mutually Exclusive (DR)
11. [P3733R1](https://wg21.link/P3733R1) — More named universal character escapes (DR)
12. [P3847R1](https://wg21.link/P3847R1) — Lexical order for lambdas (DR)
13. [P2243R0](https://wg21.link/P2243R0) — Language linkage for templates (DR)
14. [P3424R2](https://wg21.link/P3424R2) — Deallocation Functions with Throwing Exception Specification Are Ill-formed
15. [P3822R2](https://wg21.link/P3822R2) — Conditional noexcept specifiers in compound requirements
16. [P3097R3](https://wg21.link/P3097R3) — Contracts for C++: Virtual functions
17. [P4101R1](https://wg21.link/P4101R1) — Consteval-only Values for C++26 (DR)
18. [P2414R12](https://wg21.link/P2414R12) — Pointer lifetime-end zap proposed solutions (DR)
19. [P3670R4](https://wg21.link/P3670R4) — Pack Indexing for Template Names
20. [P3540R3](https://wg21.link/P3540R3) — #embed offset parameter

### Library (LWG) — 19 Polls

1. [P4258R0](https://wg21.link/P4258R0) — C++ Standard Library Ready Issues (Brno, Jun. 2026)
2. [P3319R6](https://wg21.link/P3319R6) — Add an `iota` object for `simd` (and more)
3. [P3798R1](https://wg21.link/P3798R1) — The unexpected in `std::expected`
4. [P3052R2](https://wg21.link/P3052R2) — `view_interface::at()`
5. [P4206R0](https://wg21.link/P4206R0) — Revert string support in `std::constant_wrapper`
6. [P3395R6](https://wg21.link/P3395R6) — Fix encoding issues and add a formatter for `std::error_code`
7. [P3505R4](https://wg21.link/P3505R4) — Fix the default floating-point representation in `std::format`
8. [P3154R3](https://wg21.link/P3154R3) — Deprecating signed character types in iostreams
9. [P3428R4](https://wg21.link/P3428R4) — Hazard Pointer Batches
10. [P3248R5](https://wg21.link/P3248R5) — Require `[u]intptr_t`
11. [P3793R2](https://wg21.link/P3793R2) — Better shifting
12. [P3242R4](https://wg21.link/P3242R4) — Copy and fill for `mdspan`
13. [P3692R4](https://wg21.link/P3692R4) — How to Avoid OOTA Without Really Trying
14. [P3104R6](https://wg21.link/P3104R6) — Bit permutations
15. [P3772R2](https://wg21.link/P3772R2) — `std::simd` overloads for bit permutations
16. [P3091R6](https://wg21.link/P3091R6) — Better Lookups for `map`, `unordered_map`, and `flat_map`
17. [P3125R6](https://wg21.link/P3125R6) — constexpr pointer tagging
18. [P2019R9](https://wg21.link/P2019R9) — Thread attributes
19. [P3785R1](https://wg21.link/P3785R1) — Library Wording Changes for Defaulted Postfix Increment and Decrement Operations
