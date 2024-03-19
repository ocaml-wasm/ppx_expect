open! Base
open! Import

let chop_if_exists ~ancestor ~from:path =
  String.chop_prefix_if_exists path ~prefix:(ancestor ^ "/")
;;

let f
  ?(use_dot_patdiff = false)
  ?corrected_path
  ?(use_color = false)
  ?diff_command
  ?diff_path_prefix
  ~next_contents
  ~path
  ()
  =
  let prev_contents =
    if Stdlib.Sys.file_exists path
    then Stdio.In_channel.with_file path ~f:Stdio.In_channel.input_all
    else ""
  in
  match String.( = ) prev_contents next_contents with
  | true ->
    (* It's possible for stale .corrected files to linger and ideally we would delete them
       here, but this probably isn't worth fixing since it's mooted by dune, which puts
       its build products in a separate directory. If we do add deletion at some point in
       the future, we should make sure it doesn't cause problems for clients who call [f]
       and then perform deletion on their own. *)
    Ok ()
  | false ->
    let default_corrected_path = path ^ ".corrected" in
    let corrected_path = Option.value corrected_path ~default:default_corrected_path in
    Stdio.Out_channel.write_all corrected_path ~data:next_contents;
    let extra_patdiff_args =
      let default_configs =
        match use_dot_patdiff && Option.is_none (Sys.getenv "TESTING_FRAMEWORK") with
        | true -> []
        | false -> [ "-default" ]
      in
      let cwd = Stdlib.Sys.getcwd () in
      (* diff_path_prefix is useful to transform output paths to make it easier for the
         consumer (e.g. editor) to locate the files with diffs. One particular example this
         helps is the "test-this-file" rules generated by emacs/vscode in jenga/start/jbuild,
         where the rule and the test are in different directories. *)
      let prefix =
        match diff_path_prefix with
        | Some prefix -> String.rstrip ~drop:(Char.equal '/') prefix ^ "/"
        | None -> ""
      in
      let alt_old = [ "-alt-old"; prefix ^ chop_if_exists ~ancestor:cwd ~from:path ] in
      let alt_new =
        [ "-alt-new"; prefix ^ chop_if_exists ~ancestor:cwd ~from:default_corrected_path ]
      in
      [ default_configs; alt_old; alt_new ] |> List.concat
    in
    Ppxlib_print_diff.print
      ?diff_command
      ~use_color
      ~extra_patdiff_args
      ~file1:path
      ~file2:corrected_path
      ();
    Error (Error.of_string "Changes found.")
;;
