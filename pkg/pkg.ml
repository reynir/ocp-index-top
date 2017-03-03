#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let () =
  Pkg.describe "ocp-index-top" @@ fun c ->
  Ok [
    Pkg.mllib ~api:[] "ocp-index-top.mllib";
  ]
