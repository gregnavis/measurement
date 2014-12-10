This repository contains a Ruby implementation of measurements based on the
article [*Arithmetic with Measurements on Dynamically-Typed Object-Oriented
Languages*](https://dl.acm.org/citation.cfm?id=1094964).

**The library is not intended for production use.**

# Usage

Firstly, you should define desired units and their relationships. For example:

```ruby
@kg = BaseUnit.new('kg')
@m = BaseUnit.new('m')
@km = ProportionalDerivedUnit.new('km', 1000, @m)
@s = BaseUnit.new('s')
```

Secondly, measurements should be created by calling
`Measurement.new(amount, unit)`. The objects support four basic arithmetic
operations and handle unit compatibility and conversions, e.g.:

```ruby
t = Measurement.new(10, @s)
x = Measurement.new(3.3, @km)
v = x / t # = 330.0 m / s
```

# Differences from the Paper

Firstly, `MeasurementBag` and `NonProportionalDerivedUnit` haven't been
implemented yet.

Secondly, units are not simplified, i.e. km * h / h will not yield km. The only
type of simplification that is performed is when both the numerator and
denominator contain exactly the same units in the same order.

Thirdly, multiplication of units is non-commutative. Subtracting 2 m * s from
10 s * m should yield 8 m * s = 8 s * m. It fails in the current version.

# Design Limitations

The library assumes one-way conversion - from a derived to base unit. The goal
is having the ability to compute and compare measurements of different but
related units. The conversion in the other direction is *not* supported.

Another limitation, which may not be present in the library presented in the
paper, is that unit conversion is performed even when it isn't strictly
necessary. Dividing 3.3 km by 10 s yields, as demonstrated by the example above,
330 m / s instead of 0.33 km / s.
