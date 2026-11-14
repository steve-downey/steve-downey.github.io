// clang-format off
// (formatting is off: the comments are aligned by hand, and the post shows this file by line range)
// P4222R3 initialization-profile probes, 2026-10-24
// Compilers (Compiler Explorer): clang_profiles_init  (cppalliance/clang profiles-init @ 4a2d2673)
//                                gcontracts-p4324-trunk (villevoutilainen/gcc p4324 @ 146e7ba1)
// Flags: -std=c++23 -pedantic-errors ; profile enabled by the file-scope attribute below
// (or -fprofiles-enforce=std::init on either compiler).
// Rechecked 2026-11-14: Clang unchanged, GCC rebuilt by Compiler Explorer at a9bec5e9 (2026-11-13).
// A comment that changed says "revised 2026-11-14" and what it said before.
//
// Each block below is one godbolt link with both compilers side by side.
// FN = accepted but reads/double-inits indeterminate memory; FP = rejected but correct per the paper.

// ============================================================================
// L1  https://godbolt.org/z/ex75Eeqbe   two pointers to one object
// ============================================================================
[[profiles::enforce(std::init)]];
// A1: conditional store, then a second (unmarked) pointer to the same object
int a1_via_p(int* p [[ref_to_uninit]], bool c) {
    if (c) *p = 1;
    return *p;          // Clang: rejected (correct: uninit when !c). GCC: accepted -> FN.
                        // revised 2026-11-14: was "both reject"; GCC checks no read through a marked parameter
}
int a1_via_q(int* p [[ref_to_uninit]], bool c) {
    if (c) *p = 1;
    int* q = p;         // Clang: accepted ("initialized on some path" suffices for an unmarked copy)
    return *q;          // Clang: accepted  -> FN.   GCC: rejects the copy at the line above.
}
// A1b: unconditional store, then an unmarked copy (paper §4.3: fine)
int a1b_f(int* p [[ref_to_uninit]]) {
    *p = 1;
    int* q = p;         // GCC: rejected -> FP (GCC never un-marks a referent without now_init)
    return *q;          // Clang: accepted (correct)
}

// ============================================================================
// L2  https://godbolt.org/z/4qMKz13T5   escape / alias of the pointer object / lambda
// ============================================================================
// A3: paper §4.2 example + a second name for u
struct X { int v; };
void a3_f(X* p [[ref_to_uninit]]);      // ordinary function, not [[must_init]]/[[now_init]]
X a3_tst() {
    X x [[uninit]];
    a3_f(&x);
    X z = x;            // both reject (paper: "x is still [[uninit]]") -- correct
    return z;
}
int a3_tst2() {
    int u [[uninit]];
    int* p [[ref_to_uninit]] = &u;   // second name for u, nothing stored through it
    return u;                        // Clang: accepted -> FN ("escape counts as assignment"). GCC: rejects.
}
// A4: alias of the POINTER OBJECT; reseat through the alias
int a4_f(int* p [[ref_to_uninit]]) {
    int other [[uninit]];
    *p = 1;
    int*& r = p;
    r = &other;         // GCC: rejected here ("address of other taken") -- sound by accident
    return *p;          // Clang: accepted -> FN (p now points at `other`)
}
int a4_h(int* p [[ref_to_uninit]]) {
    int init = 7;
    int*& r = p;
    r = &init;
    return *p;          // both accept (correct, by luck: Clang has lost track of p)
}
// A5: read through a captured marked pointer
int a5_f(int* p [[ref_to_uninit]]) {
    auto l = [&p] { return *p; };    // Clang: accepted -> FN ; GCC: accepted -> FN
    return l();
}
int a5_g(int* p [[ref_to_uninit]]) {
    auto l = [p] { return *p; };     // Clang: rejected (for the marking, not the read) ; GCC: accepted -> FN
    return l();
}

// ============================================================================
// L3  https://godbolt.org/z/da4MGM6Eo   two references / alias of this
// ============================================================================
// R: two [[ref_to_uninit]] references to one object -- Clang gets all five right.
// GCC rejects every `int& a [[ref_to_uninit]] = u;` as "address taken before provably initialized" -> FP
int r1() { int u [[uninit]]; int& a [[ref_to_uninit]] = u; a = 1; return u; }                                // accept
int r2() { int u [[uninit]]; int& a [[ref_to_uninit]] = u; int& b [[ref_to_uninit]] = u; a = 1; return b; }  // accept
int r3() { int u [[uninit]]; int& a [[ref_to_uninit]] = u; int& b [[ref_to_uninit]] = u; return b; }         // must reject
int r4() { int u [[uninit]]; int& a [[ref_to_uninit]] = u; u = 1; return a; }                                // accept
int r5() { int u [[uninit]]; int& a [[ref_to_uninit]] = u; int& b [[ref_to_uninit]] = u; a = 1; return u; }  // accept
// CT: alias of this inside a constructor (both compilers behave identically)
struct C1 { int m [[uninit]]; int v; C1() : v(0) { C1* self = this; self->m = 1; v = m; } };  // rejected -> FP (write via alias earns no credit)
struct C2 { int m [[uninit]]; int v; C2() : v(0) { C2* self = this; v = self->m; } };         // accepted -> FN (read via alias not attributed)
struct C3 { int m [[uninit]]; int v; C3() : v(0) { v = m; } };                                 // rejected (control)

// ============================================================================
// L4  https://godbolt.org/z/87vnTdTza   pointers to members of an [[uninit]] aggregate
// ============================================================================
struct Point { int x, y; };
int b1_f() {
    Point p [[uninit]];
    p.x = 7;            // both reject: paper §5.4 bans member-wise init of an [[uninit]] aggregate
    p.y = 9;
    return p.x + p.y;
}
int b1_g() {
    Point p [[uninit]];
    int* px [[ref_to_uninit]] = &p.x;   // bindings accepted
    int* py [[ref_to_uninit]] = &p.y;
    *px = 7; *py = 9;                   // stores accepted, but credit nothing
    return p.x + p.y;                   // both reject -> FP (fully written) -- the §5.4 ban re-expressed through pointers
}
int b1_h() {
    Point p [[uninit]];
    int* px [[ref_to_uninit]] = &p.x;
    *px = 7;
    return p.y;                         // both reject (correct, for the same syntactic reason)
}
// B2: pointer-to-data-member
int b2_f(int Point::*pm) {
    Point p [[uninit]];
    p.*pm = 1;          // Clang: "writing a member"; GCC: "address of p taken"
    return p.x + p.y;   // both reject (correct, by form only)
}

// ============================================================================
// L5  https://godbolt.org/z/joG1Kbo4Y   [[uninit]] members via another object, memset, void*, malloc
// ============================================================================
#include <memory>
#include <cstring>
#include <cstdlib>
struct S { int a [[uninit]]; int b = 0; };
int m_f(S* p) { return p->a; }       // both accept -> FN: [[uninit]] members are not checked outside ctor / local aggregate
int m_g() { S s; return s.a; }       // both reject (correct)
int b3_f(S* p) {
    int* pa [[ref_to_uninit]] = &p->a;
    *pa = 1;
    return p->a;                     // both accept -- but only because m_f is accepted too
}
struct B { int b; };
struct D : B { int d; };
int b4_f() {
    D u [[uninit]];
    std::construct_at(static_cast<B*>(&u), B{1});
    u.d = 2;                         // both reject (designed strictness: aggregate member write)
    return u.b + u.d;
}
int b4_g() {
    int arr [[uninit]] [4];
    std::memset(arr, 0, sizeof(int));   // only arr[0]
    return arr[3];                      // both accept -> FN (memset credits the whole array)
}
struct Triv { int x; int y; };
int b5_f() {
    void* v [[ref_to_uninit]] = std::malloc(sizeof(Triv));   // GCC: rejected -> FP (GCC thinks malloc returns initialized memory)
    std::construct_at((int*)v, 1);                           // only first int
    return ((Triv*)v)->y;                                    // Clang: accepted -> FN (typeless storage credited whole)
}
int b5_g(int* p [[ref_to_uninit]]) {
    int* q = p + 1;     // Clang: accepted ; GCC: accepted
    int* r = &p[1];     // Clang: rejected ; GCC: accepted
    return *q + *r;     // Clang: *q accepted -> FN ; GCC: accepted -> FN
}
int mal_f() { int* p = (int*)std::malloc(sizeof(int)); return *p; }                   // Clang: rejected ; GCC: accepted -> FN
int mal_g() { int* p [[ref_to_uninit]] = (int*)std::malloc(sizeof(int)); return *p; } // Clang: rejected (read) ; GCC: rejected for the wrong reason (marking)

// ============================================================================
// L6  https://godbolt.org/z/Kf6114vdb   double construction / correlated conditions
// ============================================================================
struct X2 { int v; };
void a2_f() {
    X2 u [[uninit]];
    X2* p [[ref_to_uninit]] = &u;
    X2* q [[ref_to_uninit]] = &u;
    std::construct_at(p, X2{1});
    std::construct_at(q, X2{2});   // Clang: rejected (tracks both names to u) ; GCC: accepted -> FN (does not notice a second construct_at)
                                   // revised 2026-11-14: was "knows nothing of construct_at"; GCC does credit the first one on a local
    int r = u.v; (void)r;
}
int use(int);
int c1_f(bool c) {
    int x [[uninit]];
    if (c) x = 1;
    if (c) return use(x);   // both reject: path-insensitive by design (§1.5) -> designed FP
    return 0;
}
