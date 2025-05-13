#import "abbreviations.typ"

// ╭───────────────╮
// │ Miscellaneous │
// ╰───────────────╯

#let left-judge(j) = [#context(h(-measure(j).width))#j]
#let judge = left-judge

#let sub-label(lbl) = {
  metadata(label(lbl))
}


// ╭─────────────────────╮
// │ Interlinear glosses │
// ╰─────────────────────╯

#let build-gloss(lines, styles, word-spacing, line-spacing) = {
    let make-word-box(..args) = {
        context{
          let spacing = line-spacing
          if spacing == auto {
            spacing = par.leading
          }
          box(stack(dir: ttb, spacing: spacing, ..args))
        }
    }

    let len = lines.at(0).len()

    for word-index in range(0, len) {
        let args = ()
        for (line, style) in lines.zip(styles) {
            let word = line.at(word-index)
            args.push(style(word))
        }
        make-word-box(..args)
        h(word-spacing)
    }
}


#let gloss(
  ..args,
  judge: none,
  word-spacing: 1em,
  line-spacing: auto,
  after-spacing: auto,
  styles: (),
) = {
  let lines = args.pos()
  assert(lines.len() > 0, message: "at least one gloss line must be present")
  let first-line = lines.at(0)

  for line in lines {
    assert(type(line) == array, message: "all gloss lines need to be arrays; perhaps you forgot to type `(` and `)`, or a trailing comma?")
    assert(line.len() == first-line.len(), message: "all gloss lines need to be of equal lengths")
  }

  // fill missing styles with defaults
  if styles.len() < lines.len() {
    styles += (x => x,) * (lines.len() - styles.len())
  }

  // prepend judge to the first word of the first line
  let first-line = ([#left-judge(judge)#first-line.at(0)],) + first-line.slice(1)

  context {
    let after = after-spacing
    if after == auto {
      after = par.spacing
    }
    par(
      spacing: after,
      build-gloss((first-line,) + lines.slice(1), styles, word-spacing, line-spacing)
    )
  }
}


// ╭─────────────────────╮
// │ Linguistic examples │
// ╰─────────────────────╯

#let example-count = counter("example-count")

#let example(
    content,
    label: none,
    label-supplement: none,
    indent: 0em,
    body-indent: 2em,
    sub-indent: 1.5em,
    breakable: false,
    number: none,
    num-pattern: "(1)",
    sub-num-pattern: "a.",
) = {

    // get-set numbering
    let example-number = [#context example-count.display(num-pattern)]
    if number != none {
      // if custom number is sent
      // override example number
      // and skip it for counting
      example-number = numbering(num-pattern, number)
    } else {
      example-count.step()
    }
    
    show figure.where(kind: "subexample"): it => {
      // override auto centering in figures
      set align(start)
      it
    }
    
    let add-subexample(
      number,
      example,
      label: none
    ) = {
      [
        #figure(
          kind: "subexample",
          numbering: it => [#example-count.display()#numbering("a", number)],
          supplement: label-supplement,
          outlined: false,
          grid(
            columns: (sub-indent, 1fr),
            [#numbering(sub-num-pattern, number)],
            [#example]
          )
        ) #if label != none {std.label(label)}
      ]
    }

    let get-sub-label(item) = {
      let body = item.body
      let label
      if "children" in body.fields() {
        label = body.children.find(it => "value" in it.fields() and type(it.value) == std.label)
      }
      if label != none {
        label = str(label.value)
      }
      return label
    }

    show figure.where(kind: "example"): it => {
      // override auto centering in figures
      set align(start)
      // we don't want translations etc to indent
      set par(first-line-indent: 0em)
      // reassemble subexamples
      show enum: it => {
        for (i, item) in it.children.enumerate(start: 1) {
          let label = get-sub-label(item) 
          add-subexample(i, item.body, label: label)
        }
      }
      it
    }

    context(
      [
        #figure(
          kind: "example",
          numbering: it => [#example-count.display()],
          outlined: false,
          supplement: label-supplement,
          grid(
            columns: (indent, body-indent, 1fr),
            [],
            example-number,
            content
          )
        ) #if label != none {std.label(label)}
      ]
    )
}


// ╭─────────────╮
// │ Referencing │
// ╰─────────────╯

#let ex-ref(left: none, right: none, ..args) = {
  // first ref
  let fst = ref(args.at(0))
  [(#left#fst]
  // second ref
  if args.pos().len() > 1 {
    // hide the digit part of a subexample ref
    show regex("\d+[a-z]+"): m => {
      show regex("\d+"): n => []
      m
    }
    [\-#ref(args.at(1))]
  }
  [#right)]
}
