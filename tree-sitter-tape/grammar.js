/**
 * tree-sitter grammar for .tape (agent-execution trace, v1.2).
 *
 * Total line model, no external scanner, no regex look-around. Every
 * line token REQUIRES a trailing newline (no zero-width tokens → the
 * top-level repeat always progresses, no parser hang). .tape files are
 * LF-terminated by spec, so this is exact. Exposes `type` + `edge_op`
 * for highlighting; heredoc / divider / CJK body lines fall through to
 * `text` / `body`. Block structure is the LSP's job.
 */
module.exports = grammar({
  name: 'tape',

  extras: $ => [],

  rules: {
    source_file: $ => repeat($._line),

    _line: $ => choice(
      $.blank,
      $.comment,
      $.header,
      $.edge,
      $.body,
      $.text,
    ),

    blank: $ => token(prec(1, /[ \t]*\n/)),

    comment: $ => token(prec(5, /[ \t]*#[^\n]*\n/)),

    header: $ => seq($.type, $._rest),

    type: $ => token(prec(4, /@[A-Z?]/)),

    edge: $ => seq($._indent, $.edge_op, $._rest),

    body: $ => seq($._indent, $._rest),

    _indent: $ => token(prec(3, /[ \t]+/)),

    edge_op: $ => token(prec(4, choice(
      '<-', '->', '=>', '==', '~>', '|>', '!!',
      '<:', ':>', '?>', '!>', '@>',
    ))),

    _rest: $ => token(prec(1, /[^\n]*\n/)),

    // a column-0 line that is not @type / # / blank (rare: CJK or a
    // divider that does not start with '#')
    text: $ => token(prec(0, /[^ \t#@\n][^\n]*\n/)),
  },
});
