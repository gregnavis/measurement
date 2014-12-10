require 'measurement'

require 'minitest'
require 'minitest/autorun'

describe Measurement do
  before do
    @m = BaseUnit.new('m')
    @cm = ProportionalDerivedUnit.new('cm', 0.01, @m)
    @s = BaseUnit.new('s')
    @h = ProportionalDerivedUnit.new('h', 3600, @s)

    @_10m = Measurement.new(10, @m)
    @_2m = Measurement.new(2, @m)
    @_50cm = Measurement.new(50, @cm)

    @_10s = Measurement.new(10, @s)
  end

  it 'has an amount' do
    assert_equal(10, @_10m.amount)
  end

  it 'has a unit' do
    assert_equal(@m, @_10m.unit)
  end

  describe 'to_s' do
    it 'prints the unit' do
      assert_equal('10 m', @_10m.to_s)
    end
  end

  describe '+' do
    it 'does not convert equal units' do
      sum = @_10m + @_2m

      assert_equal(12, sum.amount)
      assert_equal(@m, sum.unit)
    end

    it 'converts compatible units' do
      sum = @_2m + @_50cm

      assert_equal(2.5, sum.amount)
      assert_equal(@m, sum.unit)
    end

    it 'fails on incompatible units' do
      assert_raises(RuntimeError) do
        Measurement.new(1, @m) + Measurement.new(2, @s)
      end
    end

    it 'yields null measurement amount becomes zero' do
      measurement = Measurement.new(1, @m) + Measurement.new(-1, @m)

      assert_equal(NullMeasurement.instance, measurement)
    end
  end

  describe '-' do
    it 'does not convert equal units' do
      sum = @_10m - @_2m

      assert_equal(8, sum.amount)
      assert_equal(@m, sum.unit)
    end

    it 'converts compatible units' do
      sum = @_2m - @_50cm

      assert_equal(1.5, sum.amount)
      assert_equal(@m, sum.unit)
    end

    it 'fails on incompatible units' do
      assert_raises(RuntimeError) do
        Measurement.new(1, @m) - Measurement.new(2, @s)
      end
    end

    it 'yields null measurement amount becomes zero' do
      measurement = @_10m - @_10m

      assert_equal(NullMeasurement.instance, measurement)
    end
  end

  describe '*' do
    it 'multiplies equal units' do
      product = Measurement.new(2, @m) * Measurement.new(3, @m)

      assert_equal(6, product.amount)
      assert_equal([@m, @m], product.unit.factors)
    end

    it 'multiplies by null unit without conversion' do
      product = Measurement.new(2, @h) * Measurement.new(3, NullUnit.instance)

      assert_equal(6, product.amount)
      assert_equal(@h, product.unit)
    end

    it 'converts unequal units' do
      product = Measurement.new(2, @m) * Measurement.new(300, @cm)

      assert_equal(6, product.amount)
      assert_equal([@m, @m], product.unit.factors)
    end
  end

  describe '/' do
    it 'yields no units for equal unit' do
      quotient = Measurement.new(6, @m) / Measurement.new(2, @m)

      assert_equal(3, quotient.amount)
      assert_equal(NullUnit.instance, quotient.unit)
    end

    it 'divides by null unit without conversion' do
      product = Measurement.new(4, @h) / Measurement.new(2, NullUnit.instance)

      assert_equal(2, product.amount)
      assert_equal(@h, product.unit)
    end

    it 'converts and divides other units' do
      quotient = Measurement.new(10800, @m) / Measurement.new(1, @h)

      assert_equal(3, quotient.amount)
      assert_equal(@m, quotient.unit.numerator)
      assert_equal(@s, quotient.unit.denominator)
    end
  end

  describe '<=>' do
    it 'compares amounts of equal units' do
      assert_equal(0, Measurement.new(1, @m) <=> Measurement.new(1, @m))
      assert_equal(1, Measurement.new(2, @m) <=> Measurement.new(1, @m))
      assert_equal(-1, Measurement.new(2, @m) <=> Measurement.new(3, @m))
    end

    it 'converts amounts of inequal units' do
      assert_equal(0, Measurement.new(1, @m) <=> Measurement.new(100, @cm))
      assert_equal(0, Measurement.new(100, @cm) <=> Measurement.new(1, @m))
    end

    it 'fails on incompatible units' do
      assert_raises(RuntimeError) do
        Measurement.new(1, @m) <=> Measurement.new(1, @s)
      end
    end
  end

  it 'responds to comparison methods' do
    assert(@_10m.respond_to?(:<))
    assert(@_10m.respond_to?(:<=))
    assert(@_10m.respond_to?(:>))
    assert(@_10m.respond_to?(:>=))
  end
end

describe NullMeasurement do
  it 'reports 0 amount' do
    assert_equal(0, NullMeasurement.instance.amount)
  end

  it 'reports null unit' do
    assert_equal(NullUnit.instance, NullMeasurement.instance.unit)
  end
end

describe 'units' do
  before do
    @null = NullUnit.instance
    @kg = BaseUnit.new('kg')
    @m = BaseUnit.new('m')
    @s = BaseUnit.new('s')
    @A = BaseUnit.new('A')

    @m_per_s = DividedUnit.new(@m, @s)
    @A_per_kg = DividedUnit.new(@A, @kg)

    @kg_s = MultipliedUnit.new([@kg, @s])
    @A_m = MultipliedUnit.new([@A, @m])

    @km = ProportionalDerivedUnit.new('km', 1000, @m)
    @h = ProportionalDerivedUnit.new('h', 3600, @s)

    @km_per_h = DividedUnit.new(@km, @h)
  end

  describe BaseUnit do
    it 'has a name' do
      assert_equal('kg', @kg.name)
    end

    it 'is its own base unit' do
      assert_equal(@kg, @kg.base_unit)
    end

    describe 'convert_amount_base_units' do
      it 'returns the amount expressed in itself' do
        measurement = @m.convert_amount_base_units(1)

        assert_equal(1, measurement.amount)
        assert_equal(@m, measurement.unit)
      end
    end

    describe '*' do
      it 'returns a multiplied unit after multiplying by a base unit' do
        assert_equal([@kg, @s], (@kg * @s).factors)
      end

      it 'handles proportional units like base units' do
        assert_equal([@kg, @h], (@kg * @h).factors)
      end

      it 'computes u * (p * q) = (u * p * q)' do
        assert_equal([@m, @kg, @s], (@m * @kg_s).factors)
      end

      it 'computes u * (p / q) = (u * p) / q' do
        product = @kg * @m_per_s

        assert_equal([@kg, @m], product.numerator.factors)
        assert_equal(@s, product.denominator)
      end

      it 'returns itself after being multiplied by a null unit' do
        assert_equal(@kg, @kg * @null)
      end
    end

    describe '/' do
      it 'returns a divided unit after dividing by a base unit' do
        quotient = @m / @s

        assert_equal(@m, quotient.numerator)
        assert_equal(@s, quotient.denominator)
      end

      it 'handles proportional units like base unit' do
        quotient = @m / @h

        assert_equal(@m, quotient.numerator)
        assert_equal(@h, quotient.denominator)
      end

      it 'computes u / (p / q) = (u * q) / p' do
        quotient = @kg / @m_per_s

        assert_equal([@kg, @s], quotient.numerator.factors)
        assert_equal(@m, quotient.denominator)
      end

      it 'computes u / (p * q)' do
        quotient = @kg / @kg_s

        assert_equal(@kg, quotient.numerator)
        assert_equal([@kg, @s], quotient.denominator.factors)
      end

      it 'returns itself after being divided by a null unit' do
        assert_equal(@kg, @kg / @null)
      end
    end
  end

  describe ProportionalDerivedUnit do
    it 'has a name' do
      assert_equal('km', @km.name)
    end

    it 'has a factor' do
      assert_equal(1000, @km.factor)
    end

    it 'references the correct base unit' do
      assert_equal(@m, @km.base_unit)
    end

    describe 'convert_amount_base_units' do
      it 'returns the amount in the base unit' do
        measurement = @km.convert_amount_base_units(1)

        assert_equal(1000, measurement.amount)
        assert_equal(@m, measurement.unit)
      end
    end

    describe '*' do
      it 'returns a multiplied unit after multiplying by a base unit' do
        assert_equal([@km, @s], (@km * @s).factors)
      end

      it 'handles proportional units like base units' do
        assert_equal([@km, @h], (@km * @h).factors)
      end

      it 'computes u * (p * q) = (u * p * q)' do
        assert_equal([@km, @kg, @s], (@km * @kg_s).factors)
      end

      it 'computes u * (p / q) = (u * p) / q' do
        product = @km * @m_per_s

        assert_equal([@km, @m], product.numerator.factors)
        assert_equal(@s, product.denominator)
      end

      it 'returns itself after being multiplied by a null unit' do
        assert_equal(@km, @km * @null)
      end
    end

    describe '/' do
      it 'returns a divided unit after dividing by a base unit' do
        quotient = @km / @s

        assert_equal(@km, quotient.numerator)
        assert_equal(@s, quotient.denominator)
      end

      it 'handles proportional units like base unit' do
        quotient = @km / @h

        assert_equal(@km, quotient.numerator)
        assert_equal(@h, quotient.denominator)
      end

      it 'computes u / (p / q) = (u * q) / p' do
        quotient = @km / @m_per_s

        assert_equal([@km, @s], quotient.numerator.factors)
        assert_equal(@m, quotient.denominator)
      end

      it 'computes u / (p * q)' do
        quotient = @km / @kg_s

        assert_equal(@km, quotient.numerator)
        assert_equal([@kg, @s], quotient.denominator.factors)
      end

      it 'returns itself after being divided by a null unit' do
        assert_equal(@km, @km / @null)
      end
    end
  end

  describe DividedUnit do
    it 'returns null unit when they are identical' do
      assert_equal(@null, DividedUnit.new(@m, @m))
    end

    describe 'name' do
      it 'does not put parentheses around base units' do
        assert_equal('m / s', @m_per_s.name)
      end

      it 'puts parents around multiplied units in denominator' do
        assert_equal('m / (A * s)', (@m / (@A * @s)).name)
      end
    end

    it 'has a numerator' do
      assert_equal(@m, @m_per_s.numerator)
    end

    it 'has a denominator' do
      assert_equal(@s, @m_per_s.denominator)
    end

    it 'references the correct base unit' do
      assert_equal(@m, @km_per_h.base_unit.numerator)
      assert_equal(@s, @km_per_h.base_unit.denominator)
    end

    describe 'convert_amount_base_units' do
      it 'returns the amount in the base unit' do
        measurement = @km_per_h.convert_amount_base_units(1)

        assert_equal(1000 / 3600, measurement.amount)
        assert_equal(@m, measurement.unit.numerator)
        assert_equal(@s, measurement.unit.denominator)
      end
    end

    describe '*' do
      it '(p / q) * u = (p * u) / q' do
        product = @m_per_s * @kg

        assert_equal([@m, @kg], product.numerator.factors)
        assert_equal(@s, product.denominator)
      end

      it 'handles proportional units like base units' do
        product = @m_per_s * @h

        assert_equal([@m, @h], product.numerator.factors)
        assert_equal(@s, product.denominator)
      end

      it '(p / q) * (u * v) = (p * u * v) / q' do
        product = @m_per_s * (@kg_s)

        assert_equal([@m, @kg, @s], product.numerator.factors)
        assert_equal(@s, product.denominator)
      end

      it '(p / q) * (u / v) = (p * u) / (q * v)' do
        product = @m_per_s * @A_per_kg

        assert_equal([@m, @A], product.numerator.factors)
        assert_equal([@s, @kg], product.denominator.factors)
      end

      it 'returns self after being multiplied by a null unit' do
        assert_equal(@m_per_s, @m_per_s * @null)
      end
    end

    describe '/' do
      it 'computes (p / q) / u = p / (q * u)' do
        quotient = @m_per_s / @kg

        assert_equal(@m, quotient.numerator)
        assert_equal([@s, @kg], quotient.denominator.factors)
      end

      it 'treats proportional units like base units' do
        quotient = @m_per_s / @h

        assert_equal(@m, quotient.numerator)
        assert_equal([@s, @h], quotient.denominator.factors)
      end

      it 'computes (p / q) / (u * v) = p / (q * u * v)' do
        quotient = @m_per_s / @kg_s

        assert_equal(@m, quotient.numerator)
        assert_equal([@s, @kg, @s], quotient.denominator.factors)
      end

      it 'computes (p / q) / (u / v) = (p * v) / (q * u)' do
        quotient = @m_per_s / @A_per_kg

        assert_equal([@m, @kg], quotient.numerator.factors)
        assert_equal([@s, @A], quotient.denominator.factors)
      end

      it 'returns self after being multiplied by a null unit' do
        assert_equal(@m_per_s, @m_per_s / @null)
      end
    end
  end

  describe MultipliedUnit do
    it 'has a name' do
      assert_equal('A * m', @A_m.name)
    end

    it 'has factors' do
      assert_equal([@kg, @s], @kg_s.factors)
    end

    it 'references the correct base unit' do
      assert_equal([@m, @s], (@km * @h).base_unit.factors)
    end

    describe 'convert_amount_base_units' do
      it 'returns the amount in the base unit' do
        measurement = (@km * @h).convert_amount_base_units(1)

        assert_equal(1000 * 3600, measurement.amount)
        assert_equal([@m, @s], measurement.unit.factors)
      end
    end

    describe '*' do
      it 'computes (p * q) * v = (p * q * v)' do
        product = @kg_s * @m

        assert_equal([@kg, @s, @m], product.factors)
      end

      it 'handles proportional units like base units' do
        product = @kg_s * @h

        assert_equal([@kg, @s, @h], product.factors)
      end

      it 'computes (p * q) * (u * v) = (p * q * u * v)' do
        product = @kg_s * @A_m

        assert_equal([@kg, @s, @A, @m], product.factors)
      end

      it 'computes (u * v) * (p / q) = (u * v * p) / q' do
        product = @kg_s * @m_per_s

        assert_equal([@kg, @s, @m], product.numerator.factors)
      end

      it 'returns self after being multiplied by a null unit' do
        assert_equal(@kg_s, @kg_s * @null)
      end
    end

    describe '/' do
      it 'computes (u * v) / p' do
        quotient = @kg_s / @m

        assert_equal([@kg, @s], quotient.numerator.factors)
        assert_equal(@m, quotient.denominator)
      end

      it 'treats proportional units like base units' do
        quotient = @kg_s / @h

        assert_equal([@kg, @s], quotient.numerator.factors)
        assert_equal(@h, quotient.denominator)
      end

      it 'computes (u * v) / (p * q)' do
        quotient = @kg_s / @A_m

        assert_equal([@kg, @s], quotient.numerator.factors)
        assert_equal([@A, @m], quotient.denominator.factors)
      end

      it 'computes (u * v) / (p / q) = (u * v * q) / p' do
        quotient = @kg_s / @A_per_kg

        assert_equal([@kg, @s, @kg], quotient.numerator.factors)
        assert_equal(@A, quotient.denominator)
      end

      it 'returns self for null unit' do
        assert_equal(@kg_s, @kg_s / @null)
      end
    end
  end

  describe NullUnit do
    it 'has an empty name' do
      assert_equal('', @null.name)
    end

    it 'is its own base unit' do
      assert_equal(@null, @null.base_unit)
    end

    describe 'convert_amount_base_units' do
      it 'returns the amount with null unit' do
        measurement = @null.convert_amount_base_units(2)

        assert_equal(2, measurement.amount)
        assert_equal(@null, measurement.unit)
      end
    end

    describe '*' do
      it 'returns the multiplicand' do
        assert_equal(@kg, @null * @kg)
      end
    end

    describe '/' do
      it 'returns self for null unit' do
        assert_equal(@null, @null / @null)
      end

      it 'computes 1 / u for non-divided units' do
        quotient = @null / @kg

        assert_equal(quotient.numerator, @null)
        assert_equal(quotient.denominator, @kg)
      end

      it 'computes 1 / (u / v) = v / u' do
        quotient = @null / @km_per_h

        assert_equal(@h, quotient.numerator)
        assert_equal(@km, quotient.denominator)
      end
    end
  end
end

describe Numeric do
  it 'returns self as amount' do
    assert_equal(2, 2.amount)
  end

  it 'returns null unit' do
    assert_equal(NullUnit.instance, 2.unit)
  end
end