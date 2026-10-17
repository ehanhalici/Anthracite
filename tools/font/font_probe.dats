#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "os/fs.sats"
staload "data_font/sfnt/sfnt.sats"

fun probe(face: !SfntFace, cp: int): void = let
  val gid = sfnt_glyph(face,cp)
  val metric = sfnt_glyph_metrics(face,gid)
in println!("event=font_metric cp=",cp," gid=",gid,
  " advance=",metric.advance," bearing=",metric.bearing) end

fun probes(face: !SfntFace): void = let
  val () = probe(face,65)
  val () = probe(face,304)
  val () = probe(face,351)
  val () = probe(face,1576)
  val () = probe(face,1614)
  val () = probe(face,1615)
  val () = probe(face,64830)
in probe(face,64831) end

fun error_code(error: SfntError): string = case+ error of
  | SfntIo(code) => "io" | SfntDirectory() => "directory" | SfntContainer() => "container"
  | SfntOutline() => "outline" | SfntVariable() => "variable"
  | SfntMetrics() => "metrics" | SfntCharacterMap() => "cmap" | SfntLocations() => "loca"

fun run(path: string): int = case+ sfnt_open(path) of
  | ~RejectedSfnt(error) => let
      val () = println!("event=font_probe status=rejected reason=",error_code(error))
    in 1 end
  | ~LoadedSfnt(face) => let
      val info = sfnt_info(face)
      val () = println!("event=font_probe status=accepted units=",info.units," glyphs=",info.glyphs)
      val () = probes(face)
      val () = sfnt_dispose(face)
    in 0 end

implement main0() =
  if ine(c_argc(),2) then exit(2) else if igt(run(c_argv(1)),0) then exit(1) else ()
