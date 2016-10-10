import .clause_ops .prover_state data.monad.transformers
open expr tactic monad

namespace super

meta def has_diff_constr_eq_l (c : clause) : tactic bool := do
env ← get_env,
return $ list.bor $ do
  l ← c↣get_lits,
  guard l↣is_neg,
  return $ match is_eq l↣formula with
  | some (lhs, rhs) :=
    if env↣is_constructor_app lhs ∧ env↣is_constructor_app rhs ∧
       lhs↣get_app_fn↣const_name ≠ rhs↣get_app_fn↣const_name then
      tt
    else
      ff
  | _ := ff
  end

meta def diff_constr_eq_l_pre := preprocessing_rule $
filterM (λc, liftM bnot $♯ has_diff_constr_eq_l c↣c)

meta def try_no_confusion_eq_r (c : clause) (i : ℕ) : tactic (list clause) :=
on_right_at' c i $ λhyp,
  match is_eq hyp↣local_type with
  | some (lhs, rhs) := do
    env ← get_env,
    lhs ← whnf lhs, rhs ← whnf rhs,
    guard $ env↣is_constructor_app lhs ∧ env↣is_constructor_app rhs,
    pr ← mk_app (lhs↣get_app_fn↣const_name↣get_prefix <.> "no_confusion") [false_, lhs, rhs, hyp],
    -- FIXME: change to local false ^^
    ty ← infer_type pr, ty ← whnf ty,
    pr ← to_expr `(@eq.mpr _ %%ty rfl %%pr), -- FIXME
    return [([], pr)]
  | _ := failed
  end

example (x y : ℕ) (h : nat.zero = nat.succ nat.zero) (h2 : nat.succ x = nat.succ y) : true := by do
h ← get_local `h >>= clause.of_classical_proof,
h2 ← get_local `h2 >>= clause.of_classical_proof,
cs ← try_no_confusion_eq_r h 0,
forM' cs clause.validate,
cs ← try_no_confusion_eq_r h2 0,
forM' cs clause.validate,
to_expr `(trivial) >>= exact

@[super.inf]
meta def datatype_infs : inf_decl := inf_decl.mk 10 $ take given, do
sequence' (do i ← list.range given↣c↣num_lits, [inf_if_successful 0 given $ try_no_confusion_eq_r given↣c i])

end super
