import 'class_model.dart';
import 'mark_model.dart';
import 'test_model.dart';

class StudentAcademicResult {
  final TestModel test;
  final MarkModel? mark;
  final ClassModel? classModel;

  StudentAcademicResult({
    required this.test,
    this.mark,
    this.classModel,
  });

  bool get isCancelled => test.isCancelled;
  bool get isArchived => test.isArchived;

  bool get isAbsent => mark?.isAbsent ?? false;
  double? get marksObtained => mark?.marks;
  String? get remarks => mark?.remarks;

  double get totalMarks => test.totalMarks > 0 ? test.totalMarks : 100.0;
  double? get passingMarks => test.passingMarks;

  bool get hasRecord => mark != null && mark!.markId.isNotEmpty;
  bool get hasMarksValue => !isAbsent && marksObtained != null;

  String get status {
    if (isCancelled) return 'Cancelled';
    if (isAbsent) return 'Absent';
    if (!hasMarksValue) return 'Pending';
    if (passingMarks != null) {
      return marksObtained! >= passingMarks! ? 'Pass' : 'Fail';
    }
    return (percentage >= 35.0) ? 'Pass' : 'Fail';
  }

  double get percentage {
    if (isAbsent || !hasMarksValue || totalMarks <= 0) return 0.0;
    return (marksObtained! / totalMarks) * 100.0;
  }

  String get percentageDisplay {
    if (isAbsent) return 'Absent';
    if (!hasMarksValue) return 'Pending';
    return '${percentage.toStringAsFixed(1)}%';
  }

  String get marksDisplay {
    if (isAbsent) return 'Absent';
    if (!hasMarksValue) return 'Pending';
    final obStr = marksObtained!.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    final totStr = totalMarks.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return '$obStr / $totStr';
  }
}

class SubjectAcademicSummary {
  final String subjectName;
  final List<StudentAcademicResult> results;

  SubjectAcademicSummary({
    required this.subjectName,
    required this.results,
  });

  List<StudentAcademicResult> get activeResults =>
      results.where((r) => !r.isCancelled).toList();

  int get totalTests => activeResults.length;

  List<StudentAcademicResult> get completedResults =>
      activeResults.where((r) => r.hasMarksValue || r.isAbsent).toList();

  int get completedCount => completedResults.length;

  int get pendingCount =>
      activeResults.where((r) => !r.hasMarksValue && !r.isAbsent).toList().length;

  int get passCount =>
      activeResults.where((r) => r.status == 'Pass').toList().length;

  int get failCount =>
      activeResults.where((r) => r.status == 'Fail').toList().length;

  int get absentCount =>
      activeResults.where((r) => r.isAbsent).toList().length;

  double get subjectAveragePercentage {
    final valid = activeResults.where((r) => r.hasMarksValue && !r.isAbsent).toList();
    if (valid.isEmpty) return 0.0;
    double sumObtained = 0.0;
    double sumMax = 0.0;
    for (var r in valid) {
      sumObtained += r.marksObtained!;
      sumMax += r.totalMarks;
    }
    return sumMax > 0 ? (sumObtained / sumMax) * 100.0 : 0.0;
  }
}

class StudentAcademicSummary {
  final List<StudentAcademicResult> allResults;

  StudentAcademicSummary({required this.allResults});

  List<StudentAcademicResult> get activeResults =>
      allResults.where((r) => !r.isCancelled).toList();

  int get totalTests => activeResults.length;

  List<StudentAcademicResult> get completedResults =>
      activeResults.where((r) => r.hasMarksValue || r.isAbsent).toList();

  int get completedCount => completedResults.length;

  int get pendingCount =>
      activeResults.where((r) => !r.hasMarksValue && !r.isAbsent).toList().length;

  int get passCount =>
      activeResults.where((r) => r.status == 'Pass').toList().length;

  int get failCount =>
      activeResults.where((r) => r.status == 'Fail').toList().length;

  int get absentCount =>
      activeResults.where((r) => r.isAbsent).toList().length;

  double get overallAveragePercentage {
    final valid = activeResults.where((r) => r.hasMarksValue && !r.isAbsent).toList();
    if (valid.isEmpty) return 0.0;
    double sumObtained = 0.0;
    double sumMax = 0.0;
    for (var r in valid) {
      sumObtained += r.marksObtained!;
      sumMax += r.totalMarks;
    }
    return sumMax > 0 ? (sumObtained / sumMax) * 100.0 : 0.0;
  }

  List<SubjectAcademicSummary> get subjectSummaries {
    final Map<String, List<StudentAcademicResult>> map = {};
    for (var r in allResults) {
      final sub = r.test.subject.trim().isEmpty ? 'General' : r.test.subject.trim();
      map.putIfAbsent(sub, () => []).add(r);
    }

    final list = <SubjectAcademicSummary>[];
    final sortedSubjects = map.keys.toList()..sort((a, b) => a.compareTo(b));
    for (var sub in sortedSubjects) {
      list.add(SubjectAcademicSummary(
        subjectName: sub,
        results: map[sub]!,
      ));
    }
    return list;
  }
}
