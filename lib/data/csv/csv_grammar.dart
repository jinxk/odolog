/// Low level RFC 4180 read and write primitives shared by every CSV file this
/// app produces or reads back. Escaping and line tracking live here, once,
/// so the data bundle codec only has to worry about what the columns mean.
library;

/// One parsed CSV record: its fields in order, and the physical line number
/// on which the record started. A record spans more than one physical line
/// when a quoted field embeds a line break.
class CsvRecord {
  const CsvRecord(this.fields, this.line);

  final List<String> fields;
  final int line;
}

/// Reads and writes one CSV file's worth of quoting and escaping, with no
/// knowledge of what the rows mean.
class CsvGrammar {
  const CsvGrammar._();

  /// Wraps [value] in double quotes, doubling any quote it already contains.
  /// Every field is quoted on write regardless of content, so a reader never
  /// has to guess whether a bare token is a number, a date, or text.
  static String field(String value) => '"${value.replaceAll('"', '""')}"';

  /// Joins already-quoted [fields] into one CSV row. Does not add a line
  /// terminator; the caller decides how rows are separated.
  static String row(Iterable<String> fields) => fields.map(field).join(',');

  /// Parses [content] into records, tracking the physical line each one
  /// starts on so a validation failure can cite it. A quoted field may embed
  /// commas and line breaks, matching RFC 4180, since a row written before
  /// free text input was restricted can still carry a stray quote mark. A
  /// blank physical line is skipped rather than treated as an empty record,
  /// so a stray newline left by hand editing a template does not read as
  /// data.
  static List<CsvRecord> parse(String content) {
    final records = <CsvRecord>[];
    var fields = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    var line = 1;
    var recordStartLine = 1;
    var sawField = false;

    void endField() {
      fields.add(field.toString());
      field.clear();
    }

    void endRecord() {
      endField();
      records.add(CsvRecord(List<String>.of(fields), recordStartLine));
      fields = <String>[];
      sawField = false;
    }

    final length = content.length;
    var i = 0;
    while (i < length) {
      final char = content[i];
      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < length && content[i + 1] == '"') {
            field.write('"');
            i += 2;
          } else {
            inQuotes = false;
            i++;
          }
        } else {
          if (char == '\n') line++;
          field.write(char);
          i++;
        }
        continue;
      }
      switch (char) {
        case '"':
          inQuotes = true;
          sawField = true;
          i++;
        case ',':
          endField();
          sawField = true;
          i++;
        case '\r':
          if (i + 1 < length && content[i + 1] == '\n') i++;
          if (sawField) endRecord();
          line++;
          recordStartLine = line;
          i++;
        case '\n':
          if (sawField) endRecord();
          line++;
          recordStartLine = line;
          i++;
        default:
          field.write(char);
          sawField = true;
          i++;
      }
    }
    if (sawField) endRecord();
    return records;
  }
}
