(*
 * Copyright © 2009 The Regents of the University of California. 
 * All rights reserved. Permission is hereby granted, without written 
 * agreement and without 
 * license or royalty fees, to use, copy, modify, and distribute this 
 * software and its documentation for any purpose, provided that the 
 * above copyright notice and the following two paragraphs appear in 
 * all copies of this software. 
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY 
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES 
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN 
 * IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY 
 * OF SUCH DAMAGE. 
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, 
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION 
 * TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *)

open Misc.Ops
module SS = Misc.StringSet

(******* This module contains globals representing "flags" **************)
let annotsep_name       = "\n\n=+=\n\n"
let global_name         = "GLOBAL"
let lib_path            = Sys.argv.(0) |> Filename.dirname |> ref

let file: string option ref = ref None         (* last commandline param*)
let liquidc_file_prefix = ref "liquidc"        (* where to find/place liquidc-related files *)
let safe                = ref false            (* -safe *)
let manual              = ref false            (* -manual *)
let out_file            = ref "out"            (* -save *)
let save_file           = ref "out.fq"         (* -save *)
let dump_ref_constraints= ref false            (* -drconstr *)
let ctypes_only         = ref false            (* -ctypes *)
let ol_default          = 2
let verbose_level       = ref ol_default       (* -v *)
let inccheck            = ref SS.empty         (* -inccheck *)

let strictsortcheck     = ref false            (* -strictsortcheck *)
let latex_file: string option ref = ref None   (* translate to LaTeX *)
let armc_file: string option ref  = ref None   (* translate to ARMC *)
let horn_file: string option ref  = ref None   (* translate to Horn clauses *)
let raw_horn_file: string option ref  = ref None   (* translate to raw Horn clauses *)
let q_armc_file: string option ref = ref None   (* OBSOLETE translate to Q'ARMC file *)
let dot_file: string option ref = ref None   (* translate to dot file *)
let purify_function_application = ref true  (* replace fun-terms by existentially quantified variables *)
let z3_timeout           = ref 25

let fastscalar                  = ref false (* -fastscalar *)
let minquals                    = ref false (* -minquals *)
let ptag                        = ref true  (* -ptag *)
let genspec                     = ref false (* -genspec *)
let simplify_t                  = ref false (* simplify and prune vacuous FixConstraint.t constraints *)
let root                        = ref ""    (* root function *)
let refine_sort                 = ref false (* -refinesort *)
let sorted_quals                = ref false (* -sortedquals *)
let true_unconstrained          = ref true  (* -true_unconstrained *)
let do_nothing                  = ref false (* -nop *)
let dump_imp                    = ref false (* -imp *)
let dump_simp                   = ref ""    (* -simp *)
let prune_live                  = ref false (* -prunelive *)
let print_nontriv               = ref false (* -print_nontriv *)
let heapify_nonarrays           = ref true  (* heapify all stack variables *)
let timeout                     = ref (-1)
let lfp                         = ref true (* -nolfp *)
let slice                       = ref true  (* -slice  *)
(* JHALA: what do these do ? *)
let psimple       = ref true            (* -psimple *)
let simple        = ref true            (* -simple  *) 
let dump_graph    = ref false           (* -dgraph :: this probably caused the dsolve solver to dump the constraint graph *)
let dropcalls     = ref false           (* -dropcalls *)
let adjdeps       = ref true            (* -origdeps *)
let check_is      = ref false           (* -check-indices *)
let trace_scalar  = ref false           (* -trace-scalar *)
let prune_index   = ref false           (* -prune-index *)  

(****************************************************************)
(************* Output levels ************************************)
(****************************************************************)

(* verbosity levels by purpose *)
let ol_always = 0
let ol_solve_error = 1
let ol_warning = 1
let ol_solve_master = 2
let ol_solve_stats = 2
let ol_timing = 2
let ol_warn_mlqs = 3
let ol_normalized = 3
let ol_finals = 3
let ol_ctypes = 3
let ol_dquals = 4 
let ol_unique_names = 5 (* must be > ol_dquals *)
let ol_solve = 10 
let ol_refine = 11 
let ol_scc = 12 
let ol_dump_env = 10 
let ol_axioms = 5
let ol_dump_prover = 20
let ol_verb_constrs = 21
let ol_dump_wfs = 22
let ol_dump_meas = 30
let ol_dump_quals = 50
let ol_insane = 200

let verb_stack = ref []
let null_formatter = Format.make_formatter (fun a b c -> ()) ignore
let nprintf a = Format.fprintf null_formatter a
let ck_olev l = l <= !verbose_level

let bprintf b = if b then Format.printf else nprintf
let cprintf l = if ck_olev l then Format.printf else nprintf
let ecprintf l = if ck_olev l then Format.eprintf else nprintf
let fcprintf ppf l = if ck_olev l then Format.fprintf ppf else nprintf
let icprintf printer l ppf = if ck_olev l then printer ppf else printer null_formatter
let cprintln l s = if ck_olev l then Printf.ksprintf (Format.printf "@[%s@\n@]") s else nprintf
let elevate_olev l = if ck_olev l then () else verb_stack := !verbose_level :: !verb_stack; verbose_level := l
let restore_olev = match !verb_stack with x :: xs -> verbose_level := x; verb_stack := xs | _ -> ()

(******************************************************************************)
(*********************************** Logging **********************************)
(******************************************************************************)

let logChannel   = ref stdout
let logFormatter = ref (Format.formatter_of_out_channel stdout)

let setLogChannel lc =
  logChannel   := lc;
  logFormatter := Format.formatter_of_out_channel lc

let logPrintf a  = Format.fprintf !logFormatter a
let cLogPrintf l = if ck_olev l then logPrintf else nprintf

(*****************************************************************)
(*********** Command Line Options ********************************)
(*****************************************************************)

(* taken from dsolve/liquid/liquid.ml *)

let arg_spec = 
  [("-out", 
    Arg.String (fun s -> out_file := s), 
    " Save solution to file [out]"); 
   ("-save", 
    Arg.String (fun s -> save_file := s), 
    " Save constraints to file [out.fq]"); 
   ("-inccheck", 
    Arg.String (fun s -> true_unconstrained := false; 
                         inccheck := SS.add s !inccheck), 
    " Incrementally check the specified function"); 
   ("-noslice",
   Arg.Clear slice,
   " Compute fixpoint for all kvars, not just those affecting property"); 
   ("-nolfp",
   Arg.Clear lfp,
   " Weaken environment (do not produce least fixed-point solution)"); 
   ("-origdeps",
     Arg.Clear adjdeps,
     " Don't adjust constraint dependencies [true]");
   ("-dropcalls",
     Arg.Set dropcalls,
     " Ignore function calls during consgen [false]");
   ("-drconstr", 
    Arg.Set dump_ref_constraints, 
    " Dump refinement constraints [false]");
   ("-strictsortcheck",
    Arg.Set strictsortcheck,
    " Strict Sort Checking -- e.g. ptr/int comparisons -- for non-C constraints
    [false]");
   ("-ctypes",
    Arg.Set ctypes_only,
    " Infer ctypes only [false]");
   ("-safe", 
    Arg.Set safe, 
    " run in failsafe mode [false]");
   ("-manual",
    Arg.Set manual,
    " only verify manually-inserted checks");
   ("-fastscalar",
    Arg.Set fastscalar,
    " use new (experimental) fastscalar solver, eventually will be default"); 
   ("-minquals",
    Arg.Set minquals,
    " minimize qualifiers by using pre-computed one-level implication ");
   ("-timeout",
    Arg.Set_int timeout,
    " limit total time (in seconds, default no limit)");
   ("-ptag", 
    Arg.Set ptag, 
    " prioritize constraints using lexico-ordering on tags [true]");
   ("-genspec", 
    Arg.Set genspec, 
    " Generate spec file only [false]");
   ("-root",
    Arg.String (fun s -> root := s),
    " Use root function []");
   ("-psimple", 
    Arg.Set psimple, 
    " prioritize simple constraints [true]");
   ("-dgraph", 
    Arg.Set dump_graph, 
    " dump constraints SCC to constraints.dot [false]");
   ("-sortedquals",
    Arg.Set sorted_quals,
    " use sorted parameters in the qualifiers, to speed up instantiation. Should
      become default after vetting.");
    ("-refinesort",
    Arg.Set refine_sort,
    " use sortchecking to refine constraints -- and toss out badly instantiated quals. 
      Shouldn't need except for backward compatibility with dsolve constraints, DONT USE!");
   ("-sortedquals",
    Arg.Set sorted_quals,
    " RLG: missing switch required by liquidc/fixpoint, I don't know what it does");
   ("-notruekvars",
    Arg.Clear true_unconstrained,
    " don't true unconstrained kvars [true]");
   ("-v", Arg.Int (fun c -> verbose_level := c), 
              " <level> Set degree of analyzer verbosity:\n\
               \032    0      No output\n\
               \032    1      +Verbose errors\n\
               \032    [2]    +Verbose stats, timing\n\
               \032    3      +Print normalized source\n\
               \032    11     +Verbose solver\n\
               \032    13     +Dump constraint graph\n\
               \032    64     +Drowning in output");
   ("-latex", 
    Arg.String (fun s -> 
		  let l = String.length s in
		    if l = 0 || String.sub s (l-4) 4 <> ".tex" then
		      print_endline "-latex: invalid parameter"
		    else
		      latex_file := Some s),
    " translates constraints to LaTeX file"
   );
   ("-armc", 
    Arg.String (fun s -> 
		  let l = String.length s in
		    if l = 0 then
		      print_endline "-armc: invalid parameter"
		    else
		      armc_file := Some s),
    " translate constraints to ARMC file"
   );
   ("-horn", 
    Arg.String (fun s -> 
		  let l = String.length s in
		    if l = 0 then
		      print_endline "-rules: invalid parameter"
		    else
		      horn_file := Some s),
    " translate constraints to Horn clauses"
   );
   ("-raw-horn", 
    Arg.String (fun s -> 
		  let l = String.length s in
		    if l = 0 then
		      print_endline "-rules: invalid parameter"
		    else
		      raw_horn_file := Some s),
    " translate constraints to raw Horn clauses"
   );
   ("-qarmc", 
    Arg.String (fun s -> 
		  let l = String.length s in
		    if l = 0 then
		      print_endline "-qarmc: invalid parameter"
		    else
		      q_armc_file := Some s),
    " translate constraints to Q'ARMC file"
   );
   ("-dot", 
    Arg.String (fun s -> 
		  let l = String.length s in
		    if l = 0 || String.sub s (l-4) 4 <> ".dot" then
		      print_endline "-dot: invalid parameter"
		    else
		      dot_file := Some s),
    " translate constraints to dot file"
   );
   ("-keep-uif", 
    Arg.Clear purify_function_application,
    " do not replace function terms by existentially quantified variables"
   );
   ("-no-simplify-t", 
    Arg.Clear simplify_t,
    " do not simplify constraints"
   );
   ("-simplify-t", 
    Arg.Set simplify_t,
    " simplify constraints"
   );
   ("-libpath",
    Arg.String (fun s -> lib_path := s), 
    (" library path for default spec, quals ["^(!lib_path)^"]")
   );
   ("-nop",
    Arg.Set do_nothing,
    " do nothing (useful for regression tests known to be broken)";
   );
   ("-imp",
    Arg.Set dump_imp,
    " print constraints as IMP program (experimental)"
   );
   ("-prunelive",
    Arg.Set prune_live,
    " Restrict liquid types to live variables (experimental)"
   ); 
   ("-simp",
    Arg.String ((:=) dump_simp),
    " print simplified constraints to save-file (experimental) use [andrey] or [jhala] or [id]"
   );
   ("-print-nontriv",
    Arg.Set (print_nontriv),
    " print non-trivial bindings in each environment [false]"
   );
   ("-trace-scalar",
    Arg.Set(trace_scalar),
    " print constraints and index values in the Index solver");
   ("-check-indices",
    Arg.Set(check_is),
    " sanity check computed indices");
   ("-prune-index",
    Arg.Set(prune_index),
    " use the index domain to prune initial solution");
  ]


let is_prefix p s = 
  let reg = Str.regexp p in
  Str.string_match reg s 0

(****************************** CIL Specific ********************************)

let is_pure_function s =
  s = "validptr" || 
  s = "lcc_assert" || 
  s = "lcc_assume"

let is_cil_tempvar s = 
  Misc.is_prefix "__cil_tmp" s || 
  Misc.is_prefix "mem_" s

let suffix_of_fn = fun fn -> "_" ^ fn

let rename_local = fun fn vn -> vn ^ (suffix_of_fn fn)

let unrename_local fn vn = 
  let s = suffix_of_fn fn in 
  if not (Misc.is_suffix s vn) then vn else 
    String.sub vn 0 (String.length vn - (String.length s))

(******************************************************************)
(*************** Paths for builtin specs, quals etc ***************)
(******************************************************************)

let get_lib_squals      = fun () -> Filename.concat !lib_path "lib.squals"
let get_lib_hquals      = fun () -> Filename.concat !lib_path "lib.hquals"
let get_lib_spec        = fun () -> Filename.concat !lib_path "lib.spec"
let get_lib_h           = fun () -> Filename.concat !lib_path "lib.h"
let get_liquidc_h       = fun () -> Filename.concat !lib_path "../lib/liquidc.h"

