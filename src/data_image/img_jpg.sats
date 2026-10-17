staload "mem.sats"

(* Success: positive dimensions and width * height * 4 RGBA bytes in buf_len.
   Failure: both dimensions and buf_len are zero; the caller still frees Buf.
   Supported: 8-bit Huffman SOF0/SOF1/SOF2, up to 8192 pixels per dimension.
   No production C JPEG fallback is called. *)
fun decode_jpg(src: !Buf, wout: &int >> _, hout: &int >> _): Buf
fun make_jpg(): Buf
