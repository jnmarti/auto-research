import Lean

open Lean

private def allowedAxioms : List Name := [`propext, `Classical.choice, `Quot.sound]

private def audit (mod : Name) : CoreM Nat := do
  let env ← getEnv
  let some idx := env.getModuleIdx? mod
    | throwError "Could not find compiled module {mod}"
  let mut count := 0
  for (name, info) in env.constants.toList do
    if env.getModuleIdxFor? name == some idx then
      match info with
      | .thmInfo _ =>
        count := count + 1
        for ax in ← Lean.collectAxioms name do
          unless allowedAxioms.contains ax do
            throwError "{mod}: theorem {name} depends on disallowed axiom {ax}"
      | .axiomInfo _ =>
        -- The compiler may generate internal declarations for executable
        -- definitions. These do not justify a theorem unless its dependency
        -- closure contains them, in which case the branch above rejects it.
        unless name.isInternal || allowedAxioms.contains name do
          throwError "{mod}: declaration {name} is a disallowed axiom {name}"
      | _ => pure ()
  if count == 0 then
    throwError "{mod}: no theorem declarations to audit"
  return count

def main (args : List String) : IO UInt32 := do
  let [modString] := args
    | throw <| IO.userError "Expected one module name"
  let mod := Name.mkSimple modString
  initSearchPath (← findSysroot)
  let env ← importModules #[{module := mod}] {}
  let ctx : Core.Context := { fileName := "<proof audit>", fileMap := default }
  let (count, _) ← (audit mod).toIO ctx { env := env }
  IO.println s!"Audited {count} theorem declaration(s) in {mod}."
  return 0
