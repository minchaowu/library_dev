/-
Copyright (c) 2014 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors Jeremy Avigad, Leonardo de Moura

-- TODO: in emacs mode, change "\sub" to regular subset, use "\ssub" for strict,
         similarly for "\sup"

-- QUESTION: can make the first argument in ∀ x ∈ a, ... implicit?
-- QUESTION: how should we handle facts that only hold classically?
-/
import logic.basic
import data.set  -- from the library in the main repo
open function tactic set

universe variables u v w
variables {α : Type u} {β : Type v} {γ : Type w}

namespace set

/- strict subset -/

def strict_subset (a b : set α) := a ⊆ b ∧ a ≠ b

instance : has_ssubset (set α) := ⟨strict_subset⟩

/- empty set -/

attribute [simp] mem_empty_eq empty_subset

theorem exists_mem_of_ne_empty {s : set α} (h : s ≠ ∅) : ∃ x, x ∈ s :=
classical.by_contradiction
  (suppose ¬ ∃ x, x ∈ s,
    have ∀ x, x ∉ s, from forall_not_of_not_exists this,
    show false, from h (eq_empty_of_forall_not_mem this))

theorem subset_empty_iff (s : set α) : s ⊆ ∅ ↔ s = ∅ :=
iff.intro eq_empty_of_subset_empty (take xeq, begin rw xeq, apply subset.refl end)

lemma bounded_forall_empty_iff {p : α → Prop} :
  (∀ x ∈ (∅ : set α), p x) ↔ true :=
iff.intro (take H, true.intro) (take H x H1, absurd H1 (not_mem_empty _))

/- universal set -/

definition univ : set α := λx, true

theorem mem_univ (x : α) : x ∈ univ :=
by triv

theorem mem_univ_iff (x : α) : x ∈ @univ α ↔ true := iff.rfl

@[simp]
theorem mem_univ_eq (x : α) : x ∈ @univ α = true := rfl

theorem empty_ne_univ [h : inhabited α] : (∅ : set α) ≠ univ :=
assume H : ∅ = univ,
absurd (mem_univ (inhabited.default α)) (eq.rec_on H (not_mem_empty _))

@[simp]
theorem subset_univ (s : set α) : s ⊆ univ := λ x H, trivial

theorem eq_univ_of_univ_subset {s : set α} (h : univ ⊆ s) : s = univ :=
eq_of_subset_of_subset (subset_univ s) h

theorem eq_univ_of_forall {s : set α} (H : ∀ x, x ∈ s) : s = univ :=
ext (take x, iff.intro (assume H', trivial) (assume H', H x))

/- union -/

theorem mem_union_left {x : α} {a : set α} (b : set α) : x ∈ a → x ∈ a ∪ b :=
assume h, or.inl h

theorem mem_union_right {x : α} {b : set α} (a : set α) : x ∈ b → x ∈ a ∪ b :=
assume h, or.inr h

theorem mem_unionl {x : α} {a b : set α} : x ∈ a → x ∈ a ∪ b :=
assume h, or.inl h

theorem mem_unionr {x : α} {a b : set α} : x ∈ b → x ∈ a ∪ b :=
assume h, or.inr h

theorem mem_or_mem_of_mem_union {x : α} {a b : set α} (H : x ∈ a ∪ b) : x ∈ a ∨ x ∈ b := H

theorem mem_union.elim {x : α} {a b : set α} {P : Prop}
    (H₁ : x ∈ a ∪ b) (H₂ : x ∈ a → P) (H₃ : x ∈ b → P) : P :=
or.elim H₁ H₂ H₃

theorem mem_union_iff (x : α) (a b : set α) : x ∈ a ∪ b ↔ x ∈ a ∨ x ∈ b := iff.rfl

theorem mem_union_eq (x : α) (a b : set α) : x ∈ a ∪ b = (x ∈ a ∨ x ∈ b) := rfl

attribute [simp] union_self union_empty empty_union -- union_comm union_assoc

theorem union_left_comm (s₁ s₂ s₃ : set α) : s₁ ∪ (s₂ ∪ s₃) = s₂ ∪ (s₁ ∪ s₃) :=
by rw [-union_assoc, union_comm s₁, union_assoc]

theorem union_right_comm (s₁ s₂ s₃ : set α) : (s₁ ∪ s₂) ∪ s₃ = (s₁ ∪ s₃) ∪ s₂ :=
by rw [union_assoc, union_comm s₂, union_assoc]

theorem subset_union_left (s t : set α) : s ⊆ s ∪ t := λ x H, or.inl H

theorem subset_union_right (s t : set α) : t ⊆ s ∪ t := λ x H, or.inr H

theorem union_subset {s t r : set α} (sr : s ⊆ r) (tr : t ⊆ r) : s ∪ t ⊆ r :=
λ x xst, or.elim xst (λ xs, sr xs) (λ xt, tr xt)

theorem union_eq_self_of_subset_left {s t : set α} (h : s ⊆ t) : s ∪ t = t :=
eq_of_subset_of_subset (union_subset h (subset.refl _)) (subset_union_right _ _)

theorem union_eq_self_of_subset_right {s t : set α} (h : t ⊆ s) : s ∪ t = s :=
by rw [union_comm, union_eq_self_of_subset_left h]

attribute [simp] union_comm union_assoc union_left_comm

/- intersection -/

theorem mem_inter_iff (x : α) (a b : set α) : x ∈ a ∩ b ↔ x ∈ a ∧ x ∈ b := iff.rfl

@[simp]
theorem mem_inter_eq (x : α) (a b : set α) : x ∈ a ∩ b = (x ∈ a ∧ x ∈ b) := rfl

theorem mem_inter {x : α} {a b : set α} (ha : x ∈ a) (hb : x ∈ b) : x ∈ a ∩ b :=
⟨ha, hb⟩

theorem mem_of_mem_inter_left {x : α} {a b : set α} (h : x ∈ a ∩ b) : x ∈ a :=
h^.left

theorem mem_of_mem_inter_right {x : α} {a b : set α} (h : x ∈ a ∩ b) : x ∈ b :=
h^.right

attribute [simp] inter_self inter_empty empty_inter -- inter_comm inter_assoc

theorem nonempty_of_inter_nonempty_right {T : Type} {s t : set T} (h : s ∩ t ≠ ∅) : t ≠ ∅ :=
suppose t = ∅,
have s ∩ t = ∅, from eq.subst (eq.symm this) (inter_empty s),
h this

theorem nonempty_of_inter_nonempty_left {T : Type} {s t : set T} (h : s ∩ t ≠ ∅) : s ≠ ∅ :=
suppose s = ∅,
have s ∩ t = ∅,
  begin rw this, apply empty_inter end,
h this

theorem inter_left_comm (s₁ s₂ s₃ : set α) : s₁ ∩ (s₂ ∩ s₃) = s₂ ∩ (s₁ ∩ s₃) :=
by rw [-inter_assoc, inter_comm s₁, inter_assoc]

theorem inter_right_comm (s₁ s₂ s₃ : set α) : (s₁ ∩ s₂) ∩ s₃ = (s₁ ∩ s₃) ∩ s₂ :=
by rw [inter_assoc, inter_comm s₂, inter_assoc]

theorem inter_univ (a : set α) : a ∩ univ = a :=
ext (take x, and_true _)

theorem univ_inter (a : set α) : univ ∩ a = a :=
ext (take x, true_and _)

theorem inter_subset_left (s t : set α) : s ∩ t ⊆ s := λ x H, and.left H

theorem inter_subset_right (s t : set α) : s ∩ t ⊆ t := λ x H, and.right H

theorem inter_subset_inter_right {s t : set α} (u : set α) (H : s ⊆ t) : s ∩ u ⊆ t ∩ u :=
take x, assume xsu, and.intro (H (and.left xsu)) (and.right xsu)

theorem inter_subset_inter_left {s t : set α} (u : set α) (H : s ⊆ t) : u ∩ s ⊆ u ∩ t :=
take x, assume xus, and.intro (and.left xus) (H (and.right xus))

theorem subset_inter {s t r : set α} (rs : r ⊆ s) (rt : r ⊆ t) : r ⊆ s ∩ t :=
λ x xr, and.intro (rs xr) (rt xr)

theorem inter_eq_self_of_subset_left {s t : set α} (h : s ⊆ t) : s ∩ t = s :=
eq_of_subset_of_subset (inter_subset_left _ _) (subset_inter (subset.refl _) h)

theorem inter_eq_self_of_subset_right {s t : set α} (h : t ⊆ s) : s ∩ t = t :=
by rw [inter_comm, inter_eq_self_of_subset_left h]

attribute [simp] inter_comm inter_assoc inter_left_comm

/- distributivity laws -/

theorem inter_distrib_left (s t u : set α) : s ∩ (t ∪ u) = (s ∩ t) ∪ (s ∩ u) :=
ext (take x, and_distrib _ _ _)

theorem inter_distrib_right (s t u : set α) : (s ∪ t) ∩ u = (s ∩ u) ∪ (t ∩ u) :=
ext (take x, and_distrib_right _ _ _)

theorem union_distrib_left (s t u : set α) : s ∪ (t ∩ u) = (s ∪ t) ∩ (s ∪ u) :=
ext (take x, or_distrib _ _ _)

theorem union_distrib_right (s t u : set α) : (s ∩ t) ∪ u = (s ∪ u) ∩ (t ∪ u) :=
ext (take x, or_distrib_right _ _ _)

/- insert -/

theorem subset_insert (x : α) (a : set α) : a ⊆ insert x a :=
take y, assume ys, or.inr ys

theorem mem_insert (x : α) (s : set α) : x ∈ insert x s :=
or.inl rfl

theorem mem_insert_of_mem {x : α} {s : set α} (y : α) : x ∈ s → x ∈ insert y s :=
assume h, or.inr h

theorem eq_or_mem_of_mem_insert {x a : α} {s : set α} : x ∈ insert a s → x = a ∨ x ∈ s :=
assume h, h

theorem mem_of_mem_insert_of_ne {x a : α} {s : set α} (xin : x ∈ insert a s) : x ≠ a → x ∈ s :=
or_resolve_right (eq_or_mem_of_mem_insert xin)

@[simp]
theorem mem_insert_iff (x a : α) (s : set α) : x ∈ insert a s ↔ (x = a ∨ x ∈ s) :=
iff.intro eq_or_mem_of_mem_insert
  (λ h, or.elim h
    (λ h', begin rw h', apply mem_insert a s end)
    (λ h', mem_insert_of_mem _ h'))

@[simp]
theorem insert_eq_of_mem {a : α} {s : set α} (h : a ∈ s) : insert a s = s :=
ext (take x, iff.intro
  (begin intro h, cases h with h' h', rw h', exact h, exact h' end)
  (mem_insert_of_mem _))

theorem insert_comm (a b : α) (s : set α) : insert a (insert b s) = insert b (insert a s) :=
ext (take c, by simp)

theorem insert_ne_empty (a : α) (s : set α) : insert a s ≠ ∅ :=
λ h, absurd (mem_insert a s) begin rw h, apply not_mem_empty end

-- useful in proofs by induction
theorem forall_of_forall_insert {P : α → Prop} {a : α} {s : set α} (h : ∀ x, x ∈ insert a s → P x) :
  ∀ x, x ∈ s → P x :=
λ x xs, h x (mem_insert_of_mem _ xs)

lemma bounded_forall_insert_iff {P : α → Prop} {a : α} {s : set α} :
  (∀ x ∈ insert a s, P x) ↔ P a ∧ (∀x ∈ s, P x) :=
begin
  apply iff.intro, all_goals (do intro `h, skip),
  { apply and.intro,
    { apply h, apply mem_insert },
    { intros x hx, apply h, apply mem_insert_of_mem, assumption } },
  { intros x hx, cases hx with eq hx,
    { cases eq, apply h^.left },
    { apply h^.right, assumption } }
end

/- properties of singletons -/

theorem singleton_eq (a : α) : ({a} : set α) = insert a ∅ := rfl

-- TODO: interesting: the theorem fails to elaborate without the annotation
@[simp]
theorem mem_singleton_iff (a b : α) : a ∈ ({b} : set α) ↔ a = b :=
iff.intro
  (assume ainb,
    or.elim (ainb : a = b ∨ false) (λ aeqb, aeqb) (λ f, false.elim f))
  (assume aeqb, or.inl aeqb)

-- TODO: again, annotation needed
@[simp]
theorem mem_singleton (a : α) : a ∈ ({a} : set α) := mem_insert a _

theorem eq_of_mem_singleton {x y : α} (h : x ∈ ({y} : set α)) : x = y :=
or.elim (eq_or_mem_of_mem_insert h)
  (suppose x = y, this)
  (suppose x ∈ (∅ : set α), absurd this (not_mem_empty _))

theorem mem_singleton_of_eq {x y : α} (H : x = y) : x ∈ ({y} : set α) :=
eq.subst (eq.symm H) (mem_singleton y)

theorem insert_eq (x : α) (s : set α) : insert x s = ({x} : set α) ∪ s :=
ext (take y, iff.intro
  (suppose y ∈ insert x s,
    or.elim this (suppose y = x, or.inl (or.inl this)) (suppose y ∈ s, or.inr this))
  (suppose y ∈ ({x} : set α) ∪ s,
    or.elim this
      (suppose y ∈ ({x} : set α), or.inl (eq_of_mem_singleton this))
      (suppose y ∈ s, or.inr this)))

@[simp]
theorem pair_eq_singleton (a : α) : ({a, a} : set α) = {a} :=
begin rw insert_eq_of_mem, apply mem_singleton end

theorem singleton_ne_empty (a : α) : ({a} : set α) ≠ ∅ := insert_ne_empty _ _

/- separation -/

theorem mem_sep {s : set α} {p : α → Prop} {x : α} (xs : x ∈ s) (px : p x) : x ∈ {x ∈ s | p x} :=
⟨xs, px⟩

theorem eq_sep_of_subset {s t : set α} (ssubt : s ⊆ t) : s = {x ∈ t | x ∈ s} :=
ext (take x, iff.intro
  (suppose x ∈ s, ⟨ssubt this, this⟩)
  (suppose x ∈ {x ∈ t | x ∈ s}, this^.right))

@[simp]
theorem mem_sep_eq {s : set α} {p : α → Prop} {x : α} : x ∈ {x ∈ s | p x} = (x ∈ s ∧ p x) :=
rfl

theorem mem_sep_iff {s : set α} {p : α → Prop} {x : α} : x ∈ {x ∈ s | p x} ↔ x ∈ s ∧ p x :=
iff.rfl

theorem sep_subset (s : set α) (p : α → Prop) : {x ∈ s | p x} ⊆ s :=
take x, assume H, and.left H

theorem forall_not_of_sep_empty {s : set α} {p : α → Prop} (h : {x ∈ s | p x} = ∅) :
  ∀ x ∈ s, ¬ p x :=
take x, suppose x ∈ s, suppose p x,
have x ∈ {x ∈ s | p x}, from ⟨by assumption, this⟩,
show false, from ne_empty_of_mem this h

/- complement -/

theorem mem_compl {s : set α} {x : α} (h : x ∉ s) : x ∈ -s := h

theorem not_mem_of_mem_compl {s : set α} {x : α} (h : x ∈ -s) : x ∉ s := h

@[simp]
theorem mem_compl_eq (s : set α) (x : α) : x ∈ -s = (x ∉ s) := rfl

theorem mem_compl_iff (s : set α) (x : α) : x ∈ -s ↔ x ∉ s := iff.rfl

@[simp]
theorem inter_compl_self (s : set α) : s ∩ -s = ∅ :=
ext (take x, and_not_self_iff _)

@[simp]
theorem compl_inter_self (s : set α) : -s ∩ s = ∅ :=
ext (take x, not_and_self_iff _)

@[simp]
theorem compl_empty : -(∅ : set α) = univ :=
ext (take x, not_false_iff)

@[simp]
theorem compl_union (s t : set α) : -(s ∪ t) = -s ∩ -t :=
ext (take x, not_or_iff _ _)

-- don't declare @[simp], since it is classical
theorem compl_compl (s : set α) : -(-s) = s :=
ext (take x, classical.not_not_iff _)

-- ditto
theorem compl_inter (s t : set α) : -(s ∩ t) = -s ∪ -t :=
ext (take x, classical.not_and_iff _ _)

@[simp]
theorem compl_univ : -(univ : set α) = ∅ :=
ext (take x, not_true_iff)

theorem union_eq_compl_compl_inter_compl (s t : set α) : s ∪ t = -(-s ∩ -t) :=
by simp [compl_inter, compl_compl]

theorem inter_eq_compl_compl_union_compl (s t : set α) : s ∩ t = -(-s ∪ -t) :=
by simp [compl_compl]

theorem union_compl_self (s : set α) : s ∪ -s = univ :=
ext (take x, classical.or_not_self_iff _)

theorem compl_union_self (s : set α) : -s ∪ s = univ :=
ext (take x, classical.not_or_self_iff _)

theorem compl_comp_compl : compl ∘ compl = @id (set α) :=
funext (λ s, compl_compl s)

/- set difference -/

theorem diff_eq (s t : set α) : s \ t = s ∩ -t := rfl

theorem mem_diff {s t : set α} {x : α} (h1 : x ∈ s) (h2 : x ∉ t) : x ∈ s \ t :=
⟨h1, h2⟩

theorem mem_of_mem_diff {s t : set α} {x : α} (h : x ∈ s \ t) : x ∈ s :=
h^.left

theorem not_mem_of_mem_diff {s t : set α} {x : α} (h : x ∈ s \ t) : x ∉ t :=
h^.right

theorem mem_diff_iff (s t : set α) (x : α) : x ∈ s \ t ↔ x ∈ s ∧ x ∉ t := iff.rfl

@[simp]
theorem mem_diff_eq (s t : set α) (x : α) : x ∈ s \ t = (x ∈ s ∧ x ∉ t) := rfl

theorem union_diff_cancel {s t : set α} (h : s ⊆ t) : s ∪ (t \ s) = t :=
begin rw [diff_eq, union_distrib_left, union_compl_self, inter_univ,
          union_eq_self_of_subset_left h] end

theorem diff_subset (s t : set α) : s \ t ⊆ s := @inter_subset_left _ s _

theorem compl_eq_univ_diff (s : set α) : -s = univ \ s :=
ext (take x, iff.intro (assume H, and.intro trivial H) (assume H, and.right H))

/- powerset -/

theorem mem_powerset {x s : set α} (h : x ⊆ s) : x ∈ powerset s := h

theorem subset_of_mem_powerset {x s : set α} (h : x ∈ powerset s) : x ⊆ s := h

theorem mem_powerset_iff (x s : set α) : x ∈ powerset s ↔ x ⊆ s := iff.rfl

/- function image -/

section image

@[reducible] def eq_on (f1 f2 : α → β) (a : set α) : Prop :=
∀ x ∈ a, f1 x = f2 x

-- TODO(Jeremy): is this a bad idea?

infix ` ' `:80 := image

-- TODO(Jeremy): use bounded exists in image

theorem mem_image_eq (f : α → β) (s : set α) (y: β) : y ∈ f ' s = ∃ x, x ∈ s ∧ f x = y :=
rfl

-- the introduction rule
theorem mem_image {f : α → β} {s : set α} {x : α} {y : β} (h₁ : x ∈ s) (h₂ : f x = y) :
  y ∈ f ' s :=
⟨x, h₁, h₂⟩

theorem mem_image_of_mem (f : α → β) {x : α} {a : set α} (h : x ∈ a) : f x ∈ image f a :=
mem_image h rfl

-- facilitate cases on being in the image
inductive is_mem_image (f : α → β) (s : set α) (y : β) : Prop
| mk : Π x : α, x ∈ s → f x = y → is_mem_image

theorem mem_image_dest {f : α → β} {s : set α} {y : β} (h : y ∈ f ' s) : is_mem_image f s y :=
exists.elim h (take x hx, and.elim hx (take xs fxeq, is_mem_image.mk x xs fxeq))

def mem_image_elim {f : α → β} {s : set α} {y : β} {C : Prop} (h : y ∈ f ' s)
  (h₁ : ∀ (x : α), x ∈ s → f x = y → C) : C :=
begin
  apply is_mem_image.rec_on (mem_image_dest h),
  apply h₁
end

theorem image_eq_image_of_eq_on {f₁ f₂ : α → β} {s : set α} (heq : eq_on f₁ f₂ s) :
  f₁ ' s = f₂ ' s :=
ext (take y, iff.intro
  (assume h, mem_image_elim h (take x xs f₁xeq, mem_image xs ((heq x xs)^.symm^.trans f₁xeq)))
  (assume h, mem_image_elim h (take x xs f₂xeq, mem_image xs ((heq x xs)^.trans f₂xeq))))

lemma image_comp (f : β → γ) (g : α → β) (a : set α) : (f ∘ g) ' a = f ' (g ' a) :=
ext (take z,
  iff.intro
    (assume ⟨x, (hx₁ : x ∈ a), (hx₂ : f (g x) = z)⟩,
      have g x ∈ g ' a,
        from mem_image hx₁ rfl,
      show z ∈ f ' (g ' a),
        from mem_image this hx₂)
    (assume ⟨y, ⟨x, (hz₁ : x ∈ a), (hz₂ : g x = y)⟩, (hy₂ : f y = z)⟩,
      have f (g x) = z,
        from eq.subst (eq.symm hz₂) hy₂,
      show z ∈ (f ∘ g) ' a,
        from mem_image hz₁ this))

lemma image_subset {a b : set α} (f : α → β) (h : a ⊆ b) : f ' a ⊆ f ' b :=
take y,
assume ⟨x, hx₁, hx₂⟩,
mem_image (h hx₁) hx₂

theorem image_union (f : α → β) (s t : set α) :
  image f (s ∪ t) = image f s ∪ image f t :=
ext (take y, iff.intro
  (assume ⟨x, (xst : x ∈ s ∪ t), (fxy : f x = y)⟩,
    or.elim xst
      (assume xs, or.inl (mem_image xs fxy))
      (assume xt, or.inr (mem_image xt fxy)))
  (assume H : y ∈ image f s ∪ image f t,
    or.elim H
      (assume ⟨x, (xs : x ∈ s), (fxy : f x = y)⟩,
        mem_image (or.inl xs) fxy)
      (assume ⟨x, (xt : x ∈ t), (fxy : f x = y)⟩,
        mem_image (or.inr xt) fxy)))

theorem image_empty (f : α → β) : image f ∅ = ∅ :=
eq_empty_of_forall_not_mem (take y, assume ⟨x, (h : x ∈ ∅), h'⟩, h)

theorem mem_image_compl (t : set α) (S : set (set α)) :
  t ∈ compl ' S ↔ -t ∈ S :=
iff.intro
  (assume ⟨t', (Ht' : t' ∈ S), (Ht : -t' = t)⟩,
    show -t ∈ S, begin rw [-Ht, compl_compl], exact Ht' end)
  (suppose -t ∈ S,
    have -(-t) ∈ compl ' S, from mem_image_of_mem compl this,
    show t ∈ compl ' S, from compl_compl t ▸ this)

theorem image_id (s : set α) : id ' s = s :=
ext (take x, iff.intro
  (assume ⟨x', (hx' : x' ∈ s), (x'eq : x' = x)⟩,
    show x ∈ s, begin rw [-x'eq], apply hx' end)
  (suppose x ∈ s, mem_image_of_mem id this))

theorem compl_compl_image (S : set (set α)) :
  compl ' (compl ' S) = S :=
by rw [-image_comp, compl_comp_compl, image_id]

lemma bounded_forall_image_of_bounded_forall {f : α → β} {s : set α} {p : β → Prop}
  (h : ∀ x ∈ s, p (f x)) : ∀ y ∈ f ' s, p y :=
begin
  intros y hy,
  cases mem_image_dest hy with y hy heq,
  rw heq^.symm,
  apply h,
  assumption
end

lemma bounded_forall_image_iff {f : α → β} {s : set α} {p : β → Prop} :
  (∀ y ∈ f ' s, p y) ↔ (∀ x ∈ s, p (f x)) :=
iff.intro (take h x xs, h _ (mem_image_of_mem _ xs)) bounded_forall_image_of_bounded_forall

lemma image_insert_eq {f : α → β} {a : α} {s : set α} :
  f ' insert a s = insert (f a) (f ' s) :=
begin
  apply set.ext,
  intro x, apply iff.intro, all_goals (do intro `h, skip),
  { cases mem_image_dest h with y hy heq, rw heq^.symm, cases hy with y_eq,
    { rw y_eq, apply mem_insert },
    { apply mem_insert_of_mem, apply mem_image_of_mem, assumption } },
  { cases h with eq hx,
    { rw eq, apply mem_image_of_mem, apply mem_insert },
    { cases mem_image_dest hx with y hy heq,
      rw heq^.symm, apply mem_image_of_mem, apply mem_insert_of_mem, assumption } }
end

end image

/- collections of disjoint sets -/

definition pairwise_disjoint (C : set (set α)) : Prop := ∀ s ∈ C, ∀ t ∈ C, s ≠ t → s ∩ t = ∅

theorem pairwise_disjoint_empty : pairwise_disjoint (∅ : set (set α)) :=
λ s h t, absurd h (not_mem_empty s)

theorem pairwise_disjoint_union {C D : set (set α)}
  (hC : pairwise_disjoint C) (hD : pairwise_disjoint D)
    (h : ∀ s ∈ C, ∀ t ∈ D, s ∩ t = ∅) :
  pairwise_disjoint (C ∪ D) :=
λ s hs t ht hne,
match hs, ht with
| (or.inl sC), (or.inl tC) := hC s sC t tC hne
| (or.inl sC), (or.inr tD) := h s sC t tD
| (or.inr sD), (or.inl tC) := inter_comm t s ▸ h t tC s sD
| (or.inr sD), (or.inr tD) := hD s sD t tD hne
end

theorem pairwise_disjoint_singleton (s : set α) : pairwise_disjoint {s} :=
begin
  unfold pairwise_disjoint, simp, intros s₁ s₁eq s₂ s₂eq, simp [s₁eq, s₂eq]
end

/- union and intersection over a family of sets indexed by a type -/

def Union (s : α → set β) : set β := {x : β | ∃ i, x ∈ s i}
def Inter (s : α → set β) : set β := {x : β | ∀ i, x ∈ s i}

notation `⋃` binders `, ` r:(scoped f, Union f) := r
notation `⋂` binders `, ` r:(scoped f, Inter f) := r

@[simp]
theorem mem_Union_eq (x : β) (s : α → set β) : (x ∈ ⋃ i, s i) = (∃ i, x ∈ s i) := rfl

@[simp]
theorem mem_Inter_eq (x : β) (s : α → set β) : (x ∈ ⋂ i, s i) = (∀ i, x ∈ s i) := rfl

theorem Union_subset {s : α → set β} {t : set β} (h : ∀ i, s i ⊆ t) : (⋃ i, s i) ⊆ t :=
take x,
suppose x ∈ ⋃ i, s i,
exists.elim this
  (take i hi, show x ∈ t, from h i hi)

theorem subset_Inter {t : set β} {s : α → set β} (h : ∀ i, t ⊆ s i) : t ⊆ ⋂ i, s i :=
λ x xt i, h i xt

@[simp]
theorem compl_Union (s : α → set β) : - (⋃ i, s i) = (⋂ i, - s i) :=
ext (λ x, begin simp, apply not_exists_iff_forall_not end)

-- classical
theorem compl_Inter (s : α → set β) : -(⋂ i, s i) = (⋃ i, - s i) :=
ext (λ x, begin simp, apply classical.not_forall_iff_exists_not end)

-- classical
theorem Union_eq_comp_Inter_comp (s : α → set β) : (⋃ i, s i) = - (⋂ i, - s i) :=
by simp [compl_Inter, compl_compl]

-- classical
theorem Inter_eq_comp_Union_comp (s : α → set β) : (⋂ i, s i) = - (⋃ i, -s i) :=
by simp [compl_compl]

theorem inter_distrib_Union_left (s : set β) (t : α → set β) :
  s ∩ (⋃ i, t i) = ⋃ i, s ∩ t i :=
ext (take x, iff.intro
  (assume ⟨xs, ⟨i, xti⟩⟩, ⟨i, ⟨xs, xti⟩⟩)
  (assume ⟨i, ⟨xs, xti⟩⟩, ⟨xs, ⟨i, xti⟩⟩))

-- classical
theorem union_distrib_Inter_left (s : set β) (t : α → set β) :
  s ∪ (⋂ i, t i) = ⋂ i, s ∪ t i :=
ext (take x, iff.intro
    (assume h, or.elim h
      (assume h₁, take i, or.inl h₁)
      (assume h₁, take i, or.inr (h₁ i)))
    (assume h,
      classical.by_cases
        (suppose x ∈ s, or.inl this)
        (suppose x ∉ s, or.inr (take i, or.resolve_left (h i) this))))

-- these are useful for turning binary union / intersection into countable ones

definition bin_ext (s t : set α) (n : ℕ) : set α :=
nat.cases_on n s (λ m, t)

lemma Union_bin_ext (s t : set α) : (⋃ i, bin_ext s t i) = s ∪ t :=
ext (take x, iff.intro
  (assume ⟨i, (hi : x ∈ (bin_ext s t) i)⟩,
    begin cases i, apply or.inl hi, apply or.inr hi end)
  (assume h,
    or.elim h
      (suppose x ∈ s, ⟨0, this⟩)
      (suppose x ∈ t, ⟨1, this⟩)))

lemma Inter_bin_ext (s t : set α) : (⋂ i, bin_ext s t i) = s ∩ t :=
ext (take x, iff.intro
  (assume h, and.intro (h 0) (h 1))
  (assume ⟨hs, ht⟩ i, begin cases i, repeat { assumption } end))

/- bounded unions and intersections -/

theorem mem_bUnion {s : set α} {t : α → set β} {x : α} {y : β} (xs : x ∈ s) (ytx : y ∈ t x) :
  y ∈ ⋃ x ∈ s, t x :=
bexists.intro x xs ytx

theorem mem_bInter {s : set α} {t : α → set β} {y : β} (h : ∀ x ∈ s, y ∈ t x) :
  y ∈ ⋂ x ∈ s, t x :=
h

-- faciliate cases with membership in a bUnion
inductive is_mem_bUnion (s : set α) (t : α → set β) (y : β) : Prop
| mk : Π x ∈ s, y ∈ t x → is_mem_bUnion

theorem mem_bUnion_dest {s : set α} {t : α → set β} {y : β} :
  y ∈ (⋃ x ∈ s, t x) →  is_mem_bUnion s t y :=
assume ⟨x, xs, ytx⟩, is_mem_bUnion.mk x xs ytx

theorem mem_bUnion_elim {s : set α} {t : α → set β} {y : β} {C : Prop} (h : y ∈ ⋃ x ∈ s, t x)
    (h₁ : ∀ x, x ∈ s → y ∈ t x → C) : C :=
begin
  apply is_mem_bUnion.rec h₁,
  apply mem_bUnion_dest h
end

theorem bUnion_subset {s : set α} {t : set β} {u : α → set β} (h : ∀ x ∈ s, u x ⊆ t) :
  (⋃ x ∈ s, u x) ⊆ t :=
take y, assume ⟨x, ⟨xs, yux⟩⟩,
show y ∈ t, from h x xs yux

theorem subset_bInter {s : set α} {t : set β} {u : α → set β} (h : ∀ x ∈ s, t ⊆ u x) :
  t ⊆ ⋂ x ∈ s, u x :=
take y, assume yt, take x, assume xs, h x xs yt

theorem subset_bUnion_of_mem {s : set α} {u : α → set β} {x : α} (xs : x ∈ s) :
  u x ⊆ ⋃ x ∈ s, u x :=
take y, assume hy, mem_bUnion xs hy

theorem bInter_subset_of_mem {s : set α} {t : α → set β} {x : α} (xs : x ∈ s) :
  (⋂ x ∈ s, t x) ⊆ t x :=
take y, assume hy, hy x xs

@[simp]
theorem bInter_empty (u : α → set β) : (⋂ x ∈ (∅ : set α), u x) = univ :=
eq_univ_of_forall (take y x xmem, absurd xmem (not_mem_empty x))

@[simp]
theorem bInter_univ (u : α → set β) : (⋂ x ∈ @univ α, u x) = ⋂ x, u x :=
ext (take y, iff.intro (λ h x, h x trivial) (λ h x unix, h x))

-- TODO(Jeremy): here is an artifact of the the encoding of bounded intersection:
-- without dsimp, the next theorem fails to type check, because there is a lambda
-- in a type that needs to be contracted. Using simp [eq_of_mem_singleton xa] also works.

@[simp]
theorem bInter_singleton (a : α) (s : α → set β) : (⋂ x ∈ ({a} : set α), s x) = s a :=
ext (take y, iff.intro
  (assume h, h a (mem_singleton _))
  (assume h, take x, assume xa, begin dsimp, rw [eq_of_mem_singleton xa], apply h end))

theorem bInter_union (s t : set α) (u : α → set β) :
  (⋂ x ∈ s ∪ t, u x) = (⋂ x ∈ s, u x) ∩ (⋂ x ∈ t, u x) :=
ext (take y, iff.intro
  (assume h, and.intro (λ x xs, h x (or.inl xs)) (λ x xt, h x (or.inr xt)))
  (assume h, λ x xst, or.elim (xst) (λ xs, h^.left x xs) (λ xt, h^.right x xt)))

-- TODO(Jeremy): simp [insert_eq, bInter_union] doesn't work
@[simp]
theorem bInter_insert (a : α) (s : set α) (t : α → set β) :
  (⋂ x ∈ insert a s, t x) = t a ∩ (⋂ x ∈ s, t x) :=
begin rw insert_eq, simp [bInter_union] end

-- TODO(Jeremy): another example of where an annotation is needed

theorem bInter_pair (a b : α) (s : α → set β) :
  (⋂ x ∈ ({a, b} : set α), s x) = s a ∩ s b :=
by simp

@[simp]
theorem bUnion_empty (s : α → set β) : (⋃ x ∈ (∅ : set α), s x) = ∅ :=
eq_empty_of_forall_not_mem (take y, assume ⟨x, ⟨xmem, ysx⟩⟩, not_mem_empty x xmem)

@[simp]
theorem bUnion_univ (s : α → set β) : (⋃ x ∈ @univ α, s x) = ⋃ x, s x :=
ext (take y, iff.intro (λ ⟨x, ⟨xuniv, ysx⟩⟩, ⟨x, ysx⟩) (λ ⟨x, ysx⟩, ⟨x, ⟨trivial, ysx⟩⟩))

@[simp]
theorem bUnion_singleton (a : α) (s : α → set β) : (⋃ x ∈ ({a} : set α), s x) = s a :=
ext (take y, iff.intro
  (assume ⟨x, ⟨xa, ysx⟩⟩,
    show y ∈ s a, begin rw [-eq_of_mem_singleton xa], exact ysx end)
  (assume h, ⟨a, ⟨mem_singleton a, h⟩⟩))

theorem bUnion_union (s t : set α) (u : α → set β) :
  (⋃ x ∈ s ∪ t, u x) = (⋃ x ∈ s, u x) ∪ (⋃ x ∈ t, u x) :=
ext (take y, iff.intro
  (assume ⟨x, ⟨xst, yux⟩⟩,
    or.elim xst
      (λ xs, or.inl ⟨x, ⟨xs, yux⟩⟩)
      (λ xt, or.inr ⟨x, ⟨xt, yux⟩⟩))
  (assume h, or.elim h
    (assume ⟨x, ⟨xs, yux⟩⟩, ⟨x, ⟨or.inl xs, yux⟩⟩)
    (assume ⟨x, ⟨xt, yux⟩⟩, ⟨x, ⟨or.inr xt, yux⟩⟩)))

-- TODO(Jeremy): once again, simp doesn't do it alone.

@[simp]
theorem bUnion_insert (a : α) (s : set α) (t : α → set β) :
  (⋃ x ∈ insert a s, t x) = t a ∪ (⋃ x ∈ s, t x) :=
begin rw [insert_eq], simp [bUnion_union] end

theorem bUnion_pair (a b : α) (s : α → set β) :
  (⋃ x ∈ ({a, b} : set α), s x) = s a ∪ s b :=
by simp

@[reducible]
definition sUnion (S : set (set α)) : set α := ⋃ s ∈ S, s

@[reducible]
definition sInter (S : set (set α)) : set α := ⋂ s ∈ S, s

prefix `⋃₀`:110 := sUnion
prefix `⋂₀`:110 := sInter

theorem mem_sUnion {x : α} {t : set α} {S : set (set α)} (hx : x ∈ t) (ht : t ∈ S) :
  x ∈ ⋃₀ S :=
bexists.intro t ht hx

theorem not_mem_of_not_mem_sUnion {x : α} {t : set α} {S : set (set α)}
    (hx : x ∉ ⋃₀ S) (ht : t ∈ S) :
  x ∉ t :=
suppose x ∈ t,
have x ∈ ⋃₀ S, from mem_sUnion this ht,
show false, from hx this

theorem mem_sInter {x : α} {t : set α} {S : set (set α)} (h : ∀ t ∈ S, x ∈ t) : x ∈ ⋂₀ S := h

theorem sInter_subset_of_mem {S : set (set α)} {t : set α} (tS : t ∈ S) : (⋂₀ S) ⊆ t :=
bInter_subset_of_mem tS

theorem subset_sUnion_of_mem {S : set (set α)} {t : set α} (tS : t ∈ S) : t ⊆ (⋃₀ S) :=
subset_bUnion_of_mem tS

@[simp]
theorem sUnion_empty : ⋃₀ ∅ = (∅ : set α) := begin unfold sUnion, simp end

@[simp]
theorem sInter_empty : ⋂₀ ∅ = (univ : set α) := begin unfold sInter, simp end

@[simp]
theorem sUnion_singleton (s : set α) : ⋃₀ {s} = s := begin unfold sUnion, simp end

@[simp]
theorem sInter_singleton (s : set α) : ⋂₀ {s} = s := begin unfold sInter, simp end

theorem sUnion_union (S T : set (set α)) : ⋃₀ (S ∪ T) = ⋃₀ S ∪ ⋃₀ T :=
begin unfold sUnion, simp [bUnion_union] end

theorem sInter_union (S T : set (set α)) : ⋂₀ (S ∪ T) = ⋂₀ S ∩ ⋂₀ T :=
begin unfold sInter, simp [bInter_union] end

@[simp]
theorem sUnion_insert (s : set α) (T : set (set α)) : ⋃₀ (insert s T) = s ∪ ⋃₀ T :=
begin unfold sUnion, simp end

@[simp]
theorem sInter_insert (s : set α) (T : set (set α)) : ⋂₀ (insert s T) = s ∩ ⋂₀ T :=
begin unfold sInter, simp end

@[simp]
theorem sUnion_image (f : α → set β) (s : set α) : ⋃₀ (f ' s) = ⋃ x ∈ s, f x :=
ext (take y, iff.intro
  (assume h, mem_bUnion_elim h
    (take t, assume tfs : t ∈ f ' s, assume yt : y ∈ t,
       mem_image_elim tfs
         (take x, assume xs : x ∈ s, assume fxeq : f x = t,
            mem_bUnion xs (show y ∈ f x, begin rw fxeq, apply yt end))))
  (assume h, mem_bUnion_elim h
    (take x, assume xs : x ∈ s, assume yfx : y ∈ f x,
      mem_bUnion (mem_image_of_mem f xs) yfx)))

@[simp]
theorem sInter_image (f : α → set β) (s : set α) : ⋂₀ (f ' s) = ⋂ x ∈ s, f x :=
ext (take y, iff.intro
  (λ h x xs, h _ (mem_image_of_mem f xs))
  (λ h t ht, mem_image_elim ht (λ x xs fxeq, show y ∈ t, begin rw -fxeq, apply h x xs end)))

theorem compl_sUnion (S : set (set α)) :
  - ⋃₀ S = ⋂₀ (compl ' S) :=
begin simp, reflexivity end

-- classical
theorem sUnion_eq_compl_sInter_compl (S : set (set α)) :
  ⋃₀ S = - ⋂₀ (compl ' S) :=
by rw [-compl_compl (⋃₀ S), compl_sUnion]

-- classical
theorem compl_sInter (S : set (set α)) :
  - ⋂₀ S = ⋃₀ (compl ' S) :=
by rw [sUnion_eq_compl_sInter_compl, compl_compl_image]

-- classical
theorem sInter_eq_comp_sUnion_compl (S : set (set α)) :
   ⋂₀ S = -(⋃₀ (compl ' S)) :=
by rw [-compl_compl (⋂₀ S), compl_sInter]

theorem inter_empty_of_inter_sUnion_empty {s t : set α} {S : set (set α)} (hs : t ∈ S)
    (h : s ∩ ⋃₀ S = ∅) :
  s ∩ t = ∅ :=
eq_empty_of_subset_empty
  begin rw -h, apply inter_subset_inter_left, apply subset_sUnion_of_mem hs end

theorem Union_eq_sUnion_image (s : α → set β) : (⋃ i, s i) = ⋃₀ (s ' univ) :=
by simp

theorem Inter_eq_sInter_image {α I : Type} (s : I → set α) : (⋂ i, s i) = ⋂₀ (s ' univ) :=
by simp

end set
