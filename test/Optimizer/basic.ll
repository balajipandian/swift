; RUN: %swift %s -arc-optimize | FileCheck %s
target datalayout = "e-p:64:64:64-S128-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f16:16:16-f32:32:32-f64:64:64-f128:128:128-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
target triple = "x86_64-apple-darwin11.3.0"

%swift.refcounted = type { %swift.heapmetadata*, i64 }
%swift.heapmetadata = type { i64 (%swift.refcounted*)*, i64 (%swift.refcounted*)* }

declare %swift.refcounted* @swift_allocObject(%swift.heapmetadata* , i64, i64) nounwind
declare void @swift_release(%swift.refcounted* nocapture)
declare %swift.refcounted* @swift_retain(%swift.refcounted* ) nounwind
declare void @swift_retain_noresult(%swift.refcounted* nocapture) nounwind


define void @trivial_retain_release(%swift.refcounted* %P) {
entry:
  tail call void @swift_retain_noresult(%swift.refcounted* %P)
  tail call void @swift_release(%swift.refcounted* %P) nounwind
  ret void
}

; CHECK: @trivial_retain_release(
; CHECK-NEXT: entry:
; CHECK-NEXT: ret void


; rdar://11542743
define i64 @max_test(i64 %x) nounwind {
entry:
  %0 = tail call noalias %swift.refcounted* @swift_allocObject(%swift.heapmetadata* null, i64 24, i64 8) nounwind
  %1 = tail call %swift.refcounted* @swift_retain(%swift.refcounted* %0) nounwind
  tail call void @swift_release(%swift.refcounted* %0) nounwind
  %2 = icmp sgt i64 %x, 0
  %x.y.i = select i1 %2, i64 %x, i64 0
  %3 = tail call %swift.refcounted* @swift_retain(%swift.refcounted* %1) nounwind
  tail call void @swift_release(%swift.refcounted* %3) nounwind
  tail call void @swift_release(%swift.refcounted* %1) nounwind
  ret i64 %x.y.i
}
; CHECK: @max_test
; CHECK-NEXT: entry:
; CHECK-NEXT: icmp
; CHECK-NEXT: select
; CHECK-NEXT: ret


; rdar://11563395 - 
define { i8*, i64, %swift.refcounted* } @retain3_test1(i8*, i64, %swift.refcounted*) nounwind {
entry:
  %3 = call %swift.refcounted* @swift_retain(%swift.refcounted* %2)
  %4 = insertvalue { i8*, i64, %swift.refcounted* } undef, i8* %0, 0
  %5 = insertvalue { i8*, i64, %swift.refcounted* } %4, i64 %1, 1
  %6 = insertvalue { i8*, i64, %swift.refcounted* } %5, %swift.refcounted* %3, 2
  ret { i8*, i64, %swift.refcounted* } %6
}

; CHECK: @retain3_test1
; CHECK: swift_retainAndReturnThree
; CHECK: ret
