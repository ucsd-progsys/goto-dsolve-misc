(**************************************************************)
(*************** Unit Test For Time Modules *******************)
(**************************************************************)

open Misc.Ops

let rec pause n = if n > 0 then pause (n-1) 

let rec sim n c b t = 
  if n > 0 then begin
    Timer.log_event t (Some ("downtick "^(string_of_int n))); 
    pause b; sim (n-1) c (c*b) t
  end

let c = try Sys.argv.(1) |> int_of_string with _ -> 2
let _ = Timer.create "boo" 
        >> sim 8 c 9999999 
        |> Format.printf "%a" Timer.print 
