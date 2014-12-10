# Design Limitations

* the conversions are one-way - from derived to base units
* correct multiplication of units is not supported, e.g. 1 cm * 1 m = 100 cm^2 =
  0.001 m^2

# Differences from the Paper

Firstly, I haven't implemented `MeasurementBag` and `NonProportionalDerivedUnit`
yet.

Secondly, units are not simplified, i.e. km * h / h will not yield km.