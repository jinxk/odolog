import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/data/csv/csv_grammar.dart';

void main() {
  test('field wraps a plain value in quotes', () {
    expect(CsvGrammar.field('Activa'), '"Activa"');
  });

  test('field doubles an embedded quote mark', () {
    expect(CsvGrammar.field('5.3" tank'), '"5.3"" tank"');
  });

  test('row quotes every field and joins them with commas', () {
    expect(CsvGrammar.row(['a', 'b, c']), '"a","b, c"');
  });

  test('parse reads a simple quoted row', () {
    final records = CsvGrammar.parse('"a","b"\n');
    expect(records, hasLength(1));
    expect(records.single.fields, ['a', 'b']);
    expect(records.single.line, 1);
  });

  test('parse keeps a comma inside a quoted field as one value', () {
    final records = CsvGrammar.parse('"a","near the mall, on the highway"\n');
    expect(records.single.fields[1], 'near the mall, on the highway');
  });

  test('parse unescapes a doubled quote back to one quote mark', () {
    final records = CsvGrammar.parse('"5.3"" tank"\n');
    expect(records.single.fields, ['5.3" tank']);
  });

  test('parse keeps an embedded line break inside a quoted field', () {
    final records = CsvGrammar.parse('"line one\nline two","b"\n');
    expect(records.single.fields[0], 'line one\nline two');
  });

  test('parse tracks the starting line of each record', () {
    final records = CsvGrammar.parse('"a"\n"b"\n"c"\n');
    expect(records.map((r) => r.line).toList(), [1, 2, 3]);
  });

  test('a record spanning an embedded line break resumes line counting after '
      'it', () {
    final records = CsvGrammar.parse('"line one\nline two"\n"next row"\n');
    expect(records[0].line, 1);
    expect(records[1].line, 3);
  });

  test('a blank physical line is skipped rather than read as an empty '
      'record', () {
    final records = CsvGrammar.parse('"a"\n\n"b"\n');
    expect(records, hasLength(2));
    expect(records[0].fields, ['a']);
    expect(records[1].fields, ['b']);
  });

  test('a final row with no trailing newline is still read', () {
    final records = CsvGrammar.parse('"a","b"');
    expect(records, hasLength(1));
    expect(records.single.fields, ['a', 'b']);
  });

  test('empty content produces no records', () {
    expect(CsvGrammar.parse(''), isEmpty);
  });
}
