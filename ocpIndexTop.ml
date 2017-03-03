let stdlib_dir = Config.standard_library

let opamlib_dir =
  let root_dir = (OpamStateConfig.opamroot ()) in
  let Some opam_config = OpamStateConfig.load root_dir in
  OpamPath.Switch.Default.lib_dir
    root_dir
    (OpamFile.Config.switch opam_config)
  |> OpamFilename.Dir.to_string

let opamlib_dirs =
  LibIndex.Misc.unique_subdirs [opamlib_dir]

let lib_dirs = stdlib_dir :: opamlib_dirs

let index = LibIndex.load lib_dirs

let acme_client_get_crt_doc () =
  Lazy.force (LibIndex.get index "Acme.Client.get_crt").LibIndex.doc

let () =
  Hashtbl.add
    Toploop.directive_table
    "doc"
    (Toploop.Directive_string (fun s ->
         match Lazy.force (LibIndex.get index s).LibIndex.doc with
         | Some doc ->
           print_endline doc
         | None ->
           Printf.printf "No documentation found for %s\n" s
         | exception Not_found ->
           print_endline "Unknown element."))
