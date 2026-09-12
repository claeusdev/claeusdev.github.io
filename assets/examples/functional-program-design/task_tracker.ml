(* Companion to "Functional Program Design in OCaml: Building a Task Tracker".
   Standard library only. Tested with OCaml 5.5.

   ocamlc -o task_tracker task_tracker.ml
   ./task_tracker
   ./task_tracker --test

   Tasks live only for the current session. *)

type error =
  | Empty_title
  | Unknown_task of int
  | Invalid_command
  | Invalid_id

module Title : sig
  type t
  val make : string -> (t, error) result
  val to_string : t -> string
end = struct
  type t = string

  let make text =
    let text = String.trim text in
    if text = "" then Error Empty_title else Ok text

  let to_string title = title
end

module Tracker : sig
  type status = Open | Done
  type task = { id : int; title : Title.t; status : status }
  type t

  val empty : t
  val tasks : t -> task list
  val add : string -> t -> (t * task, error) result
  val complete : int -> t -> (t, error) result
end = struct
  type status = Open | Done
  type task = { id : int; title : Title.t; status : status }
  type t = { next_id : int; tasks : task list }

  let empty = { next_id = 1; tasks = [] }
  let tasks state = List.rev state.tasks

  let add text state =
    Result.bind (Title.make text) (fun title ->
      let task = { id = state.next_id; title; status = Open } in
      let next = { next_id = state.next_id + 1; tasks = task :: state.tasks } in
      Ok (next, task))

  let complete id state =
    match List.find_opt (fun task -> task.id = id) state.tasks with
    | None -> Error (Unknown_task id)
    | Some { status = Done; _ } -> Ok state
    | Some _ ->
        let tasks = List.map (fun task ->
          if task.id = id then { task with status = Done } else task
        ) state.tasks in
        Ok { state with tasks }
end

type command = Add of string | Complete of int | List | Quit

let split_command line =
  let line = String.trim line in
  match String.index_opt line ' ' with
  | None -> (line, "")
  | Some index ->
      let verb = String.sub line 0 index in
      let argument =
        String.sub line (index + 1) (String.length line - index - 1)
        |> String.trim
      in
      (verb, argument)

let parse line =
  match split_command line with
  | "add", title -> Ok (Add title)
  | "done", text ->
      let decimal =
        text <> "" && String.for_all (fun c -> c >= '0' && c <= '9') text
      in
      if not decimal then Error Invalid_id
      else (
        match int_of_string_opt text with
        | Some id when id > 0 -> Ok (Complete id)
        | _ -> Error Invalid_id)
  | "list", "" -> Ok List
  | "quit", "" -> Ok Quit
  | _ -> Error Invalid_command

let render_task (task : Tracker.task) =
  let marker = match task.status with Open -> " " | Done -> "x" in
  Printf.sprintf "%d. [%s] %s" task.id marker (Title.to_string task.title)

let render_tasks state =
  match Tracker.tasks state with
  | [] -> "No tasks yet."
  | tasks -> tasks |> List.map render_task |> String.concat "\n"

type outcome = Continue of Tracker.t * string | Stop

let execute command state =
  match command with
  | Add title ->
      Result.map (fun (next, task) ->
        Continue (next, Printf.sprintf "Added task %d." task.Tracker.id)
      ) (Tracker.add title state)
  | Complete id ->
      Result.map (fun next ->
        Continue (next, Printf.sprintf "Task %d is done." id)
      ) (Tracker.complete id state)
  | List -> Ok (Continue (state, render_tasks state))
  | Quit -> Ok Stop

let process_line line state =
  Result.bind (parse line) (fun command -> execute command state)

let error_message = function
  | Empty_title -> "A task title must contain text."
  | Unknown_task id -> Printf.sprintf "No task with ID %d." id
  | Invalid_command -> "Use: add <title>, done <id>, list, or quit."
  | Invalid_id -> "Use a positive task ID, such as: done 1."

let rec loop state =
  print_string "> ";
  flush stdout;
  match read_line () with
  | exception End_of_file -> print_newline ()
  | line ->
      match process_line line state with
      | Error error ->
          print_endline (error_message error);
          loop state
      | Ok (Continue (next, message)) ->
          print_endline message;
          loop next
      | Ok Stop -> print_endline "Goodbye."

(* Assertions describe observable behavior, without inspecting Tracker.t. *)
let self_test () =
  let unwrap = function
    | Ok value -> value
    | Error error -> failwith (error_message error)
  in
  let initial = Tracker.empty in
  let first, task = unwrap (Tracker.add "  Write the article  " initial) in
  let second, other = unwrap (Tracker.add "Check the examples" first) in
  let completed = unwrap (Tracker.complete task.id second) in

  assert (Tracker.tasks initial = []);
  assert (Title.to_string task.title = "Write the article");
  assert (task.id = 1 && other.id = 2);
  assert (Tracker.tasks first = [task]);
  assert (Tracker.tasks second = [task; other]);
  assert (List.map (fun (t : Tracker.task) -> t.status)
    (Tracker.tasks completed) = [Tracker.Done; Tracker.Open]);
  assert (Tracker.tasks (unwrap (Tracker.complete task.id completed))
    = Tracker.tasks completed);
  assert (Tracker.complete 99 completed = Error (Unknown_task 99));
  assert (Tracker.add " \t " second = Error Empty_title);
  let third, next_task = unwrap (Tracker.add "Review" second) in
  assert (next_task.id = 3 && List.length (Tracker.tasks third) = 3);

  assert (parse "  add   Read a paper  " = Ok (Add "Read a paper"));
  assert (parse "done 01" = Ok (Complete 1));
  List.iter (fun line -> assert (parse line = Error Invalid_id))
    ["done"; "done 0"; "done -1"; "done +1"; "done abc";
     "done 0x10"; "done 1_0"; "done 1 extra";
     "done 99999999999999999999999999999999999"];
  List.iter (fun line -> assert (parse line = Error Invalid_command))
    [""; "remove 1"; "list extra"; "quit extra"];
  assert (parse "list" = Ok List);
  assert (parse "quit" = Ok Quit);
  assert (process_line "add" initial = Error Empty_title);
  assert (process_line "done 99" second = Error (Unknown_task 99));
  assert (process_line "quit" second = Ok Stop);
  assert (process_line "list" initial = Ok (Continue (initial, "No tasks yet.")));
  assert (render_tasks completed =
    "1. [x] Write the article\n2. [ ] Check the examples");
  print_endline "All task tracker tests passed."

let () =
  match Array.to_list Sys.argv with
  | [_] ->
      print_endline "Tasks last for this session. Commands: add <title>, done <id>, list, quit.";
      loop Tracker.empty
  | [_; "--test"] -> self_test ()
  | _ ->
      prerr_endline "Usage: task_tracker [--test]";
      exit 2
