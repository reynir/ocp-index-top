let cmd_input_line cmd =
  try
    let ic = Unix.open_process_in (cmd ^ " 2>/dev/null") in
    let r = input_line ic in
    let r =
      let len = String.length r in
      if len>0 && r.[len - 1] = '\r' then String.sub r 0 (len-1) else r
    in
    match Unix.close_process_in ic with
    | Unix.WEXITED 0 -> r
    | _ -> failwith "cmd_input_line"
  with
  | End_of_file | Unix.Unix_error _ | Sys_error _ -> failwith "cmd_input_line"

let stdlib_dir = Config.standard_library

let opamlib_dir =
  cmd_input_line "opam config var lib"

let opamlib_dirs =
  LibIndex.Misc.unique_subdirs [opamlib_dir]

let lib_dirs = stdlib_dir :: opamlib_dirs

let index = LibIndex.load lib_dirs

let mk_resolver find lident =
  let env = !Toploop.toplevel_env in
    try
      let path = find lident env in
      Some (Path.name path)
    with Not_found ->
      None

let resolve_type =
#if OCAML_VERSION < (4, 4, 0)
  mk_resolver (fun lident env -> fst (Env.lookup_type lident env))
#else
  mk_resolver (fun lident env -> Env.lookup_type lident env)
#endif

let resolve_value =
  mk_resolver (fun lident env -> fst (Env.lookup_value lident env))

let resolve_module =
  mk_resolver (Env.lookup_module ~load:true)

let resolve_modtype =
  mk_resolver (fun lident env -> fst (Env.lookup_modtype lident env))

let resolve_class =
  mk_resolver (fun lident env -> fst (Env.lookup_class lident env))

let resolve_cltype =
  mk_resolver (fun lident env -> fst (Env.lookup_cltype lident env))

let resolvers = [
  resolve_type;
  resolve_value;
  resolve_module;
  resolve_modtype;
  resolve_class;
  resolve_cltype
]

let resolve_all : (Longident.t -> string option) list -> Longident.t -> string =
  fun fs lident ->
    match List.fold_right
            (fun f acc ->
               match acc with
               | Some _ -> acc
               | None -> f lident)
            fs
            None
    with
    | Some s -> s
    | None -> Longident.flatten lident |> String.concat "."

let mk_directive resolver =
  Toploop.Directive_ident (fun lident ->
      let s = resolver lident in
      match Lazy.force (LibIndex.get index s).LibIndex.doc with
      | Some doc ->
        print_endline doc
      | None ->
        Printf.printf "No documentation found for %s\n" s
      | exception Not_found ->
        print_endline "Unknown element.")


let () =
  Hashtbl.add
    Toploop.directive_table
    "doc"
    (mk_directive (resolve_all resolvers))

let () =
  Hashtbl.add
    Toploop.directive_table
    "doc_type"
    (mk_directive (resolve_all [resolve_type]))

let () =
  Hashtbl.add
    Toploop.directive_table
    "doc_val"
    (mk_directive (resolve_all [resolve_value]))

let () =
  Hashtbl.add
    Toploop.directive_table
    "doc_module"
    (mk_directive (resolve_all [resolve_module]))

let () =
  Hashtbl.add
    Toploop.directive_table
    "doc_module_type"
    (mk_directive (resolve_all [resolve_modtype]))

let () =
  Hashtbl.add
    Toploop.directive_table
    "doc_class"
    (mk_directive (resolve_all [resolve_class]))

let () =
  Hashtbl.add
    Toploop.directive_table
    "doc_class_type"
    (mk_directive (resolve_all [resolve_cltype]))
