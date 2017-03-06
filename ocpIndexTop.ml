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

let () =
  Hashtbl.add
    Toploop.directive_table
    "doc"
    (Toploop.Directive_ident (fun lident ->
         let s = Longident.flatten lident |> String.concat "." in
         match Lazy.force (LibIndex.get index s).LibIndex.doc with
         | Some doc ->
           print_endline doc
         | None ->
           Printf.printf "No documentation found for %s\n" s
         | exception Not_found ->
           print_endline "Unknown element."))
