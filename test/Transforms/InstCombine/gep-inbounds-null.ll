; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -S < %s -instcombine | FileCheck %s

;; Start by showing the results of constant folding (which doesn't use
;; the poison implied by gep for the nonnull cases).

define i1 @test_ne_constants_null() {
; CHECK-LABEL: @test_ne_constants_null(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i1 false
;
entry:
  %gep = getelementptr inbounds i8, i8* null, i64 0
  %cnd = icmp ne i8* %gep, null
  ret i1 %cnd
}

define i1 @test_ne_constants_nonnull() {
; CHECK-LABEL: @test_ne_constants_nonnull(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i1 true
;
entry:
  %gep = getelementptr inbounds i8, i8* null, i64 1
  %cnd = icmp ne i8* %gep, null
  ret i1 %cnd
}

define i1 @test_eq_constants_null() {
; CHECK-LABEL: @test_eq_constants_null(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i1 true
;
entry:
  %gep = getelementptr inbounds i8, i8* null, i64 0
  %cnd = icmp eq i8* %gep, null
  ret i1 %cnd
}

define i1 @test_eq_constants_nonnull() {
; CHECK-LABEL: @test_eq_constants_nonnull(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i1 false
;
entry:
  %gep = getelementptr inbounds i8, i8* null, i64 1
  %cnd = icmp eq i8* %gep, null
  ret i1 %cnd
}

;; Then show the results for non-constants.  These use the inbounds provided
;; UB fact to ignore the possible overflow cases.

define i1 @test_ne(i8* %base, i64 %idx) {
; CHECK-LABEL: @test_ne(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CND:%.*]] = icmp ne i8* [[BASE:%.*]], null
; CHECK-NEXT:    ret i1 [[CND]]
;
entry:
  %gep = getelementptr inbounds i8, i8* %base, i64 %idx
  %cnd = icmp ne i8* %gep, null
  ret i1 %cnd
}

define i1 @test_eq(i8* %base, i64 %idx) {
; CHECK-LABEL: @test_eq(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CND:%.*]] = icmp eq i8* [[BASE:%.*]], null
; CHECK-NEXT:    ret i1 [[CND]]
;
entry:
  %gep = getelementptr inbounds i8, i8* %base, i64 %idx
  %cnd = icmp eq i8* %gep, null
  ret i1 %cnd
}

;; TODO: vectors not yet handled
define <2 x i1> @test_vector_base(<2 x i8*> %base, i64 %idx) {
; CHECK-LABEL: @test_vector_base(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr inbounds i8, <2 x i8*> [[BASE:%.*]], i64 [[IDX:%.*]]
; CHECK-NEXT:    [[CND:%.*]] = icmp eq <2 x i8*> [[GEP]], zeroinitializer
; CHECK-NEXT:    ret <2 x i1> [[CND]]
;
entry:
  %gep = getelementptr inbounds i8, <2 x i8*> %base, i64 %idx
  %cnd = icmp eq <2 x i8*> %gep, zeroinitializer
  ret <2 x i1> %cnd
}

define <2 x i1> @test_vector_index(i8* %base, <2 x i64> %idx) {
; CHECK-LABEL: @test_vector_index(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr inbounds i8, i8* [[BASE:%.*]], <2 x i64> [[IDX:%.*]]
; CHECK-NEXT:    [[CND:%.*]] = icmp eq <2 x i8*> [[GEP]], zeroinitializer
; CHECK-NEXT:    ret <2 x i1> [[CND]]
;
entry:
  %gep = getelementptr inbounds i8, i8* %base, <2 x i64> %idx
  %cnd = icmp eq <2 x i8*> %gep, zeroinitializer
  ret <2 x i1> %cnd
}

define <2 x i1> @test_vector_both(<2 x i8*> %base, <2 x i64> %idx) {
; CHECK-LABEL: @test_vector_both(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr inbounds i8, <2 x i8*> [[BASE:%.*]], <2 x i64> [[IDX:%.*]]
; CHECK-NEXT:    [[CND:%.*]] = icmp eq <2 x i8*> [[GEP]], zeroinitializer
; CHECK-NEXT:    ret <2 x i1> [[CND]]
;
entry:
  %gep = getelementptr inbounds i8, <2 x i8*> %base, <2 x i64> %idx
  %cnd = icmp eq <2 x i8*> %gep, zeroinitializer
  ret <2 x i1> %cnd
}

;; These two show instsimplify's reasoning getting to the non-zero offsets
;; before instcombine does.

define i1 @test_eq_pos_idx(i8* %base) {
; CHECK-LABEL: @test_eq_pos_idx(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i1 false
;
entry:
  %gep = getelementptr inbounds i8, i8* %base, i64 1
  %cnd = icmp eq i8* %gep, null
  ret i1 %cnd
}

define i1 @test_eq_neg_idx(i8* %base) {
; CHECK-LABEL: @test_eq_neg_idx(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i1 false
;
entry:
  %gep = getelementptr inbounds i8, i8* %base, i64 -1
  %cnd = icmp eq i8* %gep, null
  ret i1 %cnd
}

;; Show an example with a zero sized type since that's
;; a cornercase which keeps getting mentioned.  The GEP
;; produces %base regardless of the value of the index
;; expression.
define i1 @test_size0({}* %base, i64 %idx) {
; CHECK-LABEL: @test_size0(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CND:%.*]] = icmp ne {}* [[BASE:%.*]], null
; CHECK-NEXT:    ret i1 [[CND]]
;
entry:
  %gep = getelementptr inbounds {}, {}* %base, i64 %idx
  %cnd = icmp ne {}* %gep, null
  ret i1 %cnd
}
define i1 @test_size0_nonzero_offset({}* %base) {
; CHECK-LABEL: @test_size0_nonzero_offset(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CND:%.*]] = icmp ne {}* [[BASE:%.*]], null
; CHECK-NEXT:    ret i1 [[CND]]
;
entry:
  %gep = getelementptr inbounds {}, {}* %base, i64 15
  %cnd = icmp ne {}* %gep, null
  ret i1 %cnd
}


define i1 @test_index_type([10 x i8]* %base, i64 %idx) {
; CHECK-LABEL: @test_index_type(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CND:%.*]] = icmp eq [10 x i8]* [[BASE:%.*]], null
; CHECK-NEXT:    ret i1 [[CND]]
;
entry:
  %gep = getelementptr inbounds [10 x i8], [10 x i8]* %base, i64 %idx, i64 %idx
  %cnd = icmp eq i8* %gep, null
  ret i1 %cnd
}


;; Finally, some negative tests for sanity checking.

define i1 @neq_noinbounds(i8* %base, i64 %idx) {
; CHECK-LABEL: @neq_noinbounds(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr i8, i8* [[BASE:%.*]], i64 [[IDX:%.*]]
; CHECK-NEXT:    [[CND:%.*]] = icmp ne i8* [[GEP]], null
; CHECK-NEXT:    ret i1 [[CND]]
;
entry:
  %gep = getelementptr i8, i8* %base, i64 %idx
  %cnd = icmp ne i8* %gep, null
  ret i1 %cnd
}

define i1 @neg_objectatnull(i8 addrspace(2)* %base, i64 %idx) {
; CHECK-LABEL: @neg_objectatnull(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr inbounds i8, i8 addrspace(2)* [[BASE:%.*]], i64 [[IDX:%.*]]
; CHECK-NEXT:    [[CND:%.*]] = icmp eq i8 addrspace(2)* [[GEP]], null
; CHECK-NEXT:    ret i1 [[CND]]
;
entry:
  %gep = getelementptr inbounds i8, i8 addrspace(2)* %base, i64 %idx
  %cnd = icmp eq i8 addrspace(2)* %gep, null
  ret i1 %cnd
}
