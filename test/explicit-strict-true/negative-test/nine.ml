(* Show that, when compiling with [-expect-test-strict-indentation=true], test blocks
   that match the output modulo indentation, but are not themselves formatted according to
   the indentation rules, are corrected. *)

let%expect_test _ =
  let module _ = struct
    let () =
      print_string "hello";
      [%expect
        {|
                                              hello
                                            |}]
    ;;

    let () =
      print_string "hello\n";
      [%expect
        {|
                                              hello
                                            |}]
    ;;

    let () =
      print_string "hello\n\n";
      [%expect
        {|
                                              hello

                                            |}]
    ;;

    let () =
      print_string "\nhello";
      [%expect {|

                                              hello|}]
    ;;

    let () =
      print_string "\nhello\n";
      [%expect
        {|

                                              hello
                                            |}]
    ;;

    let () =
      print_string "\nhello\n\n";
      [%expect
        {|

                                              hello

                                            |}]
    ;;

    let () =
      print_string "\n\nhello";
      [%expect {|


                                              hello|}]
    ;;

    let () =
      print_string "\n\nhello\n";
      [%expect
        {|


                                              hello
                                            |}]
    ;;

    let () =
      print_string "\n\nhello\n\n";
      [%expect
        {|


                                              hello

                                            |}]
    ;;
  end
  in
  ()
;;
