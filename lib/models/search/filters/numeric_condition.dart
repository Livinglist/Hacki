enum NumericCondition {
  equalTo('='),
  greaterThan('>'),
  lessThan('<'),
  greaterThanOrEqualTo('>='),
  lessThanOrEqualTo('<=');

  const NumericCondition(this.operator);

  final String operator;

  static NumericCondition defaultValue = equalTo;
}
