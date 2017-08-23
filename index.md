# Integrating Rust code into Firefox

---

# `whoami`

 * Emilio Cobos Álvarez

 * `emilio@mozilla.com`

---

# Quantum CSS (stylo)

---

 * Integrate Servo's parallel style system in Gecko.
 * 77k lines of Rust code on `components/style`, without counting dependencies.
 * Enabled on Firefox Nightly (`layout.css.servo.enabled`), probably on 57.
 * bugzil.la/stylo

---

# Approach to parallelism

---

 * The style of a given element only depends on the styles of its ancestors.
 * Thus, we can parallelize across children of a given DOM element.
 * Speed / memory trade-offs.
 * [crisal.io/demos/traversal.html](https://crisal.io/demos/traversal.html).

---

# Rust type system

 * Makes tractable to introduce parallelism in such a complex system.

---

 * Avoiding sharing data unsafely between threads.

```rust
pub trait DomTraversal<E: TElement> : Sync {
    // ...
}
```

---

 * Lifetimes ensure we don't misuse or keep references for longer than what we
   can.

```rust
#[derive(Clone, Copy)]
pub struct GeckoNode<'ln>(pub &'ln RawGeckoNode);
```

---

 * `AtomicRefCell` to wrap read-write data where statically proving its correct
   usage is not possible.

---

# Rust ecosystem

 * Makes it easier to write complex code.
 * Impossible to have stylo without a lot of code from the community.

---

 * `rayon`: Easy, fast, and safe parallelism primitives.

```rust
for chunk in nodes.chunks(WORK_UNIT_MAX) {
    let nodes = chunk.iter().cloned().collect::<WorkUnit<E::ConcreteNode>>();
    let traversal_data_copy = traversal_data.clone();
    scope.spawn(move |scope| {
        let n = nodes;
        top_down_dom(&*n, 0, root,
                     traversal_data_copy, scope, pool, traversal, tls)
    });
}
```

---

 * Lots of other crates from the community in which we depend on for all sorts
   of stuff.

---

# Custom `derive` + generics.

 * Allows us to have less repetitive and more bug-free code.

---

 * Currently derivable traits: `ToCss`, `ComputeSquaredDistance`,
   `HasViewportPercentage`, `ToAnimatedValue`, `ToComputedValue`.

 * Lots of other cleanups possible / in the way.

 * `@nox` is responsible for most of this (thanks to the `synstructure` crate,
   by `@mystor`).

---

```rust
/// A generic value for a single `filter`.
#[cfg_attr(feature = "servo", derive(Deserialize, HeapSizeOf, Serialize))]
#[derive(Clone, Debug, HasViewportPercentage, PartialEq, ToAnimatedValue, ToComputedValue, ToCss)]
pub enum Filter<Angle, Factor, Length, DropShadow> {
    /// `blur(<length>)`
    #[css(function)]
    Blur(Length),
    /// `brightness(<factor>)`
    #[css(function)]
    Brightness(Factor),
    // ...
}
```

---

# Integration into Firefox.

---

 * The kinda-ugly part :-)

 * The basic layer of separation is that the rust style system outputs C++
   structs.

 * We use FFI functions for high-level functionality, with conversion between
   rust and C++ types, `bindgen` for fast access.

 * Had to rewrite `bindgen` to make it work in `mozilla-central`.

---

```rust
#[repr(C)]
#[derive(Debug)]
pub struct nsStyleFont {
    pub mFont: root::nsFont,
    pub mSize: root::nscoord,
    pub mGenericID: u8,
    pub mScriptLevel: i8,
    pub mMathVariant: u8,
    // ...
}
```

---

 * Correct layout enforced by runtime assertions.

 * Lots of improvements possible, little time before 57 :)

---

# Questions / want to help out?

 * Ask here, or drop me a line at `emilio@mozilla.com`.
 * Lots of bugs to fix, some of them suitable for beginners.
 * Happy to mentor!

