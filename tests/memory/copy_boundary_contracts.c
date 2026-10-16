#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include "mem.cats"

enum { FIXTURE_BYTES = 16 };
typedef struct {
  int source_capacity, target_capacity, source_offset, target_offset, length;
} CopyCase;

static int valid_range(int capacity, int offset, int length) {
  return offset >= 0 && length > 0 && (int64_t)offset + length <= capacity;
}

static int check_copy(CopyCase c) {
  unsigned char source[FIXTURE_BYTES], target[FIXTURE_BYTES], expected[FIXTURE_BYTES];
  for (int i = 0; i < FIXTURE_BYTES; ++i) source[i] = (unsigned char)(i + 1);
  memset(expected, 0, sizeof(expected));
  if (valid_range(c.source_capacity, c.source_offset, c.length) &&
      valid_range(c.target_capacity, c.target_offset, c.length))
    memcpy(expected + c.target_offset, source + c.source_offset, (size_t)c.length);
  memset(target, 0, sizeof(target));
  anth_buf_copy(target, c.target_capacity, c.target_offset,
    source, c.source_capacity, c.source_offset, c.length);
  int errors = memcmp(target, expected, sizeof(target)) != 0;
  memset(target, 0, sizeof(target));
  anth_copy_to_ptr(source, c.source_capacity, c.source_offset,
    target, c.target_capacity, c.target_offset, c.length);
  return errors + (memcmp(target, expected, sizeof(target)) != 0);
}

static int offset_cases(int source_capacity, int target_capacity) {
  const int lengths[] = {-1, 0, 1, 4, FIXTURE_BYTES, FIXTURE_BYTES + 1, INT_MAX};
  int errors = 0;
  for (int source = -1; source <= FIXTURE_BYTES + 1; ++source)
    for (int target = -1; target <= FIXTURE_BYTES + 1; ++target)
      for (size_t i = 0; i < sizeof(lengths) / sizeof(lengths[0]); ++i) {
        CopyCase c = {source_capacity, target_capacity, source, target, lengths[i]};
        errors += check_copy(c);
      }
  return errors;
}

static int capacity_cases(void) {
  const int capacities[] = {INT_MIN, -1, 0, 1, 4, FIXTURE_BYTES};
  int errors = 0;
  for (size_t source = 0; source < sizeof(capacities) / sizeof(capacities[0]); ++source)
    for (size_t target = 0; target < sizeof(capacities) / sizeof(capacities[0]); ++target)
      errors += offset_cases(capacities[source], capacities[target]);
  return errors;
}

static int overlap_case(void) {
  unsigned char actual[FIXTURE_BYTES], expected[FIXTURE_BYTES];
  for (int i = 0; i < FIXTURE_BYTES; ++i) actual[i] = expected[i] = (unsigned char)i;
  memmove(expected + 4, expected, 8);
  anth_buf_copy(actual, FIXTURE_BYTES, 4, actual, FIXTURE_BYTES, 0, 8);
  return memcmp(actual, expected, sizeof(actual)) != 0;
}

int main(void) {
  CopyCase overflow = {FIXTURE_BYTES, FIXTURE_BYTES, 0, 8, INT_MAX};
  int errors = check_copy(overflow);
  CopyCase source_overflow = {FIXTURE_BYTES, FIXTURE_BYTES, 8, 0, INT_MAX};
  errors += check_copy(source_overflow);
  CopyCase huge_offset = {FIXTURE_BYTES, FIXTURE_BYTES, INT_MAX, INT_MAX, 1};
  errors += check_copy(huge_offset);
  errors += capacity_cases() + overlap_case();
  printf("event=copy_boundary_contracts errors=%d\n", errors);
  return errors ? 1 : 0;
}
