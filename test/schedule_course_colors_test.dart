import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seeku/features/schedule/presentation/schedule_course_colors.dart';

void main() {
  test('CourseColorPalette generates stable white-readable colors', () {
    final first = CourseColorPalette.colorForCourse('数据结构', const {});
    final second = CourseColorPalette.colorForCourse('数据结构', const {});
    final other = CourseColorPalette.colorForCourse('数据库系统', const {});

    expect(first.toARGB32(), second.toARGB32());
    expect(first.toARGB32(), isNot(other.toARGB32()));
    expect(1.05 / (first.computeLuminance() + 0.05), greaterThanOrEqualTo(4.5));

    const override = Color(0xFF247BA0);
    expect(
      CourseColorPalette.colorForCourse('数据结构', const {
        '数据结构': 0xFF247BA0,
      }).toARGB32(),
      override.toARGB32(),
    );
  });
}
