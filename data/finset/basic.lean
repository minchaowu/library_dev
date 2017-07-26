import ..list.set ..list.perm
open list subtype nat

def nodup_list (A : Type) := {l : list A // nodup l}

variable {α : Type}

def to_nodup_list_of_nodup {l : list α} (n : nodup l) : nodup_list α := 
⟨l, n⟩

def to_nodup_list [decidable_eq α] (l : list α) : nodup_list α :=
@to_nodup_list_of_nodup α (erase_dup l) (nodup_erase_dup l)

private definition eqv (l₁ l₂ : nodup_list α) := 
perm l₁.1 l₂.1

local infix ~ := eqv

private definition eqv.refl (l : nodup_list α) : l ~ l :=
perm.refl _

private definition eqv.symm {l₁ l₂ : nodup_list α} : l₁ ~ l₂ → l₂ ~ l₁ :=
perm.symm

private definition eqv.trans {l₁ l₂ l₃ : nodup_list α} : l₁ ~ l₂ → l₂ ~ l₃ → l₁ ~ l₃ :=
perm.trans

instance finset.nodup_list_setoid  (α : Type) : setoid (nodup_list α) :=
setoid.mk (@eqv α) (mk_equivalence (@eqv α) (@eqv.refl α) (@eqv.symm α) (@eqv.trans α))

definition finset (α : Type) : Type :=
quotient (finset.nodup_list_setoid α)

namespace finset

definition to_finset_of_nodup (l : list α) (n : nodup l) : finset α :=
⟦to_nodup_list_of_nodup n⟧

definition to_finset [decidable_eq α] (l : list α) : finset α :=
⟦to_nodup_list l⟧

-- lemma to_finset_eq_of_nodup [decidable_eq α] {l : list α} (n : nodup l) :
--   to_finset_of_nodup l n = to_finset l :=
-- have P : to_nodup_list_of_nodup n = to_nodup_list l, from
--   begin
--     rewrite [↑to_nodup_list, ↑to_nodup_list_of_nodup],
--     congruence,
--     rewrite [erase_dup_eq_of_nodup n]
--   end,
-- quotient.sound (eq.subst P (setoid.refl _))

instance has_decidable_eq  [decidable_eq α] : decidable_eq (finset α) :=
λ s₁ s₂, quotient.rec_on_subsingleton₂ s₁ s₂
  (λ l₁ l₂,
     match perm.decidable_perm l₁.1 l₂.1 with
     | decidable.is_true e := decidable.is_true (quot.sound e)
     | decidable.is_false n := decidable.is_false (λ e : ⟦l₁⟧ = ⟦l₂⟧, absurd (quotient.exact e) n)
end)

definition mem (a : α) (s : finset α) : Prop :=
quot.lift_on s (λ l, a ∈ l.1)
 (λ l₁ l₂ (e : l₁ ~ l₂), propext (iff.intro
   (λ ainl₁, perm.mem_of_perm e ainl₁)
   (λ ainl₂, perm.mem_of_perm (perm.symm e) ainl₂)))

-- instance : has_mem α (finset α) := ⟨mem⟩  -- this causes failure of type class inference on mem_of_mem_list
infix ∈ := mem
notation a ∉ b := ¬ mem a b

theorem mem_of_mem_list {a : α} {l : nodup_list α} : a ∈ l.1 → a ∈ ⟦l⟧ :=
λ ainl, ainl

theorem mem_list_of_mem {a : α} {l : nodup_list α} : a ∈ ⟦l⟧ → a ∈ l.1 :=
λ ainl, ainl

instance decidable_mem [h : decidable_eq α] : ∀ (a : α) (s : finset α), decidable (a ∈ s) :=
λ a s, quot.rec_on_subsingleton s
  (λ l, match list.decidable_mem a l.1 with
        | decidable.is_true p := decidable.is_true (mem_of_mem_list p)
        | decidable.is_false n := decidable.is_false (λ p, absurd (mem_list_of_mem p) n)
        end)

theorem mem_to_finset [decidable_eq α] {a : α} {l : list α} : a ∈ l → a ∈ to_finset l :=
λ ainl, mem_erase_dup ainl

theorem mem_to_finset_of_nodup {a : α} {l : list α} (n : nodup l) : a ∈ l → a ∈ to_finset_of_nodup l n :=
λ ainl, ainl

/- extensionality -/
theorem ext {s₁ s₂ : finset α} : (∀ a, a ∈ s₁ ↔ a ∈ s₂) → s₁ = s₂ :=
quotient.induction_on₂ s₁ s₂ (λ l₁ l₂ e, quot.sound (perm.perm_ext l₁.2 l₂.2 e))

/- empty -/
definition empty : finset α :=
to_finset_of_nodup [] nodup_nil

instance : has_emptyc (finset α) := ⟨empty⟩

attribute [simp]
theorem not_mem_empty (a : α) : a ∉ (∅ : finset α) :=
λ aine, aine

attribute [simp]
theorem mem_empty_iff (x : α) : x ∈ (∅ : finset α) ↔ false :=
iff_false_intro (not_mem_empty _)

theorem mem_empty_eq (x : α) : x ∈ (∅ : finset α) = false :=
propext (mem_empty_iff _)

theorem eq_empty_of_forall_not_mem {s : finset α} (H : ∀x, x ∉ s) : s = ∅ :=
ext (λ x, iff_false_intro (H x))

-- /- universe -/
-- definition univ [h : fintype A] : finset A :=
-- to_finset_of_nodup (@fintype.elems A h) (@fintype.unique A h)

-- theorem mem_univ [fintype A] (x : A) : x ∈ univ :=
-- fintype.complete x

-- theorem mem_univ_eq [fintype A] (x : A) : x ∈ univ = true := propext (iff_true_intro !mem_univ)


/- card -/
definition card (s : finset α) : nat :=
quot.lift_on s
  (λ l, length l.1)
  (λ l₁ l₂ p, perm.length_eq_length_of_perm p)

theorem card_empty : card (@empty α) = 0 :=
rfl

lemma ne_empty_of_card_eq_succ {s : finset α} {n : nat} : card s = succ n → s ≠ ∅ :=
λ h hn, by rw hn at h; contradiction

/- insert -/
section insert
variable [h : decidable_eq α]
include h

definition insert (a : α) (s : finset α) : finset α :=
quot.lift_on s
  (λ l, to_finset_of_nodup (insert a l.1) (nodup_insert l.2))
  (λ (l₁ l₂ : nodup_list α) (p : l₁ ~ l₂), quot.sound (perm.perm_insert a p))

-- set builder notation
notation `'{`:max a:(foldr `, ` (x b, insert x b) ∅) `}`:0 := a

theorem mem_insert (a : α) (s : finset α) : a ∈ insert a s :=
quot.induction_on s
 (λ l : nodup_list α, mem_to_finset_of_nodup _ (mem_insert_self _ _))

theorem mem_insert_of_mem {a : α} {s : finset α} (b : α) : a ∈ s → a ∈ insert b s :=
quot.induction_on s
 (λ (l : nodup_list α) (ainl : a ∈ ⟦l⟧), mem_to_finset_of_nodup _ (mem_insert_of_mem ainl))

theorem eq_or_mem_of_mem_insert {x a : α} {s : finset α} : x ∈ insert a s → x = a ∨ x ∈ s :=
quot.induction_on s (λ l : nodup_list α, λ H, list.eq_or_mem_of_mem_insert H)

theorem mem_of_mem_insert_of_ne {x a : α} {s : finset α} (xin : x ∈ insert a s) : x ≠ a → x ∈ s :=
or_resolve_right (eq_or_mem_of_mem_insert xin)

theorem mem_insert_iff (x a : α) (s : finset α) : x ∈ insert a s ↔ (x = a ∨ x ∈ s) :=
iff.intro eq_or_mem_of_mem_insert
  (λ h, or.elim h (λ l, by rw l; apply mem_insert) (λ r, mem_insert_of_mem _ r))

theorem mem_insert_eq (x a : α) (s : finset α) : x ∈ insert a s = (x = a ∨ x ∈ s) :=
propext (mem_insert_iff _ _ _)

theorem mem_singleton_iff (x a : α) : x ∈ '{a} ↔ (x = a) :=
by rewrite [mem_insert_eq, mem_empty_eq, or_false]

theorem mem_singleton (a : α) : a ∈ '{a} := mem_insert a ∅

theorem mem_singleton_of_eq {x a : α} (H : x = a) : x ∈ '{a} :=
by rewrite H; apply mem_insert

theorem eq_of_mem_singleton {x a : α} (H : x ∈ '{a}) : x = a := iff.mp (mem_singleton_iff _ _) H

theorem eq_of_singleton_eq {a b : α} (H : '{a} = '{b}) : a = b :=
have a ∈ '{b}, by rewrite ←H; apply mem_singleton,
eq_of_mem_singleton this

theorem insert_eq_of_mem {a : α} {s : finset α} (H : a ∈ s) : insert a s = s :=
ext (λ x, eq.substr (mem_insert_eq x a s)
   (or_iff_right_of_imp (λH1, eq.substr H1 H)))

theorem singleton_ne_empty (a : α) : '{a} ≠ ∅ :=
begin
  intro H,
  apply not_mem_empty a,
  rewrite ←H,
  apply mem_insert
end

theorem pair_eq_singleton (a : α) : '{a, a} = '{a} :=
by rw [insert_eq_of_mem]; apply mem_singleton

-- useful in proofs by induction
theorem forall_of_forall_insert {P : α → Prop} {a : α} {s : finset α}
    (H : ∀ x, x ∈ insert a s → P x) :
  ∀ x, x ∈ s → P x :=
λ x xs, H x (mem_insert_of_mem _ xs)

theorem insert.comm (x y : α) (s : finset α) : insert x (insert y s) = insert y (insert x s) :=
ext (λ a, begin repeat {rw mem_insert_eq}, rw [propext or.left_comm] end)

theorem card_insert_of_mem {a : α} {s : finset α} : a ∈ s → card (insert a s) = card s :=
quot.induction_on s
  (λ (l : nodup_list α) (ainl : a ∈ ⟦l⟧), list.length_insert_of_mem ainl)

theorem card_insert_of_not_mem {a : α} {s : finset α} : a ∉ s → card (insert a s) = card s + 1 :=
quot.induction_on s
  (λ (l : nodup_list α) (nainl : a ∉ ⟦l⟧), list.length_insert_of_not_mem nainl)

theorem card_insert_le (a : α) (s : finset α) :
  card (insert a s) ≤ card s + 1 :=
if H : a ∈ s then by rewrite [card_insert_of_mem H]; apply le_succ
else by rewrite [card_insert_of_not_mem H]

attribute [recursor 6]
protected theorem induction {P : finset α → Prop}
    (H1 : P empty)
    (H2 : ∀ ⦃a : α⦄, ∀{s : finset α}, a ∉ s → P s → P (insert a s)) :
  ∀s, P s :=
λ s,
quot.induction_on s
 (λ u,
  subtype.rec_on u
   (λ l,
    list.rec_on l
      (λ nodup_l, H1)
      (λ a l',
        λ IH nodup_al',
        have aux₁: a ∉ l', from not_mem_of_nodup_cons nodup_al',
        have ndl' : nodup l', from nodup_of_nodup_cons nodup_al',
        have p1 : P (quot.mk _ (subtype.mk l' ndl')), from IH ndl',
        have ¬ mem a (quot.mk _ (subtype.mk l' ndl')), from aux₁,
        have P (insert a (quot.mk _ (subtype.mk l' _))), from H2 this p1,
        have hperm : perm (list.insert a l') (a :: l'), from perm.perm_insert_cons_of_not_mem aux₁, 
        begin
          apply @eq.subst _ P _ _ _ this,
          apply quot.sound,
          exact hperm
        end)))


protected theorem induction_on {P : finset α → Prop} (s : finset α)
    (H1 : P empty)
    (H2 : ∀ ⦃a : α⦄, ∀ {s : finset α}, a ∉ s → P s → P (insert a s)) :
  P s :=
finset.induction H1 H2 s

theorem exists_mem_of_ne_empty {s : finset α} : s ≠ ∅ → ∃ a : α, a ∈ s :=
@finset.induction_on _ _ (λ x, x ≠ empty → ∃ a : α, mem a x) s 
(λ h, absurd rfl h)
(by intros a s nin ih h; existsi a; apply mem_insert)

theorem eq_empty_of_card_eq_zero {s : finset α} (H : card s = 0) : s = ∅ :=
@finset.induction_on _ _ (λ x, card x = 0 → x = empty) s 
(λ h, rfl) 
(by intros a s' H1 Ih H; rw (card_insert_of_not_mem H1) at H; contradiction) H

end insert

/- erase -/
section erase
variable [h : decidable_eq α]
include h

definition erase (a : α) (s : finset α) : finset α :=
quot.lift_on s
  (λ l, to_finset_of_nodup (l.1.erase a) (nodup_erase_of_nodup a l.2))
  (λ (l₁ l₂ : nodup_list α) (p : l₁ ~ l₂), quot.sound (perm.erase_perm_erase_of_perm a p))

theorem not_mem_erase (a : α) (s : finset α) : a ∉ erase a s :=
quot.induction_on s
  (λ l, list.mem_erase_of_nodup _ l.2)

theorem card_erase_of_mem {a : α} {s : finset α} : a ∈ s → card (erase a s) = pred (card s) :=
quot.induction_on s (λ l ainl, list.length_erase_of_mem ainl)

theorem card_erase_of_not_mem {a : α} {s : finset α} : a ∉ s → card (erase a s) = card s :=
quot.induction_on s (λ l nainl, length_erase_of_not_mem nainl)

theorem erase_empty (a : α) : erase a ∅ = ∅ :=
rfl

theorem ne_of_mem_erase {a b : α} {s : finset α} : b ∈ erase a s → b ≠ a :=
by intros h beqa; subst b; exact absurd h (not_mem_erase _ _)

theorem mem_of_mem_erase {a b : α} {s : finset α} : b ∈ erase a s → b ∈ s :=
quot.induction_on s (λ l bin, mem_of_mem_erase bin)

theorem mem_erase_of_ne_of_mem {a b : α} {s : finset α} : a ≠ b → a ∈ s → a ∈ erase b s :=
quot.induction_on s (λ l n ain, list.mem_erase_of_ne_of_mem n ain)

theorem mem_erase_iff (a b : α) (s : finset α) : a ∈ erase b s ↔ a ∈ s ∧ a ≠ b :=
iff.intro
  (λ H, and.intro (mem_of_mem_erase H) (ne_of_mem_erase H))
  (λ H, mem_erase_of_ne_of_mem (and.right H) (and.left H))

theorem mem_erase_eq (a b : α) (s : finset α) : a ∈ erase b s = (a ∈ s ∧ a ≠ b) :=
propext (mem_erase_iff _ _ _)

open decidable
theorem erase_insert {a : α} {s : finset α} : a ∉ s → erase a (insert a s) = s :=
λ anins, finset.ext (λ b, by_cases
  (λ beqa : b = a, iff.intro
    (λ bin, by subst b; exact absurd bin (not_mem_erase _ _))
    (λ bin, by subst b; contradiction))
  (λ bnea : b ≠ a, iff.intro
    (λ bin,
       have b ∈ insert a s, from mem_of_mem_erase bin,
       mem_of_mem_insert_of_ne this bnea)
    (λ bin,
      have b ∈ insert a s, from mem_insert_of_mem _ bin,
      mem_erase_of_ne_of_mem bnea this)))

theorem insert_erase {a : α} {s : finset α} : a ∈ s → insert a (erase a s) = s :=
λ ains, finset.ext (λ b, by_cases
  (λ h : b = a, iff.intro
    (λ bin, by subst b; assumption)
    (λ bin, by subst b; apply mem_insert))
  (λ hn : b ≠ a, iff.intro
    (λ bin, mem_of_mem_erase (mem_of_mem_insert_of_ne bin hn))
(λ bin, mem_insert_of_mem _ (mem_erase_of_ne_of_mem hn bin))))
end erase

/- union -/
section union
variable [h : decidable_eq α]
include h

definition union (s₁ s₂ : finset α) : finset α :=
quotient.lift_on₂ s₁ s₂
  (λ l₁ l₂,
    to_finset_of_nodup (list.union l₁.1 l₂.1)
                       (nodup_union_of_nodup_of_nodup l₁.2 l₂.2))
  (λ v₁ v₂ w₁ w₂ p₁ p₂, quot.sound (perm.perm_union p₁ p₂))

infix ∪ := union

theorem mem_union_left {a : α} {s₁ : finset α} (s₂ : finset α) : a ∈ s₁ → a ∈ s₁ ∪ s₂ :=
quotient.induction_on₂ s₁ s₂ (λ l₁ l₂ ainl₁, list.mem_union_left ainl₁ _)

theorem mem_union_l {a : α} {s₁ : finset α} {s₂ : finset α} : a ∈ s₁ → a ∈ s₁ ∪ s₂ :=
mem_union_left s₂

theorem mem_union_right {a : α} {s₂ : finset α} (s₁ : finset α) : a ∈ s₂ → a ∈ s₁ ∪ s₂ :=
quotient.induction_on₂ s₁ s₂ (λ l₁ l₂ ainl₂, list.mem_union_right _ ainl₂)

theorem mem_union_r {a : α} {s₂ : finset α} {s₁ : finset α} : a ∈ s₂ → a ∈ s₁ ∪ s₂ :=
mem_union_right s₁

theorem mem_or_mem_of_mem_union {a : α} {s₁ s₂ : finset α} : a ∈ s₁ ∪ s₂ → a ∈ s₁ ∨ a ∈ s₂ :=
quotient.induction_on₂ s₁ s₂ (λ l₁ l₂ ainl₁l₂, list.mem_or_mem_of_mem_union ainl₁l₂)

theorem mem_union_iff (a : α) (s₁ s₂ : finset α) : a ∈ s₁ ∪ s₂ ↔ a ∈ s₁ ∨ a ∈ s₂ :=
iff.intro
 (λ h, mem_or_mem_of_mem_union h)
 (λ d, or.elim d
   (λ i, mem_union_left _ i)
(λ i, mem_union_right _ i))

theorem mem_union_eq (a : α) (s₁ s₂ : finset α) : (a ∈ s₁ ∪ s₂) = (a ∈ s₁ ∨ a ∈ s₂) :=
propext (mem_union_iff _ _ _)

theorem union_comm (s₁ s₂ : finset α) : s₁ ∪ s₂ = s₂ ∪ s₁ :=
ext (λ a, by repeat {rw mem_union_eq}; exact or.comm)

theorem union_assoc (s₁ s₂ s₃ : finset α) : (s₁ ∪ s₂) ∪ s₃ = s₁ ∪ (s₂ ∪ s₃) :=
ext (λ a, by repeat {rw mem_union_eq}; exact or.assoc)

theorem union_left_comm (s₁ s₂ s₃ : finset α) : s₁ ∪ (s₂ ∪ s₃) = s₂ ∪ (s₁ ∪ s₃) :=
left_comm _ union_comm union_assoc s₁ s₂ s₃

theorem union_right_comm (s₁ s₂ s₃ : finset α) : (s₁ ∪ s₂) ∪ s₃ = (s₁ ∪ s₃) ∪ s₂ :=
right_comm _ union_comm union_assoc s₁ s₂ s₃

theorem union_self (s : finset α) : s ∪ s = s :=
ext (λ a, iff.intro
  (λ ain, or.elim (mem_or_mem_of_mem_union ain) (λ i, i) (λ i, i))
  (λ i, mem_union_left _ i))

theorem union_empty (s : finset α) : s ∪ empty = s :=
ext (λ a, iff.intro
  (λ l, or.elim (mem_or_mem_of_mem_union l) (λ i, i) (λ i, absurd i (not_mem_empty _)))
  (λ r, mem_union_left _ r))

theorem empty_union (s : finset α) : empty ∪ s = s :=
calc empty ∪ s = s ∪ empty : union_comm _ _
     ... = s : union_empty _

theorem insert_eq (a : α) (s : finset α) : insert a s = '{a} ∪ s :=
ext (λ x, by rw [mem_insert_iff, mem_union_iff, mem_singleton_iff])

theorem insert_union (a : α) (s t : finset α) : insert a (s ∪ t) = insert a s ∪ t :=
by rewrite [insert_eq, insert_eq a s, union_assoc]

end union

/- inter -/
section inter
variable [h : decidable_eq α]
include h

definition inter (s₁ s₂ : finset α) : finset α :=
quotient.lift_on₂ s₁ s₂
  (λ l₁ l₂,
    to_finset_of_nodup (list.inter l₁.1 l₂.1)
                       (nodup_inter_of_nodup _ l₁.2))
  (λ v₁ v₂ w₁ w₂ p₁ p₂, quot.sound (perm.perm_inter p₁ p₂))


infix ∩ := inter

theorem mem_of_mem_inter_left {a : α} {s₁ s₂ : finset α} : a ∈ s₁ ∩ s₂ → a ∈ s₁ :=
quotient.induction_on₂ s₁ s₂ (λ l₁ l₂ ainl₁l₂, list.mem_of_mem_inter_left ainl₁l₂)

theorem mem_of_mem_inter_right {a : α} {s₁ s₂ : finset α} : a ∈ s₁ ∩ s₂ → a ∈ s₂ :=
quotient.induction_on₂ s₁ s₂ (λ l₁ l₂ ainl₁l₂, list.mem_of_mem_inter_right ainl₁l₂)

theorem mem_inter {a : α} {s₁ s₂ : finset α} : a ∈ s₁ → a ∈ s₂ → a ∈ s₁ ∩ s₂ :=
quotient.induction_on₂ s₁ s₂ (λ l₁ l₂ ainl₁ ainl₂, list.mem_inter_of_mem_of_mem ainl₁ ainl₂)

theorem mem_inter_iff (a : α) (s₁ s₂ : finset α) : a ∈ s₁ ∩ s₂ ↔ a ∈ s₁ ∧ a ∈ s₂ :=
iff.intro
 (λ h, and.intro (mem_of_mem_inter_left h) (mem_of_mem_inter_right h))
(λ h, mem_inter (and.elim_left h) (and.elim_right h))

theorem mem_inter_eq (a : α) (s₁ s₂ : finset α) : (a ∈ s₁ ∩ s₂) = (a ∈ s₁ ∧ a ∈ s₂) :=
propext (mem_inter_iff _ _ _)

theorem inter_comm (s₁ s₂ : finset α) : s₁ ∩ s₂ = s₂ ∩ s₁ :=
ext (λ a, by repeat {rw mem_inter_eq}; exact and.comm)

theorem inter_assoc (s₁ s₂ s₃ : finset α) : (s₁ ∩ s₂) ∩ s₃ = s₁ ∩ (s₂ ∩ s₃) :=
ext (λ a, by repeat {rw mem_inter_eq}; exact and.assoc)

theorem inter_left_comm (s₁ s₂ s₃ : finset α) : s₁ ∩ (s₂ ∩ s₃) = s₂ ∩ (s₁ ∩ s₃) :=
left_comm _ inter_comm inter_assoc s₁ s₂ s₃

theorem inter_right_comm (s₁ s₂ s₃ : finset α) : (s₁ ∩ s₂) ∩ s₃ = (s₁ ∩ s₃) ∩ s₂ :=
right_comm _ inter_comm inter_assoc s₁ s₂ s₃


theorem inter_self (s : finset α) : s ∩ s = s :=
ext (λ a, iff.intro
  (λ h, mem_of_mem_inter_right h)
  (λ h, mem_inter h h))

theorem inter_empty (s : finset α) : s ∩ empty = empty :=
ext (λ a, iff.intro
  (λ h, absurd (mem_of_mem_inter_right h) (not_mem_empty _))
  (λ h, absurd h (not_mem_empty _)))

theorem empty_inter (s : finset α) : empty ∩ s = empty :=
calc empty ∩ s = s ∩ empty : inter_comm _ _
       ... = empty     : inter_empty _

theorem singleton_inter_of_mem {a : α} {s : finset α} (H : a ∈ s) :
  '{a} ∩ s = '{a} :=
ext (λ x,
  begin
    rewrite [mem_inter_eq, mem_singleton_iff],
    exact iff.intro
      (λ h, h.left)
      (λ h, ⟨h, (eq.subst (eq.symm h) H)⟩)
  end)

theorem singleton_inter_of_not_mem {a : α} {s : finset α} (H : a ∉ s) :
  '{a} ∩ s = (∅ : finset α) :=
ext (λ x,
  begin
    rewrite [mem_inter_eq, mem_singleton_iff, mem_empty_eq],
    exact iff.intro
      (λ h, H (eq.subst h.left h.right))
      (false.elim)
end)

end inter

/- distributivity laws -/
section inter
variable [h : decidable_eq α]
include h

theorem inter_distrib_left (s t u : finset α) : s ∩ (t ∪ u) = (s ∩ t) ∪ (s ∩ u) :=
ext (λ x, by rw [mem_inter_eq];repeat {rw mem_union_eq};repeat {rw mem_inter_eq}; super)

theorem inter_distrib_right (s t u : finset α) : (s ∪ t) ∩ u = (s ∩ u) ∪ (t ∩ u) :=
ext (λ x, by rw [mem_inter_eq]; repeat {rw mem_union_eq}; repeat {rw mem_inter_eq}; super)

theorem union_distrib_left (s t u : finset α) : s ∪ (t ∩ u) = (s ∪ t) ∩ (s ∪ u) :=
ext (λ x, by rw [mem_union_eq]; repeat {rw mem_inter_eq}; repeat {rw mem_union_eq}; super)

theorem union_distrib_right (s t u : finset α) : (s ∩ t) ∪ u = (s ∪ u) ∩ (t ∪ u) :=
ext (λ x, by rw [mem_union_eq]; repeat {rw mem_inter_eq}; repeat {rw mem_union_eq}; super)

end inter
definition subset_aux {T : Type} (l₁ l₂ : list T) := ∀ ⦃a : T⦄, a ∈ l₁ → a ∈ l₂

/- subset -/
definition subset (s₁ s₂ : finset α) : Prop :=
quotient.lift_on₂ s₁ s₂
  (λ l₁ l₂, subset_aux l₁.1 l₂.1)
  (λ v₁ v₂ w₁ w₂ p₁ p₂, propext (iff.intro
    (λ s₁ a i, perm.mem_of_perm p₂ (s₁ (perm.mem_of_perm (perm.symm p₁) i)))
    (λ s₂ a i, perm.mem_of_perm (perm.symm p₂) (s₂ (perm.mem_of_perm p₁ i)))))

infix ⊆ := subset

theorem empty_subset (s : finset α) : empty ⊆ s :=
quot.induction_on s (λ l, list.nil_subset l.1)

-- theorem subset_univ [h : fintype α] (s : finset α) : s ⊆ univ :=
-- quot.induction_on s (λ l a i, fintype.complete a)

theorem subset.refl (s : finset α) : s ⊆ s :=
quot.induction_on s (λ l, list.subset.refl l.1)

theorem subset.trans {s₁ s₂ s₃ : finset α} : s₁ ⊆ s₂ → s₂ ⊆ s₃ → s₁ ⊆ s₃ :=
quotient.induction_on₃ s₁ s₂ s₃ (λ l₁ l₂ l₃ h₁ h₂, list.subset.trans h₁ h₂)

theorem mem_of_subset_of_mem {s₁ s₂ : finset α} {a : α} : s₁ ⊆ s₂ → a ∈ s₁ → a ∈ s₂ :=
quotient.induction_on₂ s₁ s₂ (λ l₁ l₂ h₁ h₂, h₁ h₂)

theorem subset.antisymm {s₁ s₂ : finset α} (H₁ : s₁ ⊆ s₂) (H₂ : s₂ ⊆ s₁) : s₁ = s₂ :=
ext (λ x, iff.intro (λ H, mem_of_subset_of_mem H₁ H) (λ H, mem_of_subset_of_mem H₂ H))

-- alternative name
theorem eq_of_subset_of_subset {s₁ s₂ : finset α} (H₁ : s₁ ⊆ s₂) (H₂ : s₂ ⊆ s₁) : s₁ = s₂ :=
subset.antisymm H₁ H₂

theorem subset_of_forall {s₁ s₂ : finset α} : (∀x, x ∈ s₁ → x ∈ s₂) → s₁ ⊆ s₂ :=
quotient.induction_on₂ s₁ s₂ (λ l₁ l₂ H, H)

theorem subset_insert [h : decidable_eq α] (s : finset α) (a : α) : s ⊆ insert a s :=
subset_of_forall (λ x h, mem_insert_of_mem _ h)

theorem eq_empty_of_subset_empty {x : finset α} (H : x ⊆ empty) : x = empty :=
subset.antisymm H (empty_subset x)

theorem subset_empty_iff (x : finset α) : x ⊆ empty ↔ x = empty :=
iff.intro eq_empty_of_subset_empty (λ xeq, by rewrite xeq; apply subset.refl empty)

section
variable [decα : decidable_eq α]
include decα

theorem erase_subset_erase (a : α) {s t : finset α} (H : s ⊆ t) : erase a s ⊆ erase a t :=
begin
  apply subset_of_forall,
  intro x,
  repeat {rw mem_erase_eq},
  intro H',
  show x ∈ t ∧ x ≠ a, from and.intro (mem_of_subset_of_mem H (and.left H')) (and.right H')
end

theorem erase_subset  (a : α) (s : finset α) : erase a s ⊆ s :=
begin
  apply subset_of_forall,
  intro x,
  rewrite mem_erase_eq,
  intro H,
  apply and.left H
end

theorem erase_eq_of_not_mem {a : α} {s : finset α} (anins : a ∉ s) : erase a s = s :=
eq_of_subset_of_subset (erase_subset _ _)
  (subset_of_forall (λ x, λ xs : x ∈ s,
    have x ≠ a, from λ H', anins (eq.subst H' xs),
mem_erase_of_ne_of_mem this xs))

theorem erase_insert_subset (a : α) (s : finset α) : erase a (insert a s) ⊆ s :=
decidable.by_cases
  (λ ains : a ∈ s, by rewrite [insert_eq_of_mem ains]; apply erase_subset)
  (λ nains : a ∉ s, by rewrite [erase_insert nains]; apply subset.refl)

theorem erase_subset_of_subset_insert {a : α} {s t : finset α} (H : s ⊆ insert a t) :
  erase a s ⊆ t :=
subset.trans (erase_subset_erase _ H) (erase_insert_subset _ _)

theorem insert_erase_subset (a : α) (s : finset α) : s ⊆ insert a (erase a s) :=
decidable.by_cases
  (λ ains : a ∈ s, by rewrite [insert_erase ains]; apply subset.refl)
  (λ nains : a ∉ s, by rewrite[erase_eq_of_not_mem nains]; apply subset_insert)

theorem insert_subset_insert (a : α) {s t : finset α} (H : s ⊆ t) : insert a s ⊆ insert a t :=
begin
  apply subset_of_forall,
  intro x,
  repeat {rw mem_insert_eq},
  intro H',
  cases H' with xeqa xins,
    exact (or.inl xeqa),
  exact (or.inr (mem_of_subset_of_mem H xins))
end

theorem subset_insert_of_erase_subset {s t : finset α} {a : α} (H : erase a s ⊆ t) :
  s ⊆ insert a t :=
subset.trans (insert_erase_subset a s) (insert_subset_insert _ H)

theorem subset_insert_iff (s t : finset α) (a : α) : s ⊆ insert a t ↔ erase a s ⊆ t :=
iff.intro erase_subset_of_subset_insert subset_insert_of_erase_subset

end

/- upto -/
section upto

definition upto (n : nat) : finset nat :=
to_finset_of_nodup (list.upto n) (nodup_upto n)

theorem card_upto : ∀ n, card (upto n) = n :=
list.length_upto

theorem lt_of_mem_upto {n a : nat} : a ∈ upto n → a < n :=
@list.lt_of_mem_upto n a

theorem mem_upto_succ_of_mem_upto {n a : nat} : a ∈ upto n → a ∈ upto (succ n) :=
list.mem_upto_succ_of_mem_upto

theorem mem_upto_of_lt {n a : nat} : a < n → a ∈ upto n :=
@list.mem_upto_of_lt n a

theorem mem_upto_iff (a n : nat) : a ∈ upto n ↔ a < n :=
iff.intro lt_of_mem_upto mem_upto_of_lt

theorem mem_upto_eq (a n : nat) : a ∈ upto n = (a < n) :=
propext (mem_upto_iff _ _)

end upto

theorem upto_zero : upto 0 = empty := rfl

theorem upto_succ (n : ℕ) : upto (succ n) = upto n ∪ '{n} :=
begin
  apply ext, intro x,
  rw [mem_union_iff], repeat {rw mem_upto_iff}, 
  rw [mem_singleton_iff, ←le_iff_lt_or_eq], 
  apply iff.intro,
  {intro h, apply le_of_lt_succ, exact h},
  {apply lt_succ_of_le}
end

/- useful rules for calculations with quantifiers -/
theorem exists_mem_empty_iff {A : Type} (P : A → Prop) : (∃ x, mem x empty ∧ P x) ↔ false :=
iff.intro
  (λ H,
    let ⟨x,H1⟩ := H in
    not_mem_empty _ (H1.left))
  (λ H, false.elim H)

theorem exists_mem_empty_eq {A : Type} (P : A → Prop) : (∃ x, mem x empty ∧ P x) = false :=
propext (exists_mem_empty_iff _)

theorem exists_mem_insert_iff {A : Type} [d : decidable_eq A]
    (a : A) (s : finset A) (P : A → Prop) :
  (∃ x, x ∈ insert a s ∧ P x) ↔ P a ∨ (∃ x, x ∈ s ∧ P x) :=
iff.intro
  (λ H,
    let ⟨x,H1,H2⟩ := H in
    or.elim (eq_or_mem_of_mem_insert H1)
      (λ l, or.inl (eq.subst l H2))
      (λ r, or.inr ⟨x, ⟨r, H2⟩⟩))
  (λ H,
    or.elim H
      (λ l, ⟨a, ⟨mem_insert _ _, l⟩⟩)
      (λ r, let ⟨x,H2,H3⟩ := r in ⟨x, ⟨mem_insert_of_mem _ H2, H3⟩⟩))


theorem exists_mem_insert_eq {A : Type} [d : decidable_eq A] (a : A) (s : finset A) (P : A → Prop) :
  (∃ x, x ∈ insert a s ∧ P x) = (P a ∨ (∃ x, x ∈ s ∧ P x)) :=
propext (exists_mem_insert_iff _ _ _)

theorem forall_mem_empty_iff {A : Type} (P : A → Prop) : (∀ x, mem x empty → P x) ↔ true :=
iff.intro (λ H, trivial) (λ H x H', absurd H' (not_mem_empty _))

theorem forall_mem_empty_eq {A : Type} (P : A → Prop) : (∀ x, mem x empty → P x) = true :=
propext (forall_mem_empty_iff _)

theorem forall_mem_insert_iff {A : Type} [d : decidable_eq A]
    (a : A) (s : finset A) (P : A → Prop) :
  (∀ x, x ∈ insert a s → P x) ↔ P a ∧ (∀ x, x ∈ s → P x) :=
iff.intro
  (λ H, and.intro (H _ (mem_insert _ _)) (λ x H', H _ (mem_insert_of_mem _ H')))
  (λ H x, λ H' : x ∈ insert a s,
    or.elim (eq_or_mem_of_mem_insert H')
      (λ l, eq.subst (eq.symm l) H.left)
      (λ r, and.right H _ r))

theorem forall_mem_insert_eq {A : Type} [d : decidable_eq A] (a : A) (s : finset A) (P : A → Prop) :
  (∀ x, x ∈ insert a s → P x) = (P a ∧ (∀ x, x ∈ s → P x)) :=
propext (forall_mem_insert_iff _ _ _)

end finset

