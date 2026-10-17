#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_image/img_jpg.sats"

macdef JPEG_TEST_RGBA_CHANNELS = 4

%{#
#include "image/jpg_oracle_c.cats"
%}

extern fun oracle_c_decode(buf: ptr, len: int, w: &int >> _, h: &int >> _): ptr = "mac#oracle_c_decode"
extern fun oracle_c_free(p: ptr): void = "mac#oracle_c_free"
extern fun oracle_c_is_null(p: ptr): int = "mac#oracle_c_is_null"
extern fun oracle_c_byte_at(p: ptr, i: int): int = "mac#oracle_c_byte_at"
extern fun oracle_c_print_result(name: string, ok: int): void = "mac#oracle_c_print_result"
extern fun oracle_c_print_fixture(path: string, errors: int): void = "mac#oracle_c_print_fixture"

fun compare_pixels {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), ats_px: !Buf, c_px: ptr, total_bytes: int, i: int, diffs: int
): int =
  if recfuel > 0 then (
    if ige(i, total_bytes) then diffs
    else let
      val b_ats = buf_get(ats_px, i)
      val b_c = oracle_c_byte_at(c_px, i)
      val d = if b_ats <> b_c then 1 else 0
    in
      compare_pixels(recfuel - 1, ats_px, c_px, total_bytes, iadd(i, 1), iadd(diffs, d))
    end
  ) else (if ige(i, total_bytes) then diffs else 1)

fun compare_decoded_output(px_ats: !Buf, px_c: ptr, wa: int, ha: int, wc: int, hc: int): int = let
  val dimensions_ok = ieq(wa, wc) andalso ieq(ha, hc) andalso igt(wa, 0) andalso igt(ha, 0)
  val total_bytes = imul(imul(wa, ha), JPEG_TEST_RGBA_CHANNELS)
  val storage_ok = ieq(buf_len(px_ats), total_bytes) andalso ige(buf_cap(px_ats), total_bytes)
in
  if not(dimensions_ok) orelse not(storage_ok) orelse oracle_c_is_null(px_c) <> 0 then let
    val () = println!("event=jpeg_oracle status=invalid_output ats=", wa, "x", ha, " c=", wc, "x", hc, " len=", buf_len(px_ats))
  in 1 end
  else let
    val diffs = compare_pixels(airlock_span(0, total_bytes), px_ats, px_c, total_bytes, 0, 0)
    val () = if diffs > 0 then println!("event=jpeg_oracle differing_bytes=", diffs) else ()
  in if diffs > 0 then 1 else 0 end
end

fun run_oracle_comparison(src: !Buf): int = let
  val live_start = mem_live()
  var w_ats: int = 0 and h_ats: int = 0
  val px_ats = decode_jpg(src, w_ats, h_ats)
  var w_c: int = 0 and h_c: int = 0
  val px_c = oracle_c_decode(buf_ptr(src), buf_len(src), w_c, h_c)
  val error = compare_decoded_output(px_ats, px_c, w_ats, h_ats, w_c, h_c)
  val () = buf_free(px_ats)
  val () = oracle_c_free(px_c)
in
  if error > 0 orelse live_start <> mem_live() then 1 else 0
end

fun test_baseline_fixture(): int = let
  val src = make_jpg()
  val err = run_oracle_comparison(src)
  val () = buf_free(src)
in err end

fun read_fixture_file(path: string): Buf = let
  val sz = fs_size(path)
in
  if sz <= 0 then buf_make(4)
  else let
    val fd = fs_open_read(path)
  in
    if fd < 0 then buf_make(4)
    else let
      val b = buf_make(sz)
      val n = fs_read_buf(fd, b, sz)
      val () = fs_close(fd)
      val () = buf_set_len(b, n)
    in b end
  end
end

fun load_progressive_buf(): Buf = let
  val sz1 = fs_size("tests/fixtures/progressive.jpg")
in
  if sz1 > 0 then read_fixture_file("tests/fixtures/progressive.jpg")
  else read_fixture_file("../tests/fixtures/progressive.jpg")
end

fun test_progressive_fixture(): int = let
  val src = load_progressive_buf()
in
  if buf_len(src) < 100 then let
    val () = buf_free(src)
  in 1 end
  else let
    val err = run_oracle_comparison(src)
    val () = buf_free(src)
  in err end
end

fun test_rejected_input(src: !Buf): int = let
  val live_start = mem_live()
  var width: int = 123 and height: int = 456
  val pixels = decode_jpg(src, width, height)
  val rejected = ieq(width, 0) andalso ieq(height, 0) andalso ieq(buf_len(pixels), 0)
  val () = buf_free(pixels)
in
  if rejected andalso ieq(live_start, mem_live()) then 0 else 1
end

fun test_fixture_path(path: string, reject: bool): int = let
  val src = read_fixture_file(path)
  val errors: int = if buf_len(src) <= 0 then 1 else
    (if reject then test_rejected_input(src) else run_oracle_comparison(src))
  val () = buf_free(src)
  val () = oracle_c_print_fixture(path, errors)
in errors end

fun test_default_fixtures(): int = let
  val err1 = test_baseline_fixture()
  val () = oracle_c_print_result("oracle_baseline_match", if ieq(err1, 0) then 1 else 0)
  val err2 = test_progressive_fixture()
  val () = oracle_c_print_result("oracle_progressive_match", if ieq(err2, 0) then 1 else 0)
in iadd(err1, err2) end

implement main0(argc, argv) = let
  val errors: int = if argc = 1 then test_default_fixtures()
    else if argc = 2 then test_fixture_path(argv[1], false)
    else if argc = 3 then
      (if argv[1] = "reject" then test_fixture_path(argv[2], true) else 1)
    else 1
in
  if igt(errors, 0) then exit(1) else exit(0)
end
