#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let cmd c os files =
  OS.Cmd.run Cmd.(Pkg.build_cmd c os %% v "-plugin-tag" %% v "package(cppo_ocamlbuild)" %% of_list files)

let () =
  Pkg.describe "ocp-index-top" ~build:(Pkg.build ~cmd ()) @@ fun c ->
  Ok [
    Pkg.mllib ~api:[] "ocp-index-top.mllib";
  ]
