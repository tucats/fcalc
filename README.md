# fcalc

**A scientific calculator for the terminal, written in Fortran 90, that runs on
a VAX under VMS and on Linux or macOS with gfortran.**

```
fcalc> e^(i*pi)
-1
fcalc> a = [4, -2; 1, 1]
a =
  4  -2
  1   1
fcalc> eig(a)
  2
  3
fcalc> solve cos(t) = t for t from 0 to 1
t = 0.739085133215
fcalc> integrate exp(-x^2) for x from 0 to 3
0.88620734826
fcalc> roots 1, 0, 0, -1
  -0.5 - 0.866025403784i
  -0.5 + 0.866025403784i
                       1
```

## Why fcalc is interesting

- **Every number is complex.** `sqrt(-4)` is `2i`, `ln(-1)` is `pi*i`,
  `asin(2)` has an answer, and `(-8)^(1/3)` is the principal cube root. You
  only see the complex part when there is one.
- **Vectors and matrices are values too.** You type them with brackets
  (`[1, 2; 3, 4]`), index and slice them (`m(2, :)`, `v([3, 1])`), and use
  matrix products, inverses, determinants, `A \ b` solves, ranks, norms, and
  eigenvalues, in the style of MATLAB and Octave.
- **It does real numerical methods.** SOLVE uses the secant method or Brent's
  method on a bracket. INTEGRATE uses adaptive Gauss-Kronrod quadrature, DIFF
  uses Ridders' extrapolation, and ROOTS uses Durand-Kerner polished by Newton.
  Eigenvalues come from a Hessenberg reduction and the shifted QR iteration,
  and the gamma function from Lanczos's approximation.
- **It draws.** TABLE prints values in columns and PLOT draws curves as
  character graphics, both in any terminal.
- **It never crashes on arithmetic.** It checks every operation's operands
  before computing. Division by zero, overflow, and a value outside a
  function's domain each give a message, never a trap or an infinity. That
  matters on a VAX, which traps where IEEE hardware quietly makes an infinity.
- **One source, two very different machines.** The same Fortran 90 runs as a
  VMS image on a VAX with G_floating arithmetic, and as a native program built
  with gfortran with IEEE arithmetic. Both print the same output, line for
  line, for every test script. fcalc's display and comparison rules keep the
  two machines' different last bits out of sight.
- **It is meant to be read.** It has about 11,000 lines in 16 modules. Each
  Fortran 90 feature is explained where the code first uses it: modules,
  derived types, pointers, recursion, internal procedures, array sections, and
  generic interfaces. Each numerical method is explained where it is applied.
  If you want to learn Fortran 90 or numerical programming from a whole
  working program, start here.

fcalc began as the milestone program for the Fortran 90 compiler in
[govax](https://github.com/tucats/govax), an emulator of a DEC VAX running VMS.
govax compiles fcalc into VAX MACRO-32, assembles and links it, and runs it
under its own VMS. It has also been built and run, unchanged, by the MACRO
assembler and linker of a real VMS 7.1 system.

## Building

### Linux or macOS, with gfortran

```sh
./build.sh          # builds ./fcalc
./build.sh test     # builds, then runs every script in tests/
./build.sh clean    # removes ./fcalc and build/
```

`FC` and `FFLAGS` choose the compiler and flags (the defaults are `gfortran`
and `-std=f95 -O2`). The sources keep to Fortran 90, so `-std=f95` builds them
with no warnings. For a strictly checked build, use:

```sh
FFLAGS="-std=f95 -O0 -fcheck=all,no-array-temps -ffpe-trap=invalid,zero,overflow,underflow" ./build.sh test
```

On macOS, `build.sh` sets `SDKROOT` to the SDK's path, because without it
gfortran's link can't find library `System`.

The gfortran build uses `src/gfortran/fcplatform.f90` in place of
`src/fcplatform.f90`. That one module holds everything that differs between
the two systems. Under gfortran fcalc has no command-line form and no HELP,
since both come from VMS's run-time library.

### govax (VAX/VMS)

Copy the repository to a govax volume, with the sources in a `[.SRC]`
directory below `BUILDVMS.COM`, and run the procedure:

```
$ @DUA1:[FCALC]BUILDVMS
FCALC.EXE built
$ FCALC :== $DUA1:[FCALC]FCALC
$ FCALC 2^10 + 1
1025
```

The procedure compiles each module `/G_FLOATING`, because fcalc's real kind,
`SELECTED_REAL_KIND(15, 300)`, needs G_floating's range. It compiles them in
the order of `src/compiles.txt`, each before the modules that use it. Then it
assembles and links them, and leaves `FCALC.EXE` beside the procedure.

### Tests

`tests/` holds eleven scripts, each a `name.in` of what a user types and a
`name.out` of what fcalc prints. The scripts cover the basics, complex values,
the functions, user functions, vectors, matrices, the numerical commands, the
display settings, saved state, every error message, and TABLE and PLOT.
`tests/files/` holds command files that the scripts run, and
`tests/expected/` holds the files that SAVE and LOG write. `./build.sh test`
runs every script in one scratch directory and compares each result line for
line. The date and time in a saved file's heading are masked.

### The sources

| File | What it holds |
|---|---|
| `fcplatform.f90` | what differs by system: carriage control, record lengths, the command line, HELP (`gfortran/fcplatform.f90` is gfortran's version) |
| `fckinds.f90` | the real kind `RK`, fcalc's limits, the constants |
| `fcmessages.f90` | output and the `%FCALC-E-...` messages |
| `fcvalues.f90` | `TYPE VALUE`: complex arithmetic guarded so nothing traps, and how values are shown |
| `fcarrays.f90` | `TYPE QUANTITY`: a scalar or an array through a pointer, and how arrays are shown |
| `fclexer.f90` | the tokens, including numbers in other bases |
| `fctree.f90` | expression trees of pointers, and the recursive descent parser |
| `fcsymbols.f90` | variables and user functions, each a binary search tree |
| `fcfuncs.f90` | the built-in functions, real and complex |
| `fcpoly.f90` | polynomials: roots (Durand-Kerner and Newton), `poly`, `polyval` |
| `fcmatrix.f90` | products, LU, inverses, determinants, powers, rank, norms, eigenvalues (Hessenberg and shifted QR) |
| `fceval.f90` | the evaluator: element-by-element operations, matrix literals, indexes, user function calls |
| `fcnumeric.f90` | SOLVE (secant, Brent), INTEGRATE (Gauss-Kronrod), DIFF (Ridders), ROOTS |
| `fcplot.f90` | TABLE and PLOT |
| `fcstate.f90` | settings, SAVE, LOAD, command files, LOG |
| `fcalc.f90` | the main program: the prompt and the commands |

---

# User's manual

fcalc is a scientific calculator. It works with numbers, complex values,
vectors, and matrices. It has the functions of a scientific calculator and
some of a statistician's, and you can define functions of your own. Its
commands solve equations, integrate, differentiate, find a polynomial's roots,
and show values in tables and graphs.

## Format

```
fcalc
FCALC [line]          (VMS only)
```

fcalc reads lines at its prompt, `fcalc> `, until EXIT, QUIT, or end of file
(Ctrl/D on Unix, Ctrl/Z on VMS). On VMS, when fcalc runs as a foreign command
with a line, it runs that line and ends: `FCALC 2^10 + 1` prints 1025. On VMS,
HELP inside fcalc shows the help text, and HELP followed by a topic shows a
topic below it (`HELP COMMANDS SOLVE`).

Each line is one of these:

- an expression, whose value fcalc shows and keeps as `ans`
- an assignment, `name = expression`
- a function definition, `name(x, ...) = expression`
- a command

Case doesn't matter. A line ending in `;` is quiet: fcalc keeps the value but
doesn't show it. A line starting with `!` is a comment.

## Expressions

Numbers are written as in Fortran or C: `42`, `1.5e-3`, `.5`. A number
followed by `i` is imaginary: `2i`, `1.5e3i`. Whole numbers may also be
written in hexadecimal (`0xFF`), octal (`0o377`), or binary (`0b1011`).

Every value is complex. A value with no imaginary part is shown as a real
number, and a whole number is shown with no decimal point:

```
fcalc> (1 + 2i) * (3 - i)
5 + 5i
```

The constants are:

| Constant | Value |
|---|---|
| `pi` | 3.14159265359... |
| `e` | 2.71828182846... |
| `i` | the imaginary unit |
| `eps` | the machine's epsilon, the distance from 1 to the next larger number |
| `huge` | the largest number fcalc keeps, 1e300 |
| `ans` | the last value shown |

fcalc never stops on an arithmetic error. A division by zero, a result too
large, or a function argument out of range gives a message, and the line has
no value. See [Messages](#messages).

## Operators

From the loosest binding to the tightest:

| Operator | Meaning |
|---|---|
| `or` | either is true (not zero) |
| `and` | both are true |
| `not` | true if the operand is false |
| `==` `<>` `<` `<=` `>` `>=` | comparisons, of the real parts; true is 1, false 0; `==` and `<>` are to within 64 epsilons |
| `+` `-` | addition, subtraction |
| `*` `/` `mod` | multiplication, division, remainder |
| `-` `+` | sign |
| `^` `**` | power, right to left: `2^3^2` is `2^9` |
| `!` | factorial, after its operand: `5!` is 120 |

Parentheses group. `-2^2` is -4, as in mathematics. A power of a negative or
complex number, and a fractional power, is the principal value: `(-8)^(1/3)`
is `1 + 1.73205080757i`.

On vectors and matrices, `+` and `-` work element by element and `*` is the
matrix product. `.*`, `./`, and `.^` work element by element, `'` is the
conjugate transpose, `.'` is the transpose, and `A \ b` solves `A*x = b`. See
[Vectors and matrices](#vectors-and-matrices).

## Variables

A name is a letter followed by letters, digits, and underscores, up to 31
characters. Case doesn't matter. An assignment shows the value:

```
fcalc> r = 2.5
r = 2.5
fcalc> area = pi * r^2
area = 19.6349540849
```

A name must be given a value before it is used. It may not be a constant, a
built-in function's name, or one of the words `or`, `and`, `not`, `mod`,
`solve`, `integrate`, `diff`, `table`, and `plot`.

You can assign an element or a section of a vector or matrix: `v(2) = 0`,
`m(1, :) = [1, 2]`.

LIST VARIABLES shows the variables and their values. CLEAR name (or CLEAR
ALL) forgets them.

## User functions

To define a function of up to 8 parameters, type its name and parameters,
an `=` sign, and its value. fcalc shows the definition as it keeps it:

```
fcalc> f(x) = x^3 - 2*x - 5
f(x) = x^3 - 2*x - 5
fcalc> g(x, y) = sqrt(x^2 + y^2)
g(x, y) = sqrt(x^2 + y^2)
fcalc> f(2)
-1
fcalc> g(3, 4)
5
```

The expression may use the parameters, the variables, the built-in functions,
and other functions of your own, defined before or after it. A variable's
value is the one it has when the function is called, not when the function
was defined.

A function may call itself through `if()`, which evaluates only the arm it
chooses:

```
fcalc> fact(n) = if(n < 2, 1, n * fact(n - 1))
fact(n) = if(n < 2, 1, n * fact(n - 1))
fcalc> fact(10)
3628800
```

Calls may go 200 deep. Defining a function again replaces it. LIST FUNCTIONS
shows the definitions, and CLEAR name forgets one.

## Functions

The topics below list the built-in functions by kind. Every function of one
argument works on each element of a vector or matrix. The list functions also
take a vector or matrix as their list. Functions of an angle use the angle
mode (SET ANGLE).

### Elementary

| Function | Value | Function | Value |
|---|---|---|---|
| `sqrt(x)` | square root | `cbrt(x)` | cube root |
| `exp(x)` | e to the power x | `ln(x)` | natural logarithm |
| `log10(x)` | common logarithm | `log2(x)` | base 2 logarithm |
| `log(x, b)` | logarithm to base b | `hypot(x, y)` | `sqrt(x^2 + y^2)` |

Each takes a complex argument and gives the principal value: `sqrt(-4)` is
`2i`, and `ln(-1)` is `pi*i` (`3.14159265359i`).

### Trigonometric

```
sin(x)   cos(x)   tan(x)   sec(x)   csc(x)   cot(x)
asin(x)  acos(x)  atan(x)  atan2(y, x)
sinh(x)  cosh(x)  tanh(x)  asinh(x) acosh(x) atanh(x)
```

The trigonometric functions take and give angles in the angle mode: radians,
degrees, or grads (SET ANGLE). The hyperbolic functions don't depend on it.
`atan2(y, x)` is the angle of the point (x, y), from -pi to pi. Every one
takes complex arguments: `asin(2)` is `1.57079632679 - 1.31695789692i`.

### Complex

| Function | Value |
|---|---|
| `re(z)` | real part |
| `im(z)` | imaginary part |
| `abs(z)` | magnitude |
| `arg(z)` | angle, -pi to pi |
| `conj(z)` | complex conjugate |
| `polar(r, t)` | `r * (cos(t) + i*sin(t))`, from a magnitude and an angle |
| `cis(t)` | `cos(t) + i*sin(t)` |

`arg`, `polar`, and `cis` use the angle mode.

### Integers

| Function | Value |
|---|---|
| `floor(x)` | the largest whole number not above x |
| `ceil(x)` | the smallest whole number not below x |
| `round(x)` | the nearest whole number, halves away from zero |
| `trunc(x)` | x with its fraction dropped |
| `frac(x)` | `x - trunc(x)` |
| `sign(x)` | -1, 0, or 1 |
| `gcd(a, b, ...)` | greatest common divisor |
| `lcm(a, b, ...)` | least common multiple |
| `isprime(n)` | 1 if n is prime, 0 if not |
| `ncr(n, k)` | combinations, n! / (k! (n-k)!) |
| `npr(n, k)` | permutations, n! / (n-k)! |

`gcd`, `lcm`, `isprime`, `ncr`, and `npr` need whole numbers.

### Special

| Function | Value |
|---|---|
| `gamma(x)` | the gamma function; `gamma(n + 1)` is n! |
| `lgamma(x)` | the logarithm of `abs(gamma(x))` |
| `erf(x)` | the error function |
| `erfc(x)` | `1 - erf(x)`, accurate where `erf(x)` is near 1 |
| `beta(a, b)` | `gamma(a) gamma(b) / gamma(a + b)` |

These take real arguments. `x!` is `gamma(x + 1)`, so `0.5!` is
`0.886226925453`.

### Lists

| Function | Value |
|---|---|
| `min(...)`, `max(...)` | the smallest and largest |
| `sum(...)`, `prod(...)` | the sum and product |
| `mean(...)`, `median(...)` | the mean and median |
| `var(...)`, `stdev(...)` | the sample variance and standard deviation (at least two values) |

Each takes any number of arguments, or a vector or matrix whose elements are
the list: `mean(1, 2, 3, 4)` and `mean([1, 2, 3, 4])` are both 2.5. `min` and
`max` compare real parts.

### Arrays

```
size(a)  size(a, d)  rows(a)  cols(a)  numel(a)
zeros(m, n)  ones(m, n)  eye(n)  diag(v)  linspace(a, b, n)
range(a, b)  range(a, b, step)  reshape(a, m, n)
transpose(a)  trace(m)  det(m)  inv(m)  rank(m)  eig(m)
norm(v)  norm(v, p)  dot(u, v)  cross(u, v)  kron(a, b)
cumsum(v)  sort(v)  roots(c)  poly(r)  polyval(c, x)
```

See [Array functions](#array-functions) for what each does.

### Other

| Function | Value |
|---|---|
| `if(c, a, b)` | a if c is true (not zero), else b; only the arm chosen is evaluated, so a function may call itself through it |
| `rand()` | a random number from 0 to 1 |
| `rand(a, b)` | a random number from a to b |

SET SEED n starts `rand`'s sequence again from n.

## Vectors and matrices

A value may be a vector or a matrix of complex numbers. Brackets make one:
commas separate the elements of a row, and semicolons separate the rows.

| Literal | Meaning |
|---|---|
| `[1, 2, 3]` | a row vector |
| `[1; 2; 3]` | a column vector |
| `[1, 2; 3, 4]` | a 2 by 2 matrix |
| `[v, 4]`, `[m; v]` | joined (the parts must fit) |

Elements may be any expressions. A matrix is shown in rows with its columns
aligned, and each element is shown to the digits of the largest:

```
fcalc> m = [2, 1; 1, 3]
m =
  2  1
  1  3
```

Arrays may hold up to 10,000 elements.

### Indexing

`v(k)` is a vector's kth element, and `m(i, j)` is a matrix's element in row
i and column j, counting from 1. An index may be a range `a:b`, a `:` for
all, or a vector of indexes:

| Index | Meaning |
|---|---|
| `m(2, :)` | the second row |
| `m(:, 1)` | the first column |
| `v(2:4)` | the second to fourth elements |
| `v([3, 1])` | the third and the first |

`end` isn't a word here. Use `size`, `rows`, or `cols` instead:
`v(numel(v))`.

Assigning to an element or a section changes it: `v(1) = 10`,
`m(:, 2) = [0; 0]`.

### Array operators

| Operator | Meaning |
|---|---|
| `a + b`, `a - b` | element by element; a scalar is spread over an array |
| `a * b` | the matrix product; with a scalar, element by element |
| `a .* b`, `a ./ b` | element by element |
| `a .^ b` | element by element power |
| `m ^ n` | a square matrix to a whole power; a negative power through the inverse |
| `a'` | the conjugate transpose |
| `a.'` | the transpose |
| `A \ b` | the solution x of `A*x = b` |
| comparisons | element by element, giving 1s and 0s |

Shapes must agree: a 2 by 3 matrix plus a 3 by 2 one is NOTCONFORM.

### Array functions

| Function | Value |
|---|---|
| `size(a)`, `size(a, d)` | `[rows, columns]`, or the size of dimension d |
| `rows(a)`, `cols(a)`, `numel(a)` | rows, columns, elements |
| `zeros(m, n)`, `ones(m, n)`, `eye(n)` | arrays of 0s and 1s, the identity |
| `diag(v)` | a square matrix with v down its diagonal, or a square matrix's diagonal as a vector |
| `linspace(a, b, n)` | n values from a to b, equally spaced |
| `range(a, b[, s])` | a, a+s, ... up to b (s is 1 if not given) |
| `reshape(a, m, n)` | a's elements, column by column, as m by n |
| `cumsum(v)`, `sort(v)` | running sums; sorted by real part |
| `dot(u, v)`, `cross(u, v)`, `kron(a, b)` | products |
| `norm(v[, p])` | the p-norm (2 if not given) |
| `transpose(a)`, `trace(m)`, `det(m)`, `inv(m)`, `rank(m)` | the usual |
| `eig(m)` | the eigenvalues, sorted, by the QR method |
| `roots(c)`, `poly(r)`, `polyval(c, x)` | see [ROOTS](#roots) |

## Commands

A line that starts with one of these words is a command. Each section below
describes one. RUN, LOAD, SAVE, LOG, and HELP followed by `=` or `(` aren't
commands: `RUN = 3` assigns a variable, and `LOG(8, 2)` is a logarithm.

### SOLVE

Finds a root of an equation.

```
SOLVE expr [= expr] FOR x [FROM a [TO b]]
```

`x` is a name standing for the unknown. A variable of that name is left
alone. With FROM a alone, fcalc starts the secant method at a (at 0 if FROM
is left out), and from a complex start it can find complex roots. With FROM a
TO b, the expression must change sign between a and b, and fcalc narrows the
bracket by Brent's method, which always converges.

```
fcalc> solve x^2 = 2 for x from 1
x = 1.41421356237
fcalc> solve cos(t) = t for t from 0 to 1
t = 0.739085133215
```

NOROOT means the secant method found no root. SAMESIGN means the bracket's
ends have values of the same sign.

### INTEGRATE

Integrates an expression between two limits.

```
INTEGRATE expr FOR x FROM a TO b
```

fcalc uses adaptive Gauss-Kronrod quadrature. It integrates each piece of the
interval by rules of 7 and 15 points, and their difference estimates the
error. It cuts the piece with the largest error in two, and repeats until the
pieces' errors add up to little enough. The pieces shrink where the
expression is hard to integrate, so fcalc also handles a jump, or a
singularity at an end that has a finite integral.

```
fcalc> integrate exp(-x^2) for x from 0 to 3
0.88620734826
```

If the pieces (200) run out before the estimate is small, the value comes
with `%FCALC-W-INACCURATE`, which says how large the error may be.

### DIFF

Differentiates an expression at a point.

```
DIFF expr FOR x AT a
```

fcalc uses Ridders' method, Richardson extrapolation of central differences,
which gives about 10 digits for a smooth function. The point a may be
complex.

```
fcalc> diff sin(x) for x at 0
1
```

At a point where the function isn't smooth, the value comes with
`%FCALC-W-INACCURATE`.

### ROOTS

Finds every root, real and complex, of a polynomial.

```
ROOTS c1, c2, ..., cn
ROOTS v
```

The coefficients are given from the highest power down, or as a vector:
`ROOTS 1, 0, -1` is x^2 - 1. fcalc uses the Durand-Kerner method, then
polishes each root by Newton's method. It shows the roots as a column and
keeps them as `ans`:

```
fcalc> roots 1, -6, 11, -6
  1
  2
  3
```

Three functions go with it: `roots(c)` gives the same roots as a value,
`poly(r)` gives the coefficients of the polynomial with roots r, and
`polyval(c, x)` gives its value at x.

### TABLE

Shows expressions' values in columns.

```
TABLE expr[, expr...] FOR x FROM a TO b [STEP s]
TABLE v[, w...]
```

With FOR, fcalc evaluates each expression at a, a + s, ... up to b, a row
for each point, up to 1,000 rows. If STEP is left out, s is (b - a)/10. A
point where an expression has no value shows the error's name, such as
DIVZERO. Without FOR, each expression is a vector, all of one length, and
fcalc shows them side by side. A table may have up to 8 expressions. See
[Table and plot](#table-and-plot).

### PLOT

Draws expressions' values as a graph of characters.

```
PLOT expr[, expr...] FOR x FROM a TO b [SIZE w, h] [Y lo, hi]
PLOT v[, w...] [VERSUS u] [SIZE w, h] [Y lo, hi]
```

With FOR, fcalc evaluates each expression at as many points as the graph is
wide. Without FOR, each expression is a vector, drawn against its index, or,
after VERSUS, against the vector u.

The graph is 61 characters wide and 19 high unless SIZE says otherwise (10
to 100 wide, 3 to 60 high). Its vertical range is the values' range unless Y
gives one, and values outside it aren't drawn. Each curve has a mark: `*`,
`o`, `#`, `x`, `@`, `%`, `&`, and `$` in turn, named under the graph. The
axes are drawn where zero is in range. Points where a value can't be
computed, or isn't real, are left out. See [Table and plot](#table-and-plot).

### LIST

```
LIST [VARIABLES | FUNCTIONS | ALL]
```

Shows the variables and their values, the functions and their definitions,
or both (ALL, the default), in the order of their names.

### CLEAR

```
CLEAR name ...
CLEAR ALL
```

Forgets the variables and functions named, or every one. A name that isn't
defined gets `%FCALC-W-NOTDEF`.

### SET

```
SET DIGITS n
SET FORMAT AUTO | FIXED | SCIENTIFIC | ENGINEERING
SET BASE DECIMAL | HEX | OCTAL | BINARY
SET ANGLE RADIANS | DEGREES | GRADS
SET SEED n
SET ECHO | NOECHO
```

DIGITS, FORMAT, and BASE choose how values are shown (see
[Display](#display)). ANGLE is the unit the trigonometric functions use
(radians unless set). SEED starts the random numbers again from n, so a
sequence can be repeated. ECHO shows each line read after the prompt, as a
terminal does, which makes a transcript of a file of commands (NOECHO unless
set).

### SHOW

```
SHOW SETTINGS
SHOW DIGITS | FORMAT | BASE | ANGLE | SEED | ECHO
SHOW MEMORY
```

SHOW SETTINGS shows each setting as the SET command that makes it. SHOW
followed by a setting's name shows that one. SHOW MEMORY counts the arrays
and expression trees in use, which CLEAR ALL should bring to 0.

### SAVE

```
SAVE file
```

Writes the settings, variables, and functions to the file as fcalc's own
commands: SET lines, assignments, and definitions. Each number is written
with the fewest digits that read back exactly. You can read and edit the
file. A file name with no type gets `.fcalc`.

### LOAD

```
LOAD file
```

Clears every variable and function, then runs the file's lines quietly, as
SAVE wrote them. This restores exactly the session that SAVE saved.

### @ and RUN

```
@file
RUN file
```

Runs the lines of a file of commands as if they were typed, with their output
shown. A file may run another, up to 8 deep. An error ends the file, and
every file that ran it, each saying the line it was at. EXIT or QUIT in a
file ends that file only. A name with no type gets `.fcalc`.

### LOG

```
LOG file
LOG OFF
```

Keeps a transcript: fcalc adds each line typed, and everything it shows, to
the end of the file until LOG OFF.

### HELP

```
HELP [topic ...]
```

On VMS, shows this help, the FCALC topic of the system's help library
(SYS$HELP:HELPLIB.HLB), the same text as DCL's HELP FCALC. HELP COMMANDS
SOLVE shows the topic SOLVE under Commands. The gfortran build has no help
library, and HELP gets `%FCALC-E-NOHELP`.

### EXIT

```
EXIT
QUIT
```

Ends fcalc, or the file of commands it is running. End of file ends fcalc
too.

## Display

fcalc shows values to 12 significant digits, in fixed notation from 1e-5 to
1e11 and in scientific notation outside that range (SET FORMAT AUTO). Fixed
notation drops trailing zeros: `1/4` is `0.25`.

| Setting | Effect |
|---|---|
| `SET DIGITS n` | significant digits, 1 to 15 (12 unless set); under FIXED, places after the point |
| `SET FORMAT FIXED` | always fixed, with exactly DIGITS places |
| `SET FORMAT SCIENTIFIC` | always `d.ddd...e+nn` |
| `SET FORMAT ENGINEERING` | scientific, with the exponent a multiple of 3 |
| `SET BASE HEX` | whole numbers in hexadecimal, `0xFF`; also OCTAL (`0o377`), BINARY (`0b11111111`), and DECIMAL |

Under SET BASE, a value that isn't a whole number is shown in decimal. If one
part of a complex value is smaller than the other by more than the digits
shown, it is shown as zero, so `1e-20 + 1` is `1`. An array's elements are
shown to the digits of its largest element.

SHOW SETTINGS shows the settings as SET commands.

## Messages

fcalc shows an error with the line, a `^` under the place it found the
error, and a message in VMS's form:

```
fcalc> 1 / (2 - 2)
         ^
%FCALC-E-DIVZERO, division by zero
```

An error (E) leaves the line with no value and ends a file of commands. A
warning (W) gives the value and goes on. In a file, a second message says
where:

```
-FCALC-I-INFILE, in line 3 of setup.fcalc
```

No input ends fcalc, and nothing it computes stops it. Every operation checks
its operands first, so nothing overflows or traps.

## Examples

Each section below is a session, shown as a terminal shows it.

### Arithmetic

```
fcalc> 2^10 + 1
1025
fcalc> sqrt(2)
1.41421356237
fcalc> 1 / 3 + 1 / 6
0.5
fcalc> e^(i*pi)
-1
fcalc> (3 + 4i) / (1 - 2i)
-1 + 2i
fcalc> 20!
2.43290200818e+18
fcalc> set angle degrees
fcalc> sin(30)
0.5
fcalc> atan2(1, -1)
135
fcalc> set base hex
fcalc> 255 + 1
0x100
```

### Functions of your own

```
fcalc> f(x) = x^3 - 2*x - 5
f(x) = x^3 - 2*x - 5
fcalc> solve f(x) for x from 2
x = 2.09455148154
fcalc> diff f(x) for x at ans
11.1614377265
fcalc> fib(n) = if(n < 2, n, fib(n - 1) + fib(n - 2))
fib(n) = if(n < 2, n, fib(n - 1) + fib(n - 2))
fcalc> fib(15)
610
fcalc> list functions
f(x) = x^3 - 2*x - 5
fib(n) = if(n < 2, n, fib(n - 1) + fib(n - 2))
```

### Matrices

```
fcalc> a = [4, -2; 1, 1]
a =
  4  -2
  1   1
fcalc> det(a)
6
fcalc> inv(a)
   0.166666666667  0.333333333333
  -0.166666666667  0.666666666667
fcalc> eig(a)
  2
  3
fcalc> a \ [2; 3]
  1.33333333333
  1.66666666667
fcalc> v = range(1, 5)
v =
  1  2  3  4  5
fcalc> v .^ 2
  1  4  9  16  25
fcalc> mean(v)
3
fcalc> stdev(v)
1.58113883008
```

### Numerics

```
fcalc> integrate 4 / (1 + x^2) for x from 0 to 1
3.14159265359
fcalc> integrate sin(x) / x for x from 0 to pi
1.85193705198
fcalc> roots 1, 0, 0, -1
  -0.5 - 0.866025403784i
  -0.5 + 0.866025403784i
                       1
fcalc> solve x = cos(x) for x from 0 to 1
x = 0.739085133215
```

### Table and plot

```
fcalc> table x^2, sqrt(x) for x from 1 to 5 step 1
  x  x^2        sqrt(x)
  -  ---  -------------
  1    1              1
  2    4  1.41421356237
  3    9  1.73205080757
  4   16              2
  5   25   2.2360679775
fcalc> plot sin(x), cos(x) for x from 0 to 2*pi size 50, 13 y -1, 1
 1 |oooo      ******                              oooo
   |    oo ***      **                          oo
   |     *oo          **                      oo
   |    *   o           **                   o
   |  **     oo           *                oo
   | *         o           *              o
 0 |*-----------o-----------**-----------o-----------*
   |             oo           *        oo           *
   |               o           *      o           **
   |                oo          **  oo           *
   |                  o           *o           **
   |                   ooo      ooo **      ***
-1 |                      oooooo      ******
   +--------------------------------------------------
    0                                          6.28319
    * sin(x)   o cos(x)
```

## License

fcalc is released under the MIT License. See [LICENSE](LICENSE).
